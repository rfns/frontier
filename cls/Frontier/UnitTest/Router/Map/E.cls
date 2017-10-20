Class Frontier.UnitTest.Router.Map.E Extends Frontier.Router
{

XData UrlMap [ XMLNamespace = "http://github.com/rfns/frontier" ]
{
<Routes>
<Route Url="/result" Method="GET" Call="TestGETParentSinglePlaceholder" />
<Route Url="/something_(up|down)" Strict="false" Method="GET" Call="TestMe" />
</Routes>
}

ClassMethod TestGETParentSinglePlaceholder() As %Status
{
}

ClassMethod TestMe(matches As %DynamicArray, result As %String) As %Status
{
  return matches
}

}

