
WIP

## 目的
複数人が参加する開発プロジェクトにおいて、メインの開発ツールとしてVSCODEを使用している環境で、現時点ではスタジオ(あるいはブラウザ)でしか編集出来ないInteroperability機能のBPL,DTL,Ruleを、VSCODEによるソースコート管理に加える。

## 前提
* 各利用者が専用のワークディレクトリ、ローカルレポジトリを持つ  
これを共有してしまうと、コミット内容にあわせて編集対象をステージングするというGitの基本的な操作が出来なくなります。
一時的にデバッグ用途で作成したルーチン(test1, deb2)などをソース管理に追加するのは避けたいものです。

* VSCODEとスタジオで同一のワークディレクトリを使用する  
これを別にしてしまうと、同じファイルを別のレポジトリにコミットするという危険を排除出来なくなります。
VSCODE,スタジオ双方を使用した一連の修正をコミットするという操作が出来なくなります。

* 各利用者が専用のIRIS環境を持つ  
これを共有してしまうと、DB内のソースコードとワークディレクトリ内のソースコードの同期がとれなくなります。

これら前提を満たすのは、以下の2環境となります。  
1. 全てローカル
IRISインスタンス自体をローカルPC上にインストールして個人環境として使用しながら開発を進める。

2. 全てリモート
共有サーバを使用します。
IRISインスタンスは共有しながらも、ネームスペースとそこに紐づけるワークディレクトリは、個別に用意する。
vscodeはRemote Development extensionでSSH接続して、リモートのファイルシステム上の各利用者固有のワークディレクトリを使用。  
Linux向けの機能ですが、WindowsでもSSHとWSLを導入すれば、接続対象になれます。
ただし、ワークディレクトリは、WSL配下のファイルシステム(ext4など)ではなく、IRISから直接ファイル操作可能な場所(/c/以下)に作成することになりますので、ファイルオーナーやプロテクションといった情報が、正しく伝わらない恐れがあります。要検証です。

1,2共にIRISをDockerで稼働させることが可能です。
後述する、ブランチの切り替えも非常に楽になりますので、非常に魅力的ですがIRISがLinux(Ubuntu)版に限定されますので、プロダクション環境がWindowsの場合は、選択し辛いと思います。

## 使用するソース管理機能
VSCODEではGitのエクステンションを使用。
スタジオ/ブラウザでは、編集内容を保存時にワークディレクトリに出力するソース管理フックを使用。

## 実行例
上述の全てローカルであり、共有リポジトリパターンの場合を例にとり使用方法の流れを俯瞰します。  
全体の流れは、Gitを使用した典型的なの開発フローと何ら変わりありませんので、利用環境に合わせて適用いただくための参考としてお読みください。

1. リモートリポジトリを作成
開発プロジェクトProject1用に、管理者がレポジトリ名:Project1, ブランチb1を作成。
```bash
cd \var\git
git clone https://github.com/IRISMeister/Project1.git
cd Project1
git checkout -b b1
git push --set-upstream origin b1
```

2. フォルダ構成の決定
決まりはありません。ここでは、下記のようなフォルダ構成とします。
フォルダ名: Project1    通常レポジトリ名と一致する。スタジオのプロジェクト名も同名で定義する。
C:\var\git\Project1     ここにローカルレポジトリ(.gitフォルダ)が存在
C:\var\git\Project1\... ここにIRISと直接関係のないファイルを配置
C:\var\git\Project1\src ここにIRIS関連ファイル(cls, mac, incなど)を配置

3. 参加各位のローカルフォルダにgit clone
ブランチをb1に切り替えて作業開始
```bash
cd \var\git
git clone https://github.com/IRISMeister/Project1.git
cd Project1
git checkout b1
```
4. ツールの初期設定
vscodeでの設定
普通にそのワークディレクトリを開きます。
```
cd \var\git\Project1
code .
```
ローカルIRISのAPPネームスペース(*)を接続先に指定する。
vscodeでは、.vscode/settings.jsonに下記のような接続情報を設定します。
```
    "objectscript.conn": {
        "active": true,
        "host": "localhost",
        "port": 52773,
        "ns": "APP",
        "username": "SuperUser",
        "password": "SYS"
    }
```

