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
  
  #define NormalizeClassName(%cn) if $l(%cn, ".") = 1 && ($e(%cn) = "%") set %cn = "%Library."_$e(%cn, 2, *)   
  if className = "" quit 0
  
  $$$NormalizeClassName(className)
  $$$NormalizeClassName(expectedType)  
  
  if className = expectedType return 1
  
  // Uses default %Extends method to check for common cases and improve performance.
  return ##class(%Dictionary.CompiledClass).%ExistsId(className) && $classmethod(className, "%Extends", expectedType)
}

}

