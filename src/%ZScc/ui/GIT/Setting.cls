Class %ZScc.ui.GIT.Setting Extends %ZScc.ui.Basic.Setting
{

Parameter PRODUCT = "GIT";

ClassMethod OnPageBODY() As %Boolean
{
	Write "<body>"
	Write !,!,"		"
	Write "<!-- Put your page code here -->"
	&HTML<<PRE>>
	&HTML<下記のグローバルを対象ネームスペース上に手動で設定してください。>
	&HTML<^SYS("SourceControl","#(..#PRODUCT)#","LocalWorkspaceRoot")>
	&HTML<^SYS("SourceControl","#(..#PRODUCT)#","Src")>
	&HTML<^SYS("SourceControl","#(..#PRODUCT)#","MainCommand")>
	&HTML<^SYS("SourceControl","#(..#PRODUCT)#","AutoCommit")>
	&HTML<^SYS("SourceControl","#(..#PRODUCT)#","AutoCreateRepo")>
	&HTML<^SYS("SourceControl","#(..#PRODUCT)#","RemotePassword")  (optional)>
	&HTML<^SYS("SourceControl","#(..#PRODUCT)#","RemoteUser")      (optional)>
	&HTML<^SYS("SourceControl","#(..#PRODUCT)#","RemoteRepository")  (optional)>

	&HTML<<br/>>
	&HTML<[現在の設定]>
	&HTML<^SYS("SourceControl","#(..#PRODUCT)#","LocalWorkspaceRoot")=#($G(^SYS("SourceControl",..#PRODUCT,"LocalWorkspaceRoot")))#>
	&HTML<^SYS("SourceControl","#(..#PRODUCT)#","Src")=#($G(^SYS("SourceControl",..#PRODUCT,"Src")))#>
	&HTML<^SYS("SourceControl","#(..#PRODUCT)#","MainCommand")=#($G(^SYS("SourceControl",..#PRODUCT,"MainCommand")))#>
	&HTML<^SYS("SourceControl","#(..#PRODUCT)#","AutoCommit")=#($G(^SYS("SourceControl",..#PRODUCT,"AutoCommit")))#>
	&HTML<^SYS("SourceControl","#(..#PRODUCT)#","AutoCreateRepo")=#($G(^SYS("SourceControl",..#PRODUCT,"AutoCreateRepo")))#>
	&HTML<^SYS("SourceControl","#(..#PRODUCT)#","RemotePassword")=#($G(^SYS("SourceControl",..#PRODUCT,"RemotePassword")))#>
	&HTML<^SYS("SourceControl","#(..#PRODUCT)#","RemoteUser")=#($G(^SYS("SourceControl",..#PRODUCT,"RemoteUser")))#>
	&HTML<^SYS("SourceControl","#(..#PRODUCT)#","RemoteRepository")=#($G(^SYS("SourceControl",..#PRODUCT,"RemoteRepository")))#>

	&HTML<<br/>>
	&HTML<[設定例]>

	If $$$ISWINDOWS {
		&HTML<Set ^SYS("SourceControl","#(..#PRODUCT)#","LocalWorkspaceRoot")="c:\var\git\Project_XYZ\">
	}
	Else {
		&HTML<Set ^SYS("SourceControl","#(..#PRODUCT)#","LocalWorkspaceRoot")="/home/irisusr/git/Project_XYZ/">
	}
	&HTML<Set ^SYS("SourceControl","#(..#PRODUCT)#","Src")="src">
	&HTML<Set ^SYS("SourceControl","#(..#PRODUCT)#","MainCommand")="git">
	&HTML<Set ^SYS("SourceControl","#(..#PRODUCT)#","AutoCommit")=0>
	&HTML<Set ^SYS("SourceControl","#(..#PRODUCT)#","AutoCreateRepo")=0>
	/*
	&HTML<Set ^SYS("SourceControl","#(..#PRODUCT)#","RemotePassword")="xxxxx">
	&HTML<Set ^SYS("SourceControl","#(..#PRODUCT)#","RemoteUser")="xxxx">
	&HTML<Set ^SYS("SourceControl","#(..#PRODUCT)#","RemoteRepository")="http://centos7.mydomain/">
	*/
	
	&HTML<</PRE>>
	&HTML<設定例の値を使用するならボタンを押してください。押下後、スタジオを再起動してください。>
	&HTML<<input type="button" value="設定例の値で初期化" onClick='onServer()'>>

	Write "</body>"
}

}
