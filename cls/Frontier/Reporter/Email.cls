/// This class demonstrates how to create a reporter that sends an e-mail when a request error occurs.
/// If you want to see it working, create another class extending from this one and fill
/// the fields that aren't private, or you can instantiate it and change it's values manually.
Class Frontier.Reporter.Email Extends Frontier.Reporter
{

Property Mail As %Net.MailMessage [ Private ];

Property SMTPServer As %Net.SMTP [ Private ];

Property Authenticator As %Net.Authenticator [ Private ];

Property SMTPServerLocation As %String [ InitialExpression = "your smtp server" ];

Property SMTPServerPort As %Integer [ InitialExpression = 25 ];

Property SenderEmail As %String [ InitialExpression = "youremail@host.com" ];

Property SenderPassword As %String [ InitialExpression = "yourpasssword" ];

Property DestinationEmail As %String [ InitialExpression = "dest@host.com" ];

Property TemplateLocation As %String [ InitialExpression = "/the/email/template.html" ];

Property SSLConfiguration As %String;

Property UseSTARTTLS As %Boolean;

Method %OnNew() As %Status
{
  set ..SMTPServer = ##class(%Net.SMTP).%New()
  set ..Authenticator = ##class(%Net.Authenticator).%New()
  set ..Mail = ##class(%Net.MailMessage).%New()
  set ..Mail.IsHTML = 1
  set ..SMTPServer.authenticator = ..Authenticator
  $$$QuitOnError(..SetupAccount())
  return $$$OK
}

Method Setup(context As Frontier.Context) As %Status [ Internal ]
{
  $$$QuitOnError(..SetupSMTPServer())
  $$$QuitOnError(..SetupAuthenticator())
  $$$QuitOnError(..SetupMail(context))
  return $$$OK
}

Method SetupSMTPServer() As %Status
{
  set ..SMTPServer.smtpserver = ..SMTPServerLocation
  set ..SMTPServer.port = ..SMTPServerPort
  set ..SMTPServer.SSLConfiguration = ..SSLConfiguration
  set ..SMTPServer.UseSTARTTLS = ..UseSTARTTLS
  return $$$OK
}

Method SetupAuthenticator() As %Status
{
  set ..Authenticator.UserName = ..SenderEmail
  set ..Authenticator.Password = ..SenderPassword
  return $$$OK
}

Method SetupMail(context As Frontier.Context) As %Status
{
  set ..Mail.From = ..SenderEmail
  do ..Mail.To.Insert(..DestinationEmail)      
  return $$$OK
}

Method Report(context As Frontier.Context) As %Status
{
  set ..Mail.Subject = $$$FormatText("[Error Report] - %1", $System.Status.GetErrorText(context.Error))
  $$$QuitOnError(..Mail.TextData.Write(..ReplacePlaceholders(context)))
  return ..SMTPServer.Send(..Mail)
}

Method ReplacePlaceholders(context As Frontier.Context) As %String [ Private ]
{
  set method = ##class(Frontier.Method).%New(context.ClassName, context.Method)  
  set template = ##class(%Stream.FileCharacter).%New()
  
  $$$QuitOnError(template.LinkToFile(..TemplateLocation))  
  
  set formatParameters = 6
  set formatParameters(1) = $System.Status.GetErrorText(context.Error)
  set formatParameters(2) = context.RequestURL
  set formatParameters(3) = context.ClassName
  set formatParameters(4) = context.Method
  if context.ArgumentValues '= 0  {
    for i=1:1:context.ArgumentValues {
      set methodArgument = method.MethodArguments.GetAt(i)
      set argumentName = methodArgument.Name
      set argumentValue = context.ArgumentValues(i)
      set argumentType = methodArgument.Type
      if argumentType = "" set argumentType = "<i>n/a</i>"
      set formatParameters(5) = $$$FormatText("%1 %2:%3: %4<br>", $get(formatParameters(5)), argumentName, argumentType, argumentValue)
    }
  } else {
    set formatParameters(5) = "<i>none</i>"
  }
  set formatParameters(6) = $replace(context.Stack, $c(10), "<br>")
  return $$$FormatText(template.Read(), formatParameters...)
}

Method SetupAccount() As %Status
{
  return $$$OK
}

}

