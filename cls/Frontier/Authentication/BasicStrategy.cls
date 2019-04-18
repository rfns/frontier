Include (%occErrors, %occStatus)

/// Testando.
Class Frontier.Authentication.BasicStrategy Extends Frontier.Authentication.Strategy
{

Property Realm As %String [ Private ];

Property Validator As %String [ Private ];

Property Required As %Boolean [ InitialExpression = 0 ];

Property Name As %String [ InitialExpression = "Basic" ];

Method %OnNew(config As %DynamicObject) As %Status
{
  set ..Realm = config.realm
  set ..Validator = config.validator
  if config.%IsDefined("name") set ..Name = config.name
  return $$$OK
}

Method Verify(session As %CSP.Session, request As %CSP.Request, response As %CSP.Response, Output user As %DynamicObject = {{}}, resourceScope As %String = "") As %Status
{
  set sc = $$$OK
  set found = 0
  set httpStatus = ""
  set authHeader = request.GetCgiEnv("HTTP_AUTHORIZATION")

  if authHeader = "" {
    // Let the manager call the next strategy, if that's the last one than the error is
    // fired by the router class.
    return $$$OK
  } elseif authHeader '= "" && ($extract(authHeader, 1, 5) '= "Basic") {
    // Specific errors can overwrite the return with something other than $$$OK.
    set sc = $$$ERROR($$$GeneralError, "Malformed authentication header.")
    set response.Status = "400 Bad Request"
  } else {
    set credentials = $System.Encryption.Base64Decode($piece(authHeader, " ", 2))
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

Method GetChallenge(session As %CSP.Session, request As %CSP.Request, response As %CSP.Response, challenge As %String = "") As %Status
{
  set challenge = "Basic realm="""_..Realm_""""
  return $$$OK
}

}

