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
	// This will fail but move to the next strategy. The Next flag indicates that there
	// isn't enough info about the authentication method to decide a strategy thus making the manager ignores it.
	set dummyStrategy1 = ##class(Frontier.UnitTest.Authentication.DummyStrategy).%New()
	set dummyStrategy1.ShouldPass = 0
	set dummyStrategy1.Next = 1
	
	// Same here.
	set dummyStrategy2 = ##class(Frontier.UnitTest.Authentication.DummyStrategy).%New()
	set dummyStrategy2.ShouldPass = 0
	set dummyStrategy2.Next = 1
	
	// If the flag is not set, then it'll validate the input.
	// Luckly, we're informing our dummy strategy that it should allow the access.
	set dummyStrategy3 = ##class(Frontier.UnitTest.Authentication.DummyStrategy).%New()
	set dummyStrategy3.ShouldPass = 1
	
	//do $$$AssertStatusOK(..AuthenticationManager.AddStrategy(dummyStrategy1), "can add strategy")
	do ..AuthenticationManager.AddStrategy(dummyStrategy1)
	
	do ..AuthenticationManager.AddStrategy(dummyStrategy2)
	do ..AuthenticationManager.AddStrategy(dummyStrategy3)
	
	set sc = ..AuthenticationManager.Verify(.user)	
	
	do $$$AssertStatusOK(sc, "allows access")
	
	do $$$AssertTrue(..Response.GetHeader("WWW-Authenticate") = "", "doesn't output the WWW-Authenticate if one strategy works.")
	
	set dummyStrategy4 = ##class(Frontier.UnitTest.Authentication.DummyStrategy).%New()
	set dummyStrategy4.ShouldPass = 0
	
	do ..AuthenticationManager.AddStrategy(dummyStrategy4)	
	
	set sc = ..AuthenticationManager.Verify(.user)
	do $$$AssertStatusOK(sc, "skips pending strategies if one works")
	
	// This time we're forcing our passing strategy to fail, and there's no Next flag
	// so assume that the user sent us a valid authentication but the credentials are
	// not what we expected.
	set dummyStrategy3.ShouldPass = 0
	
	set sc = ..AuthenticationManager.Verify(.user)
	
	do $$$AssertEquals(user.name, "", "always return an user object even if empty")
	do $$$AssertStatusNotOK(sc, "returns the last strategy error")
	
	// Now we have the WWW-Authenticate header set.
	do $$$AssertTrue(..Response.GetHeader("WWW-Authenticate") '= "", "outputs the WWW-Authenticate when neither of the provided strategies succeed.")
}

ClassMethod T()
{
	set t = ..%New(##class(Port.UnitTest.Manager).%New())
	do t.OnBeforeOneTest()
	do t.TestVerify()
	do t.OnBeforeOneTest()
}

}

