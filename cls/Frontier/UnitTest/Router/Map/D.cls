Class Frontier.UnitTest.Router.Map.D Extends Frontier.Router
{

XData UrlMap [ XMLNamespace = "http://github.com/rfns/frontier" ]
{
<Routes>
 <Route Url="/parent-sparse-params/:operation" Method="GET" Call="TestGETParentSparseParams"/>
</Routes>
}

ClassMethod TestGETParentSparseParams(operation As %String, paramA As %Integer, paramB As %Integer)
{
  if operation = "sum" return paramA + paramB
  if operation = "subtract" return paramA - paramB
  if operation = "divide" return paramA / paramB
  if operation = "multiply" return paramA * paramB
  return 0
}

}