スタジオでの設定  
スタジオでの操作は、ソースコントロールフックの有効化と、ファイル出力先として、ワークディレクトリを指定します。
ソースコントロールフックの有効化方法？
```
Set $NAMESPACE="APP"
^SYS("SourceControl","GIT","LocalWorkspaceRoot")="c:\var\git\"
^SYS("SourceControl","GIT","MainCommand")="git"
^SYS("SourceControl","GIT","Src")="src"
```
その後、通常の接続操作でAPPネームスペースに接続します。

5. 開発作業  
git pull - コンフリクト解消 - ローカルIRISへのImport - 開発作業 - git add/commit - git push  
この繰り返し。  
主な編集作業はvscodeで行います。InteroperabilityのBPL,DTL,Ruleだけは、スタジオもしくはブラウザで編集作業を行います。  
スタジオでのソース管理コマンドの実行方法はメニュー操作になります。  
ソースコントロールフックの有効化を行うと、ブラウザにはソース管理ボタンが提供されます。  
ただし、本例で使用するBasicのフックは、ソースコード保存時に、自動的にワークディレクトリに対象をエクスポートするだけですのでメニュー操作は不要です。  
(Git用のフックを選んだ場合、各Gitコマンドの発行が可能になりますが、本稿の対象外です)  
他の参加者による修正の反映。コンフリクトがあれば解消。内容のローカルIRISに反映。単体テストにはローカルのIRISを使用します。  
適宜ローカルのレポジトリにコミット。vscodeで行っても良いし(お勧め)、スタジオで行っても良い。  
適宜リモートレポジトリにプッシュ。vscodeで行っても良いし(お勧め)、スタジオで行っても良い。  

6. 自動化テスト
継続的にテスト実施するような環境を使用して、リモートリポジトリのb1ブランチのソースコードをテスト
Dockerを使える(ターゲットがLinux環境)と楽です。  
https://github.com/IRISMeister/simple
GitHub Actionを使用して、Dockerイメージを作成する例。

7. リリース作業
管理者がb1ブランチをmasterブランチにマージします。

8. 新規リリースに向け、b2ブランチを作成。以降、繰り返し。

## ネームスペースについて
以下は、スタジオの利用を伴わない場合でも同様ですが、ネームスペースが指し示すソースコード保存用のデータベース(ルーチンのデフォルトデータベース)に関して配慮が必要です。
ネームスペースとソースコードの保存場所は、1対1ではありません。パッケージマッピングなどにより複数のデータベースに跨っている可能性があります(共通関数などを別個のデータベースに配置している場合など)。
そのことを考慮すると、ブランチ切り替えの際に、単純にネームスペースで認識できる既存のソースコードを「全部削除」して、切り替わったソースコードと置き換える、というオペレーションでは、どうしても、削除もれや削除し過ぎ、といったミスや無駄な再コンパイル発生を排除できません。
少々手間ではありますが、各ブランチに対応するソースコード保存専用のデータベースを個別に用意しておいて、ブランチを切り替える際には、ネームスペースのメインのソースコードの保存場所も切り替えるのが最も安全だと思います。

master  - APP   - app/master/IRIS.DAT
                + CommonPackage/IRIS.DAT
                + DATA/IRIS.DAT

b1      - APP   - app/b1/IRIS.DAT
                + CommonPackage/IRIS.DAT
                + DATA/IRIS.DAT

b2      - APP   - app/b2/IRIS.DAT
                + CommonPackage/IRIS.DAT
                + DATA/IRIS.DAT

一方、IRISの稼働環境として、リモートレポジトリを使用して焼いたDockerイメージを使用すれば、これらの操作は個別の利用者から隠ぺいされ、切り替えの手間が大幅に削減できます。

master  - MYIRIS:master (docker image app:master = app/master/IRIS.DAT+CommonPackage/IRIS.DAT)
        + DATA/IRIS.DAT (external database)

b1      - MYIRIS:b1     (docker image app:b1 = app/b1/IRIS.DAT+CommonPackage/IRIS.DAT)
        + DATA/IRIS.DAT (external database)

b2      - MYIRIS:b2     (docker image app:b2 = app/b2/IRIS.DAT+CommonPackage/IRIS.DAT)
        + DATA/IRIS.DAT (external database)

参考 
https://www.intersystems.com/jp/wp-content/uploads/sites/6/2019/04/5IRISDAY2019.pdf (P.25)
⑨でmasterブランチではなく、編集対象のブランチを使用してビルドする

