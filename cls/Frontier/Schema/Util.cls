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
  set i = ""
  
  if totalRoutes > 0 {
    set resourceType = "R"
    for i=1:1:totalRoutes {
      set route = routes.Route.GetAt(i)
      set pattern = $$WritePattern(route.Url, .placeholders)
      set patterns(i) = $lb(resourceType, pattern, route.Method, route.Call, route.Cors, placeholders, route.Scope, route.UseAuth, route.Strict)
    }    
  } 
  if totalMaps > 0 {
    set resourceType = "M"
    for j=1:1:totalMaps {
      set map = routes.Map.GetAt(j)
      set pattern = $$WritePattern(map.Prefix, .placeholders)
      set patterns(i + j) = $lb(resourceType, pattern, map.Forward, placeholders, map.Strict)
    }
  }
  
  return $$$OK
  
WritePattern(resource, placeholders)
  #define GetPlaceholder(%exp) $piece(%exp, ":", 2) 
  #define AddPlaceholderIfNotDefined(%placeholder)  ##continue
  if '$lf(placeholders, %placeholder) { ##continue
    set $list(placeholders, *+1) = $$$GetPlaceholder(%placeholder) ##continue 
  }
    
  
  set pattern = ""
  set placeholders = ""
  set shouldCloseParenthesis = 0
  
  if $extract(resource) = ":" {
    $$$AddPlaceholderIfNotDefined($piece(resource, "/", 1))
  }
  
  set resourcePartsLength = $length(resource,"/")
  
  for resourceIndex=2:1:resourcePartsLength {
    set resourcePart = $piece(resource,"/", resourceIndex)
    if $extract(resourcePart) = ":" {
      $$$AddPlaceholderIfNotDefined(resourcePart) 
      set pattern = pattern_"/([A-Za-z0-9-._~:]+)"
    } else {      
      set pattern = pattern_"/"_resourcePart
    }   
  }
  return $case(resourceType, "M" : pattern_"/?(.*)", : pattern)
}

}

