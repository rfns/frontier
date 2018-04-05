Class Frontier.DevTools.FakeAgent Extends %RegisteredObject
{

Property Cache As %String;

Property Namespace As %String;

Method %OnNew() As %Status
{
  set ..Namespace = $namespace
  set ..Cache = "^|"""_..Namespace_"""|Frontier.DevTools.FakeAgent"
  return $$$OK
}

Method %OnClose() As %Status
{
  kill @i%Cache
  return $$$OK
}

ClassMethod EnsureRequestExists(Output request As Frontier.DevTools.FakeRequest, url As %String, method As %String, payload As %DynamicObject, auth As %String = "Basic Zm9vOmJhcg==") As %Status [ Internal, Private ]
{
  do ##class(%Net.URLParser).Parse(url, .components)
  do ParseQueryString(components("query"), .data)
  
  if '$data(request) || ($data(request) && '$isobject(request)) {
    set request = ##class(Frontier.DevTools.FakeRequest).%New()
  }
  
  set request.URL = components("path")
  set request.CgiEnvs("CONTENT_LENGTH") = 0
  set request.CgiEnvs("CONTENT_TYPE") = "application/json; charset=utf-8"
  set request.CgiEnvs("HTTP_ACCEPT") = "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8"
  set request.CgiEnvs("HTTP_ACCEPT_ENCODING") = "gzip, deflate"
  set request.CgiEnvs("HTTP_ACCEPT_LANGUAGE") = "en-US;q=0.8,en;q=0.7"
  set request.CgiEnvs("HTTP_AUTHORIZATION") = auth 
  set request.CgiEnvs("HTTP_HOST") = "localhost:57772" 
  set request.CgiEnvs("HTTP_USER_AGENT") = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/65.0.3325.181 Safari/537.36 FakeAgent/1.0"
  set request.CgiEnvs("QUERY_STRING") = $get(components("query"))  
  set request.CgiEnvs("REQUEST_METHOD") = $$$ucase(method)
  set request.CgiEnvs("REQUEST_SCHEME") = "http"
  set request.CgiEnvs("REQUEST_URI") = components("path")  
  set request.CgiEnvs("SERVER_NAME") = "localhost"
  set request.CgiEnvs("SERVER_PORT") = 57772  
  set request.CgiEnvs("SERVER_PROTOCOL") = "HTTP/1.1"
  set request.Content = ##class(%Stream.GlobalCharacter).%New()  
  if $isobject(payload) do request.Content.Write(payload.%ToJSON())  
  if $order(data("")) '= "" merge request.Data = data
  
  return $$$OK
  
ParseQueryString(qs, data)
  if qs = "" quit
  
  set qp = $lfs(qs, "&")
  
  for i=1:1:$ll(qp) {
    set key = $piece($lg(qp, i), "=", 1)
    set value = $piece($lg(qp, i), "=", 2)
    if key '= "" && (value '= "") set data(key, 1) = value
  }  
  quit
}

ClassMethod DispatchRequestAndRespondToStream(dispatcherClass As %String, url As %String, httpMethod As %String, Output str As %Stream.Object) As %Status [ Internal, Private, ProcedureBlock = 0 ]
{

  new %frontier  
  set %frontier = ##class(Frontier.Context).%New(%session, %request, %response, 1)

  new oldMnemonic, alreadyRedirected, sc
  
  set sc = $$$OK
  set isRedirected = 0
  
  set str = ##class(%Stream.GlobalCharacter).%New()
  set alreadyRedirected = ##class(%Device).ReDirectIO()
  set oldMnemonic = "^"_##class(%Device).GetMnemonicRoutine()
  set initIO = $io
  
  try {    
    use $io::("^"_$zname)
    
    do ##class(%Device).ReDirectIO(1)
    set isRedirected = 1
    set sc = $classmethod(dispatcherClass, "DispatchRequest", url, httpMethod)
    do str.Rewind()
  } catch ex {
    set str = ""
    set sc = ex.AsStatus()
  }
     
  
  if oldMnemonic '= "" {
    use initIO::(oldMnemonic)
  } else {
    use oldMnemonic
  }
  
  do ##class(%Device).ReDirectIO(alreadyRedirected)  
      
  return sc
  
wstr(s) Do str.Write(s) Quit
wchr(a) Do str.Write($char(a)) Quit
wnl Do str.Write($char(13,10)) Quit
wff Do str.Write($char(13,10,13,10)) Quit
wtab(n) Do str.Write($c(9)) Quit
rstr(len,time) Quit ""
rchr(time) Quit ""
}

Method ForgeRequest(url As %String, method As %String = "GET", payload As %DynamicAbstractObject = {{}}, auth As %String = "", Output sc As %Status = {$$$OK}) As %Stream.GlobalBinary [ PublicList = (%session, %response) ]
{
   
  new %request, %session, %response
  
  // Makes sure that any attempts to change the namespace internally ends up in the original one.
  set fromNamespace = ..Namespace
  set str = "" 
  
  set %session = ##class(%CSP.Session).%New(-1, 0)
  set %response = ##class(%CSP.Response).%New()
      
  try {    
    set urlWithInitialSlash = $select($extract(url) '= "/" : "/"_url, 1: url)
    set appInfo = ..GetApplicationInfoFromUrl(urlWithInitialSlash)
    do ..EnsureRequestExists(.%request, url, method, payload, auth)
    set %request.Application = appInfo.Name
    $$$ThrowOnError(..DispatchRequestAndRespondToStream(appInfo.DispatchClass, %request.URL, method, .str))
  } catch ex {    
    set sc = ex.AsStatus()
    set ^mtempFrontier("err", $i(i)) = sc
    if '$isobject(str) set str = ##class(%Stream.GlobalBinary).%New()
  }
  kill %request, %session, %response
  
  set $namespace = fromNamespace
  
  return str
}

Method GetApplicationInfoFromUrl(url As %String) As %DynamicObject
{
   
  #define APPCACHE @i%Cache
  
  // Cache matches to prevent roundtrips to %SYS.
  if $data($$$APPCACHE) {
    set index = $lf($$$APPCACHE, url)
    if index > 0 return $$ListToJSON(index)
  }
        
  set $namespace = "%SYS"
    
  set result = {}
  
  // Revert the ordering so that longer are considered first, note that the longer the path is higher is similarity with the url.
  set rows = ##class(%SQL.Statement).%ExecDirect(, "SELECT TOP 1 Name, DispatchClass FROM SECURITY.APPLICATIONS WHERE ? %STARTSWITH Name ORDER BY LEN(Name) DESC", url)
  if rows.%Next() {
    set $list($$$APPCACHE, *+1) = url
    set index = $ll($$$APPCACHE)
    set $list($$$APPCACHE, *+1) = rows.%Get("Name")    
    set $list($$$APPCACHE, *+1) = rows.%Get("DispatchClass")
    set result = $$ListToJSON(index)
  }
  
  set $namespace = ..Namespace
  
  return result
  
ListToJSON(urlIndex)
  return {
    "Name": ($lg($$$APPCACHE, urlIndex + 1)),
    "DispatchClass": ($lg($$$APPCACHE, urlIndex + 2))
  }
}

ClassMethod Request(url As %String, method As %String = "GET", payload As %DynamicAbstractObject = {{}}, auth As %String = "", outputToDevice As %Boolean = 0, Output sc As %Status = {$$$OK}) As %Stream.GlobalBinary
{
  set agent = ..%New()
  if outputToDevice = 1 {
    set str = agent.ForgeRequest(url, method, payload, auth, .sc)
    do str.OutputToDevice()
  } else {
    return agent.ForgeRequest(url, method, payload, auth, .sc)
  }  
  return str
}

}

