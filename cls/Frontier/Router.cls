Include (%occErrors, %occStatus)

Class Frontier.Router Extends %CSP.REST
{

ClassMethod Page(skipheader As %Boolean = 1) As %Status [ ProcedureBlock = 0 ]
{
  set %frontier = ##class(Frontier.Context).%New(%session, %request, %response)  
  $$$QuitOnError(##super(skipheader))
  do ..OnPostHTTP()
  return $$$OK
}

ClassMethod DispatchMap(index As %Integer) As %String [ CodeMode = objectgenerator, Final, Internal ]
{
  // Don't generate patterns if target class is super.
  if %compiledclass.Name = "Frontier.Router" return $$$OK
  
  // Kills remaining data, so that we can prevent using obsolete patterns.
  kill ^Frontier.Patterns(%compiledclass.Name)
  
  $$$ThrowOnError(##class(Frontier.Schema.Util).Parse(%compiledclass.Name, .routes))
  $$$ThrowOnError(##class(Frontier.Schema.Util).GeneratePatterns(routes, %compiledclass.Name, .patterns))  
  merge ^Frontier.Patterns(%compiledclass.Name) = patterns
  do %code.WriteLine("  return $get(^Frontier.Patterns($classname(), index))")
  return $$$OK
}

ClassMethod DispatchRequest(pUrl As %String, pMethod As %String, pForwarded As %Boolean = 0) As %Status
{
  
  #; This is a modified version of %CSP.REST's DispatchRequest that creates an entry point for
  #; for additional features.
  #; TODO: Check the possibility of purging this source code to stop overwriting the original method.
  
  #dim e As %Exception.AbstractException
  
  #dim tMatcher As %Regex.Matcher
  
  #dim tArgs,tClass,tMatchUrl,tMapEntry,tRegEx,tCall,tForward,tAccess,tTarget,tType,tHttpStatus As %String
  #dim tI,tIndex As %Integer
  #dim tResourceMatched,tContinue As %Boolean
  #dim tMethodMatched As %Boolean
  
  set tHttpStatus = $case(pMethod, "POST": ..#HTTP201CREATED, : ..#HTTP200OK)    
    
   try {
    set (tResourceMatched,tMethodMatched) = 0
                
    #; Extract the match url from the application name    
    if 'pForwarded {
      set tMatchUrl = "/"_$extract(pUrl, $length(%request.Application)+1,*)     
    } else {
      set tMatchUrl = pUrl
    }    
      
    #; Uppercase the method
    set pMethod=$ZCVT(pMethod,"U")    
          
    #; Pre-Dispatch
    set tContinue = 1
    $$$ThrowOnError(..OnPreDispatch(tMatchUrl, pMethod, 1))        
            
    #; Walk the dispatch map in collation order of defintion
    for tIndex=1:1 {           
      
      #; Get the next map entry
      set tMapEntry = ..DispatchMap(tIndex) if tMapEntry="" quit      
             
      #; Pick out the RegEx
      set tRegEx = $list(tMapEntry,2)
      
      #; Create a matcher
      set tMatcher = ##class(%Regex.Matcher).%New(tRegEx)
            
      #; Test each regular expression in turn, extracting the arguments,
      #; dispatching to the named method
      if tMatcher.Match(tMatchUrl) {
        
        #; We have matched the resource
        set tResourceMatched = 1
        
        set %frontier.RequestURL = %request.URL
        set %frontier.ClassName = $classname()
                  
        $$$ThrowOnError(..OnSetup())
        $$$ThrowOnError(..OnDataSet(%frontier.Data))        
        
        set tScope = $lg(tMapEntry, 7)
        
        #; Run pending authentication strategies. If one passes, then the implementation
        #; is responsible for filling the user object.
        $$$ThrowOnError(%frontier.AuthenticationManager.Verify(.user, tScope))
        set %frontier.User = user               
        
        #; This checks the user.scope against the resource scope and validates the
        #; resource access.
        if '%frontier.AuthenticationManager.CheckResourceScope(tScope, user.scope) {
          set %response.Status = ..#HTTP403FORBIDDEN
          $$$ThrowOnError($$$ERROR($$$GeneralError, "This account has not enough privilege to execute this action."))
        }                
                
        set tType = $list(tMapEntry,1)
                
        #; If we are a simple route
        if tType = "R" {
                   
          #; Support OPTIONS VERB (cannot be overriden)
          if pMethod="OPTIONS" {                       
            set tMethodMatched = 1                      
            $$$ThrowOnError(..OnHandleOptionsRequest(tMatchUrl))                        
                        
            #; Dispatch CORS
            $$$ThrowOnError(..ProcessCorsRequest(pUrl,$list(tMapEntry,5)))                       
            return $$$OK
          }        
                    
          #; comparison is case-insensitive now
          If pMethod '= $ZCVT($list(tMapEntry,3),"U") continue                   
          set tTarget = $list(tMapEntry,4)
                      
          #; We have matched a method
          set tMethodMatched = 1
                      
          #; Dispatch CORS
          $$$ThrowOnError(..ProcessCorsRequest(pUrl,$list(tMapEntry,5)))
                   
          #; Got a match, marshall the arguments can call directly
          if tMatcher.GroupCount {
            #; Modified for Frontier compatibility: store key instead of index. We need this info to correlate the arguments later.            
            for tI=1:1:tMatcher.GroupCount set tArgs($lg($lg(tMapEntry,6), tI))=tMatcher.Group(tI)
            set tArgs = tI
          } else {
            set tArgs=0
          }          
                    
          #; Check for optional ClassName prefix
          set tClass = $classname()
          If tTarget [ ":" set tClass = $piece(tTarget,":"), tTarget = $Piece(tTarget,":",2)              

          #; Dispatch
          #; Modified to add support for type resolution and query parameters
          set tPublicMethod = ##class(Method).%New(tClass, tTarget, .tArgs, %request, %frontier.PropertyFormatter)
          merge tMethodArguments = tPublicMethod.Arguments
          
          set %frontier.Method = tTarget
          if tMethodArguments > 0 {
            merge %frontier.ArgumentValues = tMethodArguments
            set return = $classmethod(tClass, tTarget, tMethodArguments...)
          } else {            
            set return = $classmethod(tClass, tTarget)
          }
          $$$ThrowOnError(..DispatchResponse(return, .tReturnParameters))
          return $$$OK
        } else {                  
          #; We are a map, message the URL and forward the request
          set tMatchUrl = $piece(tMatchUrl,tMatcher.Group(1),"2",*)
          if tMatchUrl = "" set tMatchUrl = "/"
          set tForward = $listget(tMapEntry,3)
          set (tResourceMatched, tMethodMatched) = 1
          #; Dispatch with modified URL          
          $$$ThrowOnError($classmethod(tForward,"DispatchRequest",tMatchUrl,pMethod,1))
        }                        
        return $$$OK
      }              
    }
        
    #; Didn't have a match for the resource, report not found
    if tResourceMatched '= 1 && (tMethodMatched '= 1) {
      set %response.Status = ..#HTTP404NOTFOUND
      $$$ThrowOnError($$$ERROR($$$GeneralError, "Resource not found."))
    }
  } catch (e) {
    set responseCode = $piece(%response.Status, " ")
    
    #; There might have cases where we get a success HTTP status, we need to normalize
    #; it forcing a common 500 error.
    if responseCode < 300 {
      set %response.Status = ..#HTTP500INTERNALSERVERERROR
      set responseCode = 500
    }
    
    set exceptionJSON = ##class(Exception).ToDynamicObject(e)
    set exceptionJSON.error."response_code" = responseCode    
    set sc = e.AsStatus()    
    
    if %frontier.ThrownByApplication || ($$$GETERRORCODE(sc) '= $$$GeneralError) {
      set %frontier.Error = sc
      set %frontier.Stack = ##class(Exception).CaptureStack()
    }
    
    set %response.OutputSessionToken = 0
    write exceptionJSON.%ToJSON()    
  }   
  return $$$OK
}

ClassMethod DispatchResponse(returnedData As %CacheString, method As Frontier.Router, ByRef returnTypeParams = "") As %Status
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
  if %frontier.DirectWrite = 1 {
    return ##class(Frontier.Dynamic.Serializer).Serialize(response, 1, %frontier.PropertyFormatter)
  } else {
    $$$QuitOnError(##class(Frontier.Dynamic.Serializer).SerializeToStream(response, .stream, %frontier.PropertyFormatter))
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

ClassMethod OnPostHTTP() [ Final ]
{
  do %frontier.ReporterManager.Report() 
  kill %frontier
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
</xs:complexType>
</xs:element>
<xs:element name="Map">
<xs:complexType>
<xs:attribute name="Prefix" type="string" use="required"/>
<xs:attribute name="Forward" type="forward" use="required"/>
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

