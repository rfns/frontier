Class UnitTest.Frontier.Authentication.Manager Extends Port.UnitTest.TestCase
{

Property AuthenticationManager As Frontier.Authentication.Manager;

Property Request As %CSP.Request;

Property Response As %CSP.Response;

Property Session As %CSP.Session;

Method OnBeforeOneTest() As %Status
{
  set ..Session = ##class(%CSP.Session).%New("t3st1ng")
  set ..Request = ##class(%CSP.Request).%New()
  set ..Response = ##class(%CSP.Response).%New()
  set context = ##class(Frontier.Context).%New(..Session, ..Request, ..Response)
  set ..AuthenticationManager = context.AuthenticationManager  
  return $$$OK
}

Method OnAfterOneTest() As %Status
{
  set ..Request = ""
  set ..Response = ""
  set ..Session = ""
  set ..AuthenticationManager = ""
  return $$$OK
}

Method TestVerify()
{
  
  // Skips first and second strategy, assume that the validation criteria wasn't found on each of them.
  set dummyStrategy1 = ##class(Frontier.UnitTest.Authentication.DummyStrategy).%New()
  set dummyStrategy1.Behavior = "bypass"
  
  set dummyStrategy2 = ##class(Frontier.UnitTest.Authentication.DummyStrategy).%New()
  set dummyStrategy2.Behavior = "bypass"
  
  // Instead, assume that the third input fits the third strategy, thus verifying it.
  set dummyStrategy3 = ##class(Frontier.UnitTest.Authentication.DummyStrategy).%New()
  set dummyStrategy3.Behavior = "pass"
  
  do ..AuthenticationManager.AddStrategy(dummyStrategy1)  
  do ..AuthenticationManager.AddStrategy(dummyStrategy2)
  do ..AuthenticationManager.AddStrategy(dummyStrategy3)
  
  set sc = ..AuthenticationManager.Verify(.user)  
  
  // Must not return an error.
  do $$$AssertStatusOK(sc, "allows access")
  
  do $$$AssertTrue(..Response.GetHeader("WWW-Authenticate") = "", "doesn't include the challenge if one strategy works.")
  
  set dummyStrategy4 = ##class(Frontier.UnitTest.Authentication.DummyStrategy).%New()
  
  // This one should not be called because the manager should bail out after validating using the third strategy.
  do ..AuthenticationManager.AddStrategy(dummyStrategy4)
  
  set sc = ..AuthenticationManager.Verify(.user)
  do $$$AssertStatusOK(sc, "skips pending strategies if one works")
  
  // Now we'll test the failure condition.
  set dummyStrategy3.Behavior = ""
  
  // This is not a verification mismatch, but a true error.
  set sc = ..AuthenticationManager.Verify(.user)
  
  // Validation failed, user should be empty.
  do $$$AssertEquals(user.name, "", "always return an user object even if empty")    
  do $$$AssertStatusNotOK(sc, "returns the last strategy error")
  
  // Header should NOT be set, remember that this is not an user error.
  do $$$AssertTrue(..Response.GetHeader("WWW-Authenticate") = "", "don't output the strategy on error.")
   
  do ..AuthenticationManager.Reset()
    
  // Test the condition where every strategy is bypassed and so it should enforce the first one.
  set dummyStrategy5 = ##class(Frontier.UnitTest.Authentication.DummyStrategy).%New()
  set dummyStrategy5.Behavior = "bypass"
  
  set dummyStrategy6 = ##class(Frontier.UnitTest.Authentication.DummyStrategy).%New()
  set dummyStrategy6.Behavior = "bypass" 
  
  set dummyStrategy7 = ##class(Frontier.UnitTest.Authentication.DummyStrategy).%New()
  set dummyStrategy7.Behavior = "bypass"  
  
  do ..AuthenticationManager.AddStrategy(dummyStrategy5)
  do ..AuthenticationManager.AddStrategy(dummyStrategy6)
  do ..AuthenticationManager.AddStrategy(dummyStrategy7)
    
  set sc = ..AuthenticationManager.Verify(.user)
  
  do $$$AssertStatusOK(sc, "returns ok if all strategies were skipping")  
  do $$$AssertNotTrue(..AuthenticationManager.Verified, "Verified flag must be 0")  
  do $$$AssertTrue(..Response.GetHeader("WWW-Authenticate") '= "", "outputs the challenge because nothing was provided.")
}

}

