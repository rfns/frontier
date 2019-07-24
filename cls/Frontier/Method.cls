Include frontier

Class Frontier.Method Extends %RegisteredObject
{

Property DispatchClass As %String;

Property DispatchMethod As %String;

Property MethodArguments As list Of ArgumentDescription;

Property MethodDescriptor As %Dictionary.CompiledMethod [ Private ];

Property ReturnTypeParameters As %String [ MultiDimensional ];

Property Payload As %CacheString;

Property HttpMethod As %String [ InitialExpression = "GET" ];

Property RouteParameters As %String [ MultiDimensional, ReadOnly ];

Property Arguments As %CacheString [ InitialExpression = 0, MultiDimensional, ReadOnly ];

Property Context As Frontier.Context [ Private ];

Method %OnNew(context As Frontier.Context, RESTMethodArguments As %String = 0, ByRef matches As %String = 0) As %Status [ Private ]
{
  set requestQueryParams = 0
  set strictQueryParameters = context.StrictQueryParameters
  set propertyFormatter = context.PropertyFormatter
  set request = context.Request

  $$$ThrowOnError(..AssertMethodExists(context.ClassName, context.Method))

  set ..DispatchClass = context.ClassName
  set ..DispatchMethod = context.Method
  set ..Context = context
  set ..HttpMethod = context.Request.Method
  set ..MethodDescriptor = ##class(%Dictionary.CompiledMethod).%OpenId(context.ClassName_"||"_context.Method)

  $$$ThrowOnError(..ParseArguments())
  $$$ThrowOnError(..ParseReturnTypeParameters())

  if ..MethodDescriptor.ReturnType = "" {
    $$$ThrowOnError($$$ERROR($$$GeneralError, $$$FormatText("Expected a return type for method %1.", ..DispatchMethod)))
  }

  if $isobject(request) {
    set ..Payload = request.Content
    set ..HttpMethod = request.Method
    merge requestQueryParams = request.Data
  }

  merge i%RouteParameters = RESTMethodArguments

  if matches = "" {
    $$$ThrowOnError(..MergeArguments(.RESTMethodArguments, .requestQueryParams, .mergedArguments, strictQueryParameters))
    $$$ThrowOnError(..Sequentialize(.mergedArguments, propertyFormatter))
  } else {
    set i%Arguments = matches
    merge i%Arguments = matches
  }
  quit $$$OK
}

Method ParseArguments() As %Status [ Private ]
{
  set sc = $$$OK
  set describedArguments = ##class(%ListOfObjects).%New()
  set formalSpec = ..MethodDescriptor.FormalSpecParsed
  set unparsedFormalSpec = ..MethodDescriptor.FormalSpec
    
  for i=1:1:$ll(formalSpec) {
    set argSpec = $lg(formalSpec, i)
    set unparsedArg = $piece(unparsedFormalSpec, ",", i)
    set argument = ##class(Frontier.ArgumentDescription).%New()    
    set argName = $lg(argSpec, 1)
    set defaultValue = $lg(argSpec, 4)       
    
    set argument.Index = i
    
    if argName [ "..." {
      set argName = $replace(argName, "...", "")
      set argument.Arity = 1
    }
    
    if defaultValue '= "" {
      set argument.HasDefaultValue = 1
      set argument.DefaultValue = $$$trimQuote(defaultValue)
    }
    
    set argument.Name = argName
    
    // This deals with unspecified argument type, we cannot use FormalSpecParsed because
    // when undefined it defaults to %Library.String, and that is not ideal for type checking.
    set typeDef = $piece(unparsedArg, ":", 2)
    // -2 = Go back to the position BEFORE the char is found.
    set typeBoundary = $find(typeDef, "(") - 2
    if typeBoundary < 1 set typeBoundary = $find(typeDef, "=") - 2
    if typeBoundary < 1 set typeBoundary = $length(typeDef)                
    
    set argument.Type = $extract(typeDef, 1, typeBoundary)
    
    for ii=6:2:$ll(argSpec) {
      set paramName = $lg(argSpec, ii - 1)
      set paramValue = $$$trimQuote($lg(argSpec, ii))
      do argument.Parameters.SetAt(paramValue, paramName)
      if paramName = "ALIAS" set argument.Alias = paramValue
    }
    do ..MethodArguments.Insert(argument)
  }
  
  return $$$OK
}

Method FindArgumentByAliasOrName(identifier As %String) As Frontier.ArgumentDescription [ Internal, Private ]
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
  #define GetPayloadType(%classname) $case(%classname, "%Library.DynamicArray" : "array", : "object")

  set sc = $$$OK

  set argsProcessed = 0
  set payloadFound = 0

  set methodArgumentsLength = ..MethodArguments.Count()

  set jsonErrorMessage = "Wrong argument value: Using '%1' as argument type requires that a JSON payload is sent to be parsed."
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
      set resolvedId = ""

      if value = "" {
        if 'methodArgument.Arity set value = methodArgument.DefaultValue
        else  set value = $get(mergedArguments(methodArgument.Index))
      }

      set shouldUnmarshall = (methodArgument.Parameters.GetAt("UNMARSHAL") = 1)
      set whereId = methodArgument.Parameters.GetAt("WHEREID")
      set isDynamic = ##class(Frontier.Types).IsDynamic(methodArgument.Type)
      set isPersistable = ##class(Frontier.Types).IsPersistent(methodArgument.Type)

      if whereId '= "" {
        set sc = ..ResolveWhereId(whereId, methodArgument.Name,  methodArgument.Type, .resolvedId)
      }

      if shouldUnmarshall || isDynamic {
        set dynamicClass = $select('shouldUnmarshall : methodArgument.Type, 1: "%Library.DynamicObject")
        if ..Payload = "" {
          return $$$ERROR($$$GeneralError, $$$FormatText(jsonErrorMessage, dynamicClass))
        }        

        // If there's already a payloadable argument and another one is found, then we fail the request.
        $$$AssertSinglePayloadParameter
        $$$TriggerPayloadFlag

        // This flag is only set for some specific http methods.
        // This is useful for validating if one of these methods are used.
        if 'payloadFound {
          set errMessage = $$$FormatText("Incorrect http method: Dispatcher method '%1' cannot expect payload because it's configured to accept %2 HTTP method, which is not payloadable.", ..DispatchMethod, ..HttpMethod)
          return $$$ERROR($$$GeneralError, errMessage)
        }

        try {
          set value = $classmethod(dynamicClass, "%FromJSON", ..Payload)
          if 'shouldUnmarshall {
            set type = methodArgument.Type
            $$$NormalizeClassName(type)
            set expected = $$$GetPayloadType(type)
            set received = $$$GetPayloadType($classname(value))
            if expected '= received {
              return $$$ERROR($$$GeneralError, $$$FormatText("Payload type mismatch: expected %1 but received %2", expected, received))
            }
          }         
        } catch ex {
          return $$$ERROR($$$GeneralError, "Error while parsing the payload: the request did not send a valid JSON format.")
        }

        if isPersistable {
          // POST is default. So we check the object first.
          if ..HttpMethod = "PUT" || (..HttpMethod = "PATCH") {
            // PUT or PATCH usually send the id along with the URL, so we try to fetch from it or we fallback to object again.
            if resolvedId set value."__id__" = resolvedId
            if value."__id__" = "" {
              set value."__id__" = $get(..RouteParameters(methodArgument.Name), value."__id__")
              if value."__id__" = "" {
                // Still no ids, then no more hope. This request is doomed.
                return $$$ERROR($$$GeneralError, $$$FormatText("Cannot unmarshall payload to '%1': A PUT/PATCH request requires an identifier. E.g.: /route/1 or { __id__: 1 }.", methodArgument.Type))
              }
            }
          } else {
            // POST should always create. So remove __id__ from the payload.
            do value.%Remove("__id__")
          }
          set sc = ##class(Frontier.Dynamic.Unmarshaller).Unmarshal(methodArgument.Type, value, .instance, propertyFormatter)
          if $$$ISERR(sc) return sc
          set value = instance
        }
      } elseif isPersistable {
        // Type extends from %Persistent, but the match is expecting a GET.
        set value = $System.OBJ.OpenId(methodArgument.Type, $select(resolvedId '= "" : resolvedId, 1: value))
      } elseif methodArgument.Type = "%Boolean" {
        // true/false -> 1/0.
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
  
  if $data(requestArguments("Error:ErrorCode", 1)) {
    return $$$EMBEDSC($$$ERROR($$$GeneralError, "A fatal error happened while trying to dispatch the result. Check this web application's configuration."), requestArguments("Error:ErrorCode", 1))
  } 

  for {
    set key = $order(requestArguments(key))
    quit:key=""
    
    set keyGroup = $$$KeyGroup(key)
    set $list(keysFound, *+1) = keyGroup
    set methodArgument = ..FindArgumentByAliasOrName(key)

    if '$isobject(methodArgument) {
      set methodArgument = ..FindArgumentByAliasOrName(keyGroup)
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
  set weakTypedArgs = ""

  if methodArgumentsLength > 0 {
    for m=1:1:methodArgumentsLength {
      set methodArgument = ..MethodArguments.GetAt(m)
      set isDynamic = ##class(Frontier.Types).IsDynamic(methodArgument.Type)
      set isPersistent = ##class(Frontier.Types).IsPersistent(methodArgument.Type)
      set shouldUnmarshal = (methodArgument.Parameters.GetAt("UNMARSHAL") = 1)
      set isPayloadArgument = isDynamic || (isPersistent && shouldUnmarshal)
      if methodArgument.Type = "" set $list(weakTypedArgs, *+1) = methodArgument.Name

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

  if $ll(weakTypedArgs) > 0 {
    return $$$ERROR($$$GeneralError, "The following arguments are missing the type definition: "_$lts(weakTypedArgs, ", ")_".")
  }

  if $ll(missingArguments) > 0 {
    return $$$ERROR($$$GeneralError, "The following query parameters are missing: "_$lts(missingArguments, ", ")_".")
  }

  // Now we must merge the route arguments back, remember that they always take priority over query parameters.
  set routeKey = ""
  for {
    set routeKey = $order(routeArguments(routeKey), 1, routeValue)
    quit:routeKey=""

    set methodArgument =  ..FindArgumentByAliasOrName(routeKey)

    if '$isobject(methodArgument) {
      return $$$ERROR($$$GeneralError, $$$FormatText("Route parameter '%1' was not specified as an argument in the method '%2'.", routeKey, ..MethodDescriptor.Name))
    }
    set preArguments(..FindArgumentByAliasOrName(routeKey).Index) = routeValue
  }
  set preArguments = argumentIndex
  return $$$OK
}

Method ResolveWhereId(expression As %String, argumentName As %String, argumentType As %String, resolvedId As %String = "") As %Status [ Internal, Private ]
{
  #define NextPlaceholder  $e(expression, $f(expression, ":") - 1, $f(expression, " ", $f(expression, ":")) - 2)

  set expression = expression_ " "
  set value = resolvedId
  set matchesWherePlaceholder = 0
  set sqlTemplate = "SELECT TOP 1 ID FROM %1 WHERE %2"

  set sqlParams = ""

  while expression [ ":" {
    set placeholder = $$$NextPlaceholder
    if '(placeholder?1":".AN) {
      return $$$ERROR($$$GeneralError, "Invalid where format. Expected 'field = :placeholder")
    }

    set parameterValue = ..RouteParameters($e(placeholder, 2, $l(placeholder)))
    if parameterValue = "" set parameterValue = $property(..Context.User, placeholder)
    if parameterValue = "" set parameterValue = $property(..Context.Data, placeholder)       

    if parameterValue = "" {
      return $$$ERROR($$$GeneralError, $$$FormatText("No id could be resolved source because '%1' could not be found or is empty.", name))
    }

    set sqlParams($i(i)) = parameterValue
    set sqlParams = i
    set expression = $replace(expression, placeholder, "?", 1)
  }

  set tableName = ##class(%Dictionary.CompiledClass).%OpenId(argumentType).SqlQualifiedNameQ
  set rows = ##class(%SQL.Statement).%ExecDirect(, $$$FormatText(sqlTemplate, tableName, expression), sqlParams...)
  do rows.%Next()

  if rows.%SQLCODE '= 0 {
    set sc = ##class(%Exception.SQL).CreateFromSQLCODE(rows.%SQLCODE, rows.%Message).AsStatus()
  } else {
    set resolvedId = rows.%Get("ID")  
  }
  
  return $$$OK
}

Method Invoke(Output methodReturn = "", Output stack As %Stream.Object = "") As %Status [ Internal ]
{
 
  set sc = $$$OK
  set io = $io
  merge methodArguments = ..Arguments
  set returnType = ..MethodDescriptor.ReturnType
  
  use $$$NULL
  
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
  
  use io 
  return sc
}

}

