Include %ZScc.Constants

/// SourceControlクラスの基底クラス<br/>
/// 編集した対象をワークスペースにファイル出力する機能を提供。<br/>
/// ソース管理クラスとしては、サブクラスを使用すること。<br/>
/// ワークディレクトリを複数ユーザで共有し、ユーザ別に維持・管理しようとすると
/// <li>全員が別個のCache'アカウントを使用しないといけない</li>
/// <li>プロジェクトは個々のアイテムへのリンク情報であり、別々のプロジェクトに属するアイテムが同一である可能性がある</li>
/// <li>プロジェクトの排他の方法や同期の方法が加わるとソース管理の処理事態が複雑になってしまう</li>
/// 等の制約が加わる。むしろ、ソース管理は単一の利用者に閉じて使用するほうが良いと判断。
/// プロジェクトファイルは(prj拡張子を持つ)アイテムの一つとして管理される。
/// 排他はStudioが持つ編集対象(ルーチン等)を排他する仕組みを利用することにした。
/// この機能により、Aが編集中にBが同じ対象を編集することはあり得ない。
/// よって、ワーク、リポジトリの構造はRoot/インスタンス名/ネームスペース名/xxxx
/// というシンプルなもの(構造に$UsernameやProject名を含めない)となった。<br/>
/// 実行には、各ネームスペースに下記の^SYSグローバルが必要。
/// <PRE>
/// 設定例
/// USER>zw ^SYS
/// ^SYS("SourceControl","Basic","Debug")=1   <==任意。Studio結果WindowにDebug情報を出力。
/// ^SYS("SourceControl","Basic","LocalWorkspaceRoot")="\var\Basic\work\"
/// </PRE>
Class %ZScc.Basic Extends %Studio.SourceControl.Base
{

Parameter PRODUCT = "Basic";

/// ^SYSへの定義が済んでいるか？
Property IsInitialized As %Boolean [ Calculated ];

/// 自動commitは有効か？
Property IsAutoCommitOn As %Boolean [ InitialExpression = 1 ];

/// ShowCommandは有効か？
Property IsShowCommandOn As %Boolean [ InitialExpression = 0 ];

Property IsStdImportInProgress As %Boolean [ InitialExpression = 0 ];

/// Cache Config Name such as 'CACHE'
Property ConfigName As %String [ Calculated ];

Property CurrentProjectName As %String;

Property ExternalName As %String;

Property LocalWorkspaceRoot As %String [ Calculated ];

Property RepositoryRoot As %String [ Calculated ];

/// this indicates the branch name, default is trunk
Property Branch As %String [ InitialExpression = "trunk" ];

Property RemoteUser As %String [ Calculated ];

Property RemotePassword As %String [ Calculated ];

Property Debug As %Boolean [ InitialExpression = 0 ];

Parameter USERACTIONNAME = "tried to change a document that is locked in source control;created a new document;deleted a document;opened a document;closed a document;connected to a new namespace";

XData Menu
{
<MenuBase>
<Menu Name="%SourceMenu" Type="0">
<MenuItem Name="settings" />
<MenuItem Separator="1"/> 
<MenuItem Name="addpj" />
<MenuItem Name="addns" />
<MenuItem Name="import" />
<MenuItem Name="import1" />
<MenuItem Separator="1"/> 
<MenuItem Name="dump"/>
</Menu>
</MenuBase>
}

/// メニューやドキュメント操作時のアクションをここに記述
Method UserAction(Type As %Integer, Name As %String, InternalName As %String, SelectedText As %String, ByRef Action As %String, ByRef Target As %String, ByRef Msg As %String, ByRef Reload As %Boolean) As %Status
{
	If ..Debug {
		Set tName=Name
		#;If Type=$$$ACTIONTYPEOTHER Set tName=$P(..#USERACTIONNAME,";",Name+1)_"("_Name_")"
		Write "Method 'UserAction' Type:"_Type_" Name:"_tName_" InternalName:"_InternalName_" SelectedText:"_SelectedText_" Action:"_Action_" Target:"_Target_" Msg:"_Msg_" Reload:"_$G(Reload),!
	}
	#; 標準のImportを実行した場合
	#; ドキュメント毎に、Add/Commitが発生する(遅い)のを防ぐため、この場合何もしない。
	If (Type=$$$ACTIONTYPEOTHER),(Name=$$$ACTIONOTHERIMPORT)  {
		Set ..IsStdImportInProgress=1
		Return $$$OK
	}
	Else {
		Set ..IsStdImportInProgress=0
	}

	#;もし、UserActionが"User has connected to a new namespace"だったら。
	#;Type=1 : Other Studio action
	#;Name=5 : User has connected to a new namespace
	If (Type=$$$ACTIONTYPEOTHER),(Name=$$$ACTIONOTHERCONNECT)  {

		If '..IsInitialized  {
				w " ***************************************************************************************",!
				w " >>>    If you havn't define ^SYS globals yet,                                       <<<",!
				w " >>>          plase do so now and restart studio .                                   <<<",!		
				w " >>>          Until then, source control will not work .                             <<<",!		
				w " ***************************************************************************************",!
				#;2014-09-25
				#;Quit '$$$OK
				Quit $$$OK
		}

		#;debugフラグを初期化する
		Set ..Debug=..IsDebugEnabled()
		If ..Debug { set ..IsShowCommandOn=1 }

		If ..Debug Write "Checking Repository/workdirectory since this is the first connect by this studio instance.",!

		#; PRODUCT specific logic here
		Do ..OnConnect()
	}
	
	//Type=0  menu操作を行った場合のアクション
	elseif Type=$$$ACTIONTYPEMENU {
		Set menuID=..TranslateMenuNameToMenuID(Name)
		//初期化していない状態でsettings以外を選ぶとエラーを出す
		if (..IsInitialized=0)&(menuID'="settings") {
			set Action=$$$ACTIONALERTDIALOG
			set Target="System is not initialized yet. Do settings first."
			goto done
		}	
		
		if menuID="settings" {
			set Action=$$$ACTIONRUNCSP
			Set Target=$system.CSP.GetDefaultApp($NAMESPACE)_"/%25ZScc.ui."_$Parameter(,"PRODUCT")_".Setting.cls"			
		} elseif menuID="addpj" {
			set Action=$$$ACTIONDONOTHING
			Do ..AddProjectItems()
		} elseif menuID="addns" {
			set Action=$$$ACTIONDONOTHING
			Do ..AddNameSpaceItems()
		} elseif menuID="checkout" {
			set Action=$$$ACTIONSIMPLEDIALOG
			set Target=$$$USERACTMSGCO
		} elseif menuID="checkout1" {
			set Action=$$$ACTIONSIMPLEDIALOG
			set Target=$$$USERACTMSGCO1
		} elseif menuID="checkout2" {
			set Action=$$$ACTIONSIMPLEDIALOG
			set Target=$$$USERACTMSGCO2
		} elseif menuID="import" {
			set Action=$$$ACTIONSIMPLEDIALOG
			set Target=$$$USERACTMSGIMPORT
		} elseif menuID="import1" {
			set Action=$$$ACTIONSIMPLEDIALOG
			set Target=$$$USERACTMSGIMPORT1
		} elseif menuID="commitoff" {
			set Action=$$$ACTIONALERTDIALOG
			set Target=$$$USERACTMSGCOMMITOFF
			set ..IsAutoCommitOn=0
		} elseif menuID="commiton" {
			set Action=$$$ACTIONALERTDIALOG
			set Target=$$$USERACTMSGCOMMITON
			set ..IsAutoCommitOn=1
		} elseif menuID="commit" {
			set Action=$$$ACTIONTEXTDIALOG
			set Target="Comment"
		} elseif menuID="pull" {
			set Action=$$$ACTIONDONOTHING
			Set tSC=..Pull()
			If ('tSC) {
				set Action=$$$ACTIONALERTDIALOG
				set Target=$$$USERACTMSGPULLFAIL
			}
		} elseif menuID="push" {
			set Action=$$$ACTIONDONOTHING
			Set tSC=..Push()
			If ('tSC) {
				set Action=$$$ACTIONALERTDIALOG
				set Target=$$$USERACTMSGPUSHFAIL
			}

		} elseif menuID="status" {
			set Action=$$$ACTIONDONOTHING
			Do ..Status("",0)
		} elseif menuID="statusv" {
			set Action=$$$ACTIONDONOTHING
			Do ..Status("",1)
		} elseif menuID="statusv1" {  // verbose status of a current item
			set Action=$$$ACTIONDONOTHING
			Set extName=""
			If InternalName'="" {Set extName=##class(%ZScc.Utils).ExternalName(InternalName,"") Do ..Status(extName,1)}
			Else {
				set Action=$$$ACTIONALERTDIALOG
				set Target=$$$USERACTMSGSTATUS1
			}
		} elseif menuID="showcmdon" {
			set Action=$$$ACTIONDONOTHING
			set ..IsShowCommandOn=1
		} elseif menuID="showcmdoff" {
			set Action=$$$ACTIONDONOTHING
			set ..IsShowCommandOn=0
		} elseif menuID="test" {
			set Action=$$$ACTIONSIMPLEDIALOG
			set Target=$$$USERACTMSGTEST
		} elseif menuID="dump" {
			w "<<<dumping object...>>>",!
			Do $SYSTEM.OBJ.Dump($this)
			w "<<<dumping settings...>>>",!
			w "ConfigName:",..ConfigName,!
			w "IsInitialized:",..IsInitialized,!
			w "LocalWorkspaceRoot:",..LocalWorkspaceRoot,!
			w "RepositoryRoot:",..RepositoryRoot,!
			w "DebugMode:",..Debug,!
			w "CurrentProjectName:",..CurrentProjectName,!
			w "GetLocalWorkspacePath:",..GetLocalWorkspacePath(),!
			w "GetLocalWorkspacePathConfig:",..GetLocalWorkspacePathConfig(),!
			w "GetExtraPath:",..GetExtraPath(),!
			w "GetRepositoryPath(..Branch):",..GetRepositoryPath(),!
			w "<<<End of dump>>>",!

			set Action=$$$ACTIONDONOTHING
		} 
		else {
			set Action=$$$ACTIONALERTDIALOG
			set Target=$$$USERACTMSGNYI
			If ..Debug Write "NYI. MenuID was ",menuID," Name was ",Name,!

		}		
	}
done	
	Quit $$$OK
}

