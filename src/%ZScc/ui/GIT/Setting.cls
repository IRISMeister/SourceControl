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
	&HTML<^ZScc("#(..#PRODUCT)#","LocalWorkspaceRoot")>
	&HTML<^ZScc("#(..#PRODUCT)#","Src")>
	&HTML<^ZScc("#(..#PRODUCT)#","Debug")>
	&HTML<^ZScc("#(..#PRODUCT)#","MainCommand")>
	&HTML<^ZScc("#(..#PRODUCT)#","AutoCommit")>
	&HTML<^ZScc("#(..#PRODUCT)#","AutoCreateRepo")>
	&HTML<^ZScc("#(..#PRODUCT)#","RemotePassword")  (optional)>
	&HTML<^ZScc("#(..#PRODUCT)#","RemoteUser")      (optional)>
	&HTML<^ZScc("#(..#PRODUCT)#","RemoteRepository")  (optional)>

	&HTML<<br/>>
	&HTML<[現在の設定]>
	&HTML<^ZScc("#(..#PRODUCT)#","LocalWorkspaceRoot")=#($G(^ZScc(..#PRODUCT,"LocalWorkspaceRoot")))#>
	&HTML<^ZScc("#(..#PRODUCT)#","Src")=#($G(^ZScc(..#PRODUCT,"Src")))#>
	&HTML<^ZScc("#(..#PRODUCT)#","Debug")=#($G(^ZScc(..#PRODUCT,"Debug")))#>
	&HTML<^ZScc("#(..#PRODUCT)#","MainCommand")=#($G(^ZScc(..#PRODUCT,"MainCommand")))#>
	&HTML<^ZScc("#(..#PRODUCT)#","AutoCommit")=#($G(^ZScc(..#PRODUCT,"AutoCommit")))#>
	&HTML<^ZScc("#(..#PRODUCT)#","AutoCreateRepo")=#($G(^ZScc(..#PRODUCT,"AutoCreateRepo")))#>
	&HTML<^ZScc("#(..#PRODUCT)#","RemotePassword")=#($G(^ZScc(..#PRODUCT,"RemotePassword")))#>
	&HTML<^ZScc("#(..#PRODUCT)#","RemoteUser")=#($G(^ZScc(..#PRODUCT,"RemoteUser")))#>
	&HTML<^ZScc("#(..#PRODUCT)#","RemoteRepository")=#($G(^ZScc(..#PRODUCT,"RemoteRepository")))#>

	&HTML<<br/>>
	&HTML<[設定例]>

	If $$$ISWINDOWS {
		&HTML<Set ^ZScc("#(..#PRODUCT)#","LocalWorkspaceRoot")="c:\var\git\Project_XYZ\">
	}
	Else {
		&HTML<Set ^ZScc("#(..#PRODUCT)#","LocalWorkspaceRoot")="/home/irisusr/git/Project_XYZ/">
	}
	&HTML<Set ^ZScc("#(..#PRODUCT)#","Src")="src">
	&HTML<Set ^ZScc("#(..#PRODUCT)#","AutoCommit")=0>
	&HTML<Set ^ZScc("#(..#PRODUCT)#","AutoCreateRepo")=0>
	/*
	&HTML<Set ^ZScc("#(..#PRODUCT)#","RemotePassword")="xxxxx">
	&HTML<Set ^ZScc("#(..#PRODUCT)#","RemoteUser")="xxxx">
	&HTML<Set ^ZScc("#(..#PRODUCT)#","RemoteRepository")="http://centos7.mydomain/">
	*/
	
	&HTML<</PRE>>
	&HTML<設定例の値を使用するならボタンを押してください。押下後、スタジオを再起動してください。>
	&HTML<<input type="button" value="設定例の値で初期化" onClick='onServer()'>>

	Write "</body>"
}

}
