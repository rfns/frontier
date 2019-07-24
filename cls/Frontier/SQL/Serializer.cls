Class Frontier.SQL.Serializer Extends Frontier.AbstractSerializer
{

ClassMethod Serialize(results As %SQL.Statement, metadata As %SQL.StatementMetadata, depth As %Integer = 1, propertyFormatter As Frontier.PropertyFormatter = "") As %Status
{
     
  set sc = $$$OK
  $$$QuitOnError(..FetchColumnMetadatas(metadata, .columnMetadata))  
  
  set data = ##class(%Stream.GlobalCharacter).%New()
  
  write "["
  
  set itemComma = ""
  set propertyComma = ""
  
  try {               
    while results.%Next(.sc) {
      $$$ThrowOnError(sc)
      
      write itemComma
      
      set itemComma = ","
      set propertyComma = ""
      
      write "{"         
      
      for c=1:1:columnMetadata {
        write propertyComma
        set propertyComma = ","
        
        set columnName = columnMetadata(c)
        set columnType = columnMetadata(c, "type")
        set isList = columnMetadata(c, "list")
        set value = results.%Get(columnName)        
        set jsonDataFormat = ##class(Frontier.Types).GetJSONDataFormat(columnType)
        
        if $isobject(propertyFormatter) {
          set columnName = propertyFormatter.Format(columnName, depth)
        }
        
        write $$$ZENJSONPROP(columnName, "s")_":"
        
        if isList = 1 {
          set delimiter = columnMetadata(c, "list_delimiter")
          set isString = columnMetadata(c, "list_string")
          do ListToJSONArray(value, delimiter, isString)
        } elseif value = "" && (jsonDataFormat = "null") {
          if jsonDataFormat = "null" write jsonDataFormat
          else  write """"
        } elseif jsonDataFormat = "boolean" {
          set value = $$$FormatBoolean(value)
          // Must be set to empty and not assume false because some applications might be checking the value like: value '= "".
          // That could generate a breaking change.
          if value = "" write """"""
          else  write value
        } else {
          write $$$ZENJSONVALUE(value, "s")
        }                               
      }
      write "}"
    }   
    write "]"
  } catch ex {
    set sc = ex.AsStatus()
  }
  return sc
  
ListToJSONArray(value, delimiter, string)
  write "["
  
  set comma = ""  
  set length = $length(value, delimiter)
  
  for i=1:1:length {
    write comma
    if string write $$$ZENJSONSTR($piece(value, delimiter, i), "s")
    else  write $$$ZENJSNUM($piece(value, delimiter, i))
    set comma = ","
  }
  
  write "]"
}

ClassMethod FetchColumnMetadatas(metadata As %SQL.StatementMetadata, Output columnMetadata As %String) As %Status [ Private ]
{
  
  set columns = metadata.columns
  set columnMetadata = columns.Count()
  for i=1:1:columnMetadata {
    set column = columns.GetAt(i)
    set columnMetadata(i) = column.label
    
    if $isobject(column.typeClass) {
      set columnMetadata(i, "type") = column.typeClass.Name
    } else {
      set columnMetadata(i, "type") = ""
    }
    
    if $isobject(column.property) {
      set columnMetadata(i, "list") = (column.property.Collection = "list")
      set columnMetadata(i, "list_delimiter") = $$$trimQuote(column.property.Parameters.GetAt("CollectionOdbcDelimiter"))
      set columnMetadata(i, "list_string") = ($$$ucase(column.property.Type) [ "STRING")
    } else {
      set columnMetadata(i, "list") = 0
    }
  }  
  return $$$OK
}

}

