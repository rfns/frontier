Include (%occErrors, %occStatus, frontier)

/// This strategy provides the implementation for handling clients requests whose authentication
/// follows the format: Authorization: Bearer <bearer_token>. There's not much difference with
/// the Basic version, only that it won't decode the token since a Bearer token is implementation specific.
/// Which means that the implementer must use the method specified in the 'validator' to decode and validate it.
Class Frontier.Authentication.BearerStrategy Extends Frontier.Authentication.Strategy
{

/// This is the name the of the strategy. Can be used to determine that this strategy should be used for a Route exclusively.
Property Name As %String [ InitialExpression = "Bearer" ];

/// This is used by the challenge. Represents the "realm=<value>" from the WWW-Authenticate challenge header.
Property Realm As %String [ Private ];

/// A string whose format should be classname:classmethod, which is used to validate the value from the Authorization header.
Property Validator As %String [ Private ];

Property ChallengeScope As %String [ Private ];

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
    // Let the manager call the next strategy, if that's the last one, then the error is
    // fired by the router class.
    return $$$OK
  } else {
    set token = $$$trim($extract(authHeader, 7, *))
    set sc = ##class(Frontier.Shared.Utilities).SafeClassMethodCall(..Validator, token, .found, .httpStatus, .user)
    if 'found  set ..ChallengeScope = $replace(resourceScope, ",", " ")
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
  if ..ChallengeScope '= "" set challenge = challenge_" scope="_..ChallengeScope
  return $$$OK
}

}

