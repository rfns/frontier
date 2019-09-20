Class Frontier.Shared.Utilities [ Abstract ]
{

ClassMethod RandomString(size, lowerCase As %Boolean = 0, extras = "") As %String
{
  set key = ""
  set alpha = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
  if lowerCase = 1 set alpha = alpha_$$$lcase(alpha)
  if extras '= "" set alpha = alpha_extras
  
  while $length(key) < size {
    set next = $select($random(2) = 1 : $extract(alpha, $random($length(alpha))), 1: $random(9))
    set key = key_next
  }
  quit key
}

ClassMethod SanitizeFilename(fileName) As %String
{
  if fileName [ "/" set fileName = $piece(fileName, "/", *)
  if fileName [ "\" set fileName = $piece(fileName, "\", *)
  
  set fileName = $translate(fileName, "àáÁÀÂâÃÁÂÃãèéÉÈêÊÉìíÍÌÎîòóÓÒÔôÕÓÔõùúÚÙÛûÇçÖöÜüÑ ", "aaAAAaAAAAaeeEEeEEiiIIIiooOOOOOoOouuUUUuCcOoUuN-")
  return $zstrip(fileName, "*E'N'A", "", "_-@.")
}

ClassMethod ReplacePlaceholders(definitions As %DynamicObject) As %String
{
  set text = definitions.text
    
  set it = definitions.placeholders.%GetIterator()
  while it.%GetNext(.key, .value) { set text = $replace(text, key, value) }  
  
  return text
}

ClassMethod DeepExtend(sources... As %DynamicObject) As %DynamicObject
{
  
  #dim result As %DynamicObject
    
  set result = {}    
  
  for i=1:1:sources {
    set iterator = sources(i).%GetIterator()
    while iterator.%GetNext(.property, .value) {
      set target = $property(result, property)
      if $isobject(value) && value.%IsA("%DynamicObject") && $isobject(target) {
        set isSameSize = (target.%Size() = value.%Size())
        set hasSameProperty = $property(target, property) = $property(value, property)
        if '(isSameSize && hasSameProperty) {
          set $property(result, property) = ..DeepExtend(target, value)
        }
      } elseif 'result.%IsDefined(property) {
        set $property(result, property) = value
      }      
    }
  }
  return result
}

ClassMethod SafeClassMethodCall(expression As %String, args... As %String) As %Status
{
  set sc = $$$OK
  if expression = "" return sc
  
  set class = $piece(expression, ":")
  set method = $piece(expression, ":", 2)
  try {
    set sc = $classmethod(class, method, args...)
  } catch ex {
    set sc = ex.AsStatus()
  }
  return sc
}

ClassMethod SafeMethodCallAndReturn(sc As %Status = {$$$OK}, instance As %RegisteredObject, method As %String, args...)
{
  set ret = ""
  
  try {
    set ret = $method(instance, method, args...)
    if $extract(ret, 1, 2) = "0 " && $lv($p(ret, " ", 2)) {
      set errcode = $$$GETERRORCODE(ret)
      if errcode '= "" {
        set sc = ret
        set ret = ""
      }
    }
  } catch ex {
    set sc = ex.AsStatus()
  }
  return ret
}

ClassMethod URLBase64Encode(value As %String) As %String
{
  return $translate($System.Encryption.Base64Encode(value, 1), "+/=", "-_")
}

ClassMethod URLBase64Decode(value As %String) As %String
{
  return $System.Encryption.Base64Decode($translate(value, "-_", "+/"))
}

ClassMethod CallAndCapture(object, method As %String, Output str As %Stream.GlobalCharacter = "", args... As %String) As %Status [ ProcedureBlock = 0 ]
{
  new oldMnemonic, alreadyRedirected, sc
  
  set sc = $$$OK
  set isRedirected = 0  
  
  set str = ##class(%Stream.GlobalCharacter).%New()
  set alreadyRedirected = ##class(%Device).ReDirectIO()
  set oldMnemonic = ##class(%Device).GetMnemonicRoutine()
  set initIO = $io  
  
  try {   
    use $io::("^"_$zname)    
    do ##class(%Device).ReDirectIO(1)
    if $isobject(object) set sc = $method(object, method, args...)
    else  set class = object set sc = $classmethod(class, method, args...)
    do str.Rewind()
  } catch ex {
    set str = ""
    set sc = ex.AsStatus()
  }     
  
  if oldMnemonic '= "" {
    use initIO::("^"_oldMnemonic)
  } else {
    use oldMnemonic
  }
  
  do ##class(%Device).ReDirectIO(alreadyRedirected)
      
  return sc
  
wstr(s) Do str.Write(s) Quit
wchr(a) Do str.Write($char(a)) Quit
wnl Do str.Write($char(13,10)) Quit
wff Do str.Write($char(13,10,13,10)) Quit
wtab(n) Do str.Write($c(9)) Quit
rstr(len,time) Quit ""
rchr(time) Quit ""
}

ClassMethod CreateSSLConfigurationIfNoneExists(name As %String) [ Private ]
{
   new $namespace
   set $namespace = "%SYS"
      
   do ##class(Security.SSLConfigs).Get("Discord Webhook SSL", .p)
   if $data(p) quit   
   
   set p("CipherList")="ALL:!aNULL:!eNULL:!EXP:!SSLv2"
   set p("CAFile")=""
   set p("CAPath")=""
   set p("CRLFile")=""
   set p("CertificateFile")=""
   set p("CipherList")="ALL:!aNULL:!eNULL:!EXP:!SSLv2"
   set p("Description")=""
   set p("Enabled")=1
   set p("PrivateKeyFile")=""
   set p("PrivateKeyPassword")=""
   set p("PrivateKeyType")=2
   set p("Protocols")=24
   set p("SNIName")=""
   set p("Type")=0
   set p("VerifyDepth")=9
   set p("VerifyPeer")=0
   
   do ##class(Security.SSLConfigs).Create(name, .p)
}

}

