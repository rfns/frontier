Class Frontier.Authentication.Manager Extends %RegisteredObject
{

Property Strategies As list Of Frontier.Authentication.Strategy [ Private ];

Property Session As %CSP.Session [ Private ];

Property Request As %CSP.Request [ Private ];

Property Response As %CSP.Response [ Private ];

Property ScopeSeparator As %String [ InitialExpression = " " ];

Method %OnNew(session As %CSP.Session, request As %CSP.Request, response As %CSP.Response) As %Status
{
  set ..Session = session
  set ..Request = request
  set ..Response = response
  return $$$OK
}

Method ScopeSeparatorSet(value As %String) As %Status [ Final, Internal, Private ]
{
	set i%ScopeSeparator = $get(value, ",")
}

Method AddStrategy(strategy As Frontier.Authentication.Strategy) As %Status
{
    
  $$$QuitOnError(..Strategies.Insert(strategy))  
  return $$$OK
}

Method Verify(Output user As %DynamicObject = {{}}, resourceScope As %String = "") As %Status
{
  set sc = $$$OK
  set totalStrategies = ..Strategies.Count()
  set strategy = "" 
  
  try {
    for i=1:1:totalStrategies {
      set strategy = ..Strategies.GetAt(i)
      set sc = strategy.Verify(..Session, ..Request, ..Response, .user, resourceScope)
      if $$$ISOK(sc) {
	      quit
      } elseif 'strategy.Next {
		    set challengeSC = strategy.GetChallenge(..Session, ..Request, ..Response, .challenge)
				if $$$ISOK(challengeSC) do ..Response.SetHeader("WWW-Authenticate", challenge)
				quit		    
      }
    }
  } catch ex {
    set sc = ex.AsStatus()
  }
  return sc
}

Method CheckResourceScope(resourceScope As %String = "", authenticationScope As %DynamicObject = {{}}) As %Boolean
{
  if resourceScope '= "" return $lf($lfs(authenticationScope, ..ScopeSeparator), resourceScope) > 0
  return 1
}

}