Method OnConnect()
{
	Set sts=##class(%File).DirectoryExists(..GetLocalWorkspacePath())
	If 'sts {
		If ..Debug w "Creating directory ",..GetLocalWorkspacePath(),!
		Set x=$ZF(-1,"md "_..GetLocalWorkspacePath())
		Quit $$$OK
	}
	else {
		If ..Debug w "Directory ",..GetLocalWorkspacePath()," Already exist",!
		Quit '$$$OK
	}
}

Method OnAfterSave(InternalName As %String, Object As %RegisteredObject = {$$$NULLOREF}) As %Status
{
	if ..Debug Write "Method 'OnAfterSave' InternalName:"_InternalName_" Object: "_Object,!
	//DBへの保存は成功させたいのでOKを返す
	If '..IsInitialized  Quit $$$OK

	//default projectは保存しない
	If $E(InternalName,1,$L($$$DEFAULTPRJNAME))=$$$DEFAULTPRJNAME {
		Write $$$MSGNODEFAULTPRJ,!
		Quit $$$OK
	}	

	Set path=..LocalWorkspaceRoot_..GetExtraPath()
	Set ..ExternalName=##class(%ZScc.Utils).ExportSingleItem(InternalName,path,..Debug)

	Quit $$$OK
}

Method ConfigNameGet() As %String
{
	Quit ##class(%SYS.System).GetInstanceName()
}

