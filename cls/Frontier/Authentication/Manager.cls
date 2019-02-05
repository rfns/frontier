Class Frontier.Authentication.Manager Extends %RegisteredObject
{

Property Strategies As list Of Frontier.Authentication.Strategy [ Private ];

Property Session As %CSP.Session [ Private ];

Property Request As %CSP.Request [ Private ];

Property Response As %CSP.Response [ Private ];

Property ScopeSeparator As %String [ InitialExpression = " " ];

Property Verified As %Boolean [ InitialExpression = 0 ];

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
  set ..Verified = 0
  $$$QuitOnError(..Strategies.Insert(strategy))
  return $$$OK
}

Method Reset() As %Status
{
  set ..Verified = 0
  return ..Strategies.Clear()
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
      if $$$ISERR(sc) return sc
      
      set ..Verified = strategy.Verified      
      
      if ..Verified = 1 {
        return $$$OK      
      } elseif i < totalStrategies {
        continue        
      } elseif $$$ISOK(sc) {
        do ..SetChallenge(strategy)
      }
    }
  } catch ex {
    set sc = ex.AsStatus()
  }
  
  return sc
}

Method VerifyUsing(namedStrategy As %String, Output user, resourceScope As %String = "") As %Status
{
  set ..Verified = 0
  set sc = $$$OK
  set found = 0
  
  for i=1:1:..Strategies.Count() {
    set strategy = ..Strategies.GetAt(i)
    if strategy.Name = namedStrategy {
      set found = 1
      try {
        set sc = strategy.Verify(..Session, ..Request, ..Response, .user, resourceScope)
        if $$$ISERR(sc) return sc 
        
        set ..Verified = strategy.Verified
        
        if ..Verified = 1 {
          return $$$OK
        } elseif $$$ISOK(sc) {
          do ..SetChallenge(strategy)
          return sc
        } 
      } catch ex {
        set sc = ex.AsStatus()
      }                  
    }
  }    
  
  if 'found {
    return $$$ERROR($$$GeneralError, $$$FormatText("Strategy '%1' was not defined.", namedStrategy))
  }
  return sc
}

Method CheckResourceScope(resourceScope As %String = "", authenticationScope As %DynamicObject = {{}}) As %Boolean
{
  if resourceScope '= "" return $lf($lfs(authenticationScope, ..ScopeSeparator), resourceScope) > 0
  return 1
}

Method SetChallenge(strategy As Frontier.Authentication.Strategy) [ Private ]
{
  set sc = strategy.GetChallenge(..Session, ..Request, ..Response, .challenge)
  if challenge '= "" do ..Response.SetHeader("WWW-Authenticate", challenge)
  $$$ThrowOnError(sc)
}

}

