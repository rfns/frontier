Class Frontier.Dynamic.Unmarshaller [ Abstract ]
{

ClassMethod Unmarshall(className As %String, dynamicObject As %DynamicAbstractObject, Output registeredObject As %RegisteredObject = "") As %Status
{
  
  if $isobject(dynamicObject) {   
    set dynamicType = $classname(dynamicObject)
    set isCollection = ##class(Frontier.Types).IsCollection(className) || ##class(Frontier.Types).IsDynamicArray(className)    
    
    if ##class(Frontier.Types).IsDynamicArray(dynamicType) {
      return ..MakeCollection(className, dynamicObject, .registeredObject)
    } elseif 'isCollection && ##class(Frontier.Types).IsDynamicObject(dynamicType) && ##class(Frontier.Types).IsInstantiable(className) {
      return ..MakeObject(className, dynamicObject, .registeredObject)
    }    
  }
  return $$$ERROR($$$GeneralError, "Cannot unmarshall data types.")
}

ClassMethod MakeObject(className As %String, dynamicObject As %DynamicAbstractObject, Output object As %RegisteredObject = "") As %Status [ Private ]
{
  set object = ""
  set sc = $$$OK
  
  if '$isobject(dynamicObject) || ($isobject(dynamicObject) && 'dynamicObject.%IsA("%DynamicObject")) {
    quit $$$ERROR($$$GeneralError, "dynamicObject must be an instance of %DynamicObject.")
  }
  
  if dynamicObject.%IsDefined("__id__") {
    set object = $System.OBJ.OpenId(className, dynamicObject.%Get("__id__"))
  }
  
  set descriptor = ##class(%Dictionary.CompiledClass).%OpenId(className)
  set properties = descriptor.Properties
  
  set propCount = properties.Count()
  
  set iterator = dynamicObject.%GetIterator()  

  while iterator.%GetNext(.key, .value) {
    if key = "__id__" continue
    set propertyId = className_"||"_key
    set property = ##class(%Dictionary.CompiledProperty).%OpenId(propertyId)     
    if '$isobject(property) continue
    if property.Private || property.Calculated || ($extract(property.Name) = "%") continue
    if '$isobject(object) {
      set object = $System.OBJ.New(className)
    }
    set dynamicObjectPropertyValue = $property(dynamicObject, property.Name)
    set isDataType = ##class(Frontier.Types).IsDataType(property.Type)
    set isSerial = ##class(Frontier.Types).IsSerial(property.Type)
    if 'isDataType {      
      if $isobject(dynamicObjectPropertyValue) && dynamicObjectPropertyValue.%IsA("%DynamicObject") {
        set sc = ..MakeObject(property.Type, dynamicObjectPropertyValue, .dynamicChildInstance)          
        quit:$$$ISERR(sc)
        set $property(object, property.Name) = dynamicChildInstance
      } elseif ##class(Frontier.Types).IsStream(property.Type) {
        set childStream = $System.OBJ.New(property.Type)
        if $isobject(dynamicObjectPropertyValue) && dynamicObjectPropertyValue.%Extends("%Stream.Object") {         
          do childStream.CopyFrom(dynamicObjectPropertyValue)
        } else {          
          do childStream.Write(dynamicObjectPropertyValue)
        }
        set $property(object, property.Name) = childStream
      } elseif isSerial {
        set $property(object, property.Name) = $classmethod(property.Type, "%Open", $lb(dynamicObjectPropertyValue, property.Type))
      } elseif property.Collection '= "" {
        set collectionType = $property(object, property.Name).ElementType
        set dynamicChildInstance = $property(object, property.Name)   
        if $isobject(dynamicObjectPropertyValue) {    
          set sc = ..MakeCollection(collectionType, dynamicObjectPropertyValue, .dynamicChildInstance)        
          quit:$$$ISERR(sc)
          set $property(object, property.Name) = dynamicChildInstance
        } elseif dynamicObjectPropertyValue '= "" {
          set value = dynamicObjectPropertyValue         
          set childInstance = $System.OBJ.OpenId(className, value)
          if $isobject(childInstance) {
            set $property(object, property.Name) = $property(childInstance, property.Name)
          }
        }
      } else {
        set childInstance = $System.OBJ.OpenId(property.Type, value)
        if $isobject(childInstance) set $property(object, property.Name) = childInstance                   
      }      
    } else {
      if dynamicObjectPropertyValue = "null" set dynamicObjectPropertyValue = ""  
      if property.Type = "%Library.Boolean" { set logicalValue = $case(value, "true" : 1, "false" : 0, 1 : 1, 0 : 0, : "") }
      elseif property.Type = "%Library.Date" && (dynamicObjectPropertyValue?4N1"-"2N1"-"2N1"T"2N1":"2N1":"2N1"."3N1"Z" = 1) { set logicalValue = $zdateh($piece(dynamicObjectPropertyValue,"T",1),3,,,,,,,dynamicObjectPropertyValue) }
      else {
        if isDataType && (##class(%Dictionary.CompiledMethod).%ExistsId(property.Type_"||IsValid") && ('$classmethod(property.Type, "IsValid", dynamicObjectPropertyValue) = 1)) {
          try {
            set logicalValue = $method(object, property.Name_"DisplayToLogical", dynamicObjectPropertyValue)            
          } catch {
            set logicalValue = dynamicObjectPropertyValue
          }
        } else {
          set logicalValue = dynamicObjectPropertyValue
        }
      }
      set $property(object, property.Name) = logicalValue     
    }
  }
  quit sc
}

ClassMethod MakeCollection(collectionType As %String, dynamicCollection As %DynamicAbstractObject, Output collection As %Collection.Super = "") As %Status [ Private ]
{
    
  set sc = $$$OK
  set insertStrategy = "list"
  set hasChildObjects = 0
  set collectionClass = "%ListOfDataTypes"
  set firstItem = dynamicCollection.%Get(0)
  set startOffset = 0  
  
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
  
  // We must check for both occorences: 
  // 1 - When this method is called within Deproxify.
  // 2 - When this method is a first call.
  if $isobject(collection) {
    do collection.Clear()
  } else {      
    set collection = $System.OBJ.New(collectionClass)
    set collection.ElementType = collectionType
  }
  
  set iterator = dynamicCollection.%GetIterator()
  set isPersistentItem = ##class(Frontier.Types).IsPersistent(collectionType)
  
  while iterator.%GetNext(.key, .dynamicItem) { 
    set isIdCandidate = '$isobject(dynamicItem) && (dynamicItem '= "")
    set itemClass = $select('isIdCandidate : $classname(dynamicItem), 1: "")
    
    if dynamicItem = "null" && (itemClass '= "") {
      continue      
    }    
    
    if isIdCandidate && isPersistentItem {
      set item = $System.OBJ.OpenId(collectionType, dynamicItem)
    } elseif $isobject(dynamicItem) { 
      set sc = $select(
        dynamicItem.%IsA("%DynamicObject") : ..MakeObject(collectionType, dynamicItem, .item),
        dynamicItem.%Extends("%DynamicArray") : ..MakeCollection(itemClass, dynamicItem, .item),
        1: $$$ERROR($$$GeneralError, "Cannot unmarshall items that aren't dynamic.")
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
  }
  quit sc
}

}

