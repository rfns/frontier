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
  quit ..IsTypeOf(className, "%SerialObject", 0, "serial")
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
  
  // Uses default %Extends method to check for common cases and improve performance.
  set matches = ##class(%Dictionary.CompiledClass).%ExistsId(className) && $classmethod(className, "%Extends", expectedType)
  if matches = 1 return matches
  
  // Now we check classes that are custom data types.
  set definition = ##class(%Dictionary.CompiledClass).%OpenId(className)
  if $isobject(definition) {
    // This should contain one of: "serial" or "datatype".
    set isExpectedType = (definition.Super [ expectedType || (expectedClassType '= "" && (definition.ClassType = expectedClassType)))
    // If we did not find it, we must traverse the inheritance up to the super.
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

