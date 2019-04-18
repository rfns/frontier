Include frontier

/// Provides the capability of handling file payloads. form-data/multipart and single file are supported.
/// This class cannot be used without the %frontier context variable.
Class Frontier.Files.Uploader Extends %RegisteredObject
{

Parameter MINFILENAMELENGTHMSG = "File name :FILE_NAME must have at least :SIZE characters.";

Parameter MAXFILENAMELENGTHMSG = "File name :FILE_NAME cannot exceed :SIZE characters.";

Parameter MAXFILESIZEMSG = "File :FILE_NAME (:SIZE bytes) exceeded the max allowed size of :VALUE bytes.";

Parameter EXTENSIONNOTALLOWEDMSG = "File extension :EXTENSION is not allowed.";

Property Context As Frontier.Context [ Private ];

Property OnItemUploadSuccess As %String [ Private ];

Property OnItemUploadError As %String [ Private ];

Property Filter As %DynamicObject [ Private ];

Method %OnNew(context As Frontier.Context) As %Status
{
  set ..Context = context
  return $$$OK
}

Method HandleRequest(settings As %DynamicObject) As %Status [ Internal ]
{

  #define DestinationAsObject(%d) if '$isobject(%d) set %d = { "path": (%d) }
  set sc = $$$OK
  set validMethods = $lb("POST", "PUT")

  if $lf(validMethods, ..Context.Request.Method) < 1 {
    return $$$ERROR($$$GeneralError, "Must use POST or PUT to handle uploads.")
  }

  if '$isobject(settings.filters) set settings.filters = {}
  if '$isobject(settings.hooks) set settings.hooks = {}

  set ..OnItemUploadSuccess = settings.hooks.onItemUploadSuccess

  set result = []

  $$$QuitOnError($$AssertContentTypeMatch(settings.%IsDefined("destinations")))

  if $isobject(settings.destinations) {
    set it = settings.destinations.%GetIterator()
    set isSingle = 1

    while it.%GetNext(.key, .destination) {
      $$$DestinationAsObject(destination)
      if destination.slots = "" || (destination.slots < 0) set destination.slots = 1

      set ssc = ..HandleMultipart(key, destination, settings.filters, .filePath)

      if $$$ISOK(ssc) set ssc = $$$EMBEDSC(ssc, ..CallHook(settings.hooks.onItemUploadSuccess, key, destination, filePath))
      else  set ssc = $$$EMBEDSC(ssc, ..CallHook(settings.hooks.onItemUploadError, key, destination, filePath, ssc))

      set sc = $$$ADDSC(sc, ssc)
      do result.%Push({ "sc": (ssc), "key": (key), "destination": (destination), "filePath": (filePath) })
    }
  } elseif settings.destination '= "" {
    set sc = $$$ADDSC(sc, ..HandleSingleFile(settings.destination, settings.filters, .filePath))
    do result.%Push({ "sc": (sc), "destination": (settings.destination), "filePath": (filePath) })

    if $$$ISERR(sc) {
      set sc = $$$ADDSC(sc, ..CallHook(settings.hooks.onItemUploadError, "", settings.destination, filePath, sc))
    }
  } else {
    return $$$ERROR($$$GeneralError, "No valid uploader configuration was found.")
  }

  set sc = $$$ADDSC(sc, ..CallHook(settings.hooks.onComplete, result))
  return sc

AssertContentTypeMatch(multi)
  set error = $$$ERROR($$$GeneralError, "Wrong request headers.")

  set receivedMulti = (..Context.Request.ContentType [ "multipart/form-data")
  set receivedSingle = (..Context.Request.ContentType '[ "multipart/form-data")

  if (multi && (receivedMulti = 1)) || ('multi && receivedSingle = 1) {
    return $$$OK
  }

  do ..Context.Status("400 Bad Request")
  return error
}

Method HandleMultipart(key As %String, destination As %DynamicObject, filters As %DynamicObject, Output filePath As %String = "") As %Status [ Private ]
{
  #define AddErrorAndContinue(%error) set sc = $$$ADDSC(sc, %error)  continue

  set sc = $$$OK
  set mimeDataCount = ..Context.Request.CountMimeData(key)

  // Prevents the request from bypassing the limit otherwise takes the count as limit
  // if the request provided is lesser MIME entries than the expected.
  set limit = $select(destination.slots > mimeDataCount : mimeDataCount, 1: destination.slots)

  if '$isobject(destination.filters) set destination.filters = {}
  set filters = ##class(Frontier.Shared.Utilities).DeepExtend(destination.filters, filters)

  for i=1:1:limit {
    set mimeData = ..Context.Request.GetMimeData(key, "", i)

    if '$isobject(mimeData) {
      if destination.optional = 1 return $$$OK
      if limit > 1 $$$AddErrorAndContinue($$$ERROR($$$GeneralError, $$$FormatText("No data for '%1' at index %2.", key, i)))
      $$$AddErrorAndContinue($$$ERROR($$$GeneralError, $$$FormatText("No data for '%1'.", key)))
    }

    set fileName = ##class(Frontier.Shared.Utilities).SanitizeFilename(mimeData.FileName)
    set extension = $piece(fileName, ".", *)

    set filePath = ..MakeFilePath(key, i, fileName, destination.path, extension)

    if '..MatchFilters(filters, fileName, extension, mimeData, .fsc) $$$AddErrorAndContinue(fsc)
    $$$AddErrorAndContinue(..StoreToFS(key, i, destination.path, filePath, mimeData))
 }
 return sc
}

Method HandleSingleFile(destination As %String, filters As %DynamicObject, Output filePath = "") As %Status [ Private ]
{
  set stream = ..Context.Request.Content

 if '$isobject(stream) {
   return $$$ERROR($$$GeneralError, "No file was sent.")
 }

 set fileName = ##class(%File).GetFilename(destination)
 set extension = $piece(fileName, ".", *)

 set filePath = ..MakeFilePath("", fileName, "", destination, extension)

 if '..MatchFilters(filters, fileName, extension, stream, .sc) return sc

 return ..StoreToFS("", "", destination, filePath, stream)
}

