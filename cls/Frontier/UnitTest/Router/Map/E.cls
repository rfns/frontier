Class Frontier.UnitTest.Router.Map.E Extends Frontier.Router
{

XData UrlMap [ XMLNamespace = "http://github.com/rfns/frontier" ]
{
<Routes>
<Route Url="/get-parent-and-(\w+)-(\w+)" Strict="false" Method="GET" Call="TestGETMultipleRegexMatches" />
</Routes>
}

ClassMethod TestGETMultipleRegexMatches(namedParam As %String) As %Status
{
  set matches = [ (namedParam) ]
  
  for i=1:1:%frontier.Matches {
    do matches.%Push(%frontier.Matches(i))
  }
  
  return matches
}

}

