<p>
    <img src="https://img.shields.io/badge/Port-enabled-green.svg" height="18">
</p>

# Frontier

Frontier is an abstraction layer for rapid web application development, it uses the already estabilished practices from %CSP.REST making it compatible and adds several helpers to make sure you're not wasting time re-implementing them.

# Why?

Have you ever found yourself dealing with repetitive tasks like mounting objects, serializing them and eventually handling multiple kind of errors? Frontier can boost your development by making you focus on what really matters: your application.

It's made to stop you from WRITE'ing by instead forcing your methods to return values, this way you can make your code cleaner.

# Features

* __Automatic exception handling:__ Handles the exception feedback accordingly when it's thrown. Recommended to be used along with status to notify the consumer application about errors.

```
ClassMethod TestPOSTInvalidPayload() As %String
{
  // This will be thrown and captured.
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

* __Support for query parameters:__ Can be used by simply adding them as parameters to the method to-be-called.

```
ClassMethod TestGETOneQueryParameter(msg As %String) As %String
{
  // curl -H "Content-Type: application/json" 'localhost:57772/api/frontier/test/query_params?msg=hello'
  // {result":"hello"}
  return "hello"
}
```

* __Support for sequential parameters:__ Provides more flexibility for a single query parameter by making it aware to sequential inputs. Can be defined in using the three dots notation.

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

* __Automatic payload detection (can also be an array):__ Applications requiring to send payload data (normally JSON), can do so with methods whose parameters are typed from %DynamicAbstractObject instances.

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

*  __Seamless marshalling procedure:__ Normalizes the instance graphs by marshalling them into %DynamicObject instances before serialization.

```
ClassMethod TestGETMixedDynamicObject(class As Frontier.UnitTest.Fixtures.Class) As %DynamicObject
{
  // curl -H "Content-Type: application/json" http://localhost:57772/api/frontier/test/mixed/object?class=1
  return {
    "class": (class)
  }
}
```

* __Setup__: Define a set of configurations that should be applied for the router before the matching `Call` method is invoked.

```
ClassMethod OnSetup() As %Status
{
  // This method is called before your specified Call method.
  return $$$OK
}
```

* __Error reporters:__ Define a set of reporters that are triggered when an abnormal error happens.
```
ClassMethod OnSetup() As %Status
{
  // Reporters should be used to signal the developer about request errors.
  $$$QuitOnError(%frontier.ReporterManager.AddReporter(##class(MyReporter.Email).%New()))
  $$$QuitOnError(%frontier.ReporterManager.AddReporter(##class(MyReporter.GithubIssues).%New()))

  return $$$OK
}
```

* __Authentication:__ Protect resources from unauthorized access using a [Passport](http://passportjs.org)-like strategy mechanism.
```
ClassMethod OnSetup() As %Status
{
  // Asks the user for a Basic + Base64(username:password) encoded Authorization header.
  set basicStrategy = ##class(Frontier.Authentication.BasicStrategy).%New({
    "realm": "tests",
    "validator": ($classname()_":ValidateCredentials")
  })

  // Tells to Frontier that we should use this strategy.
  $$$QuitOnError(%frontier.AuthenticationManager.AddStrategy(basicStrategy))

  return $$$OK
}
```

* __Shareable data:__ Makes an object available to all methods inside a router.
```
ClassMethod OnDataSet(data As %DynamicObject) As %Status
{
  /// This 'data' object is shared between all methods. Accessible using %frontier.Data.
  set data.Message = "This 'Message' is shared between all methods."
  return $$$OK
}

...
ClassMethod TestGETData() As %DynamicObject
{
  // Prints { "results": "This 'Message' is shared between all methods." }.
  return %frontier.Data
}
```

## I want to see this demo running!

You're in luck! Just import the class [Frontier.UnitTest.WebApplicationInstaller](https://github.com/rfns/frontier/blob/master/cls/Frontier/UnitTest/WebApplicationInstaller.cls) and use some browser or tool like cURL to see it in action.

## How do I quick start a Frontier router?

Just like you would [do](http://docs.intersystems.com/latest/csp/docbook/DocBook.UI.Page.cls?KEY=GREST_preface) with %CSP.REST.

But instead of extending your router from %CSP.REST you use ```Frontier.Router.```

Still with doubts? The [class](https://github.com/rfns/frontier/blob/master/cls/Frontier/UnitTest/Router.cls) demo'ed on Features is available to check out.

## CONTRIBUTING

If you want to contribute with this project. Please read the [CONTRIBUTING](https://github.com/rfns/frontier/blob/master/CONTRIBUTING.md) file.

## LICENSE

[MIT](https://github.com/rfns/frontier/blob/master/LICENSE.md).


