Class Frontier.UnitTest.Reporter.Email Extends Frontier.Reporter.Email
{

Method SetupAccount() As %Status
{
  // If you want to test this reporter you need to configure the following properties.
  set ..SMTPServerLocation = "smtp.youremailhost.com"
  set ..SMTPServerPort = 25 // Your SMTP server port
  set ..SenderEmail = "sender_email@email.com"
  set ..SenderPassword = "sender_password"
  set ..DestinationEmail = "destination@email.com"
  set ..TemplateLocation = "/InterSystems/Cache/CSP/user/email-template.html"
  set ..SSLConfiguration = "SSL Configuration name"
  set ..UseSTARTTLS = 1 // 1, "" or 0
  return $$$OK
}

}

