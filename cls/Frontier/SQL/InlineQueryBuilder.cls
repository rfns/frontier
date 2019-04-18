Include frontier

Class Frontier.SQL.InlineQueryBuilder Extends %RegisteredObject
{

Property Filter As %String [ Private ];

Property OrderBy As %String [ Private ];

Property Parameters As %String [ MultiDimensional, Private ];

Property PaginationParameters As %List [ Private ];

Property SelectedFields As %String [ InitialExpression = "*", Private ];

Property Status As %Status [ InitialExpression = 1, Private ];

Property For As %String [ Private ];

Property Result As %String;

Property GroupBy As %String [ Private ];

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
  
  if $$$ISOK(..Status) set ..PaginationParameters = $lb(page, limit)
  return $this
}

Method Fields(fields As %String) As Frontier.SQL.InlineQueryBuilder
{
  if fields = "" set ..SelectedFields = "*" 
  else  set ..SelectedFields = ..SanitizeInput(fields)
  return $this
}

Method OrderBy(orderBy As %String) As Frontier.SQL.InlineQueryBuilder
{
  set ..OrderBy = "ORDER BY "_..SanitizeInput(orderBy)
  return $this
}

Method GroupBy(groupBy As %String) As Frontier.SQL.InlineQueryBuilder
{
  set ..GroupBy = "GROUP BY "_..SanitizeInput(groupBy)
}

Method SanitizeInput(input As %String) As %String [ Private ]
{
  return $zstrip(input, "*E'N'A", "", "_.*, ")
}

Method WithPagination(where As %String = "", tableName As %String) As %String [ Private ]
{
  if ..PaginationParameters = "" return ""
  
  set page = $lg(..PaginationParameters, 1)
  set limit = $lg(..PaginationParameters, 2)
  set offset = (page * limit) - (limit - 1)
  set limit = page * limit
  
  set args = 8
  set args(1) = limit
  set args(2) = ..SelectedFields
  set args(3) = tableName
  set args(4) = where  
  set args(5) = ..GroupBy
  set args(6) = ..OrderBy
  set args(7) = offset
  set args(8) = limit
  
  return $$$FormatText("SELECT *, %VID AS row FROM (SELECT TOP %1 %2 FROM %3 %4 %5 %6) WHERE %VID BETWEEN %7 AND %8", args...)
}

Method CheckPaginationParameters() [ Private ]
{
     
  #define AppendStatus(%newStatus) set sc = $$$ADDSC(sc, $$$ERROR($$$GeneralError, %newStatus))  
  
  set sc = $$$OK
  set page = $lg(..PaginationParameters)
  set limit = $lg(..PaginationParameters, 2)
  
  if '$isvalidnum(page) $$$AppendStatus("Page must be a number.")
  if page = 0 $$$AppendStatus("Page must be start from 1")
  if page < 0 $$$AppendStatus("Page must be a positive number.")
  
  if '$isvalidnum(page) $$$AppendStatus("Limit must be a number.")
  if page = 0 $$$AppendStatus("Limit must be start from 1")
  if page < 0 $$$AppendStatus("Limit must be a positive number.")
  
  if $$$ISERR(sc) return $$$EMBEDSC($$$ERROR($$$GeneralError, "Invalid pagination parameters."), sc)
  return sc
}

