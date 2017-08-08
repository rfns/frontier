Class Frontier.UnitTest.Router Extends Frontier.Router
{

XData UrlMap [ XMLNamespace = "http://github.com/rfns/frontier" ]
{
<Routes>
  <Route Url="/route_params/:class" Method="GET" Call="TestGETRouteParams"/>
  <Route Url="/query_params" Method="GET" Call="TestGETOneQueryParameter"/>
  <Route Url="/rest_params" Method="GET" Call="TestGETRestParametersSum"/>
  <Route Url="/unpublished" Method="GET" Call="TestGETUnpublishedMethod"/>
  <Route Url="/payload/single_object" Method="POST" Call="TestPOSTObjectPayloadSingle"/>
  <Route Url="/payload/object_with_query_params" Method="POST" Call="TestPOSTObjectPayloadQueryParams"/>
  <Route Url="/payload/array_with_query_params" Method="POST" Call="TestPOSTArrayPayloadQueryParams"/>
  <Route Url="/payload/single_array" Method="POST" Call="TestPOSTArrayPayloadSingle"/>
  <Route Url="/payload/invalid" Method="POST" Call="TestPOSTInvalidPayload"/>
  <Route Url="/mixed/object" Method="GET" Call="TestPOSTMixedDynamicObject"/>
  <Route Url="/mixed/array" Method="GET" Call="TestPOSTMixedDynamicArray"/>
 </Routes>
}

/// curl -H "Content-Type: application/json" -X GET localhost:57772/api/frontier/test/route_params/6 
ClassMethod TestGETRouteParams(class As Frontier.UnitTest.Fixtures.Class) As %Status(PUBLIC=1)
{
  return class
}

ClassMethod TestGETOneQueryParameter(msg As %String) As %String(PUBLIC=1)
{
  return msg
}

ClassMethod TestGETRestParametersSum(n... As %String) As %Integer(PUBLIC=1)
{
  set sum = 0
  for i=1:1:n  set sum = sum + n(i)
  return sum
}

ClassMethod TestGETUnpublishedMethod(namespace As %String) As %Status
{
  // Whatever would you expect to happen here, it actually shouldn't.
  return $$$OK
}

ClassMethod TestPOSTObjectPayloadSingle(payload As %DynamicObject, msg As %String) As %DynamicObject(PUBLIC=1)
{
  return {
    "payload": (payload),
    "message": (msg)
  }
}

ClassMethod TestPOSTObjectPayloadQueryParams(payload As %DynamicObject, msg As %String = "")
{
  return {
    "msg": (msg),
    "payload": (payload)
  }
}

ClassMethod TestPOSTArrayPayloadSingle(payload As %DynamicArray) As %DynamicObject(PUBLIC=1)
{
  return payload
}

ClassMethod TestPOSTArrayPayloadQueryParams(payload As %DynamicObject, msg As %String = "")
{
  return [ (msg), (payload) ]
}

ClassMethod TestPOSTInvalidPayload(payload As %DynamicArray) As %DynamicArray(PUBLIC=1)
{
  return payload
}

ClassMethod TestPOSTMixedDynamicObject(namespace As %String) As %DynamicObject(PUBLIC=1)
{
  return {
    "class": (##class(Frontier.UnitTest.Fixtures.Class).%OpenId(1))
  }
}

ClassMethod TestPOSTMixedDynamicArray(namespace As %String) As %DynamicArray(PUBLIC=1)
{
  return [ (##class(Frontier.UnitTest.Fixtures.Class).%OpenId(1)) ]
}

}

