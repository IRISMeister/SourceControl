Class %ZScc.GIT Extends %ZScc.Basic
{

Parameter PRODUCT = "GIT";

Property Branch As %String [ InitialExpression = "master" ];

XData Menu
{
<MenuBase>
<Menu Name="%SourceMenu" Type="0">
<MenuItem Name="settings" />
<MenuItem Separator="1"/> 
<MenuItem Name="addpj" />
<MenuItem Name="addns" />
<MenuItem Separator="1"/> 
<!--
<MenuItem Name="checkout2" />
<MenuItem Separator="1"/> 
-->
<MenuItem Name="import" />
<MenuItem Name="import1" />
<MenuItem Separator="1"/> 
<MenuItem Name="commiton" />
<MenuItem Name="commitoff" />
<MenuItem Name="commit" />
<MenuItem Separator="1"/> 
<MenuItem Name="checkout1" />
<MenuItem Separator="1"/> 
<MenuItem Name="pull" />
<MenuItem Name="push" />
<MenuItem Separator="1"/> 
<MenuItem Name="status" />
<MenuItem Name="statusv" />
<MenuItem Name="statusv1" />
<MenuItem Separator="1"/> 
<MenuItem Name="showcmdon"/>
<MenuItem Name="showcmdoff"/>
<MenuItem Separator="1"/> 
<MenuItem Name="dump"/>
</Menu>
</MenuBase>
}

Method OnConnect()
{
	Set tSC=##super()
	If $$$ISOK(tSC) {
		#;これによりWORKがGITの管理対象になる(.gitフォルダが作成される)
		If ..Debug w "initialize work folders",!
		Do ..InitDir()
	}

	#;Remote Repositoryへのリンクが既に存在するかどうかチェック。
	#;無ければ何もしない
	If ..GetRepositoryPath()'="" {
		Set sts=..CheckRepository(..GetRepositoryPath())
		if sts=$$$OK {
			If ..Debug w "Remote Repository ",..GetRepositoryPath()," already linked",!
		}
		else {
			w " ***************************************************************************************",!
			w " Adding remote repository by calling 'git remote add origin url'",!		
			w " Remote repository is ",..GetRepositoryPath(),!		
			w " ***************************************************************************************",!
			Do ..LinkToRepository(..GetRepositoryPath())
		}
	}
}

Method OnAfterSave(InternalName As %String, Object As %RegisteredObject = {$$$NULLOREF}) As %Status
{
	// Don't perform add/commit if importing via standard studio function
	If ..IsStdImportInProgress { Return $$$OK }
	Set tSC=##super(InternalName,Object)
	Do ..Add(..ExternalName)
	If ..IsAutoCommitOn Do ..Commit(..ExternalName,"auto commited")

	Return $$$OK
}

/// ダイアログ表示の後にユーザの入力値に基づいたアクションをここに記述
Method AfterUserAction(Type As %Integer, Name As %String, InternalName As %String, Answer As %Integer, Msg As %String = "", ByRef Reload As %Boolean) As %Status
{
	If ..Debug Write "Method 'AfterUserAction' Type:"_Type_" Name:"_Name_" InternalName:"_InternalName_" Answer:"_Answer_" Msg:"_Msg_" Reload:"_$G(Reload),!

	if Type=$$$ACTIONTYPEMENU {
		Set menuID=..TranslateMenuNameToMenuID(Name)
		If menuID="import" { //import all from workspace
			If Answer'=$$$YES Quit $$$OK
			Set dire=..GetLocalWorkspacePath()
			If ##class(%File).Exists(dire) {
				Do $SYSTEM.OBJ.ImportDir(dire,"*.mac;*.cls;*.xml","ck",.e,1)
				zw e
			}
			Else { Quit '$$$OK }

		} 
		ElseIf menuID="import1" { //import an item from workspace
			If Answer'=$$$YES Quit $$$OK
			Set path=..GetLocalWorkspacePath()
			Set file=##class(%ZScc.Utils).ExternalName(InternalName,path)
			Do $System.OBJ.Load(file,"ck")
		}
		ElseIf menuID="commit" {
			If Answer'=$$$YES Quit $$$OK
			Set comment=Msg
			Do ..Commit("",comment)
		}
		ElseIf menuID="checkout1" {
			If Answer'=$$$YES Quit $$$OK
			Set extName=##class(%ZScc.Utils).ExternalName(InternalName,"")			
			Do ..CheckOut1(..GetLocalWorkspacePath(),extName) 
		}
		ElseIf menuID="checkout2" {
			#;NYI
		}
		
	}
	Quit $$$OK
}

