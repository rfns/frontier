Class Frontier.Authentication.Common [ Abstract ]
{

ClassMethod SetUser() As %Status
{
  return $$$OK
}

ClassMethod GetUser() As %Status
{
  return $$$OK
}

ClassMethod ValidateAccess(session As %CSP.Session, request As %CSP.Request) As %Status
{
}

}

