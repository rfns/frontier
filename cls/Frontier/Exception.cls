Class Frontier.Exception Extends %Exception.StatusException
{

ClassMethod CreateFromStatus(pSC As %Status, errorIndex As %Integer = 1) As Frontier.Exception
{
  #dim tException As %Exception.AbstractException
  #dim tData As %List
  #dim tInfo
  
  Set tException = $$$NULLOREF
  
  Do $SYSTEM.Status.DecomposeStatus(pSC,.tInfo, "pt-br")
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
  set de.error = ..BuildObjectGraph(exception)
  return de
}

ClassMethod CreateInfoObject(exception As Frontier.Exception) As %DynamicObject [ Private ]
{
  set de = ##class(%DynamicObject).%New()    
  set de.code = exception.Code
  
  set unfilteredErrorMessage = $System.Status.GetOneStatusText(exception.AsStatus(), 1)
  set errorMessage = $select(unfilteredErrorMessage [ $char(13, 10) : $extract(unfilteredErrorMessage, 1, $find(unfilteredErrorMessage, $c(13,10)) - 3), 1: unfilteredErrorMessage)
  if errorMessage?.ANPE1" > ".ANPE set errorMessage = $extract(errorMessage, 1, $find(errorMessage, " > ") - 2)
  set de.message = errorMessage
  return de
}

ClassMethod BuildObjectGraph(exception As Frontier.Exception) As %DynamicObject [ Private ]
{
  set de = ..CreateInfoObject(exception)  
  
  if $isobject(exception.InnerException) {
    set de.from = ..ToDynamicObject(exception.InnerException)
  }
  
  if $isobject(exception) && ##class(%Dictionary.CompiledProperty).%ExistsId($classname(exception)_"||NextException") && $isobject(exception.NextException) {
    set nextExceptions = ##class(%ListOfObjects).%New()
    set de.next = nextExceptions
    
    set ex = exception.NextException
    while ex {
      do de.next.Insert(..CreateInfoObject(ex, 0))
      set ex = ex.NextException
    }
  }
  
  return de
}

ClassMethod CaptureStack(Output stackText As %Stream.GlobalCharacter = "") As %String
{
  set stackText = ##class(%Stream.GlobalCharacter).%New()
    
  do stackText.WriteLine("Runtime exception ")
  set max = $stack(-1)
  for loop=max:-1:1 {
    set sc  = stackText.WriteLine($char(9)_"     at "_$stack(loop, "PLACE")_$stack(loop, "MCODE")_" (LV: "_loop_")")
    if $$$ISERR(sc) return sc
  }   
  return stackText.Read()
}

}

