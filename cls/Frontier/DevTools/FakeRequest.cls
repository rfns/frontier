Class Frontier.DevTools.FakeRequest Extends %RegisteredObject
{

Property Data As %String [ MultiDimensional ];

Property CgiEnvs As %String [ MultiDimensional ];

Property URL As %String;

Property Method As %String;

Property Application As %String;

Property Content As %Stream.Object;

Method GetCgiEnv(name As %String) As %String
{
  return $get(i%CgiEnvs(name))
}

Method Get(name As %String, default As %String = "") As %String
{
  return $get(i%Data(name), default)
}

}

