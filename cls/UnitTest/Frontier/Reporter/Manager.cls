Class UnitTest.Frontier.Reporter.Manager Extends Port.UnitTest.TestCase
{

Property Context As Frontier.Context;

Property ReporterManager As Frontier.Reporter.Manager;

Property SetupStatuses As %Status [ InitialExpression = {$lb(1, ..CreateError(), 1, 1, ..CreateError(), ..CreateError())} ];

Property ReportStatuses As %Status [ InitialExpression = {$lb(..CreateError(), ..CreateError(), ..CreateError(), 1, 1)} ];

Property MockIds As %String [ MultiDimensional ];

Method OnBeforeOneTest() As %Status
{
  set session = ##class(%CSP.Session).%New("t3st1ng")
  set request = ##class(%CSP.Request).%New()
  set response = ##class(%CSP.Response).%New()
  set ..Context = ##class(Frontier.Context).%New(session, request, response)
  set ..Context.Error = ..CreateError()
  set ..ReporterManager = ..Context.ReporterManager
  return $$$OK
}

ClassMethod CreateError() As %Status
{
  return $$$ERROR($$$GeneralError, "dummy error")
}

Method OnAfterOneTest() As %Status
{
  set ..ReporterManager = ""
  set ..Context = ""
  kill ..MockIds
  return $$$OK
}

Method TestAddReporter(skipAssertion As %Boolean = 0) As %Status
{
  for i=1:1:$ll(..SetupStatuses) {
    set expectedSetupStatus = $lg(..SetupStatuses, i)
    set expectedReportStatus = $lg(..ReportStatuses, i)
    set mockReporter = ##class(Frontier.UnitTest.Reporter.Mock).%New()
    set ..MockIds(i) = mockReporter
    set mockReporter.ExpectedSetupStatus = expectedSetupStatus
    set mockReporter.ExpectedReportStatus = expectedReportStatus
    set returnedStatus = ..ReporterManager.AddReporter(mockReporter)
    set matchInstance = (^||Frontier.UnitTest.Spy("Setup", ..MockIds(i)) '= "")
    if 'skipAssertion {
      if (returnedStatus '= expectedSetupStatus) return $$$AssertTrue(0, "returns each reporter's Setup status")      
      if 'matchInstance return $$$AssertTrue(matchInstance, "Report received context.")
    }
  }
  return $$$OK
}

Method TestReport() As %Status
{
  
  set sc = ..TestAddReporter(1)
  if $$$ISERR(sc) return $$$AssertSkipped("failed to add dummy reporters")
  
  set sc = ..ReporterManager.Report()
  set errorCount = $$$GETERRORCOUNT(sc)
  // 2 because Setup failures nullifies reporters so they never can be used.
  // We actually have only 2 reporters added.
  if errorCount '= 2 do $$$AssertTrue(errorCount '= 2, "appends reporter errors.")
  
  for i=1:1:$ll(..ReportStatuses) {
    // Skip reports that couldn't be added. We only need to know about reporters ready to call the Report method.
    // Even if the Report method fails itself.
    if $data(^||Frontier.UnitTest.Spy("Report", ..MockIds(i))) {
      set matchInstance = (^||Frontier.UnitTest.Spy("Report", ..MockIds(i)) '= "")
      if 'matchInstance return $$$AssertTrue(matchInstance, "Report received context.")
    }
  }
}

}

