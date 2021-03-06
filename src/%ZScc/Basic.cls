Include (%sySite, %ZScc.Constants)

Class %ZScc.Basic Extends %Studio.SourceControl.Base
{

Parameter PRODUCT = "Basic";

/// ^ZSccへの定義が済んでいるか？
Property IsInitialized As %Boolean [ Calculated ];

/// 自動commitは有効か？
Property IsAutoCommitOn As %Boolean [ Calculated ];

/// 自動Repo作成は有効か？
Property IsAutoCreateRepoOn As %Boolean [ Calculated ];

/// ShowCommandは有効か？
Property IsShowCommandOn As %Boolean [ InitialExpression = 0 ];

Property IsStdImportInProgress As %Boolean [ InitialExpression = 0 ];

/// Cache Config Name such as 'CACHE'
Property ConfigName As %String [ Calculated ];

Property CurrentProjectName As %String;

Property ExternalName As %String;

Property LocalWorkspaceRoot As %String [ Calculated ];

Property RemoteRepository As %String [ Calculated ];

Property Branch As %String [ InitialExpression = "master" ];

Property RemoteUser As %String [ Calculated ];

Property RemotePassword As %String [ Calculated ];

Property Debug As %Boolean [ Calculated ];

Property Src As %String [ Calculated ];

Parameter USERACTIONNAME = "tried to change a document that is locked in source control;created a new document;deleted a document;opened a document;closed a document;connected to a new namespace";

XData Menu
{
<MenuBase>
<Menu Name="%SourceMenu" Type="0">
<MenuItem Name="settings" />
<MenuItem Separator="1"/> 
<MenuItem Name="addpj" />
<MenuItem Name="addns" />
<MenuItem Name="add1" />
<MenuItem Name="importall" />
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
		Write "Method 'UserAction' Type:"_Type_" Name:"_tName_" InternalName:"_InternalName_" SelectedText:"_SelectedText_" Action:"_$G(Action)_" Target:"_$G(Target)_" Msg:"_$G(Msg)_" Reload:"_$G(Reload),!
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
				w " ******************************************************************************************",!
				w " >>> ^ZSccグローバルの設定が行われていません。                                           ",!
				w " >>> 設定メニューを使用するか、直接グローバルのセットを行い設定を完了してください。      ",!		
				w " >>> 設定の有効化のため、スタジオを再起動、もしくはネームスペース切り替えを行ってください。",!		
				w " ******************************************************************************************",!
				#;2014-09-25
				#;Quit '$$$OK
				Quit $$$OK
		}

		If ..Debug { 
			Set ..IsShowCommandOn=1 
			Write "IsAutoCommitOn="_..IsAutoCommitOn,!
			Write "IsAutoCreateRepoOn="_..IsAutoCreateRepoOn,!
			Write "Checking root work directory since this is the first connect by this studio instance.",!
		}
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
			#; Fails if Default App is not CSP-Application Enabled or doesn't exist.
			set Action=$$$ACTIONRUNCSP
			Set Target=$system.CSP.GetDefaultApp($NAMESPACE)_"/%25ZScc.ui."_$Parameter(,"PRODUCT")_".Setting.cls"			
		} elseif menuID="addpj" {
			set Action=$$$ACTIONSIMPLEDIALOG
			set Target=$$$USERACTMSGADDPJ
		} elseif menuID="addns" {
			set Action=$$$ACTIONSIMPLEDIALOG
			set Target=$$$USERACTMSGADDNS
		} elseif menuID="add1" {
			set Action=$$$ACTIONSIMPLEDIALOG
			set Target=$$$USERACTMSGADD1
		} elseif menuID="checkout" {
			set Action=$$$ACTIONSIMPLEDIALOG
			set Target=$$$USERACTMSGCO
		} elseif menuID="checkout1" {
			set Action=$$$ACTIONSIMPLEDIALOG
			set Target=$$$USERACTMSGCO1
		} elseif menuID="checkout2" {
			set Action=$$$ACTIONSIMPLEDIALOG
			set Target=$$$USERACTMSGCO2
		} elseif menuID="importall" {
			set Action=$$$ACTIONSIMPLEDIALOG
			set Target=$$$USERACTMSGIMPORTALL
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
			w "ConfigName: ",..ConfigName,!
			w "Debug: ",..Debug,!
			w "IsAutoCommitOn: ",..IsAutoCommitOn,!
			w "IsAutoCreateRepoOn: ",..IsAutoCreateRepoOn,!
			w "IsInitialized: ",..IsInitialized,!
			w "LocalWorkspaceRoot: ",..LocalWorkspaceRoot,!
			w "RemotePassword: ",..RemotePassword,!
			w "RemoteUser: ",..RemoteUser,!
			w "RemoteRepository: ",..RemoteRepository,!
			w "Src: ",..Src,!

			w "CurrentProjectName: ",..CurrentProjectName,!
			w "GetLocalWorkspacePath(): ",..GetLocalWorkspacePath(),!
			w "GetExtraPath(): ",..GetExtraPath(),!
			w "GetRepositoryPath(): ",..GetRepositoryPath(),!
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
	Set sts=##class(%File).DirectoryExists(..LocalWorkspaceRoot)
	If 'sts {
		If ..Debug w "Creating directory ",..LocalWorkspaceRoot,!
		Set tSC=##class(%File).CreateDirectoryChain(..LocalWorkspaceRoot,.ret)
		If ..Debug w "Status:"_tSC,!
		Quit $$$OK
	}
	else {
		If ..Debug w "Directory ",..LocalWorkspaceRoot," Already exist",!
		Quit '$$$OK
	}
}

