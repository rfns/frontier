Class Frontier.DevTools.FakeRequest Extends %RegisteredObject
{

Property Data As %String [ MultiDimensional ];

Property CgiEnvs As %String [ MultiDimensional ];

Property URL As %String;

Property Method As %String;

Property Application As %String;

Property Content As %Stream.Object;

Property Cookies As %String [ MultiDimensional, Private ];

Method GetCgiEnv(name As %String) As %String
{
  return $get(i%CgiEnvs(name))
}

Method Get(name As %String, index As %Integer = 1, default As %String = "") As %String
{
  set index = $select(index < 1 : 1, 1: index)
  return $get(i%Data(name, index), default)
}

Method SetCookie(name As %String, value As %String, index As %Integer = 1)
{
  set index = $select(index < 1 : 1, 1: index) + 1
  set i%Cookies(name, index) = value
}

Method GetCookie(name As %String, index As %Integer = 1)
{
  return $get(i%Cookies(name, index))
}

}