Method InitDir(DirectoryName As %String = "", Repository As %String = "") As %Status
{
	#; git init
	If DirectoryName="" {Set p1=..GetLocalWorkspacePath()}
	Else {Set p1=DirectoryName}
	Set p2=""

	if ..Debug Write "Method 'InitDir' DirectoryName:"_p1_" Repository:"_p2,!

	Set tCmd=##class(%ZScc.GIT.Command).%New($lb(p1,p2))
	Set tCmd.SubCommand="init"
	Do tCmd.Execute()
	$$$DUMPCOMMAND(tCmd.CommandString)
	Do ..DumpOutput(tCmd.Result)

	#; need these config settings as default
	Set tCmd=##class(%ZScc.GIT.Command).%New($lb(p1,p2))
	Set tCmd.SubCommand="config user.email xxx@yyy"
	Do tCmd.Execute()
	$$$DUMPCOMMAND(tCmd.CommandString)
	Do ..DumpOutput(tCmd.Result)

	Set tCmd=##class(%ZScc.GIT.Command).%New($lb(p1,p2))
	Set tCmd.SubCommand="config user.name xxx"
	Do tCmd.Execute()
	$$$DUMPCOMMAND(tCmd.CommandString)
	Do ..DumpOutput(tCmd.Result)

	Quit $$$OK
}

Method CheckOut1(DirectoryName As %String = "", FileName As %String = "") As %Status
{
	If DirectoryName="" {Set p1=..GetLocalWorkspacePath()}
	Else {Set p1=DirectoryName}

	if ..Debug Write "Method 'CheckOutDir' DirectoryName:"_p1_" FileName:"_FileName,!

	Set tCmd=##class(%ZScc.GIT.Command).%New($lb(p1,""))
	Set tCmd.SubCommand="checkout HEAD "_FileName
	Set status=tCmd.Execute()
	$$$DUMPCOMMAND(tCmd.CommandString)
	If ..Debug {Do ..DumpOutput(tCmd.Result)}
	If 'status  Do ..DumpOutput(tCmd.Result,"ERROR")

	Quit $$$OK
}

Method CheckOut2(DirectoryName As %String = "", Branch As %String = "") As %Status
{
	If DirectoryName="" {Set p1=..GetLocalWorkspacePath()}
	Else {Set p1=DirectoryName}

	if ..Debug Write "Method 'CheckOutDir' DirectoryName:"_p1_" Branch:"_Branch,!

	Set tCmd=##class(%ZScc.GIT.Command).%New($lb(p1,""))
	Set tCmd.SubCommand="checkout "_Branch
	Set status=tCmd.Execute()
	$$$DUMPCOMMAND(tCmd.CommandString)
	If ..Debug {Do ..DumpOutput(tCmd.Result)}
	If 'status  Do ..DumpOutput(tCmd.Result,"ERROR")

	Quit $$$OK
}

Method Add(FileName As %String = "", Description As %String = "") As %Status
{
	if ..Debug Write "Method 'Add' FileName "_FileName_" Description:"_Description,!

	Set p1=..GetLocalWorkspacePath()
	Set p2=FileName
	
	if ..Debug Write "Adding to Repository: file "_p1_" filename "_p2,!

	Set tCmd=##class(%ZScc.GIT.Command).%New($lb(p1,p2))
	Set tCmd.SubCommand="add"
	Set status=tCmd.Execute()
	$$$DUMPCOMMAND(tCmd.CommandString)
	$$$DUMPRESULT(tCmd.Result)
	If 'status  Do ..DumpOutput(tCmd.Result,"ERROR")

	Quit $$$OK
}

Method Commit(FileName As %String = "", Description As %String = "default commit message") As %Status
{
	if ..Debug Write "Method 'Commit' FileName "_FileName_" Description:"_Description,!

	s p1=..GetLocalWorkspacePath()
	s p2=""
	if ..Debug Write "Commiting to Repository  directory:"_p1_" filename:"_p2,!

	Set tCmd=##class(%ZScc.GIT.Command).%New($lb(p1,p2))
	Set tCmd.SubCommand="commit"
	#; need ^ to escape for dos commands
	Do tCmd.Options.SetAt($USERNAME_" ^<dummy@localhost^>","--author")
	Do tCmd.Options.SetAt(Description,"-m")

	Set status=tCmd.Execute()
	$$$DUMPCOMMAND(tCmd.CommandString)
	$$$DUMPRESULT(tCmd.Result)
	If 'status  Do ..DumpOutput(tCmd.Result,"ERROR")
	
	Quit $$$OK
}

Method Pull() As %Status
{
	if ..Debug Write "Method 'Pull' Current branch:",..Branch,!

	s p1=..GetLocalWorkspacePath()
	s p2=""
	if ..Debug Write "Pulling from remote repository:"_..RepositoryRoot,!

	Set tCmd=##class(%ZScc.GIT.Command).%New($lb(p1,p2))
	Set tCmd.Debug=..Debug
	Set tCmd.SubCommand="pull origin "_..Branch

	Set status=tCmd.Execute()
	$$$DUMPCOMMAND(tCmd.CommandString)
	$$$DUMPRESULT(tCmd.Result)
	If 'status  Do ..DumpOutput(tCmd.Result,"ERROR")
	
	Quit status
}

