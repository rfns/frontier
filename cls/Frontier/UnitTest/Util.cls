Class Frontier.UnitTest.Util [ Abstract ]
{

Parameter FRONTIERTESTURL = "/api/frontier/test";

ClassMethod CreateWebApp() As %Status
{
  set ns = $namespace
  new $namespace
  
  set $namespace = "%SYS"  
  set properties("NameSpace") = ns
  set properties("DispatchClass") = "Frontier.UnitTest.Router"  
  
  if ##class(Security.Applications).Exists(..#FRONTIERTESTURL) {
    $$$QuitOnError(..DestroyWebApp())
  }
  return ##class(Security.Applications).Create(..#FRONTIERTESTURL, .properties)
}

ClassMethod DestroyWebApp() As %Status
{
  
  set ns = $namespace
  new $namespace
  
  set $namespace = "%SYS"
  do ##class(%File).RemoveDirectoryTree($System.Util.InstallDirectory()_"csp/frontier")
  return ##class(Security.Applications).Delete(..#FRONTIERTESTURL)
}

ClassMethod MergeErrors(errors As %DynamicArray) As %Status
{
  
  set sc = $$$OK
  
  for i=0:1:errors.%Size() {
    set errorObject = errors.%Get(i)
    set sc = $$$ADDSC(sc, $$$ERROR(errorObject.code, errorObject.params.%GetAt(0)))
  }
  
  return sc
}

Method DeepCompare(currentPersistent As %Persistent, currentProxy As JQX.ProxyObject, i = "")
{
  set sc = $$$OK
  
  while currentProxy.Next(.key, .proxyValue) {
    set propertyDescriptor = ##class(%Dictionary.CompiledProperty).%OpenId($classname(currentPersistent)_"||"_key)
    set skipCurrent = 0
    set entityValue = ..GetDeepChildPropertyValue(currentPersistent, $replace(key, "_", "."))
    if $isobject(entityValue) {
      if ##class(JQX.Utils.Descriptor).IsPersistent(propertyDescriptor.RuntimeType) set entityValue = entityValue.%Id()
      if ##class(JQX.Utils.Descriptor).IsStream(propertyDescriptor.RuntimeType) set entityValue = entityValue.Read()
    }
    if $isobject(proxyValue) && $isobject(entityValue) {
      if proxyValue.%Extends("%Collection.AbstractList") {
        if $isobject(proxyValue.GetAt(1)) {        
          for j=1:1:proxyValue.Count() {
            set childEntityObject = entityValue.GetAt(j)
            set childProxyObject = proxyValue.GetAt(j)    
            set sc = ..CompareValues(childEntityObject, childProxyObject, j)
            if $$$ISERR(sc) quit            
          }
        }
      }
    } elseif '$isobject(proxyValue) && '$isobject(entityValue) {
      if proxyValue = "" set proxyValue = "<EMPTY>"
      if entityValue = "" set entityValue = "<EMPTY>"
      if entityValue '= proxyValue {
        set sc = $$$ERROR($$$GeneralError, $$$FormatText("Assertion error: %1property %2, where prox value '= entity value. Mismatch: %3 '= %4", $select(i = "" : i, 1: "index at "_i_", "), key, proxyValue, entityValue))
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

