Class Frontier.UnitTest.Authentication.DummyStrategy Extends Frontier.Authentication.Strategy
{

Property Behavior As %String [ InitialExpression = "fail" ];

Method %OnNew(config As %DynamicObject = {{}}) As %Status
{
  return $$$OK
}

Method Verify(session As %CSP.Session, request As %CSP.Request, response As %CSP.Response, Output user As %DynamicObject = {{}}, resourceScope As %String = "") As %Status
{
    
  if ..Behavior = "bypass" return $$$OK
  if ..Behavior = "pass" set ..Verified = 1 return $$$OK
  set response.Status = "401 Unauthorized"
  return $$$ERROR($$$GeneralError, "Requested to fail")
}

Method GetChallenge(session As %CSP.Session, request As %CSP.Request, response As %CSP.Response, Output challenge As %String = "") As %Status
{
  set challenge = "realm=""Tests"""
  return $$$OK
}

}

