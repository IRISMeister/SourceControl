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

