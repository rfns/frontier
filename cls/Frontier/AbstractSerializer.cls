Include (frontier, %ZEN.Utils)

Class Frontier.AbstractSerializer [ Abstract ]
{

ClassMethod SerializeToStream(Output str As %Stream.Object = "", arguments...) As %Status [ ProcedureBlock = 0 ]
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
    set sc = ..Serialize(arguments...)
    do str.Rewind()
  } catch ex {
    set str = ""
    set sc = ex.AsStatus()
  }   
  
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

}

