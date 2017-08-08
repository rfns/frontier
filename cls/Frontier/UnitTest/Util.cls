Class Frontier.UnitTest.Util [ Abstract ]
{

Parameter FRONTIERTESTURL = "/api/frontier/test";

ClassMethod CreateWebApp() As %Status
{
  set ns = $namespace
  new $namespace
  
  set $namespace = "%SYS"  
  set properties("NameSpace") = ns
  set properties("DispatchClass") = "Frontier.UnitTest.Router"  
  
  if ##class(Security.Applications).Exists(..#FRONTIERTESTURL) {
    $$$QuitOnError(..DestroyWebApp())
  }
  return ##class(Security.Applications).Create(..#FRONTIERTESTURL, .properties)
}

ClassMethod DestroyWebApp() As %Status
{
  
  set ns = $namespace
  new $namespace
  
  set $namespace = "%SYS"
  do ##class(%File).RemoveDirectoryTree($System.Util.InstallDirectory()_"csp/frontier")
  return ##class(Security.Applications).Delete(..#FRONTIERTESTURL)
}

}

