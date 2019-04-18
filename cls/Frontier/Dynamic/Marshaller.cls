Class Frontier.Dynamic.Marshaller Extends %RegisteredObject
{

Property Cache As %DynamicObject [ MultiDimensional, Private ];

Property Properties As %List [ Private ];

Property Depth As %Integer [ Private ];

Property DescriptorsCache As %CacheString [ Internal, MultiDimensional, Private ];

Property PropertiesCache As %CacheString [ Internal, MultiDimensional, Private ];

Property JSONDataFormatsCache As %CacheString [ Internal, MultiDimensional, Private ];

Method PropertiesSet(value As %String = "") As %Status
{
  set i%Properties = $lfs(value)
  return $$$OK
}

ClassMethod Marshal(object As %RegisteredObject, Output dynamicObject As %DynamicAbstractObject, properties As %String = "") As %Status
{
 
  set marshaller = ..%New()
  set marshaller.Properties = properties
    
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
      do marshalledObject.%Set(key, .dynamicValueResult)
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
    
    if property.MultiDimensional || property.Private || property.Internal continue
    if ($extract(property.Name) = "%") continue
    if property.Cardinality = "parent" || property.Cardinality = "one" continue
      
    return 1    
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
 
  if 'skipCacheCheck && ..IsCached(object) return $$$OK  
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
          do dynamicObject.%Set(property.Name,  value.%Id())
        } elseif '##class(Frontier.Types).IsSerial($classname(value)) {
          do dynamicObject.%Set(property.Name, "null")
        }
      } else {
        do dynamicObject.%Set(property.Name, child)
      }            
    } elseif '(property.Type = "%Boolean" || (property.Type = "%Library.Boolean")) {
      do dynamicObject.%Set(property.Name, value)
      if value = "" continue      
      set external = ..GetExternalValue(object, property.Name, property.Type, value)      
      if value '= external do dynamicObject.%Set(property.Name_"__x", external)
    } else {
      do dynamicObject.%Set(property.Name, value, "boolean")
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
  if ..IsCached(collection) return $$$OK
  
  set startOffset = 0
  set elementType = collection.ElementType
  if elementType [ ":" set collection.ElementType = $piece(elementType, ":")
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
    do dynamicCollection.%Set(key - startOffset, value)    
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

