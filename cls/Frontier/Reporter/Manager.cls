Include %occErrors

/// This class allows the routers to add reporters and iterates over each calling the Report method.
/// For each call the context object is sent to provide full disclosure regarding the current status.
Class Frontier.Reporter.Manager Extends %RegisteredObject
{

/// This holds the list of the reporters added by using the AddReporter method.
Property Reporters As list Of Frontier.Reporter [ Private ];

/// This holds the current instance of the class Frontier.Context.
Property Context As Frontier.Context [ Private ];

Method %OnNew(context As Frontier.Context) As %Status
{
  set ..Context = context   
  return $$$OK
}

/// Adds a reporter to the queue which is called whenever an uncaught exception is detected.
Method AddReporter(reporter As Frontier.Reporter) As %Status
{
  return ..Reporters.Insert(reporter)
}

/// Iterates over the queue calling the Report method for each. Each call is implementation dependent.
Method Report() As %Status [ Internal ]
{
  set sc = $$$OK
  if '$isobject(..Context.Exception) return $$$OK
  
  try {
    for i=1:1:..Reporters.Count() {
      set reporter = ..Reporters.GetAt(i)
      set sc = $$$ADDSC(sc, reporter.Report(..Context))
    }
  } catch ex {
    set sc = ex.AsStatus()
  }
  return sc
}

}

