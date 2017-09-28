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
  set readCount = 0
  do v.Rewind()
  
  // Instead of using AtEnd, we compare the stream size with the buffer read size.
  // This is because apparently AtEnd doesn't track the position correctly when the device is redirected.
  // This can also be related to how we are dealing with this redirection along with %CSP.REST.
  while readCount < v.Size {
    set buffer = v.Read()
    set readCount = readCount + $length(buffer)
    write $$$ZENJSONESCAPE(buffer,"s")
  }
}

}