Method CreateWHEREStatement(filter As %String = {..Filter}, type As %String = " AND ", whereStatement As %String = "WHERE ") As %String [ Private ]
{
 
  if filter = "" return ""  
  set where = ""  
  set l = $length(filter, ";")
  
  for i=1:1:l {
    set condition = $piece(filter, ";", i)
    // If ] is found then the builder is trying to capture the same condition, so skip it.   
    if condition?.ANP1"]" = 1 continue
    if $extract(condition, 1, 3)?1"_"1(1"or",1"an") = 1 {
      set conditionType = $$$ucase($extract(condition, $find(condition, "_"), $find(condition, ":") - 2))
      set expression = $$HandleCompositeCondition(condition, conditionType)
    } else {
      set expression = $$HandleSingleCondition(condition)
    }    
    set $list(where, *+1) = expression    
  }
  
  if $ll(where) '= 0 set where = whereStatement_"("_$lts(where, " "_type_" ")_")"
  return where
  
 
HandleSingleCondition(condition)
  // Normalizes field:value to field_eq:value.
  if condition '[ "_" set condition = $piece(condition, ":")_"_eq:"_$piece(condition, ":", 2, *)
  set field = $$$trim($piece(condition, "_"))
  
  // Deep access: a.b = a->b in Caché SQL.
  if field [ "." set field = $replace(field, ".", "->")
  
  set op = $$$trim($piece($piece(condition, "_", 2, 2), ":", 1))
  set value = $piece(condition, ":", 2, *)
  
  set exp = ..TransformFilter(field, value, op)
  return exp
    
HandleCompositeCondition(condition, conditionType)  
  set start = $find(filter, condition) - ($length(condition) - 5)
  set end = $find(filter, "]", start) - 2
  set setStart = start
  if conditionType = "AND" set setStart = start + 1  
  set composition = $extract(filter, setStart, end)
  return ..CreateWHEREStatement(composition, conditionType, "")
}

Method Build() As %Status
{
  set sc = $$$OK
  
  try {
    if ..PaginationParameters '= "" $$$ThrowOnError(..CheckPaginationParameters())
    if ..For = "" $$$ThrowStatus($$$ERROR($$$GeneralError, "For method not called."))
    
    set cclass = ##class(%Dictionary.CompiledClass).%OpenId(..For)
    if cclass = "" $$$ThrowStatus($$$ERROR($$$GeneralError, $$$FormatText("Class '%1' does not exist.", ..For)))
    set tableName = cclass.SqlQualifiedNameQ
  
    if tableName = "" $$$ThrowStatus($$$ERROR($$$GeneralError, "Class does is not a persistent representation."))  
    
    set where = ..CreateWHEREStatement()
    set paginatedQuery = ..WithPagination(where, tableName)
    set statement = paginatedQuery
    
    if statement = "" {
      set statement = $$$FormatText("SELECT %1 FROM %2 %3 %4 %5", ..SelectedFields, tableName, where, ..GroupBy, ..OrderBy)
    }
    
    set ..Result = statement
    return $this
  } catch ex {
    if $data(%frontier) throw ex
    set sc = ex.AsStatus()
  }
  return sc
}

Method TransformFilter(filter As %String, value, op As %String) As %String [ Private ]
{
  set expression = ""
  set singleVarOpTypes = $lb("eq", "ne", "gt", "gte", "lt", "lte", "sw", "nsw", "ct", "nct", "lk", "nlk", "is", "isn", "il", "nil")
  
  if $lf(singleVarOpTypes, op) > 0 {
    if op = "eq" set expression = filter_" = ?"
    if op = "ne" set expression = filter_" <> ?"
    if op = "gt" set expression = filter_" > ?"
    if op = "gte" set expression = filter_" >= ?"
    if op = "lt" set expression = filter_" < ?"
    if op = "lte" set expression = filter_" <= ?"
    if op = "sw" set expression = filter_" %STARTSWITH ? "
    if op = "nsw" set expression = filter_" NOT %STARTSWITH ?"
    if op = "ct" set expression = filter_" [ ?"
    if op = "nct" set expression = filter_" '[ ?"
    if op = "lk" set expression = filter_" LIKE ?"
    if op = "nlk" set expression = filter_" NOT LIKE ?"
    if op = "il" set expression = filter_" %INLIST ?" set value = $lfs(value)
    if op = "nil" set expression = filter_" NOT %INLIST ?" set value = $lfs(value)
    
    if op '= "is" && (op '= "isn") {
      do AddParameter(value)
    } elseif value = "null" {
      set null = $$$ucase(value)
      if op = "is" set expression = filter_" IS "_null
      if op = "isn" set expression = filter_" IS NOT "_null
    }
  } elseif op = "bt" || (op = "nbt") {
    set not = ""
    if op = "nbt" set not = "NOT"
    set left = $piece(value, ",", 1, 1)
    set right = $piece(value, ",", 2, 2)
    set expression = filter_not_" BETWEEN ? AND ? "
    do AddParameter(left)
    do AddParameter(right)
  } elseif op = "in" || (op = "nin") {
    set not = ""
    set phs = ""
    set l = $length(value, ",")
    for i=1:1:l  do AddParameter($piece(value, ",", i)) set $list(phs, *+1) = "?"
    set expression = filter_not_" IN ("_$lts(phs)_")"
  }
  
  return expression
  
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

