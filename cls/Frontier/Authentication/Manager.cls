/// The Authentication Manager is responsible for running the verification
/// from each provided strategy. When implementing a strategy you must follow
/// the specification provided by the Frontier.Authentication.Strategy.
Class Frontier.Authentication.Manager Extends %RegisteredObject
{

/// A list of strategies added that will be executed.
Property Strategies As list Of Frontier.Authentication.Strategy [ Private ];

/// A reference for the %session object.
Property Session As %CSP.Session [ Private ];

/// A reference for the %request object.
Property Request As %CSP.Request [ Private ];

/// A reference for the %response object.
Property Response As %CSP.Response [ Private ];

/// If the authenticated user have more than one scope, you can define how each scope must be splitted before the check.
Property ScopeSeparator As %String [ InitialExpression = " " ];

/// This is an internal flag that signals the routing engine that the client can access the protected resource.
/// This flag should NOT be set manually.
Property Verified As %Boolean [ InitialExpression = 0, Internal ];

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

/// Adds a strategy to the chain. Added strategies will be used to validade against the client's request data.
Method AddStrategy(strategy As Frontier.Authentication.Strategy) As %Status
{
  set ..Verified = 0
  $$$QuitOnError(..Strategies.Insert(strategy))
  return $$$OK
}

/// Resets the manager into the initial state. If you have a router with an authentication
/// already configured and a child router that must provide a new authentication chain, you must
/// call this method before populating the new chain.
Method Reset() As %Status
{
  set ..Verified = 0
  return ..Strategies.Clear()
}

/// This method will run each strategy to check if the client comply to any of their requirements.
/// The Verified flag will be set to 1 if there's any. Otherwise an error will be thrown informing that the client is not authenticated.
/// If a strategy implements the method GetChallenge, this method will be called if the client didn't provided any credentials that match any strategies in the chain.
/// Note that the GetChallenge will be executed only if the current strategy is the last one.
Method Verify(Output user As %DynamicObject = {{}}, resourceScope As %String = "") As %Status
{
  set sc = $$$OK
  set totalStrategies = ..Strategies.Count()
  set strategy = ""

  try {
    for i=1:1:totalStrategies {
      set strategy = ..Strategies.GetAt(i)
      if 'strategy.%Extends("Frontier.Authentication.Strategy") continue
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

/// If the Route contains an AuthStrategy property, the named strategy provided there will be the only one called.
/// In this case the client must always comply with that strategy.
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

/// This is an internal method used by the routing engine to check if any of the user's scope complies to the one provided
/// in the Route element's Scope property.
Method CheckResourceScope(resourceScope As %String = "", authenticationScope As %DynamicObject = {{}}) As %Boolean [ Internal ]
{
  if resourceScope [ " " {
    set resourceScope = $lfs(resourceScope, " ")
    set isMatch = 0

    for i=1:1:$ll(resourceScope) {
      set oneScope = $zstrip($lg(resourceScope, i), "<>W")
      set modifier = $extract(oneScope, 1)
      if $extract(modifier)?1AN = 1 set modifier = "+"

      if modifier = "-" set mustMatch = 0
      else  set mustMatch = 1

      set oneScope = $translate(oneScope, "+-", "")
      set isMatch = ..CheckResourceScope(oneScope, authenticationScope)
      if mustMatch && 'isMatch { return 0 }
      elseif 'mustMatch && isMatch { return 0 }
    }
    return 1
  }
  if resourceScope '= "" return $lf($lfs(authenticationScope, ..ScopeSeparator), resourceScope) > 0
  return 1
}

/// An internal method that will be used to set the client challenge.
Method SetChallenge(strategy As Frontier.Authentication.Strategy) [ Private ]
{
  set sc = strategy.GetChallenge(..Session, ..Request, ..Response, .challenge)

  if challenge '= "" do ..Response.SetHeader("WWW-Authenticate", challenge)
  $$$ThrowOnError(sc)
}

/// Returns if there's any strategies added.
Method HasStrategies() As %Boolean
{
  return ..Strategies.Count() > 0
}

}

