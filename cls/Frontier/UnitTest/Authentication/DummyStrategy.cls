Class Frontier.UnitTest.Authentication.DummyStrategy Extends Frontier.Authentication.Strategy
{

Property ShouldPass As %Boolean [ InitialExpression = 1 ];

Method Verify(session As %CSP.Session, request As %CSP.Request, response As %CSP.Response, Output user As %DynamicObject = {{}}, resourceScope As %String = "") As %Status
{
 
  if ..ShouldPass = 1 || (..Next = 1) return $$$OK
  set response.Status = "401 Unauthorized"
  return $$$ERROR($$$GeneralError, "Requested to fail")
}

Method GetChallenge(session As %CSP.Session, request As %CSP.Request, response As %CSP.Response, Output challenge As %String = "") As %Status
{
  set challenge = "realm=""Tests"""
  return $$$OK
}

}

