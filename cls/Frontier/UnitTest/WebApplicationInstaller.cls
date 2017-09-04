Class Frontier.UnitTest.WebApplicationInstaller Extends %Projection.AbstractProjection
{

Parameter NAME = "/api/frontier/test/";

Projection Installer As Frontier.UnitTest.WebApplicationInstaller;

ClassMethod CreateProjection(classname As %String, ByRef parameters As %String, modified As %String, qstruct) As %Status
{
  return ..CreateWebApplication()
}

ClassMethod RemoveProjection(classname As %String, ByRef parameters As %String, recompile As %Boolean, modified As %String, qstruct) As %Status
{
  return ..RemoveWebApplication()
}

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
  set properties("Namespace") = targetNamespace
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
  write !, ">> Deleting sample web application ..."   
  
  $$$QuitOnError(##class(Security.Applications).Delete(..#NAME))
  write !, ">> Web application has been deleted with success."
  
  return $$$OK
}

}

