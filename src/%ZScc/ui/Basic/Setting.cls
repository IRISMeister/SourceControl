Include %sySite

Class %ZScc.ui.Basic.Setting Extends %CSP.Page
{

Parameter PRODUCT = "Basic";

ClassMethod OnPage() As %Status
{
	Do ..OnPageCSPROOT()
	Quit $$$OK
}

ClassMethod OnPageBODY() As %Boolean
{
	Write "<body>"
	Write !,!,"		"
	Write "<!-- Put your page code here -->"
	&HTML<<PRE>>
	&HTML<下記のグローバルを対象ネームスペース上に手動で設定してください。>
	&HTML<^ZScc("#(..#PRODUCT)#","LocalWorkspaceRoot")>
	&HTML<^ZScc("#(..#PRODUCT)#","Src")>

	&HTML<<br/>>
	&HTML<[現在の設定]>
	&HTML<^ZScc("#(..#PRODUCT)#","LocalWorkspaceRoot")=#($G(^ZScc(..#PRODUCT,"LocalWorkspaceRoot")))#>
	&HTML<^ZScc("#(..#PRODUCT)#","Src")=#($G(^ZScc(..#PRODUCT,"Src")))#>

	&HTML<<br/>>
	&HTML<[設定例]>
	&HTML<Set ^ZScc("#(..#PRODUCT)#","Debug")=0>
	If $$$ISWINDOWS {
		&HTML<Set ^ZScc("#(..#PRODUCT)#","LocalWorkspaceRoot")="c:\var\basic\Project_XYZ\">
	}
	Else {
		&HTML<Set ^ZScc("#(..#PRODUCT)#","LocalWorkspaceRoot")="/home/irisusr/basic/Project_XYZ/">
	}
	&HTML<Set ^ZScc("#(..#PRODUCT)#","Src")="src">
	&HTML<</PRE>>
	&HTML<設定例の値を使用するならボタンを押してください。押下後、スタジオを再起動してください。>
	&HTML<<input id="btn" name="btn" type="button" value="設定例の値で初期化" onClick='onServer()'>>
	Write "</body>"
}

ClassMethod AcceptDefault() As %Status
{
	Do $CLASSMETHOD("%ZScc."_..#PRODUCT,"SampleSetup")
	Set %session.EndSession=1
	Quit $$$OK
}

ClassMethod OnPageCSPROOT() As %Boolean
{
	Do ..OnPageHTML()
}

ClassMethod OnPageHEAD() As %Boolean
{
 &html<
   <head>
   <script language=javascript>
   function onServer()
   {
      var value = #server(..AcceptDefault())#;
      //There seems no way to disable it from Studio.
      //document.getElementById("btn").disabled=true;
      if (value == 1) alert('done');
      else { alert('Unexpected Error'); }
   }
   </script>
   #(..HyperEventHead())#
   </head>
   >
}

ClassMethod OnPageHTML() As %Boolean
{
	Write "<html>"
	Write !
	Do ..OnPageHEAD()
	Write !,!
	Do ..OnPageBODY()
	Write !,"</html>"
}

}
