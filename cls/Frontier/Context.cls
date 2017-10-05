Include (%occErrors, %occStatus)

Class Frontier.Context Extends %RegisteredObject
{

Property Session As %CSP.Session [ Private ];

Property Request As %CSP.Request [ Private ];

Property Response As %CSP.Response [ Private ];

Property CharSet As %String [ InitialExpression = "utf-8" ];

Property RequestURL As %String;

Property Method As %String;

Property ClassName As %String;

Property ArgumentValues As %String [ MultiDimensional ];

Property Stack As %String [ Internal ];

Property Error As %Status [ InitialExpression = {$$$OK}, Internal ];

Property SQL As Frontier.SQL [ ReadOnly ];

Property ReporterManager As Frontier.Reporter.Manager [ ReadOnly ];

Property AuthenticationManager As Frontier.Authentication.Manager [ ReadOnly ];

Property Data As %DynamicObject;

Property ThrownByApplication As %Boolean [ Internal, ReadOnly ];

Property DirectWrite As %Boolean [ InitialExpression = 0 ];

Property User As %DynamicObject [ InitialExpression = 1 ];

Property PropertyFormatter As Frontier.PropertyFormatter;

Method %OnNew(session As %CSP.Session, request As %CSP.Request, response As %CSP.Response) As %Status
{
  set ..Session = session
  set ..Request = request
  set ..Response = response
  set i%SQL = ##class(Frontier.SQL).%New()
  set i%ReporterManager = ##class(Frontier.Reporter.Manager).%New($this)
  set i%AuthenticationManager = ##class(Frontier.Authentication.Manager).%New(..Session, ..Request, ..Response)
  set i%ArgumentValues = 0
  set ..Data = ##class(%DynamicObject).%New()
  do ..Response.SetHeader("Content-Type", "application/json")
  set ..CharSet = "utf-8"  
  return $$$OK
}

Method CharSetSet(charset As %String) As %Status
{
  set ..Response.CharSet = charset
  set ..Response.HeaderCharSet = charset  
  return $$$OK
}

Method Raw() As %Status
{
  do ..Response.SetHeader("Content-Type", "text/plain")
  return $$$OK
}

Method IsRaw() As %Boolean
{
  return $$$lcase(..Response.ContentType) = "text/plain"
}

Method HTML() As %Status
{
  do ..Response.SetHeader("Content-Type", "text/html")
  return $$$OK
}

Method IsHTML() As %Boolean
{
  return $$$lcase(..Response.ContentType) = "text/html"
}

Method JSON() As %Status
{
  do ..Response.SetHeader("Content-Type", "application/json")
  return $$$OK
}

Method IsJSON() As %Boolean
{
  return $$$lcase(..Response.ContentType) = "application/json"
}

Method Status(statusCode As %String) As %Status
{
  set ..Response.Status = statusCode
  return $$$OK
}

Method ThrowException(message As %String, statusCode As %Integer = {$$$GeneralError}, parameters... As %String)
{
  if '$data(parameters) set parameters = 0
  set args = 2 + parameters
  set args(1) = statusCode
  set args(2) = message
  
  for i=1:1:parameters set args(2+i) = parameters(i)
  set ..ThrownByApplication = 1
  throw ##class(%Exception.StatusException).CreateFromStatus($$$ERROR(args...))
}

}

