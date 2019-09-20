Include (%occErrors, frontier)

/// This class is used to transform a %DynamicAbstractObject into a full-featured %RegisteredObject, which also includes %Persistent-inherited class instances.
/// It's used internally by Frontier, but can be used manually as well by using the method Unmarshal, which takes a class name and the dynamic instance.
Class Frontier.Dynamic.Unmarshaller Extends %RegisteredObject
{

/// An integer indicating how deep in the dynamic object the marshalling is.
Property Depth As %Integer [ InitialExpression = 0, Private ];

/// An instance of the property formatter that was provided in the router's OnSetup method.
Property Formatter As Frontier.PropertyFormatter [ Private ];

/// A list of the already used definitions, which can prevent roundtrips.
Property CachedDefinitions As %String [ MultiDimensional ];

/// A string indicating the current visited path, that is used to report errors.
Property Path As %String [ InitialExpression = "<root>", Private ];

/// If set to 1 will return an error if the dynamic object doesn't fully comply with the provided class definition properties.
/// Otherwise the unknown properties will be skipped.
Property Strict As %Boolean [ InitialExpression = 0 ];

Method %OnNew(formatter As Frontier.PropertyFormatter = "", strict As %Boolean = 0) As %Status [ Private ]
{
  set ..Formatter = formatter
  set ..Strict = strict
  return $$$OK
}

/// Creates a full-featured instance of the 'className', using the 'source' to populate its properties.
/// If $$$OK the 'result' is populated with the generated instance.
ClassMethod Unmarshal(className As %String, source As %DynamicAbstractObject, Output result As %RegisteredObject = "", formatter As Frontier.PropertyFormatter = "", strict As %Boolean = 0) As %Status
{
  set unmarshaller = ..%New(formatter, strict)
  return unmarshaller.DetermineTypeAndUnmarshal(className, source, .result)
}

Method DetermineTypeAndUnmarshal(className As %String, dynamicObject As %DynamicAbstractObject, Output registeredObject As %RegisteredObject = "") As %Status [ Private ]
{
  set sc = $$$OK

  if '##class(%Dictionary.CompiledClass).%ExistsId(className) {
    return $$$ERROR($$$GeneralError, "Unable to determine which class is '"_className_"'.")
  }

  if $isobject(dynamicObject) {
    set dynamicType = $classname(dynamicObject)
    set isCollection = ##class(Frontier.Types).IsCollection(className) || ##class(Frontier.Types).IsDynamicArray(className)

    if ##class(Frontier.Types).IsDynamicArray(dynamicType) {
      set sc = ..UnmarshalCollection(dynamicObject, .registeredObject, className)
    } elseif 'isCollection && ##class(Frontier.Types).IsDynamicObject(dynamicType) && ##class(Frontier.Types).IsInstantiable(className) {
      set sc = ..UnmarshalObject(className, dynamicObject, .registeredObject)
    }

    if $$$ISERR(sc) {
      set registeredObject = ""
      return $$$EMBEDSC($$$ERROR($$$GeneralError, $$$FormatText("Failed to unmarshal payload to type '%1'. Path: %2", className, ..Path)), sc)
    }

    return sc
  }
  return $$$ERROR($$$GeneralError, "Cannot unmarshal data types, expected a dynamic object that imitates an instance of "_className_". But received value: "_dynamicObject_ " instead.")
}

ClassMethod UnmarshalUsingObject(object As %RegisteredObject, dynamicObject As %DynamicAbstractObject, Output registeredObject As %RegisteredObject = "", propertyFormatter As Frontier.PropertyFormatter) As %Status
{
  set dynamicObject."__id__" = object.%Id()
  return ..Unmarshal($classname(object), dynamicObject, .registeredObject, propertyFormatter)
}