Method MakeFilePath(key As %String, index As %String, fileName As %String, destination As %String, extension As %String = "") As %Status [ Private ]
{

  set filePath = ##class(Frontier.Shared.Utilities).ReplacePlaceholders({
    "text": (destination),
    "placeholders": {
      ":RANDOM": (##class(Frontier.Shared.Utilities).RandomString(10)),
      ":FILE_NAME": ($piece(fileName, ".", *-1)),
      ":KEY": (key),
      ":INDEX": (index),
      ":EXTENSION": ($case(extension, "": "", : "."_extension)),
      ":NAMESPACE": ($namespace),
      ":USER": ($username)
    }
  })
  return ##class(%File).NormalizeFilename(filePath)
}

Method StoreToFS(key As %String, index As %String, destination As %String, filePath As %String, mimeData As %Stream.Object) As %Status [ Private ]
{
  set sc = $$$OK

  try {
    // Sometimes GetDirectory cannot find the directory.
    // So we use $piece instead.
    // set path = ##class(%File).GetDirectory(filePath)
    set path = $piece(filePath, $$$OSSlash, 1, *-1)
    set created = ##class(%File).CreateDirectoryChain(path, .oserr)

    if 'created {
      return $$$ERROR($$$GeneralError, "Cannot prepare file destination: System reported code "_oserr_".")
    }

    if mimeData.IsCharacter() {
      set file = ##class(%Stream.FileCharacter).%New()
    } else {
      set file = ##class(%Stream.FileBinary).%New()
    }

    $$$ThrowOnError(file.LinkToFile(filePath))
    $$$ThrowOnError(file.CopyFromAndSave(mimeData))
    $$$ThrowOnError(..CallHook(..OnItemUploadSuccess, key, index, destination, filePath))
  } catch ex {
    set sc = ex.AsStatus()
  }
  return sc
}

ClassMethod CallHook(hook As %String = "", args...) As %Status [ Private ]
{
  if hook = "" return $$$OK

  set classname = $piece(hook, ":", 1)
  set method = $piece(hook, ":", 2)
  try {
    return $classmethod(classname, method, args...)
  } catch ex {
    return ex.AsStatus()
  }
  return $$$OK
}

ClassMethod MatchFilters(filters As %DynamicObject, fileName As %String, extension As %String, mimeData As %Stream.Object, Output sc As %Status) As %Boolean [ Private ]
{

  set sc = $$$OK
  set nameLength = $length(fileName)

  if filters.%IsDefined("minNameLength") {
    do BuildFilter(filters.minNameLength, ..#MINFILENAMELENGTHMSG, .minNameLength)
    if nameLength < minNameLength.value {
      if filters.verbose = 1 set sc = $$$ERROR($$$GeneralError, minNameLength.message)
      return 0
    }
  }

  if filters.%IsDefined("maxNameLength") {
    do BuildFilter(filters.maxNameLength, ..#MAXFILENAMELENGTHMSG, .maxNameLength)
    if nameLength > maxNameLength.value {
      if filters.verbose = 1 set sc = $$$ERROR($$$GeneralError, maxNameLength.message)
      return 0
    }
  }

  if filters.%IsDefined("maxFileSize") {
    do BuildFilter(filters.maxFileSize, ..#MAXFILESIZEMSG, .maxFileSize)
    if mimeData.Size > maxFileSize.value {
      if filters.verbose = 1 set sc = $$$ERROR($$$GeneralError, maxFileSize.message)
      return 0
    }
  }

  if filters.%IsDefined("extensions") {
    do BuildFilter(filters.extensions, ..#EXTENSIONNOTALLOWEDMSG, .extensions)
    set match = 0
    for i=0:1:extensions.value.%Size() - 1 {
      if extensions.value.%Get(i) = extension {
        set match = 1
        quit
      }
    }
    if 'match {
      if filters.verbose = 1 set sc = $$$ERROR($$$GeneralError, extensions.message)
      return 0
    }
  }

  return 1

BuildFilter(filter, templateMsg, normalizedFilter)
  if '$isobject(filter) || 'filter.%IsA("%DynamicObject") {
    set filter = {
      "value": (filter),
      "errorTemplate": (templateMsg)
    }
  }

  set placeholders = {
    ":FILE_NAME": (fileName),
    ":VALUE": (filter.value),
    ":SIZE": (mimeData.Size),
    ":EXTENSION": (extension)
  }

  set normalizedFilter = {
    "value": (filter.value),
    "message": (
      ##class(Frontier.Shared.Utilities).ReplacePlaceholders({
        "text": (filter.errorTemplate),
        "placeholders": (placeholders)
      })
    )
  }

  quit
}

}
