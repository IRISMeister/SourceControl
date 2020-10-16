# SourceControl
IRIS用ソースコントロールフック

## 導入方法
1. Linuxであればaptやyumで、Windowsであれば、git for windowsをインストールします。
Windowsの場合、git.exeにPATHを通す選択(Use Git from the Windows Command Promp)をしてください。
2. IRISのソースコード一式をインポートします。
```bash
$ git clone https://github.com/IRISMeister/SourceControl.git
$ cd SourceControl
```
Linux
```
$ iris session iris -U %SYS
%SYS>d $SYSTEM.OBJ.ImportDir($SYSTEM.Util.GetEnviron("PWD")_"/src","*","ck",,1)
```
Windows  
ターミナル起動。第1引数(パス)を適宜変更のこと。
```
%SYS>d $SYSTEM.OBJ.ImportDir("c:\temp\SourceControl\src","*","ck",,1)
```

ソースコード管理の設定画面は下記のようにCSPページにアクセスします。
```ObjectScript
	Set Target=$system.CSP.GetDefaultApp($NAMESPACE)_"/%25ZScc.ui."_$Parameter(,"PRODUCT")_".Setting.cls"			
```
例えばネームスペースMYAPPに/csp/myappが存在しない、もしくは存在してもRESTアクセス用であった場合、設定画面の表示に失敗します。設定画面の表示は必須ではありませんので、その場合、直接グローバルへの設定を行ってください。

## 提供される機能
2種類のソースコントロールフックを提供します。
1. %ZScc.Basic
- ソースコードの保存時にその内容を指定したワークディレクトリにUDL形式で出力します。 
- パッケージ名をフォルダ構造に展開します。
- ネームスペース内のソースコード、スタジオプロジェクトに追加された項目をワークディレクトリにエクスポートします。
- ワークディレクトリの内容をインポートします。
- MAC, INT, INC, CLS, PRJ, BPM, DTLを識別します。
-  各種メニューを提供します。

|メニューアイテム名|メニュー表示|用途・補足|
|:--|:--|:--|
||設定|初期設定の実施|
||プロジェクトをレポジトリに追加|ワークディレクトリへのエクスポートのみ実行|
||ネームスペースをレポジトリに追加|ワークディレクトリへのエクスポートのみ実行|
||ワークからすべてのアイテムをインポート|IRISにインポート|
||ワークから現在のアイテムをインポート|表示中のドキュメントをIRISにインポート|
||設定のダンプ|設定内容をダンプ|


- 補足  
エクスポートには$System.OBJ.ExportUDL(,,"/diffexport/nodisplaylog")を使用します。実装は%ZScc.Utils:ExportSingleItem()を参照ください。
修飾子の意味は[こちら](https://docs.intersystems.com/iris20201/csp/docbookj/DocBook.UI.Page.cls?KEY=RCOS_vsystem)を参照ください。  

- 注意事項  
Linuxと異なり、Widnowsはファイル名の大文字小文字の区別をしません。大文字小文字を区別するルーチンはIRIS内ではtest.macとTEST.macの混在を許容しますが、エクスポート時には衝突し、どちらかに上書きされてしまいます。

2. %ZScc.Git
 %ZScc.Basicに加えて、各種gitコマンドを発行するメニューを提供します。
 >本機能はスタジオ経由で完全なgit機能を提供することを目的としていません。補助的な役割に徹しています。特にブランチ切り替えやコンフリクトの解消などの操作は、コマンドラインや専用ツールとの併用が必要になります。より透過的なソースコード管理機能が必要な場合はVSCodeやOpenExchangeの[ツール](https://openexchange.intersystems.com/package/Cach%C3%A9-Tortoize-Git)の使用をご検討ください。

|gitコマンド|メニューアイテム名|メニュー表示|用途・補足|
|:--|:--|:--|:--|
|||自動コミットを有効化|保存時にgit commitを実行します|
|||自動コミットを無効化|保存時にgit commitを実行しません|
|commit||コミット実行|明示的にgit commitを実行します|
|checkout HEAD||チェックアウト|表示中のドキュメントをHEADからgit checkoutします|
|pull||リモートからプル|使用は非推奨|
|push||リモートにプッシュ|使用は非推奨|
|status||ステータス表示||
|status --verbose||ステータス表示(verbose)||
|status||現在のアイテムのステータス表示(verbose)|表示中のドキュメントに対してgit status実行|
|||コマンドを表示|実行したgitコマンドを出力します|
|||コマンドを非表示|実行したgitコマンドを出力しません|

## ソースコントロールの有効化
管理ポータルの、システム管理-構成-追加の設定-ソースコントロール、でネームスペース単位で有効化・無効化します。%ZScc.Basicもしくは、%ZScc.Gitを選択してください。

## 各ネームスペースでのソースコントロールの設定
スタジオ上のソースコントロール-設定メニューを使用して、もしくは直接下記のグローバルをセットして設定を行います。
以下は、最低限必要な設定となります。
1. %ZScc.Basic
```ObjectScript
Set $NAMESPACE="APP"
^ZScc("Basic","LocalWorkspaceRoot")="c:\var\basic\Project_XYZ\"
^ZScc("Basic","Src")="src"
```

2. %ZScc.Git
```ObjectScript
Set $NAMESPACE="APP"
^ZScc("GIT","LocalWorkspaceRoot")="c:\var\git\Project_XYZ\"
^ZScc("GIT","Src")="src"
```

これらの設定とワークディレクトリの関係
- LocalWorkspaceRootの値が"C:\git\basic\Project_XYZ\"
- Srcの値が"src"  
である場合、下記のようなワークディレクトリ構造を作成します。
```
C:\var\git\Project_XYZ     ここにローカルレポジトリ(.gitフォルダ)が存在。
C:\var\git\Project_XYZ\... ここにIRISと直接関係のないファイルを配置
C:\var\git\Project_XYZ\src ここにIRIS関連ファイル(cls, mac, incなど)を配置
```

|第1ノード|第2ノード|用途・補足|省略時値|
|:--|:--|:--|:--|
|Basic,GIT|LocalWorkspaceRoot|ワークディレクトリの場所|省略不可|
|Basic,GIT|Src|IRIS関連のソースコード保存ディレクトリ名|省略不可|
|Basic,GIT|Debug|Debug情報を表示するかどうかのフラグ|0:表示しない|
|GIT|AutoCreateRepo|スタジオ起動時に、指定されたワークディレクトリがgit initされていない場合に、git initを実行するかどうかのフラグ|0:しない|
|GIT|AutoCommit|コミットを自動実行するかどうかのフラグ|0:しない|
|GIT|MainCommand|git実行イメージのパス|git|
|GIT|RemoteUser|リモートレポジトリをアクセスする際のユーザ名|なし|
|GIT|RemotePassword|リモートレポジトリをアクセスする際のパスワード|なし|
|GIT|RemoteRepository|リモートレポジトリのURL|なし|

AutoCreateRepoが1に設定されていると、先ほどの例でC:\var\git\Project_XYZ に、.gitフォルダが存在するかどうかを確認し、無ければ下記の一連の初期化コマンドを実行します。
```
git init
git config user.email xxx@yyy
git config user.name xxx
```
実装は%ZScc.GIT:InitDir()にありますので、適宜修正してください。
