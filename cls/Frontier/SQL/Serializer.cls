Class Frontier.SQL.Serializer Extends Frontier.AbstractSerializer
{

ClassMethod Serialize(context As Frontier.Context, provider As Frontier.SQL.Provider, depth As %Integer = 0) As %Status
{
	
	set results = provider.Results
	set metadata = provider.Metadata
	set propertyFormatter = context.PropertyFormatter
	set indentBy = context.Parameters.INDENTSIZE
	     
  #define NewLineIf write $select(indentBy > 0 : $char(10), 1: "")
  #define SpaceIf $select(indentBy > 0: " ", 1: "")
  
  set sc = $$$OK
  $$$QuitOnError(..FetchColumnMetadatas(metadata, .columnMetadata))  
  
  set data = ##class(%Stream.GlobalCharacter).%New()
  
  if depth > 1 do ..SetIndentation(depth * indentBy)
  write "["
  set depth = depth + 1
  
  set itemComma = ""
  set propertyComma = ""   
  
  try {               
    while results.%Next(.sc) {
      $$$ThrowOnError(sc)
      
      write itemComma      
            
      set itemComma = ","
      set propertyComma = ""
      
      if itemComma = "," $$$NewLineIf
      
      do ..SetIndentation(depth * indentBy)
      write "{"
      set depth = depth + 1
      $$$NewLineIf
      
      for c=1:1:columnMetadata {
        write propertyComma
        
        if propertyComma = "," $$$NewLineIf
        set propertyComma = ","
                        
        do ..SetIndentation(depth * indentBy)
        
        set columnName = columnMetadata(c)
        set columnType = columnMetadata(c, "type")
        set isList = columnMetadata(c, "list")
        set value = results.%Get(columnName)        
        set jsonDataFormat = ##class(Frontier.Types).GetJSONDataFormat(columnType)
        
        if $isobject(propertyFormatter) {
          set columnName = propertyFormatter.Format(columnName, depth)
        }
        
        write $$$ZENJSONPROP(columnName, "s")_":"_$$$SpaceIf
        
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
      
      $$$NewLineIf
      set depth = depth - 1
      if depth > 1 do ..SetIndentation(depth * indentBy)
      write "}"
    }
    
    set depth = depth - 1    
    $$$NewLineIf
    do ..SetIndentation(depth * indentBy)
    write "]"    
    
  } catch ex {
    set sc = ex.AsStatus()
  }
  return sc
  
ListToJSONArray(value, delimiter, string)
  #define IsList(%value) $lv(%value) && $ll(%value)
  write "["
  
  set depth = depth + 1
  
  set comma = ""
  set isList = $select($lv(value) && $ll(value) : 1, 1: 0)
  set length = $select(isList : $ll(value), 1: $length(value, ","))
  
  for i=1:1:length {
    write comma
    if isList {
      if string write $$$ZENJSONSTR($lg(value, i), "s")
      else  write $$$ZENJSNUM($lg(value, i))
    } else {
      if string write $$$ZENJSONSTR($piece(value, delimiter, i), "s")
      else  write $$$ZENJSNUM($piece(value, delimiter, i))      
    }
    set comma = ","
    $$$NewLineIf
    do ..SetIndentation(depth * indentBy)
  }
  
  set depth = depth - 1
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

