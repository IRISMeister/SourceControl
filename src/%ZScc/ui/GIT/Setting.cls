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
	&HTML<^SYS("SourceControl","#(..#PRODUCT)#","MainCommand")>
	&HTML<^SYS("SourceControl","#(..#PRODUCT)#","RemotePassword")  (optional)>
	&HTML<^SYS("SourceControl","#(..#PRODUCT)#","RemoteUser")      (optional)>
	&HTML<^SYS("SourceControl","#(..#PRODUCT)#","RepositoryRoot")  (optional)>

	&HTML<<br/>>
	&HTML<[現在の設定]>
	&HTML<^SYS("SourceControl","#(..#PRODUCT)#","LocalWorkspaceRoot")=#($G(^SYS("SourceControl",..#PRODUCT,"LocalWorkspaceRoot")))#>
	&HTML<^SYS("SourceControl","#(..#PRODUCT)#","MainCommand")=#($G(^SYS("SourceControl",..#PRODUCT,"MainCommand")))#>
	&HTML<^SYS("SourceControl","#(..#PRODUCT)#","RemotePassword")=#($G(^SYS("SourceControl",..#PRODUCT,"RemotePassword")))#>
	&HTML<^SYS("SourceControl","#(..#PRODUCT)#","RemoteUser")=#($G(^SYS("SourceControl",..#PRODUCT,"RemoteUser")))#>
	&HTML<^SYS("SourceControl","#(..#PRODUCT)#","RepositoryRoot")=#($G(^SYS("SourceControl",..#PRODUCT,"RepositoryRoot")))#>

	&HTML<<br/>>
	&HTML<[設定例]>

	If $$$ISWINDOWS {
		&HTML<Set ^SYS("SourceControl","#(..#PRODUCT)#","LocalWorkspaceRoot")="c:\var\git\">
	}
	Else {
		&HTML<Set ^SYS("SourceControl","#(..#PRODUCT)#","LocalWorkspaceRoot")="/home/irisusr/git/">
	}
	&HTML<Set ^SYS("SourceControl","#(..#PRODUCT)#","MainCommand")="git">
	/*
	&HTML<Set ^SYS("SourceControl","#(..#PRODUCT)#","RemotePassword")="xxxxx">
	&HTML<Set ^SYS("SourceControl","#(..#PRODUCT)#","RemoteUser")="xxxx">
	&HTML<Set ^SYS("SourceControl","#(..#PRODUCT)#","RepositoryRoot")="http://centos7.mydomain/">
	*/
	
	&HTML<</PRE>>
	&HTML<設定例の値を使用するならボタンを押してください。押下後、スタジオを再起動してください。>
	&HTML<<input type="button" value="設定例の値で初期化" onClick='onServer()'>>

	Write "</body>"
}

}
