Class Frontier.PropertyFormatter.SnakeCase Extends Frontier.PropertyFormatter
{

Method OnFormat(propertyName As %String) As %String
{
	
	return ..Snakeify(propertyName)
}

ClassMethod Snakeify(propertyName As %String) As %String
{
	set snakedName = ""
	set nameLength = $length(propertyName)
	for i=1:1:nameLength {
		set c = $extract(propertyName, i)
		set n = $extract(propertyName, i+1)
		if c = $$$ucase(c) && (n '= $$$ucase(n)) && (i > 1) set c = "_"_c
		set snakedName = snakedName_c
	}	
	return $$$lcase(snakedName)
}

}

