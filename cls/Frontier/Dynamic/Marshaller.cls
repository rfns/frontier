/// This class provides an API used to transform an object into a %DynamicAbstractObject, which can be either a %DynamicObject or a %DynamicArray.
/// This is used internally by Frontier, but it might also be used manually by calling the method Marshal.
/// By default while marshalling an object, this engine will attempt to build a dynamic instance while preventing cyclic references.
/// However since this can be ineffective for most of the cases. So if you want more control, you can also define until which depth the marshalling should be made.
Class Frontier.Dynamic.Marshaller Extends %RegisteredObject
{

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
Property MaxDepth As %Integer [ InitialExpression = 7, Private ];

/// A string that represents the path from concatenated property names, used to filter which properties to include.
Property Path As %String [ Private ];

Property Object As %RegisteredObject [ Private ];

Method %OnNew(maxDepth As %Integer = 7, properties As %String = "", object As %RegisteredObject = "") As %Status
{
  
  if maxDepth < 0 set maxDepth = 7
  set ..Properties = ..SpreadProperties(properties)  
  set ..MaxDepth = maxDepth
  set ..Object = object
  
  return $$$OK
}

/// Marshals the provided 'object' into a dynamic instance that is ready to be serialized.
/// This method returns an error if it fails, otherwise the 'dynamicObject' is populated.
/// The parameter 'properties' can be used to define which properties the instance should contain.
/// The parameter 'maxDepth' if specified will be used in the place of the default cyclic references check.
ClassMethod MarshalDirect(object As %RegisteredObject, Output dynamicObject As %DynamicAbstractObject, properties As %String = "", maxDepth As %Integer = 7) As %Status
{
  set marshaller = ..%New(maxDepth, properties, object)
  return marshaller.Marshal(.dynamicObject)
}

/// Marshals the current object into a Dynamic qualified instance.
/// This method uses the configuration provided from %New which includes an optional object overwrite to be marshalled.
Method Marshal(Output dynamicObject As %DynamicAbstractObject, object As %RegisteredObject = {..Object}) As %Status [ Internal ]
{
  
  if '$isobject(object) {
    return $$$ERROR($$$GeneralError, "Object to marshal was not provided.")
  }  
  
  set i%DescriptorsCache = ""
  set i%PropertiesCache = ""
  set i%JSONDataFormatsCache = ""  
  
  set type = $classname(object)      
  if ##class(Frontier.Types).IsCollection(type) return ..MakeDynamicCollection(object, .dynamicObject)
  if ##class(Frontier.Types).IsDynamic(type) return ..Traverse(object, .dynamicObject)
  if ##class(Frontier.Types).IsInstantiable(type) return ..MakeDynamicObject(object, .dynamicObject) 
  
  return $$$ERROR($$$GeneralError, "Invalid object type to marshal: class must extend from %RegisteredObject.")
}

ClassMethod SpreadProperties(value As %String = "") As %Status [ Internal, Private ]
{
  set props = ""
  set value = $lfs(value)
  
  for i=1:1:$ll(value) {
    set property = $lg(value, i)
    if '$lf(props, property) set $list(props, *+1) = property
    if property [ "." {
      for ii=$length(property, "."):-1:1 {
        set part = $piece(property, ".", 1, ii)
        if $lf(props, part) || (part = "*") continue
        set $list(props, *+1) = part 
      }
    }
  }
  
  return props
}

Method SetValue(target, key, value, type = "") [ Internal, Private ]
{
  if ..IsTooDeep() quit

  if type '= "" {
    do target.%Set(key, value, type)
  } else {
    do target.%Set(key, value)
  }
}

Method IsTooDeep(depth As %Integer = {..Depth}) As %Boolean [ Internal, Private ]
{
  if ..MaxDepth '= "" && (depth > ..MaxDepth) return 1
  return 0
}

Method UpdatePath(pathComponent As %String = "") [ Internal, Private ]
{
  if pathComponent '="" {
    if i%Path '= "" set $piece(i%Path, ".", *+1) = pathComponent
    else  set i%Path = pathComponent
  } else {
    set ..Path = $piece(..Path, ".", 1, *-1)
  }
}

Method Traverse(dynamicInstance As %DynamicAbstractObject, marshalledObject As %DynamicAbstractObject = "") As %Status [ Internal, Private ]
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
        set sc = ..Traverse(value, .dynamicValueResult)
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

ClassMethod MarshalCollection(collection As %RegisteredObject, Output dynamicCollection As %DynamicObject, properties As %String = "") As %Status [ Internal, Private ]
{
  set marshaller = ..%New()
  set marshaller.Properties = properties
  return marshaller.MakeDynamicCollection(collection, .dynamicCollection)
}

Method BuildPropertiesList(classDescriptor As %Dictionary.CompiledClass, Output properties As %AbstractList = "") As %Status [ Internal, Private ]
{
  if $lv(..Properties) && (..Properties '= "") {
    set properties = ##class(%ListOfObjects).%New()
    
    while ..NextSerializableProperty(classDescriptor.Properties, .property, .index) {
      set path = property.Name
      if ..Path '= "" set path = ..Path_"."_property.Name
      
      if $lf(..Properties, path) || $lf(..Properties, ..Path_".*") {
        set sc = properties.Insert(property)
        if $$$ISERR(sc) return sc
      }    
    } 
  } else {
    set properties = classDescriptor.Properties
  }
  return $$$OK
}

Method NextSerializableProperty(properties As %ListOfObjects, ByRef property As %Dictionary.CompiledProperty = "", ByRef index As %Integer = 1) As %Boolean [ Internal, Private ]
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

