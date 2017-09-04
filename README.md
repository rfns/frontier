<p>
    <img src="https://img.shields.io/badge/Port-enabled-green.svg" height="18">
</p>

# Frontier

Frontier is a framework for developing applications using routing functionality. It's based on %CSP.REST with a set of additional features.

# Features

* Automatic exception handling.

```
ClassMethod TestPOSTInvalidPayload() As %String
{
  // This will be thrown and be captured.
  return idontexist
}
```

* Smart parameter type resolution.

```
ClassMethod TestGETRouteParams(class As Frontier.UnitTest.Fixtures.Class) As %Status
{
  // curl -H "Content-Type: application/json" 'localhost:57772/api/frontier/test/route_params/6'
  // {"Plate":"O5397","Students":[{"Name":"Drabek,Peter T.","__id__":"20"}],"__id__":"6"}
  return class
}
```

* Support named query parameters.

```
ClassMethod TestGETOneQueryParameter(msg As %String) As %String
{
  // curl -H "Content-Type: application/json" 'localhost:57772/api/frontier/test/query_params?msg=hello'
  // {result":"hello"}
  return "hello"
}
```

* Support for rest parameters.

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

* Automatic payload detection (can also be an array).

```
ClassMethod TestPOSTObjectPayloadSingle(payload As %DynamicObject) As %DynamicObject
{
  // curl -H "Content-Type: application/json" -X POST -d '{"username":"xyz","password":"xyz"}' 'http://localhost:57772/api/frontier/test/payload/single_object'
  // {"username":"xyz","password":"xyz"}
  return payload
}
```

* Request rules enforcement.

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

* Advanced on-the-fly configuration with %frontier instance.


```
ClassMethod TestGETRawMode() As %String
{
  do %frontier.Raw()
  // Content-Type is now text/plain, response is plain as well.
  return "hello raw response"
}
```

*  Seamless marshalling execution.

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

- [ ] SQL support.
- [ ] Easier credentials validation and user object access.
- [ ] Request error email reporter.

## CONTRIBUTING

If you want to contribute with this project. Please read the [CONTRIBUTING](https://github.com/rfns/frontier/blob/master/CONTRIBUTING.md) file.

## LICENSE

[MIT](https://github.com/rfns/frontier/blob/master/LICENSE.md).


