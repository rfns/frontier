Include frontier

Class Frontier.CORS Extends %RegisteredObject
{

Property Context As Frontier.Context [ Private ];

Property VaryHeaders [ Private ];

Property AllowedOrigin As %String [ Private ];

Property AllowedMethods As %String [ Private ];

Property AllowedCredentials As %String [ Private ];

Property AllowedHeaders As %String [ Private ];

Property AllowedAge As %String [ Private ];

Property ExposedHeaders As %String [ Private ];

Property PreflightReceived As %Boolean [ InitialExpression = 0, Private ];

Property OriginVerifier As %String [ InitialExpression = "Frontier.CORS:IsOriginAllowed" ];

Method %OnNew(context As Frontier.Context) As %Status
{
  set ..Context = context
  return $$$OK
}

Method AllowOrigin(origins... As %String)
{
  if '$data(origins) set origins = 0  
  
  if origins = 0 {
    set ..AllowedOrigin = ..Context.Request.GetCgiEnv("HTTP_ORIGIN")
  } elseif origins = 1 {
    set ..AllowedOrigin = origins(1)
  } elseif origins > 2 {
    for i=1:1:origins {
      if ..TestOrigin(origins(i)) {
        set ..AllowedOrigin = origins(i) quit
      }
    }
  }
}

Method AllowMethods(methods... As %String)
{
  if '$data(methods) set methods = 0
  set ..AllowedMethods = ..makeList(methods...)
}

Method AllowHeaders(headers... As %String)
{
  if '$data(headers) set headers = 0
  set ..AllowedHeaders = ..makeList(headers...)
}

Method AllowCredentials(enabled As %Boolean = 0)
{
  set ..AllowedCredentials = $$$FormatBoolean(enabled)
}

Method ExposeHeaders(headers... As %String)
{
  if '$data(headers) set headers = 0
  set ..ExposedHeaders = ..makeList(headers)
}

Method makeList(args... As %String) As %List
{
  set list = ""
  
  for i=1:1:args {
    set $list(list, *+1) = args(i)
  }
  
  return $lts(list, ", ")
}

Method Default(origins... As %String)
{
  do ..AllowOrigin(origins...)
  do ..AllowCredentials(1)
  do ..AllowMethods("GET", "POST", "PUT", "DELETE", "HEAD")
  do ..AllowHeaders("Authorization", "Content-Type")  
  do ..AllowCredentials(1)
}

Method Vary(varyHeaders... As %String)
{
  if '$data(varyHeaders) set varyHeaders = 0
  do ..Context.Response.SetHeader("Vary", ..makeList(varyHeaders...))
}

Method CheckPreflight() [ Internal ]
{
  do ..SetHeaderIfProvided("Vary", "Origin")
  do ..SetHeaderIfProvided("Vary", "Access-Control-Request-Headers")
  do ..SetHeaderIfProvided("Access-Control-Allow-Origin", ..AllowedOrigin)
  do ..SetHeaderIfProvided("Access-Control-Allow-Methods", ..AllowedMethods)
  do ..SetHeaderIfProvided("Access-Control-Allow-Headers", ..AllowedHeaders)
  do ..SetHeaderIfProvided("Access-Control-Allow-Credentials", ..AllowedCredentials)
  do ..SetHeaderIfProvided("Access-Control-Expose-Headers", ..ExposedHeaders)
  do ..SetHeaderIfProvided("Access-Control-Max-Age", ..AllowedAge)
  do ..Context.Response.DeleteHeader("Content-Type")  
  set ..Context.Response.ContentType = ""
}

Method Set() [ Internal ]
{
  do ..SetHeaderIfProvided("Vary", "Origin") 
  do ..SetHeaderIfProvided("Access-Control-Allow-Origin", ..AllowedOrigin)
  do ..SetHeaderIfProvided("Access-Control-Allow-Credentials", ..AllowedCredentials)
}

Method Unset()
{
  do ..Context.Response.DeleteHeader("Vary")
  do ..Context.Response.DeleteHeader("Access-Control-Allow-Origin")
  do ..Context.Response.DeleteHeader("Access-Control-Allow-Methods")
  do ..Context.Response.DeleteHeader("Access-Control-Allow-Headers")
  do ..Context.Response.DeleteHeader("Access-Control-Allow-Credentials")
}

Method SetHeaderIfProvided(header As %String, value As %String) [ Private ]
{
  if value '= "" do ..Context.Response.SetHeader(header, value)
}

Method IsOriginAllowed(allowedOrigin As %String, requestUrl As %String) As %Boolean [ Private ]
{
  return allowedOrigin = requestUrl
}

Method TestOrigin(origin As %String) As %Boolean [ Private ]
{
  set isAllowed = 0
  set className = $piece(..OriginVerifier, ":")
  set methodName = $piece(..OriginVerifier, ":", 2)
    
  try {
    set isAllowed = $classmethod(className, methodName, origin, ..Context.Request.URL)
  } catch ex { }
  
  return isAllowed
}

}

