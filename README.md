<p>
    <img src="https://img.shields.io/badge/Port-enabled-green.svg" height="18">
</p>

# Frontier

Frontier is a REST framework made with the purpose of reducing boilerplate code and imposing a clean coding style where __dispatcher methods should always return a value or throw an exception.__ This way the application will never use the WRITE command manually inside these kind of methods.

# Why?

Have you ever found yourself dealing with repetitive tasks like mounting objects, serializing them and eventually handling multiple kind of errors? Frontier was built to boost your development by making you focus on what really matters: your application.

# Features

%CSP.REST is the base class *exclusive* for creating RESTful applications. While Frontier uses the %CSP.REST for welcoming the requests, it overwrites how %CSP.REST transports the request to the dispatcher method in a way that you can use it even if your application is not RESTful. Here's how Frontier compares to the default %CSP.REST:

| Feature | Frontier | %CSP.REST
| :------- | :------- | :---- |
| Query parameters | By argument name | Using %request.Get |
| Variable number of arguments | By indexed query parameter | Using %request.Get(name, index) |
| Map placeholders | Supported | Parsing from %request.URL |
| Routes with regular expressions | Supported when Strict="false" | Supported |
| JSON serialization | Using %Dynamic instances | Writing to the device |
| Error handling | Implicit | try/catch or trap mechanism with device write |
| Argument instantiation | By argument class type (query/route parameters) | Manually |
| Payload handling | Triggered by %Dynamic based arguments | Manually checking from %request.Content |
| SQL result serialization | Using a wrapper for the SQL API | Writing to the device |
| Unmarshaling | When typing an argument and setting UNMARSHAL=1 | Manually |
| Marshalling | Seamlessly returning a mixed %Dynamic type | Manually |
| Serving files | Using the Frontier Files API | Not supported on %CSP.REST, but %CSP.StreamServer |
| Upload handling | By using the Frontier Files Upload API | Manually from %request.MimeData
| Error reporting | By using the Frontier Reporter API | Manually
| Authentication | Strategy-oriented (isolated) | Based on web application config / OAuth2 API |
| Stream response | Implicit | Writing to the device |
| Sharing common data | Using OnDataSet method and %frontier.Data object | N/A |
| Property formatters | Using %frontier.PropertyFormatter | While mounting the object |

## In practice

* __Automatic exception handling:__ Handles the exception feedback accordingly when it's thrown. Recommended to be used along with status to notify the consumer application about errors.