Method InitializeObject(className As %String, dynamicObject As %DynamicAbstractObject, Output initialObject As %RegisteredObject = "") As %Status [ Private ]
{

  if '$isobject(dynamicObject) || ($isobject(dynamicObject) && 'dynamicObject.%IsA("%DynamicObject")) {
    return $$$ERROR($$$GeneralError, "An instance of %DynamicObject was not provided.")
  }

  if dynamicObject.%IsDefined("__id__") {
    set initialObject = $System.OBJ.OpenId(className, dynamicObject."__id__")
    if '$isobject(initialObject) return $$$ERROR($$$GeneralError, "Invalid id for '"_className_"'.")
  } else {
    set id = ..AtemptToFindIdUsingIndices(className, dynamicObject)
    if id '= "" {
      set dynamicObject."__id__" = id
      return ..InitializeObject(className, dynamicObject, .initialObject)
    }
    set initialObject = $System.OBJ.New(className)
  }
  return $$$OK
}

Method UpdatePath(pathComponent As %String = "") [ Private ]
{
  if pathComponent '="" set $piece(i%Path, ".", *+1) = pathComponent
  else  set ..Path = $piece(..Path, ".", 1, *-1)
}

Method AtemptToFindIdUsingIndices(className As %String, dynamicObject As %DynamicObject) As %String [ Private ]
{
  set idMembers = ""
  set id = ""

  set definition = ..GetAndCacheDefinition(className)
  for i=1:1:definition.Indices.Count() {
    set index = definition.Indices.GetAt(i)
    if index.IdKey = 1 {
      set idMembers = $lfs(index.Properties)
      quit
    }
  }

  if idMembers '= "" {
    for i=1:1:$listlength(idMembers) {
      set idProperty = $listget(idMembers, i)
      set value = dynamicObject.%Get(idProperty)
      if value '= "" set $piece(id, "||", *+1) = value
    }
  }
  if $length(id, "||") = $listlength(idMembers) return id
  return ""
}

Method PopulateFormatter(className As %String) As %Status [ Private ]
{
  set definition = ..GetAndCacheDefinition(className)
  if '$isobject(definition) return $$$ERROR($$$ClassDoesNotExist, className)

  if $isobject(..Formatter) {
    do ..Formatter.FormatAllProperties(definition.Properties, ..Depth)
  }

  return $$$OK
}

Method GetPropertyId(className As %String, key As %String) As %String [ Private ]
{
  set propertyId = className_"||"

  if $isobject(..Formatter) {
    set propertyId = propertyId_..Formatter.Normalize(key, ..Depth)
  } else {
    set propertyId = propertyId_key
  }

  return propertyId
}

Method NextQualifiedProperty(className As %String, iterator As %Iterator.AbstractIterator, Output key As %String = "", Output value = "", Output property As %Dictionary.CompiledProperty, iterationError As %Status = {$$$OK}) As %Boolean [ Private ]
{

  #define IsQualifiedProperty(%p) '(%p.Private || %p.Calculated || ($extract(%p.Name) = "%"))

  while 1 {
    set iterationError = $$$OK
    set hasNext = iterator.%GetNext(.candidateKey, .candidateValue)
    if 'hasNext return 0

    if candidateKey = "__id__" continue

    set propertyId = ..GetPropertyId(className, candidateKey)
    set property = ..GetAndCacheDefinition(propertyId)

    if '$isobject(property) {
      if '..Strict continue
      do ..UpdatePath(candidateKey)
      set iterationError = $$$ERROR($$$GeneralError, $$$FormatText("Candidate field '%1' is not a property from '%2'", candidateKey, className))
      return 0
    }

    if $$$IsQualifiedProperty(property) {
      set key = candidateKey
      set value = candidateValue
      return 1
    } else {
      continue
    }
  }
}

Method GetInputType(value As %String, property As %Dictionary.CompiledProperty) As %String [ Private ]
{
  if '$isobject(value) && ##class(Frontier.Types).IsDataType(property.Type) {
    return "datatype"
  } elseif $isobject(value) && value.%IsA("%DynamicObject") {
    return "dynamic"
  } elseif property.Collection '= "" {
    return "collection"
  } elseif ##class(Frontier.Types).IsPersistent(property.Type) {
    return "persistent"
  } elseif ##class(Frontier.Types).IsSerial(property.Type) {
    return "serial"
  } elseif ##class(Frontier.Types).IsStream(property.Type) {
    return "stream"
  }
  return ""
}

