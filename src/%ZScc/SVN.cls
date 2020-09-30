/// SVN用のSourceControlクラス<br/>
/// 実行には、各ネームスペースに下記の^SYSグローバルが必要。
/// <PRE>
/// 設定例
/// USER>zw ^SYS
/// ^SYS("SourceControl","SVN","Debug")=1   <==任意。Studio結果WindowにDebug情報を出力。
/// ^SYS("SourceControl","SVN","LocalWorkspaceRoot")="c:\var\svn\work\"
/// ^SYS("SourceControl","SVN","RepositoryRoot")="file:///var/svn/repos/"  あるいは "svn://ipaddress/"
/// ^SYS("SourceControl","SVN","MainCommand")="C:\""Program Files""\SlikSvn\bin\svn.exe"
/// </PRE>
Class %ZScc.SVN Extends %ZScc.Basic
{

Parameter PRODUCT = "SVN";

XData Menu
{
<MenuBase>
<Menu Name="%SourceMenu" Type="0">
<MenuItem Name="settings" />
<MenuItem Separator="1"/> 
<MenuItem Name="addpj" />
<MenuItem Name="addns" />
<MenuItem Separator="1"/> 
<MenuItem Name="checkout" />
<MenuItem Separator="1"/> 
<MenuItem Name="import" />
<MenuItem Name="import1" />
<MenuItem Separator="1"/> 
<MenuItem Name="commiton" />
<MenuItem Name="commitoff" />
<MenuItem Name="commit" />
<MenuItem Separator="1"/> 
<MenuItem Name="status" />
<MenuItem Name="statusv" />
<MenuItem Name="statusv1" />
<MenuItem Separator="1"/> 
<MenuItem Name="showcmdon"/>
<MenuItem Name="showcmdoff"/>
<MenuItem Separator="1"/> 
<MenuItem Name="test"/>
<MenuItem Name="dump"/>
</Menu>
</MenuBase>
}

Method OnConnect()
{
	#;Repositoryが既に存在するかどうかチェック。
	#;無ければここで有無を言わさず作成する
	Set sts=..CheckRepository(..GetRepositoryPath())
	if sts=$$$OK {
		If ..Debug w "Repository ",..GetRepositoryPath()," Already exist",!
	}
	else {
		If sts=-1 {  //cannot contact svn Repository
			w "Repository "_..GetRepositoryPath()_ " is unreachable !!! Nothing to do.",!
		}
		else { 
			w " ***************************************************************************************",!
			w " >>>    IT SEEMS THAT THIS IS A BRAND NEW NAMESPACE WITH NO ENTRY IN THE REPOSITORY  <<<",!	
			W " >>>    Now creating Repository entry for this Namespace                              <<<",!
			w " >>>    If you havn't create Repository yet,                                         <<<",!
			w " >>>          plase do so now and restart studio                                     <<<",!		
			w " >>>          SVN 'svnadmin create'                                                  <<<",!		
			;w " >>>          GIT 'git init'                                                         <<<",!		
			w " ***************************************************************************************",!
			#;Repositoryを新規作成
			Do ..CreateInitialRepositoryDir()
		}
	}
	
	#;ここでワークの存在チェックもしておく。
	#;無ければ作成してしまう。
	Set sts=##class(%File).DirectoryExists(..GetLocalWorkspacePath2Namespace())
	If 'sts {
		If ..Debug w "Creating directory ",..GetLocalWorkspacePath2Namespace(),!
		Set x=$ZF(-1,"md "_..GetLocalWorkspacePath2Namespace())

		#;これによりWORKがSVNの管理対象になる(.svnフォルダが作成される)
		If ..Debug w "Checking out to initialize work folders",!
		Do ..CheckOutDir()

	}
	else {
		If ..Debug w "Directory ",..GetLocalWorkspacePath2Namespace()," Already exist",!
	}
}

/// This is called after the item has been saved to the database.
/// It may be passed a reference to the object representing the item
/// just saved. It can be use to export this documement to an external form for example.
Method OnAfterSave(InternalName As %String, Object As %RegisteredObject = {$$$NULLOREF}) As %Status
{
	// Don't perform add/commit if importing via standard studio function
	If ..IsStdImportInProgress { Return $$$OK }
	Set tSC=##super(InternalName,Object)
	Set file=..GetRepositoryPath()_..ToRepositoryPath(..ExternalName)
	#;アイテムがRepositoryに存在するかチェック。無ければAdd+Commitする。あればCommitだけする。
	Set sts=..CheckRepository(file)
	if sts='$$$OK { //Repositoryに存在しない
		Do ..Add(..ExternalName)
	}

	If ..IsAutoCommitOn Do ..Commit(..ExternalName,"auto commited")

	Quit $$$OK
}

