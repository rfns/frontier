Include (%occErrors, %occStatus)

Class Frontier.Authentication.BasicStrategy Extends Frontier.Authentication.Strategy
{

Property Realm As %String [ Private ];

Property Validator As %String [ Private ];

Method %OnNew(config As %DynamicObject) As %Status
{
  set ..Realm = config.realm
  set ..Validator = config.validator
  return $$$OK
}

Method Verify(session As %CSP.Session, request As %CSP.Request, response As %CSP.Response, Output user As %DynamicObject = {{}}, resourceScope As %String = "") As %Status
{
  set sc = $$$OK
  set found = 0
  set httpStatus = ""
  set authHeader = request.GetCgiEnv("HTTP_AUTHORIZATION")
  
  if authHeader = "" {
    set ..Next = 1
    return $$CreateError("You must be authenticated to access this resource.")
  }
  
  if $extract(authHeader, 1, 5) '= "Basic" {
    set ..Next = 1
    return $$CreateError("Malformed authorization header.", "400 Bad Request")
  }

  set credentials = $System.Encryption.Base64Decode($piece(authHeader, " ", 2))
    
  set userName = $piece(credentials, ":")
  set password = $piece(credentials, ":", 2)  
  
  if ..Validator '= "" {
    set class = $piece(..Validator, ":")
    set method = $piece(..Validator, ":", 2)
    try {
      set sc = $classmethod(class, method, userName, password, .found, .httpStatus, .user)
    } catch ex {
      set sc = ex.AsStatus()
    }
  } else {
    return $$CreateError("Credentials validator was not specified", "500 Internal Server Error")
  }
  
  if $$$ISERR(sc) {
    return $$CreateError(sc, httpStatus, 1)
  }
  
  if httpStatus = "" {
    set httpStatus = "500 Internal Server Error"
  }
  
  if 'found {
    return $$CreateError("Unknown user or password.", "403 Forbidden")  
  }  
  
  return sc
  
CreateError(message, status="401 Unauthorized", isStatus=0)
  set response.Status = status
  if 'isStatus return $$$ERROR($$$GeneralError, message) 
  return message
}

Method GetChallenge(session As %CSP.Session, request As %CSP.Request, response As %CSP.Response, challenge As %String = "") As %Status
{
  set challenge = "Basic realm="""_..Realm_""""
  return $$$OK
}

}

