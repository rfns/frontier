Class Frontier.Authentication.StrategyCombiner Extends Frontier.Authentication.Strategy
{

Property Strategies As list Of Frontier.Authentication.Strategy [ Private ];

Method Combine(strategies... As Frontier.Authentication.Strategy) As %Status
{
  set sc = $$$OK
  
  for i=1=1:strategies {
    set strategy = strategies(i)
    set sc = ..Strategies.Insert(strategy)
    if $$$ISERR(sc) return sc
  }
  return $$$OK
}

Method Verify(session As %CSP.Session, request As %CSP.Request, response As %CSP.Response, Output user As %DynamicObject = {{}}, resourceScope As %String = "") As %Status
{
  set sc = $$$OK
  
  for i=1:1:..Strategies.Count() {
    set sc = ..Strategies.Verify(session, request, response, .user)
    if $$$ISERR(sc) return sc
  }
  
  return sc
}

}

