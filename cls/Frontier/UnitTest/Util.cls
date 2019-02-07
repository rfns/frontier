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

}

