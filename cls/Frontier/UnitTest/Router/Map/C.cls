Class Frontier.UnitTest.Router.Map.C Extends Frontier.Router
{

XData UrlMap
{
<Routes>
 <Route Url="/" Method="GET" Call="TestGETRouteWithoutParameters" />
 <Route Url="/scoped" Method="GET" Scope="admin" Call="TestGETScopedResponse" />
 <Route Url="/auth/bypass" Method="GET" UseAuth="false" Call="TestGETBypassAuth" />
</Routes>
}

ClassMethod TestGETRouteWithoutParameters() As %String
{
  return "Hello from a simple but mapped route!"
}

ClassMethod TestGETScopedResponse() As %String
{
  return $$$FormatText("Hello %1! If you're seeing this, then you have enough privilege for that!", %frontier.User.login)
}

ClassMethod TestGETBypassAuth() As %String
{
 
  return "This is an unprotected resource!"
}

}