/// ダイアログ表示の後にユーザの入力値に基づいたアクションをここに記述
Method AfterUserAction(Type As %Integer, Name As %String, InternalName As %String, Answer As %Integer, Msg As %String = "", ByRef Reload As %Boolean) As %Status
{
	Quit $$$OK
}

/// This is called before the actual load of data to give the chance
/// to load the item from an external format.
Method OnBeforeLoad(InternalName As %String) As %Status
{
	If ..Debug Write "Method 'OnBeforeLoad' InternalName:"_InternalName,!

	Set tType=##class(%ZScc.Utils).GetItemType(InternalName)
	If ##class(%ZScc.Utils).ItemCategory(tType)="project" Set ..CurrentProjectName=InternalName

	Quit $$$OK
}

Method AddProjectItems() As %Status
{
	if ..Debug Write "AddProjectItems.  Target:",..CurrentProjectName,!
	If '..IsInitialized  Quit '$$$OK

	//default projectは保存しない
	If $E(..CurrentProjectName,1,$L($$$DEFAULTPRJNAME))=$$$DEFAULTPRJNAME {
		Write $$$MSGNODEFAULTPRJ,!
		Quit '$$$OK
	}

	Set path=..LocalWorkspaceRoot_..GetExtraPath()
	Set tSC=##class(%ZScc.Utils).ExportProjectItems(..CurrentProjectName,path,..Debug)

	Quit tSC
}

