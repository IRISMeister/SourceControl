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
	set:..File="..xml" ..File="" set tSC=..%Save() ; what?

	try {
		If $$$ISWINDOWS {
			set tCmd="cmd /C "
			set tCd="cd /D "_..LocalWorkspace
			set tCmd=tCmd_""""_tCd_" & "_..Command
		}
		Else {
			set tCmd="bash -c "
			set tCd="cd "_..LocalWorkspace
			set tCmd=tCmd_""""_tCd_" ; "_..Command
		}
		
		// subcommand
		set:(..SubCommand'="") tCmd=tCmd_" "_..SubCommand
		// subcommand options
		set i="" for  set tOption=..Options.GetNext(.i) q:i=""  set tCmd=tCmd_" "_i set:tOption'="" tCmd=tCmd_" "_$s($E(tOption)'=$c(34):$c(34),1:"")_tOption_$s($E(tOption)'=$C(34):$c(34),1:"")
		// repository
		set:(..Repository'="") tCmd=tCmd_" "_..Repository

		Set tCmd=tCmd_$C(34)
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
