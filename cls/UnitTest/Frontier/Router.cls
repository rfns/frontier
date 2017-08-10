Class UnitTest.Frontier.Router Extends Port.UnitTest.TestCase
{

Parameter TESTSERVER = "localhost";

Parameter TESTSERVERPORT = 57772;

Property Request As %Net.HttpRequest;

Property Class As Frontier.UnitTest.Fixtures.Class;

Property Student As Frontier.UnitTest.Fixtures.Student;

Method OnAfterAllTests() As %Status
{
  $$$QuitOnError(##class(Frontier.UnitTest.Fixtures.Class).%KillExtent())
  return ##class(Frontier.UnitTest.Fixtures.Student).%KillExtent()
}

Method OnBeforeAllTests() As %Status
{
  do ##class(Frontier.UnitTest.Fixtures.Class).Populate()
  do ##class(Frontier.UnitTest.Fixtures.Student).Populate()
  
  &sql(SELECT TOP 1 ID INTO :classId FROM FRONTIER_UNITTEST_FIXTURES.CLASS)
  &sql(SELECT TOP 1 ID INTO :studentId FROM FRONTIER_UNITTEST_FIXTURES.STUDENT)
  
  set ..Class = ##class(Frontier.UnitTest.Fixtures.Class).%OpenId(classId)
  set ..Student = ##class(Frontier.UnitTest.Fixtures.Student).%OpenId(studentId)
  
  return $$$OK
}

Method OnBeforeOneTest() As %Status
{
  set ..Request = ##class(%Net.HttpRequest).%New()
  do ..Request.SetHeader("Content-Type", "application/json; charset=utf-8")
  set ..Request.Server = ..#TESTSERVER
  set ..Request.Port = ..#TESTSERVERPORT
  return $$$OK
}

Method AssertRequest(resource As %String, expected As %DynamicAbstractObject = "", method As %String = "GET", payload As %DynamicAbstractObject = "") As %Status
{
   
  if $isobject(payload) {
    $$$QuitOnError(..Request.SetHeader("Content-Type", "application/json; charset=utf-8"))
    $$$QuitOnError(..Request.EntityBody.Write(payload.%ToJSON()))
  }
  
  $$$QuitOnError(..Request.Send(method, resource))
  
  set response = ##class(%DynamicObject).%FromJSON(..Request.HttpResponse.Data)
  
  if $isobject(response) {
    if response.errors {
      return ##class(Frontier.UnitTest.Util).MergeErrors(response.errors)
    } else {
      set responseText = response.%ToJSON()
      set expectedText = expected.%ToJSON()
      if responseText '= expectedText {
        return $$$ERROR($$$GeneralError, $$$FormatText("The received content mismatches with the expected one: %1 '= %2", responseText, expectedText))
      }
    }
  }
  return $$$OK
}

Method TestGETRouteParams()
{
  set resource = "api/frontier/test/route_params/"_..Class.%Id()  
  do ##class(Frontier.Dynamic.Marshaller).Marshall(..Class, .expected)
  return $$$AssertStatusOK(..AssertRequest(resource, expected), $$$FormatText("can retrieve the expected data from the resource %1", resource))
}

Method TestGETOneQueryParameter()
{
  set expected = { "result": "hello" }  
  set resource = "api/frontier/test/query_params?msg=hello"  
  return $$$AssertStatusOK(..AssertRequest(resource, expected), $$$FormatText("can retrieve the expected data from the resource %1", resource))
}

Method TestGETRestParametersSum()
{
  set expected = { "result": 60 }
  set resource = "api/frontier/test/rest_params?n1=10&n2=20&n3=30"  
  return $$$AssertStatusOK(..AssertRequest(resource, expected), $$$FormatText("can retrieve the expected data from the resource %1", resource))
}

Method TestPOSTMixedRestParametersSum()
{
  set resource = "api/frontier/test/mixed/rest?n1=10&n2=20&msg=hello"
  set payload = {"username":"xyz","password":"xyz"}
  set expected = {"sum":30,"data":{"username":"xyz","password":"xyz"},"params":["10","20"],"msg":"hello"}
  return $$$AssertStatusOK(..AssertRequest(resource, expected, "POST", payload), $$$FormatText("can retrieve the expected data from the resource %1", resource))
}

Method TestPOSTObjectPayloadSingle()
{
  set resource = "api/frontier/test/payload/single_object"
  set payload = {"username":"xyz","password":"xyz"}
  set expected = payload
  return $$$AssertStatusOK(..AssertRequest(resource, expected, "POST", payload), $$$FormatText("can retrieve the expected data from the resource %1", resource))
}

Method TestPOSTObjectPayloadQueryParams()
{
  set resource = "api/frontier/test/payload/object_with_query_params?msg=hello"
  set payload = {"username":"xyz","password":"xyz"}
  set expected = {"msg":"hello","payload":(payload)}
  return $$$AssertStatusOK(..AssertRequest(resource, expected, "POST", payload), $$$FormatText("can retrieve the expected data from the resource %1", resource))
}

Method TestPOSTArrayPayloadSingle()
{
  set resource = "api/frontier/test/payload/single_array"
  set payload = [{"password":"xyz","username":"xyz"}]
  set expected = {"result":(payload)}
  return $$$AssertStatusOK(..AssertRequest(resource, expected, "POST", payload), $$$FormatText("can retrieve the expected data from the resource %1", resource))
}

Method TestPOSTArrayPayloadQueryParams()
{
  set resource = "api/frontier/test/payload/array_with_query_params?msg=hello"
  set payload = [{"password":"xyz","username":"xyz"}]
  set expected = {"result":["hello",(payload)]}
  return $$$AssertStatusOK(..AssertRequest(resource, expected, "POST", payload), $$$FormatText("can retrieve the expected data from the resource %1", resource))
}

Method TestPOSTInvalidPayload()
{
  set resource = "api/frontier/test/payload/invalid"
  set payload = [{"username":"xyz","password":"xyz"}]
  return $$$AssertStatusNotOK(..AssertRequest(resource, "" /* we're expecting an error */, "POST", payload), "returns an error if more than one payload is formally expected")
}

Method TestGETInvalidRestSequence()
{
  set resource = "api/frontier/test/rest_params?n1=&n4=10"
  return $$$AssertStatusNotOK(..AssertRequest(resource, "" /* we're expecting an error */), "returns an error if rest argument index is not sequential")
}

Method TestGETUnspecifiedArgument()
{
  set resource = "api/frontier/test/query_params?unknown=1"
  return $$$AssertStatusNotOK(..AssertRequest(resource, "" /* we're expecting an error */), "returns an error if an unknown argument is provided")
}

Method TestGETMixedDynamicObject()
{
  set resource = "http://localhost:57772/api/frontier/test/mixed/object?class=1"
  do ##class(Frontier.Dynamic.Marshaller).Marshall(..Class, .class)
  set expected = {"class":(class)}
  return $$$AssertStatusOK(..AssertRequest(resource, expected), $$$FormatText("can retrieve the expected data from the resource %1", resource))
}

Method TestGETMixedDynamicArray()
{
  set resource = "api/frontier/test/mixed/array?class=1"
  do ##class(Frontier.Dynamic.Marshaller).Marshall(..Class, .class)
  set expected = {"result":[(class)]}
  return $$$AssertStatusOK(..AssertRequest(resource, expected), $$$FormatText("can retrieve the expected data from the resource %1", resource))
}

}

