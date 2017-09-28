Class Frontier.AbstractSerializer [ Abstract ]
{

/*ClassMethod SerializeToStream(
  dynamic As %DynamicAbstractObject,
  Output stream As %Stream.Object = "") [ ProcedureBlock = 0 ]
{
  new oldMnemonic, alreadyRedirected, sc
  
  set sc = $$$OK
  set isRedirected = 0
  
  if '$isobject(stream) set stream = ##class(%Stream.TmpBinary).%New()
  set alreadyRedirected = ##class(%Device).ReDirectIO()
  set initIO = $io
  
  try {
    set oldMnemonic = "^"_##class(%Device).GetMnemonicRoutine()
    use $io::("^"_$zname)
    do ##class(%Device).ReDirectIO(1)
    set isRedirected = 1
    $$$ThrowOnError(..Serialize(dynamic))    
  } catch ex {
    set sc = ex.AsStatus()
  }
  
  if alreadyRedirected { 
    do ##class(%Device).ReDirectIO(1) 
    use $io::(oldMnemonic) 
  }
  
  if isRedirected {
    do ##class(%Device).ReDirectIO(0)
  }
  
  return sc
  
wstr(s) Do stream.Write(s) Quit
wchr(a) Do stream.Write($char(a)) Quit
wnl Do stream.Write($char(13,10)) Quit
wff Do stream.Write($char(13,10,13,10)) Quit
wtab(n) Do stream.Write($c(9)) Quit
rstr(len,time) Quit ""
rchr(time) Quit ""
}*/
ClassMethod SerializeToStream(dynamic As %DynamicAbstractObject, Output str As %Stream.Object = "") As %Status [ ProcedureBlock = 0 ]
{
  new oldMnemonic, alreadyRedirected, sc
  
  set sc = $$$OK
  set isRedirected = 0
  
  set str = ##class(%Stream.TmpBinary).%New()
  set alreadyRedirected = ##class(%Device).ReDirectIO()
  set oldMnemonic = "^"_##class(%Device).GetMnemonicRoutine()
  set initIO = $io
  
  try {    
    use $io::("^"_$zname)
    
    do ##class(%Device).ReDirectIO(1)
    set isRedirected = 1
    set sc = ..Serialize(dynamic)
  } catch ex {
    set str = ""
    set sc = ex.AsStatus()
  }
  
  do str.Rewind()  
  
  if oldMnemonic '= "" {
    use initIO::(oldMnemonic)
  } else {
    use oldMnemonic
  }
  
  do ##class(%Device).ReDirectIO(alreadyRedirected)  
      
  return sc
  
wstr(s) Do str.Write(s) Quit
wchr(a) Do str.Write($char(a)) Quit
wnl Do str.Write($char(13,10)) Quit
wff Do str.Write($char(13,10,13,10)) Quit
wtab(n) Do str.Write($c(9)) Quit
rstr(len,time) Quit ""
rchr(time) Quit ""
}

ClassMethod T()
{
  set p = ##class(Frontier.SQL.Provider).%New("SELECT TOP 3 * FROM FRONTIER_UNITTEST_FIXTURES.CLASS")
  set sc = p.Execute()
  
  set j = { "p": (p) }
  
  set sc = ##class(Frontier.Dynamic.Serializer).SerializeToStream(j, .str)
  do str.OutputToDevice()
}

}

