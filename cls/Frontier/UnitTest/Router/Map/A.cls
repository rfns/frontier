Class Frontier.UnitTest.Router.Map.A Extends Frontier.Router
{

XData UrlMap [ XMLNamespace = "http://github.com/rfns/frontier" ]
{
<Routes>
   <Route Url="/route-parameter-not-specified" Method="GET" Call="TestGETRouteParameterNotSpecified" />
   <Route Url="/pass-route-param-to-child" Method="GET" Call="TestGETPassRouteParamToChild" />
   <Route Url="/prioritize-route-parameter" Method="GET" Call="TestGETPrioritizeRouteParameter" />
 </Routes>
}

ClassMethod TestGETRouteParameterNotSpecified() As %String
{
  return "this wont be returned"
}

ClassMethod TestGETPassRouteParamToChild(param1 As %String) As %String
{
  return param1
}

ClassMethod TestGETPrioritizeRouteParameter(param1 As %String) As %String
{
  return param1
}

}

