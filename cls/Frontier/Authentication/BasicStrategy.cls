Include (%occErrors, %occStatus, frontier)

/// This strategy provides the implementation for handling clients requests whose authentication
/// follows the format: Authorization: Basic b64(user:password). This class can be used to demonstrate
/// how a strategy can be implemented and even augmented. This strategy works as the following:
/// * If the user doesn't provide an Authorization header, we assume that the client isn't using the Basic
/// specification and let the request be handle by the next strategy.
/// * If the user provided an Authorization header, but the value doesn't start with 'Basic', we consider
/// it as malformed and reply it back to the client as an error.
/// * If the client didn't provided any authentication, we challenge it using the implemented GetChallenge.
Class Frontier.Authentication.BasicStrategy Extends Frontier.Authentication.Strategy
{

/// This is the name the of the strategy. Can be used to determine that this strategy should be used for a Route exclusively.
Property Name As %String [ InitialExpression = "Basic" ];

/// This is used by the challenge. Represents the "realm=<value>" from the WWW-Authenticate challenge header.
Property Realm As %String [ Private ];

/// A string whose format should be classname:classmethod, which is used to validate the value from the Authorization header.
Property Validator As %String [ Private ];

Method %OnNew(config As %DynamicObject) As %Status
{
  set ..Realm = config.realm
  set ..Validator = config.validator
  if config.%IsDefined("name") set ..Name = config.name
  return $$$OK
}

/// Searches for the Authorization header, skips if nothing is found. Otherwise validates the header and the credentials themselves.
Method Verify(session As %CSP.Session, request As %CSP.Request, response As %CSP.Response, Output user As %DynamicObject = {{}}, resourceScope As %String = "") As %Status
{
  set sc = $$$OK
  set found = 0
  set httpStatus = ""
  set authHeader = request.GetCgiEnv("HTTP_AUTHORIZATION")

  set authType = $$$trim($$$ucase($piece(authHeader, " ", 1)))

  if authHeader = "" {
    // Let the manager call the next strategy, if that's the last one than the error is
    // fired by the router class.
    return $$$OK
  } elseif authType = "BASIC" {
    set credentials = $System.Encryption.Base64Decode($$$trim($piece(authHeader, " ", 2)))
    set userName = $piece(credentials, ":")
    set password = $piece(credentials, ":", 2)
    set sc = ##class(Frontier.Shared.Utilities).SafeClassMethodCall(..Validator, userName, password, .found, .httpStatus, .user)
    set ..Verified = found
    if $$$ISERR(sc) {
      if httpStatus '= "" set response.Status = httpStatus
      else  set response.Status = "500 Internal Server Error"
    }
  }

  if $$$ISOK(sc) && (found = 0) {
    set sc = $$$ERROR($$$InvalidUsernameOrPassword)
    set response.Status = "403 Forbidden"
  }

  return sc
}

/// Returns a string that is used to populate the WWW-Authenticate.
Method GetChallenge(session As %CSP.Session, request As %CSP.Request, response As %CSP.Response, challenge As %String = "") As %Status
{
  set challenge = "Basic realm="""_..Realm_""""
  return $$$OK
}

}

