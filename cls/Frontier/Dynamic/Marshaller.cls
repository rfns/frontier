/// This class provides an API used to transform an object into a %DynamicAbstractObject, which can be either a %DynamicObject or a %DynamicArray.
/// This is used internally by the routing engine, but it might also be used manually by calling the method Marshal.
/// By default while marshalling an object, this engine will attempt to build a dynamic instance while preventing cyclic references.
/// However since this can be ineffective for most of the cases. So if you want more control, you can also define until which depth the marshalling should be made.
Class Frontier.Dynamic.Marshaller Extends %RegisteredObject
{

/// Contains a list of the visited objects. This is used to marshalling prevent cyclic references.
Property Cache As %DynamicObject [ MultiDimensional, Private ];

/// Contains a list of properties that should be contained in the marshalled object.
Property Properties As %List [ Private ];

/// This is a internal counter indicating the current object depth.
Property Depth As %Integer [ Private ];

/// Contains a list of class descriptors. This is used to prevent roundtrips thus improving the performance.
Property DescriptorsCache As %CacheString [ Internal, MultiDimensional, Private ];

/// Contains a list of property descriptors. Same reason as DescriptorsCache.
Property PropertiesCache As %CacheString [ Internal, MultiDimensional, Private ];

/// Contains a list of JSON property types. Also to prevent roundtrips.
Property JSONDataFormatsCache As %CacheString [ Internal, MultiDimensional, Private ];

/// Holds a positive integer value that specifies the maximum depth the marshalling process can reach.
Property MaxDepth As %Integer [ Private ];

Method PropertiesSet(value As %String = "") As %Status [ Private ]
{
  set i%Properties = $lfs(value)
  return $$$OK
}

Method MaxDepth(value As %Integer) As %Integer [ Private ]
{
 if value < 0  set i%MaxDepth = value
 else  set i%MaxDepth = value
 return $$$OK
}

Method SetValue(target, key, value, type = "") [ Private ]
{
  if ..IsTooDeep() quit

  if type '= "" {
    do target.%Set(key, value, type)
  } else {
    do target.%Set(key, value)
  }
}

Method IsTooDeep(depth As %Integer = {..Depth}) As %Boolean [ Private ]
{
  if ..MaxDepth '= "" && (..MaxDepth < depth) return 1
  return 0
}

/// Marshals the provided 'object' into a dynamic instance that is ready to be serialized.
/// This method returns an error if it fails, otherwise the 'dynamicObject' is populated.
/// The parameter 'properties' can be used to define which properties the instance should contain.
/// The parameter 'maxDepth' if specified will be used in the place of the default cyclic references check.
ClassMethod Marshal(object As %RegisteredObject, Output dynamicObject As %DynamicAbstractObject, properties As %String = "", maxDepth As %Integer = "") As %Status
{

  set marshaller = ..%New()
  set marshaller.Properties = properties
  set marshaller.MaxDepth = maxDepth

  if $isobject(object) {
    set type = $classname(object)
    if ##class(Frontier.Types).IsCollection(type) return marshaller.MakeDynamicCollection(object, .dynamicObject)
    if ##class(Frontier.Types).IsDynamic(type) return marshaller.MarshalPartial(object, .dynamicObject)
    if ##class(Frontier.Types).IsInstantiable(type) return marshaller.MakeDynamicObject(object, .dynamicObject)
  }
  return $$$OK
}

