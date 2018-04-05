Include frontier

Class Frontier.Method Extends %RegisteredObject
{

Property DispatchClass As %String;

Property DispatchMethod As %String;

Property MethodArguments As list Of ArgumentDescription;

Property MethodDescriptor As %Dictionary.CompiledMethod [ Private ];

Property ReturnTypeParameters As %String [ MultiDimensional ];

Property ReturnType As %String;

Property Payload As %CacheString;

Property HttpMethod As %String [ InitialExpression = "GET" ];

Property Arguments As %CacheString [ InitialExpression = 0, MultiDimensional, ReadOnly ];

Method %OnNew(className As %String, methodName As %String, RESTMethodArguments As %String = 0, request As %CSP.Request = "", propertyFormatter As Frontier.PropertyFormatter = "", strictQueryParameters As %Boolean = 1, ByRef matches As %String = 0) As %Status [ Private ]
{
  set requestQueryParams = 0
  $$$ThrowOnError(..AssertMethodExists(className, methodName))
  
  set ..DispatchClass = className
  set ..DispatchMethod = methodName  
  set ..MethodDescriptor = ##class(%Dictionary.CompiledMethod).%OpenId(className_"||"_methodName)  
  
  $$$ThrowOnError(..DescribeArguments())
  $$$ThrowOnError(..ParseReturnTypeParameters())
  
  if ..MethodDescriptor.ReturnType = "" {
    $$$ThrowOnError($$$ERROR($$$GeneralError, $$$FormatText("Expected a return type for method %1.", methodName)))
  }  
  
  if $isobject(request) {
    set ..Payload = request.Content
    set ..HttpMethod = request.Method
    merge requestQueryParams = request.Data
  }
  
  if matches = "" {
    $$$ThrowOnError(..MergeArguments(.RESTMethodArguments, .requestQueryParams, .mergedArguments, strictQueryParameters)) 
    $$$ThrowOnError(..Sequentialize(.mergedArguments, propertyFormatter))
  } else {
    set i%Arguments = matches
    merge i%Arguments = matches
  }   
  quit $$$OK
}

Method DescribeArguments() As %Status [ Private ]
{
  set sc = $$$OK
  set describedArguments = ##class(%ListOfObjects).%New()
  set formalSpec = ..MethodDescriptor.FormalSpec
  set currentIndex = 0
  set currentPiece = 0
  
  while $$ParseArgument(.parsedArgument) {
    set sc = ..MethodArguments.Insert(parsedArgument)
    if $$$ISERR(sc) return sc
  }
  
  return sc 
 
ParseArgument(parsedArgument)
  set currentIndex = currentIndex + 1
  set currentPiece = currentPiece + 1
  set argument = $piece(formalSpec, ",", currentPiece)
  
  if argument [ "(" {
    while '$find(argument, ")") {
      set currentPiece = currentPiece + 1
      set argument = argument_","_$piece(formalSpec, ",", currentPiece)
    }
  }    
  
  if argument '= "" {
    set parsedArgument = ##class(Frontier.ArgumentDescription).%New()
    if argument [ "..." set parsedArgument.Arity = 1
    set parsedArgument.Name = $piece($replace($piece(argument, ":", 1), "...", ""), "=", 1)       
    set parsedArgument.Index = currentIndex
    set preType = $piece(argument, ":", 2)    
    if preType [ "(" {      
      set parsedArgument.Type = $extract(preType, 1, $find(preType, "(") - 2)
      set maybeDefault = $piece(preType, "=", *)
      if $extract(maybeDefault, *) = ")" set maybeDefault = ""
      set parsedArgument.DefaultValue = $$$trimQuote(maybeDefault)
      set argumentParameters = $extract(preType, $find(preType, "("), $find(preType, ")") - 2)
      if '$find(argumentParameters, ",") set argumentParameters = argumentParameters_","
      for i=1:1:$length(argumentParameters, ",") {
        set argumentParameter = $piece(argumentParameters, ",", i)
        quit:argumentParameter=""
        set parameterName = $piece(argumentParameter, "=")
        set parameterValue = $$$trimQuote($piece(argumentParameter, "=", 2))
        do parsedArgument.Parameters.SetAt(parameterValue, parameterName)
        if parameterName = "ALIAS" set parsedArgument.Alias = parameterValue
      }
    } else {      
      set parsedArgument.Type = $piece(preType, "=", 1)
      set defaultQuotedValue = $piece(preType, "=", 2)
      if defaultQuotedValue '= "" {
        set parsedArgument.DefaultValue = $$$trimQuote(defaultQuotedValue)
        set parsedArgument.HasDefaultValue = 1
      }
    }
    return 1
  }    
  return 0
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

Method Sequentialize(ByRef mergedArguments = 0, propertyFormatter As Frontier.PropertyFormatter = "") As %Status [ Private ]
{
  #dim methodArgument As Frontier.ArgumentDescription
  #define TriggerPayloadFlag if ..HttpMethod = "POST" || (..HttpMethod = "PUT") || (..HttpMethod = "PATCH") set payloadFound = 1
  #define AssertSinglePayloadParameter throw:payloadFound=1 ##class(%Exception.StatusException).CreateFromStatus($$$ERROR($$$GeneralError, "Cannot have more than one payload for POST/PUT/PATCH requests."))
  
  set sc = $$$OK  
  
  set argsProcessed = 0  
  set payloadFound = 0
    
  set methodArgumentsLength = ..MethodArguments.Count()
  
  set jsonErrorMessage = "Invalid JSON payload: expected a %1 compatible notation."  
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
        if ..Payload = "" return $$$ERROR($$$GeneralError, $$$FormatText(jsonErrorMessage, methodArgument.Type))
        $$$AssertSinglePayloadParameter
        $$$TriggerPayloadFlag
        set unmarshallTo = methodArgument.Parameters.GetAt("UNMARSHALLTO")
        set idFrom = methodArgument.Parameters.GetAt("IDFROM")
        set value = $classmethod(methodArgument.Type, "%FromJSON", ..Payload)
        if unmarshallTo '= "" {
          set instanceId = value."__id__"    
          if idFrom '= "" {
            set value."__id__" = $get(mergedArguments(..FindDescribedArgument(idFrom).Index))
            if value."__id__" = "" set value."__id__" = instanceId
          }
          if value."__id__" = "" && (..HttpMethod = "PUT" || (..HttpMethod = "PATCH")) {
            return $$$ERROR($$$GeneralError, "Cannot unmarshall payload: a PUT/PATCH request requires an identifier.")
          }
          set sc = ##class(Frontier.Dynamic.Unmarshaller).Unmarshall(unmarshallTo, value, .instance, propertyFormatter)
          if $$$ISERR(sc) return sc
          set value = instance
        } else {
          if value = "" return $$$ERROR($$$GeneralError, $$$FormatText(jsonErrorMessage, methodArgument.Type))
        }
      } elseif ##class(Frontier.Types).IsPersistent(methodArgument.Type) {
        set value = $System.OBJ.OpenId(methodArgument.Type, value)
        if '$isobject(value) set value = ""
      } elseif methodArgument.Type = "%Boolean" {
        // Attempts to convert true to 1 and false to 0, resolve to itself if input is not a boolean candidate.
        set value = $$$BooleanToBinary(value)
      }
      set i%Arguments(argsProcessed) = value
    }
  }
  set i%Arguments = argsProcessed
  return sc
}

