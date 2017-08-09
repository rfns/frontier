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
    set parsedArgument.Index = currentIndex
    quit 1
  }    
  quit 0
}

ClassMethod DescribeSingleArgumentByIndex(className As %String, methodName As %String, Output parsedArgument As Frontier.ArgumentDescription = "", index As %Integer = 1) As %Status
{
  $$$QuitOnError(..AssertMethodExists(className, methodName))
  
  set id = className_"||"_methodName  
  set describedArguments = ##class(%ListOfObjects).%New()
  set formalSpec = ##class(%Dictionary.CompiledMethod).%OpenId(id).FormalSpec   
  
  set argumentSpec = $piece(formalSpec, ",", index)
  if index < 1 set index = 1
  
  if argumentSpec '= "" {
    set parsedArgument = ##class(Frontier.ArgumentDescription).%New()
    if argumentSpec [ "..." set parsedArgument.Arity = 1
    set parsedArgument.Name = $replace($piece(argumentSpec, ":", 1), "...", "")
    set parsedArgument.DefaultValue = $piece(argumentSpec, "=", 2)
    set parsedArgument.Type = $piece($piece(argumentSpec, ":", 2), "=")
    set parsedArgument.Index = index
    quit 1
  }
}

ClassMethod FindDescribedArgumentByName(describedArguments As %ListOfObjects, name As %String) As Frontier.ArgumentDescription [ Internal, Private ]
{
  
  for i=1:1:describedArguments.Count() {
    set describedArgument = describedArguments.GetAt(i)
    if describedArgument.Name = name return describedArgument
  }
  return ""
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
  #define KeyGroup(%requestKey)  $zstrip($zstrip(%requestKey, "<=N"), "=>N")
  #define KeyIndex(%requestKey)  $zstrip($zstrip(%requestKey, "<=N"), "<=A")   
  
  if requestArgs = "" || (requestArgs < 0) return $$$ERROR($$$GeneralError, "request arguments list must have length.")
  $$$QuitOnError(..DescribeArguments(className, methodName, .methodArguments))    
  
  set sc = $$$OK
  
  set args = 0
  set argsProcessed = 0  
  set payloadFound = 0
    
  set methodArgumentsLength = methodArguments.Count()
  if methodArgumentsLength = 0 return $$$OK
  
  set jsonErrorMessage = "Invalid JSON format, expected a %1 compatible notation."
  
  do MergeArguments(.mergedArguments, .sc)
  if $$$ISERR(sc) return sc  
  
  set maxLength = methodArgumentsLength
  if maxLength < mergedArguments set maxLength = mergedArguments  
  
  for argsProcessed=1:1:maxLength {
    set methodArgument = $select(argsProcessed > methodArgumentsLength : methodArguments.GetAt(methodArgumentsLength), 1: methodArguments.GetAt(argsProcessed))
    set value = $get(mergedArguments(argsProcessed))
    
    if value = "" {
      if 'methodArgument.Arity set value = methodArgument.DefaultValue
      else  set value = $get(mergedArgs(methodArgument.Index))
    }       
    
    if ##class(Frontier.Types).IsDynamic(methodArgument.Type) {
      $$$AssertSinglePayloadParameter
      $$$TriggerPayloadFlag      
      set value = $classmethod(methodArgument.Type, "%FromJSON", content)
      if value = "" return $$$ERROR($$$GeneralError, $$$FormatText(jsonErrorMessage, methodArgument.Type))
    } elseif ##class(Frontier.Types).IsZENProxyObject(methodArgument.Type) {
      $$$AssertSinglePayloadParameter
      $$$TriggerPayloadFlag
      set sc = ##class(%ZEN.Auxiliary.altJSONProvider).%ConvertJSONToObject(content,,.value)
      if $$$ISERR(sc) return $$$ERROR($$$GeneralError, $$$FormatText(jsonErrorMessage, methodArgument.Type))
    } elseif ##class(Frontier.Types).IsPersistent(methodArgument.Type) {
      set value = $System.OBJ.OpenId(methodArgument.Type, value)
      if '$isobject(value) set value = ""
    }
    set args(argsProcessed) = value
  }  
  set args = argsProcessed
  return sc
  
MergeArguments(arguments, sc)
  // We need to fix the request parameters first.
  set argumentIndex = 0  
  set nextKeyIndex = 0
  set key = ""
  set arguments = 0  

  for {
    set key = $order(requestArgs(key))
    quit:key=""
    
    set keyGroup = $$$KeyGroup(key)
    set methodArgument = ..FindDescribedArgumentByName(methodArguments, keyGroup)
    if '$isobject(methodArgument) {
      set sc = $$$ERROR($$$GeneralError, "Formal spec doesn't match with request: "_keyGroup_" was not expected.")
      quit
    }
    
    // Don't depend on query parameter repeatance, because JavaScript cannot repeat object keys.
    // Instead the parameter should follow the pattern "paramN" which represents a sequence.    
    set value = requestArgs(key, 1)  
    
    // Checks if we have a sequenced query param.
    if key?.A1.2N {               
      if methodArgumentsLength > 1 {     
        set argumentIndex = methodArgumentsLength + nextKeyIndex
      } else {
        set argumentIndex = nextKeyIndex + 1
      }
      
      set nextKeyIndex = nextKeyIndex + 1
      
      if nextKeyIndex '= $$$KeyIndex(key) {
        set sc = $$$ERROR($$$GeneralError, keyGroup_" was expected to be sequential.")
        quit
      }
    } else {
      set argumentIndex = methodArgument.Index
    }
    set arguments(argumentIndex) = value  
  }  
  // Now we merge the arguments, route arguments always take priority.
  if $$$ISOK(sc) {    
    merge arguments = routeArgs
    set arguments = argumentIndex
  }
  quit
}

}