ClassMethod WrapString(type As %String, value, Output stream As %Stream.Object = "") As %Status [ Private ]
{
  set stream = $System.OBJ.New(type)
  $$$AssertClassExists(stream)

  if $isobject(value) && value.%Extends("%Stream.Object") {
    // This is never true until ISC provides native support for Stream property when using dynamic instances.
    do stream.CopyFrom(value)
  } else {
    do stream.Write(value)
  }

  return $$$OK
}

ClassMethod GetSerialObject(type As %String, value, Output serial As %SerialObject = "") As %Status [ Private ]
{

  set serial = $classmethod(type, "%Open", $lb(value, type))
  return $$$OK
}

Method ResolvePrimitive(type As %String, name As %String, object As %RegisteredObject, value, Output result As %String = "") As %Status [ Private ]
{
  #define BoolToBin(%v) $case(%v, "true" : 1, 1: 1, : 0)
  #define DateISOString(%d) (%d?4N1"-"2N1"-"2N1"T"2N1":"2N1":"2N1"."3N1"Z" = 1)

  set sc = $$$OK
  set inputValue = value

  try {
    if value = "null" {
      set value = ""
    } elseif type = "%Library.Boolean" {
      set value = $$$BoolToBin(value)
    } elseif $$$DateISOString(value) {
      if type = "%Library.Date" { set value = $zdh($p(value,"T",1),3,,,,,,,"") }
      elseif type = "%Library.Time" { set value = $zth($p($p(value, "T", 2), ".", 1)) }
      elseif type = "%Library.TimeStamp" || (type = "%Library.DateTime") {  set value = $translate(value, "Z", "") }
    } elseif type = "%Library.TimeStamp" || (type = "%Library.DateTime") {
      set value = $translate(value, "Z", "")
    } elseif type = "%Library.Date" || (type = "%Library.Time") {
      set value = ##class(Frontier.Shared.Utilities).SafeMethodCallAndReturn(.sc, object, name_"DisplayToLogical", value)
      $$$ThrowOnError(sc)
    }

    set valid = ##class(Frontier.Shared.Utilities).SafeMethodCallAndReturn(.sc, object, name_"IsValid", value)
    $$$ThrowOnError(sc)

    set value = ##class(Frontier.Shared.Utilities).SafeMethodCallAndReturn(.sc, object, name_"Normalize", value)
    if value = "error" $$$ThrowOnError($$$ERROR($$$GeneralError, "Internal normalization error"))
    $$$ThrowOnError(sc)

    if valid = 1 set result = value
  } catch {
    set error = $$$ERROR($$$GeneralError, $$$FormatText("Validation error: Invalid primitive value for property '%1' of type '%2' in class '%3'. Value: %4", name, type, $classname(object), inputValue))
    set sc = error
  }

  return sc
}

Method GetPersistedObject(type As %String, name As %String, value, Output result As %Persistent = "") As %Status [ Private ]
{
  set result = $System.OBJ.OpenId(type, value)

  if '$isobject(result) && (value '= "") {
    return $$$ERROR($$$GeneralError, $$$FormatText("Invalid id for property '%1' from '%2'.", name, type))
  }

  return $$$OK
}

