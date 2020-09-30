Class %ZScc.ui.SVN.Setting Extends %ZScc.ui.Basic.Setting
{

Parameter PRODUCT = "SVN";

ClassMethod OnPageBODY() As %Boolean
{
	Write "<body>"
	Write !,!,"		"
	Write "<!-- Put your page code here -->"
	&HTML<<PRE>>
	&HTML<下記のグローバルを対象ネームスペース上に手動で設定してください。>
	&HTML<^SYS("SourceControl","#(..#PRODUCT)#","LocalWorkspaceRoot")>
	&HTML<^SYS("SourceControl","#(..#PRODUCT)#","RepositoryRoot")>
	&HTML<^SYS("SourceControl","#(..#PRODUCT)#","MainCommand")>

	&HTML<<br/>>
	&HTML<[現在の設定]>
	&HTML<^SYS("SourceControl","#(..#PRODUCT)#","LocalWorkspaceRoot")=#($G(^SYS("SourceControl",..#PRODUCT,"LocalWorkspaceRoot")))#>
	&HTML<^SYS("SourceControl","#(..#PRODUCT)#","RepositoryRoot")=#($G(^SYS("SourceControl",..#PRODUCT,"RepositoryRoot")))#>
	&HTML<^SYS("SourceControl","#(..#PRODUCT)#","MainCommand")=#($G(^SYS("SourceControl",..#PRODUCT,"MainCommand")))#>

	&HTML<<br/>>
	&HTML<[設定例]>
	&HTML<Set ^SYS("SourceControl","#(..#PRODUCT)#","Debug")=0>
	&HTML<Set ^SYS("SourceControl","#(..#PRODUCT)#","LocalWorkspaceRoot")="c:\var\svn\work\">
	&HTML<Set ^SYS("SourceControl","#(..#PRODUCT)#","RepositoryRoot")="file:///var/svn/repos/">
	&HTML<Set ^SYS("SourceControl","#(..#PRODUCT)#","MainCommand")="C:\""Program Files""\SlikSvn\bin\svn.exe">

	&HTML<</PRE>>
	&HTML<設定例の値を使用するならボタンを押してください。押下後、スタジオを再起動してください。>
	&HTML<<input type="button" value="設定例の値で初期化" onClick='onServer()'>>

	Write "</body>"
}

}
