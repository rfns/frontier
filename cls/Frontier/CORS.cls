Include frontier

/// The Frontier CORS API
/// Use this API to define a set of CORS rules that allow or deny access to the
/// protected resource if the origin is extraneous.
Class Frontier.CORS Extends %RegisteredObject
{

/// The %frontier context.
Property Context As Frontier.Context [ Private ];

/// The header names to be added in the Vary header.
Property VaryHeaders [ Private ];

/// A single origin resolved from the incoming request and list of allowed origins.
/// If this is empty, then the request will fail.
Property AllowedOrigin As %String [ Private ];

/// If the request is made using a HTTP method that is not in this list, the request will fail.
Property AllowedMethods As %String [ Private ];

/// If this value is not set to true and the request contains Authorization, the request will fail.
Property AllowedCredentials As %String [ Private ];

/// Any headers that aren't in this list will make the request fail.
Property AllowedHeaders As %String [ Private ];

/// How long the preflight request can be cached.
Property AllowedAge As %String [ Private ];

/// What the response can expose.
Property ExposedHeaders As %String [ Private ];

/// A string containing the class:method which is used to filter which origins should be allowed.
Property OriginVerifier As %String [ InitialExpression = "Frontier.CORS:IsOriginAllowed" ];

Method %OnNew(context As Frontier.Context) As %Status
{
  set ..Context = context
  return $$$OK
}

Method IsActive() As %Boolean
{
  if i%VaryHeaders '= "" return 1
  if i%AllowedOrigin '= "" return 1
  if i%AllowedMethods '= "" return 1
  if i%AllowedCredentials '= "" return 1
  if i%AllowedHeaders '= "" return 1
  if i%AllowedAge '= "" return 1
  if i%ExposedHeaders '= "" return 1
  return 0
}

/// Defines a set of origins allowed to access this protected resource.
/// If more than one is provided, then it will use the classmethod from OriginVerifier to validated each entry against the request origin.
/// If no origin is provided, then it will match against the request origin making it unrestricted.
/// If only one origin is provided, than the request origin will be matched against it and fail the request if it differs.
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

/// Specify which HTTP methods the request can use when accessing this protected resource.
/// Each method will be used against the request's method. If none match, the request will fail.
Method AllowMethods(methods... As %String)
{
  if '$data(methods) set methods = 0
  set ..AllowedMethods = ..makeList(methods...)
}

/// Specify a list of headers that the request can be sent with, any header sent that is not present in this list
/// will cause the request to fail.
Method AllowHeaders(headers... As %String)
{
  if '$data(headers) set headers = 0
  set ..AllowedHeaders = ..makeList(headers...)
}

/// Specify if the request include credential related headers. Otherwise the request will fail.
Method AllowCredentials(enabled As %Boolean = 0)
{
  set ..AllowedCredentials = $$$FormatBoolean(enabled)
}

/// Specify a list of response headers that the client can read.
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

/// Provides full resouce access to the specified origins otherwise assume any origin can access it.
Method Default(origins... As %String)
{
  do ..AllowOrigin(origins...)
  do ..AllowCredentials(1)
  do ..AllowMethods("GET", "POST", "PUT", "DELETE", "HEAD")
  do ..AllowHeaders("Authorization", "Content-Type")
  do ..AllowCredentials(1)
}

/// Sets the list of Vary headers.
Method Vary(varyHeaders... As %String)
{
  if '$data(varyHeaders) set varyHeaders = 0
  do ..Context.Response.SetHeader("Vary", ..makeList(varyHeaders...))
}

Method CheckPreflight() [ Internal ]
{
  if '..IsActive() quit
  do ..SetHeaderIfProvided("Vary", "Origin")
  do ..SetHeaderIfProvided("Vary", "Access-Control-Request-Headers")
  do ..SetHeaderIfProvided("Access-Control-Allow-Origin", ..AllowedOrigin)
  do ..SetHeaderIfProvided("Access-Control-Allow-Methods", ..AllowedMethods)
  do ..SetHeaderIfProvided("Access-Control-Allow-Headers", ..AllowedHeaders)
  do ..SetHeaderIfProvided("Access-Control-Allow-Credentials", ..AllowedCredentials)
  do ..SetHeaderIfProvided("Access-Control-Expose-Headers", ..ExposedHeaders)
  do ..SetHeaderIfProvided("Access-Control-Max-Age", ..AllowedAge)
  do ..Context.Response.DeleteHeader("Content-Type")
  set ..Context.Response.ContentLength = 0
  set ..Context.Response.ContentType = ""
}

Method Set() [ Internal ]
{
  if '..IsActive() quit
  do ..SetHeaderIfProvided("Vary", "Origin")
  do ..SetHeaderIfProvided("Access-Control-Allow-Origin", ..AllowedOrigin)
  do ..SetHeaderIfProvided("Access-Control-Allow-Credentials", ..AllowedCredentials)
}

/// Use this method to undo CORS configuration. Can be used if you need to ovewrite
/// the parent router with a children configuration.
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