Method MarshalPartial(dynamicInstance As %DynamicAbstractObject, marshalledObject As %DynamicAbstractObject = "") As %Status [ Private ]
{
  set sc = $$$OK

  set iterator = dynamicInstance.%GetIterator()
  set marshalledObject = dynamicInstance

  if '$isobject(dynamicInstance) {
    set marshalledObject = $System.OBJ.New($classname(dynamicInstance))
  }

  set dynamicValueResult = ""

  while iterator.%GetNext(.key, .value) {
    set dynamicValueResult = value
    if $isobject(value) {
      set valueType = $classname(value)
      set isDynamic = ##class(Frontier.Types).IsDynamic(valueType)
      set isCollection = ##class(Frontier.Types).IsCollection(valueType)
      set isStream = ##class(Frontier.Types).IsStream(valueType)
      set isSQLProvider = ##class(Frontier.Types).IsSQLProvider(valueType)
      if isDynamic {
        set sc = ..MarshalPartial(value, .dynamicValueResult)
      } elseif isCollection {
        set sc = ..MarshalCollection(value, .dynamicValueResult)
      } elseif 'isStream && 'isSQLProvider {
        set sc = ..MakeDynamicObject(value, .dynamicValueResult)
      }
      do ..SetValue(marshalledObject, key, dynamicValueResult)
      if $$$ISERR(sc) return sc
    }
  }
  return sc
}

ClassMethod MarshalCollection(collection As %RegisteredObject, Output dynamicCollection As %DynamicObject, properties As %String = "") As %Status [ Private ]
{
  set marshaller = ..%New()
  set marshaller.Properties = properties
  return marshaller.MakeDynamicCollection(collection, .dynamicCollection)
}

Method BuildPropertiesList(classDescriptor As %Dictionary.CompiledClass, Output properties As %AbstractList = "") As %Status [ Private ]
{

  if $lv(..Properties) && (..Properties '= "") {
    set properties = ##class(%ListOfObjects).%New()
    for i=1:1:classDescriptor.Properties.Count() {
      set propertyDescriptors = classDescriptor.Properties.GetAt(i)
      if $lf(..Properties, propertyDescriptors.Name) {
        set sc = properties.Insert(propertyDescriptors)
        if $$$ISERR(sc) return sc
      }
    }
  } else {
    set properties = classDescriptor.Properties
  }
  return $$$OK
}

Method NextSerializableProperty(properties As %ListOfObjects, ByRef property As %Dictionary.CompiledProperty = "", ByRef index As %Integer = 1) As %Boolean [ Private ]
{

  while 1 {
    set property = properties.GetAt(index)
    if property = "" return 0

    set index = index + 1
    if property.MultiDimensional || property.Private || property.Internal || ($extract(property.Name) = "%") {
      continue
    } else {
      return 1
    }
  }
}

Method MakeChildObject(object As %RegisteredObject, child As %RegisteredObject, isCollection As %Boolean = 0) [ Private ]
{

  set sc = $$$OK

  if 'isCollection {
    if object.%Extends("%Stream.Object") {
      set child = $System.OBJ.New($classname(object))
      set sc = child.CopyFrom(object)
      if $$$ISERR(sc) quit
    } else {
      set sc = ..MakeDynamicObject(object, .child)
    }
  } else {
    set sc = ..MakeDynamicCollection(object, .child)
  }
  return sc
}

Method GetExternalValue(object As %RegisteredObject, propertyName As %String, propertyType As %String, internalValue As %String) As %String [ Private ]
{
  if ##class(%Dictionary.CompiledMethod).%ExistsId(propertyType_"||LogicalToDisplay") {
    return $method(object, propertyName_"LogicalToDisplay", internalValue)
  }
  return ""
}

