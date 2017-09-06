Class Frontier.UnitTest.Fixtures.Student Extends (%Persistent, %Populate)
{

Property Name As %String;

Relationship Class As Class [ Cardinality = one, Inverse = Students ];

Query Top10ClassStudents() As %SQLQuery [ SqlProc ]
{
  --SELECT TOP 10 S.*, C.PLATE as placa, 'ouch' as ai FROM FRONTIER_UNITTEST_FIXTURES.STUDENT S
  --JOIN FRONTIER_UNITTEST_FIXTURES.CLASS C ON C.ID = S.CLASS
  --WHERE S.NAME LIKE '%'||:name||'%'
  
  SELECT JSON_OBJECT('id':S.ID,'placa':C.PLATE,'ai': 'ouch') FROM FRONTIER_UNITTEST_FIXTURES.STUDENT S
  JOIN FRONTIER_UNITTEST_FIXTURES.CLASS C ON C.ID = S.CLASS
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
<AverageFieldSize>1.2</AverageFieldSize>
<Selectivity>14.2857%</Selectivity>
</Property>
<Property name="Name">
<AverageFieldSize>15.3</AverageFieldSize>
<Selectivity>10.0000%</Selectivity>
</Property>
<SQLMap name="IDKEY">
<BlockCount>-4</BlockCount>
</SQLMap>
<StreamLocation>^Frontier.UnitTest.F50C.StudentS</StreamLocation>
<Type>%Library.CacheStorage</Type>
}

}

