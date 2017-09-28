Class Frontier.Authentication.Manager Extends %RegisteredObject
{

Property Strategies As list Of Frontier.Authentication.Strategy [ Private ];

Property Session As %CSP.Session [ Private ];

Property Request As %CSP.Request [ Private ];

Property Response As %CSP.Response [ Private ];

Method %OnNew(session As %CSP.Session, request As %CSP.Request, response As %CSP.Response) As %Status
{
  set ..Session = session
  set ..Request = request
  set ..Response = response
  return $$$OK
}

Method AddStrategy(strategy As Frontier.Authentication.Strategy) As %Status
{
    
  $$$QuitOnError(..Strategies.Insert(strategy))  
  return $$$OK
}

Method Verify(Output user As %DynamicObject = {{}}) As %Status
{
  set sc = $$$OK
  set totalStrategies = ..Strategies.Count()
  set strategy = "" 
  
  try {
    for i=1:1:totalStrategies {
      set strategy = ..Strategies.GetAt(i)
      set sc = strategy.Verify(..Session, ..Request, ..Response, .user)
      if $$$ISOK(sc) quit
    }
    if $$$ISERR(sc) && (i = totalStrategies) && (..Response.Status = "401 Unauthorized") {
      do ..Response.SetHeader("WWW-Authenticate", strategy.GetChallenge(..Session, ..Request, ..Response))   
    }
  } catch ex {
    set sc = ex.AsStatus()
  }
  return sc
}

Method UserMatchesResourceScope(resourceScope As %String = "", user As %DynamicObject = {{}}) As %Boolean
{
  if resourceScope '= "" return $lf($lfs(user.scope, " "), resourceScope) > 0
  return 1
}

}

