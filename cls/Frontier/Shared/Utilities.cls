Class Frontier.Shared.Utilities [ Abstract ]
{

ClassMethod RandomString(size, lowerCase As %Boolean = 0, extras = "") As %String
{
  set key = ""
  set alpha = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
  if lowerCase = 1 set alpha = alpha_$$$lcase(alpha)
  if extras '= "" set alpha = alpha_extras
  
  while $length(key) < size {
    set next = $select($random(2) = 1 : $extract(alpha, $random($length(alpha))), 1: $random(9))
    set key = key_next
  }
  quit key
}

ClassMethod SanitizeFilename(fileName) As %String
{
  if fileName [ "/" set fileName = $piece(fileName, "/", *)
  if fileName [ "\" set fileName = $piece(fileName, "\", *)
  
  set fileName = $translate(fileName, "àáÁÀÂâÃÁÂÃãèéÉÈêÊÉìíÍÌÎîòóÓÒÔôÕÓÔõùúÚÙÛûÇçÖöÜüÑ", "aaAAAaAAAAaeeEEeEEiiIIIiooOOOOOoOouuUUUuCcOoUuN")
  return $zstrip(fileName, "*E'N'A", "", "_-@. ")
}

ClassMethod ReplacePlaceholders(definitions As %DynamicObject) As %String
{
  set text = definitions.text
    
  set it = definitions.placeholders.%GetIterator()
  while it.%GetNext(.key, .value) { set text = $replace(text, key, value) }  
  
  return text
}

ClassMethod DeepExtend(sources... As %DynamicObject) As %DynamicObject
{
  
  #dim result As %DynamicObject
    
  set result = {}    
  
  for i=1:1:sources {
    set iterator = sources(i).%GetIterator()
    while iterator.%GetNext(.property, .value) {
      set target = $property(result, property)
      if $isobject(value) && value.%IsA("%DynamicObject") && $isobject(target) {
        set isSameSize = (target.%Size() = value.%Size())
        set hasSameProperty = $property(target, property) = $property(value, property)
        if '(isSameSize && hasSameProperty) {
          set $property(result, property) = ..DeepExtend(target, value)
        }
      } elseif 'result.%IsDefined(property) {
        set $property(result, property) = value
      }      
    }
  }
  return result
}

}