```
ClassMethod SayHello() As %String
{
  // This will return { "result": "hello" }
  return "hello"

  // or

  $$$ThrowStatus($$$ERORR($$$GeneralError, "oops"))

  // or

  return %frontier.ThrowException("oops")

  // or (this will be captured automatically)

  set value = oops
}
```
* __Typed argument:__ Set the argument type as something that extends from %Persistent and it'll be
replaced with the instance resulting from an implicit %OpenId call right before the dispatcher method is invoked. This works for both: query parameters and route parameters.
```
ClassMethod TestGETRouteParams(class As Frontier.UnitTest.Fixtures.Class) As %Status
{
  // curl -H "Content-Type: application/json" 'localhost:57772/api/frontier/test/route-params/6'
  // {"Plate":"O5397","Students":[{"Name":"Drabek,Peter T.","__id__":"20"}],"__id__":"6"}
  return class
}
```
* __Query parameters:__ Unhandled arguments (not explicitly set on Route/Map) are considered as query parameters. By default they are required, however it's possible to make them optional simply by providing a default value.
```
ClassMethod SayHelloTo(who As %String = "John Doe") As %String
{
  // curl -H "Content-Type: application/json" 'localhost:57772/api/frontier/test/query-params?who=Francis'
  // curl -H "Content-Type: application/json" 'localhost:57772/api/frontier/test/query-params'
  return "hello "_who
}
```
* __Variable number of arguments:__ Multiple query parameters with the same name but different indexes. To enable it, use the three dot notation.
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
* __Payload handling:__ Client applications requiring to send payload data (normally JSON), can be handled by the server with methods whose parameters are typed from %DynamicAbstractObject instances.
```
ClassMethod EchoUserPayload(payload As %DynamicObject) As %DynamicObject
{
  // curl -H "Content-Type: application/json" -X POST -d '{"username":"xyz","password":"xyz"}' 'http://localhost:57772/api/frontier/test/payload/single-object'
  // {"username":"xyz","password":"xyz"}
  return payload
}
```
* __Unmarshaling:__ Set `UNMARSHAL=1` while typing the payload to a persistent class so that the payload will be parsed and unmarshalled to it.
```
ClassMethod CreateClass(class As Frontier.UnitTest.Fixtures.Class(UNMARSHAL=1)) As Frontier.UnitTest.Fixtures.Student
{
  // curl -H "Content-Type: application/json" -X POST\
  // -d '{"Plate": "R-2948","Students": [{"Name": "Rubens",\
  // "BirthDate": "04/21/1970","SomeValue": 0}]}'\
  // 'http://localhost:57772/api/frontier/unmarshal
  $$$ThrowOnError(class.%Save())
  return {
    "ok": true,
    "__id__": (class.%Id())
  }
}
```
* __SQL results:__ Return a serializable SQL result using the Frontier SQL API.
```
ClassMethod GetPaginatedSQLResult(
  page As %Integer = 1,
  rows As %Integer = 5) As Frontier.SQL.Provider
{
  set offset = (page * rows) - (rows - 1)
  set limit = page * rows

  return %frontier.SQL.Prepare(
    "SELECT *, %VID as Index FROM (SELECT TOP ? * FROM FRONTIER_UNITTEST_FIXTURES.STUDENT) WHERE %VID BETWEEN ? AND ?"
  ).Parameters(limit, offset, limit)

  // or

  return %frontier.SQL.Prepare("Package.Class:QueryName").Parameters(limit, offset)
}
```
* __Streams:__ Return a stream instance to deliver a content that exceeds the maximum string length.
```
ClassMethod TestGETStream() As %Stream.Object
{
  set stream = ##class(%Stream.GlobalCharacter).%New()
  do stream.Write("This line is from a stream.")

  return stream
}
```
*  __Seamless object serialization:__ Mix multiple object types into a single returning `%DynamicObject/%DynamicArray` instance and all its composition will be mutated to dynamic instances as well.
```
ClassMethod TestGETMixedDynamicObject(class As Frontier.UnitTest.Fixtures.Class) As %DynamicObject
{
  // Class is a instance of a %Persistent derived type.
  return {
    "class": (class)
  }
}
```
* __Shareable object__: Allows the context to share a set of objects that can be retrived on each dispatcher method.
```
ClassMethod OnDataSet(data As %DynamicObject) As %Status
{
  /// This 'data' object is shared between all methods. Accessible using %frontier.Data.
  set data.Message = "This 'Message' is shared between all methods."
  return $$$OK
}

ClassMethod TestGETData() As %DynamicObject
{
  // Prints { "results": "This 'Message' is shared for all methods." }.
  return %frontier.Data
}
```

# Configuring the router

Each Router class provides a configuration method called `OnSetup()`. This method allows the developer to define how the Router should behave for certain situations. Configuration is made by using the helpers provided in the `%frontier` object which is composed by several modules to handle different tasks.

## Authentication

The helper `AuthenticationManager` allows the declaration of a chain of strategies that attempt to match themselves with the authentication model and the credentials provided by the client. In other words, a strategy is elected from the chain and used to validate the credentials.

Below is an example on how to configure a strategy in the chain.

Implementation:
```
ClassMethod OnSetup() As %Status
{
  // Asks the user for a Basic + Base64(username:password) encoded Authorization header.
  set basicStrategy = ##class(Frontier.Authentication.BasicStrategy).%New({
    "realm": "tests",
    "validator": ($classname()_":ValidateCredentials")
  })

  // Tells Frontier that we should use this strategy.
  $$$QuitOnError(%frontier.AuthenticationManager.AddStrategy(basicStrategy))
}
```

> NOTE: This will make all the routes under the current Router to be protected. If you want to disable authentication you can set `UseAuth="false"` in the related `<Route>`. You can also force a route to use a single strategy by using `AuthStrategy="MyAuth"`.

### Implementing a strategy

If you want to use your own strategy, you need to consider a few entry points:

