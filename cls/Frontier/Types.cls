Class Frontier.Types [ Abstract ]
{

ClassMethod IsInstantiable(className As %String) As %Boolean
{
  quit ..IsTypeOf(className, "%RegisteredObject", 0, "")
}

ClassMethod IsPersistent(className As %String) As %Boolean
{
  quit ..IsTypeOf(className, "%Persistent", 0, "")
}

ClassMethod IsDataType(className As %String) As %Boolean
{
  quit ..IsTypeOf(className, "%DataType", 0, "datatype")
}

ClassMethod IsStream(className As %String) As %Boolean
{
  quit ..IsTypeOf(className, "%Stream.Object", 0, "")
}

ClassMethod IsCollection(className As %String) As %Boolean
{
  quit ..IsTypeOf(className, "%Collection.AbstractIterator", 0, "")
}

ClassMethod IsSerial(className As %String) As %Boolean
{
  quit ..IsTypeOf(className, "%Serial", 0, "serial")
}

ClassMethod IsDynamic(className As %String) As %Boolean
{
  return ..IsTypeOf(className, "%DynamicAbstractObject", 0)
}

ClassMethod IsDynamicArray(className As %String) As %Boolean
{
  return ..IsTypeOf(className, "%DynamicArray", 0)
}

ClassMethod IsDynamicObject(className As %String) As %Boolean
{
  return ..IsTypeOf(className, "%DynamicObject", 0)
}

ClassMethod IsZENProxyObject(className As %String) As %Boolean
{
  return ..IsTypeOf(className, "%ZEN.proxyObject", 0)
}

ClassMethod IsTypeOf(className As %String, expectedType As %String, whenNull As %String = 0, expectedClassType As %String = "") As %Boolean [ Final, Private ]
{
  #define NormalizeClassName(%cn) if $l(%cn, ".") = 1 && ($e(%cn) = "%") set %cn = "%Library."_$e(%cn, 2, *)
  
  set isExpectedType = whenNull
  if className = "" quit isExpectedType
  
  $$$NormalizeClassName(className)
  $$$NormalizeClassName(expectedType)  
  
  if className = expectedType return 1
  
  set definition = ##class(%Dictionary.CompiledClass).%OpenId(className)
  if $isobject(definition) {
    // Checks if current is truly an expectedType.
    set isExpectedType = (definition.Super [ expectedType || (expectedClassType '= "" && (definition.ClassType = expectedClassType)))
    if 'isExpectedType {
      if definition.Super [ "," {
        if definition.Inheritance '= "right" {
          for i=1:1:$length(definition.Super, ",") {     
            set superClass = $piece(definition.Super, ",", i)
            set isExpectedType = ..IsTypeOf(superClass, expectedType, whenNull, expectedClassType)
            if isExpectedType return isExpectedType
          }
        } else {
          for i=$length(definition.Super, ","):-1:1 {     
            set superClass = $piece(definition.Super, ",", i)
            set isExpectedType = ..IsTypeOf(superClass, expectedType, whenNull, expectedClassType)            
            if isExpectedType return isExpectedType
          }          
        }
      } else {
        set isExpectedType = ..IsTypeOf(definition.Super, expectedType, whenNull, expectedClassType)
      }
    }       
  }  
  return isExpectedType
}

}

