Class Frontier.Schema.Map Extends (%RegisteredObject, %XML.Adaptor)
{

Property Prefix As %String(XMLPROJECTION = "ATTRIBUTE");

Property Forward As %String(XMLPROJECTION = "ATTRIBUTE");

Property Strict As %Boolean(XMLPROJECTION = "ATTRIBUTE") [ InitialExpression = 1 ];

}