Method MakeChildObject(object As %RegisteredObject, child As %RegisteredObject, Output bailOut As %Boolean = 0) [ Internal, Private ]
{

  set sc = $$$OK
  
  if object.%Extends("%Stream.Object") {
    set child = $System.OBJ.New($classname(object))
    set sc = child.CopyFrom(object)
    if $$$ISERR(sc) quit
  } elseif object.%Extends("%Collection.AbstractIterator") {    
    set sc = ..MakeDynamicCollection(object, .child, .bailOut)
  } else {
    set sc = ..MakeDynamicObject(object, .child,  .bailOut)
  }  
  return sc
}

Method GetExternalValue(object As %RegisteredObject, propertyName As %String, propertyType As %String, internalValue As %String) As %String [ Internal, Private ]
{
  if ##class(%Dictionary.CompiledMethod).%ExistsId(propertyType_"||LogicalToDisplay") {
    return $method(object, propertyName_"LogicalToDisplay", internalValue)
  }
  return ""
}

Method MakeDynamicObject(object As %RegisteredObject, Output dynamicObject As %DynamicObject = "", Output bailOut As %Boolean = 0) As %Status [ Private ]
{
  set sc = $$$OK

  if ..IsTooDeep(..Depth + 1) set bailOut = 1 return $$$OK
  set dynamicObject = {}

  set ..Depth = ..Depth + 1

  set classname = $classname(object)
  set skip = 0
  
  $$$QuitOnError(..GetProperties(classname, .properties))

  while ..NextSerializableProperty(properties, .property, .index) {
    do ..UpdatePath(property.Name)
    
    set skip = 0
    set value = $property(object, property.Name)
    set jsonDataFormat = ..GetJSONDataFormat(property.Type)
    set isCollection = property.Collection '= ""
    if isCollection || ##class(Frontier.Types).IsInstantiable(property.Type) {
      set child = ""
      if '$isobject(value) do dynamicObject.%Set(property.Name, "", "null") continue
      else  set sc = ..MakeChildObject(value, .child, .skip)
      if skip = 1 continue
      if $$$ISERR(sc) {
        quit
      } elseif child = "" && (value '= "") {
        if ##class(Frontier.Types).IsPersistent($classname(value)) {
          do ..SetValue(dynamicObject, property.Name, "", "null")
        } elseif '##class(Frontier.Types).IsSerial($classname(value)) {
          do ..SetValue(dynamicObject, property.Name, "", "null")
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
    
    do ..UpdatePath("")
  }

  if object.%Extends("%Persistent") && 'skip {
    if $lf(..Properties, "__id__") || (..Properties = "") {
      set id = object.%Id()
      if id '= "" set $property(dynamicObject, "__id__") = object.%Id()
    }
  }  
  
  set ..Depth = ..Depth - 1 
  if dynamicObject.%Size() = 0 {
    set bailOut = 1
    set dynamicObject = ""
  }
  quit sc
}

Method MakeDynamicCollection(collection As %Collection.Super, Output dynamicCollection As %String, Output bailOut As %Boolean = 0) As %Status [ Private ]
{

  set sc = $$$OK
  set startOffset = 0
  
  set elementType = collection.ElementType
  if elementType [ ":" set elementType = $piece(elementType, ":")
  set expectingObject = ##class(Frontier.Types).IsInstantiable(collection.ElementType)
  
  if collection.%Extends("%Collection.AbstractIterator") {
    set startOffset = 1
    set dynamicCollection = []
  } else {
    set dynamicCollection = {}
  } 
   
  set shouldAdvanceDepth = (expectingObject && startOffset = 1)
  
  if shouldAdvanceDepth && ..IsTooDeep(..Depth + 2) set bailOut = 1 return $$$OK 
  if 'shouldAdvanceDepth && ..IsTooDeep(..Depth + 1) set bailOut = 1 return $$$OK   
  
  set ..Depth = ..Depth + 1

  set key = ""
  set item = collection.GetNext(.key)

  while key {
    set skip = 0
    if $isobject(item) {
      if item.%IsA("%Collection.AbstractIterator") {
        set sc = ..MakeDynamicCollection(item, .value, .skip)
      } else {
        set sc = ..MakeDynamicObject(item, .value, .skip)
      }
    } else {      
      if expectingObject set item = "null"
      set value = item
    }

    if 'skip do ..SetValue(dynamicCollection, key - startOffset, value)
    if $$$ISERR(sc) quit

    set item = collection.GetNext(.key)
  }
  
  set ..Depth = ..Depth - 1
  
  if dynamicCollection.%Size() '= collection.Count() {
    set bailOut = 1
    set dynamicCollection = ""
  }  
  
  quit sc
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
  set properties = ..GetPropertiesListFromCache(classname)
  if $isobject(properties) return $$$OK  

  set descriptor = ..GetDescriptor(classname)

  $$$QuitOnError(..BuildPropertiesList(descriptor, .properties))
  do ..CachePropertiesList(classname, properties)

  return $$$OK
}

Method GetPropertiesListFromCache(className As %String) As %Dictionary.CompiledProperty [ Internal, Private ]
{
  if ..Properties '= "" return ""
  set properties = $get(i%PropertiesCache(className))
  
  if properties '= "" return properties
  return ""
}

Method CachePropertiesList(classname As %String, properties As %ListOfObjects) [ Internal, Private ]
{
  if ..Properties '= "" quit
  set i%PropertiesCache(classname) = properties
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