* `Realm (String):` This should be used to define the 'realm' when sending the challenge to the client.
* `GetChallenge (Method)`: This should return a valid `WWW-Authenticate` whenever adequate.
* `Verify (Method):` This method takes four arguments: `session`, `request`, `response`, and `user`. The implementation use the three first arguments to resolve the `user` which is represented by a %DynamicObject. When `user` is populated with a `scope`  property, then this `scope` will be used to validate against the Route's `Scope` attribute if present.

To have a better idea on how to implement a custom strategy check out the class [Frontier.Authentication.BasicStrategy](https://github.com/rfns/frontier/blob/feature/files/cls/Frontier/Authentication/BasicStrategy.cls). It implements all the entry points described here.

## Reporters

Reporters can be used to take an informative action on unhandled errors. just like the `AuthenticationManager`, the `ReporterManager` can have a chain of reporters as well. But instead of electing a single strategy and firing it, the `ReportManager` will call each consecutively.

> NOTE: Since reporters are fired after the request has been finished, you'll need to make the application aware of it, in order to do so, set up the event class `Frontier.SessionEvents`. You can also customize it for your needs.

Reporters should be set using the method `OnSetup` and its syntax is very similar to the Authentication.

```
ClassMethod OnSetup() As %Status
{
  // Reporters should be used to signal the developer about request errors.
  $$$QuitOnError(%frontier.ReporterManager.AddReporter(##class(MyReporter.Email).%New()))
  $$$QuitOnError(%frontier.ReporterManager.AddReporter(##class(MyReporter.GithubIssues).%New()))
  return $$$OK
}
```

### Implementing a reporter

Since reporters provides more freedom on how to implement them, there is only two entry points:

* `Setup (method)`: This receives `context`: an object representing the `%frontier`. Use this method to prepare or configure the custom reporter.
*  `Report (method)`: This also receives `context`, however `Report` is called only when an abnormal error happens and the request has already finished. This is where the custom reporter should take an action.

Check out the class [Frontier.Reporter.Log](https://github.com/rfns/frontier/blob/feature/files/cls/Frontier/Reporter/Log.cls) to see how to implement those entry points.

### Property Formatters

They're used for modifying the writing style for each property. The usage is pretty straightforward:

`set %frontier.PropertyFormatter = ##class(Frontier.PropertyFormatter.SnakeCase).%New()`

This will make all the properties to be written using `snake_case` format. If you don't define a property formatter, then the original format is used.

# The Frontier SQL API

If you want to output directly from SQL results, you need to return a provider.
A provider can be created by using the Frontier SQL API, its syntax is:

```
  %frontier
    SQL
      .Prepare(SQL or named query) // This returns the provider
        .Parameters(n...) // while this
        .Mode(DisplayMode) // and this decorates it. So they are optional.
```

Returning the provider will output `{ "results": [{...}, {...} ...]}`. If you want customize it, then just put the provider into an array or object so that the output will be merged with it.

> NOTE #1: By default the Display mode is configured to 0: the internal format.

> NOTE #2: You cannot use this API the iterate over each row, if you want to do so, then you're recommended to use the %SQL.Statement API itself.

## Using the query builder

You can also allow the client to provide you the query, this can be useful for creating in-app advanced filters. You can setup the query builder by making it respond in place of the default API. E.g.

```
ClassMethod InlineQuery(filter As %String = "", page As %String = "", fields As %String = "id, name, ssn", orderBy As %String = "id asc, dob desc", limit As %Integer = 50) As Frontier.SQL.Provider
{
  set builder = %frontier.SQL.InlineQueryBuilder()
  do builder.For("Sample.Person")
  do builder.Filter(filter)
  do builder.OrderBy("id as PersonID, SSN")
  return builder.Build().Provide()
}
```

# The Frontier Files API

This enables the application to serve or receive static files.

## Serving files

There are two ways of serving a file. You can serve a directory or a single file.

### Server a directory

Serving a directory means that the user can select what to retrieve by using the URL path. As long as it belongs
to the directory you provided the access: files are served starting from the `root` path that's only know to the server, combined with the URL match that indicates the root path's subdirectory. E.g.

```
URL is             /my/application/static/docs/help.txt
Root is            /var/lib/app/public
Which resolves to  /var/lib/app/public/docs/help.txt
```

In order to serve files inside a directory, you must make sure that you have configured a `Route` that:

1. Has `Strict` set to "false". So that you can use regular expressions.
2. Uses group to capture the file path. Something like `?(.*)?` should be enough.
3. Has a class method that directs to the file server.

* For steps 1 and 2:

```xml
<Route Url="/static/?(.*)?" Strict="false" Method="GET" Call="TestGETStaticFile"/>
```

* For step 3:

```
ClassMethod TestGETStaticFile() As %Stream.Object
{
  return %frontier.Files.ServeFrom("/var/lib/app/public")
}
```

This is the most basic format to start serving files from a directory.

Check out the class [Frontier.UnitTest.Router](https://github.com/rfns/frontier/blob/feature/files/cls/Frontier/UnitTest/Router.cls), method `TestGETStaticFileWithCustomConfig` to learn how to use advanced configurations.

### Serving a file

One of the cons on serving a directory is that the path inside the directory gets exposed. Serving a file however, allows the application to mask that path using the route url instead with the limitation of serving a file exclusively.

```
<Route Url="/static/documents/:id" Strict="false" Method="GET" Call="GetUserDocument"/>
```

```
ClassMethod GeUserDocument(id As %String) As %Status
{
  set path = ##class(%File).NormalizeFilename(id_".pdf", "/uploads/files/pdf")
  return %frontier.Files.ServeFile(path)
}
```

## Receiving files

Files can be saved to the server by preparing a route capable of handling uploads. Configuring the upload handler requires less work in the Route definition, but instead more configuration in the uploader itself.

Finally, you need a class method to set up the upload handler, this must be same as the `Call` attribute.

And now, you're ready to set up the upload handler.

> NOTE: You need a `Route` that accepts a POST request, anything else won't work.

```
ClassMethod HandleUpload() As %Status
{
  set location = "/var/lib/my/app/uploads"
  set destination = location_"/:KEY/:FILE_NAME:EXTENSION"

  // 512 KB
  set maxFileSize = (1024**2/0.5)

  return %frontier.Files.Upload({
    "hooks": {
      "onItemUploadSuccess": "Frontier.UnitTest.Router:WriteResultToProcessGlobal",
      "onItemUploadError": "Frontier.UnitTest.Router:WriteErrorToProcessGlobal",
      "onComplete": "Frontier.UnitTest.Router:WriteResultSummaryToProcessGlobal"
    },
    "filters": {
      // Will throw an error instead of silently ignoring the entry.
      "verbose": true,
      "extensions": ["txt", "pdf"],
      "maxFileSize": {
        "value": (maxFileSize),
        "errorTemplate": "The file exceeded the :VALUE bytes limit."
      }
    },
    "destinations": {
      "file_a": { "path": (destination) },
      "file_b": { "path": (destination) },
      "file_c": { "path": (destination), "optional": true },
      "file_d": { "path": (destination), "optional": true },
      // optional=false
      "file_x": (destination),
      "files": {
        "path": (location_"/files/:INDEX/:FILE_NAME:EXTENSION"),
        "slots": 3, // Enables sending multiple files with the same key.
        "filters": { "maxFileSize": 500000000 }
      }
    }
  })
}
```

# Running the test suites

Although for using Frontier you don't need any additional library, in order to run the test suites you'll need to execute the following steps:

1. Download and install [Port](https://github.com/rfns/port).
2. Configure `Port` to the path you cloned this repo. E.g.: If you cloned to `/projects/frontier` you'll need to run `##class(Port.Configuration).SetCustomWorkspace("frontier", "/projects/frontier")`.
3. Download and install [Forgery](https://github.com/rfns/forgery).
4. Import the class `Frontier.UnitTest.WebApplicationInstaller.cls`. This will create the application required to run the tests.

## CONTRIBUTING

If you want to contribute with this project, you're encouraged to do so, however please read the [CONTRIBUTING](https://github.com/rfns/frontier/blob/master/CONTRIBUTING.md) file before doing so.

## LICENSE

[MIT](https://github.com/rfns/frontier/blob/master/LICENSE.md).


