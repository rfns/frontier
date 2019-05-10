/// This class is the backbone required to implement an strategy.
/// The implementation must follow a specification below:
/// ****
/// 1 - The strategy implementation must inherit from this class.
/// ****
/// 2 - The strategy must always check if the client provided sufficient data
/// to run the validation, if it didn't, the strategy MUST return $$$OK. This will
/// make the manager skips to the next strategy in the chain.
/// ****
/// 3 - If the user provided enough data and the validation succeeded, then the strategy
/// must set the Verified flag to 1. This will make the manager bail out without running
/// the remaining strategies, thus allowing the client to access the protected resource.
/// ****
/// 4 - If the user provided enough data but the validation failed, the strategy must return
/// an $$$ERROR. This will also make the manager bail out the strategy chain but the error emitted by
/// the current strategy will be display. Additionally, the strategies can also provide a challenge
/// by implementing the method GetChallenge and/or set an adequate HTTP Status Code, by using the response.Status property.
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
  return $$$OK
}

}
