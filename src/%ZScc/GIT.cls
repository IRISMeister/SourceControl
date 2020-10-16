Class %ZScc.GIT Extends %ZScc.Basic
{

Parameter PRODUCT = "GIT";

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
<MenuItem Name="importall" />
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
	#; At this moment, project name is still unknow. So creation/init of folders are deffered to OnBeforeLoad.
}

Method OnBeforeLoad(InternalName As %String) As %Status
{
	If ..Debug Write "Method 'OnBeforeLoad(GIT)' InternalName:"_InternalName,!
	Set tSC=##super(InternalName)

	#; If this is a project file, check if git init is already done.
	Set tType=##class(%ZScc.Utils).GetItemType(InternalName)
	If ##class(%ZScc.Utils).ItemCategory(tType)="project" {
#if 1		
		If ..IsAutoCreateRepoOn {
			if '##class(%File).Exists(..LocalWorkspaceRoot_".git") {
				#;これによりWORKがGITの管理対象になる(.gitフォルダが作成される)
				Do ..InitDir(..LocalWorkspaceRoot)

				If ..GetRemoteRepositoryPath()'="" {
					Set sts=..CheckRemoteRepository(..GetRemoteRepositoryPath())
					if sts=$$$OK {
						If ..Debug w "Remote Repository ",..GetRemoteRepositoryPath()," already linked",!
					}
					else {
						w " ***************************************************************************************",!
						w " Adding remote repository by calling 'git remote add origin url'",!		
						w " Remote repository is ",..GetRemoteRepositoryPath(),!		
						w " ***************************************************************************************",!
						Do ..LinkToRepository(..GetRemoteRepositoryPath())
					}
				}
			}
		}
#endif
	}

	Quit $$$OK
}

Method OnAfterSave(InternalName As %String, Object As %RegisteredObject = {$$$NULLOREF}) As %Status
{
	if ..Debug Write "Method 'OnAfterSave(Git)' InternalName:"_InternalName_" Object: "_Object,!
	// Don't perform add/commit if importing via standard studio function
	If ..IsStdImportInProgress { 
		If ..Debug Write "IsStdImportInProgress is true.",!
		Return $$$OK 
	}
	Do ##super(InternalName,Object)
	If ..ExternalName'="" {
		Do ..Add(..ExternalName)
		If ..IsAutoCommitOn Do ..Commit(..ExternalName,"auto commited")
	}

	Return $$$OK
}

/// ダイアログ表示の後にユーザの入力値に基づいたアクションをここに記述
Method AfterUserAction(Type As %Integer, Name As %String, InternalName As %String, Answer As %Integer, Msg As %String = "", ByRef Reload As %Boolean) As %Status
{
	If ..Debug Write "Method 'AfterUserAction(GIT)' Type:"_Type_" Name:"_Name_" InternalName:"_InternalName_" Answer:"_Answer_" Msg:"_Msg_" Reload:"_$G(Reload),!

	Do ##super(Type,Name,InternalName,Answer,Msg,.Reload)
	if Type=$$$ACTIONTYPEMENU {
		Set menuID=..TranslateMenuNameToMenuID(Name)
		If menuID="commit" {
			If Answer'=$$$YES Quit $$$OK
			Set comment=Msg
			Do ..Commit("",comment)
		}
		ElseIf menuID="checkout1" {
			If Answer'=$$$YES Quit $$$OK
			If InternalName'="" {
				Set extName=##class(%ZScc.Utils).ExternalName(InternalName,"")			
				Do ..CheckOut1(..GetLocalWorkspacePath(),extName) 
			}
			Else {
				W $$$USERACTMSGSTATUS1,!
			}
		}
		ElseIf menuID="checkout2" {
			#;NYI
		}
		
	}
	Quit $$$OK
}

Method InitDir(DirectoryName As %String = "", Repository As %String = "") As %Status
{

	if ..Debug Write "Method 'InitDir' DirectoryName:"_DirectoryName_" Repository:"_Repository,!

	#; git init
	If DirectoryName="" {Set p1=..GetLocalWorkspacePath()}
	Else {Set p1=DirectoryName}
	Set p2=""


	Set tSC=##class(%File).CreateDirectoryChain(p1,.ret)
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
	if ..Debug Write "Method 'CheckOut1' DirectoryName:"_DirectoryName_" FileName:"_FileName,!

	If FileName="." {
		Write $$$USERACTMSGSTATUS1,!
		Quit $$$OK
	}
	If DirectoryName="" {Set p1=..GetLocalWorkspacePath()}
	Else {Set p1=DirectoryName}


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
	if ..Debug Write "Method 'CheckOut2' DirectoryName:"_DirectoryName_" Branch:"_Branch,!

	If DirectoryName="" {Set p1=..GetLocalWorkspacePath()}
	Else {Set p1=DirectoryName}

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
	If FileName="" Quit $$$OK

	Set p1=..GetLocalWorkspacePath()
	Set p2=FileName
	
	if ..Debug Write "Adding to Repository: "_p1_" filename: "_p2,!

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

	Set gitmailaddr=$USERNAME_"@localhost"
	Set tCmd=##class(%ZScc.GIT.Command).%New($lb(p1,p2))
	Set tCmd.SubCommand="-c user.name='"_$USERNAME_"' -c user.email='"_gitmailaddr_"' commit"
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
	if ..Debug Write "Pulling from remote repository:"_..RemoteRepository,!

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
	if ..Debug Write "Pushing to remote repository:"_..RemoteRepository,!

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
	If ..RemoteRepository="" Quit ""
	set tPath=$ZCVT(..RemoteRepository_..RemoteUser_"/"_..GetGitProjectName()_".git","L")
	Quit $translate(tPath,$$$FolderDelimiter,$$$URLDelimiter)
}

Method GetRemoteRepositoryPath() As %String
{
	If ..RemoteRepository="" Quit ""
	set tPath=$ZCVT(..RemoteRepository_..RemoteUser_"/"_..GetGitProjectName()_".git","L")
	Quit $translate(tPath,$$$FolderDelimiter,$$$URLDelimiter)
}

Method CheckRemoteRepository(Repository As %String) As %Integer
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
	If ..IsAutoCommitOn Do ..Commit("","commited by AddProjectItems")

	Quit $$$OK
}

Method AddNameSpaceItems() As %Status
{
	Set tSC=##super()
	If $$$ISERR(tSC) { Quit tSC}

	Do ..Add("*")
	If ..IsAutoCommitOn Do ..Commit("","commited by AddNameSpaceItems.")
	Quit $$$OK
}

ClassMethod SampleSetup()
{
	Kill ^ZScc(..#PRODUCT)

	If $$$ISWINDOWS { Set root="C:\var\git\Project_XYZ\" } Else { Set root="/home/irisusr/git/Project_XYZ/"}
	Set ^ZScc(..#PRODUCT,"LocalWorkspaceRoot")=root
	Set ^ZScc(..#PRODUCT,"Src")="src"
	Set ^ZScc(..#PRODUCT,"AutoCreateRepo")=0
	Set ^ZScc(..#PRODUCT,"AutoCommit")=0
	/*
	Set ^ZScc(..#PRODUCT,"RemotePassword")="xxxxx"
	Set ^ZScc(..#PRODUCT,"RemoteUser")="xxxx"
	Set ^ZScc(..#PRODUCT,"RemoteRepository")="http://centos7.mydomain/"
	*/
}

}
