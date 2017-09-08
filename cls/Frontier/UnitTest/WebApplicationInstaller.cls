Class Frontier.UnitTest.WebApplicationInstaller Extends %Projection.AbstractProjection
{

Parameter NAME = "/api/frontier/test/";

Projection Installer As Frontier.UnitTest.WebApplicationInstaller;

ClassMethod CreateProjection(classname As %String, ByRef parameters As %String, modified As %String, qstruct) As %Status
{
  $$$QuitOnError(##class(Frontier.UnitTest.Fixtures.Class).%KillExtent())
  $$$QuitOnError(##class(Frontier.UnitTest.Fixtures.Student).%KillExtent())
  $$$QuitOnError(##class(Frontier.UnitTest.Fixtures.Class).Populate())
  $$$QuitOnError(##class(Frontier.UnitTest.Fixtures.Student).Populate())  
  return ##class(Frontier.UnitTest.Util).CreateWebApplication()
}

ClassMethod RemoveProjection(classname As %String, ByRef parameters As %String, recompile As %Boolean, modified As %String, qstruct) As %Status
{
  $$$QuitOnError(##class(Frontier.UnitTest.Fixtures.Class).%KillExtent())
  $$$QuitOnError(##class(Frontier.UnitTest.Fixtures.Student).%KillExtent())  
  return ##class(Frontier.UnitTest.Util).RemoveWebApplication()
}

}

