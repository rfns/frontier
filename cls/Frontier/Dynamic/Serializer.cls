Include (frontier, %ZEN.Utils)

Class Frontier.Dynamic.Serializer
{

ClassMethod Serialize(dynamic As %DynamicAbstractObject, parentKey As %String = "") As %Status [ Internal ]
{
  set sc = $$$OK
  set results = ""
  set isArray = ##class(Frontier.Types).IsDynamicArray($classname(dynamic))    
  
  if isArray {
    write "["
  } else {
    write "{"
  }
  
  set iterator = dynamic.%GetIterator()   
  set comma = ""  
  
  while iterator.%GetNext(.key, .value) {
    write comma
    set comma = ","
    if 'isArray write $$$ZENJSONPROP(key, "s")_":"
    if $isobject(value) {
      set type = $classname(value)
      if ##class(Frontier.Types).IsDynamic(type) {         
        set sc = $$$ADDSC(sc, ..Serialize(value, key))
      } elseif ##class(Frontier.Types).IsStream(type) {
        write $c(34)
        do WriteEscaped(value)
        write $c(34)
      } elseif ##class(Frontier.Types).IsSQLProvider(type) {
        if 'value.StatementExecuted $$$ThrowOnError(value.Execute())
        $$$ThrowOnError(##class(Frontier.SQL.Serializer).Serialize(value.Results))
      }
    } else {
      write $$$ZENJSONVALUE(value, "s")
    }    
  }
  
  if isArray write "]"
  else  write "}"
  
  return sc
  
WriteEscaped(v)
  while 'v.AtEnd { 
    write $$$ZENJSONESCAPE(v.Read(),"s")
  }
}

ClassMethod SerializeToStream(dynamic As %DynamicAbstractObject, Output stream As %Stream.Object = "") [ ProcedureBlock = 0 ]
{
  new currentMnemonic, alreadyRedirected, sc
  
  set sc = $$$OK
  set isRedirected = 0
  
  set stream = ##class(%Stream.TmpBinary).%New()
  set alreadyRedirected = ##class(%Device).ReDirectIO()
  
  try {
    set currentMnemonic = "^"_##class(%Device).GetMnemonicRoutine()
    use $io::("^"_$zname)
    do ##class(%Device).ReDirectIO(1)
    $$$ThrowOnError(..Serialize(dynamic))
  } catch ex {
    set sc = ex.AsStatus()
  }
  
  if alreadyRedirected { 
    do ##class(%Device).ReDirectIO(1) 
    use $io::(currentMnemonic) 
  }
  
  return sc
  
wstr(s) Do stream.Write(s) Quit
wchr(a) Do stream.Write($char(a)) Quit
wnl Do stream.Write($char(13,10)) Quit
wff Do stream.Write($char(13,10,13,10)) Quit
wtab(n) Do stream.Write($c(9)) Quit
rstr(len,time) Quit ""
rchr(time) Quit ""
}

}

