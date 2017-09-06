Include frontier

Class Frontier.SQL.Provider Extends %RegisteredObject
{

Property SQLProvider As Frontier.SQL.DeviceOutputAdapter;

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
    set ..SQLProvider.queryNAme = $piece(statement, ":", 2)   
  } elseif $extract($$$ucase($$$trim(statement)), 1, 6) = "SELECT" {
    set ..SQLProvider.sql = statement    
  }
  return $$$OK
}

Method Paginate(page As %Integer = 1, size As %Integer = 30) As Frontier.SQL.Provider
{
  set ..SQLProvider.maxRows = page * size  
  return $this
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

