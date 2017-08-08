Class Frontier.Method [ Abstract ]
{

ClassMethod DescribeArguments(className As %String, methodName As %String, Output describedArguments As %ListOfObjects = "") As %Status
{
  $$$QuitOnError(..AssertMethodExists(className, methodName))
   
  set id = className_"||"_methodName  
  set describedArguments = ##class(%ListOfObjects).%New()
  set formalSpec = ##class(%Dictionary.CompiledMethod).%OpenId(id).FormalSpec
  set currentIndex = 0
  
  while $$ParseArgument(.parsedArgument) {
    set sc = describedArguments.Insert(parsedArgument)
    if $$$ISERR(sc) return sc
  }
  
  return sc 
 
ParseArgument(parsedArgument)
  set currentIndex = currentIndex + 1
  set argument = $piece(formalSpec, ",", currentIndex)
  
  if argument '= "" {
    set parsedArgument = ##class(Frontier.ArgumentDescription).%New()
    if argument [ "..." set parsedArgument.Arity = 1
    set parsedArgument.Name = $replace($piece(argument, ":", 1), "...", "")
    set parsedArgument.DefaultValue = $piece(argument, "=", 2)
    set parsedArgument.Type = $piece($piece(argument, ":", 2), "=")
    quit 1
  }    
  quit 0
}

ClassMethod GetReturnTypeParameters(className As %String, method As %String, Output parameters As %String = "") As %Status
{
  $$$ThrowOnError(..AssertMethodExists(className, method))
  
  set serializedParameters = ##class(%Dictionary.CompiledMethod).%OpenId(className_"||"_method).ReturnTypeParams
  if serializedParameters = "" return $$$OK
  
  set parametersCount = $length(serializedParameters, ",")
  
  for i=1:1:parametersCount {
    set part = $piece(serializedParameters, ",", i)
    set parameterKey = $piece(part, "=", 1)
    set parameterValue = $piece(part, "=", 2)
    set parameters(parameterKey) = parameterValue
  }
  return $$$OK
}

ClassMethod AssertMethodExists(className As %String, methodName As %String) As %Status [ Internal, Private ]
{
  set id = className_"||"_methodName
  
  if '##class(%Dictionary.CompiledClass).%ExistsId(className) {
    return $$$ERROR($$$ClassDoesNotExist, className)   
  }    
  
  if '##class(%Dictionary.CompiledMethod).%ExistsId(id) {
    return $$$ERROR($$$MethodDoesNotExist, methodName)
  }
  return $$$OK
}

ClassMethod PrepareArguments(className As %String, methodName As %String, httpMethod As %String, ByRef routeArgs As %String = 0, ByRef requestArgs As %String = 0, content As %Stream.Object = "", Output args = 0) As %Status
{
  #define TriggerPayloadFlag if httpMethod = "POST" || (httpMethod = "PUT") || (httpMethod = "PATCH") set payloadFound = 1
  #define AssertSinglePayloadParameter throw:payloadFound=1 ##class(%Exception.StatusException).CreateFromStatus($$$ERROR($$$GeneralError, "Cannot have more than one payload for POST/PUT/PATCH request."))
  
  if requestArgs = "" || (requestArgs < 0) return $$$ERROR($$$GeneralError, "request arguments list must have length.")
  $$$QuitOnError(..DescribeArguments(className, methodName, .methodArguments))  
  
  set args = 0
  set argsProcessed = 0
  set argsIndex = 0
  set argKey = ""
  set argValue = ""
  set output = ""
  set sc = $$$OK
  set payloadFound = 0
    
  set methodArgumentsLength = methodArguments.Count()
  if methodArgumentsLength = 0 return $$$OK
  
  set jsonErrorMessage = "Invalid JSON format, expected a %1 compatible notation."
  
  do MergeArguments(.mergedArguments, .sc)
  if $$$ISERR(sc) return sc  
  
  set maxLength = methodArgumentsLength
  if maxLength < mergedArguments set maxLength = mergedArguments
  
  for argsProcessed=1:1:maxLength {    
    set argKey = $order(mergedArguments(argKey), 1, argValue)
    if argKey = "" set argValue = ""    
    set methodArgument = $select(argsProcessed > methodArgumentsLength : methodArguments.GetAt(methodArgumentsLength), 1: methodArguments.GetAt(argsProcessed))
    set value = $select(argValue '= "" : argValue, 1: methodArgument.DefaultValue)
    set output = value 
    
    if ##class(Frontier.Types).IsDynamic(methodArgument.Type) {
      $$$AssertSinglePayloadParameter
      $$$TriggerPayloadFlag      
      set output = $classmethod(methodArgument.Type, "%FromJSON", content)
      if output = "" return $$$ERROR($$$GeneralError, $$$FormatText(jsonErrorMessage, methodArgument.Type))
    } elseif ##class(Frontier.Types).IsZENProxyObject(methodArgument.Type) {
      $$$AssertSinglePayloadParameter
      $$$TriggerPayloadFlag
      set sc = ##class(%ZEN.Auxiliary.altJSONProvider).%ConvertJSONToObject(content,,.output)
      if $$$ISERR(sc) return $$$ERROR($$$GeneralError, $$$FormatText(jsonErrorMessage, methodArgument.Type))
    } elseif ##class(Frontier.Types).IsPersistent(methodArgument.Type) {
      set output = $System.OBJ.OpenId(methodArgument.Type, value)
      if '$isobject(output) set output = ""
    }
    set argsIndex = argsIndex + 1
    set args(argsIndex) = output
  }
  set args = argsProcessed
  zw args
  return sc
  
MergeArguments(mergedArgs, sc)
  #define KeyGroup(%requestKey)  $zstrip($zstrip(%requestKey, "<=N"), "=>N")
  #define KeyIndex(%requestKey)  $zstrip($zstrip(requestKey, "<=N"), "<=A") 
    
  // We need to fix the request parameters first.
  set mergedArgsLength = 0
  set nextKeyIndex = 0
  set lastKeyGroup = ""
  set k = ""    
  set requestKey = ""
  set queryParams = 0
  for {
    set k = $order(requestArgs(k))
    quit:k="" 
    
    set requestKey = k
    
    // Don't depend on query parameter repeatance, because JavaScript cannot repeat object keys.
    // Instead the parameter should follow the pattern "paramN".    
    set value = requestArgs(k, 1)
    
    if k?.A1.2N = 1 {
      set currentKeyGroup = $$$KeyGroup(requestKey)      
      // Removes anything that is not the index located at the end of the key.
      if lastKeyGroup = "" {
        set lastKeyGroup = $$$KeyGroup(requestKey)
      } elseif lastKeyGroup '= currentKeyGroup {      
        set currentKeyGroup = currentKeyGroup
        set nextKeyIndex = 0
      }
      
      set requestKeyIndex = $$$KeyIndex(requestKey)
      set nextKeyIndex = nextKeyIndex + 1
      
      if nextKeyIndex '= requestKeyIndex {
        set sc = $$$ERROR($$$GeneralError, "Rest parameters must be sequential.")
        quit
      }
      set requestKey = currentKeyGroup_requestKeyIndex
    }        
        
    set queryParams(requestKey) = value
    set queryParams = queryParams
  }
  // Now we merge the parameters back, route args always take priority.
  if $$$ISOK(sc) {
    merge mergedArgs = queryParams
    merge mergedArgs = routeArgs
    set k = ""
    for  set k = $order(mergedArgs(k)) quit:k=""  set mergedArgs = mergedArgs + 1    
  }
  quit
}

}

