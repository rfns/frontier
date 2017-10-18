Include frontier

Class Frontier.Types [ Abstract ]
{

ClassMethod IsInstantiable(className As %String) As %Boolean
{
  quit ..IsTypeOf(className, "%RegisteredObject")
}

ClassMethod IsPersistent(className As %String) As %Boolean
{
  quit ..IsTypeOf(className, "%Persistent")
}

ClassMethod IsDataType(className As %String) As %Boolean
{
  quit ..IsTypeOf(className, "%DataType")
}

ClassMethod IsStream(className As %String) As %Boolean
{
  quit ..IsTypeOf(className, "%Stream.Object")
}

ClassMethod IsCollection(className As %String) As %Boolean
{
  quit ..IsTypeOf(className, "%Collection.AbstractIterator")
}

ClassMethod IsSerial(className As %String) As %Boolean
{
  quit ..IsTypeOf(className, "%SerialObject")
}

ClassMethod IsDynamic(className As %String) As %Boolean
{
  return ..IsTypeOf(className, "%DynamicAbstractObject")
}

ClassMethod IsDynamicArray(className As %String) As %Boolean
{
  return ..IsTypeOf(className, "%DynamicArray")
}

ClassMethod IsDynamicObject(className As %String) As %Boolean
{
  return ..IsTypeOf(className, "%DynamicObject")
}

ClassMethod IsZENProxyObject(className As %String) As %Boolean
{
  return ..IsTypeOf(className, "%ZEN.proxyObject")
}

ClassMethod IsSQLProvider(className As %String) As %Boolean
{
  return ..IsTypeOf(className, "Frontier.SQL.Provider")
}

ClassMethod IsTypeOf(className As %String, expectedType As %String) As %Boolean [ Final, Private ]
{
   
  if className = "" quit 0
  
  $$$NormalizeClassName(className)
  $$$NormalizeClassName(expectedType)  
  
  if className = expectedType return 1
  
  // Uses default %Extends method to check for common cases and improve performance.
  return ##class(%Dictionary.CompiledClass).%ExistsId(className) && $classmethod(className, "%Extends", expectedType)
}

ClassMethod GetJSONDataFormat(cacheType As %String) As %String [ Internal ]
{
  
  $$$NormalizeClassName(cacheType)
  
  if ..IsDataType(cacheType) {
    set type = $case(cacheType,
      "%Library.Boolean": "boolean",
      "%Library.Double": "number",
      "%Library.BigInt": "number",
      "%Library.TinyInt": "number",
      "%Library.Decimal": "number",
      "%Library.Integer": "number",
      "%Library.Float": "number",
      "%Library.Date": "number",
      "%Library.Time": "number",
      "%Library.DateTime": "number",
      "%Library.TimeStamp": "number",
      : "string")
  } else {
    set type = "null"
  }
  return type
}

}

