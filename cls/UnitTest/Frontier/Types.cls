Class UnitTest.Frontier.Types Extends Port.UnitTest.TestCase
{

Method TestIsDataType()
{
  do $$$AssertTrue(##class(Frontier.Util).IsDataType("%Library.String"), "returns 1 if true")
  do $$$AssertNotTrue(##class(Frontier.Util).IsDataType("%Library.RegisteredObject"), "returns 0 if false")
  do $$$AssertNotTrue(##class(Frontier.Util).IsDataType("Invalid"), "returns 0 if invalid")
  do $$$AssertTrue(##class(Frontier.Util).IsDataType("%String"), "can resolve omitted %Library packages")
  do $$$AssertTrue(##class(Frontier.Util).IsDataType("%ZEN.Datatype.boolean"), "can resolve deep inheritances (custom datatypes)")
}

Method TestIsStream()
{
  do $$$AssertTrue(##class(Frontier.Util).IsStream("%Stream.Object"), "returns 1 if true")
  do $$$AssertNotTrue(##class(Frontier.Util).IsStream("%Library.RegisteredObject"), "returns 0 if false")
  do $$$AssertNotTrue(##class(Frontier.Util).IsStream("Invalid"), "returns 0 if invalid")
  do $$$AssertTrue(##class(Frontier.Util).IsStream("%Stream.GlobalCharacter"), "can resolve deep inheritances")
}

Method TestIsSerial()
{
  do $$$AssertTrue(##class(Frontier.Util).IsSerial("%Library.SerialObject"), "returns 1 if true")
  do $$$AssertNotTrue(##class(Frontier.Util).IsSerial("%Library.RegisteredObject"), "returns 0 if false")
  do $$$AssertNotTrue(##class(Frontier.Util).IsSerial("Invalid"), "returns 0 if invalid")
  do $$$AssertTrue(##class(Frontier.Util).IsSerial("%SerialObject"), "can resolve omitted %Library packages")
  do $$$AssertTrue(##class(Frontier.Util).IsSerial("%ArrayOfDataTypes"), "can resolve deep inheritances")
}

Method TestIsCollection()
{
  do $$$AssertTrue(##class(Frontier.Util).IsCollection("%Collection.AbstractIterator"), "returns 1 if true")
  do $$$AssertNotTrue(##class(Frontier.Util).IsCollection("%String"), "returns 0 if false")
  do $$$AssertNotTrue(##class(Frontier.Util).IsCollection("Invalid"), "returns 0 if invalid")
  do $$$AssertTrue(##class(Frontier.Util).IsCollection("%ListOfDataTypes"), "can resolve omitted %Library packages")
  do $$$AssertTrue(##class(Frontier.Util).IsCollection("%Library.ArrayOfDataTypes"), "can resolve deep inheritances")
}

Method TestIsPersistent()
{
  do $$$AssertTrue(##class(Frontier.Util).IsPersistent("%Library.Persistent"), "returns 1 if true")
  do $$$AssertNotTrue(##class(Frontier.Util).IsPersistent("%String"), "returns 0 if false")
  do $$$AssertNotTrue(##class(Frontier.Util).IsPersistent("Invalid"), "returns 0 if invalid")
  do $$$AssertTrue(##class(Frontier.Util).IsPersistent("%Persistent"), "can resolve omitted %Library packages")
  do $$$AssertTrue(##class(Frontier.Util).IsPersistent("%Dictionary.ClassDefinition"), "can resolve deep inheritances")
}

Method TestIsInstantiable()
{
  do $$$AssertTrue(##class(Frontier.Util).IsInstantiable("%Library.RegisteredObject"), "returns 1 if true")
  do $$$AssertNotTrue(##class(Frontier.Util).IsInstantiable("%String"), "returns 0 if false")
  do $$$AssertNotTrue(##class(Frontier.Util).IsInstantiable("Invalid"), "returns 0 if invalid")
  do $$$AssertTrue(##class(Frontier.Util).IsInstantiable("%RegisteredObject"), "can resolve omitted %Library packages")
  do $$$AssertTrue(##class(Frontier.Util).IsInstantiable("%ZEN.proxyObject"), "can resolve deep inheritances")
}

}