Method MergeArguments(ByRef routeArguments As %String = 0, ByRef requestArguments As %String = 0, Output preArguments As %String = 0, strictMode As %Boolean = 1) As %Status [ Private ]
{
     
  // Conformity check:
  // 1 - No weak typing: All arguments must have a type provided.
  // 2 - Default values must be specified if optional.
  // 3 - Arity arguments must follow argumentnameN format, where N is an index.
  // 4 - Payloads must not have default values.
  // 5 - Each method must have only one payloadable type (%DynamicObject or DynamicArray).  
  
  set argumentIndex = routeArguments 
  set nextKeyIndex = 0
  set key = ""
  set preArguments = 0
  set methodArgumentsLength = ..MethodArguments.Count()
  set keysFound = ""

  for {
    set key = $order(requestArguments(key))
    quit:key=""    
    
    set keyGroup = $$$KeyGroup(key)
    set $list(keysFound, *+1) = keyGroup
    set methodArgument = ..FindDescribedArgument(key)
    
    if '$isobject(methodArgument) {
      set methodArgument = ..FindDescribedArgument(keyGroup)
    }
    
    if '$isobject(methodArgument) {
      if strictMode {
        return $$$ERROR($$$GeneralError, keyGroup_" query parameter was not expected.")
      } else {
        continue
      }
    }
    
    // Don't depend on query parameter repeatance, because JavaScript cannot repeat object keys.
    // Instead the parameter should follow the pattern "paramN" which represents a sequence.    
    set value = requestArguments(key, 1)  
    
    // Checks if we have a sequenced query param.
    if key?.A1.2N && (key '= methodArgument.Name) {
      if methodArgument.Arity '= 1 {
        if strictMode {
          return $$$ERROR($$$GeneralError, $$$FormatText("'%1' was NOT expected to be sequential.", keyGroup))
        } else {
          continue
        }
      }               
      if methodArgumentsLength > 1 {     
        set argumentIndex = methodArgumentsLength + nextKeyIndex
      } else {
        set argumentIndex = nextKeyIndex + 1
      }
      
      set nextKeyIndex = nextKeyIndex + 1
      
      if nextKeyIndex '= $$$KeyIndex(key) {
        return $$$ERROR($$$GeneralError, $$$FormatText("'%1' was expected to be sequential.", keyGroup))
      }
    } else {
      set argumentIndex = methodArgument.Index
    }
    set preArguments(argumentIndex) = value  
  }
  
  set missingArguments = ""
  set weaklyTypedArgs = ""
  
  if methodArgumentsLength > 0 {    
    for m=1:1:methodArgumentsLength {
      set methodArgument = ..MethodArguments.GetAt(m)      
      set isPayloadArgument = (methodArgument.Type [ "DynamicObject" || (methodArgument.Type [ "DynamicArray"))
      if methodArgument.Type = "" set $list(weaklyTypedArgs, *+1) = methodArgument.Name
            
      if 'methodArgument.HasDefaultValue && 'isPayloadArgument {
        set queryParameterName = $select(
          methodArgument.Alias '= "" : methodArgument.Alias, 
          1: methodArgument.Name
        )
        
        if methodArgument.Arity {
          set queryParameterName = $$$KeyGroup(queryParameterName)
        }        
        
        if '$lf(keysFound, queryParameterName) && '$data(routeArguments(queryParameterName)) {
          set $list(missingArguments, *+1) = queryParameterName
        }        
      }
    }
  }
  
  if $ll(weaklyTypedArgs) > 0 {
    return $$$ERROR($$$GeneralError, "The following arguments must be strongly typed: "_$lts(weaklyTypedArgs, ", ")_".")
  }  
  
  if $ll(missingArguments) > 0 {
    return $$$ERROR($$$GeneralError, "The following query parameters are missing: "_$lts(missingArguments, ", ")_".")
  } 
    
  // Now we must merge the route arguments back, remember that they always take priority over query parameters.
  set routeKey = ""
  for {
    set routeKey = $order(routeArguments(routeKey), 1, routeValue)
    quit:routeKey=""
    
    set methodArgument =  ..FindDescribedArgument(routeKey)
    
    if '$isobject(methodArgument) {
      return $$$ERROR($$$GeneralError, $$$FormatText("Route parameter '%1' was not specified as an argument in the method '%2'.", routeKey, ..MethodDescriptor.Name))
    }    
    set preArguments(..FindDescribedArgument(routeKey).Index) = routeValue
  }
  set preArguments = argumentIndex
  return $$$OK
}

Method Invoke(Output methodReturn = "", Output stack As %Stream.Object = "") As %Status [ Internal ]
{
  set sc = $$$OK
  merge methodArguments = ..Arguments
  
  new $estack
  
  try {
    if methodArguments > 0 {
      set methodReturn = $classmethod(..DispatchClass, ..DispatchMethod, methodArguments...)      
    } else {            
      set methodReturn = $classmethod(..DispatchClass, ..DispatchMethod)
    }
  } catch ex {
    do ##class(Frontier.Exception).CaptureStack(.stack)
    set sc = ex.AsStatus()
  }
  return sc
}

}

