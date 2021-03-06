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
  set k = 0
  set p = 0
  
  set lowPriorityPatterns = 0
  
  if totalRoutes > 0 {
    set resourceType = "R"
    for i=1:1:totalRoutes {
      set route = routes.Route.GetAt(i)
      set pattern = $$WritePattern(route.Url, .placeholders, route.Strict)
      set routePattern = $lb(resourceType, pattern, route.Method, route.Call, route.Cors, placeholders, route.Scope, route.UseAuth, route.Strict, route.Url, route.AuthStrategy)
      if placeholders = "" && (pattern '= "/") {
        set patterns($increment(p)) = routePattern
      } else {
        set lowPriorityPatterns($increment(k)) = routePattern
        set lowPriorityPatterns = k
      }
    }    
  } 
  
  if totalMaps > 0 {
    set resourceType = "M"
    for j=1:1:totalMaps {
      set map = routes.Map.GetAt(j)
      set pattern = $$WritePattern(map.Prefix, .placeholders, 1)
      set routePattern = $lb(resourceType, pattern, map.Forward, placeholders, 1)
      if placeholders = "" && (pattern '= "/") {
        set patterns($increment(p)) = routePattern
      } else {
        set lowPriorityPatterns($increment(k)) = routePattern
        set lowPriorityPatterns = k
      }
    }
  }
  
  for i=1:1:lowPriorityPatterns {
    set patterns(p + i) = lowPriorityPatterns(i)
  }  
  
  return $$$OK
  
WritePattern(resource, placeholders, strict)
  #define GetPlaceholder(%exp) $piece(%exp, ":", 2) 
  #define AddPlaceholderIfNotDefined(%placeholder)  ##continue
  if '$lf(placeholders, %placeholder) { ##continue
    set $list(placeholders, *+1) = $$$GetPlaceholder(%placeholder) ##continue 
  }    
      
  set pattern = ""
  set placeholders = ""
  set shouldCloseParenthesis = 0
  
  if 'strict return resource
  
  if $extract(resource) = ":" {
    $$$AddPlaceholderIfNotDefined($piece(resource, "/", 1))
  }
  
  set resourcePartsLength = $length(resource,"/")
  
  for resourceIndex=2:1:resourcePartsLength {
    set resourcePart = $piece(resource,"/", resourceIndex)
    if $extract(resourcePart) = ":" {
      $$$AddPlaceholderIfNotDefined(resourcePart) 
      set pattern = pattern_"/([^\/]+?)"
    } else {      
      set pattern = pattern_"/"_resourcePart
    }   
  }
  return $case(resourceType, "M" : pattern_"(?:(?:/(?=.*))(.*)|/?$)", : pattern)
}

}

