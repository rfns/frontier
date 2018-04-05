Include (%occErrors, %occStatus, frontier)

Class Frontier.Router Extends %CSP.REST
{

Parameter CHARSET = "utf-8";

Parameter CONTENTTYPE = "application/json";

Parameter CONVERTINPUTSTREAM = 1;

ClassMethod Page(skipheader As %Boolean = 1) As %Status [ ProcedureBlock = 0 ]
{
 
  new %frontier
  set %frontier = ##class(Frontier.Context).%New(%session, %request, %response)
  set %session.Data("%frontier") = %frontier
  $$$QuitOnError(##super(skipheader))
  return $$$OK
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

ClassMethod DispatchRequest(url As %String, httpMethod As %String, forwarded As %Boolean = "", routeParameters As %String = 0, ByRef matches As %String = "", parentIsStrict As %Boolean = "") As %Status
{
   
  set httpStatus = $case(httpMethod, "POST": ..#HTTP201CREATED, : ..#HTTP200OK)
  set isResourceMatch = 0
  set isHttpMethodMatch = 0
  
  set %frontier.Method = "DispatchRequest"
  
  // Makes sure the http method is following specs.
  set httpMethod = $$$ucase(httpMethod)  
  
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
        set strictRouteParameters = $case(matchType, "R": $lg(mapEntry, 9), : $lg(mapEntry, 5))        
        
        // Now check if http method is corresponding with the expected one.
        // Bails out if not to save resources.
        if httpMethod '= $list(mapEntry, 3) && (matchType = "R") continue
                
        set %frontier.RequestURL = %request.URL
        set %frontier.ClassName = $classname()        
        
        set %frontier.Method = "OnDataSet"
        $$$ThrowOnError(..OnDataSet(%frontier.Data))        
                 
        set %frontier.Method = "OnSetup"
        $$$ThrowOnError(..OnSetup())           
        
        if parentIsStrict '= "" && (parentIsStrict '= strictRouteParameters) {
          $$$ThrowOnError($$$ERROR($$$GeneralError, "Cannot use route with mixed Strict definition."))
        }           
        
        if matcher.GroupCount {
          do FetchRouteParameters(.routeParameters)
        }        
        
        // This is our final router. Search for the dispatch method and prepare it to be called.
        if matchType = "R" {
          set shouldQuit = 0
          set requiresCors = $list(mapEntry, 5)
          set useAuth = $lg(mapEntry, 8)                                           
          
          if httpMethod = "OPTIONS" do HandleOptionsRequest(url, requiresCors, .shouldQuit)
          // Don't continue if we hit this point, let the agent do the rest.
          if shouldQuit return $$$OK                  
          
          $$$ThrowOnError(..ProcessCorsRequest(url, requiresCors))
                   
          if useAuth {
            // Run pending authentication strategies. If one passes, then the implementation
            // is responsible for filling the user object.
            $$$ThrowOnError(%frontier.AuthenticationManager.Verify(.user, resourceScope))
            
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
          
          set dispatchMethod = $listget(mapEntry, 4)
          set dispatchClass = $classname()
          
          // If the Call has : then it's calling a method outside this router.
          if dispatchMethod [ ":" {
            set dispatchClass = $piece(dispatchMethod, ":", 1) 
            set dispatchMethod = $piece(dispatchMethod, ":", 2)         
          }
          
          // Parse dispatchMethod retrieving its metadata.
          set publicMethod = ##class(Method).%New(dispatchClass, dispatchMethod, .routeParameters, %request, %frontier.PropertyFormatter, %frontier.StrictQueryParameters, .matches)                   
          merge methodArguments = publicMethod.Arguments
          
          if matches = "" merge %frontier.RouteParameters = routeParameters
          else  merge %frontier.RouteParameters = matches
          
          set %frontier.Method = dispatchMethod
          merge %frontier.ArgumentValues = publicMethod.Arguments
          
          // Executes the method and retrives its value. The method MUST return a value or a 
          // <COMMAND> will be issued.
          set sc = publicMethod.Invoke(.methodReturn, .stack)
          set %frontier.Stack = stack
          
          $$$ThrowOnError(sc)
          
          // Now we serialize and output the result back to the agent.
          $$$ThrowOnError(..DispatchResponse(methodReturn, .tReturnParameters))
          
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
          set parentIsStrict = strictRouteParameters                    
                    
          // Re-invoke this method using the class that this map forwards the request to. 
          $$$ThrowOnError($classmethod(forwardingClass, "DispatchRequest", resolvedUrl, httpMethod, 1, .routeParameters, .matches, strictRouteParameters))
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
    if %frontier.Debug = 1 {
      do ##class(Frontier.Dynamic.Serializer).Serialize(exceptionPayload, 1, %frontier.PropertyFormatter)
    } else {
      do ##class(Frontier.Dynamic.Serializer).SerializeToStream(.stream, exceptionPayload, 1, %frontier.PropertyFormatter)
      do stream.OutputToDevice()
    }    
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
 
HandleOptionsRequest(url, requireCors, shouldQuit)
 if httpMethod = "OPTIONS" {
   set isHttpMethodMatch = 1 
   $$$ThrowOnError(..OnHandleOptionsRequest(resolvedUrl))        
                      
   // As we got options, we imply that it's a CORS request.
   $$$ThrowOnError(..ProcessCorsRequest(url, requireCors))
   set shouldQuit = 1
 }
 quit
}

ClassMethod HandleException(exception As %Exception.AbstractException) As %DynamicObject [ Private ]
{
  set responseCode = $piece(%response.Status, " ")
    
  // There might have cases where we get a success HTTP status, we need to normalize forcing it to be a 500 error.
  if responseCode < 300 {
    set %response.Status = ..#HTTP500INTERNALSERVERERROR
    set responseCode = 500
  }
    
  set exceptionJSON = ##class(Exception).ToDynamicObject(exception)
  set exceptionJSON.responseCode = responseCode
  set sc = exception.AsStatus()
  set stack = %frontier.Stack  
    
  if '%frontier.ThrownByApplication && ($$$GETERRORCODE(sc) '= $$$GeneralError) {
    set %frontier.Error = sc
  }  
  
  if stack '= "" && (%frontier.IncludeStack = 1) {    
    set exceptionJSON.stack = %frontier.Stack
  }
    
  set %response.OutputSessionToken = 0
  return exceptionJSON
}

ClassMethod DispatchResponse(returnedData As %CacheString, method As Frontier.Router, warnings As %DynamicObject = "", ByRef returnTypeParams = "") As %Status [ Private ]
{
  
  set sc = $$$OK
  set response = {}  
  
  if $isobject(returnedData) {
    set type = $classname(returnedData)
    set isCollection = ##class(Types).IsCollection(type)
    set isSQLProvider = ##class(Types).IsSQLProvider(type)
    set isStream = ##class(Types).IsStream(type)
    set isDynamic = ##class(Types).IsDynamic(type)
    set isSystemType = ($extract(type) = "%")
    set isMarshallable = isCollection || isDynamic || isStream || isSQLProvider || ('isSystemType && ##class(Types).IsInstantiable(type))
    if isMarshallable {
      if isStream {
        set stream = returnedData set returnedData = response
        set response.content = stream
      } elseif isSQLProvider {
        set provider = returnedData
        set response.results = provider
      } else {      
        $$$QuitOnError(##class(Frontier.Dynamic.Marshaller).Marshall(returnedData, .response))
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
  if %frontier.DirectWrite = 1 || (%frontier.Debug = 1) {
    return ##class(Frontier.Dynamic.Serializer).Serialize(response, 1, %frontier.PropertyFormatter)
  } else {
    $$$QuitOnError(##class(Frontier.Dynamic.Serializer).SerializeToStream(.stream, response, 1, %frontier.PropertyFormatter))
    do stream.OutputToDevice()
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

