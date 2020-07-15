Include (%occErrors, %occStatus)

/// When instantiated, this class provides a set of features that can be used
/// to configure how Frontier behaves when handling the requests. Usually represented
/// by the public %frontier variable, which is always available inside a router class.
Class Frontier.Context Extends %RegisteredObject
{

Parameter VERSION = "5.1.2";

/// This holds the reference for the %session object.
Property Session As %CSP.Session [ Private ];

/// This holds the reference for the %request object.
Property Request As %CSP.Request;

/// This holds the reference for the %response object.
Property Response As %CSP.Response;

/// The URL that matched the route.
Property RequestURL As %String;

/// The last method called in the current request.
Property Method As %String;

/// The dispatcher class that will reply the request.
Property ClassName As %String;

/// A list of resolved arguments built by the Frontier.Method class.
Property ArgumentValues As %String [ MultiDimensional ];

/// The current stack that is used by reporters to display the error.
Property Stack As %Stream.GlobalCharacter [ Internal ];

/// An internal flag that signals when to include stack info with the error.
Property IncludeStack As %Boolean [ InitialExpression = 0 ];

/// The exception data that will be passed to the reporter.
Property Exception As Frontier.Exception [ Internal ];

/// This Frontier SQL API, a minimalist API used to quickly retrieve SQL results.
Property SQL As Frontier.SQL [ ReadOnly ];

/// The Reporter API, which is used to handle and report errors.
Property ReporterManager As Frontier.Reporter.Manager [ ReadOnly ];

/// The Authentication API, which is used to define a set of strategies and configure them.
Property AuthenticationManager As Frontier.Authentication.Manager [ ReadOnly ];

/// The Files API, which allows the handling of file uploads and serving files/directories as well.
Property Files As Frontier.Files [ ReadOnly ];

/// The object populated by the method OnDataSet which is called before each request.
Property Data As %DynamicObject;

/// DEPRECATED: use %frontier.Modifiers.DIRECTWRITE instead.
/// This flag indicates if the response should be rewritten to the response stream buffer or write directly.
/// Keep this flag set to 0 to prevent errors from corrupting the output, set it to 1 if you need performance
/// and your code is secure enough to not error while writing to the device.
Property DirectWrite As %Boolean [ InitialExpression = 0 ];

/// This holds all the properties defined by the elected strategy.
Property User As %DynamicObject [ InitialExpression = 1 ];

/// This allows to provide a custom property formatter for JSON.
Property PropertyFormatter As Frontier.PropertyFormatter;

/// By default Frontier won't allow the usage of query parameters that aren't arguments from the classmethod that will be called.
/// Setting this flag to 0 will disable this check.
Property StrictQueryParameters As %Boolean [ InitialExpression = 0 ];

/// This is plain text version from the route parameters. It's useful when its equivalent argument resolved to an object due to its type.
/// Each route parameters is keyed by its name.
Property RouteParameters As %String [ InitialExpression = 0, MultiDimensional ];

/// When the Route element has Strict=false, this property will be populated with the set of regular expression matching groups.
Property Matches As %String [ InitialExpression = 0, MultiDimensional ];

/// By default, everything Frontier outputs is formatted to JSON. This internal flag informs the routing engine to display the result as plain text.
Property RawMode As %Boolean [ InitialExpression = 0, Private ];

/// Represents the response charset.
Property Encoding As %String [ InitialExpression = "utf-8" ];

/// The CORS API, which handles the access from extraneous servers.
Property CORS As Frontier.CORS [ ReadOnly ];

/// A string that holds the Route element's Url expression. Can be used to identified which route as been called.
Property Route As %String;

/// An object containing a list of properties related to how Frontier behaves.
Property Parameters As Frontier.Parameters [ ReadOnly ];

Property OutputDevice As %String [ Internal, ReadOnly ];

Method %OnNew(session As %CSP.Session, request As %CSP.Request, response As %CSP.Response) As %Status
{
  set ..Session = session
  set ..Request = request
  set ..Response = response
  set i%SQL = ##class(Frontier.SQL).%New()
  set i%ReporterManager = ##class(Frontier.Reporter.Manager).%New($this)
  set i%AuthenticationManager = ##class(Frontier.Authentication.Manager).%New(..Session, ..Request, ..Response)
  set i%Files = ##class(Frontier.Files).%New($this)
  set i%CORS = ##class(Frontier.CORS).%New($this)
  set i%Parameters = ##class(Frontier.Parameters).%New()
  set i%ArgumentValues = 0
  set i%OutputDevice = $io  
  set ..Data = {}
  set ..Response.ContentType = "application/json"
  return $$$OK
}

/// Disables the JSON output, making the response to be sent in plain text.
/// The Content-Type header is overwritten to 'text/plain'.
Method Raw() As %Status
{
  set ..RawMode = 1
  do ..Response.SetHeader("Content-Type", "text/plain")
  return $$$OK
}

/// Returns if the Raw mode is enabled.
Method IsRaw() As %Boolean
{
  return (..RawMode = 1)
}

/// This is almost the same than the Raw method.
/// But instead the Content-Type will be overwritten to 'text/html'.
Method HTML() As %Status
{
  set ..RawMode = 1
  do ..Response.SetHeader("Content-Type", "text/html")
  return $$$OK
}

/// Returns if the HTML method has been called.
Method IsHTML() As %Boolean
{
  return (..RawMode = 1 && ($$$lcase(..Response.ContentType) = "text/html"))
}

/// Restores Frontier making it use JSON.
Method JSON() As %Status
{
  set ..RawMode = 0
  do ..Response.SetHeader("Content-Type", "application/json")
  return $$$OK
}

/// Returns if Frontier will be sending JSON.
Method IsJSON() As %Boolean
{
  return (..RawMode = 0 && ($$$lcase(..Response.ContentType) = "application/json"))
}

/// Sets the status that will be sent with the response.
Method Status(statusCode As %String) As %Status
{
  set ..Response.Status = statusCode
  return $$$OK
}

/// Throws an application controlled error, such errors won't cause the Reporter API to be fired.
Method ThrowException(message As %String, httpStatus As %String = "500 Internal Server Error", parameters... As %String)
{
  if '$data(parameters) set parameters = 0
  set args = 2 + parameters
  set args(1) = $$$GeneralError
  set args(2) = message

  set ..Response.Status = httpStatus

  for i=1:1:parameters set args(2+i) = parameters(i)
  throw ##class(%Exception.StatusException).CreateFromStatus($$$ERROR(args...))
}

Method DirectWriteSet(value As %Boolean) As %Status
{
  set ..Parameters.DIRECTWRITE = 1
  set i%DirectWrite = value
  return $$$OK
}

Method StrictQueryParametersSet(value) As %Status
{
	set ..Parameters.STRICTQUERYPARAMETERS = value
	set i%StriactQueryParameters = value
	return $$$OK
}

}

