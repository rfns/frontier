Class Frontier.UnitTest.Router.Map.B Extends Frontier.Router
{

XData UrlMap [ XMLNamespace = "http://github.com/rfns/frontier" ]
{
<Routes>
    <Route Url="/" Method="GET" Call="TestGETMultipleRouteParameters" />
    <Route Url="/something_(up|down)" Strict="false" Method="GET" Call="TestMe" />
  </Routes>
}

ClassMethod TestMe(matches As %DynamicArray) As %Status
{
  return matches
}

ClassMethod TestGETMultipleRouteParameters(param2 As %String, param1 As %String) As %String
{
  return param1_" "_param2
}

}

