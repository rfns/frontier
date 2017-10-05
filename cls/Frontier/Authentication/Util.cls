Class Frontier.Authentication.Util [ Abstract ]
{

ClassMethod GenerateRandomString(size As %Integer, caseType As %String = "uppercase", extras As %String = "") As %String
{
  set key = ""
  set alpha = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
  if caseType = "mixed" set alpha = alpha_$$$lcase(alpha)
  if caseType = "lower" set alpha = $$$lcase(alpha)
  if extras '= "" set alpha = alpha_extras
  
  while $length(key) < size {
    set next = $select($random(2) = 1 : $extract(alpha, $random($length(alpha))), 1: $random(9))
    set key = key_next
  }
  return key
}

}

