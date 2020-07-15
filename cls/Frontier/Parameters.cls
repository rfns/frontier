Class Frontier.Parameters Extends %RegisteredObject
{

/// The size of the indent. Leave it 0 to keep the output inline. Anything other than 0 will add line breaks when adequate.
Property INDENTSIZE As %Integer [ InitialExpression = 0 ];

/// The maximum depth a object can serialized. You should not change it unless you know what you're doing.
Property MAXIMUMDEPTH As %Integer [ InitialExpression = 7 ];

/// Disables the safety mechanism that buffers the response into a stream before outputting it.
/// Use this if you're sure that the request won't return an unhandled error.
Property DIRECTWRITE As %Boolean [ InitialExpression = 0 ];

/// Set the flag to 1 to block parameters that are not explicitly set in the formal spec of the calling method.
/// Otherwise Frontier will skip these parameters.
Property STRICTQUERYPARAMETERS As %Boolean [ InitialExpression = 0 ];

}

