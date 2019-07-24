Class Frontier.SessionEvents Extends %CSP.SessionEvents
{

/// Called when we have finished processing this request
ClassMethod OnEndRequest() As %Status
{
  set frontier = %session.Get("%frontier")
  if $isobject(frontier) return frontier.ReporterManager.Report()
  return $$$OK
}

}

