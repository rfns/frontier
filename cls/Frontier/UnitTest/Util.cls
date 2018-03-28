Class Frontier.UnitTest.Util [ Abstract ]
{

Parameter NAME = "/api/frontier/test/";

ClassMethod CreateWebApplication() As %Status
{
  set targetNamespace = $namespace
  
  new $namespace  
  set $namespace = "%SYS"
  
  write !, ">> Creating demo web application using namespace "_targetNamespace_" ..."
  if ##class(Security.Applications).Exists(..#NAME) {
    write !, ">> Application already exists, skipping ..."
    return $$$OK
  }
  
  set properties("CookiePath") = ..#NAME
  set properties("DispatchClass") = "Frontier.UnitTest.Router"
  set properties("EventClass") = "Frontier.SessionEvents"
  set properties("NameSpace") = targetNamespace
  set properties("UseCookies") = 2
  set properties("AutheEnabled") = 64
  
  $$$QuitOnError(##class(Security.Applications).Create(..#NAME, .properties))
  write !, ">> Application /api/frontier/test has been created."
  return $$$OK
}

ClassMethod RemoveWebApplication() As %Status
{
  new $namespace
  set $namespace = "%SYS"
  
  if '##class(Security.Applications).Exists(..#NAME) return $$$OK
  write !, ">> Deleting demo web application "_..#NAME_" ..."
  
  $$$QuitOnError(##class(Security.Applications).Delete(..#NAME))
  write !, ">> Web application has been deleted with success."
  
  return $$$OK
}

ClassMethod MergeErrors(errors As %DynamicArray) As %Status
{
  
  set sc = $$$OK
  
  for i=0:1:(errors.%Size() - 1) {
    set errorObject = errors.%Get(i)
    set sc = $$$ADDSC(sc, $$$ERROR(errorObject.code, errorObject.params.%Get(0)))
  }
  
  return sc
}

ClassMethod MarshallSQLResult(SQLResult As %IResultSet, Output dynamicArray As %DynamicArray) As %Status
{
  set sc = $$$OK
  set dynamicArray = []
  set columnInfo = ""
  
  set columnsCount = SQLResult.%ResultColumnCount
  for c = 1:1:columnsCount {
    set columnInfo(c,"name") = SQLResult.%GetMetadata().columns.GetAt(c).label
  }  
  
  while (SQLResult.%Next(.sc)) {
    quit:$$$ISERR(sc)
    set node = {}
    for c = 1:1:SQLResult.%ResultColumnCount {
      set value = SQLResult.%GetData(c)
        
      if ($isvalidnum(value) && ($e(value) '= 0)) do node.%Set($get(columnInfo(c,"name")),$num(value),"number")
      else  do node.%Set($get(columnInfo(c,"name")),value)
    }
    Do dynamicArray.%Push(node)
  }
  return sc
}

ClassMethod UpdateRequestObject(request As %CSP.Request, url As %String, method As %String, payload As %DynamicObject, auth As %String = "Basic Zm9vOmJhcg==") As %Status
{
  do ##class(%Net.URLParser).Parse(url, .components)
  do ParseQueryString(components("query"), .data)  
  
  set request.URL = components("path")
  set request.CgiEnvs("CONTENT_LENGTH") = 0
  set request.CgiEnvs("CONTENT_TYPE") = "application/json; charset=utf-8"
  set request.CgiEnvs("HTTP_ACCEPT") = "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8"
  set request.CgiEnvs("HTTP_ACCEPT_ENCODING") = "gzip, deflate, br"
  set request.CgiEnvs("HTTP_ACCEPT_LANGUAGE") = "en-US;q=0.8,en;q=0.7"
  set request.CgiEnvs("HTTP_AUTHORIZATION") = auth 
  set request.CgiEnvs("HTTP_HOST") = "localhost:57772" 
  set request.CgiEnvs("HTTP_USER_AGENT") = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/65.0.3325.181 Safari/537.36"
  set request.CgiEnvs("QUERY_STRING") = $get(components("query"))  
  set request.CgiEnvs("REQUEST_METHOD") = $$$ucase(method)
  set request.CgiEnvs("REQUEST_SCHEME") = "http"
  set request.CgiEnvs("REQUEST_URI") = components("path")  
  set request.CgiEnvs("SERVER_NAME") = "localhost"
  set request.CgiEnvs("SERVER_PORT") = 57772  
  set request.CgiEnvs("SERVER_PROTOCOL") = "HTTP/1.1"  
  set request.CgiEnvs("SERVER_SOFTWARE") = "Apache/2.4.20 (win32) Cache_Server_Pages-Apache_Module/2017.1.0.792.0-1701.1606aa"
  set request.Application = "/api/frontier/test"
  set request.Content = ##class(%Stream.GlobalCharacter).%New()  
  if $isobject(payload) do request.Content.Write(payload.%ToJSON())  
  if $order(data("")) '= "" merge request.Data = data
  
  quit $$$OK
  
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

ClassMethod DispatchRequestAndRespondToStream(dispatcherClass As %String, url As %String, httpMethod As %String, Output str As %Stream.Object) As %Status [ Internal, ProcedureBlock = 0 ]
{

  new %frontier
  set %frontier = ##class(Frontier.Context).%New(%session, %request, %response)

  new oldMnemonic, alreadyRedirected, sc
  
  set sc = $$$OK
  set isRedirected = 0
  
  set str = ##class(%Stream.TmpBinary).%New()
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

}

