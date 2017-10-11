Class Frontier.SQL.Serializer Extends Frontier.AbstractSerializer
{

ClassMethod Serialize(results As %SQL.Statement, metadata As %SQL.StatementMetadata, depth As %Integer = 1, propertyFormatter As Frontier.PropertyFormatter = "") As %Status
{
  
  #define WriteThrowable(%expr) $$$ThrowOnError(data.Write(%expr))
  
  set sc = $$$OK
  $$$QuitOnError(..FetchColumnNames(metadata, .columnNames))
  
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
      
      for c=1:1:columnNames {
        set columnName = columnNames(c)
        set columnType = columnNames(c, "type")
        set value = results.%Get(columnName)
        set jsonDataFormat = ##class(Frontier.Types).GetJSONDataFormat(columnType)     
        
        if jsonDataFormat = "null" && (value = "") {
          set value = jsonDataFormat
        } elseif jsonDataFormat = "boolean" {          
          set value = $$$FormatBoolean(value)
        }        
        
        if $isobject(propertyFormatter) {
          set columnName = propertyFormatter.Format(columnName, depth)
        }
        
        write propertyComma        
        
        write $$$ZENJSONPROP(columnName, "s")_":"                
        write ..HandleJSONWord(value)
        
        set propertyComma = ","
      }
      write "}"
    }   
    write "]"
  } catch ex {
    set sc = ex.AsStatus()
  }
  return sc
}

ClassMethod FetchColumnNames(metadata As %SQL.StatementMetadata, Output columnNames As %String) As %Status [ Private ]
{
  
  set columns = metadata.columns
  set columnNames = columns.Count()
  for i=1:1:columnNames {
    set column = columns.GetAt(i)
    set columnNames(i) = column.label
    if $isobject(column.typeClass) {
      set columnNames(i, "type") = column.typeClass.Name
    } else {
      set columnNames(i, "type") = ""
    }
  }  
  return $$$OK
}

}

