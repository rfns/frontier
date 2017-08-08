Class UnitTest.Frontier.Router Extends Frontier.Router
{

XData UrlMap [ XMLNamespace = "http://github.com/rfns/port" ]
{
<Routes>
  <Route Url="/:namespace" Method="GET" Call="GetNamespaceName"/>
  <Route Url="/:namespace" Method="POST" Call="TestPayload"/>
  <Route Url="/:namespace/class" Method="GET" Call="GetClass"/>
 </Routes>
}

ClassMethod TestPayload(namespace As %String, q As %String, payload As %DynamicArray) As %DynamicObject(PUBLIC=1)
{
  set payload.%Get(0).q = q
  return payload
}

ClassMethod GetClass(namespace As %String, class As UnitTest.Frontier.Fixtures.Class) As %DynamicObject(SQLMODE=1)
{
  return "SELECT TOP 1 * FROM UnitTest.Frontier.Fixtures.Class"
}

Query Whatever() As %SQLQuery
{
  SELECT TOP 3 JSON_OBJECT('lit':'Employee from','t':%TABLENAME,'name':Name,'num':SSN) FROM Sample.Employee
}

}

