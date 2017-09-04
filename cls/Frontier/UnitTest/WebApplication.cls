Class Frontier.UnitTest.WebApplication Extends %Projection.AbstractProjection
{

Projection Reference As Frontier.UnitTest.WebApplication;

ClassMethod CreateProjection(classname As %String, ByRef parameters As %String, modified As %String, qstruct) As %Status
{
  return ##class(Frontier.UnitTest.Util).CreateWebApp()
}

ClassMethod RemoveProjection(classname As %String, ByRef parameters As %String, recompile As %Boolean, modified As %String, qstruct) As %Status
{
  return ##class(Frontier.UnitTest.Util).DestroyWebApp()
}

}

