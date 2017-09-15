Class Frontier.Reporter.Manager Extends %RegisteredObject
{

Property Reporters As list Of Frontier.Reporter [ Private ];

Property Context As Frontier.Context [ Private ];

Method %OnNew(context As Frontier.Context) As %Status
{
  set ..Context = context
  return $$$OK
}

Method AddReporter(reporter As Frontier.Reporter) As %Status
{
  $$$QuitOnError(reporter.Setup(..Context))
  $$$QuitOnError(..Reporters.Insert(reporter))
  return $$$OK
}

Method Report() As %Status
{
  set sc = $$$OK
  if $$$ISOK(..Context.Error) return $$$OK
  
  for i=1:1:..Reporters.Count() {
    set reporter = ..Reporters.GetAt(i)
    set sc = $$$ADDSC(sc, reporter.Report(..Context))
  }  
  return sc
}

Method SetupReporters() As %Status
{
  set sc = $$$OK
  
  for i=1:1:..Reporters.Count() {
    set reporter = ..Reporters.GetAt(i)
    set sc = $$$ADDSC(reporter.Setup(..Context), sc)
  }  
  return $$$OK
}

}