Method MakeDynamicObject(object As %RegisteredObject, Output dynamicObject As %DynamicObject = "", skipCacheCheck As %Boolean = 0) As %Status [ Private ]
{
  set sc = $$$OK

  if ..IsTooDeep(..Depth + 1) return $$$OK
  if 'skipCacheCheck && ..IsCached(object)
  set dynamicObject = {}

  do ..PutInCache(object)
  set ..Depth = ..Depth + 1

  set classname = $classname(object)
  $$$QuitOnError(..GetProperties(classname, .properties))

  while ..NextSerializableProperty(properties, .property, .index) {
    set value = $property(object, property.Name)
    set jsonDataFormat = ..GetJSONDataFormat(property.Type)
    set isCollection = property.Collection '= ""
    if isCollection || ##class(Frontier.Types).IsInstantiable(property.Type) {
      set child = ""
      if '$isobject(value) do dynamicObject.%Set(property.Name, "", "null")
      else  set sc = ..MakeChildObject(value, .child, isCollection)
      if $$$ISERR(sc) {
        quit
      } elseif child = "" && (value '= "") {
        if ##class(Frontier.Types).IsPersistent($classname(value)) {
          do ..SetValue(dynamicObject, property.Name, value.%Id())
        } elseif '##class(Frontier.Types).IsSerial($classname(value)) {
          do ..SetValue(dynamicObject, property.Name, "null")
        }
      } else {
        do ..SetValue(dynamicObject, property.Name, child)
      }
    } elseif '(property.Type = "%Boolean" || (property.Type = "%Library.Boolean")) {
      do ..SetValue(dynamicObject, property.Name, value)
      if value = "" continue
      set external = ..GetExternalValue(object, property.Name, property.Type, value)
      if value '= external do ..SetValue(dynamicObject, property.Name_"__x", external)
    } else {
      do ..SetValue(dynamicObject, property.Name, value, "boolean")
    }
  }

  if object.%Extends("%Persistent") {
    if $lf(..Properties, "__id__") || (..Properties = "") {
      set id = object.%Id()
      if id '= "" set $property(dynamicObject, "__id__") = object.%Id()
    }
  }
  set ..Depth = ..Depth - 1
  quit sc
}

Method MakeDynamicCollection(collection As %Collection.Super, Output dynamicCollection As %String) As %Status [ Private ]
{

  set sc = $$$OK
  if ..IsTooDeep(..Depth + 2) return $$$OK
  if ..IsCached(collection) return $$$OK

  set startOffset = 0
  set elementType = collection.ElementType
  if elementType [ ":" set elementType = $piece(elementType, ":")
  set expectingObject = ##class(Frontier.Types).IsInstantiable(collection.ElementType)

  if collection.%IsA("%Collection.AbstractList") || collection.%IsA("%RelationshipObject") {
    set startOffset = 1
    set dynamicCollection = []
  } else {
    set dynamicCollection = {}
  }

  do ..PutInCache(collection)
  set ..Depth = ..Depth + 1

  set key = ""
  set item = collection.GetNext(.key)

  while key {
    if $isobject(item) {
      if item.%IsA("%Collection.AbstractIterator") {
        set sc = ..MakeDynamicCollection(item, .value, 1)
      } else {
        set sc = ..MakeDynamicObject(item, .value, 1)
      }
    } else {
      if expectingObject set item = "null"
      set value = item
    }

    do ..SetValue(dynamicCollection, key - startOffset, value)
    if $$$ISERR(sc) quit

    set item = collection.GetNext(.key)
  }

  set ..Depth = ..Depth - 1
  quit sc
}

Method IsCached(object As %RegisteredObject) As %Boolean [ Internal, Private ]
{
  if '$isobject(object) return 0
  return $data(i%Cache(object))
}

Method PutInCache(object As %RegisteredObject) As %Boolean [ Internal, Private ]
{
  if '$isobject(object) quit
  set i%Cache(object) = ""
}

Method GetDescriptor(classname As %String) As %Status [ Internal, Private ]
{
  set descriptor = $get(i%DescriptorsCache(classname))
  if descriptor = "" {
    set descriptor = ##class(%Dictionary.CompiledClass).%OpenId(classname)
    set i%DescriptorsCache(classname) = descriptor
  }

  return descriptor
}

Method GetProperties(classname As %String, Output properties As %Collection.AbstractList = "") As %Status [ Internal, Private ]
{

  set properties = $get(i%PropertiesCache(classname))
  if properties '= "" return $$$OK

  set descriptor = ..GetDescriptor(classname)

  $$$QuitOnError(..BuildPropertiesList(descriptor, .properties))
  set i%PropertiesCache(classname) = properties

  return $$$OK
}

Method GetJSONDataFormat(propertyType As %String) As %String [ Internal, Private ]
{
  set format = $get(i%JSONDataFormatsCache(propertyType))
  if format = "" {
    set format = ##class(Frontier.Types).GetJSONDataFormat(propertyType)
    set i%JSONDataFormatsCache(propertyType) = format
  }

  return format
}

}