Method AddNameSpaceItems() As %Status
{
	if ..Debug Write "AddNameSpaceItems.  Target:",$NAMESPACE,!
	If '..IsInitialized  Quit '$$$OK
	
	Set path=..LocalWorkspaceRoot_..GetExtraPath()
	Do ##class(%ZScc.Utils).ExportAllItems(path,..Debug)
	Quit $$$OK
}

Method OnMenuItem(MenuName As %String, InternalName As %String, SelectedText As %String, ByRef Enabled As %Boolean, ByRef DisplayName As %String) As %Status
{
	if ..Debug Write "Method 'OnMenuItem' MenuName:"_MenuName_" InternalName:"_InternalName_" SelectedText:"_SelectedText_" Enabled:"_Enabled_" DisplayName:"_DisplayName,!
	Set type=$P(MenuName,",",1)
	Set name=$P(MenuName,",",2)

	#;separator etc...
	If name="" Quit $$$OK
	
	Set menuid=..TranslateMenuNameToMenuID(MenuName,.DisplayName)
	if ..Debug Write "Method 'OnMenuItem' MenuId:"_menuid,!

	#;Disable all except 'Settings'
	If '..IsInitialized {
		If menuid'="settings" Set Enabled=0
	}
	If menuid="commiton" {
		If ..IsAutoCommitOn Set Enabled=0
		Else  Set Enabled=1
	}	
	ElseIf menuid="commitoff" {
		If ..IsAutoCommitOn Set Enabled=1
		Else  Set Enabled=0
	}	
	ElseIf menuid="commit" {
		If ..IsAutoCommitOn Set Enabled=0
		Else  Set Enabled=1
	}	
	ElseIf menuid="showcmdon" {
		If ..IsShowCommandOn Set Enabled=0
		Else  Set Enabled=1
	}	
	ElseIf menuid="showcmdoff" {
		If ..IsShowCommandOn Set Enabled=1
		Else  Set Enabled=0
	}	
	ElseIf menuid="pull" {
		If ..RepositoryRoot'="" Set Enabled=1
		Else  Set Enabled=0
	}	
	ElseIf menuid="push" {
		If ..RepositoryRoot'="" Set Enabled=1
		Else  Set Enabled=0
	}	
	
	Quit $$$OK
}

/// どのメニューを選択したかは表示名で返却される。その表示名を疑似的なIDに変換するためのロジック。
/// 今となっては不要。
Method TranslateMenuNameToMenuID(Name As %String, ByRef DisplayName As %String) As %String
{
	set tMenu=$zcvt($p($p(Name,",",2)," ",1),"L")

	If tMenu="settings" {Set DisplayName=$$$MENUSETTINGS}
	ElseIf tMenu="addpj" {Set DisplayName=$$$MENUADDPJ}
	ElseIf tMenu="addns" {Set DisplayName=$$$MENUADDNS }
	ElseIf tMenu="copytrunk" {Set DisplayName=$$$MENUCOPYTRUNK }
	ElseIf tMenu="checkout" {Set DisplayName=$$$MENUCHECKOUT   }
	ElseIf tMenu="checkout1" {Set DisplayName=$$$MENUCHECKOUT1   }
	ElseIf tMenu="checkout2" {Set DisplayName=$$$MENUCHECKOUT2   }
	ElseIf tMenu="import" {Set DisplayName=$$$MENUIMPALL   }
	ElseIf tMenu="import1" {Set DisplayName=$$$MENUIMP1   }
	ElseIf tMenu="commiton"  {Set DisplayName=$$$MENUENACOMMIT   }
	ElseIf tMenu="commitoff"  {Set DisplayName=$$$MENUDISACOMMIT }
	ElseIf tMenu="commit"  {Set DisplayName=$$$MENUCOMMIT }
	ElseIf tMenu="statusv"  {Set DisplayName=$$$MENUSTATUSV}
	ElseIf tMenu="statusv1"  {Set DisplayName=$$$MENUSTATUSV1}
	ElseIf tMenu="status"  {Set DisplayName=$$$MENUSTATUS}
	ElseIf tMenu="diff"  {Set DisplayName=$$$MENUDIFF}
	ElseIf tMenu="showcmdon"  {Set DisplayName=$$$MENUENASHOWCMD   }
	ElseIf tMenu="showcmdoff"  {Set DisplayName=$$$MENUDISASHOWCMD }
	ElseIf tMenu="test"  {Set DisplayName=$$$MENUTEST}
	ElseIf tMenu="dump" {Set DisplayName=$$$MENUDYMP}
	ElseIf tMenu="pull" {Set DisplayName=$$$MENUPULL}
	ElseIf tMenu="push" {Set DisplayName=$$$MENUPUSH}
	Else {Set tMenu=""}
	Quit tMenu
}

