Class Frontier.Authentication.Strategy Extends %RegisteredObject
{

Property Next As %Boolean [ InitialExpression = 0 ];

Method %OnNew(config As %DynamicObject = {{}}) As %Status
{
  return $$$OK
}

Method NextSet(value As %Boolean) As %Status
{
	set i%Next = +value
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

