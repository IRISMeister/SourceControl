Include (%sySite, %ZScc.Constants, %occErrors)

Class %ZScc.GIT.Command Extends %ZScc.Command
{

/// Product name, e.g. VSS, ClearCase, CVS, etc..
Parameter PRODUCT = "GIT";

Parameter MAINCOMMAND = "git";

Method Execute() As %Integer
{
	If ..Command="" { Set ..Command=..#MAINCOMMAND }

	Set status=$$$OK   //by T.I  to provide quick error status to the caller  2012/10/16
	set tCmd=$s($$$ISWINDOWS:"cmd /C ",$$$ISUNIX:"bash ",1:1)
	set:..File="..xml" ..File="" set tSC=..%Save()
	try {
		// windows only...
		set tCd="cd /D "_..LocalWorkspace
		// this is windows only commands concatenation
		set tCmd=tCmd_""""_tCd_" & "_..Command
		// global options
		// set i="" for  set i=$o(..GlobalOptions(i)) quit:i=""  set tCmd=tCmd_" "_i set:..GlobalOptions(i)'="" tCmd=tCmd_" "_$c(34)_..GlobalOptions(i)_$c(34)
		set i="" for  set tGlobalOption=..GlobalOptions.GetNext(.i) quit:i=""  set tCmd=tCmd_" "_i set:tGlobalOption'="" tCmd=tCmd_" "_$c(34)_tGlobalOption_$c(34)
		
		
		// subcommand
		set:(..SubCommand'="") tCmd=tCmd_" "_..SubCommand
		// subcommand options
		set i="" for  set tOption=..Options.GetNext(.i) q:i=""  set tCmd=tCmd_" "_i set:tOption'="" tCmd=tCmd_" "_$s(tOption[" ":$c(34),1:"")_tOption_$s(tOption[" ":$c(34),1:"")
		// repository
		set:(..Repository'="") tCmd=tCmd_" "_..Repository

		set ..CommandString=tCmd
		//
		$$$DEBUG("Command:"_tCmd)
		$$$DEBUG("Command GUID:"_..GUID)
		
		// go and do it!
		//open tCmd:("QR"):5 if '$test throw
		open tCmd:("QRK\SJIS\"):5 if '$test throw
		use tCmd
		Set tEof=$system.Process.SetZEOF(1)
		for j=1:1 q:$zeof  do
		. read tLine If ..Debug s ^ZScc.Debug($i(^ZScc.Debug))=tLine
		. // TODO: build list of command results
		. do ..Result.WriteLine(tLine)
		. If tLine["[rejected]" Set status='$$$OK
		. If tLine["conflict" Set status='$$$OK
		set tEof=$system.Process.SetZEOF(tEof)
		close tCmd
	} catch (ex) {
		d BACK^%ETN
		do ..Result.WriteLine("Runtime ERROR: "_$ze)
		//close tCmd
	}
	if ..Result.Size=0 do ..Result.WriteLine(" *** Output: none")
	set tSC=..%Save()

	#;Quit
	//by T.I  to provide quick error status to the caller  2012/10/16
	Quit status
}

Storage Default
{
<Type>%Storage.Persistent</Type>
}

}
