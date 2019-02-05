Class Frontier.Authentication.Strategy Extends %RegisteredObject
{

Property Realm As %String [ Private ];

Property Name As %String;

Property Verified As %Boolean [ InitialExpression = 0 ];

Method %OnNew(config As %DynamicObject = {{}}) As %Status
{
  $$$ThrowStatus($$$ERROR($$$MethodNotImplemented, "%OnNew"))  
  return $$$OK
}

Method Verify(session As %CSP.Session, request As %CSP.Request, response As %CSP.Response, Output user As %DynamicObject = {{}}, resourceScope As %String = "") As %Status
{
  return $$$OK
}

Method GetChallenge(session As %CSP.Session, request As %CSP.Request, response As %CSP.Response, challenge As %String = "") As %Status
{
  return $$$ERROR($$$MethodNotImplemented, "GetChallenge")
}

}

