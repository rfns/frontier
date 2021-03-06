Include (%occErrors, %occStatus, frontier)

Class Frontier.Router Extends %CSP.REST [ DependsOn = Frontier.Schema.Util ]
{

Parameter CHARSET = "utf-8";

Parameter CONTENTTYPE = "application/json";

Parameter CONVERTINPUTSTREAM = 1;

ClassMethod Page(skipheader As %Boolean = 1) As %Status [ ProcedureBlock = 0 ]
{
    
  $$$QuitOnError(..InitializeContext(.%frontier))    
  
  #dim sc As %Status = $$$OK
  #dim e As %Exception.AbstractException
  
  #dim redirected As %Boolean
  #dim originRoutine, url As %String = ""
  #dim %response As %CSP.Response
  #dim %frontier As Frontier.Context
      
  try {        
    set %response.CharSet = %frontier.Encoding 
    do %response.MatchLanguage() 
    
    // Gets the current redirection status. ON or OFF.
    set redirected = ##class(%Library.Device).ReDirectIO()
            
    // Gets the routine before attempting to redirect. Used to restore original direction.
    set originRoutine = $System.Device.GetMnemonicRoutine()
    
    // Set the web server routine to handle the request.
    use $io::("^%SYS.cspServer2")
      
    // Redirect write calls to the routine above.
    do ##class(%Library.Device).ReDirectIO(1)
      
    // Check if the application has a dispatch class.
    if $$$GetSecurityApplicationsDispatchClass(%request.AppData) = "" {
      set %response.Status = ..#HTTP500INTERNALSERVERERROR
      $$$ThrowStatus($$$ERROR($$$GeneralError, "Application has no dispatch class."))
    }
      
    // Attempt to get the URL.
    Set url = $Get(%request.CgiEnvs("CSPLIB"))      
    if url = "" Set url = %request.URL           
            
    // Query parameters are dealt later. So for now it's stripped off.
    set url = $piece(url, "?")
      
    // Delegate the handling to the appropriate router.
    $$$ThrowOnError(..DispatchRequest(url, %request.Method))
      
  } catch (e) {
    write ##class(Frontier.Exception).ToDynamicObject(e).%ToJSON()
    set %response.OutputSessionToken = 0
    set sc = e.AsStatus()
  }
          
  // Must write something to trigger redirection and write the headers.
  write ""
  
  // If we have a redirection.
  If redirected {       
    // Then restore it to the original.
    use $io::("^"_originRoutine)
      
    // And switch the redirection back to what it was originally.
    do ##class(%Library.Device).ReDirectIO(1)
  }
      
  return $$$OK
}

ClassMethod InitializeContext(Output context As Frontier.Context = "") As %Status [ Private ]
{
 
  new %frontier
  set context = ##class(Frontier.Context).%New(%session, %request, %response)
  set %session.Data("%frontier") = context
  return $$$OK
}

ClassMethod Login(skipheader As %Boolean = 1) As %Status [ ProcedureBlock = 0 ]
{
  return ..Page(skipheader)
}

ClassMethod DispatchMap(index As %Integer) As %String [ CodeMode = objectgenerator, Final, Internal ]
{
     
  // Don't try to generate patterns if the target class is Frontier.Router.
  if %compiledclass.Name = "Frontier.Router" return $$$OK   
  
  $$$ThrowOnError(##class(Frontier.Schema.Util).Parse(%compiledclass.Name, .routes))
  $$$ThrowOnError(##class(Frontier.Schema.Util).GeneratePatterns(routes, %compiledclass.Name, .patterns))  
  
  set patternIndex = ""
  
  for {
    set patternIndex = $order(patterns(patternIndex), 1, pattern)
    quit:patternIndex=""
    
    set patternString = ""
    set patternType = $lg(pattern, 1)
    
    for i=1:1:$ll(pattern) {
      set item = $lg(pattern, i)      
      if patternType = "M" {
        if i = 4 set $list(patternString, *+1) = "$lfs("_$$MakeString(item)_")"
        else  set $list(patternString, *+1) = """"_$lg(pattern, i)_""""
      } elseif patternType = "R" {
        if i = 6 set $list(patternString, *+1) = "$lfs("_$$MakeString(item)_")"
        else  set $list(patternString, *+1) = """"_$lg(pattern, i)_""""
      }
    }
    
    do %code.WriteLine("  if index = "_patternIndex_ " return $lb("_$lts(patternString)_")")
  }
  
  // Prevents the dispatch from throwing <OBJECT DISPATCH> if route is not defined.
  // This will make the engine return "Resource not found" instead.
  do %code.WriteLine("  return """"")  
  return $$$OK
  
MakeString(list)
  set stringList = ""
  for li=1:1:$ll(list) {
    set item = $lg(list, li)
    set $piece(stringList, ",", li) = ""_item_""
  }
  return """"_stringList_""""
}

ClassMethod DispatchRequest(url As %String, httpMethod As %String, forwarded As %Boolean = "", routeParameters As %String = 0, ByRef matches As %String = "") As %Status
{
   
  set httpStatus = $case(httpMethod, "POST": ..#HTTP201CREATED, : ..#HTTP200OK)
  set isResourceMatch = 0
  set isHttpMethodMatch = 0
  
  set %frontier.Method = "DispatchRequest"
  
  // Normalize the HTTP method.
  set httpMethod = $$$ucase(httpMethod)
  
  // Prevents attempts to dispatch from this class itself.
  $$$QuitOnError($$ValidateRouteOrigin)
  
  try {       
    set resolvedUrl = $$ResolveUrl(url)      
    
    while $$NextDispatchMap(.index, .mapEntry) {
      set matchType = $list(mapEntry, 1)
      set urlExpression = $list(mapEntry, 2)      
      set matcher = ##class(%Regex.Matcher).%New(urlExpression)              
      
      // If there's no match, skip to the next candidate.
      if matcher.Match(resolvedUrl) {
        set isResourceMatch = 1
        set resourceScope = $lg(mapEntry, 7)        
        set strictRouteParameters = $lg(mapEntry, 9, 1)              
        
        // Method is not an OPTIONS, neither one that should match the schema.
        if httpMethod '= "OPTIONS" && (httpMethod '= $list(mapEntry, 3) && (matchType = "R")) continue
        
        // OnSetup must be run even if the Router forwards to another one.
        set %frontier.Method = "OnSetup"
        $$$ThrowOnError(..OnSetup())
        
        set %frontier.RequestURL = %request.URL
        set %frontier.Route = urlExpression
        set %frontier.ClassName = $classname()                                      
        
        // Does this router have CORS configured?
        if %frontier.CORS.IsActive() {
          if httpMethod = "OPTIONS" {          
            do %frontier.CORS.CheckPreflight()
            return $$$OK
          } else {
            // Clears any configuration set by another router.
            do %frontier.CORS.Unset()
            // Applies the configuration defined by the current router.
            do %frontier.CORS.Set()
          }
        }                        
        
        if matcher.GroupCount && strictRouteParameters {
          do FetchRouteParameters(.routeParameters)
          merge %frontier.RouteParameters = routeParameters
        } elseif 'strictRouteParameters {
          // Cannot merge FROM ReadOnly property. Are you serious?!
          do ManualGroupMerge(matcher)
        }       
        
        // Found the router that should handle the request.
        if matchType = "R" {           
          set useAuth = $lg(mapEntry, 8)
          set authStrategy = $lg(mapEntry, 11)                                         
                   
          if useAuth && %frontier.AuthenticationManager.HasStrategies() {
            // Run pending authentication strategies. If one passes, then the implementation
            // is responsible for filling the user object.
            if authStrategy = "" {
              $$$ThrowOnError(%frontier.AuthenticationManager.Verify(.user, resourceScope))
            } else {
              // Auth is enabled AND the route requests for a specific strategy to be used.              
              $$$ThrowOnError(%frontier.AuthenticationManager.VerifyUsing(authStrategy, .user, resourceScope))
            }            
            
            if '%frontier.AuthenticationManager.Verified {
              set %response.Status = ..#HTTP401UNAUTHORIZED
              $$$ThrowOnError($$$ERROR($$$GeneralError, "You must be authenticated to access this resource."))
            }
            
            set %frontier.User = user                       
          
            // Don't let the user access this resource if this request doesn't match it.           
            if '%frontier.AuthenticationManager.CheckResourceScope(resourceScope, user.scope) {
              if %response.Status = ..#HTTP200OK || (%response.Status = ..#HTTP201CREATED) {
                set %response.Status = ..#HTTP403FORBIDDEN
              }
              $$$ThrowOnError($$$ERROR($$$GeneralError, "This account has not enough privilege to access this resource."))
            }                                            
          }                   
          
          set %frontier.Method = "OnDataSet"
          $$$ThrowOnError(..OnDataSet(%frontier.Data))
          
          set dispatchMethod = $listget(mapEntry, 4)
          set dispatchClass = $classname()
          
          // If the Call has : then it's calling a method outside this router.
          if dispatchMethod [ ":" {
            set dispatchClass = $piece(dispatchMethod, ":", 1)    
            set dispatchMethod = $piece(dispatchMethod, ":", 2)
          }
          
          set %frontier.ClassName = dispatchClass
          set %frontier.Method = dispatchMethod
          
          // Parse dispatchMethod retrieving its metadata.
          set publicMethod = ##class(Method).%New(%frontier, .routeParameters, .matches)
          merge methodArguments = publicMethod.Arguments
          
          if matches = "" merge %frontier.RouteParameters = routeParameters
          else  merge %frontier.RouteParameters = matches
          
          merge %frontier.ArgumentValues = publicMethod.Arguments
          
          // Executes the method and retrives its value. The method MUST return a value or a 
          // <COMMAND> will be issued.
          set sc = publicMethod.Invoke(.methodReturn, .stack)
          set %frontier.Stack = stack          
          
          $$$ThrowOnError(sc)
          
          // Now we serialize and output the result back to the agent.
          $$$ThrowOnError(..DispatchResponse(methodReturn))
          
          // Finishes the request.
          return $$$OK
        } elseif matchType = "M" {
          // We're reading a map, Map patterns already include everything needed to forward the
          // correct URL part, as long as we always consider targeting its the last match.
          set forwardingClass = $listget(mapEntry, 3)
          
          if forwardingClass = $classname() {
            $$$ThrowOnError($$$ERROR($$$GeneralError, $$$FormatText("Dispatcher class %1 is attempting to forward %2 to itself.", forwardingClass, resolvedUrl)))
          }                    
          
          set resolvedUrl = "/"_matcher.Group(matcher.GroupCount)
                    
          // Re-invoke this method using the class that this map forwards the request to. 
          $$$ThrowOnError($classmethod(forwardingClass, "DispatchRequest", resolvedUrl, httpMethod, 1, .routeParameters, .matches))
          // Maps are also a match, so abort everything else and let the forwarding class handle the rest.
          return $$$OK
        }
      }      
    }
    
    // Didn't have a match for the resource, report not found.
    if isResourceMatch '= 1 || (isHttpMethodMatch '= 1) {
      set %response.Status = ..#HTTP404NOTFOUND
      $$$ThrowOnError($$$ERROR($$$GeneralError, "Resource not found."))
    }
    
    return $$$OK       
  } catch ex {       
    set exceptionPayload = ..HandleException(ex)
    do ##class(Frontier.Dynamic.Serializer).Serialize(exceptionPayload,, %frontier.PropertyFormatter, %frontier.Parameters.MAXIMUMDEPTH, %frontier.Parameters.INDENTSIZE)
  }
  return $$$OK
  
ResolveUrl(url)
  if 'forwarded return "/"_$extract(url, $length(%request.Application)+1,*)
  return url
  
NextDispatchMap(index=0, mapEntry="", dispatchClass="")  
  set index = index + 1
  set mapEntry = ..DispatchMap(index)
  return (mapEntry '= "")  
  
FetchRouteParameters(routeParameters=0)  
  if matchType = "R" {
    if httpMethod '= $lg(mapEntry, 3) quit
    set max = $ll($lg(mapEntry,6))
    set storedUrl = $lg(mapEntry, 10) 
  } elseif matchType = "M" { 
    set max = $ll($lg(mapEntry,4))
    set storedUrl = $lg(mapEntry, 6) 
  }
  
  if strictRouteParameters { 
    for p=1:1:max {
      if matchType = "R" {
        set routeParameterName = $lg($lg(mapEntry,6), p)
        if '$data(routeParameters(routeParameterName)) {
          set routeParameters(routeParameterName) = matcher.Group(p)
          set routeParameters = routeParameters + 1
        }
      } elseif matchType = "M" {      
        set routeParameterName = $lg($lg(mapEntry, 4), p)      
        set routeParameters(routeParameterName) = $piece(matcher.Group(p), "/")
        set routeParameters = routeParameters + 1
      }
    }
  } else {
    set storedUrlMatcher = ##class(%Regex.Matcher).%New(storedUrl)
    set storedUrlMatcher.Text = resolvedUrl
    do storedUrlMatcher.Locate()
    for p=1:1:storedUrlMatcher.GroupCount {
      set matchIndex = $order(matches(""), -1) + 1    
      set matches(matchIndex) = storedUrlMatcher.Group(p)
      set matches = matchIndex
    }
  }
  quit
 
ManualGroupMerge(matcher)
  set %frontier.Matches = matcher.GroupCount
  for i=1:1:matcher.GroupCount {
    set %frontier.Matches(i) = matcher.Group(i)
  }
 quit
 
ValidateRouteOrigin()
  if $classname() = "Frontier.Router" {
    return $$$ERROR($$$GeneralError, "Invalid route origin: did you configure Frontier.Router as 'Dispatch Class' instead?")
  }
  return $$$OK
}

ClassMethod HandleException(exception As %Exception.AbstractException) As %DynamicObject [ Private ]
{
 
  set %frontier.Exception = exception
  set maybeException = ..OnExceptionCaught(exception)
  
  if $isobject(maybeException) && maybeException.%IsA("Frontier.Exception") {
     set exception = maybeException
  }
  
  set responseCode = +$piece(%response.Status, " ")
    
  // There might have cases where we get a success HTTP status, we need to normalize forcing it to be a 500 error.
  if responseCode < 300 {
    set %response.Status = ..#HTTP500INTERNALSERVERERROR
    set responseCode = 500
  }
    
  set exceptionJSON = ##class(Exception).ToDynamicObject(exception)
  set exceptionJSON.responseCode = responseCode  
      
  set %response.OutputSessionToken = 0
  
  return exceptionJSON
}

ClassMethod DispatchResponse(returnedData As %CacheString) As %Status [ Private ]
{
  
  set sc = $$$OK
  set response = {}  
  
  if $isobject(returnedData) {
    set type = $classname(returnedData)    
    $$$QuitOnError($$AssertClassNamespaceAvailability(type))    
    
    set isCollection = ##class(Types).IsCollection(type)
    set isSQLProvider = ##class(Types).IsSQLProvider(type)
    set isStream = ##class(Types).IsStream(type)
    set isDynamic = ##class(Types).IsDynamic(type)
    set isSystemType = ($extract(type) = "%")
    set isMarshallable = isCollection || isDynamic || isStream || isSQLProvider || ('isSystemType && ##class(Types).IsInstantiable(type))
    if isMarshallable {
      if isStream {
        if %frontier.IsRaw() return returnedData.OutputToDevice()
        set stream = returnedData set returnedData = response
        set response.content = stream
      } elseif isSQLProvider {
        set provider = returnedData
        set response.results = provider      
      } elseif isDynamic {
        set response = returnedData
      } else {
        $$$QuitOnError(##class(Frontier.Dynamic.Marshaller).MarshalDirect(returnedData, .response, %frontier.Parameters.MAXIMUMDEPTH))
      }
    } else {
      return $$$ERROR($$$GeneralError, "Cannot serialize system class instances.")
    }
  } elseif %frontier.IsJSON() {
    set response.result = returnedData  
  } else {
    write returnedData
    return $$$OK
  }  
  
  // We must use a custom serializer because the current %ToJSON implementation cannot serialize
  // mixed instances.
  if %frontier.Parameters.DIRECTWRITE = 1 {
    return ##class(Frontier.Dynamic.Serializer).Serialize(response,, %frontier.PropertyFormatter, %frontier.Parameters.MAXIMUMDEPTH, %frontier.Parameters.INDENTSIZE)
  } else {
    $$$QuitOnError(##class(Frontier.Dynamic.Serializer).SerializeToStream(.stream, response,, %frontier.PropertyFormatter, %frontier.Parameters.MAXIMUMDEPTH, %frontier.Parameters.INDENTSIZE))
    do stream.OutputToDevice()
  }
  return $$$OK

AssertClassNamespaceAvailability(className)
  if '##class(%Dictionary.CompiledClass).%OpenId(className) {
    return $$$ERROR($$$GeneralError, $$$FormatText("The object is an instance of %1 that is not available in the namespace %2.", className, $namespace))
  }
  return $$$OK
}

ClassMethod OnSetup() As %Status
{
  return $$$OK
}

ClassMethod OnDataSet(data As %DynamicObject) As %Status
{
  return $$$OK
}

ClassMethod OnExceptionCaught(exception As %Exception.AbstractException) As Frontier.Exception
{
  return $$$ERROR($$$MethodNotImplemented, "OnExceptionCaught")
}

/// This is the Schema which defines the form of the dispatch map
XData Schema [ Internal ]
{
<?xml version="1.0"?>
<xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema" >

<xs:element name="Routes">
<xs:complexType>
<xs:choice  minOccurs="0" maxOccurs="unbounded">
<xs:element name="Route">
<xs:complexType>
<xs:attribute name="Url"    type="string" use="required"/>
<xs:attribute name="Method" type="string" use="required"/>
<xs:attribute name="Call" type="call" use="required"/>
<xs:attribute name="Cors" type="xs:boolean" use="optional" default="false"/>
<xs:attribute name="Scope" type="string" use="optional" default="false"/>
<xs:attribute name="UseAuth" type="xs:boolean" use="optional" default="true"/>
<xs:attribute name="AuthStrategy" type="xs:string" use="optional"/>
<xs:attribute name="Strict" type="xs:boolean" use="optional" default="true"/>
</xs:complexType>
</xs:element>
<xs:element name="Map">
<xs:complexType>
<xs:attribute name="Prefix" type="string" use="required"/>
<xs:attribute name="Forward" type="forward" use="required"/>
<xs:attribute name="Strict" type="xs:boolean" use="optional" default="true"/>
</xs:complexType>
</xs:element>
</xs:choice>
</xs:complexType>
</xs:element>

<xs:simpleType name="call">
<xs:restriction base="xs:string">
<xs:pattern value="([%]?[a-zA-Z][a-zA-Z0-9]*(\.[a-zA-Z][a-zA-Z0-9]*)*:)?[%]?[a-zA-Z][a-zA-Z0-9]*"/>
</xs:restriction>
</xs:simpleType>

<xs:simpleType name="forward">
<xs:restriction base="xs:string">
<xs:pattern value="([%]?[a-zA-Z][a-zA-Z0-9]*(\.[a-zA-Z][a-zA-Z0-9]*)*)"/>
</xs:restriction>
</xs:simpleType>

<xs:simpleType name="string">
<xs:restriction base="xs:string">
<xs:minLength value="1"/>
</xs:restriction>
</xs:simpleType>

</xs:schema>
}

}

