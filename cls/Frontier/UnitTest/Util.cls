Class Frontier.UnitTest.Util [ Abstract ]
{

Parameter NAME = "/api/frontier/test/";

ClassMethod CreateWebApplication() As %Status
{
  set targetNamespace = $namespace
  
  new $namespace  
  set $namespace = "%SYS"
  
  write !, ">> Creating demo web application using namespace "_targetNamespace_" ..."
  if ##class(Security.Applications).Exists(..#NAME) {
    write !, ">> Application already exists, skipping ..."
    return $$$OK
  }
  
  set properties("CookiePath") = ..#NAME
  set properties("DispatchClass") = "Frontier.UnitTest.Router"
  set properties("NameSpace") = targetNamespace
  set properties("UseCookies") = 2
  set properties("AutheEnabled") = 64
  
  $$$QuitOnError(##class(Security.Applications).Create(..#NAME, .properties))
  write !, ">> Application /api/frontier/test has been created."
  return $$$OK
}

ClassMethod RemoveWebApplication() As %Status
{
  new $namespace
  set $namespace = "%SYS"
  
  if '##class(Security.Applications).Exists(..#NAME) return $$$OK
  write !, ">> Deleting demo web application "_..#NAME_" ..."
  
  $$$QuitOnError(##class(Security.Applications).Delete(..#NAME))
  write !, ">> Web application has been deleted with success."
  
  return $$$OK
}

ClassMethod MergeErrors(errors As %DynamicArray) As %Status
{
  
  set sc = $$$OK
  
  for i=0:1:(errors.%Size() - 1) {
    set errorObject = errors.%Get(i)
    set sc = $$$ADDSC(sc, $$$ERROR(errorObject.code, errorObject.params.%Get(0)))
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

ClassMethod MarshallSQLResult(SQLResult As %IResultSet, Output dynamicArray As %DynamicArray) As %Status
{
  set sc = $$$OK
  set dynamicArray = []
  set columnInfo = ""
  
  set columnsCount = SQLResult.%ResultColumnCount
  for c = 1:1:columnsCount {
    set columnInfo(c,"name") = SQLResult.%GetMetadata().columns.GetAt(c).label
  }  
  
  while (SQLResult.%Next(.sc)) {
    quit:$$$ISERR(sc)
    set node = {}
    for c = 1:1:SQLResult.%ResultColumnCount {
      set value = SQLResult.%GetData(c)
        
      if ($isvalidnum(value) && ($e(value) '= 0)) do node.%Set($get(columnInfo(c,"name")),$num(value),"number")
      else  do node.%Set($get(columnInfo(c,"name")),value)
    }
    Do dynamicArray.%Push(node)
  }
  return sc
}

}

