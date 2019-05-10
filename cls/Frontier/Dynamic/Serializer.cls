/// This class is basically an overwrite for the %ToJSON method, because Frontier needs features
/// that allows the mixed serialization of SQL providers and streams.
/// Note: As of the Caché 2019 version, the support for serializing streams have been introduced,
/// however since Frontier targets the 2017 onwards, this class is still required.
Class Frontier.Dynamic.Serializer Extends Frontier.AbstractSerializer
{

/// Takes an %DynamicAbstractObject and serializes it while writing back to the current device.
/// This method is not supposed to be used manually.
ClassMethod Serialize(dynamic As %DynamicAbstractObject, depth As %String = 1, propertyFormatter As Frontier.PropertyFormatter = "") As %Status [ Internal ]
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
    set propertyName = key
    set type = dynamic.%GetTypeOf(key)

    if $isobject(propertyFormatter) {
      set propertyName = propertyFormatter.Format(propertyName, depth)
    }

    if 'isArray {
      write $$$ZENJSONPROP(propertyName, "s")_":"
    }

    if value = "null" || (type = "null" && (value = "")) {
      write "null"
    } elseif type = "boolean" || (value?1(1"true",1"false") = 1) {
      write $$$FormatBoolean(value)
    } elseif $isobject(value) {
      set type = $classname(value)
      if ##class(Frontier.Types).IsDynamic(type) {
        set sc = $$$ADDSC(sc, ..Serialize(value, depth, propertyFormatter))
      } elseif ##class(Frontier.Types).IsStream(type) {
        write $c(34)
        do WriteEscaped(value)
        write $c(34)
      } elseif ##class(Frontier.Types).IsSQLProvider(type) {
        if 'value.StatementExecuted set sc = value.Execute()
        if $$$ISERR(sc) quit
        $$$ThrowOnError(##class(Frontier.SQL.Serializer).Serialize(value.Results, value.Metadata, depth, propertyFormatter))
      }
    } elseif type = "string" {
      write $$$ZENJSONSTR(value, "s")
    } elseif type = "number" {
      write $$$ZENJSNUM(value)
    } else {
      write $$$ZENJSONVALUE(value, "s")
    }
  }

  $$$QuitOnError(sc)

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