Method OnAfterSave(InternalName As %String, Object As %RegisteredObject = {$$$NULLOREF}) As %Status
{
	if ..Debug Write "Method 'OnAfterSave(Basic)' InternalName:"_InternalName_" Object: "_Object,!
	//DBへの保存は成功させたいのでOKを返す
	If '..IsInitialized  Quit $$$OK

	//project保存の際、現在のCurrentProjectPathと一致しない場合は保存しない
	//Projectを「名前を付けて保存」した際に発生
	If ##class(%ZScc.Utils).GetItemType(InternalName)="prj" {
		If ##class(%ZScc.Utils).GetItemName(InternalName)'=..CurrentProjectName {
			Write "Project Name doesn't match. InternalName:"_InternalName_" CurrentProjectName:"_..CurrentProjectName,!
			Quit $$$OK
		}	
	}

	//default project自体は保存しない
	If $E(InternalName,1,$L($$$DEFAULTPRJNAME))=$$$DEFAULTPRJNAME {
		W $$$MSGNODEFAULTPRJ,!
		Quit $$$OK
	}	

	Set path=..GetLocalWorkspacePath()
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
	If ..Debug Write "Method 'AfterUserAction(Basic)' Type:"_Type_" Name:"_Name_" InternalName:"_InternalName_" Answer:"_Answer_" Msg:"_Msg_" Reload:"_$G(Reload),!

	if Type=$$$ACTIONTYPEMENU {
		Set menuID=..TranslateMenuNameToMenuID(Name)
		If menuID="importall" { //import all from workspace
			If Answer'=$$$YES Quit $$$OK
			Set dire=..GetLocalWorkspacePath()
			If ##class(%File).Exists(dire) {
				Do $SYSTEM.OBJ.ImportDir(dire,"*.mac;*.cls;*.xml;*.inc","ck",.e,1)
				zw e
			}
			Else { Quit '$$$OK }

		} 
		ElseIf menuID="import1" { //import an item from workspace
			If Answer'=$$$YES Quit $$$OK
			If InternalName'="" {
				Set path=..GetLocalWorkspacePath()
				Set file=##class(%ZScc.Utils).ExternalName(InternalName,path)
				Do $System.OBJ.Load(file,"ck")
			}
			Else {
				W $$$USERACTMSGSTATUS1,!
			}
		}
		ElseIf menuID="addns" { 
			If Answer'=$$$YES Quit $$$OK
			Do ..AddNameSpaceItems()
		}
		ElseIf menuID="addpj" { 
			If Answer'=$$$YES Quit $$$OK
			Do ..AddProjectItems()
		}
		ElseIf menuID="add1" { //
			If Answer'=$$$YES Quit $$$OK
			If InternalName'="" {
				Do ..Add1Item(InternalName)
			}
			Else {
				w $$$USERACTMSGSTATUS1,!
			}
		}
	}

	Quit $$$OK
}

/// This is called before the actual load of data to give the chance
/// to load the item from an external format.
Method OnBeforeLoad(InternalName As %String) As %Status
{
	If ..Debug Write "Method 'OnBeforeLoad(Basic)' InternalName:"_InternalName,!

	Set tType=##class(%ZScc.Utils).GetItemType(InternalName)
	If ##class(%ZScc.Utils).ItemCategory(tType)="project" Set ..CurrentProjectName=$P(InternalName,".PRJ",1)

	Quit $$$OK
}

Method AddProjectItems() As %Status
{
	if ..Debug Write "AddProjectItems.  Target:",..CurrentProjectName,!
	If '..IsInitialized  Quit '$$$OK

	Set path=..GetLocalWorkspacePath()
	Set tSC=##class(%ZScc.Utils).ExportProjectItems(..CurrentProjectName,path,..Debug)
	w $$$USERACTMSGEXPORTPRJDONE,!
	Quit tSC
}

Method AddNameSpaceItems() As %Status
{
	if ..Debug Write "AddNameSpaceItems.  Target:",$NAMESPACE,!
	If '..IsInitialized  Quit '$$$OK
	
	Set path=..GetLocalWorkspacePath()
	Do ##class(%ZScc.Utils).ExportAllItems(path,..Debug)
	W $$$USERACTMSGEXPORTALLDONE,!
	Quit $$$OK
}

