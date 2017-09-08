Class Frontier.UnitTest.Router Extends Frontier.Router
{

XData UrlMap [ XMLNamespace = "http://github.com/rfns/frontier" ]
{
<Routes>
  <Route Url="/route_params/:class" Method="GET" Call="TestGETRouteParams"/>
  <Route Url="/query_params" Method="GET" Call="TestGETOneQueryParameter"/>
  <Route Url="/rest_params" Method="GET" Call="TestGETRestParametersSum"/>
  <Route Url="/sql/dynamic" Method="GET" Call="TestGETDynamicSQLResult"/>
  <Route Url="/sql/query" Method="GET" Call="TestGETQuerySQLResult"/>
  <Route Url="/raw" Method="GET" Call="TestGETRawMode"/>
  <Route Url="/shared_data" Method="GET" Call="TestGETData"/>
  <Route Url="/stream" Method="GET" Call="TestGETStream"/>
  <Route Url="/payload/single_object" Method="POST" Call="TestPOSTObjectPayloadSingle"/>
  <Route Url="/payload/object_with_query_params" Method="POST" Call="TestPOSTObjectPayloadQueryParams"/>  
  <Route Url="/payload/single_array" Method="POST" Call="TestPOSTArrayPayloadSingle"/>
  <Route Url="/payload/array_with_query_params" Method="POST" Call="TestPOSTArrayPayloadQueryParams"/>
  <Route Url="/payload/invalid" Method="POST" Call="TestPOSTInvalidPayload"/>
  <Route Url="/mixed/object" Method="GET" Call="TestGETMixedDynamicObject"/>
  <Route Url="/mixed/array" Method="GET" Call="TestGETMixedDynamicArray"/>
  <Route Url="/mixed/rest" Method="POST" Call="TestPOSTMixedRestParametersSum"/>
 </Routes>
}

/// If you need to share something between methods. You can use this method to populate %frontier.Data.
ClassMethod OnReceivingData() As %DynamicObject
{
  return {
    "Message": "This 'Message' is shared between all methods."
  }
}

/// Whenever a parameter is typed of %Persistent and a valid id is provided, the parameter will be instantiated.
/// Call example:
/// curl -H "Content-Type: application/json" 'localhost:57772/api/frontier/test/route_params/6' 
/// {"Plate":"O5397","Students":[{"Name":"Drabek,Peter T.","__id__":"20"}],"__id__":"6"}
ClassMethod TestGETRouteParams(class As Frontier.UnitTest.Fixtures.Class) As %Status
{
  return class
}

/// Query parameters are also supported. And are fetch if the parameter name matches the URL query name.
/// Call example:
/// curl -H "Content-Type: application/json" 'localhost:57772/api/frontier/test/query_params?msg=hello'
/// {result":"hello"}
ClassMethod TestGETOneQueryParameter(msg As %String) As %String
{
  
  return "hello"
}

/// Rest parameters are sequential query parameters. They can have flexible arity and have the format parameterN.
/// This request takes that number of parameters and sum them.
/// Call example:
/// curl -H "Content-Type: application/json" 'localhost:57772/api/frontier/test/rest_params?n1=10&n2=20&n3=30'
ClassMethod TestGETRestParametersSum(n... As %String) As %Integer
{
  set sum = 0
  for i=1:1:n  set sum = sum + n(i)
  return sum
}

/// Support of SQL is implemented as well. This example demonstrates how easy it's to create a paginated query.
/// For SQL, the usage of of Prepare() from frontier.SQL API is required.
ClassMethod TestGETDynamicSQLResult(page As %Integer = 1, rows As %Integer = 5) As Frontier.SQL.Provider
{
  set offset = (page * rows) - (rows - 1)
  set limit = page * rows
  
  return %frontier.SQL.Prepare(
    "SELECT *, %VID as Index FROM (SELECT * FROM FRONTIER_UNITTEST_FIXTURES.STUDENT) WHERE %VID BETWEEN ? AND ?"
  ).Parameters(offset, limit)
}

/// Support of SQL is implemented as well. This example demonstrates how easy it's to create a paginated query.
/// For SQL, the usage of of Prepare() from frontier.SQL API is required.
ClassMethod TestGETQuerySQLResult(page As %Integer = 1, rows As %Integer = 5) As Frontier.SQL.Provider
{
  set offset = (page * rows) - (rows - 1)
  set limit = page * rows
  
  return %frontier.SQL.Prepare("Frontier.UnitTest.Fixtures.Student:PaginatedStudents").Parameters(offset, limit)
}

/// There can be cases where the response should not be a JSON.
/// This method shows how to output a text in plain format.
/// Call example:
/// curl -H "Content-Type: application/json" http://localhost:57772/api/frontier/test/raw
ClassMethod TestGETRawMode() As %String
{
  do %frontier.Raw()
  return "hello raw response"
}

/// This method uses the data object provided on OnReceivingData method.
/// The idea is to demonstrate how to access shared data.
/// Call example: 
/// /// curl -H "Content-Type: application/json" 'localhost:57772/api/frontier/test/shared_data' 
ClassMethod TestGETData() As %DynamicObject
{
  return %frontier.Data
}

/// Streams can be serialized as well.
ClassMethod TestGETStream() As %Stream.Object
{
  set stream = ##class(%Stream.GlobalCharacter).%New()
  do stream.Write("This line is from a stream.")
  
  return stream
}

/// If the request is a POST/PUT/PATCH method, it can receive a payload that's represented by a parameter typed of %DynamicObject instances.
/// Call example:
/// curl -H "Content-Type: application/json" -X POST -d '{"username":"xyz","password":"xyz"}' 'http://localhost:57772/api/frontier/test/payload/single_object'
ClassMethod TestPOSTObjectPayloadSingle(payload As %DynamicObject) As %DynamicObject
{
  return payload
}

/// Request can have a payload along with a query parameter.
/// curl -H "Content-Type: application/json" -X POST -d '{"username":"xyz","password":"xyz"}' 'http://localhost:57772/api/frontier/test/payload/object_with_query_params?msg=hello'
ClassMethod TestPOSTObjectPayloadQueryParams(msg As %String = "", payload As %DynamicObject) As %Status
{
  return {
    "msg": (msg),
    "payload": (payload)
  }
}

/// Payloads can also be an array.
/// Call example:
/// curl -H "Content-Type: application/json" -X POST -d '[{"username":"xyz","password":"xyz"}]' 'http://localhost:57772/api/frontier/test/payload/single_array'
ClassMethod TestPOSTArrayPayloadSingle(payload As %DynamicArray) As %DynamicObject
{
  return payload
}

/// Requests with array payloads also support query parameters.
/// Call example:
/// curl -H "Content-Type: application/json" -X POST -d '[{"username":"xyz","password":"xyz"}]' 'http://localhost:57772/api/frontier/test/payload/array_with_query_params?msg=hello'
ClassMethod TestPOSTArrayPayloadQueryParams(payload As %DynamicObject, msg As %String = "") As %DynamicArray
{
  return [ (msg), (payload) ]
}

/// This demonstrates payload validation, as browsers can receive one payload per request
/// a classmethod that expects more than one is considered invalid and will throw an exception.
/// curl -H "Content-Type: application/json" -X POST -d '[{"username":"xyz","password":"xyz"}]' 'http://localhost:57772/api/frontier/test/payload/invalid'
ClassMethod TestPOSTInvalidPayload(payloadA As %DynamicArray, payloadB As %DynamicObject) As %DynamicArray
{
  return payloadA
}

/// Normally %Dynamic instances cannot serialize childrens that aren't dynamic as well. (%ToJSON would thrown an exception).
/// Frontier fixes it by marshalling irregular to %Dynamic instances beforehand and making it compatible.
/// Call example:
/// curl -H "Content-Type: application/json" http://localhost:57772/api/frontier/test/mixed/object?class=1
ClassMethod TestGETMixedDynamicObject(class As Frontier.UnitTest.Fixtures.Class) As %DynamicObject
{
  return {
    "class": (class)
  }
}

/// Also supported for %DynamicArray.
/// Call example:
/// curl -H "Content-Type: application/json" http://localhost:57772/api/frontier/test/mixed/array?class=1
ClassMethod TestGETMixedDynamicArray(class As Frontier.UnitTest.Fixtures.Class) As %DynamicArray
{
  return [ (class) ]
}

/// It's possible to mix multiple parameter types as you could when calling a method.
/// The example below illustrates the usage of a method that receives a 'msg' query parameter along with a payload and a rest parameter.
/// Call example:
/// curl -H "Content-Type: application/json" -X POST -d '{"username":"xyz","password":"xyz"}' 'http://localhost:57772/api/frontier/test/mixed/rest?n1=10&n2=20&msg=hello'
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

}

