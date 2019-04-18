/// This holds the metadata used to resolve each argument from the classmethod to be called which generates an response.
Class Frontier.ArgumentDescription Extends %RegisteredObject
{

Property Name As %String;

Property Alias As %String;

Property DefaultValue As %String;

Property HasDefaultValue As %Boolean [ InitialExpression = 0 ];

Property Type As %String;

Property Arity As %Boolean [ InitialExpression = 0 ];

Property Parameters As array Of %String;

Property Index As %Integer [ Required ];

}
