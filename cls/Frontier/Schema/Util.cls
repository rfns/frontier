Class Frontier.Schema.Util [ Abstract ]
{

ClassMethod Parse(targetClass As %String, Output routes As Frontier.Schema.Routes) As %Status [ Internal ]
{
  set sc = $$$OK
  set xdataId = targetClass_"||UrlMap"
  
  if '##class(%Dictionary.CompiledXData).%ExistsId(xdataId) {
    return $$$ERROR($$$XDataBlockMissing, targetClass, "UrlMap")
  }
  
  try {
    set reader = ##class(%XML.Reader).%New()
    set xdata = ##class(%Dictionary.CompiledXData).%OpenId(xdataId).Data   
    set resolver = ##class(%XML.SAX.XDataEntityResolver).%New(targetClass)
    set reader.EntityResolver = resolver
    $$$ThrowOnError(reader.OpenStream(xdata))
    do reader.Correlate("Routes", "Frontier.Schema.Routes")
    do reader.Next(.routes, .sc)
    $$$ThrowOnError(sc)
  } catch ex {
    set sc = ex.AsStatus()
  }
  return sc
}

ClassMethod GeneratePatterns(routes As Frontier.Schema.Routes, targetClass As %String, Output patterns As %String) As %Status [ Internal ]
{
  #dim route As Frontier.Schema.Route
  #dim map as Frontier.Schema.Map
  
  set totalRoutes = routes.Route.Count()
  set totalMaps = routes.Map.Count()
  
  if totalRoutes > 0 {
    set resourceType = "R"
    for i=1:1:totalRoutes {
      set route = routes.Route.GetAt(i)
      set pattern = $$WritePattern(route.Url, .placeholders)
      set patterns(i) = $lb(resourceType, pattern, route.Method, route.Call, route.Cors, placeholders, route.Scope)
    }    
  } 
  if totalMaps > 0 {
    set resourceType = "M"
    for i=1:totalMaps {
      set map = routes.Map.GetAt(i)
      set patterns(i) = $lb(resourceType, $$WritePattern(map.Prefix), map.Forward)
    }
  }
  
  return $$$OK
  
WritePattern(resource, placeholders)
  set pattern = ""
  set placeholders = ""
  for resourceIndex=2:1:$length(resource,"/") {
    set resourcePart = $piece(resource,"/", resourceIndex)
    if $extract(resourcePart) = ":" {
      set $list(placeholders, *+1) = $piece(resourcePart, ":", 2)
      if resourceType = "R" {
        set pattern = pattern_"/([^"_$char(0)_"]+)"        
      } else {        
        set pattern = pattern_"/[^/]+"
      }
    } else {
      set pattern = pattern_"/"_resourcePart
    }
  }
  if resourceType = "R" return $translate(pattern, $char(0), "/")
  return "("_pattern_")/.*"
}

}

