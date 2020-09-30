Include (%sySite, %ZScc.Constants, %occErrors)

Class %ZScc.SVN.Command Extends %ZScc.Command
{

/// Product name, e.g. VSS, ClearCase, CVS, etc..
Parameter PRODUCT = "SVN";

Parameter MAINCOMMAND = "svn";

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
		// revision #
		if ..Revision'="" {
			set tCmd=$case(..SubCommand,"checkout":tCmd_"@"_..Revision,:tCmd_" -r"_..Revision)
		}
		// file
		set:..File'="" tCmd=tCmd_" "_..File
		set tCmd=tCmd_""""
		// a little dirty trick
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
		. If tLine["svn: E" Set status='$$$OK  //by T.I  to provide simple error detection to the caller  2012/10/16
		. //set tSC=..InsertIntoResults(tLine) //comment out by T.I  to avoid too much journal entries. 2011/03/18
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

/// this method is trying to decompose output from svn commands to some
/// structured information for possible automatic post-processing.<b>
/// There is, however, a big chance that it returns a mess rather meaningful
/// info.<p>
/// Please note: <span style='color:red;'>THIS IS EXPERIMENTAL CODE!</span>
Method InsertIntoResults(pLine As %String) As %Status
{
	set tSC=$$$OK
	quit:pLine="" tSC
	#dim tResult as %ZScc.CommandResult
	
	try {
		set tResult=##class(%ZScc.CommandResult).%New()
		$$$DEBUG("insert into results: "_pLine)
		
		if $zcvt(pLine,"L")["could not connect" set ..IsDisconnected=1
		
		if ..SubCommand="info" {
			if $zcvt(pLine,"L")["(not a valid" set tResult.IsError=1
			// +DK 1.21
		} elseif (..SubCommand="status")&&($zcvt(pLine,"L")[".xml") {
			// strip all whitespaces
			set tLine=$zstrip($e(pLine,9,*),"=",$$$SPACE)
			set tResult.Action=$e(pLine,1)
			set tLen=$l(tLine,$$$SPACE)
			set tResult.ExternalName=$p(tLine,$$$SPACE,tLen)
			// Guessing here...
			// only "table" lines
			set tResult.Properties=$e(pLine,2)
			set tResult.Lock=$e(pLine,3)
			set tResult.History=$e(pLine,4)
			set tResult.Switch=$e(pLine,5)
			set tResult.LockInfo=$e(pLine,6)
			set tResult.Updates=$e(pLine,8)
			if ..Options.GetAt("-u")'="" set tResult.WorkingRevision=$p(tLine,$$$SPACE,2)
			if ..Options.GetAt("-v")'="" { 
				set tResult.WorkingRevision=$p(tLine,$$$SPACE,2)
				set tResult.LastCommittedRevision=$p(tLine,$$$SPACE,3)
				set tResult.LastCommittedAuthor=$p(tLine,$$$SPACE,4)			
			}
			// +DK 1.21
		} elseif (..SubCommand="checkout")&&($zcvt(pLine,"L")[".xml") {
			// strip all whitespaces
			set tLine=$zstrip(pLine,"=",$$$SPACE)
			set tResult.Action=$e(pLine,1)
			set tLen=$l(tLine,$$$SPACE)
			set tResult.ExternalName=$p(tLine,$$$SPACE,tLen)
		} elseif (..SubCommand="update") {
			if $zcvt($p(pLine,$$$SPACE,1),"L")="restored" {
				// THIS ONLY RETURNS FILENAME WITHOUT PATH!
				set tResult.ExternalName=$tr($p(pLine,$$$SPACE,2),"'","")
				// we treat such files as UPDATED so they load into studio
				set tResult.Action="U"
			} elseif $zcvt($p(pLine,$$$SPACE,1),"L")="at" {
				set tResult.WorkingRevision=+$p(pLine,$$$SPACE,3)
			} elseif $e(pLine,1,2)="U "||($e(pLine,1,2)="A ")||($e(pLine,1,2)="D ") {
				set tLine=$zstrip(pLine,"=",$$$SPACE)
				set tResult.Action=$e(pLine,1)
				set tLen=$l(tLine,$$$SPACE)
				set tResult.ExternalName=$p(tLine,$$$SPACE,tLen)
			} elseif (..SubCommand="mkdir") {
				// +DK 2.0
				if $zcvt(tLine,"L")'["committed" s tResult.IsError=1
			} else {
				// ? other variants?
			}
		} else {
			// TODO
		}
		set tResult.Command=##this
		set tSC=tResult.%Save()
		$$$DEBUG("CommandResult.Save:"_tSC)
	} catch (ex) {
		$$$DEBUG($ze)
		d BACK^%ETN
	}
	quit tSC
}

Storage Default
{
<Type>%Storage.Persistent</Type>
}

}
