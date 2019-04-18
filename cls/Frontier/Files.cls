Include (%cspBuild, frontier)

Class Frontier.Files Extends %RegisteredObject
{

Property Context As Frontier.Context [ Private ];

Property Uploader As Frontier.Files.Uploader [ Private ];

Method %OnNew(context As Frontier.Context) As %Status
{
  set ..Context = context
  set ..Uploader = ##class(Frontier.Files.Uploader).%New(context)
  return $$$OK
}

Method Upload(settings As %DynamicObject) As %String
{
  do ..Context.Raw()
  $$$ThrowOnError(..Uploader.HandleRequest(settings))
  return ""
}

Method ServeFrom(root As %String) As %Stream.Object
{
  return ..Serve({
    "root": (root),
    "etag": "weak",    
    "index": "index.html index.htm",
    "extensions": {
      "md": {
        "disposition": "inline",
        "mimeType": "text/markdown",
        "charset": "utf-8",
        "binary": false
      }
    }
  })
}

Method ServeFile(absoluteFilePath As %String, charset As %String = "utf-8") As %Stream.Object
{
  return ..Serve({
    "file": (absoluteFilePath),
    "etag": "weak",
    "charset": (charset),
    "extensions": {
      "md": {
        "disposition": "inline",
        "mimeType": "text/markdown",
        "binary": false
      }
    }
  })
}

Method Serve(config As %DynamicObject) As %Status
{
       
  // Make sure to stream the file in plain text.
  do ..Context.Raw()
  
  if config.%IsDefined("file") {
    // We are only serving a file that we define which is it.
    set normalizedAbsoluteFilePath = ##class(%File).NormalizeFilename(config.file)
    set fileExists = ##class(%File).Exists(normalizedAbsoluteFilePath)
    set requestDirectory = normalizedAbsoluteFilePath
  } else {
    // We are serving a directory.
    set directory = config.root
    set indexAs = config.index  
    
    // Checks if a path to a file has been provided. 
    set virtualPath = $get(..Context.Matches(1))
    set requestDirectory = ""  
    
    // Otherwise fallback to possible indexAs files.
    if virtualPath = "" set virtualPath = indexAs
    set fileExists = 0
    
    // Attempted to access a path outside the root.
    if virtualPath [ ".." {
      return ..Context.ThrowException("File does not exist.", "404 Not Found")
    }
    
    for i=1:1:$length(virtualPath, " ") {
      set virtualFileName = $piece(virtualPath, " ", i)
      set requestDirectory = ##class(%File).NormalizeFilename(virtualFileName, directory)
      if ##class(%File).Exists(requestDirectory) set fileExists = 1 quit
    }       
  }
  
  if 'fileExists {
    return ..Context.ThrowException("File does not exist.", "404 Not Found")
  } 
  
  $$$ThrowOnError(..GetFileServerConfig(.appConfig))  
  
  set fileName = $piece(requestDirectory, $$$OSSlash, *)
  set extension = $piece(fileName, ".", *)
  
  set contentConfig = ..GetContentConfiguration(extension, config)
  set charset = contentConfig.charset
  
  if contentConfig.binary = 1 {
    // Prevents content corruption.
    set ..Context.Response.NoCharSetConvert = 1
    set ..Context.Response.CharSet = ""
    set stream = ##class(%Stream.FileBinary).%New()      
  } else {
    set stream = ##class(%Stream.FileCharacter).%New()
    if charset '= "" {
      set stream.TranslateTable = $$MapCharset^%SYS.NLS(charset)
      set ..Context.Response.CharSet = contentConfig.charset
    }
  } 
    
  $$$ThrowOnError(stream.LinkToFile(requestDirectory))  
  
  set ..Context.Response.ContentType = contentConfig.mimeType
  set ..Context.Response.ContentLength = stream.Size  
  
  set extensionMatch = 0
  
  for i=1:1:contentConfig.cache.ignore.%Size() - 1 {
    if contentConfig.cache.ignore.%Get(i) = extension {
      set extensionMatch = 1
      quit
    }
  }  
  
  if 'extensionMatch {
    do ..Context.Response.SetHeader("ETag", ..MakeETag(stream, config.etag))
    do ..Context.Response.SetHeader("Cache-Control", contentConfig.cache.configuration)
  }
      
  if ..IsCacheHit(stream, config.etag) {
    do ..Context.Status("304 Not Modified")  
    return ""
  } 
  
  do ..Context.Response.SetHeader("Last-Modified", ##class(%CSP.StreamServer).ToHTTPDate(stream.LastModified))  
  do ..Context.Response.SetHeader("Vary", "Accept-Encoding")
  
  if contentConfig.disposition = "attachment" {
    do ..Context.Response.SetHeader("Content-Disposition", $$$FormatText("%1; filename=%2", contentConfig.disposition, fileName))
  }  
  return stream
}

Method GetContentConfiguration(extension As %String, config As %DynamicObject) As %DynamicObject [ Private ]
{
  
  set defaultCharset = config.charset
  set extensionConfig = $property(config.extensions, extension)
  
  do ##class(%CSP.StreamServer).FileClassify(extension, .contentType, .bin, .charset)  
  if charset = "" set charset = defaultCharset
  if charset = "" set charset = "utf-8"
  
  if '$isobject(extensionConfig) set extensionConfig = {}
  if '$isobject(config.cache) set config.cache = {}
  
  return ##class(Frontier.Shared.Utilities).DeepExtend(
    extensionConfig, 
    { "cache": (config.cache) },
    { "cache": { "configuration": "max-age=2628000, public", "ignore": [] } },
    { "binary": (bin), "mimeType": (contentType), "charset": (charset) },
    { "disposition": "inline" } 
  )
}

Method MakeETag(stream As %Stream.Object, validator As %String) As %String [ Private ]
{
  if validator = "strong" {
    set hash = ##class(%File).SHA1Hash(stream.Filename)
    return $c(34)_$zcvt(##class(%xsd.hexBinary).LogicalToXSD(hash), "l")_$c(34)
  }
  
  set hash = $System.Encryption.SHA1Hash(stream.Filename_stream.LastModified_stream.Size)
  return "W/"_$c(34)_$zcvt(##class(%xsd.hexBinary).LogicalToXSD(hash), "l")_$c(34)
}

Method IsCacheHit(stream As %Stream.Object, validator As %String) As %Boolean [ Private ]
{
  set ifNoneMatch = ..Context.Request.GetCgiEnv("HTTP_IF_NONE_MATCH")  
  if ifNoneMatch '= "" && (ifNoneMatch = ..MakeETag(stream, validator)) return 1
  return 0
}

Method GetFileServerConfig(Output config As %DynamicObject = {{}}) As %Status [ Private ]
{
  new $namespace
  set $namespace = "%SYS"
  set appPath = $extract(..Context.Request.Application, 1, *-1)
  
  set application = ##class(Security.Applications).%OpenId(appPath)
  if '$isobject(application) return $$$ERROR($$$GeneralError, "Application not found.")
  if application.ServeFiles '= 1 return $$$ERROR($$$GeneralError, "The application is not configured to serve files.")
  
  set config.ServeFilesTimeout = application.ServeFilesTimeout
  
  return $$$OK
}

}

