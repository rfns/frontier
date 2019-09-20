Include %occErrors

Class Frontier.Reporter Extends %RegisteredObject
{

Property IncludedCodes As %List [ Internal, Private, Transient ];

Property ExcludedCodes As %List [ Internal, Private, Transient ];

Method %OnNew(configuration As %DynamicObject) As %Status
{
  do ..PopulateList(configuration, "include")
  do ..PopulateList(configuration, "exclude")
  return $$$OK
}

Method Setup(context As Frontier.Context) As %Status
{
  $$$ThrowStatus($$$ERROR($$$MethodNotImplemented, "Setup"))
}

Method Report(context As Frontier.Context) As %Status
{
  $$$ThrowStatus($$$ERROR($$$MethodNotImplemented, "Report"))
}

Method IsReportable(context As Frontier.Context) As %Boolean [ Final ]
{
  if $ll(i%IncludedCodes) > 0 && ($lf(i%IncludedCodes, context.Exception.Code) > 0) return 1  
  if $ll(i%IncludedCodes) = 0 && ($ll(i%ExcludedCodes) > 0) {
     if $lf(i%ExcludedCodes, context.Exception.Code) > 0 return 0
  }  
  return 1
}

Method PopulateList(configuration As %DynamicArray, key As %String) As %Status [ Final, Private ]
{
  if 'configuration.%IsDefined(key) return $$$OK
  set iterator = configuration.%Get(key).%GetIterator()
  
  while iterator.%GetNext(,.value) { 
    if key = "include" set $list(i%IncludedCodes, *+1) = value 
    else  set $list(i%ExcludedCodes, +1) = value
  }
  
  return $$$OK
}

}

