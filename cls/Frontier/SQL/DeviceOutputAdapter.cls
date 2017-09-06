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
       Set tColInfo(c,"name") = resultSet.GetColumnHeader(c)
      }
    } else {
      set columnsCount = resultSet.%ResultColumnCount
      for c = 1:1:columnsCount {
        set tColInfo(c,"name") = resultSet.%Metadata.columns.GetAt(c).label
      }
    }   
    
    set arrayNode = []    
    Set row = 0
    
    while (resultSet.%Next(.tSC) && ((..maxRows = 0) || (row < ..maxRows))) {
      quit:$$$ISERR(tSC)
      set row = row + 1
      set node = ##class(%DynamicObject).%New()
      for c = 1:1:resultSet.%ResultColumnCount {
        set tVal = resultSet.%GetData(c)
        
        if ($isvalidnum(tVal) && ($e(tVal) '= 0)) do node.%Set($get(tColInfo(c,"name")),$num(tVal),"number")
        else  do node.%Set($get(tColInfo(c,"name")),tVal)
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

