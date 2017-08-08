Class UnitTest.Frontier.Helpers [ Abstract ]
{

Method DeepCompare(object As %Persistent, dynamic As %DynamicAbstractObject, i = "")
{
  set sc = $$$OK
  
  #dim iterator as %Iterator.AbstractIterator
  set iterator = dynamic.%GetIterator()
  
  while iterator.getNext(.key, .dynamicValue) {
    set propertyDescriptor = ##class(%Dictionary.CompiledProperty).%OpenId($classname(object)_"||"_key)
    set skipCurrent = 0
    set objectValue = ..GetDeepChildPropertyValue(object, $replace(key, "_", "."))
    if $isobject(objectValue) {
      if ##class(Frontier.Types).IsPersistent(propertyDescriptor.RuntimeType) set objectValue = objectValue.%Id()
      if ##class(Frontier.Types).IsStream(propertyDescriptor.RuntimeType) set objectValue = objectValue.Read()
    }
    if $isobject(dynamic) && $isobject(objectValue) {
      if dynamic.%Extends("%DynamicArray") {
        if $isobject(dynamic.%Get(1)) {
          for j=1:1:dynamic.Count() {
            set childObject = objectValue.GetAt(j)
            set childDynamicObject = dynamic.%Get(j)    
            set sc = ..DeepCompare(childObject, childDynamicObject, j)
            if $$$ISERR(sc) quit            
          }
        }
      }
    } elseif '$isobject(dynamicValue) && '$isobject(objectValue) {
      if dynamicValue = "" set dynamicValue = "<EMPTY>"
      if objectValue = "" set objectValue = "<EMPTY>"
      if dynamicValue '= objectValue {
        set sc = $$$ERROR($$$GeneralError, $$$FormatText("Assertion error: %1property %2, where dynamic value '= object value. Mismatch: %3 '= %4", $select(i = "" : i, 1: "index at "_i_", "), key, dynamicValue, objectValue))
      }
    }    
  }
  quit sc
}

ClassMethod GetDeepChildPropertyValue(parent As %RegisteredObject, composedKey As %String) As %RegisteredObject
{
  set nextParent = parent
  set deepestLevel = $length(composedKey, ".")
  for i=1:1:deepestLevel {
    set nextParent = $property(nextParent, $piece(composedKey, ".", i, i))   
  }
  quit nextParent
}

}

