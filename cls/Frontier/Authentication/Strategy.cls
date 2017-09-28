Class Frontier.Authentication.Strategy Extends %RegisteredObject
{

Method OnVerify(session As %CSP.Session, request As %CSP.Request, response As %CSP.Response, Output user As %DynamicObject = {{}}) As %Status
{
  return $$$OK
}

Method GetChallenge(session As %CSP.Session, request As %CSP.Request, response As %CSP.Response) As %String
{
  $$$ThrowOnError($$$ERROR($$$MethodNotImplemented, "AddChallenge"))
}

}

