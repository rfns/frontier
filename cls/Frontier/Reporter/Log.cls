Include %occErrors

Class Frontier.Reporter.Log Extends (%Persistent, Frontier.Reporter)
{

Parameter DEFAULTLIMIT = 5000;

Property Path As %String(MAXLEN = 500);

Property Route As %String(MAXLEN = 250);

Property IPAddress As %String;

Property HTTPMethod As %String;

Property HTTPStatus As %String;

Property Router As %String;

Property DispatchMethod As %String;

Property Error As %Status;

Property Arguments As %List;

Property Browser As %String(MAXLEN = 500);

Property TS As %DateTime;

Property IncludedCodes As %List [ Internal, Private, Transient ];

Property ExcludedCodes As %List [ Internal, Private, Transient ];

Property Limit As %Integer [ InitialExpression = {..#DEFAULTLIMIT}, Internal, Private, Transient ];

Method %OnNew(configuration As %DynamicObject = {{ "include": [($$$CacheError)] }}) As %Status
{
  if 'configuration.%IsDefined("limit") set ..Limit = ..#DEFAULTLIMIT
  else  set ..Limit = configuration.limit
  
  do ..PopulateList(configuration, "include")
  do ..PopulateList(configuration, "exclude")
  return $$$OK
}

Method PopulateList(configuration As %DynamicArray, key As %String) As %Status [ Private ]
{
  if 'configuration.%IsDefined(key) return $$$OK
  set iterator = configuration.%Get(key).%GetIterator()
  
  while iterator.%GetNext(,.value) { 
    if key = "include" set $list(i%IncludedCodes, *+1) = value 
    else  set $list(i%ExcludedCodes, +1) = value
  }
  
  return $$$OK
}

Method CreateLog(context As Frontier.Context) As %Status [ Private ]
{
   
  set count = ..GetLogCount()  
  if count > ..Limit do ..Shift()
  
  set ..Path = context.Request.URL
  set ..Route = context.Route
  set ..Router = context.ClassName
  set ..HTTPMethod = context.Request.Method
  set ..HTTPStatus = context.Response.Status
  set ..DispatchMethod = context.Method
  set ..Browser = context.Request.GetCgiEnv("HTTP_USER_AGENT")
  set ..Arguments = $$SerializeArguments()
  set ..TS = $zdt($zts, 3)
  set ..IPAddress = context.Request.GetCgiEnv("HTTP_X_FORWARDED_FOR", context.Request.GetCgiEnv("REMOTE_ADDR"))
  set ..Error = context.Exception.AsStatus()
  
  return ..%Save()
  
SerializeArguments()
  set list = ""
  
  for i=1:1:context.ArgumentValues {
    set value = context.ArgumentValues(i)
    if $isobject(value) && value.%Extends("%Persistent") set value = value.%Id()
    set $list(list, *+1) = value
  }  
  return list
}

ClassMethod GetLogCount() As %Integer
{
  set s = ##class(%SQL.Statement).%New()
  set sc = s.%PrepareClassQuery($classname(), "LogCount")
  if $$$ISERR(sc) quit sc
  
  set cursor = s.%Execute()
  set more = cursor.%Next(.sc)
  if $$$ISERR(sc) quit sc
  return cursor.%Get("AMOUNT")
}

ClassMethod Shift() [ Private ]
{
  set s = ##class(%SQL.Statement).%New()
  set sc = s.%Prepare("DELETE TOP 1 FROM FRONTIER_REPORTER.LOG")
  if $$$ISERR(sc) quit sc
  return s.%Execute()
}

Query LogCount() As %SQLQuery [ SqlProc ]
{
  SELECT COUNT(ID) AS AMOUNT FROM FRONTIER_REPORTER.LOG
}

Method Report(context As Frontier.Context) As %Status
{
  if '$lf(i%IncludedCodes, context.Exception.Code) || $lf(i%ExcludedCodes, context.Exception.Code) return $$$OK
  return ..CreateLog(context)
}

Storage Default
{
<Data name="LogDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Path</Value>
</Value>
<Value name="3">
<Value>IPAddress</Value>
</Value>
<Value name="4">
<Value>HTTPMethod</Value>
</Value>
<Value name="5">
<Value>HTTPStatus</Value>
</Value>
<Value name="6">
<Value>Router</Value>
</Value>
<Value name="7">
<Value>DispatchMethod</Value>
</Value>
<Value name="8">
<Value>ErrorData</Value>
</Value>
<Value name="9">
<Value>Arguments</Value>
</Value>
<Value name="10">
<Value>Browser</Value>
</Value>
<Value name="11">
<Value>Route</Value>
</Value>
<Value name="12">
<Value>TS</Value>
</Value>
<Value name="13">
<Value>CodesToCapture</Value>
</Value>
<Value name="14">
<Value>IncludedCodes</Value>
</Value>
<Value name="15">
<Value>ExcludedCodes</Value>
</Value>
<Value name="16">
<Value>Error</Value>
</Value>
</Data>
<DataLocation>^Frontier.Reporter.LogD</DataLocation>
<DefaultData>LogDefaultData</DefaultData>
<IdLocation>^Frontier.Reporter.LogD</IdLocation>
<IndexLocation>^Frontier.Reporter.LogI</IndexLocation>
<StreamLocation>^Frontier.Reporter.LogS</StreamLocation>
<Type>%Library.CacheStorage</Type>
}

}

