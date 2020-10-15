# SourceControl
WIP.  
DO NOT USE YET.

## How to install
```bash
$ git clone https://github.com/IRISMeister/SourceControl.git
$ cd SourceControl
```
On Linux
```ObjectScript
$ iris session iris -U %SYS
%SYS>d $SYSTEM.OBJ.ImportDir($SYSTEM.Util.GetEnviron("PWD")_"/src","*","ck",,1)
```
On Windows ターミナル起動。第1引数(パス)を適宜変更のこと。
```ObjectScript
%SYS>d $SYSTEM.OBJ.ImportDir("c:\temp\SourceControl\src","*","ck",,1)
```
```ObjectScript
%SYS>h
$
```

ソースコード管理の設定画面は下記のようにCSPページにアクセスします。
```ObjectScript
	Set Target=$system.CSP.GetDefaultApp($NAMESPACE)_"/%25ZScc.ui."_$Parameter(,"PRODUCT")_".Setting.cls"			
```
例えばネームスペースMYAPPに/csp/myappが存在しない、もしくは存在してもRESTアクセス用であった場合、設定画面の表示に失敗します。設定画面の表示は必須ではありませんので、その場合、直接グローバルへの設定を行ってください。
