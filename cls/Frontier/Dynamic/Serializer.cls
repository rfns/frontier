Include (frontier, %ZEN.Utils)

Class Frontier.Dynamic.Serializer Extends Frontier.AbstractSerializer
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

}