/// ダイアログ表示の後にユーザの入力値に基づいたアクションをここに記述
Method AfterUserAction(Type As %Integer, Name As %String, InternalName As %String, Answer As %Integer, Msg As %String = "", ByRef Reload As %Boolean) As %Status
{
	If ..Debug Write "Method 'AfterUserAction' Type:"_Type_" Name:"_Name_" InternalName:"_InternalName_" Answer:"_Answer_" Msg:"_Msg_" Reload:"_Reload,!

	if Type=$$$ACTIONTYPEMENU {
		Set menuID=..TranslateMenuNameToMenuID(Name)
		If menuID="import" {
			If Answer'=$$$YES Quit $$$OK
			Set dire=..GetLocalWorkspacePath()
			If ##class(%File).Exists(dire) {
				Do $SYSTEM.OBJ.LoadDir(dire,"",.e,1)  //recursive
				zw e
			}
			Else { Quit '$$$OK }

		} 
		ElseIf menuID="import1" {
			Set path=..LocalWorkspaceRoot_..GetExtraPath()
			Do $System.OBJ.Load(##class(%ZScc.Utils).ExternalName(InternalName,path))
		}
		ElseIf menuID="commit" {
			If Answer'=$$$YES Quit $$$OK
			Set comment=Msg
			Do ..Commit("",comment)
		}
		ElseIf menuID="checkout" {
			If Answer'=$$$YES Quit $$$OK
			Do ..CheckOutDir(..GetLocalWorkspacePath2Namespace(),..GetRepositoryPath()) 
		}
		
	}
	Quit $$$OK
}

Method GetExtraPath() As %String
{
	Quit ..ConfigName_$$$FolderDelimiter_$NAMESPACE_$$$FolderDelimiter_..Branch_$$$FolderDelimiter
}

Method GetRepositoryPath() As %String
{
	set tPath=..RepositoryRoot_..GetExtraPath()
	Quit ..ToRepositoryPath(tPath)
}

Method GetRepositoryPath2GivenBranch(Branch As %String = "") As %String
{
	set tPath=..RepositoryRoot_..ConfigName_$$$FolderDelimiter_$NAMESPACE_$$$FolderDelimiter_Branch_$$$FolderDelimiter
	Quit ..ToRepositoryPath(tPath)
}

Method GetRepositoryPath2Namespace() As %String
{
	set tPath=..RepositoryRoot_..ConfigName_$$$FolderDelimiter_$NAMESPACE_$$$FolderDelimiter
	Quit ..ToRepositoryPath(tPath)
}

Method ToRepositoryPath(path) As %String
{
	Quit $translate(path,$$$FolderDelimiter,$$$URLDelimiter)
}

Method GetLocalWorkspacePath2Namespace() As %String
{
	set tPath=..LocalWorkspaceRoot_..ConfigName_$$$FolderDelimiter_$NAMESPACE_$$$FolderDelimiter
	Quit tPath
}

Method CheckRepository(Repository As %String) As %Integer
{
	if ..Debug Write "Method 'CheckRepository' Repository "_Repository,!

	s p1=..GetLocalWorkspacePath()
	s p2=Repository

	Set tCmd=##class(%ZScc.SVN.Command).%New($lb(p1,p2))
	Set tCmd.SubCommand="info"
	Do tCmd.Options.SetAt($USERNAME,"--username")
	Do tCmd.Options.SetAt("""""","--password")
	Set tCmd.File=""
	Set status=tCmd.Execute()
	$$$DUMPCOMMAND(tCmd.CommandString)

	Set unreachable=0
	If 'status  {
		While('tCmd.Result.AtEnd) {
			Set line=tCmd.Result.ReadLine()
			If line[$$$SVNERRRALOCALREPOSOPENFAILED Set unreachable=1  //file: session
			If line[$$$SVNERR1 Set unreachable=1  // svn: session
			 
		}
		If unreachable Quit -1
		Quit '$$$OK
	}
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

Method CreateInitialRepositoryDir() As %Status
{
	For folder="trunk","tags","branches" {
		Do ..CreateRepositoryDir(..GetRepositoryPath2GivenBranch(folder))
	}
	Quit $$$OK
}

Method CreateRepositoryDir(DirectoryName As %String = "", Description As %String = "") As %Status
{
	if ..Debug Write "Method 'CreateRepositoryDir' DirectoryName:"_DirectoryName_" Description:"_Description,!

	s p1="."   			//local workspace
	s p2=DirectoryName  //repo
	If Description="" Set Description="Initializing namespace repository"

	Set tCmd=##class(%ZScc.SVN.Command).%New($lb(p1,p2))
	Set tCmd.SubCommand="mkdir"
	Do tCmd.Options.SetAt(Description,"-m")
	Do tCmd.Options.SetAt("","--parents")
	Do tCmd.Options.SetAt($USERNAME,"--username")
	Do tCmd.Options.SetAt("""""","--password")
	Set tCmd.File=""
	Do tCmd.Execute()
	$$$DUMPCOMMAND(tCmd.CommandString)
	Do ..DumpOutput(tCmd.Result)
	Quit $$$OK
}

Method CheckOutDir(DirectoryName As %String = "", Repository As %String = "") As %Status
{
	If DirectoryName="" {Set p1=..GetLocalWorkspacePathConfig()}
	Else {Set p1=DirectoryName}

	If Repository="" {Set p2=..GetRepositoryPath2Namespace()}
	Else {Set p2=Repository}

	if ..Debug Write "Method 'CheckOutDir' DirectoryName:"_p1_" Repository:"_p2,!

	Set tCmd=##class(%ZScc.SVN.Command).%New($lb(p1,p2))
	Set tCmd.SubCommand="checkout"
	Do tCmd.Options.SetAt($USERNAME,"--username")
	Do tCmd.Options.SetAt("""""","--password")
	Set tCmd.File=""
	Do tCmd.Execute()
	$$$DUMPCOMMAND(tCmd.CommandString)
	Do ..DumpOutput(tCmd.Result)

	Quit $$$OK
}

Method Add(FileName As %String = "", Description As %String = "") As %Status
{
	if ..Debug Write "Method 'Add' FileName "_FileName_" Description:"_Description,!

	Set p1=..GetLocalWorkspacePath()
	Set p2=FileName
	if ..Debug Write "Adding to Repository: file "_p1_" filename "_p2,!

	Set tCmd=##class(%ZScc.SVN.Command).%New($lb(p1,p2))
	Set tCmd.SubCommand="add"
	Do tCmd.Options.SetAt("","--parents")
	Do tCmd.Options.SetAt($USERNAME,"--username")
	Do tCmd.Options.SetAt("""""","--password")
	Set tCmd.File=""
	Do tCmd.Execute()
	$$$DUMPCOMMAND(tCmd.CommandString)
	Do ..DumpOutput(tCmd.Result)
	Quit $$$OK
}

Method Commit(FileName As %String = "", Description As %String = "") As %Status
{
	if ..Debug Write "Method 'Commit' FileName "_FileName_" Description:"_Description,!

	// SVN固有の問題
	//新しいパッケージ名のクラスを作って保存するときにこの問題が発生。
	//ここで毎回チェックするのではオーバヘッドが大きすぎる。
	// recusrively commit parents dirs unitl svn info returns OK.
	// because we've 'svn added --parents xxx'. 
	// C:\var\svn\work\IRIS20181\USER\trunk>svn.exe info file:///var/svn/repos/IRIS20181/USER/trunk/User/Pkg/NewClass1.cls
	// svn: warning: W170000: URL 'file:///var/svn/repos/IRIS20181/USER/trunk/User/Pkg/NewClass1.cls' は、リビジョン 11417 には存在しません
	// svn: E200009: Could not display info for all targets because some targets don't exist
	// ==> filenameを""に、つまりtrunk\以下全てをcommitするように変更。
	s p1=..GetLocalWorkspacePath()
	//s p2=FileName
	s p2=""
	if ..Debug Write "Commiting to Repository: file "_p1_" filename "_p2,!

	
	Set tCmd=##class(%ZScc.SVN.Command).%New($lb(p1,p2))
	Set tCmd.SubCommand="commit"
	Do tCmd.Options.SetAt(Description,"-m")
	Do tCmd.Options.SetAt($USERNAME,"--username")
	Do tCmd.Options.SetAt("""""","--password")
	Set tCmd.File=""
	Set status=tCmd.Execute()
	$$$DUMPCOMMAND(tCmd.CommandString)
	If 'status  Do ..DumpOutput(tCmd.Result,"ERROR")
	Quit $$$OK
}

Method Status(FileName As %String = "", verbose As %Boolean = 0) As %Status
{
	#;svn status --show-updates --verbose test.mac.xml
	if ..Debug Write "Method 'Status' FileName "_FileName,!

	s p1=..GetLocalWorkspacePath()
	s p2=FileName

	Set tCmd=##class(%ZScc.SVN.Command).%New($lb(p1,p2))
	Set tCmd.SubCommand="status"
	Do tCmd.Options.SetAt($USERNAME,"--username")
	Do tCmd.Options.SetAt("""""","--password")
	If verbose {
		Do tCmd.Options.SetAt("","--show-updates --verbose")
	}
	Else {
		Do tCmd.Options.SetAt("","--show-updates")
	}
	Set tCmd.File=""
	Set status=tCmd.Execute()
	$$$DUMPCOMMAND(tCmd.CommandString)
	Do ..DumpOutput(tCmd.Result)
	Quit $$$OK
}

ClassMethod SampleSetup()
{
	Kill ^SYS("SourceControl",..#PRODUCT)
	Set ^SYS("SourceControl",..#PRODUCT,"Debug")=0
	Set ^SYS("SourceControl",..#PRODUCT,"LocalWorkspaceRoot")="\var\svn\work\"
	Set ^SYS("SourceControl",..#PRODUCT,"RepositoryRoot")="file:///var/svn/repos/"
	Set ^SYS("SourceControl",..#PRODUCT,"MainCommand")="C:\""Program Files""\SlikSvn\bin\svn.exe"
}

}
