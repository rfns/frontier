Class Frontier.Authentication.CookieStrategy Extends Frontier.Authentication.Strategy
{

Property Name As %String [ InitialExpression = "Cookie" ];

Property Key As %String [ InitialExpression = "__fc" ];

Property Cleanup As %String [ Private ];

Property Secret As %String [ Private ];

Property Validator As %String;

Method %OnNew(config As %DynamicObject) As %Status
{
  set ..Secret = config.secret
  if config.%IsDefined("name") set ..Name = config.name
  if config.%IsDefined("key") set ..Key = config.key
  if config.%IsDefined("validator") set ..Validator = config.validator
  return $$$OK
}

Method Verify(session As %CSP.Session, request As %CSP.Request, response As %CSP.Response, Output user As %DynamicObject = {{}}, resourceScope As %String = "") As %Status
{
  set failed = 0
  #define ExpireCookie  do response.SetCookie(..Key,"",$zdt("0,0", 2)_" GMT")
  #define AssertPropertyDefined(%jp,%ip) if $p($this, %ip) = "" $$$ExpireCookie return $$$ERROR($$$GeneralError, $$$FormatText("Strategy '%1' requires '%1' property to be specified.", ..Name, %jp))

  $$$AssertPropertyDefined("validator", "Validator")
  $$$AssertPropertyDefined("key", "Key")
  $$$AssertPropertyDefined("secret", "Secret")

  if 'request.IsDefinedCookie(..Key) return $$$OK
  set token = request.GetCookie(..Key)
  set payload = ##class(Frontier.Security.CookieSignature).Unsign(token, ..Secret)

  if payload = "" {
    $$$ExpireCookie
    do %frontier.Status("401 Forbidden")
    return $$$ERROR($$$InvalidUsernameOrPassword)
  }

  $$$QuitOnError(##class(Frontier.Shared.Utilities).SafeClassMethodCall(..Validator, payload, .found, .httpStatus, .user))
  if found = 1 set ..Verified = 1
  return $$$OK
}

}
