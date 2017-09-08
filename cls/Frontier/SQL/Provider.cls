Include frontier

Class Frontier.SQL.Provider Extends %RegisteredObject
{

Property SQLProvider As Frontier.SQL.DeviceOutputAdapter [ Private ];

Method %OnNew(statement As %String) As %Status
{
  $$$ThrowOnError(..CreateProvider(statement))
  return $$$OK
}

Method CreateProvider(statement As %String) As %Status [ Private ]
{
   
  set ..SQLProvider = ##class(Frontier.SQL.DeviceOutputAdapter).%New()
  set ..SQLProvider.maxRows = 0
  
  if $length(statement, ":") = 2 {   
    set ..SQLProvider.queryClass = $piece(statement, ":")
    set ..SQLProvider.queryName = $piece(statement, ":", 2)
  } elseif $extract($$$ucase($$$trim(statement)), 1, 6) = "SELECT" {
    set ..SQLProvider.sql = statement    
  }
  return $$$OK
}

Method Parameters(params... As %String) As Frontier.SQL.Provider
{
  do ..SQLProvider.parameters.Clear()
  
  for i=1:1:params {
    set parameter = ##class(%ZEN.Auxiliary.parameter).%New()
    set parameter.value = params(i)
    do ..SQLProvider.parameters.SetAt(parameter, i)
  }
  return $this
}

Method RenderToJSON() As %Status
{
  return ..SQLProvider.%DrawJSON()
}

}

