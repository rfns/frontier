Class Frontier.SQL.DeviceOutputAdapter Extends %ZEN.Auxiliary.altJSONSQLProvider
{

Method %DrawJSON() As %Status [ Internal ]
{
  set sc = $$$OK
  set ..contentType = "array"
  set key = ""
  
  try {    
    while ..parameters.GetNext(.key) {
      set value = ..parameters.GetAt(key).value
      Set parameters(key) = $$$ZENVAL(value)
    }        
    
    set queryInfo = ##class(%ZEN.Auxiliary.QueryInfo).%New()     
    merge queryInfo.parms = parameters
    set resultSet = ..%CreateResultSet(.sc, queryInfo)
    if $$$ISERR(sc) || '$isobject(resultSet) write "null" quit
    
    kill columnInfo
    
    if resultSet.%IsA("%Library.ResultSet") {
      set columnsCount = resultSet.GetColumnCount()
      for c = 1:1:columnsCount {
       Set columnInfo(c,"name") = resultSet.GetColumnHeader(c)
      }
    } else {
      set columnsCount = resultSet.%ResultColumnCount
      for c = 1:1:columnsCount {
        set columnInfo(c,"name") = resultSet.%Metadata.columns.GetAt(c).label
      }
    }   
    
    set arrayNode = []    
    Set row = 0
    
    while (resultSet.%Next(.sc) && ((..maxRows = 0) || (row < ..maxRows))) {
      quit:$$$ISERR(sc)
      set row = row + 1
      set node = {}
      for c = 1:1:resultSet.%ResultColumnCount {
        set value = resultSet.%GetData(c)
        
        if ($isvalidnum(value) && ($e(value) '= 0)) do node.%Set($get(columnInfo(c,"name")),$num(value),"number")
        else  do node.%Set($get(columnInfo(c,"name")),value)
      }
      Do arrayNode.%Push(node)
    }   
    do arrayNode.%ToJSON()    
  } catch ex {
    Write "null"
    Set tSC = ex.AsStatus()  
  }
  return $$$OK
}

}

