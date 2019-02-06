Class Frontier.PropertyFormatter Extends %RegisteredObject
{

Property Properties As %String [ MultiDimensional, Private ];

Method Format(propertyName As %String, depth As %Integer = 1) As %String
{
  set storedFormatted = $get(i%Properties(depth, propertyName, "F"))
  if storedFormatted return storedFormatted
  
  set formattedName = ..OnFormat(propertyName)
  
  set i%Properties(depth, propertyName, "F") = formattedName
  set i%Properties(depth, formattedName, "N") = propertyName
  return formattedName
}

Method FormatAllProperties(collection As %ListOfObjects, depth As %Integer = 1) [ Internal ]
{
  for i=1:1:collection.Count() {
    set propertyName = collection.GetAt(i).Name
    if $extract(propertyName) '= "%" {
      do ..Format(collection.GetAt(i).Name, depth)
    }
  }
}

Method OnFormat(propertyName) As %String [ Private ]
{
  return propertyName
}

Method Normalize(formattedName As %String, depth As %Integer = 1) As %String [ Final ]
{
  
  return $get(i%Properties(depth, formattedName, "N"))
}

}

