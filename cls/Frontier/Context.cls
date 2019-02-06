Include (%occErrors, %occStatus)

Class Frontier.Context Extends %RegisteredObject
{

Property Session As %CSP.Session [ Private ];

Property Request As %CSP.Request;

Property Response As %CSP.Response;

Property RequestURL As %String;

Property Method As %String;

Property ClassName As %String;

Property ArgumentValues As %String [ MultiDimensional ];

Property Stack As %Stream.GlobalCharacter [ Internal ];

Property IncludeStack As %Boolean [ InitialExpression = 0 ];

Property Error As %Status [ InitialExpression = {$$$OK}, Internal ];

Property SQL As Frontier.SQL [ ReadOnly ];

Property ReporterManager As Frontier.Reporter.Manager [ ReadOnly ];

Property AuthenticationManager As Frontier.Authentication.Manager [ ReadOnly ];

Property Files As Frontier.Files [ ReadOnly ];

Property Data As %DynamicObject;

Property ThrownByApplication As %Boolean [ Internal, ReadOnly ];

Property DirectWrite As %Boolean [ InitialExpression = 0 ];

Property User As %DynamicObject [ InitialExpression = 1 ];

Property PropertyFormatter As Frontier.PropertyFormatter;

Property StrictQueryParameters As %Boolean [ InitialExpression = 1 ];

Property RouteParameters As %String [ InitialExpression = 0, MultiDimensional ];

Property Matches As %String [ InitialExpression = 0, MultiDimensional ];

Property RawMode As %Boolean [ InitialExpression = 0 ];

Property Encoding As %String [ InitialExpression = "utf-8" ];

Property CORS As Frontier.CORS [ ReadOnly ];

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
  set i%ArgumentValues = 0   
  set ..Data = {} 
  set ..Response.ContentType = "application/json"
  return $$$OK
}

Method Raw() As %Status
{
  set ..RawMode = 1
  return $$$OK
}

Method IsRaw() As %Boolean
{
  return (..RawMode = 1)
}

Method HTML() As %Status
{
  set ..RawMode = 1
  do ..Response.SetHeader("Content-Type", "text/html")
  return $$$OK
}

Method IsHTML() As %Boolean
{
  return (..RawMode = 0 && ($$$lcase(..Response.ContentType) = "text/html"))
}

Method JSON() As %Status
{
  set ..RawMode = 0
  do ..Response.SetHeader("Content-Type", "application/json")
  return $$$OK
}

Method IsJSON() As %Boolean
{
  return (..RawMode = 0 && ($$$lcase(..Response.ContentType) = "application/json"))
}

Method Status(statusCode As %String) As %Status
{
  set ..Response.Status = statusCode
  return $$$OK
}

Method ThrowException(message As %String, httpStatus As %String = "500 Internal Server Error", parameters... As %String)
{
  if '$data(parameters) set parameters = 0
  set args = 2 + parameters
  set args(1) = $$$GeneralError
  set args(2) = message
  
  set ..Response.Status = httpStatus
  
  for i=1:1:parameters set args(2+i) = parameters(i)
  set i%ThrownByApplication = 1
  throw ##class(%Exception.StatusException).CreateFromStatus($$$ERROR(args...))
}

}

