Class Frontier.UnitTest.Fixtures.Student Extends (%Persistent, %Populate)
{

Property Name As %String;

Relationship Class As Class [ Cardinality = one, Inverse = Students ];

Property Enrollment As %DateTime;

Property Adress As %String(POPSPEC = "Street()");

Property PeriodStart As %Time;

Property PeriodEnd As %Time;

Property LastPresentDate As %Date(FORMAT = 4);

Property Active As %Boolean;

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
<Value name="4">
<Value>BirthDate</Value>
</Value>
<Value name="5">
<Value>SomeValue</Value>
</Value>
<Value name="6">
<Value>Adress</Value>
</Value>
<Value name="7">
<Value>Enrollment</Value>
</Value>
<Value name="8">
<Value>PeriodStart</Value>
</Value>
<Value name="9">
<Value>PeriodEnd</Value>
</Value>
<Value name="10">
<Value>LastPresentDate</Value>
</Value>
<Value name="11">
<Value>Active</Value>
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
<Property name="Active">
<AverageFieldSize>1</AverageFieldSize>
<Selectivity>50.0000%</Selectivity>
</Property>
<Property name="Adress">
<AverageFieldSize>14.7</AverageFieldSize>
<Selectivity>10.0000%</Selectivity>
</Property>
<Property name="BirthDate">
<AverageFieldSize>5</AverageFieldSize>
<Selectivity>10.0000%</Selectivity>
</Property>
<Property name="Class">
<AverageFieldSize>1</AverageFieldSize>
<Selectivity>100.0000%</Selectivity>
</Property>
<Property name="Enrollment">
<AverageFieldSize>1</AverageFieldSize>
<Selectivity>100.0000%</Selectivity>
</Property>
<Property name="LastPresentDate">
<AverageFieldSize>5</AverageFieldSize>
<Selectivity>10.0000%</Selectivity>
</Property>
<Property name="Name">
<AverageFieldSize>15</AverageFieldSize>
<Selectivity>10.0000%</Selectivity>
</Property>
<Property name="PeriodEnd">
<AverageFieldSize>4.9</AverageFieldSize>
<Selectivity>10.0000%</Selectivity>
</Property>
<Property name="PeriodStart">
<AverageFieldSize>4.9</AverageFieldSize>
<Selectivity>10.0000%</Selectivity>
</Property>
<Property name="SomeValue">
<AverageFieldSize>7</AverageFieldSize>
<Selectivity>100.0000%</Selectivity>
</Property>
<SQLMap name="IDKEY">
<BlockCount>-4</BlockCount>
</SQLMap>
<StreamLocation>^Frontier.UnitTest.F50C.StudentS</StreamLocation>
<Type>%Library.CacheStorage</Type>
}

}