Method Add1Item(InternalName As %String) As %Status
{
	if ..Debug Write "Add1Item.  Target:",..CurrentProjectName,!
	If '..IsInitialized  Quit '$$$OK

	Set path=..GetLocalWorkspacePath()
	Set tSC=##class(%ZScc.Utils).ExportSingleItem(InternalName,path,..Debug)
	w $$$USERACTMSGEXPORT1DONE,!
	Quit tSC
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
		If '..IsInitialized { Set Enabled=0 }
		Else {
			If ..IsAutoCommitOn Set Enabled=0
			Else  Set Enabled=1
		}
	}	
	ElseIf menuid="commitoff" {
		If '..IsInitialized { Set Enabled=0 }
		Else {
			If ..IsAutoCommitOn Set Enabled=1
			Else  Set Enabled=0
		}
	}	
	ElseIf menuid="commit" {
		If '..IsInitialized { Set Enabled=0 }
		Else {
			If ..IsAutoCommitOn Set Enabled=0
			Else  Set Enabled=1
		}
	}	
	ElseIf menuid="showcmdon" {
		If '..IsInitialized { Set Enabled=0 }
		Else {
			If ..IsShowCommandOn Set Enabled=0
			Else  Set Enabled=1
		}
	}	
	ElseIf menuid="showcmdoff" {
		If '..IsInitialized { Set Enabled=0 }
		Else {
			If ..IsShowCommandOn Set Enabled=1
			Else  Set Enabled=0
		}
	}	
	ElseIf menuid="pull" {
		If ..RemoteRepository'="" Set Enabled=1
		Else  Set Enabled=0
	}	
	ElseIf menuid="push" {
		If ..RemoteRepository'="" Set Enabled=1
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
	ElseIf tMenu="add1" {Set DisplayName=$$$MENUADD1 }
	ElseIf tMenu="copytrunk" {Set DisplayName=$$$MENUCOPYTRUNK }
	ElseIf tMenu="checkout" {Set DisplayName=$$$MENUCHECKOUT   }
	ElseIf tMenu="checkout1" {Set DisplayName=$$$MENUCHECKOUT1   }
	ElseIf tMenu="checkout2" {Set DisplayName=$$$MENUCHECKOUT2   }
	ElseIf tMenu="importall" {Set DisplayName=$$$MENUIMPALL   }
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
	Quit ..Src_$$$FolderDelimiter
}

Method GetLocalWorkspacePath() As %String
{
	set tPath=..LocalWorkspaceRoot_..GetExtraPath()
	Quit tPath
}

Method GetRepositoryPath() As %String
{
	Quit ""
}

Method GetRemoteRepositoryPath() As %String
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

Method CheckRemoteRepository(Repository As %String) As %Integer
{
	Quit $$$OK
}

Method IsAutoCreateRepoOnGet() As %Boolean
{
	Quit +$g(^ZScc($Parameter(,"PRODUCT"),"AutoCreateRepo"))=1
}

Method IsAutoCommitOnGet() As %Boolean
{
	Quit +$g(^ZScc($Parameter(,"PRODUCT"),"AutoCommit"))=1
}

Method IsAutoCommitOnSet(val As %Boolean) As %Status
{
	Set ^ZScc($Parameter(,"PRODUCT"),"AutoCommit")=val
}

Method LocalWorkspaceRootGet() As %String
{
	Quit $g(^ZScc($Parameter(,"PRODUCT"),"LocalWorkspaceRoot"))
}

Method SrcGet() As %String
{
	Quit $g(^ZScc($Parameter(,"PRODUCT"),"Src"),"src")
}

Method IsInitializedGet() As %Boolean
{
	M t=^ZScc($Parameter(,"PRODUCT"))
	//These items are essential
	If $g(t("LocalWorkspaceRoot"))=""  Quit '$$$OK
	If $g(t("Src"))=""  Quit '$$$OK
	Quit $$$OK
}

Method RemoteRepositoryGet() As %String
{
	Quit $g(^ZScc($Parameter(,"PRODUCT"),"RemoteRepository"))
}

Method RemoteUserGet() As %String
{
	Quit $g(^ZScc($Parameter(,"PRODUCT"),"RemoteUser"))
}

Method RemotePasswordGet() As %String
{
	Quit $g(^ZScc($Parameter(,"PRODUCT"),"RemotePassword"))
}

Method DebugGet() As %String
{
	Quit +$g(^ZScc($Parameter(,"PRODUCT"),"Debug"))=1
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
	Kill ^ZScc(..#PRODUCT)
	If $$$ISWINDOWS { Set root="c:\var\basic\Project_XYZ\" } Else { Set root="/home/irisusr/basic/Project_XYZ/"}
	Set ^ZScc(..#PRODUCT,"LocalWorkspaceRoot")=root
	Set ^ZScc(..#PRODUCT,"Src")="src"
}

}
