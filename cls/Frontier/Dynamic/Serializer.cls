/// This class is basically an overwrite for the %ToJSON method, because Frontier needs features
/// that allows the mixed serialization of SQL providers and streams.
/// Note: As of the Caché 2019 version, the support for serializing streams have been introduced,
/// however since Frontier targets the 2017 onwards, this class is still required.
Class Frontier.Dynamic.Serializer Extends Frontier.AbstractSerializer
{

/// Takes an %DynamicAbstractObject and serializes it while writing back to the current device.
/// This method is not supposed to be used manually.
ClassMethod Serialize(context As Frontier.Context, dynamic As %DynamicAbstractObject, depth As %String = 0) As %Status [ Internal ]
{
 
  #define NewLineIf if indentBy > 0 write $c(10)
  #define SpaceIf  $select(indentBy > 0 : " ", 1: "")
  
  set propertyFormatter = context.PropertyFormatter
  set maxDepth = context.Parameters.MAXIMUMDEPTH
  set indentBy = context.Parameters.INDENTSIZE
  
  set sc = $$$OK
  set results = ""
  
  set isArray = ##class(Frontier.Types).IsDynamicArray($classname(dynamic))  

  if isArray {
    write "["
  } else {
    write "{"
  }
  
  break:dynamic.%IsA("Frontier.Context")
  set iterator = dynamic.%GetIterator()
  set comma = ""
  
  set depth = depth + 1
  
  if dynamic.%Size() > 0 $$$NewLineIf  

  while iterator.%GetNext(.key, .value) {    
    write comma
    if comma = "," $$$NewLineIf
    
    set comma = ","        
    set propertyName = key
    set type = dynamic.%GetTypeOf(key)

    if $isobject(propertyFormatter) {
      set propertyName = propertyFormatter.Format(propertyName, depth)
    }
    
    do ..SetIndentation(depth * indentBy)

    if 'isArray {      
      write $$$ZENJSONPROP(propertyName, "s")_":"_$$$SpaceIf
    }    

    if value = "null" || (type = "null" && (value = "")) {
      write "null"
    } elseif type = "boolean" || (value?1(1"true",1"false") = 1) {
      write $$$FormatBoolean(value)
    } elseif $isobject(value) {
      set type = $classname(value)
      if ##class(Frontier.Types).IsDynamic(type) {
        $$$ReturnOnError(..Serialize(context, value, depth))
      } elseif ##class(Frontier.Types).IsStream(type) {
        write $c(34)
        do WriteEscaped(value)
        write $c(34)
      } elseif ##class(Frontier.Types).IsSQLProvider(type) {
        if 'value.StatementExecuted $$$ReturnOnError(value.Execute())        
        $$$ReturnOnError(##class(Frontier.SQL.Serializer).Serialize(context, value, depth))
      } elseif ##class(Frontier.Types).IsInstantiable(type) {
        set child = value
        set value = ""
        $$$ReturnOnError(##class(Frontier.Dynamic.Marshaller).MarshalDirect(child, .value, maxDepth - depth))        
        $$$ReturnOnError(..Serialize(context, value, depth))
      }
    } else {
      if type = "string" { write $$$ZENJSONSTR(value, "s") }
      elseif type = "number" { write $$$ZENJSNUM(value) }
      else { write $$$ZENJSONVALUE(value, "s") } 
       
    }    
    if $$$ISERR(sc) quit                 
  }
  set depth = depth - 1
  if dynamic.%Size() > 0 $$$NewLineIf do ..SetIndentation(depth * indentBy)
  if isArray write "]"
  else  write "}"  

  return sc

WriteEscaped(v)
  set readCount = 0
  do v.Rewind()

  // Instead of using AtEnd, we compare the stream size with the buffer read size.
  // We use it this way, because apparently AtEnd doesn't track the position correctly when the device is redirected.
  // This can also be related to how we are dealing with this redirection along with %CSP.REST.
  while readCount < v.Size {
    set buffer = v.Read()
    set readCount = readCount + $length(buffer)
    write $$$ZENJSONESCAPE(buffer,"s")
  }
}

}

