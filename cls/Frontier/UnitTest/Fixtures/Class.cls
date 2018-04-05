Class Frontier.UnitTest.Fixtures.Class Extends (%Persistent, %Populate)
{

Property Plate As %String;

Relationship Students As Student [ Cardinality = many, Inverse = Class ];

Storage Default
{
<Data name="ClassDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Plate</Value>
</Value>
</Data>
<DataLocation>^Frontier.UnitTest.Fix50C.ClassD</DataLocation>
<DefaultData>ClassDefaultData</DefaultData>
<ExtentSize>10</ExtentSize>
<IdLocation>^Frontier.UnitTest.Fix50C.ClassD</IdLocation>
<IndexLocation>^Frontier.UnitTest.Fix50C.ClassI</IndexLocation>
<Property name="%%CLASSNAME">
<AverageFieldSize>1</AverageFieldSize>
<Selectivity>100.0000%</Selectivity>
</Property>
<Property name="%%ID">
<AverageFieldSize>1.1</AverageFieldSize>
<Selectivity>1</Selectivity>
</Property>
<Property name="Plate">
<AverageFieldSize>4.9</AverageFieldSize>
<Selectivity>10.0000%</Selectivity>
</Property>
<SQLMap name="IDKEY">
<BlockCount>-4</BlockCount>
</SQLMap>
<StreamLocation>^Frontier.UnitTest.Fix50C.ClassS</StreamLocation>
<Type>%Library.CacheStorage</Type>
}

}

