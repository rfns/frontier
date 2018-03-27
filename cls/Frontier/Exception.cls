Class Frontier.Exception Extends %Exception.StatusException
{

ClassMethod CreateFromStatus(pSC As %Status, errorIndex As %Integer = 1) As Frontier.Exception
{
  #dim tException As %Exception.AbstractException
  #dim tData As %List
  #dim tInfo
  
  Set tException = $$$NULLOREF
  
  Do $SYSTEM.Status.DecomposeStatus(pSC,.tInfo)
  If $DATA(tInfo(1)) {
    // Build the exception object
    Set tData="" For tI=1:1:9 Set tData=tData_$LB(tInfo(errorIndex,"param",tI))
    Set tException = ..%New(tInfo(errorIndex,"code"),tInfo(errorIndex,"code"),$get(tInfo(errorIndex,"caller")),tData)
    
    // If there's an embedded error, construct that also
    If $DATA(tInfo(errorIndex,"embeddedstatus")) {
      Set tException.InnerException = ..CreateFromStatus(tInfo(errorIndex,"embeddedstatus"))
    }
    If $data(tInfo(errorIndex + 1)) Set tException.NextException=..CreateFromStatus(pSC, errorIndex + 1)
  }
  
  Quit tException
}

ClassMethod ToDynamicObject(exception As Frontier.Exception) As %DynamicObject
{
  set de = ##class(%DynamicObject).%New()
  set graph = ..BuildObjectGraph(exception)
  
  if graph.%IsA("%DynamicObject") {
    set de.error = graph
  } elseif graph.%IsA("%DynamicArray") {
    set de.errors = graph
  }
  return de
}

ClassMethod CreateInfoObject(exception As Frontier.Exception) As %DynamicObject [ Private ]
{
  set de = ##class(%DynamicObject).%New()    
  set de.internalCode = exception.Code
  
  set fullMessage = $System.Status.GetOneStatusText(exception.AsStatus())
  set messageWithoutLF = $piece(fullMessage, $c(13), 1, 1)
  
  set message = $piece(messageWithoutLF, "#:", 1 , 1)
  set de.message = message
  return de
}

ClassMethod BuildObjectGraph(exception As Frontier.Exception) As %DynamicAbstractObject
{
     
  #define SupportsNextException(%ex) ($isobject(%ex) && ##class(%Dictionary.CompiledProperty).%ExistsId($classname(%ex)_"||NextException") && $isobject(%ex.NextException))  
  
  if $$$SupportsNextException(exception) {
    set de = ..CreateInfoObject(exception)
    set ex = exception.NextException
    set de = [ (de) ]
    while ex {
      set sibling = {}
      do TraverseException(.sibling, ex)
      do de.%Push(sibling)
      if $$$SupportsNextException(ex) {
        set ex = ex.NextException           
      } else {
        quit
      }      
    }
    return de
  }
  
  do TraverseException(.de, exception)
  return de

TraverseException(payload, ex)
  set payload = ..CreateInfoObject(ex)
  set supportsInnerException = ##class(%Dictionary.CompiledProperty).%ExistsId($classname()_"||InnerException") 

  if supportsInnerException && $isobject(ex.InnerException) {
    set payload.origin = ..BuildObjectGraph(ex.InnerException)   
  }
  return $$$OK
}

ClassMethod CaptureStack(Output stackText As %Stream.GlobalCharacter = "") As %String
{
  set stackText = ##class(%Stream.GlobalCharacter).%New()
    
  do stackText.WriteLine("Runtime exception ")
  set max = $stack(-1)
  for loop=max:-1:1 {
    set sc  = stackText.WriteLine($char(9)_"     at "_$stack(loop, "PLACE")_$stack(loop, "MCODE"))
    if $$$ISERR(sc) return sc
  }   
  return stackText.Read()
}

}

