Class Frontier.UnitTest.Reporter.Mock Extends Frontier.Reporter
{

Property ExpectedSetupStatus As %Status;

Property ExpectedReportStatus As %Status;

Method Setup(context As Frontier.Context) As %Status
{
  set ^||Frontier.UnitTest.Spy("Setup", $this) = context
  return ..ExpectedSetupStatus
}

Method Report(context As Frontier.Context) As %Status
{
  set ^||Frontier.UnitTest.Spy("Report", $this) = context
  return ..ExpectedReportStatus
}

}

