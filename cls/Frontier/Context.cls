Include (%occErrors, %occStatus)

Class Frontier.Context Extends %RegisteredObject
{

Property Session As %CSP.Session [ Private ];

Property Request As %CSP.Request [ Private ];

Property Response As %CSP.Response [ Private ];

Property CharSet As %String [ InitialExpression = "utf-8" ];

Property SQL As Frontier.SQL [ ReadOnly ];

Property Data As %DynamicObject;

Method %OnNew(session As %CSP.Session, request As %CSP.Request, response As %CSP.Response) As %Status
{
  set i%Session = session
  set i%Request = request
  set i%Response = response
  set i%SQL = ##class(Frontier.SQL).%New()
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
  throw ##class(%Exception.StatusException).CreateFromStatus($$$ERROR(args...))
}

}

