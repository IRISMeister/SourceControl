ROUTINE %ZScc.Constants [Type=INC]
#Include %sySite

#DEFINE ACTIONDONOTHING 0
#DEFINE ACTIONSIMPLEDIALOG 1
#DEFINE ACTIONRUNCSP 2
#DEFINE ACTIONALERTDIALOG 6
#DEFINE ACTIONTEXTDIALOG 7


 #DEFINE ACTIONTYPEMENU  0
 #DEFINE ACTIONTYPEOTHER  1


#;    0 : User has tried to change a document that is locked in source control
#;    1 : User has created a new document
#;    2 : User has deleted a document
#;    3 : User has opened a document
#;    4 : User has closed a document
#;    5 : User has connected to a new namespace
#;    6 : User has selected to import comma delimetered list of documents
#;    7 : User has saved a new document for the first time
#DEFINE ACTIONOTHERCONNECT 5
#DEFINE ACTIONOTHERIMPORT 6
    

#DEFINE FolderDelimiter	$s($$$ISWINDOWS:"\",1:"/")
#DEFINE URLDelimiter	"/" 

#DEFINE DEFAULTPRJNAME "Default_"
#DEFINE CSPEXPORTTGT "*.csp;*.csr;*.css;*.js"
 /* 
#DEFINE MENUSETTINGS "Settings"
#DEFINE MENUADDPJ "Add Project files to Subversion"
#DEFINE MENUADDNS "Add NameSpace files to Subversion"
#DEFINE MENUCOPYTRUNK "Copy trunk to specified tag"
#DEFINE MENUIMPALL "Import all items from work directory"
#DEFINE MENUIMP1 "Import a current item from work directory"
#DEFINE MENUENACOMMIT "Enable Auto Commit Mode"
#DEFINE MENUDISACOMMIT "Disable Auto Commit Mode"
#DEFINE MENUCOMMIT "Commit"
#DEFINE MENUTEST "Test"
#DEFINE MENUDYMP "Dump Settings"
#DEFINE MENUPULL "Pull from remote"
#DEFINE MENUPUSH "Push to remote"
 */
#DEFINE MENUSETTINGS "設定"
#DEFINE MENUADDPJ "プロジェクトをレポジトリに追加"
#DEFINE MENUADDNS "ネームスペースをレポジトリに追加"
#DEFINE MENUCOPYTRUNK "trunkを指定のTAGにコピー"
#DEFINE MENUCHECKOUT "レポジトリからワークに全てのアイテムをチェックアウト"
#DEFINE MENUCHECKOUT1 "チェックアウト"
#DEFINE MENUCHECKOUT2 "ブランチ切り替え"
#DEFINE MENUIMPALL "ワークからすべてのアイテムをインポート"
#DEFINE MENUIMP1 "ワークから現在のアイテムをインポート"
#DEFINE MENUENACOMMIT "自動コミットを有効化"
#DEFINE MENUDISACOMMIT "自動コミットを無効化"
#DEFINE MENUSTATUS "ステータス表示"
#DEFINE MENUSTATUSV "ステータス表示(verbose)"
#DEFINE MENUSTATUSV1 "現在のアイテムのステータス表示(verbose)"
#DEFINE MENUDIFF "ワークとレポジトリのdiff"
#DEFINE MENUCOMMIT "コミット実行"
#DEFINE MENUENASHOWCMD "コマンドを表示"
#DEFINE MENUDISASHOWCMD "コマンドを非表示"
#DEFINE MENUTEST "テスト"
#DEFINE MENUDYMP "設定のダンプ"
#DEFINE MENUPULL "リモートからプル"
#DEFINE MENUPUSH "リモートにプッシュ"

#DEFINE USERACTMSGCO "レポジトリからワークに全てのアイテムをチェックアウトします。実行しますか？"
#DEFINE USERACTMSGCO1 "ワークに現在のアイテムをチェックアウトします。実行しますか？"
#DEFINE USERACTMSGCO2 "ブランチを切り替えます。実行しますか？"
#DEFINE USERACTMSGIMPORTALL "ワークの全内容をロードします。レポジトリに影響は与えません。"_$C(13,10)_"実行しますか？"
#DEFINE USERACTMSGIMPORT1 "選択中の項目のみをワークからロードします。レポジトリに影響は与えません。"_$C(13,10)_"実行しますか？"
#DEFINE USERACTMSGCOMMITON "自動コミットを有効にしました。"
#DEFINE USERACTMSGCOMMITOFF "自動コミットを無効にしました。保存時にコミットされなくなります。明示的にコミットを実行してください。"
#DEFINE USERACTMSGSTATUS1 "アイテムが選択されていません。"
#DEFINE USERACTMSGTEST "Test selected. Nothing to do."
#DEFINE USERACTMSGPUSHFAIL "Pushに失敗しました。"
#DEFINE USERACTMSGPULLFAIL "Pullに失敗しました。"
#DEFINE USERACTMSGNYI "Not Yet Implemented. "

#DEFINE USERACTMSGEXPORTALLDONE "ネームスペースの内容をワークディレクトリに出力しました。"
#DEFINE USERACTMSGEXPORTPRJDONE "プロジェクトの内容をワークディレクトリに出力しました。"

 //#DEFINE MSGNODEFAULTPRJ "Warning !!! Default project will not be source controled."
#DEFINE MSGNODEFAULTPRJ "デフォルトプロジェクトはソース管理の対象になりません。"

 //SVN specific MACROs
#DEFINE SVNERRRALOCALREPOSOPENFAILED "E180001"
#DEFINE SVNERR1 "E730061"

#DEFINE DUMPCOMMAND(%x) If ..IsShowCommandOn Write %x,!
#DEFINE DUMPRESULT(%x) If ..IsShowCommandOn {Do ..DumpOutput(%x)}
#;From original source
  
#define PRODUCT 	"SVN"
#define FULLPATH	1
#define NOPATH		0
#define CANNOTEXECUTECOMMAND	-10001
 
#define YES			1
#define	NO			0
#define CANCEL		2
	// settings
#define CMDAUTODELETECOMMIT	+$g(^ZScc($$$PRODUCT,"AutoDeleteCommit")) 
#define	CHECKSTATUS			set Action=6 set err="" d $System.Status.DecomposeStatus(tSC,.err) set Target=err(err)	
 
#define SPACE	" " 
#define DEBUG(%var)	If ..Debug s ^ZScc.Debug($i(^ZScc.Debug))=%var
 