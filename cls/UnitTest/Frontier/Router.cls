Class UnitTest.Frontier.Router Extends Port.UnitTest.TestCase
{

Parameter TESTSERVER = "localhost";

Parameter TESTSERVERPORT = 57772;

Property Request As %Net.HttpRequest;

Property Class As Frontier.UnitTest.Fixtures.Class;

Property Student As Frontier.UnitTest.Fixtures.Student;

Property WebApplicationName As %String [ InitialExpression = {$e(##class(Frontier.UnitTest.WebApplicationInstaller).#NAME, 2, *)} ];

Property Agent As Forgery.Agent;

Method OnBeforeAllTests() As %Status [ PublicList = %session ]
{
  do ##class(Frontier.UnitTest.Fixtures.Student).%DeleteExtent()
  do ##class(Frontier.UnitTest.Fixtures.Class).%DeleteExtent()

  do ##class(Frontier.UnitTest.Fixtures.Student).Populate()
  do ##class(Frontier.UnitTest.Fixtures.Class).Populate()

  &sql(SELECT TOP 1 ID INTO :classId FROM FRONTIER_UNITTEST_FIXTURES.CLASS)
  &sql(SELECT TOP 1 ID INTO :studentId FROM FRONTIER_UNITTEST_FIXTURES.STUDENT)

  set ..Class = ##class(Frontier.UnitTest.Fixtures.Class).%OpenId(classId)
  set ..Student = ##class(Frontier.UnitTest.Fixtures.Student).%OpenId(studentId)
  set ..Agent = ##class(Forgery.Agent).%New()

  set %session = ##class(%CSP.Session).%New("t3st1ng")

  return $$$OK
}

Method OnAfterAllTests() As %Status [ PublicList = %session ]
{
  kill %session
  do ##class(%File).RemoveDirectoryTree(..GetTestDirectory("../fixtures"))
  return $$$OK
}

Method AssertRequest(resource As %String, expected As %DynamicAbstractObject = "", method As %String = "GET", payload As %DynamicAbstractObject = "", authHeader As %String = "Basic Zm9vOmJhcg==", contentType As %String = "text/plain") As %Status
{

  // Default authHeader is Basic foo:bar. Refer to the ValidateCredentials method defined in the Frontier.UnitTest.Router class.
  // There's also an admin:admin account that is used to simulate scope usage.
  set sc = ..Agent.Request({
    "url": (resource),
    "method": (method),
    "data": (payload),
    "headers": {
      "Authorization": (authHeader),
      "Content-Type": (contentType)
    }
  }, .response)

  $$$QuitOnError(sc)

  set responseText = response.Read()
  set expectedText = expected

  set firstByte = $extract(responseText)

  if $extract(firstByte)?1(1"{",1"[") {
    set response = ##class(%DynamicObject).%FromJSON(responseText)
    if $isobject(response) {
      if ##class(Frontier.Types).IsDynamicObject(response) && (response.errors '= ""){
        return ##class(Frontier.UnitTest.Util).MergeErrors(response.errors)
      } elseif ##class(Frontier.Types).IsDynamic($classname(expected)) {
        $$$QuitOnError(##class(Frontier.Dynamic.Serializer).SerializeToStream(.str, expected,,,,2))
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
  set resource = $$$FormatText("%1route-params/%2", ..WebApplicationName, ..Class.%Id())
  do ##class(Frontier.Dynamic.Marshaller).MarshalDirect(..Class, .expected)
  return $$$AssertStatusOK(..AssertRequest(resource, expected), $$$FormatText("can retrieve the expected data from the resource %1", resource))
}

Method TestGETRouteParamsWhereId()
{
  set resource = $$$FormatText("%1route-params/%2/students/%3", ..WebApplicationName, ..Class.%Id(), ..Student.%Id())
  do ##class(Frontier.Dynamic.Marshaller).MarshalDirect(..Student, .expected)
  return $$$AssertStatusOK(..AssertRequest(resource, expected), $$$FormatText("can retrieve the expected data from the resource %1", resource))
}

Method TestGETOneQueryParameter()
{
  set expected = { "result": "hello" }
  set resource = $$$FormatText("%1query-params?msg=%2", ..WebApplicationName, "hello")
  return $$$AssertStatusOK(..AssertRequest(resource, expected), $$$FormatText("can retrieve the expected data from the resource %1", resource))
}

Method TestGETRestParametersSum()
{
  set expected = { "result": 60 }
  set resource = $$$FormatText("%1rest-params?n1=10&n2=20&n3=30", ..WebApplicationName)
  return $$$AssertStatusOK(..AssertRequest(resource, expected), $$$FormatText("can retrieve the expected data from the resource %1", resource))
}

Method TestPOSTMixedRestParametersSum()
{
  set resource = $$$FormatText("%1mixed/rest?n1=10&n2=20&msg=hello", ..WebApplicationName)
  set payload = {"username":"xyz","password":"xyz"}
  set expected = {"sum":30,"data":{"username":"xyz","password":"xyz"},"params":["10","20"],"msg":"hello"}
  return $$$AssertStatusOK(..AssertRequest(resource, expected, "POST", payload), $$$FormatText("can retrieve the expected data from the resource %1", resource))
}

Method TestPOSTUnmarshalToClass()
{

  &sql(SELECT TOP 1 CAST(ID + 1 as VARCHAR) INTO :classId FROM FRONTIER_UNITTEST_FIXTURES.CLASS ORDER BY ID DESC)

  set resource = $$$FormatText("%1unmarshal", ..WebApplicationName)
  set payload = {"Plate": "R-101-3", "Students": [(..Student.%Id())]}
  set expected = {"ok": 1, "__id__": (classId)}
  set result = ..AssertRequest(resource, expected, "POST", payload)

  return $$$AssertStatusOK(result, $$$FormatText("can unmarshal the payload data to the expected result when POST'ing to %1", resource))
}

Method TestPOSTObjectPayloadSingle()
{
  set resource = $$$FormatText("%1payload/single-object", ..WebApplicationName)
  set payload = {"username":"xyz","password":"xyz"}
  set expected = payload
  return $$$AssertStatusOK(..AssertRequest(resource, expected, "POST", payload), $$$FormatText("can retrieve the expected data from the resource %1", resource))
}

Method TestPOSTObjectPayloadQueryParams()
{
  set resource = $$$FormatText("%1payload/object-with-query-params?msg=hello", ..WebApplicationName)
  set payload = {"username":"xyz","password":"xyz"}
  set expected = {"msg":"hello","payload":(payload)}
  return $$$AssertStatusOK(..AssertRequest(resource, expected, "POST", payload), $$$FormatText("can retrieve the expected data from the resource %1", resource))
}

Method TestPOSTArrayPayloadSingle()
{
  set resource = $$$FormatText("%1payload/single-array", ..WebApplicationName)
  set payload = [{"password":"xyz","username":"xyz"}]
  set expected = payload
  return $$$AssertStatusOK(..AssertRequest(resource, expected, "POST", payload), $$$FormatText("can retrieve the expected data from the resource %1", resource))
}

Method TestPOSTArrayPayloadQueryParams()
{
  set resource =  $$$FormatText("%1payload/array-with-query-params?msg=hello", ..WebApplicationName)
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
  set resource =  $$$FormatText("%1rest-params?n1=&n4=10", ..WebApplicationName)
  return $$$AssertStatusNotOK(..AssertRequest(resource, "" /* we're expecting an error */), "returns an error if rest argument index is not sequential")
}

Method TestGETUnspecifiedArgument()
{
  set resource = $$$FormatText("%1query-params?unknown=1", ..WebApplicationName)
  return $$$AssertStatusNotOK(..AssertRequest(resource, "" /* we're expecting an error */), "returns an error if an unknown argument is provided")
}

Method TestGETMixedDynamicObject()
{
  set resource = $$$FormatText("%1mixed/object?class=1", ..WebApplicationName)
  do ##class(Frontier.Dynamic.Marshaller).MarshalDirect(..Class, .class)
  set expected = {"class":(class)}
  return $$$AssertStatusOK(..AssertRequest(resource, expected), $$$FormatText("can retrieve the expected data from the resource %1", resource))
}

Method TestGETMixedDynamicArray()
{
  set resource = $$$FormatText("%1mixed/array?class=1", ..WebApplicationName)
  set sc =  ##class(Frontier.Dynamic.Marshaller).MarshalDirect(..Class, .class)
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
  set mt = sd.%Metadata
  set rd = sd.%Execute(1, 5)

  set sc = ##class(Frontier.SQL.Serializer).SerializeToStream(.s, rd, mt,,,2)
  set array =  {}.%FromJSON(.s)
  set expected = {"results":(array)}

  return $$$AssertStatusOK(..AssertRequest(resource, expected), $$$FormatText("can retrieve the expected data from the resource %1", resource))
}

Method TestGETQuerySQLResult()
{
  set resource = $$$FormatText("%1sql/query", ..WebApplicationName)

  set sd = ##class(%SQL.Statement).%New()
  set sd.%SelectMode = 2
  do sd.%PrepareClassQuery("Frontier.UnitTest.Fixtures.Student", "PaginatedStudents")
  set mt = sd.%Metadata
  set rd = sd.%Execute(1, 5)

  set sc = ##class(Frontier.SQL.Serializer).SerializeToStream(.s, rd, mt,,,2)
  set array =  {}.%FromJSON(.s)
  set expected = {"results":(array)}
  return $$$AssertStatusOK(..AssertRequest(resource, expected), $$$FormatText("can retrieve the expected data from the resource %1", resource))
}

Method TestGETSessionUserInfo()
{
  set resource = $$$FormatText("%1user-info", ..WebApplicationName)
  set expected = {"login":"foo"}
  return $$$AssertStatusOK(..AssertRequest(resource, expected), $$$FormatText("can retrieve the expected data from the resource %1", resource))
}

Method TestGETRouteParameterNotSpecified()
{
  set resource = $$$FormatText("%1map/A/1/route-parameter-not-specified", ..WebApplicationName)
  set expected = {"error":{"internalCode":5001,"message":"Route parameter 'param1' was not specified as an argument in the method 'TestGETRouteParameterNotSpecified'."},"responseCode":500}
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
  set expected = {"result":"Hello admin! If you're seeing this, then you have enough privilege for that!"}
  do $$$AssertStatusNotOK(..AssertRequest(resource, expected), $$$FormatText("can NOT retrieve the expected data from the resource %1 because it's scoped", resource))
  return $$$AssertStatusOK(..AssertRequest(resource, expected,,,"Basic "_$System.Encryption.Base64Encode("admin:admin")), $$$FormatText("can retrieve the expected data from the resource %1", resource))
}

Method TestGETBypassAuth()
{
  set resource = $$$FormatText("%1map/C/auth/bypass", ..WebApplicationName)
  set expected = {"result":"This is an unprotected resource!"}
  return $$$AssertStatusOK(..AssertRequest(resource, expected), $$$FormatText("can retrieve the expected data from the resource %1", resource))
}

Method TestGETParentSparseParams()
{
  set resource = $$$FormatText("%1map/D/5/fixed/3/parent-sparse-params/sum", ..WebApplicationName)
  set expected = {"result":8}
  return $$$AssertStatusOK(..AssertRequest(resource, expected), $$$FormatText("can retrieve the expected data from the resource %1", resource))
}

Method TestGETParentRegexParameter()
{
  set resource = $$$FormatText("%1map/E/match/get-parent-and-this-group", ..WebApplicationName)
  set expected = ["match", "this", "group"]
  return $$$AssertStatusOK(..AssertRequest(resource, expected), $$$FormatText("can retrieve the expected data from the resource %1", resource))
}

Method TestGETNoWeakTypedArgs()
{
  set resource = $$$FormatText("%1arguments/no-weak-typed", ..WebApplicationName)
  set expected = {"error":{"internalCode":5001,"message":"The following arguments are missing the type definition: b, c."},"responseCode":500}
  return $$$AssertStatusOK(..AssertRequest(resource, expected), $$$FormatText("blocks attempts to call methods with weak typed args", resource))
}

Method TestGETNoWeakTypedMethods()
{
  set resource = $$$FormatText("%1methods/no-weak-typed", ..WebApplicationName)
  set expected = {"error":{"internalCode":5001,"message":"Expected a return type for method TestGETNoWeakTypedMethods."},"responseCode":500}
  return $$$AssertStatusOK(..AssertRequest(resource, expected), $$$FormatText("blocks attempts to call methods without return types.", resource))
}

Method TestPOSTFileUpload()
{
  set filePath = ##class(%File).NormalizeFilename(
    ##class(Port.Configuration).GetWorkspace("frontier")_"/"_
    "cls/Frontier/Router.cls"
  )
  set file = ##class(%File).%New(filePath)
  do file.Open("RS")

  set stream = ##class(%CSP.CharacterStream).%New()
  do stream.CopyFrom(file)
  set stream.FileName = file.Name

  set resource = $$$FormatText("%1upload/multi", ..WebApplicationName)
  set expected = ""

  set payload = {
    "file_a": (stream),
    "file_b": (stream)
  }

  return $$$AssertStatusOK(..AssertRequest(resource, expected, "POST", .payload,, "multipart/form-data"), $$$FormatText("can handle multipart uploads", resource))
}

Method TestPOSTSingleFileUpload()
{
  set filePath = ##class(%File).NormalizeFilename(
    ##class(Port.Configuration).GetWorkspace("frontier")_"/"_
    "cls/Frontier/Router.cls"
  )

  set file = ##class(%File).%New(filePath)
  do file.Open("RS")

  set resource = $$$FormatText("%1upload", ..WebApplicationName)
  set expected = ""

  set submmitted = file.Name
  set expectation = ..GetTestDirectory("../fixtures/uploads/single/file.txt")

  return $$$AssertStatusOK(..AssertRequest(resource, "", "POST", file,,"text/plain"), $$$FormatText("can upload a single file %1", resource))
}

Method TestGETStaticFile()
{
  for i = "README.md", "LICENSE.md", "CONTRIBUTING.md" {
    set filePath = ##class(%File).NormalizeFilename(##class(Port.Configuration).GetWorkspace("frontier")_"/"_i)
    set file = ##class(%Stream.FileCharacter).%New()
    set file.TranslateTable = "UTF8"
    do file.LinkToFile(filePath)
    set resource = $$$FormatText("%1public/%2", ..WebApplicationName, i)
    do $$$AssertStatusOK(..AssertRequest(resource, file.Read(), "GET"), "can fetch file from "_resource)
    set file = ""
  }
}

}

