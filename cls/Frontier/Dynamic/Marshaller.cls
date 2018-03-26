Class Frontier.Dynamic.Marshaller Extends %RegisteredObject
{

Property Cache As %DynamicObject [ MultiDimensional, Private ];

Property Properties As %List [ Private ];

Property DropCyclicReferences [ InitialExpression = 1 ];

Method %OnNew() As %Status [ Private ]
{
  quit $$$OK
}

Method PropertiesSet(value As %String = "") As %Status
{
  set i%Properties = $lfs(value)
  quit $$$OK
}

ClassMethod Marshall(object As %RegisteredObject, Output dynamicObject As %DynamicAbstractObject, properties As %String = "") As %Status
{
  set marshaller = ..%New()
  set marshaller.Properties = properties
  if $isobject(object) {
    set type = $classname(object)
    if ##class(Frontier.Types).IsCollection(type) return marshaller.MakeDynamicCollection(object, .dynamicObject)
    if ##class(Frontier.Types).IsDynamic(type) return marshaller.MarshallPartial(object, .dynamicObject)
    if ##class(Frontier.Types).IsInstantiable(type) return marshaller.MakeDynamicObject(object, .dynamicObject)
  }
  return $$$OK
}

Method MarshallPartial(dynamicInstance As %DynamicAbstractObject, marshalledObject As %DynamicAbstractObject = "") As %Status
{
  set sc = $$$OK
  set iterator = dynamicInstance.%GetIterator()
  set marshalledObject = $System.OBJ.New($classname(dynamicInstance))
  set dynamicValueResult = ""
  
  while iterator.%GetNext(.key, .value) {
    set dynamicValueResult = value
    if $isobject(value) {
      set valueType = $classname(value)
      set isDynamic = ##class(Frontier.Types).IsDynamic(valueType)
      set isStream = ##class(Frontier.Types).IsStream(valueType)
      set isSQLProvider = ##class(Frontier.Types).IsSQLProvider(valueType)
      if isDynamic {
        set sc = ..MarshallPartial(value, .dynamicValueResult)       
      } elseif 'isStream && 'isSQLProvider {
        set sc = ..Marshall(value, .dynamicValueResult)
      }
      if $$$ISERR(sc) return sc
    }
    do marshalledObject.%Set(key, dynamicValueResult)
  }
  return sc
}

ClassMethod MarshallCollection(collection As %RegisteredObject, Output dynamicCollection As %DynamicObject, properties As %String = "") As %Status
{
  set marshaller = ..%New()
  set marshaller.Properties = properties
  quit marshaller.MakeDynamicCollection(collection, .dynamicCollection)
}

Method MakeDynamicObject(object As %RegisteredObject, Output dynamicObject As %DynamicObject = "", parentKey As %String = "", parentObject As %RegisteredObject = "") As %Status [ Private ]
{
  set sc = $$$OK     
  
  // Temporary table to reuse processed instances.
  if $data(i%Cache(object)) {
    quit $$$OK
  } else {
    set dynamicObject = ##class(%DynamicObject).%New()
    set i%Cache(object) = dynamicObject
  }
    
  set isSameObject = 0
  set affectedProperties = ""
  set classDescriptors = ##class(%Dictionary.CompiledClass).%OpenId($classname(object))
  
  if $lv(..Properties) && (..Properties '= "") {
    set affectedProperties = ##class(%ListOfObjects).%New()
    for i=1:1:classDescriptors.Properties.Count() {
      set propertyDescriptors = classDescriptors.Properties.GetAt(i)
      if $lf(..Properties, propertyDescriptors.Name) {
        set sc = affectedProperties.Insert(propertyDescriptors)
      }
    }
  } else {
    set affectedProperties = classDescriptors.Properties
  }  
    
  for i=1:1:affectedProperties.Count() {    
    set propertyDescriptors = affectedProperties.GetAt(i)    
    if '$isobject(propertyDescriptors) continue    
    if propertyDescriptors.MultiDimensional || propertyDescriptors.Private || propertyDescriptors.Internal || ($extract(propertyDescriptors.Name) = "%") continue    
    if $isobject(parentObject) && ($classname(parentObject) = propertyDescriptors.Type) && 
      (parentKey = propertyDescriptors.Name) && (propertyDescriptors.Cardinality '= "") {
      // Prevents the buffer from overflowing by skipping parent relationship serialization.
      // DO NOT DISABLE THIS FLAG WHEN SERIALIZING TO JSON!
      if '..DropCyclicReferences set $property(dynamicObject, parentKey) = i%Cache(parentObject)
      continue
    }
    set jsonDataFormat = ##class(Frontier.Types).GetJSONDataFormat(propertyDescriptors.Type)
    set value = $property(object, propertyDescriptors.Name)
    if $isobject(value) {
      if value.%IsA("%RelationshipObject") {
        set parentObject = object               
        set parentKey = propertyDescriptors.Inverse
      }
      if propertyDescriptors.Collection = "" {        
        if value.%Extends("%Stream.Object") {
          set dynamicChild = $System.OBJ.New($classname(value))
          set sc = dynamicChild.CopyFrom(value)
          if $$$ISERR(sc) quit
        } else {          
          set sc = ..MakeDynamicObject(value, .dynamicChild)
        }        
      } else {
        set sc = ..MakeDynamicCollection(value, .dynamicChild, parentKey, parentObject)          
      }
      if $$$ISERR(sc) quit      
      //set $property(dynamicObject, propertyDescriptors.Name) = dynamicChild
      if $isobject(dynamicChild) do dynamicObject.%Set(propertyDescriptors.Name, dynamicChild)
      else  do dynamicObject.%Set(propertyDescriptors.Name, "", jsonDataFormat)
    } else {
      set internalValue = $property(object, propertyDescriptors.Name)
      set d = propertyDescriptors.Type
      if jsonDataFormat '= "null" {
        do dynamicObject.%Set(propertyDescriptors.Name, internalValue, jsonDataFormat)
      } else {
        do dynamicObject.%Set(propertyDescriptors.Name, internalValue)
      }
      if ##class(%Dictionary.CompiledMethod).%ExistsId(propertyDescriptors.Type_"||LogicalToDisplay") {                
        set externalValue = $classmethod(propertyDescriptors.Type, "LogicalToDisplay", internalValue)
        if externalValue '= internalValue {
          set $property(dynamicObject, propertyDescriptors.Name_"__x") = externalValue
        }
      }
    }      
  }  
  if object.%Extends("%Persistent") {
    if $lf(..Properties, "__id__") || (..Properties = "") {
      set id = object.%Id()
      if id '= "" set $property(dynamicObject, "__id__") = object.%Id()
    }
  }      
  quit sc
}

Method MakeDynamicCollection(collection As %Collection.Super, Output dynamicCollection As %String, parentKey As %String = "", parentObject As %RegisteredObject = "") As %Status [ Private ]
{
  
  set sc = $$$OK   
  set startOffset = 0
  set cyclicReferenceTrap = 0
      
  if collection.%IsA("%Collection.AbstractList") || collection.%IsA("%RelationshipObject") {
    set startOffset = 1
    set dynamicCollection = []
  } else {
    set dynamicCollection = {}
  }
   
  set key = ""
  set item = collection.GetNext(.key)
  
  while key {  
    if $isobject(item) {
      if item.%IsA("%Collection.AbstractIterator") {
        set sc = ..MakeDynamicCollection(item , .value)
      } else {
        set sc = ..MakeDynamicObject(item, .value, parentKey, parentObject)
        set cyclicReferenceTrap = (value = "")
      }
    } else {
      set value = item
    }
    if 'cyclicReferenceTrap do dynamicCollection.%Set(key - startOffset, value)    
    if $$$ISERR(sc) quit
    
    set item = collection.GetNext(.key)
  }
  quit sc
}

}

