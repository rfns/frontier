Class Frontier.SQL Extends %RegisteredObject
{

Method Prepare(SQLExpression As %String)
{
  return ##class(Frontier.SQL.Provider).%New(SQLExpression)
}

ClassMethod InlineQueryBuilder(className As %String) As Frontier.SQL.InlineQueryBuilder
{
  return ##class(Frontier.SQL.InlineQueryBuilder).%New(className)
}

}

