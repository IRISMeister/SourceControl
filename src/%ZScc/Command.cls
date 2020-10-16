Include (%sySite, %ZScc.Constants, %occErrors)

Class %ZScc.Command Extends %Persistent
{

/// Product name, e.g. VSS, ClearCase, CVS, etc..
Parameter PRODUCT;

Property Options As array Of %String;

Property LocalWorkspace As %String(MAXLEN = 250);

Property Repository As %String(MAXLEN = 250);

/// revision number, leave empty for LATEST
Property Revision As %String;

Property Command As %String(MAXLEN = 500) [ InitialExpression = {$g(^ZScc(..#PRODUCT,"MainCommand"),"git")} ];

Property Branch As %String;

Property Log As %Boolean;

/// reload entity into Studio from workspace ?
Property Reload As %Boolean [ InitialExpression = 0 ];

Property SubCommand As %String(MAXLEN = 500);

Property CommandString As %String(MAXLEN = 3000);

Property Result As %GlobalCharacterStream;

Property IsDisconnected As %Boolean [ InitialExpression = 0 ];

/// InternalName - used for file export/reload
Property InternalName As %String(MAXLEN = 100);

/// External name with path - used to file export/reload
Property ExternalName As %String(MAXLEN = 250);

/// External name without path
Property File As %String(MAXLEN = 250);

Property GUID As %String [ InitialExpression = {$System.Util.CreateGUID()} ];

Property TimeStampCreated As %String [ ReadOnly ];

Property Debug As %Boolean [ InitialExpression = 0 ];

Index RowId On GUID [ IdKey, PrimaryKey, Unique ];

/// +DK 1.21 - changed Results from list of serial objects to parent-child reloationshi between two persistent
/// objects. This is for better debugging
Relationship Results As %ZScc.CommandResult [ Cardinality = children, Inverse = Command ];

Method %OnNew(initvalue As %CacheString) As %Status [ Private, ProcedureBlock = 1, ServerOnly = 1 ]
{
	set ..LocalWorkspace=$lg(initvalue,1)
	set ..Repository=$lg(initvalue,2)
	set ..Branch=$lg(initvalue,3)
	Quit $$$OK
}

Method LogGet() As %Boolean [ CodeMode = expression ]
{
$g(^ZScc(..#PRODUCT,"CommandLog"))
}

/// This callback method is invoked by the <METHOD>%Save</METHOD> method to 
/// provide notification that the object is being saved. It is called before 
/// any data is written to disk.
/// 
/// <P><VAR>insert</VAR> will be set to 1 if this object is being saved for the first time.
/// 
/// <P>If this method returns an error then the call to <METHOD>%Save</METHOD> will fail.
Method %OnBeforeSave(insert As %Boolean) As %Status [ Private, ServerOnly = 1 ]
{
	if insert set i%TimeStampCreated=$zdt($NOW(),3)
	Quit $$$OK
}

Storage Default
{
<Data name="CommandDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>LocalWorkspace</Value>
</Value>
<Value name="3">
<Value>Repository</Value>
</Value>
<Value name="4">
<Value>Revision</Value>
</Value>
<Value name="5">
<Value>Command</Value>
</Value>
<Value name="6">
<Value>Branch</Value>
</Value>
<Value name="7">
<Value>Log</Value>
</Value>
<Value name="8">
<Value>Reload</Value>
</Value>
<Value name="9">
<Value>SubCommand</Value>
</Value>
<Value name="10">
<Value>CommandString</Value>
</Value>
<Value name="11">
<Value>Result</Value>
</Value>
<Value name="12">
<Value>IsDisconnected</Value>
</Value>
<Value name="13">
<Value>InternalName</Value>
</Value>
<Value name="14">
<Value>ExternalName</Value>
</Value>
<Value name="15">
<Value>File</Value>
</Value>
<Value name="16">
<Value>TimeStampCreated</Value>
</Value>
<Value name="17">
<Value>Debug</Value>
</Value>
</Data>
<Data name="Options">
<Attribute>Options</Attribute>
<Structure>subnode</Structure>
<Subscript>"Options"</Subscript>
</Data>
<DataLocation>^%ZScc.CommandD</DataLocation>
<DefaultData>CommandDefaultData</DefaultData>
<IdLocation>^%ZScc.CommandD</IdLocation>
<IndexLocation>^%ZScc.CommandI</IndexLocation>
<StreamLocation>^%ZScc.CommandS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
