Class Frontier.Context Extends %RegisteredObject
{

Property Session As %CSP.Session [ ReadOnly ];

Property Request As %CSP.Request [ ReadOnly ];

Method %OnNew(session As %CSP.Session, request As %CSP.Request) As %Status
{
  set i%Session = session
  set i%Request = request
  return $$$OK
}

}

