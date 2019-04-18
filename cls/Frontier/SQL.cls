Class Frontier.SQL Extends %RegisteredObject
{

Method Prepare(SQLExpression As %String)
{
  return ##class(Frontier.SQL.Provider).%New(SQLExpression)
}

ClassMethod InlineQueryBuilder() As Frontier.SQL.InlineQueryBuilder
{
  return ##class(Frontier.SQL.InlineQueryBuilder).%New()
}

}

