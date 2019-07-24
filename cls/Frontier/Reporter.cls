Include %occErrors

Class Frontier.Reporter Extends %RegisteredObject
{

Method %OnNew(configuration As %DynamicObject) As %Status
{
  $$$ThrowStatus($$$ERROR($$$MethodNotImplemented, "%OnNew"))
}

Method Setup(context As Frontier.Context) As %Status
{
  $$$ThrowStatus($$$ERROR($$$MethodNotImplemented, "Setup"))
}

Method Report(context As Frontier.Context) As %Status
{
  $$$ThrowStatus($$$ERROR($$$MethodNotImplemented, "Report"))
}

}

