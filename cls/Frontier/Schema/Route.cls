Class Frontier.Schema.Route Extends (%RegisteredObject, %XML.Adaptor)
{

Property Url As %String(XMLPROJECTION = "ATTRIBUTE");

Property Method As %String(XMLPROJECTION = "ATTRIBUTE");

Property Call As %String(XMLPROJECTION = "ATTRIBUTE");

/// Deprecated but kept in favor of compability with %CSP.REST.
Property Cors As %String(XMLPROJECTION = "ATTRIBUTE");

Property Scope As %String(XMLPROJECTION = "ATTRIBUTE");

Property UseAuth As %Boolean(XMLPROJECTION = "ATTRIBUTE") [ InitialExpression = 1 ];

Property Strict As %Boolean(XMLPROJECTION = "ATTRIBUTE") [ InitialExpression = 1 ];

Property AuthStrategy As %String(XMLPROJECTION = "ATTRIBUTE");

}

