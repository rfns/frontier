Class Frontier.SQL Extends %RegisteredObject
{

Method Prepare(statement As %String)
{
  return ##class(Frontier.SQL.Provider).%New(statement)
}

}

