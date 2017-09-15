Class Frontier.SQL Extends %RegisteredObject
{

Method Prepare(SQLExpression As %String)
{
  return ##class(Frontier.SQL.Provider).%New(SQLExpression)
}

}

