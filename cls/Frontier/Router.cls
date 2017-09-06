Class Frontier.Router Extends %CSP.REST
{

ClassMethod DispatchRequest(pUrl As %String, pMethod As %String, pForwarded As %Boolean = 0) As %Status
{
 
  #; This is a modified version of %CSP.REST's DispatchRequest that creates an entry point for
  #; for additional features.
  #; TODO: Check the possibility of purging this source code to stop ovewriting the original method.
  
  #dim tSC As %Status = $$$OK
  #dim e As %Exception.AbstractException
  
  #dim tMatcher As %Regex.Matcher
  
  #dim tArgs,tClass,tMatchUrl,tMapEntry,tRegEx,tCall,tForward,tAccess,tSupportedVerbs,tTarget,tType As %String
  #dim tI,tIndex As %Integer
  #dim tResourceMatched,tContinue As %Boolean
  #dim tMethodMatched As %Boolean
  
  new %frontier
  set %frontier = ..InitContext(%session, %request, %response)  
    
   try {       
    set (tResourceMatched,tMethodMatched) = 0    
                
    #; Extract the match url from the application name
    if (0=pForwarded) set tMatchUrl="/"_$extract(pUrl, $length(%request.Application)+1,*)
    else  set tMatchUrl=pUrl        
      
    #; Uppercase the method
    set pMethod=$ZCVT(pMethod,"U")
    set tHttpStatus = $case(pMethod, "POST": ..#HTTP201CREATED, : ..#HTTP200OK)
          
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
            #; Modified for Frontier compatibility: store key instead of index. We need this info to correlate the arguments.            
            for tI=1:1:tMatcher.GroupCount set tArgs(tI)=tMatcher.Group(tI)
            set tArgs = tI
          } else {
            set tArgs=0
          }          
                    
          #; Check for optional ClassName prefix
          set tClass = $classname()
          If tTarget [ ":" set tClass = $piece(tTarget,":"), tTarget = $Piece(tTarget,":",2)
                              
          #; Dispatch
          #; Modified to add support for type resolution and query parameters
          set tPublicMethod = ##class(Method).%New(tClass, tTarget, .tArgs, %request)
          merge tMethodArguments = tPublicMethod.Arguments                
                   
          if tMethodArguments > 0 {
            set return = $classmethod(tClass, tTarget, tMethodArguments...)
          } else {            
            set return = $classmethod(tClass, tTarget)
          }
          $$$ThrowOnError(..DispatchResponse(return, .tReturnParameters))
          return $$$OK
        } else {                    
          #; We are a map, massage the URL and forward the request
          set tMatchUrl = $piece(tMatchUrl,tMatcher.Group(1),"2",*), tForward = $listget(tMapEntry,3)
          set (tResourceMatched, tMethodMatched) = 1
                   
          #; Dispatch with modified URL 
          $$$ThrowOnError($classmethod(tForward,"DispatchRequest",tMatchUrl,pMethod,1))
        }                        
        return $$$OK
      }              
    }
        
    #; Didn't have a match for the resource, report not found
    if tResourceMatched = 0 {
      set tHttpStatus = ..#HTTP404NOTFOUND
      $$$ThrowOnError($$$ERROR($$$GeneralError, ..#HTTP404NOTFOUND))
    }
                  
    #; Had a match for resource but method not matched
    if tMethodMatched = 0 {      
      set tSC = ..SupportedVerbs(tMatchUrl,.tSupportedVerbs)            
      return ..Http405(tSupportedVerbs) Quit
    }
  } catch (e) {
    do ..CaptureStack(.stack)
    if tHttpStatus < 300 set tHttpStatus = ..#HTTP500INTERNALSERVERERROR
    
    do ..ReportHttpStatusCode(tHttpStatus, e.AsStatus(), .json)
    set json.stack = stack.Read()
    
    do json.%ToJSON(, "aelo")
  }   
  return $$$OK
}

ClassMethod DispatchResponse(returnedData As %CacheString, method As Frontier.Router, ByRef returnTypeParams = "") As %Status
{
 
  set response = {}
  
  // Enables device writing.
  write ""
  
  if $isobject(returnedData) {   
    set type = $classname(returnedData)
    set isCollection = ##class(Types).IsCollection(type)
    set isDynamic = ##class(Types).IsDynamic(type)
    set isSystemType = ($extract(type) = "%")
    set isMarshallable = isCollection || isDynamic || ('isSystemType && ##class(Types).IsInstantiable(type))
    if isMarshallable {
      $$$QuitOnError(##class(Frontier.Dynamic.Marshaller).Marshall(returnedData, .response))
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
  do ##class(Frontier.Dynamic.Serializer).Serialize(response)
  return $$$OK
}

/// This method takes a status, renders it as json (if requested) and outputs the result
ClassMethod outputStatus(pSC As %Status, Output tJSON As %ZEN.proxyObject = "") As %Status [ Internal ]
{
  #dim tSC As %Status = $$$OK
  #dim e As %Exception.AbstractException   
   
  try {      
    if ..AcceptsContentType("application/json") {
      Set %response.ContentType = ..#CONTENTTYPEJSON        
      #; Convert the exception to a status and render to JSON
      
      set tSC = ..StatusToProxyObject(pSC, .tJSON)
      if $$$ISERR(tSC) return tSC
      #; Write the JSON to the output device
      if $$$ISERR(tSC) return tSC            
    } else {            
      #; Set plain text
      set %response.ContentType = ..#CONTENTTYPETEXT
      
      #; Write out a simple text message
      do ##class(%Exception.StatusException).CreateFromStatus(pSC).OutputToDevice()
    }        
  } catch (e) {        
    #; Oops
    set tSC = e.AsStatus()
  }
  return $$$OK
}

/// Issue an 'Http' error
ClassMethod ReportHttpStatusCode(pHttpStatus, pSC As %Status = {$$$OK}, Output pData As %ZEN.proxyObject = "") As %Status
{
    Set %response.Status=pHttpStatus
    
    If $$$ISERR(pSC) Do ..outputStatus(pSC, .pData)
        
    Quit $$$OK
}

ClassMethod InitContext(session As %CSP.Session, request As %CSP.Request, response As %CSP.Response) As Frontier.Context [ Private ]
{
  return ##class(Frontier.Context).%New(session, request, response)
}

ClassMethod CaptureStack(Output stackText As %Stream.GlobalCharacter = "") As %Status
{
  set stackText = ##class(%Stream.GlobalCharacter).%New()
    
  do stackText.WriteLine("Runtime exception ")
  set max = $stack(-1)
  for loop=max:-1:1 {
    set sc  = stackText.WriteLine($char(9)_"     at "_$stack(loop, "PLACE")_$stack(loop, "MCODE")_" (Level: "_loop_")")
    if $$$ISERR(sc) return sc
  }   
  return $$$OK
}

}

