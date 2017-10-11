Include frontier

Class Frontier.SQL.Provider Extends %RegisteredObject
{

Property QueryClass As %String [ Private ];

Property QueryName As %String [ Private ];

Property SQL As %String [ Private ];

Property QueryParameters As %String [ MultiDimensional, Private ];

Property Mode As %Integer [ InitialExpression = 1, Private ];

Property Error As %Status [ InitialExpression = {$$$OK}, Internal ];

Property StatementExecuted As %Boolean [ InitialExpression = 0 ];

Property Results As %SQL.StatementResult [ Internal, ReadOnly ];

Property Metadata As %SQL.StatementMetadata [ Internal, ReadOnly ];

Method %OnNew(statement As %String) As %Status
{
  
  $$$ThrowOnError(..HandleSQLExpression(statement))
  return $$$OK
}

Method Parameters(params... As %String) As Frontier.SQL.Provider
{
  $$$ThrowOnError(..SetQueryParameters(params...))
  return $this
}

Method Mode(selectMode As %Integer = 1) As Frontier.SQL.Provider
{
  set ..Mode = selectMode
  return $this
}

Method Execute() As %Status
{
  set ..StatementExecuted = 1
  return ..CreateAndExecute()
}

Method HandleSQLExpression(SQLExpression As %String) As %Status [ Private ]
{
   
  if $length(SQLExpression, ":") = 2 {   
    set ..QueryClass = $piece(SQLExpression, ":")
    set ..QueryName = $piece(SQLExpression, ":", 2)
  } elseif $extract($$$ucase($$$trim(SQLExpression)), 1, 6) = "SELECT" {
    set ..SQL = SQLExpression
  }
  return $$$OK
}

Method SetQueryParameters(parameters... As %String) As %Status
{
  if parameters '= 0 && 'parameters?.N && ($order(parameters(""), -1) '= parameters) {
    return $$$ERROR($$$GeneralError, "Invalid parameter spec.")
  }
  
  kill i%QueryParameters
  set i%QueryParameters = parameters
  
  merge i%QueryParameters = parameters
  return $$$OK
}

Method CreateAndExecute() As %Status [ Private ]
{
  
  set sc = $$$OK
  merge parameters = ..QueryParameters
  
  set statement = ##class(%SQL.Statement).%New()
  set statement.%SelectMode = ..Mode  
  
  if ..QueryClass '= "" && (..QueryName '= "") {    
    set sc = statement.%PrepareClassQuery(..QueryClass, ..QueryName)    
  } elseif ..SQL '= "" {
    set sc = statement.%Prepare(..SQL)
  }
  
  set i%Metadata = statement.%Metadata 
  
  $$$QuitOnError(sc)
  set results = statement.%Execute(parameters...)
  
  if results.%SQLCODE '= 0 {
    set sc = ##class(%Exception.SQL).CreateFromSQLCODE(results.%SQLCODE, results.%Message).AsStatus()
  }
  set i%Results = results
  return sc
}

}

