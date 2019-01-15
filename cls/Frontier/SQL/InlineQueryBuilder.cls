Include frontier

Class Frontier.SQL.InlineQueryBuilder Extends %RegisteredObject
{

Property Filter As %String [ Private ];

Property OrderBy As %String [ Private ];

Property Parameters As %String [ MultiDimensional, Private ];

Property PaginationParameters As %List [ Private ];

Property SelectedFields As %String [ Private ];

Property Status As %Status [ InitialExpression = 1, Private ];

Property For As %String [ Private ];

Property Result As %String;

Property Position As %Integer [ InitialExpression = 0, Private ];

Method %OnNew() As %Status
{
  set i%Parameters = 0
  return $$$OK
}

Method Filter(filter) As Frontier.SQL.InlineQueryBuilder
{
  set ..Filter = filter
  return $this
}

Method For(className As %String) As Frontier.SQL.InlineQueryBuilder
{
  set ..For = className
  return $this
}

Method Pagination(page As %Integer, limit As %String) As Frontier.SQL.InlineQueryBuilder
{
  do ..CheckPaginationParameters(page, limit)
  if $$$ISOK(..Status) set ..PaginationParameters = $lb(page, limit)
  return $this
}

Method Fields(fields As %String) As Frontier.SQL.InlineQueryBuilder
{
  if fields = "" set ..SelectedFields = "*" 
  else  set ..SelectedFields = fields
  return $this
}

Method OrderBy(orderBy As %String) As Frontier.SQL.InlineQueryBuilder
{
  set ..OrderBy = " ORDER BY "_orderBy
  return $this
}

Method WrapWithPaginationIfProvided(fields As %String = "*", where As %String = "", orderBy As %String = "", tableName As %String) As %String [ Private ]
{
  if ..PaginationParameters = "" return ""
  
  set page = $lg(..PaginationParameters, 1)
  set limit = $lg(..PaginationParameters, 2)
  set offset = (page * limit) - (limit - 1)
  set limit = page * limit
  
  return "SELECT *, %VID AS row FROM (SELECT "_fields_" FROM "_tableName_where_orderBy_") WHERE %VID BETWEEN "_offset_" AND "_limit
}

Method CheckPaginationParameters(page, limit) [ Private ]
{
   
  set sc = $$$OK
  #define AppendStatus(%newStatus) set sc = $$$ADDSC(sc, $$$ERROR($$$GeneralError, %newStatus))  
  
  if '$isvalidnum(page) $$$AppendStatus("Page must be a number.")
  if page = 0 $$$AppendStatus("Page must be start from 1")
  if page < 0 $$$AppendStatus("Page must be a positive number.")
  
  if '$isvalidnum(page) $$$AppendStatus("Limit must be a number.")
  if page = 0 $$$AppendStatus("Limit must be start from 1")
  if page < 0 $$$AppendStatus("Limit must be a positive number.")
  
  set paginationSC = $$$EMBEDSC($$$ERROR($$$GeneralError, "Invalid pagination parameters."), sc)
  if $$$ISERR(sc) set ..Status = $$$ADDSC(..Status, paginationSC)
}

Method BuildSQLWhere(filter As %String = {..Filter}, type As %String = "AND", whereStatement As %String = "WHERE") As %String [ Private ]
{
 
  if filter = "" return ""  
  set where = ""  
  set l = $length(filter, ";")
  
  for i=1:1:l {
    set condition = $piece(filter, ";", i)
    // If ] is found then the builder is trying to capture the same condition, so skip it.   
    if condition?.ANP1"]" = 1 continue
    if $extract(condition, 1, 3)?1"$"1(1"or",1"an") = 1 {
      set conditionType = $$$ucase($extract(condition, $find(condition, "$"), $find(condition, ":") - 2))
      set expression = $$DesconstructComposition(condition, conditionType)
    } else {
      set expression = $$ResolveSimpleCondition(condition)
    }    
    set $list(where, *+1) = expression    
  }
  
  if $ll(where) '= 0 set where = " "_whereStatement_" ("_$lts(where, " "_type_" ")_")"
  return where
  
 
ResolveSimpleCondition(condition)
  if condition '[ "_" set condition = $piece(condition, ":")_"_eq:"_$piece(condition, ":", 2, *)
  set field = $$$trim($piece(condition, "_"))    
  if field [ "." set field = $replace(field, ".", "->")
  
  set op = $$$trim($piece($piece(condition, "_", 2, 2), ":", 1))
  set value = $piece(condition, ":", 2, *)
  
  do ..BuildExpression(field, value, op, .exp)
  return exp
    
DesconstructComposition(condition, conditionType)  
  set setStart = $find(filter, condition) - ($length(condition) - 5)
  set setEnd = $find(filter, "]", setStart) - 2
  if conditionType = "AND" set setStart = setStart + 1
  set composition = $extract(filter, setStart, setEnd)
  set ..Position = $length(composition, ";")
  return ..BuildSQLWhere(composition, conditionType, "")
}

Method Build() As Frontier.SQL.InlineQueryBuilder
{
  if $$$ISERR(..Status) $$$ThrowStatus(..Status)
  
  set ..Position = 0
  set cclass = ##class(%Dictionary.CompiledClass).%OpenId(..For)
  if cclass = "" $$$ThrowStatus($$$ERROR($$$GeneralError, "Invalid table name."))
  set tableName = cclass.SqlQualifiedNameQ
  
  set fields = ..SelectedFields
  if fields = "" set fields = "*"
  set orderBy = ..OrderBy
  set where = ..BuildSQLWhere()
  set paginatedQuery = ..WrapWithPaginationIfProvided(fields, where, orderBy, tableName)
  set statement = paginatedQuery
  if statement = "" set statement = "SELECT "_fields_ " FROM "_tableName_where_ " "_orderBy
  set ..Result = statement
  return $this
}

Method BuildExpression(field As %String, value, op As %String, Output placeholder As %String = "") [ Private ]
{
  set singleVarOpTypes = $lb("eq", "ne", "gt", "gte", "lt", "lte", "sw", "nsw", "ct", "nct", "lk", "nlk", "is", "isn", "il", "nil")
  
  if $lf(singleVarOpTypes, op) > 0 {
    if op = "eq" set placeholder = field_" = ?"
    if op = "ne" set placeholder = field_" <> ?"
    if op = "gt" set placeholder = field_" > ?"
    if op = "gte" set placeholder = field_" >= ?"
    if op = "lt" set placeholder = field_" < ?"
    if op = "lte" set placeholder = field_" <= ?"
    if op = "sw" set placeholder = field_" %STARTSWITH ? "
    if op = "nsw" set placeholder = field_" NOT %STARTSWITH ?"
    if op = "ct" set placeholder = field_" [ ?"
    if op = "nct" set placeholder = field_" '[ ?"
    if op = "lk" set placeholder = field_" LIKE ?"
    if op = "nlk" set placeholder = field_" NOT LIKE ?"
    if op = "il" set placeholder = field_" %INLIST ?" set value = $lfs(value)
    if op = "nil" set placeholder = field_" NOT %INLIST ?" set value = $lfs(value)
    
    if op '= "is" && (op '= "isn") {
      do AddParameter(value)
    } elseif value = "null" {
      set null = $$$ucase(value)
      if op = "is" set placeholder = field_" IS "_null
      if op = "isn" set placeholder = field_" IS NOT "_null
    }
  } elseif op = "bt" || (op = "nbt") {
    set not = ""
    if op = "nbt" set not = "NOT"
    set left = $piece(value, ",", 1, 1)
    set right = $piece(value, ",", 2, 2)
    set placeholder = field_not_" BETWEEN ? AND ? "
    do AddParameter(left)
    do AddParameter(right)
  } elseif op = "in" || (op = "nin") {
    set not = ""
    set phs = ""
    set l = $length(value, ",")
    for i=1:1:l  do AddParameter($piece(value, ",", i)) set $list(phs, *+1) = "?"
    set placeholder = field_not_" IN ("_$lts(phs)_")"
  }
  
AddParameter(newparam)
  set i%Parameters = i%Parameters + 1
  set i%Parameters(i%Parameters) = newparam
}

Method Provide() As Frontier.SQL.Provider
{
  set params = ""
  merge params = i%Parameters
  set provider = ##class(Frontier.SQL.Provider).%New(..Result)
  if params > 0 $$$ThrowOnError(provider.Parameters(params...))
  return provider
}

}