Method Push() As %Status
{
	if ..Debug Write "Method 'Push' Current branch:",..Branch,!

	s p1=..GetLocalWorkspacePath()
	s p2=""
	if ..Debug Write "Pushing to remote repository:"_..RepositoryRoot,!

	Set tCmd=##class(%ZScc.GIT.Command).%New($lb(p1,p2))
	Set tCmd.Debug=..Debug
	Set tCmd.SubCommand="push -u origin "_..Branch

	Set status=tCmd.Execute()
	$$$DUMPCOMMAND(tCmd.CommandString)
	$$$DUMPRESULT(tCmd.Result)
	If 'status  Do ..DumpOutput(tCmd.Result,"ERROR")
	Quit status
}

Method Status(FileName As %String = "", verbose As %Boolean = 0) As %Status
{
	#;svn status --show-updates --verbose test.mac.xml
	if ..Debug Write "Method 'Status' FileName "_FileName,!

	s p1=..GetLocalWorkspacePath()
	s p2=FileName

	Set tCmd=##class(%ZScc.GIT.Command).%New($lb(p1,p2))
	Set tCmd.SubCommand="status"
	If verbose {
		Do tCmd.Options.SetAt("","--verbose")
	}
	Set status=tCmd.Execute()
	$$$DUMPCOMMAND(tCmd.CommandString)
	Do ..DumpOutput(tCmd.Result)
	If 'status  Do ..DumpOutput(tCmd.Result,"ERROR")
	Quit $$$OK
}

Method GetGitProjectName() As %String
{
	#; GIT doesn't accept / as delimiter
	Quit ..ConfigName_"_"_$NAMESPACE
}

Method GetRepositoryPath() As %String
{
	If ..RepositoryRoot="" Quit ""
	set tPath=$ZCVT(..RepositoryRoot_..RemoteUser_"/"_..GetGitProjectName()_".git","L")
	Quit $translate(tPath,$$$FolderDelimiter,$$$URLDelimiter)
}

Method CheckRepository(Repository As %String) As %Integer
{
	#; check if specified remote repository exists and linked
	#; C:\Users\iwamoto\git\iris-shell2docker>git config --get remote.origin.url
	if ..Debug Write "Method 'CheckRepository' Repository "_Repository,!

	s p1=..GetLocalWorkspacePath()
	s p2="" ;Repository
	If ..Debug { W "p1=",p1,!,"p2=",p2,! }
	Set tCmd=##class(%ZScc.GIT.Command).%New($lb(p1,p2))
	Set tCmd.SubCommand="config"
	Do tCmd.Options.SetAt("remote.origin.url","--get")
	Set status=tCmd.Execute()
	$$$DUMPCOMMAND(tCmd.CommandString)
	$$$DUMPRESULT(tCmd.Result)

	Set notconnected=1
	If status  {
		Set line=tCmd.Result.ReadLine()
		If line="" Set notconnected=1  
		if line=Repository Set notconnected=0  ;http://centos7.localdomain/group1/iris20181_git.git
	}
	If notconnected { Quit '$$$OK }
	Quit $$$OK
}

Method LinkToRepository(Repository As %String) As %Integer
{
	if ..Debug Write "Method 'LinkToRepository' Repository "_Repository,!

	Set p1=..GetLocalWorkspacePath()
	Set Repository=$REPLACE(Repository,"//","//"_..RemoteUser_":"_..RemotePassword_"@")
	Set p2=Repository
	If ..Debug { W "p1=",p1,!,"p2=",p2,! }

	Set tCmd=##class(%ZScc.GIT.Command).%New($lb(p1,p2))
	Set tCmd.SubCommand="remote add origin"
	Set status=tCmd.Execute()
	$$$DUMPCOMMAND(tCmd.CommandString)
	$$$DUMPRESULT(tCmd.Result)
	
	Quit $$$OK
}

Method AddProjectItems() As %Status
{
	Set tSC=##super()
	If $$$ISERR(tSC) { Quit tSC}

	Do ..Add("*")
	Do ..Commit("","commited by AddProjectItems")
	Quit $$$OK
}

Method AddNameSpaceItems() As %Status
{
	Set tSC=##super()
	If $$$ISERR(tSC) { Quit tSC}

	Do ..Add("*")
	Do ..Commit("","commited by AddNameSpaceItems.")
	Quit $$$OK
}

ClassMethod SampleSetup()
{
	Kill ^SYS("SourceControl",..#PRODUCT)
	Set ^SYS("SourceControl",..#PRODUCT,"Debug")=0
	Set ^SYS("SourceControl",..#PRODUCT,"LocalWorkspaceRoot")="\var\git\work\"
	Set ^SYS("SourceControl",..#PRODUCT,"MainCommand")="git"
	/*
	Set ^SYS("SourceControl",..#PRODUCT,"RemotePassword")="xxxxx"
	Set ^SYS("SourceControl",..#PRODUCT,"RemoteUser")="xxxx"
	Set ^SYS("SourceControl",..#PRODUCT,"RepositoryRoot")="http://centos7.mydomain/"
	*/
}

}
