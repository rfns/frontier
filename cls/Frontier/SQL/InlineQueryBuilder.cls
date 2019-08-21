Include frontier

/// This class can be used to query and return a set of SQL results.
/// You'll probably never have to call it outside the context created by Frontier.
/// 
/// The filter format can be divided into two formats:
/// 
/// Simple: fieldnameA_operation:value;fieldnameB_operation:value
/// Composited: _or:[fieldnameA_operation:value;fieldNameA_operation:value]
/// 
/// Supported operations:
/// 
/// field_eq:value field = value
/// field_neq:value field <> value
/// field_gt:value field > value
/// field_gte:value field >= value
/// field_lt:value field < value
/// field_lte:value field <= value
/// field_sw:value field %STARTSWITH value
/// field_nsw:value field NOT %STARTSWITH value
/// field_ct:value field [ value
/// field_nct:value field '[ value
/// field_lk:%value% field LIKE '%value%'
/// field_nlk:%value% field NOT LIKE '%value%'
/// field_il:v,a,l,u,e  field %INLIST($lfs('v,a,l,u,e'))
/// field_nil:v,a,l,u,e field NOT %INLIST($lfs('v,a,l,u,e'))
/// field_is:null field IS NULL
/// field_isn:null field IS NOT NULL
/// field_bt:0,5 field BETWEEN 0 and 5
/// field_nbt:0,5 field NOT BETWEEN 0 and 5
/// field_in:v,a,l,u,e field IN('v','a','l','u','e')
/// field_nin:v,a,l,u,e field NOT IN('v','a','l','u','e')
/// field:value is translated to field_eq:value
/// 
/// The method "OrderBy" can be used to sort the fields, the syntax is the same as you would use with SQL.
/// The method "Fields" can be used to select the fields you want include in the results.
/// 
/// Note: Both methods will not allow the usage of dubious characters that could into a destructive command.
/// Only alphanumeric inputs are allowed with a few symbols, they are: underscore, dot, asterisk and comma.
/// 
/// Example of usage:
/// 
/// set builder = %frontier.SQL.InlineQueryBuilder("Frontier.UnitTest.Fixtures.Student")
/// 
/// if page '= "" && (limit '= "") do builder.Pagination(page, limit)
/// if orderBy '= "" do builder.OrderBy(orderBy)
/// if groupBy '= "" do builder.GroupBy(groupBy)
/// if filter '= "" do builder.Filter(filter)
/// 
/// return builder.Build().Provide()
Class Frontier.SQL.InlineQueryBuilder Extends %RegisteredObject
{

Property Filter As %String [ Private ];

Property OrderBy As %String [ Private ];

Property Parameters As %String [ MultiDimensional, Private ];

Property PaginationParameters As %List [ Private ];

Property SelectedFields As %String [ InitialExpression = "*", Private ];

Property BuildStatus As %Status [ InitialExpression = 1, Private ];

Property For As %String [ Private ];

Property Result As %String;

Property GroupBy As %String [ Private ];

Method %OnNew(className As %String) As %Status
{
  set i%Parameters = 0
  set ..For = className
  return $$$OK
}

Method Filter(filter) As Frontier.SQL.InlineQueryBuilder
{
  set ..Filter = filter
  return $this
}

Method Pagination(page As %Integer, limit As %String) As Frontier.SQL.InlineQueryBuilder
{
  
  set ..PaginationParameters = $lb(page, limit)
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
  if page = 0 $$$AppendStatus("Page must page must start from 1.")
  if page < 0 $$$AppendStatus("Page must be a positive number.")
  
  if '$isvalidnum(page) $$$AppendStatus("Limit must be a number.")
  if page = 0 $$$AppendStatus("Limit must start from 1.")
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

Method Build(Output sc As %Status = {$$$OK}, Output expression As %String = "", Output parameters As %String = "") As Frontier.SQL.InlineQueryBuilder
{
  set sc = $$$OK
  
  merge parameters = i%Parameters
  
  set ..BuildStatus = sc
  
  try {
    if ..PaginationParameters '= "" $$$ThrowOnError(..CheckPaginationParameters())
    if ..For = "" $$$ThrowStatus($$$ERROR($$$GeneralError, "For method not called."))
    
    set cclass = ##class(%Dictionary.CompiledClass).%OpenId(..For)
    if cclass = "" $$$ThrowStatus($$$ERROR($$$GeneralError, $$$FormatText("Class '%1' does not exist.", ..For)))
    set tableName = cclass.SqlQualifiedNameQ
  
    if tableName = "" $$$ThrowStatus($$$ERROR($$$GeneralError, "Class cannot be projected to SQL."))
    
    set where = ..CreateWHEREStatement()
    set paginatedQuery = ..WithPagination(where, tableName)
    set expression = paginatedQuery
    
    if expression = "" {
      set expression = $$$FormatText("SELECT %1 FROM %2 %3 %4 %5", ..SelectedFields, tableName, where, ..GroupBy, ..OrderBy)
    }
    
    set ..Result = expression    
  } catch ex {
    set ..BuildStatus = ex.AsStatus()
    set sc = ..BuildStatus
  }
  return $this
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
    if op = "nsw" set expression = "NOT "_filter_" %STARTSWITH ?"
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
  
  // Must check if the building phase had any errors.
  $$$ThrowOnError(..BuildStatus)
  
  set params = ""
  merge params = i%Parameters
  set provider = ##class(Frontier.SQL.Provider).%New(..Result)
  if params > 0 $$$ThrowOnError(provider.Parameters(params...))
  return provider
}

}

