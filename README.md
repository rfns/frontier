<p>
    <img src="https://img.shields.io/badge/Port-enabled-green.svg" height="18">
</p>

# Frontier

Frontier is an abstraction layer for rapid web application development with Caché. By using it you'll stop worrying about how to handle data and errors thus focusing on what matters: your application.

# Features

* __Automatic exception handling:__ Handles the exception feedback accordingly when it's thrown. Recommended to be used along with status to notify the consumer application about errors.

```
ClassMethod TestPOSTInvalidPayload() As %String
{
  // This will be thrown and be captured.
  return idontexist
}
```

* __Typed parameter instantiation:__ Parameters that are typed from %Persistent classes can be resolved and instantiated right at the runtime. Invalid ids are represented by empty values.

```
ClassMethod TestGETRouteParams(class As Frontier.UnitTest.Fixtures.Class) As %Status
{
  // curl -H "Content-Type: application/json" 'localhost:57772/api/frontier/test/route_params/6'
  // {"Plate":"O5397","Students":[{"Name":"Drabek,Peter T.","__id__":"20"}],"__id__":"6"}
  return class
}
```

* __Support for query parameters:__ Can be used by simply defining their formal spec and passing them in the URL.

```
ClassMethod TestGETOneQueryParameter(msg As %String) As %String
{
  // curl -H "Content-Type: application/json" 'localhost:57772/api/frontier/test/query_params?msg=hello'
  // {result":"hello"}
  return "hello"
}
```

* __Support for rest parameters:__ If more flexibility is needed for a single query parameter, using rest parameters might be better. Define them as it would be using common COS syntax and populate it using queryN syntax, where N is a sequential index.

```
ClassMethod TestGETRestParametersSum(n... As %String) As %Integer
{
  // curl -H "Content-Type: application/json" 'localhost:57772/api/frontier/test/rest_params?n1=10&n2=20&n3=30'
  // {"result":60}
  set sum = 0
  for i=1:1:n  set sum = sum + n(i)
  return sum
}
```

* __Automatic payload detection (can also be an array):__ Applications requiring to send payload data (normally JSON), can do so with methods whose parameters are typed from %Dynamic instances.

```
ClassMethod TestPOSTObjectPayloadSingle(payload As %DynamicObject) As %DynamicObject
{
  // curl -H "Content-Type: application/json" -X POST -d '{"username":"xyz","password":"xyz"}' 'http://localhost:57772/api/frontier/test/payload/single_object'
  // {"username":"xyz","password":"xyz"}
  return payload
}
```

* __Request rules enforcement:__ Makes sure that the developer is following the correct practices for welcoming requests.
```
ClassMethod TestPOSTInvalidPayload(
  payloadA As %DynamicArray,
  payloadB As %DynamicObject) As %DynamicArray
{
  // curl -H "Content-Type: application/json" -X POST -d '[{"username":"xyz","password":"xyz"}]' 'http://localhost:57772/api/frontier/test/payload/invalid'
  // Throws because requests can only have one payload.
  return payloadA
}
```

* __Request context instance:__ Can be used to modify certain behaviors and produce different results.
```
ClassMethod TestGETRawMode() As %String
{
  do %frontier.Raw()
  // Content-Type is now text/plain, response is plain as well.
  return "hello raw response"
}
```

* __SQL support:__ SQL results can be serialized by using the Frontier's SQL API. Named queries are supported as well.
```
ClassMethod TestGETDynamicSQLResult(
	page As %Integer = 1,
	rows As %Integer = 5) As Frontier.SQL.Provider
{
  set offset = (page * rows) - (rows - 1)
  set limit = page * rows

  return %frontier.SQL.Prepare(
    "SELECT *, %VID as Index FROM (SELECT * FROM FRONTIER_UNITTEST_FIXTURES.STUDENT) WHERE %VID BETWEEN ? AND ?"
  ).Parameters(offset, limit)
}
```

* __Stream support:__ Big contents can be serialized by returning a %Stream.Object instance.

```
ClassMethod TestGETStream() As %Stream.Object
{
  set stream = ##class(%Stream.GlobalCharacter).%New()
  do stream.Write("This line is from a stream.")

  return stream
}
```

*  __Seamless marshalling procedure:__ Normalizes the instance graphs by marshalling them into %Dyanamic instances before serialization.

```
ClassMethod TestGETMixedDynamicObject(class As Frontier.UnitTest.Fixtures.Class) As %DynamicObject
{
  // curl -H "Content-Type: application/json" http://localhost:57772/api/frontier/test/mixed/object?class=1
  return {
    "class": (class)
  }
}
```

## I want to see this demo running!

You're in luck! Just import the class [Frontier.UnitTest.WebApplicationInstaller](https://github.com/rfns/frontier/blob/master/cls/Frontier/UnitTest/WebApplicationInstaller.cls) and use some browser or tool like cURL to see it in action.

## How do I create my own router?

Just like you would [do](http://docs.intersystems.com/latest/csp/docbook/DocBook.UI.Page.cls?KEY=GREST_preface) with %CSP.REST.

But instead of extending your router from %CSP.REST you use ```Frontier.Router.```

Still with doubts? The [class](https://github.com/rfns/frontier/blob/master/cls/Frontier/UnitTest/Router.cls) demo'ed on Features is available to check out.

## So, what's next?

- [v] SQL support.
- [ ] Easier credentials validation and user object access.
- [ ] Request error email reporter.

## CONTRIBUTING

If you want to contribute with this project. Please read the [CONTRIBUTING](https://github.com/rfns/frontier/blob/master/CONTRIBUTING.md) file.

## LICENSE

[MIT](https://github.com/rfns/frontier/blob/master/LICENSE.md).


