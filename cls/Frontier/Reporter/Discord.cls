/// This reporter can be used to send a message using a bot to Discord.
/// 
/// It must be feed with at least two parameters:
/// 
/// webhookId - 18 digit code.
/// token - An alphanumeric string.
/// 
/// Check the example on the end see how it works.
/// 
/// It's possible to identify the application by providing a 'name'.
/// This is useful for situations where this reporter is used for several applications.
/// Its initial value is 'Default'.
/// 
/// It's also possible to filter which types of error should be reported or not with 'include' or 'exclude'.
/// 
/// Usage example:
/// 
/// set discordReporter = ##class(Frontier.Reporter.Discord).%New({
///   "name": "MyApp",
///   "webhookId": 103849505938375836,
///   "token": "a valid discord token",
///   "exclude": [($$$GeneralError)]
/// })
/// 
/// do %frontier.Reporter.Manager.AddReporter(discordReporter)
Class Frontier.Reporter.Discord Extends Frontier.Reporter
{

Property Name As %String [ InitialExpression = "Default", Private ];

Property WebhookId As %String [ Private ];

Property Token As %String [ Private ];

Method %OnNew(configuration As %DynamicObject = {{ "include": [($$$CacheError)] }}) As %Status
{
  $$$QuitOnError(##super(configuration))
  
  if configuration.%IsDefined("name") set ..Name = configuration.name
  do ..AssertWebhookCredentials(configuration)
  return $$$OK
}

Method AssertWebhookCredentials(configuration As %DynamicObject) [ Private ]
{
  if 'configuration.%IsDefined("webhookId") {
    $$$ThrowStatus($$$ERROR($$$GeneralError, "'webhookId' was not provided."))    
  }
  
  if 'configuration.%IsDefined("token") {
    $$$ThrowStatus($$$ERROR($$$GeneralError, "'token' was not provided."))
  }
  
  set ..WebhookId = configuration.webhookId
  set ..Token = configuration.token
}

Method Report(context As Frontier.Context) As %Status
{
 
  do ##class(Frontier.Shared.Utilities).CreateSSLConfigurationIfNoneExists("Discord Webhook SSL")
  
  set http = ##class(%Net.HttpRequest).%New()
  set http.Server = "discordapp.com"
  set http.SSLConfiguration = "Discord Webhook SSL"
  set http.Https = 1  
  
  set payload = ##class(Frontier.Exception).ToDynamicObject(context.Exception)
  $$$QuitOnError(##class(Frontier.Dynamic.Serializer).SerializeToStream(.str, payload, 0, context.PropertyFormatter, context.Parameters.MAXIMUMDEPTH, 2))
  set message = str.Read()
  
  do http.InsertFormData("content", $$$FormatText("Error report received from *%1:*%7%7**Message:** %7```json%7%2%7```%7**Path:** %3.%7**Http Method:** %4.%7**Dispatch Method:** %5.%7**Arguments:** %6%7**Class:** %8%7%7", ..Name, message, context.RequestURL, context.Request.Method, context.Method, $$SerializeArguments(), $c(10), context.ClassName))
  do http.Post($$$FormatText("api/webhooks/%1/%2", ..WebhookId, ..Token))
  
  return $$$OK
  
SerializeArguments()
  set list = ""
  
  for i=1:1:context.ArgumentValues {
    set value = context.ArgumentValues(i)
    if $isobject(value) {
      if value.%Extends("%Persistent") { set value = value.%Id() }
      elseif value.%Extends("%DynamicAbstractObject") { set value = "<payload>" }
    }
    set $list(list, *+1) = value
  }
  return "["_$lts(list, ", ")_"]"
}

}

