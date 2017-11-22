Class Frontier.UnitTest.Router Extends Frontier.Router
{

XData UrlMap [ XMLNamespace = "http://github.com/rfns/frontier" ]
{
<Routes>
<Route Url="/route-params/:class" Method="GET" Call="TestGETRouteParams"/>
<Route Url="/query-params" Method="GET" Call="TestGETOneQueryParameter"/>
<Route Url="/rest-params" Method="GET" Call="TestGETRestParametersSum"/>
<Route Url="/sql/dynamic" Method="GET" Call="TestGETDynamicSQLResult"/>
<Route Url="/sql/query" Method="GET" Call="TestGETQuerySQLResult"/>
<Route Url="/raw" Method="GET" Call="TestGETRawMode"/>
<Route Url="/shared_data" Method="GET" Call="TestGETData"/>
<Route Url="/stream" Method="GET" Call="TestGETStream"/>
<Route Url="/alias" Method="GET" Call="TestGETAliasedQueryParameter"/>
<Route Url="/payload/single-object" Method="POST" Call="TestPOSTObjectPayloadSingle"/>
<Route Url="/payload/object-with-query-params" Method="POST" Call="TestPOSTObjectPayloadQueryParams"/>  
<Route Url="/payload/single-array" Method="POST" Call="TestPOSTArrayPayloadSingle"/>
<Route Url="/payload/array-with-query-params" Method="POST" Call="TestPOSTArrayPayloadQueryParams"/>
<Route Url="/payload/invalid" Method="POST" Call="TestPOSTInvalidPayload"/>
<Route Url="/mixed/object" Method="GET" Call="TestGETMixedDynamicObject"/>
<Route Url="/mixed/array" Method="GET" Call="TestGETMixedDynamicArray"/>
<Route Url="/mixed/rest" Method="POST" Call="TestPOSTMixedRestParametersSum"/>
<Route Url="/unmarshall" Method="POST" Call="TestPOSTUnmarshallToClass"/>
<Route Url="/unmarshall/:classId" Method="PUT" Call="TestPUTUnmarshallToClass"/>
<Route Url="/user-info" Method="GET" Call="TestGETSessionUserInfo"/>
<Map Prefix="/map/A/:param1" Forward="Frontier.UnitTest.Router.Map.A" />
<Map Prefix="/map/B/:param1/:param2" Forward="Frontier.UnitTest.Router.Map.B" />
<Map Prefix="/map/C" Forward="Frontier.UnitTest.Router.Map.C" />
<Map Prefix="/map/D/:paramA/fixed/:paramB" Forward="Frontier.UnitTest.Router.Map.D"/> 
<Map Prefix="/map/E/(match)" Strict="false" Forward="Frontier.UnitTest.Router.Map.E"/>
</Routes>
}

/// Use this method to share data between methods.
ClassMethod OnDataSet(data As %DynamicObject) As %Status
{
  /// This 'data' object is shared between all methods. Accessible using %frontier.Data.
  set data.Message = "This 'Message' is shared between all methods."
  return $$$OK
}

/// This method is reserved for setting up configurations.
ClassMethod OnSetup() As %Status
{
 
  // Reporters should be used to signal the developer about request errors.   
  // $$$QuitOnError(%frontier.ReporterManager.AddReporter(##class(MyReporter.Email).%New()))  
  
  // Asks the user for a Basic + Base64(username:password) encoded Authorization header.
  set basicStrategy = ##class(Frontier.Authentication.BasicStrategy).%New({
    "realm": "tests", 
    "validator": ($classname()_":ValidateCredentials"),
    "required": true
  })
  
  // This provides a way to check if the current user is authenticated using Basic scheme.
  $$$QuitOnError(%frontier.AuthenticationManager.AddStrategy(basicStrategy)) 
    
  
  return $$$OK
}

/// Whenever a parameter is typed of %Persistent and a valid id is provided, the parameter will be instantiated.
/// Call example:
/// curl -H "Content-Type: application/json" 'localhost:57772/api/frontier/test/route-params/6' 
/// {"Plate":"O5397","Students":[{"Name":"Drabek,Peter T.","__id__":"20"}],"__id__":"6"}
ClassMethod TestGETRouteParams(class As Frontier.UnitTest.Fixtures.Class) As %Status
{
  return class
}

/// Query parameters are also supported and are fetched if the parameter name matches the URL query name.
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