Method UnmarshalObject(className As %String, dynamicObject As %DynamicAbstractObject, Output object As %RegisteredObject = "") As %Status [ Private ]
{
  set sc = $$$OK

  $$$QuitOnError(..InitializeObject(className, dynamicObject, .object))
  $$$QuitOnError(..PopulateFormatter(className))

  set ..Depth = ..Depth + 1

  set iterator = dynamicObject.%GetIterator()

  while ..NextQualifiedProperty(className, iterator, .key, .value, .property, .sc) {
    set type = ..GetInputType(value, property)
    set result = ""

    do ..UpdatePath(key)

    if type = "dynamic" {
      set sc = ..UnmarshalObject(property.Type, value, .result)
    } elseif type = "stream" {
      set sc = ..WrapString(property.Type, value, .result)
    } elseif type = "persistent" {
      set sc = ..GetPersistedObject(property.Type, property.Name, value, .result)
    } elseif type = "serial" {
      set sc = ..GetSerialObject(property.Type, value, .result)
    } elseif type = "collection"  {
      set result = $property(object, property.Name)
      set sc = ..UnmarshalCollection(value, .result)
    } elseif type = "datatype" {
      set sc = ..ResolvePrimitive(property.Type, property.Name, object, value, .result)
    } else {
      set sc = $$$ERROR($$$GeneralError, $$$FormatText("Invalid input type for key '%1' from '%2'", key, className))
    }

    if $$$ISERR(sc) quit
    do ..UpdatePath("")
    set $property(object, property.Name) = result
  }

  set ..Depth = ..Depth - 1
  return sc
}

Method UnmarshalCollection(dynamicCollection As %DynamicAbstractObject, ByRef collection As %Collection.Super = "", className As %String = "") As %Status [ Private ]
{
  set sc = $$$OK
  set insertStrategy = "list"
  set hasChildObjects = 0
  set collectionClass = "%ListOfDataTypes"
  set firstItem = dynamicCollection.%Get(0)
  set startOffset = 0

  set collectionType = $classname(collection)

  if collectionType [ "RelationshipObject" {
    set startOffset = 1
  }

  if $isobject(firstItem) {
    set hasChildObjects = '##class(Frontier.Types).IsDataType($classname(firstItem))
  }

  if dynamicCollection.%IsA("%DynamicObject") {
    set insertStrategy = "Array"
    set collectionClass = $replace(collectionClass, "List", insertStrategy)
  }

  if hasChildObjects {
    set collectionClass = $replace(collectionClass, "OfDataTypes", "OfObjects")
  }

  // We usually have the collection instance, so we can just Clear it.
  // However when this method is called recursively (linear), then we must create the instance ourselves.
  if $isobject(collection) {
    do collection.Clear()
  } else {
    set collection = $System.OBJ.New(collectionClass)
  }

  set elementType = $case(className, "": collection.ElementType, : className)
  set iterator = dynamicCollection.%GetIterator()
  set isPersistentItem = ##class(Frontier.Types).IsPersistent(elementType)

  set ..Depth = ..Depth + 1

  while iterator.%GetNext(.key, .dynamicItem) {
    do ..UpdatePath(key)

    set isIdCandidate = '$isobject(dynamicItem) && (dynamicItem '= "")
    set itemClass = $select('isIdCandidate : $classname(dynamicItem), 1: "")

    if dynamicItem = "null" && (itemClass '= "") continue

    if isIdCandidate && isPersistentItem {
      set item = $System.OBJ.OpenId(elementType, dynamicItem)
    } elseif $isobject(dynamicItem) {
      set sc = $select(
        dynamicItem.%IsA("%DynamicObject") : ..UnmarshalObject(elementType, dynamicItem, .item),
        dynamicItem.%IsA("%DynamicArray") : ..UnmarshalCollection(dynamicItem, .item),
        1: $$$ERROR($$$GeneralError, "Cannot unmarshal items that aren't dynamic.")
      )
      if item = "" continue
    } else {
      set item = dynamicItem
    }

    if $$$ISERR(sc) quit

    if insertStrategy = "Array" {
      set key = $select($isvalidnum(key) && (startOffset > 0): key + startOffset, 1: key)
      do collection.SetAt(item, key)
    } else {
      do collection.Insert(item)
    }

    do ..UpdatePath("")
  }

  set ..Depth = ..Depth - 1
  quit sc
}

Method GetAndCacheDefinition(id As %String) As %Persistent [ Private ]
{

  if id [ "||" set definitionClass = "%Dictionary.CompiledProperty"
  else  set definitionClass = "%Dictionary.CompiledClass"

  set definition = $get(i%CachedDefinitions(id))
  if $isobject(definition) return definition

  set i%CachedDefinitions(id) = $System.OBJ.OpenId(definitionClass, id)
  return i%CachedDefinitions(id)
}

}

