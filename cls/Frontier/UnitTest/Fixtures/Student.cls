Class Frontier.UnitTest.Fixtures.Student Extends (%Persistent, %Populate)
{

Property Name As %String;

Relationship Class As Class [ Cardinality = one, Inverse = Students ];

Query PaginatedStudents(offset As %Integer, limit As %Integer) As %SQLQuery [ SqlProc ]
{
  
  SELECT *, %VID as Index FROM (SELECT * FROM FRONTIER_UNITTEST_FIXTURES.STUDENT) WHERE %VID BETWEEN :offset AND :limit
}

Storage Default
{
<Data name="StudentDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Name</Value>
</Value>
<Value name="3">
<Value>Class</Value>
</Value>
</Data>
<DataLocation>^Frontier.UnitTest.F50C.StudentD</DataLocation>
<DefaultData>StudentDefaultData</DefaultData>
<ExtentSize>10</ExtentSize>
<IdLocation>^Frontier.UnitTest.F50C.StudentD</IdLocation>
<IndexLocation>^Frontier.UnitTest.F50C.StudentI</IndexLocation>
<Property name="%%CLASSNAME">
<AverageFieldSize>1</AverageFieldSize>
<Selectivity>100.0000%</Selectivity>
</Property>
<Property name="%%ID">
<AverageFieldSize>1.1</AverageFieldSize>
<Selectivity>1</Selectivity>
</Property>
<Property name="Class">
<AverageFieldSize>1.1</AverageFieldSize>
<Selectivity>12.5000%</Selectivity>
</Property>
<Property name="Name">
<AverageFieldSize>16.5</AverageFieldSize>
<Selectivity>10.0000%</Selectivity>
</Property>
<SQLMap name="IDKEY">
<BlockCount>-4</BlockCount>
</SQLMap>
<StreamLocation>^Frontier.UnitTest.F50C.StudentS</StreamLocation>
<Type>%Library.CacheStorage</Type>
}

}

