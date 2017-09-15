Include (frontier, %ZEN.Utils)

Class Frontier.SQL.Serializer [ Abstract ]
{

ClassMethod Serialize(results As %SQL.Statement) As %Status
{
  set sc = $$$OK
  $$$QuitOnError(..FetchColumnNames(results.%GetMetadata(), .columnNames))
  
  set data = ##class(%Stream.GlobalCharacter).%New()
  
  do data.Write("[")
  
  set itemComma = ""
  set propertyComma = ""
  
  try {               
    while results.%Next(.sc) {
      $$$ThrowOnError(data.Write(itemComma))
      
      set itemComma = ","
      set propertyComma = ""
      
      do data.Write("{")
      $$$ThrowOnError(sc)      
      
      for c=1:1:columnNames {
        set columnName = columnNames(c)
        set value = results.%Get(columnName)        
        
        $$$ThrowOnError(data.Write(propertyComma))
        $$$ThrowOnError(data.Write($$$ZENJSONPAIR(columnName, value, "s")))
        set propertyComma = ","
      }
      $$$ThrowOnError(data.Write("}"))
    }   
    $$$ThrowOnError(data.Write("]"))
    $$$ThrowOnError(data.OutputToDevice())    
  } catch ex {
    write "null"
    set sc = ex.AsStatus()
  }
  return sc
}

ClassMethod FetchColumnNames(metadata As %SQL.StatementMetadata, Output columnNames As %String) As %Status [ Private ]
{
  
  set columns = metadata.columns
  set columnNames = columns.Count()
  for i=1:1:columnNames set columnNames(i) = columns.GetAt(i).label
  return $$$OK
}

}

