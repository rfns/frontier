Class Frontier.UnitTest.Router Extends Frontier.Router
{

XData UrlMap [ XMLNamespace = "http://github.com/rfns/frontier" ]
{
<Routes>
  <Route Url="/route_params/:class" Method="GET" Call="TestGETRouteParams"/>
  <Route Url="/query_params" Method="GET" Call="TestGETOneQueryParameter"/>
  <Route Url="/rest_params" Method="GET" Call="TestGETRestParametersSum"/>
  <Route Url="/mixed/rest" Method="POST" Call="TestPOSTMixedRestParametersSum"/>
  <Route Url="/unpublished" Method="GET" Call="TestGETUnpublishedMethod"/>
  <Route Url="/payload/single_object" Method="POST" Call="TestPOSTObjectPayloadSingle"/>
  <Route Url="/payload/object_with_query_params" Method="POST" Call="TestPOSTObjectPayloadQueryParams"/>  
  <Route Url="/payload/single_array" Method="POST" Call="TestPOSTArrayPayloadSingle"/>
  <Route Url="/payload/array_with_query_params" Method="POST" Call="TestPOSTArrayPayloadQueryParams"/>
  <Route Url="/payload/invalid" Method="POST" Call="TestPOSTInvalidPayload"/>
  <Route Url="/mixed/object" Method="GET" Call="TestGETMixedDynamicObject"/>
  <Route Url="/mixed/array" Method="GET" Call="TestGETMixedDynamicArray"/>
  <Route Url="/raw" Method="GET" Call="TestGETRawMode"/>
  <Route Url="/sql" Method="GET" Call="TestGETMixedSQL"/>
 </Routes>
}

/// curl -H "Content-Type: application/json" 'localhost:57772/api/frontier/test/route_params/6' 
/// {"Plate":"O5397","Students":[{"Name":"Drabek,Peter T.","__id__":"20"}],"__id__":"6"}
ClassMethod TestGETRouteParams(class As Frontier.UnitTest.Fixtures.Class) As %Status
{
  return class
}

/// curl -H "Content-Type: application/json" 'localhost:57772/api/frontier/test/query_params?msg=hello'
/// {result":"hello"}
ClassMethod TestGETOneQueryParameter(msg As %String) As %String
{
  
  return "hello"
}

/// curl -H "Content-Type: application/json" 'localhost:57772/api/frontier/test/rest_params?n1=10&n2=20&n3=30'
/// {"result":60}
ClassMethod TestGETRestParametersSum(n... As %String) As %Integer
{
  set sum = 0
  for i=1:1:n  set sum = sum + n(i)
  return sum
}

/// curl -H "Content-Type: application/json" -X POST -d '{"username":"xyz","password":"xyz"}' 'http://localhost:57772/api/frontier/test/mixed/rest?n1=10&n2=20&msg=hello'
/// {"sum":30,"data":{"username":"xyz","password":"xyz"},"params":["10","20"],"msg":"hello"}}
ClassMethod TestPOSTMixedRestParametersSum(msg As %String, data As %DynamicObject, n... As %Integer) As %DynamicObject
{
 
  set parameters = []  
  set sum = 0
  for i=1:1:n  set sum = sum + n(i) do parameters.%Push(n(i))
  return {
    "sum": (sum),
    "data": (data),
    "params": (parameters),
    "msg": (msg)
  }
  return sum
}

/// curl -H "Content-Type: application/json" -X POST -d '{"username":"xyz","password":"xyz"}' 'http://localhost:57772/api/frontier/test/payload/single_object'
/// {"username":"xyz","password":"xyz"}
ClassMethod TestPOSTObjectPayloadSingle(payload As %DynamicObject) As %DynamicObject
{
  return payload
}

/// curl -H "Content-Type: application/json" -X POST -d '{"username":"xyz","password":"xyz"}' 'http://localhost:57772/api/frontier/test/payload/object_with_query_params?msg=hello'
ClassMethod TestPOSTObjectPayloadQueryParams(msg As %String = "", payload As %DynamicObject) As %Status
{
  return {
    "msg": (msg),
    "payload": (payload)
  }
}

/// curl -H "Content-Type: application/json" -X POST -d '[{"username":"xyz","password":"xyz"}]' 'http://localhost:57772/api/frontier/test/payload/single_array'
ClassMethod TestPOSTArrayPayloadSingle(payload As %DynamicArray) As %DynamicObject
{
  return payload
}

/// curl -H "Content-Type: application/json" -X POST -d '[{"username":"xyz","password":"xyz"}]' 'http://localhost:57772/api/frontier/test/payload/array_with_query_params?msg=hello'
ClassMethod TestPOSTArrayPayloadQueryParams(payload As %DynamicObject, msg As %String = "") As %DynamicArray
{
  return [ (msg), (payload) ]
}

/// curl -H "Content-Type: application/json" -X POST -d '[{"username":"xyz","password":"xyz"}]' 'http://localhost:57772/api/frontier/test/payload/invalid'
ClassMethod TestPOSTInvalidPayload(payloadA As %DynamicArray, payloadB As %DynamicObject) As %DynamicArray
{
  return payloadA
}

/// curl -H "Content-Type: application/json" http://localhost:57772/api/frontier/test/mixed/object?class=1
ClassMethod TestGETMixedDynamicObject(class As Frontier.UnitTest.Fixtures.Class) As %DynamicObject
{
  return {
    "class": (class)
  }
}

/// curl -H "Content-Type: application/json" http://localhost:57772/api/frontier/test/mixed/array?class=1
ClassMethod TestGETMixedDynamicArray(class As Frontier.UnitTest.Fixtures.Class) As %DynamicArray
{
  return [ (class) ]
}

ClassMethod TestGETRawMode() As %String
{
  do %frontier.Raw()
  return "hello raw response"
}

ClassMethod TestGETMixedSQL(page As %Integer = 1, rows As %Integer = 5) As Frontier.SQL.Provider
{
  set offset = (page * rows) - (rows - 1)
  set limit = page * rows
  
  set students = %frontier.SQL.Prepare(
    "SELECT *, %VID as Index FROM (SELECT * FROM FRONTIER_UNITTEST_FIXTURES.STUDENT) WHERE %VID BETWEEN ? AND ?"
  ).Parameters(offset, limit)
  
  set str = ##class(%Stream.GlobalCharacter).%New()
  do str.Write("Hello, this is a test using stream properties.")
  
  return {
    // Stream data.
    "str": (str),
    // SQL result data. 
    "students": (students),
    // Student instance. 
    "student": (##class(Frontier.UnitTest.Fixtures.Student).%OpenId(1))
  }
}

}