Method GetExtraPath() As %String
{
	Quit ..ConfigName_$$$FolderDelimiter_$NAMESPACE_$$$FolderDelimiter
}

/// accessor method for LocalWorspacePath property
Method GetLocalWorkspacePath(Branch As %String = "") As %String
{
	set tPath=..LocalWorkspaceRoot_..GetExtraPath()
	Quit tPath
}

Method GetLocalWorkspacePathConfig() As %String
{
	set tPath=..LocalWorkspaceRoot_..ConfigName_$$$FolderDelimiter
	Quit tPath
}

Method GetRepositoryPath() As %String
{
	Quit ""
}

Method CreateInitialRepositoryDir() As %Status
{
	Quit $$$OK
}

Method CreateRepositoryDir(DirectoryName As %String = "", Description As %String = "") As %Status
{
	Quit $$$OK
}

Method CheckOutDir(DirectoryName As %String = "", Repository As %String = "") As %Status
{
	Quit $$$OK
}

Method Add(FileName As %String = "", Description As %String = "") As %Status
{
	Quit $$$OK
}

Method Commit(FileName As %String = "", Description As %String = "") As %Status
{
	Quit $$$OK
}

Method Pull() As %Status
{
	Quit $$$OK
}

Method Push() As %Status
{
	Quit $$$OK
}

Method Status(FileName As %String = "") As %Status
{
	Quit $$$OK
}

Method CheckRepository(Repository As %String) As %Integer
{
	Quit $$$OK
}

ClassMethod IsDebugEnabled() As %Boolean
{
	Quit +$g(^SYS("SourceControl",$Parameter(,"PRODUCT"),"Debug"))=1
}

Method LocalWorkspaceRootGet() As %String
{
	Quit $g(^SYS("SourceControl",$Parameter(,"PRODUCT"),"LocalWorkspaceRoot"))
}

Method IsInitializedGet() As %Boolean
{
	M t=^SYS("SourceControl",$Parameter(,"PRODUCT"))
	//These items are essential
	If $g(t("LocalWorkspaceRoot"))=""  Quit '$$$OK
	Quit $$$OK
}

Method RepositoryRootGet() As %String
{
	Quit $g(^SYS("SourceControl",$Parameter(,"PRODUCT"),"RepositoryRoot"))
}

Method RemoteUserGet() As %String
{
	Quit $g(^SYS("SourceControl",$Parameter(,"PRODUCT"),"RemoteUser"))
}

Method RemotePasswordGet() As %String
{
	Quit $g(^SYS("SourceControl",$Parameter(,"PRODUCT"),"RemotePassword"))
}

Method DumpOutput(msg As %GlobalCharacterStream, tag As %String = "OUTPUT")
{
	#;message to a studio output window
	Write "<"_..#PRODUCT_":"_tag_">",!
	While('msg.AtEnd) {
			Set line=msg.ReadLine()
			If line'="" w line,!
		}
	Write "</"_..#PRODUCT_":"_tag_">",!
	Do msg.Rewind()
}

ClassMethod SampleSetup()
{
	Kill ^SYS("SourceControl",..#PRODUCT)
	Set ^SYS("SourceControl",..#PRODUCT,"Debug")=0
	Set ^SYS("SourceControl",..#PRODUCT,"LocalWorkspaceRoot")="\var\basic\work\"
}

}
