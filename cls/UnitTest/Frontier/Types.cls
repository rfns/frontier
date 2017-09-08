Class UnitTest.Frontier.Types Extends Port.UnitTest.TestCase
{

Method TestIsDataType()
{
  do $$$AssertTrue(##class(Frontier.Types).IsDataType("%Library.String"), "returns 1 if true")
  do $$$AssertNotTrue(##class(Frontier.Types).IsDataType("%Library.RegisteredObject"), "returns 0 if false")
  do $$$AssertNotTrue(##class(Frontier.Types).IsDataType("Invalid"), "returns 0 if invalid")
  do $$$AssertTrue(##class(Frontier.Types).IsDataType("%String"), "can resolve omitted %Library packages")
  do $$$AssertTrue(##class(Frontier.Types).IsDataType("%ZEN.Datatype.boolean"), "can resolve deep inheritances (custom datatypes)")
}

Method TestIsStream()
{
  do $$$AssertTrue(##class(Frontier.Types).IsStream("%Stream.Object"), "returns 1 if true")
  do $$$AssertNotTrue(##class(Frontier.Types).IsStream("%Library.RegisteredObject"), "returns 0 if false")
  do $$$AssertNotTrue(##class(Frontier.Types).IsStream("Invalid"), "returns 0 if invalid")
  do $$$AssertTrue(##class(Frontier.Types).IsStream("%Stream.GlobalCharacter"), "can resolve deep inheritances")
}

Method TestIsSerial()
{
  do $$$AssertTrue(##class(Frontier.Types).IsSerial("%Library.SerialObject"), "returns 1 if true")
  do $$$AssertNotTrue(##class(Frontier.Types).IsSerial("%Library.RegisteredObject"), "returns 0 if false")
  do $$$AssertNotTrue(##class(Frontier.Types).IsSerial("Invalid"), "returns 0 if invalid")
  do $$$AssertTrue(##class(Frontier.Types).IsSerial("%SerialObject"), "can resolve omitted %Library packages")
  do $$$AssertTrue(##class(Frontier.Types).IsSerial("%ArrayOfDataTypes"), "can resolve deep inheritances")
}

Method TestIsCollection()
{
  do $$$AssertTrue(##class(Frontier.Types).IsCollection("%Collection.AbstractIterator"), "returns 1 if true")
  do $$$AssertNotTrue(##class(Frontier.Types).IsCollection("%String"), "returns 0 if false")
  do $$$AssertNotTrue(##class(Frontier.Types).IsCollection("Invalid"), "returns 0 if invalid")
  do $$$AssertTrue(##class(Frontier.Types).IsCollection("%ListOfDataTypes"), "can resolve omitted %Library packages")
  do $$$AssertTrue(##class(Frontier.Types).IsCollection("%Library.ArrayOfDataTypes"), "can resolve deep inheritances")
}

Method TestIsPersistent()
{
  do $$$AssertTrue(##class(Frontier.Types).IsPersistent("%Library.Persistent"), "returns 1 if true")
  do $$$AssertNotTrue(##class(Frontier.Types).IsPersistent("%String"), "returns 0 if false")
  do $$$AssertNotTrue(##class(Frontier.Types).IsPersistent("Invalid"), "returns 0 if invalid")
  do $$$AssertTrue(##class(Frontier.Types).IsPersistent("%Persistent"), "can resolve omitted %Library packages")
  do $$$AssertTrue(##class(Frontier.Types).IsPersistent("%Dictionary.ClassDefinition"), "can resolve deep inheritances")
}

Method TestIsInstantiable()
{
  do $$$AssertTrue(##class(Frontier.Types).IsInstantiable("%Library.RegisteredObject"), "returns 1 if true")
  do $$$AssertNotTrue(##class(Frontier.Types).IsInstantiable("%String"), "returns 0 if false")
  do $$$AssertNotTrue(##class(Frontier.Types).IsInstantiable("Invalid"), "returns 0 if invalid")
  do $$$AssertTrue(##class(Frontier.Types).IsInstantiable("%RegisteredObject"), "can resolve omitted %Library packages")
  do $$$AssertTrue(##class(Frontier.Types).IsInstantiable("%ZEN.proxyObject"), "can resolve deep inheritances")
}

Method TestIsDynamic()
{
  do $$$AssertTrue(##class(Frontier.Types).IsDynamic("%Library.DynamicAbstractObject"), "returns 1 if true")
  do $$$AssertNotTrue(##class(Frontier.Types).IsDynamic("%String"), "returns 0 if false")
  do $$$AssertNotTrue(##class(Frontier.Types).IsDynamic("Invalid"), "returns 0 if invalid")
  do $$$AssertTrue(##class(Frontier.Types).IsDynamic("%DynamicObject"), "can resolve omitted %Library packages")
  do $$$AssertTrue(##class(Frontier.Types).IsDynamic("%DynamicArray"), "can resolve deep inheritances")
}

Method TestIsDynamicArray()
{
  do $$$AssertTrue(##class(Frontier.Types).IsDynamicArray("%Library.DynamicArray"), "returns 1 if true")
  do $$$AssertNotTrue(##class(Frontier.Types).IsDynamicArray("%String"), "returns 0 if false")
  do $$$AssertNotTrue(##class(Frontier.Types).IsDynamicArray("Invalid"), "returns 0 if invalid")
  do $$$AssertTrue(##class(Frontier.Types).IsDynamicArray("%DynamicArray"), "can resolve omitted %Library packages")
}

Method TestIsDynamicObject()
{
  do $$$AssertTrue(##class(Frontier.Types).IsDynamicObject("%Library.DynamicObject"), "returns 1 if true")
  do $$$AssertNotTrue(##class(Frontier.Types).IsDynamicObject("%String"), "returns 0 if false")
  do $$$AssertNotTrue(##class(Frontier.Types).IsDynamicObject("Invalid"), "returns 0 if invalid")
  do $$$AssertTrue(##class(Frontier.Types).IsDynamicObject("%DynamicObject"), "can resolve omitted %Library packages")
}

Method TestIsSQLProvider()
{
  do $$$AssertTrue(##class(Frontier.Types).IsSQLProvider("Frontier.SQL.Provider"), "returns 1 if true")
  do $$$AssertNotTrue(##class(Frontier.Types).IsSQLProvider("%String"), "returns 0 if false")
  do $$$AssertNotTrue(##class(Frontier.Types).IsSQLProvider("Invalid"), "returns 0 if invalid")
}

}

