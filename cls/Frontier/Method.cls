Include frontier

Class Frontier.Method Extends %RegisteredObject
{

Property MethodArguments As list Of ArgumentDescription;

Property MethodDescriptor As %Dictionary.CompiledMethod [ Private ];

Property ReturnTypeParameters As %String [ MultiDimensional ];

Property Payload As %CacheString;

Property HttpMethod As %String [ InitialExpression = "GET" ];

Property Arguments As %CacheString [ InitialExpression = 0, MultiDimensional, ReadOnly ];

Method %OnNew(className As %String, methodName As %String, RESTMethodArguments As %String = 0, request As %CSP.Request = "") As %Status [ Private ]
{
  set requestQueryParams = 0
  $$$ThrowOnError(..AssertMethodExists(className, methodName))
  
  set ..MethodDescriptor = ##class(%Dictionary.CompiledMethod).%OpenId(className_"||"_methodName)  
  
  $$$ThrowOnError(..DescribeArguments())
  $$$ThrowOnError(..ParseReturnTypeParameters())
  
  if $isobject(request) {
    set ..Payload = request.Content
    set ..HttpMethod = request.Method
    merge requestQueryParams = request.Data
  }
  
  $$$ThrowOnError(..MergeArguments(.RESTMethodArguments, .requestQueryParams, .mergedArguments))    
  
  $$$ThrowOnError(..Sequentialize(.mergedArguments))
  quit $$$OK
}

Method DescribeArguments() As %Status [ Private ]
{
  set sc = $$$OK
  set describedArguments = ##class(%ListOfObjects).%New()
  set formalSpec = ..MethodDescriptor.FormalSpec
  set currentIndex = 0
  
  while $$ParseArgument(.parsedArgument) {
    set sc = ..MethodArguments.Insert(parsedArgument)
    if $$$ISERR(sc) return sc
  }
  
  return sc 
 
ParseArgument(parsedArgument)
  set currentIndex = currentIndex + 1
  set argument = $piece(formalSpec, ",", currentIndex)
  
  if argument '= "" {
    set parsedArgument = ##class(Frontier.ArgumentDescription).%New()
    if argument [ "..." set parsedArgument.Arity = 1
    set parsedArgument.Name = $piece($replace($piece(argument, ":", 1), "...", ""), "=", 1)
    set parsedArgument.DefaultValue = $piece(argument, "=", 2)    
    set parsedArgument.Index = currentIndex
    set preType = $piece(argument, ":", 2)
    if preType [ "(" {
      set parsedArgument.Type = $extract(preType, 1, $find(preType, "(") - 2)
      set argumentParameters = $extract(preType, $find(preType, "("), $find(preType, ")") - 2)
      if '$find(argumentParameters, ",") set argumentParameters = argumentParameters_","
      for i=1:1:$length(argumentParameters, ",") {
        set argumentParameter = $piece(argumentParameters, ",", i)
        set parameterName = $piece(argumentParameter, "=")
        set parameterValue = $$$trimQuote($piece(argumentParameter, "=", 2))
        do parsedArgument.Parameters.SetAt(parameterValue, parameterName)
        if parameterName = "ALIAS" set parsedArgument.Alias = parameterValue
      }
    } else {
      set parsedArgument.Type = preType
    }
    quit 1
  }    
  quit 0
}

Method FindDescribedArgument(identifier As %String) As Frontier.ArgumentDescription [ Internal, Private ]
{
  
  for i=1:1:..MethodArguments.Count() {
    set argument = ..MethodArguments.GetAt(i)
    if argument.Name = identifier || (argument.Alias = identifier) return argument
  }
  return ""
}

Method ParseReturnTypeParameters() As %Status [ Private ]
{
  set serializedParameters = ..MethodDescriptor.ReturnTypeParams
  if serializedParameters = "" return $$$OK
  set parametersCount = $length(serializedParameters, ",")  
  
  for i=1:1:parametersCount {
    set part = $piece(serializedParameters, ",", i)
    set parameterKey = $piece(part, "=", 1)
    set parameterValue = $piece(part, "=", 2)
    set i%ReturnTypeParameters(parameterKey) = parameterValue
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

Method Sequentialize(ByRef mergedArguments = 0) As %Status [ Private ]
{
 
  #define TriggerPayloadFlag if ..HttpMethod = "POST" || (..HttpMethod = "PUT") || (..HttpMethod = "PATCH") set payloadFound = 1
  #define AssertSinglePayloadParameter throw:payloadFound=1 ##class(%Exception.StatusException).CreateFromStatus($$$ERROR($$$GeneralError, "Cannot have more than one payload for POST/PUT/PATCH requests."))
  
  set sc = $$$OK  
  
  set argsProcessed = 0  
  set payloadFound = 0
    
  set methodArgumentsLength = ..MethodArguments.Count()
  
  set jsonErrorMessage = "Invalid JSON format, expected a %1 compatible notation."  
  if $$$ISERR(sc) return sc  
  
  set maxLength = methodArgumentsLength
  if maxLength < mergedArguments set maxLength = mergedArguments
        
  if methodArgumentsLength > 0 {
    for argsProcessed=1:1:maxLength {       
      set methodArgument = $select(argsProcessed > methodArgumentsLength 
        :  ..MethodArguments.GetAt(methodArgumentsLength), 
        1: ..MethodArguments.GetAt(argsProcessed)
      )
      set value = $get(mergedArguments(argsProcessed))
    
      if value = "" {
        if 'methodArgument.Arity set value = methodArgument.DefaultValue
        else  set value = $get(mergedArguments(methodArgument.Index))
      }       
    
      if ##class(Frontier.Types).IsDynamic(methodArgument.Type) {
        $$$AssertSinglePayloadParameter
        $$$TriggerPayloadFlag
        set value = $classmethod(methodArgument.Type, "%FromJSON", ..Payload)
        if value = "" return $$$ERROR($$$GeneralError, $$$FormatText(jsonErrorMessage, methodArgument.Type))
      } elseif ##class(Frontier.Types).IsZENProxyObject(methodArgument.Type) {
        $$$AssertSinglePayloadParameter
        $$$TriggerPayloadFlag
        set sc = ##class(%ZEN.Auxiliary.altJSONProvider).%ConvertJSONToObject(..Payload,,.value)
        if $$$ISERR(sc) return $$$ERROR($$$GeneralError, $$$FormatText(jsonErrorMessage, methodArgument.Type))
      } elseif ##class(Frontier.Types).IsPersistent(methodArgument.Type) {
        set value = $System.OBJ.OpenId(methodArgument.Type, value)
        if '$isobject(value) set value = ""
      }
      set i%Arguments(argsProcessed) = value
    }
  }
  set i%Arguments = argsProcessed
  return sc
}

Method MergeArguments(ByRef routeArguments As %String = 0, ByRef requestArguments As %String = 0, Output preArguments As %String = 0) As %Status [ Private ]
{
  
  set argumentIndex = routeArguments 
  set nextKeyIndex = 0
  set key = ""
  set preArguments = 0
  set methodArgumentsLength = ..MethodArguments.Count()  

  for {
    set key = $order(requestArguments(key))
    quit:key=""    
    
    set keyGroup = $$$KeyGroup(key)
    set methodArgument = ..FindDescribedArgument(keyGroup)
    
    if '$isobject(methodArgument) {
      return $$$ERROR($$$GeneralError, "Formal spec doesn't match with request: "_keyGroup_" was not expected.")
    }
    
    // Don't depend on query parameter repeatance, because JavaScript cannot repeat object keys.
    // Instead the parameter should follow the pattern "paramN" which represents a sequence.    
    set value = requestArguments(key, 1)  
    
    // Checks if we have a sequenced query param.
    if key?.A1.2N {               
      if methodArgumentsLength > 1 {     
        set argumentIndex = methodArgumentsLength + nextKeyIndex
      } else {
        set argumentIndex = nextKeyIndex + 1
      }
      
      set nextKeyIndex = nextKeyIndex + 1
      
      if nextKeyIndex '= $$$KeyIndex(key) {
        return $$$ERROR($$$GeneralError, keyGroup_" was expected to be sequential.")
      }
    } else {
      set argumentIndex = methodArgument.Index
    }
    set preArguments(argumentIndex) = value  
  }  
  
  // Now we must merge the arguments, remember that route arguments always take priority.    
  merge preArguments = routeArguments
  set preArguments = argumentIndex
  return $$$OK
}

}

