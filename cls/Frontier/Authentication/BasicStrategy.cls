Include (%occErrors, %occStatus)

Class Frontier.Authentication.BasicStrategy Extends Frontier.Authentication.Strategy
{

Property Realm As %String [ Private ];

Property Statement As %SQL.Statement [ Private ];

Property HashMethod As %String [ Private ];

Property Validator As %String [ Private ];

Property UserInfoMethod As %String [ Private ];

Method %OnNew(realm As %String = "Users", result As %SQL.StatementResult = "", hashMethod As %String = "", validator As %String = "", userInfoMethod As %String = "") As %Status
{
  set ..Realm = realm
  set ..HashMethod = hashMethod
  set ..Statement = result
  set ..Validator = validator
  set ..UserInfoMethod = userInfoMethod
  return $$$OK
}

Method Verify(session As %CSP.Session, request As %CSP.Request, response As %CSP.Response, Output user As %DynamicObject = {{}}) As %Status
{
  set sc = $$$OK
  set found = 0
  set authHeader = request.GetCgiEnv("HTTP_AUTHORIZATION")
  
  if authHeader = "" {
    return $$CreateError("You must be authenticated to access this resource.")
  }
  
  if $extract(authHeader, 1, 5) '= "Basic" {
    return $$CreateError("Malformed authorization header.", "400 Bad Request")
  }

  set credentials = $System.Encryption.Base64Decode($piece(authHeader, " ", 2))
    
  set userName = $piece(credentials, ":")
  set password = $piece(credentials, ":", 2)
  
  if ..HashMethod '= "" {
    set class = $piece(..HashMethod, ":")
    set method = $piece(..HashMethod, ":", 2)
    set password = $classmethod(class, method, password)
  }
  
  if $isobject(..Statement) {
    if '##class(Frontier.Types).IsTypeOf($classname(..Statement), "%SQL.Statement") {
      return $$CreateError("User list is not sourced from a valid SQL statement.", "400 Bad Request")
    }
    
    set result = ..Statement.%Execute(userName, password)
    
    if result.%SQLCODE '= 0 {
      set sc = ##class(%Exception.SQL).CreateFromSQLCODE(result.%SQLCODE, result.%Message).AsStatus()
      return $$CreateError(sc, "500 Internal Server Error", 1)
    }
    
    set found = result.%Next(.sc)    
    
    if $$$ISERR(sc) {
      return $$CreateError(sc, "500 Internal Server Error", 1)
    }
  } elseif ..Validator '= "" {
    set class = $piece(..Validator, ":")
    set method = $piece(..Validator, ":", 2)
    try {
      set found = $classmethod(class, method, userName, password)
    } catch ex {
      set sc = ex.AsStatus()
    }
  }
  
  if $$$ISERR(sc) return sc
  
  if 'found {
    return $$CreateError("Unknown user or password.", "403 Forbidden")  
  }
  
  if ..UserInfoMethod '= "" {
    set class = $piece(..UserInfoMethod, ":")
    set method = $piece(..UserInfoMethod, ":", 2)
    try {
      set sc = $classmethod(class, method, .user, userName, request)
    } catch ex {
      set sc = ex.AsStatus()
    }
    set sc = $$CreateError(sc, "500 Internal Server Error", 1)
  }
  
  return sc
  
CreateError(message, status="401 Unauthorized", isStatus=0)
  set response.Status = status
  if 'isStatus return $$$ERROR($$$GeneralError, message) 
  return message
}

Method GetChallenge(session As %CSP.Session, request As %CSP.Request, response As %CSP.Response) As %String
{
  return "Basic realm="""_..Realm_""""
}

}

