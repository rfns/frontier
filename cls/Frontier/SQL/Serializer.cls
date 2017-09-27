Include (frontier, %ZEN.Utils)

Class Frontier.SQL.Serializer Extends Frontier.AbstractSerializer
{

ClassMethod Serialize(results As %SQL.Statement) As %Status
{
  #define WriteThrowable(%expr) $$$ThrowOnError(data.Write(%expr))
  
  set sc = $$$OK
  set metadata = results.%GetMetadata()
  $$$QuitOnError(..FetchColumnNames(metadata, .columnNames))
  
  set data = ##class(%Stream.GlobalCharacter).%New()
  
  $$$WriteThrowable("[")
  
  set itemComma = ""
  set propertyComma = ""
  
  try {               
    while results.%Next(.sc) {
      $$$WriteThrowable(itemComma)
      
      set itemComma = ","
      set propertyComma = ""
      
      $$$WriteThrowable("{")
      $$$ThrowOnError(sc)      
      
      for c=1:1:columnNames {
        set columnName = columnNames(c)        
        set value = results.%Get(columnName)        
        
        $$$WriteThrowable(propertyComma)
        
        if $listvalid(value) && ($listlength(value) > 0) {
          set arrayComma = ""
          
          $$$WriteThrowable("[")
          
          for i=1:$listlength(value) {
            $$$WriteThrowable($$$ZENJSONVALUE(value, "s"))
            $$$WriteThrowable(arrayComma)
            set arrayComma = ","
          }
          
          $$$WriteThrowable("]")
        }
        $$$WriteThrowable($$$ZENJSONPAIR(columnName, value, "s"))
        set propertyComma = ","
      }
      $$$WriteThrowable("}")
    }   
    $$$WriteThrowable("]")
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

