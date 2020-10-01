# SourceControl
WIP

## How to install
```ObjectScript
$ git clone https://github.com/IRISMeister/SourceControl.git
$ cd SourceControl
$ iris session iris -U %SYS
%SYS>d $SYSTEM.OBJ.ImportDir($SYSTEM.Util.GetEnviron("PWD")_"/src","*","ck",,1)
%SYS>h
$
```