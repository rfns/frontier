Class Frontier.UnitTest.Router.Map.E Extends Frontier.Router
{

XData UrlMap [ XMLNamespace = "http://github.com/rfns/frontier" ]
{
<Routes>
<Route Url="/get-parent-and-(this)-(group)" Strict="false" Method="GET" Call="TestGETMultipleRegexMatches" />
</Routes>
}

ClassMethod TestGETMultipleRegexMatches(matches... As %String) As %Status
{
  return [ (matches(1)), (matches(2)), (matches(3)) ]
}

}

