Class UnitTest.Frontier.Router Extends Port.UnitTest.TestCase
{

Parameter TESTSERVER = "localhost";

Parameter TESTSERVERPORT = 57772;

Property Request As %Net.HttpRequest;

Property Class As Frontier.UnitTest.Fixtures.Class;

Property Student As Frontier.UnitTest.Fixtures.Student;

Property WebApplicationName As %String [ InitialExpression = {$e(##class(Frontier.UnitTest.WebApplicationInstaller).#NAME, 2, *)} ];

Method OnBeforeAllTests() As %Status
{
  
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

Method OnAfterAllTests() As %Status
{
  return $$$OK
}

Method AssertRequest(resource As %String, expected As %DynamicAbstractObject = "", method As %String = "GET", payload As %DynamicAbstractObject = "", authHeader As %String = "Basic Zm9vOmJhcg==") As %Status
{
   
  if $isobject(payload) {
    $$$QuitOnError(..Request.SetHeader("Content-Type", "application/json; charset=utf-8"))
    $$$QuitOnError(..Request.EntityBody.Write(payload.%ToJSON()))
  }
  
  // Default is Basic foo:bar. Refer to the ValidateCredentials method defined in the Frontier.UnitTest.Router class.
  // There's also an admin:admin account that is used to simulate scope usage.
  $$$QuitOnError(..Request.SetHeader("Authorization", authHeader))
  
  $$$QuitOnError(..Request.Send(method, resource))
  set response = ..Request.HttpResponse.Data
  set responseText = response.Read()
  set expectedText = expected
  
  set firstByte = $extract(responseText)
  
  if $extract(firstByte)?1(1"{",1"[") {
    set response = ##class(%DynamicObject).%FromJSON(responseText)    
    if $isobject(response) {
      if ##class(Frontier.Types).IsDynamicObject(response) && (response.errors '= ""){        
        return ##class(Frontier.UnitTest.Util).MergeErrors(response.errors)
      } elseif ##class(Frontier.Types).IsDynamic($classname(expected)) {
        $$$QuitOnError(##class(Frontier.Dynamic.Serializer).SerializeToStream(.str, expected))
        set expectedText = str.Read()
      }
    }
  }
  if responseText '= expectedText {
    return $$$ERROR($$$GeneralError, $$$FormatText("The received content mismatches with the expected one: %1%2 '= %3%4", $c(10,13), responseText, $c(10,13), expectedText))
  }  
  
  return $$$OK
}

Method TestGETRouteParams()
{
  set resource = $$$FormatText("%1route_params/%2", ..WebApplicationName, ..Class.%Id())
  do ##class(Frontier.Dynamic.Marshaller).Marshall(..Class, .expected)
  return $$$AssertStatusOK(..AssertRequest(resource, expected), $$$FormatText("can retrieve the expected data from the resource %1", resource))
}

Method TestGETOneQueryParameter()
{
  set expected = { "result": "hello" }  
  set resource = $$$FormatText("%1query_params?msg=%2", ..WebApplicationName, "hello")
  return $$$AssertStatusOK(..AssertRequest(resource, expected), $$$FormatText("can retrieve the expected data from the resource %1", resource))
}

Method TestGETRestParametersSum()
{
  set expected = { "result": 60 }
  set resource = $$$FormatText("%1rest_params?n1=10&n2=20&n3=30", ..WebApplicationName)
  return $$$AssertStatusOK(..AssertRequest(resource, expected), $$$FormatText("can retrieve the expected data from the resource %1", resource))
}

Method TestPOSTMixedRestParametersSum()
{
  set resource = $$$FormatText("%1mixed/rest?n1=10&n2=20&msg=hello", ..WebApplicationName)
  set payload = {"username":"xyz","password":"xyz"}
  set expected = {"sum":30,"data":{"username":"xyz","password":"xyz"},"params":["10","20"],"msg":"hello"}
  return $$$AssertStatusOK(..AssertRequest(resource, expected, "POST", payload), $$$FormatText("can retrieve the expected data from the resource %1", resource))
}

Method TestPOSTObjectPayloadSingle()
{
  set resource = $$$FormatText("%1payload/single_object", ..WebApplicationName)
  set payload = {"username":"xyz","password":"xyz"}
  set expected = payload
  return $$$AssertStatusOK(..AssertRequest(resource, expected, "POST", payload), $$$FormatText("can retrieve the expected data from the resource %1", resource))
}

Method TestPOSTObjectPayloadQueryParams()
{
  set resource = $$$FormatText("%1payload/object_with_query_params?msg=hello", ..WebApplicationName)
  set payload = {"username":"xyz","password":"xyz"}
  set expected = {"msg":"hello","payload":(payload)}
  return $$$AssertStatusOK(..AssertRequest(resource, expected, "POST", payload), $$$FormatText("can retrieve the expected data from the resource %1", resource))
}

Method TestPOSTArrayPayloadSingle()
{
  set resource = $$$FormatText("%1payload/single_array", ..WebApplicationName)
  set payload = [{"password":"xyz","username":"xyz"}]
  set expected = payload
  return $$$AssertStatusOK(..AssertRequest(resource, expected, "POST", payload), $$$FormatText("can retrieve the expected data from the resource %1", resource))
}

Method TestPOSTArrayPayloadQueryParams()
{
  set resource =  $$$FormatText("%1payload/array_with_query_params?msg=hello", ..WebApplicationName)
  set payload = [{"password":"xyz","username":"xyz"}]
  set expected = ["hello",(payload)]
  return $$$AssertStatusOK(..AssertRequest(resource, expected, "POST", payload), $$$FormatText("can retrieve the expected data from the resource %1", resource))
}

Method TestPOSTInvalidPayload()
{
  set resource =  $$$FormatText("%1payload/invalid", ..WebApplicationName)
  set payload = [{"username":"xyz","password":"xyz"}]
  return $$$AssertStatusNotOK(..AssertRequest(resource, "" /* we're expecting an error */, "POST", payload), "returns an error if more than one payload is formally expected")
}

Method TestGETInvalidRestSequence()
{
  set resource =  $$$FormatText("%1rest_params?n1=&n4=10", ..WebApplicationName)
  return $$$AssertStatusNotOK(..AssertRequest(resource, "" /* we're expecting an error */), "returns an error if rest argument index is not sequential")
}

Method TestGETUnspecifiedArgument()
{
  set resource = $$$FormatText("%1query_params?unknown=1", ..WebApplicationName)
  return $$$AssertStatusNotOK(..AssertRequest(resource, "" /* we're expecting an error */), "returns an error if an unknown argument is provided")
}

Method TestGETMixedDynamicObject()
{
  set resource = $$$FormatText("%1mixed/object?class=1", ..WebApplicationName)
  do ##class(Frontier.Dynamic.Marshaller).Marshall(..Class, .class)
  set expected = {"class":(class)}
  return $$$AssertStatusOK(..AssertRequest(resource, expected), $$$FormatText("can retrieve the expected data from the resource %1", resource))
}

Method TestGETMixedDynamicArray()
{
  set resource = $$$FormatText("%1mixed/array?class=1", ..WebApplicationName)
  do ##class(Frontier.Dynamic.Marshaller).Marshall(..Class, .class)
  set expected = [ (class) ]
  return $$$AssertStatusOK(..AssertRequest(resource, expected), $$$FormatText("can retrieve the expected data from the resource %1", resource))
}

Method TestGETRawMode()
{
  set resource = $$$FormatText("%1raw", ..WebApplicationName)
  set expected = "hello raw response"
  return $$$AssertStatusOK(..AssertRequest(resource, expected), $$$FormatText("can retrieve the expected data from the resource %1", resource))
}

Method TestGETStream()
{
  set resource = $$$FormatText("%1stream", ..WebApplicationName)
  set expected = {"content":"This line is from a stream."}
  return $$$AssertStatusOK(..AssertRequest(resource, expected), $$$FormatText("can retrieve the expected data from the resource %1", resource))
}

Method TestGETAliasedQueryParameter()
{
  set resource = $$$FormatText("%1alias?aliased_key=whatever", ..WebApplicationName)
  set expected = {"result":"whatever"}
  return $$$AssertStatusOK(..AssertRequest(resource, expected), $$$FormatText("can retrieve the expected data from the resource %1", resource))
}

Method TestGETDynamicSQLResult()
{
  set resource = $$$FormatText("%1sql/dynamic", ..WebApplicationName)
  
  set sd = ##class(%SQL.Statement).%New()
  set sd.%SelectMode = 2
  do sd.%Prepare("SELECT *, %VID as Index FROM (SELECT * FROM FRONTIER_UNITTEST_FIXTURES.STUDENT) WHERE %VID BETWEEN ? AND ?")
  set rd = sd.%Execute(1, 5)
  
  do $$$AssertStatusOK(##class(Frontier.UnitTest.Util).MarshallSQLResult(rd, .array), "can read SQL result")
  set expected = {"results":(array)}
  return $$$AssertStatusOK(..AssertRequest(resource, expected.%ToJSON()), $$$FormatText("can retrieve the expected data from the resource %1", resource))
}

Method TestGETQuerySQLResult()
{
  set resource = $$$FormatText("%1sql/query", ..WebApplicationName)
  
  set sd = ##class(%SQL.Statement).%New()
  set sd.%SelectMode = 2
  do sd.%PrepareClassQuery("Frontier.UnitTest.Fixtures.Student", "PaginatedStudents")
  set rd = sd.%Execute(1, 5)
  
  do $$$AssertStatusOK(##class(Frontier.UnitTest.Util).MarshallSQLResult(rd, .array), "can read SQL result")
  set expected = {"results":(array)}
  return $$$AssertStatusOK(..AssertRequest(resource, expected.%ToJSON()), $$$FormatText("can retrieve the expected data from the resource %1", resource))
}

Method TestGETRouteParameterNotSpecified()
{
  set resource = $$$FormatText("%1map/A/1/route-parameter-not-specified", ..WebApplicationName)
  set expected = {"error":{"internalCode":5001,"message":"Route parameter 'param1' was not specified as an argument on the receiving method 'TestGETRouteParameterNotSpecified'.","responseCode":500}}
  return $$$AssertStatusOK(..AssertRequest(resource, expected), $$$FormatText("can retrieve the expected data from the resource %1", resource))
}

Method TestGETPassRouteParamToChild()
{
  set resource = $$$FormatText("%1map/A/hello-from-parent/pass-route-param-to-child", ..WebApplicationName)
  set expected = {"result":"hello-from-parent"}
  return $$$AssertStatusOK(..AssertRequest(resource, expected), $$$FormatText("can retrieve the expected data from the resource %1", resource))
}

Method TestGETPrioritizeRouteParameter()
{
  set resource = $$$FormatText("%1map/A/hello-from-route/prioritize-route-parameter?param1=hello_from_query", ..WebApplicationName)
  set expected = {"result":"hello-from-route"}
  return $$$AssertStatusOK(..AssertRequest(resource, expected), $$$FormatText("can retrieve the expected data from the resource %1", resource))
}

Method TestGETRouteWithoutParameters()
{
  set resource = $$$FormatText("%1map/C/", ..WebApplicationName)
  set expected = {"result":"Hello from a simple but mapped route!"}
  return $$$AssertStatusOK(..AssertRequest(resource, expected), $$$FormatText("can retrieve the expected data from the resource %1", resource))
}

Method TestGETScopedResponse()
{
  set resource = $$$FormatText("%1map/C/scoped", ..WebApplicationName)
  set expected = {"result":"Hello admin! If you're seeing this, then you have enough privilege for it!"}
  return $$$AssertStatusNotOK(..AssertRequest(resource, expected), $$$FormatText("can NOT retrieve the expected data from the resource %1 because it's scoped", resource))
  return $$$AssertStatusOK(..AssertRequest(resource, expected,,,"Basic "_$System.Encryption.Base64Encode("admin:admin")), $$$FormatText("can retrieve the expected data from the resource %1", resource))
}

Method TestGETBypassAuth()
{
  set resource = $$$FormatText("%1map/C/auth/bypass", ..WebApplicationName)
  set expected = {"result":"This is an unprotected resource!"}
  return $$$AssertStatusOK(..AssertRequest(resource, expected), $$$FormatText("can retrieve the expected data from the resource %1", resource))
}

Method TestGETCalculateResult()
{
  set resource = $$$FormatText("%1map/D/5/fixed/3/calc/sum", ..WebApplicationName)
  set expected = {"result":8}
  return $$$AssertStatusOK(..AssertRequest(resource, expected), $$$FormatText("can retrieve the expected data from the resource %1", resource))
}

ClassMethod T()
{
  set sc = ##class(Frontier.Schema.Util).Parse("API.Mobile.Accounts", .r)
  set sc = ##class(Frontier.Schema.Util).GeneratePatterns(r, "Frontier.UnitTest.Router",.p)
  return sc
}

}

