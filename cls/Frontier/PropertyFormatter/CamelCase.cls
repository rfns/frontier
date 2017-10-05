Class Frontier.PropertyFormatter.CamelCase Extends Frontier.PropertyFormatter
{

Method OnFormat(propertyName As %String) As %String
{
	
	return ..Camelify(propertyName)
}

ClassMethod Camelify(propertyName As %String) As %String
{
	return $$$lcase($extract(propertyName, 1))_$extract(propertyName, 2, *)
}

}

