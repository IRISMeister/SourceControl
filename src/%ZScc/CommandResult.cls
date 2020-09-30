Class %ZScc.CommandResult Extends %Persistent
{

Property Action As %String;

Property ExternalName As %String(MAXLEN = 500);

Property Lock As %String(MAXLEN = 500);

Property Properties As %String(MAXLEN = 500);

Property History As %String(MAXLEN = 500);

Property Switch As %String(MAXLEN = 500);

Property LockInfo As %String(MAXLEN = 500);

Property Updates As %String(MAXLEN = 500);

Property WorkingRevision As %Integer;

Property LastCommittedRevision As %Integer;

Property LastCommittedAuthor As %String(MAXLEN = 200);

Property Reason As %String(MAXLEN = 1000);

Property IsError As %Boolean [ InitialExpression = 0 ];

Relationship Command As %ZScc.Command [ Cardinality = parent, Inverse = Results ];

Storage Default
{
<Data name="CommandResultDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Action</Value>
</Value>
<Value name="3">
<Value>ExternalName</Value>
</Value>
<Value name="4">
<Value>Lock</Value>
</Value>
<Value name="5">
<Value>Properties</Value>
</Value>
<Value name="6">
<Value>History</Value>
</Value>
<Value name="7">
<Value>Switch</Value>
</Value>
<Value name="8">
<Value>LockInfo</Value>
</Value>
<Value name="9">
<Value>Updates</Value>
</Value>
<Value name="10">
<Value>WorkingRevision</Value>
</Value>
<Value name="11">
<Value>LastCommittedRevision</Value>
</Value>
<Value name="12">
<Value>LastCommittedAuthor</Value>
</Value>
<Value name="13">
<Value>Reason</Value>
</Value>
<Value name="14">
<Value>IsError</Value>
</Value>
</Data>
<DataLocation>{%%PARENT}("Results")</DataLocation>
<DefaultData>CommandResultDefaultData</DefaultData>
<ExtentSize>100000</ExtentSize>
<IdLocation>^ZScc.CommandC("Results")</IdLocation>
<IndexLocation>^%ZScc.CommandResultI</IndexLocation>
<StreamLocation>^%ZScc.CommandResultS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