/// Dynamic SQL queries can be returned as long as the Frontier SQL API is used.
/// For SQL, the usage of Prepare() from frontier.SQL API is required.
/// Call example:
/// curl -H "Content-Type: application/json" 'http://localhost:57772/api/frontier/test/sql/dynamic?page=1&rows=5'
ClassMethod TestGETDynamicSQLResult(page As %Integer = 1, rows As %Integer = 5) As Frontier.SQL.Provider
{
  set offset = (page * rows) - (rows - 1)
  set limit = page * rows
  
  return %frontier.SQL.Prepare(
    "SELECT *, %VID as Index FROM (SELECT * FROM FRONTIER_UNITTEST_FIXTURES.STUDENT) WHERE %VID BETWEEN ? AND ?"
  ).Parameters(offset, limit).Mode(2)
}

/// The same applies for named (cached) SQL queries. Notice that they can be called by providing
/// the class:queryname instead of a dynamic SQL.
/// curl -H "Content-Type: application/json" 'http://localhost:57772/api/frontier/test/sql/query?page=1&rows=5'
ClassMethod TestGETQuerySQLResult(page As %Integer = 1, rows As %Integer = 5) As Frontier.SQL.Provider
{
  set offset = (page * rows) - (rows - 1)
  set limit = page * rows     
    
  return %frontier.SQL.Prepare("Frontier.UnitTest.Fixtures.Student:PaginatedStudents").Parameters(offset, limit).Mode(2)
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

/// This method uses the data object provided on Setup method.
/// The idea is to demonstrate how to access shared data.
/// Call example: 
/// /// curl -H "Content-Type: application/json" 'localhost:57772/api/frontier/test/shared_data' 
ClassMethod TestGETData() As %DynamicObject
{
  return %frontier.Data
}

/// This method demonstrates how %Stream.Object based instances are treated.
/// Call example: 
/// curl -H "Content-Type: application/json" 'http://localhost:57772/api/frontier/test/stream'
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
/// Call example:
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

/// For compability with existing clients that use query parameters with symbols. For such cases
/// ALIAS can be used to make it compatible. If the expected alias is not found then Frontier will 
/// fall back to using the argument name instead.
ClassMethod TestGETAliasedQueryParameter(msg As %String(ALIAS="aliased_key"))
{
  return msg
}

/// It's also possible to save from a payload directly to a %Persistent instance as long as the payload
/// has the same format as the %Persistent class. Just define the the parameter UNMARSHALLTO with the class you want
/// curl -H "Content-Type: application/json" -X POST -d '{"Plate": "R-2948","Students": [{"Name": "Rubens","BirthDate": "04/21/1970","SomeValue": 0}]}' 'http://localhost:57772/api/frontier/unmarshall'
ClassMethod TestPOSTUnmarshallToClass(class As %DynamicObject(UNMARSHALLTO="Frontier.UnitTest.Fixtures.Class")) As Frontier.UnitTest.Fixtures.Student
{
  $$$ThrowOnError(class.%Save())
  return {
    "ok": 1,
    "__id__": (class.%Id())
  }
}

/// You can also edit the entity just by providing the property "__id__" along with the new payload data. If you want the id to be read from the URL,
/// add a new parameter and map the unmarshaller to use it as id by specifying the IDCOLUMN. If the named IDCOLUMN is not
/// found, the id will be searched inside the payload. Note that when the id is not found, an exception will be thrown regarding  the
/// incorrect PUT usage.
/// curl -H "Content-Type: application/json" -X POST -d '{"Plate": "R-2948","Students": [{"Name": "Rubens","BirthDate": "04/21/1970","SomeValue": 0}]}' 'http://localhost:57772/api/frontier/unmarshall/15'
ClassMethod TestPUTUnmarshallToClass(class As %DynamicObject(UNMARSHALLTO="Frontier.UnitTest.Fixtures.Class",IDFROM="classId"), classId As %Integer) As Frontier.UnitTest.Fixtures.Student
{
  $$$ThrowOnError(class.%Save())
  return {
    "ok": 1,
    "__id__": (class.%Id())
  }
}

/// This method depends on the authorization header sent by the client and validated with the validator method.
/// The validator method is also responsible for defining the user object.
/// Call example:
/// curl -H "Authorization: Basic Zm9vOmJhcg==" 'http://localhost:57772/api/frontier/test/user'
ClassMethod TestGETSessionUserInfo() As %Status
{
  return %frontier.User
}

ClassMethod ValidateCredentials(login As %String, password As %String, found As %Boolean = 1, Output httpStatus As %String, Output user As %DynamicObject) As %Status
{
  set useScope = 0
  if login = "foo" && (password = "bar") set found = 1  
  if login = "admin" && (password = "admin") set found = 1 set useScope = 1
  if found set httpStatus = ..#HTTP200OK
  else  set httpStatus = ..#HTTP403FORBIDDEN
  
  set user = { 
    "login": (login)
  }
  
  if useScope {
    set user.scope = "admin"
  }
  return $$$OK
}

}

