Include %ZScc.Constants

Class %ZScc.Utils Extends %RegisteredObject
{

ClassMethod ExternalName(InternalName As %String, Directory As %String = "") As %String
{
	// replace slashes in (csp,..) internalname by underscores
	set InternalName=$tr(InternalName,"%","_")
	set tType=..GetItemType(InternalName)
	set tLen=$l(InternalName,".")
	set tExternal=$p(InternalName,".",1,tLen-1)  

	Set ItemCategory=..ItemCategory(tType)
	If ItemCategory'="csp" {
		set tExternal=$REPLACE(tExternal,".",$$$FolderDelimiter)
	}
	Else {
		set tExternal=$REPLACE(tExternal,"/",$$$FolderDelimiter)
		If $E(tExternal,1)=$$$FolderDelimiter Set tExternal=$E(tExternal,2,*)
	}

	Set tExternal=tExternal_"."_tType
	If ..SaveFormat(tType)="xml" { 	Set tExternal=tExternal_".xml" }
	
	Set:Directory'="" tExternal=Directory_tExternal
	Quit tExternal
}

/// helper function to determine project item type
ClassMethod ItemCategory(ItemType As %String) As %String
{
	Return $CASE(ItemType,
		"cls":"class",
		"csp":"csp",
		"csr":"csp",
		"css":"csp",
		"js":"csp",
		"prj":"project",
		"mac":"routine",
		"inc":"routine",
		"int":"routine",
		"bas":"routine",
		"mvb":"routine",
		:"other")
}

ClassMethod GetItemType(InternalName As %String) As %String
{
	Quit $ZCVT($P(InternalName,".",$L(InternalName,".")),"L")
}

ClassMethod GetItemName(InternalName As %String) As %String
{
	Quit $P(InternalName,".",1,$L(InternalName,".")-1)
}

ClassMethod SaveFormat(ItemType As %String) As %String
{
	Return $CASE(ItemType,
		"prj":"xml",
		"csp":"xml",
		"csr":"xml",
		"js":"xml",
		"css":"xml",
		"esd":"xml",
		:"udl")
}

ClassMethod ExportProjectItems(ProjectName As %String, Directory As %String = "", Debug = 0) As %Status
{
	Set projectname=$P(ProjectName,".",1)
	If '##class(%Studio.Project).%ExistsId(projectname) { Quit '$$$OK }

	Set rs=##class(%ResultSet).%New("%Studio.Project:ProjectItemsList")
 	Do rs.Execute(projectname)
 	While (rs.Next()) {
		Set InternalName=rs.Data("Name")
		#; class lacks extension, so add it.
		If $ZCVT(rs.Data("Type"),"L")="cls" Set InternalName=InternalName_".cls"
		Set extName=##class(%ZScc.Utils).ExportSingleItem(InternalName,Directory,Debug)
 	}	
	//Export a project file itself.
	Set extName=##class(%ZScc.Utils).ExportSingleItem(ProjectName,Directory,Debug)

	Quit $$$OK
}

ClassMethod ExportAllItems(Directory As %String = "", Debug = 0) As %Status
{
	#;routines
	set tRS=##class(%ResultSet).%New("%Routine:RoutineList")
	do tRS.Execute("*",,0)  // INT, MAC, INC, BAS.
	while tRS.Next() {
		set tInternalName=tRS.Get("Name")
		Set routine = ##class(%Routine).%OpenId(tInternalName)
		If routine.Generated Continue   				//exclude generated
		Set db=##class(%SYS.Namespace).GetRoutineDest(,tInternalName)
		Set db=$P(db,"^",2)
		If $ZCVT($P(db,$$$FolderDelimiter,$L(db,$$$FolderDelimiter)-1),"U")'=$NAMESPACE Continue

		Set extName=##class(%ZScc.Utils).ExportSingleItem(tInternalName,Directory,Debug)
	}
	
	#;classes
	Do $SYSTEM.OBJ.GetClassList(.classes,"/application=1/generated=0")
	Set class="" For {
		Set class=$O(classes(class)) Q:class=""
		If $E(class,1,4)="csp." Continue  // exclude csp classes
		Set tInternalName=class_".cls"
		Set extName=##class(%ZScc.Utils).ExportSingleItem(tInternalName,Directory,Debug)
	}
		
	#;Project file(ExportAllClassesIndividual doesn't handle this)
	set tRS=##class(%ResultSet).%New("%Studio.Project:ProjectList")
	do tRS.Execute()
	while tRS.Next() {
		set tInternalName=tRS.Get("Name")_".PRJ"
		#;don't export default project
		If $E(tInternalName,1,$L($$$DEFAULTPRJNAME))=$$$DEFAULTPRJNAME Continue

		Set extName=##class(%ZScc.Utils).ExportSingleItem(tInternalName,Directory,Debug)
	}
	
	#;CSP related (ExportAllClassesIndividual doesn't handle this)
	Set app=$SYSTEM.CSP.GetDefaultApp($NAMESPACE)
	Set cspdir=$SYSTEM.CSP.GetFileName(app_"/")
	Do ..ExportAllCSP(cspdir,Directory,Debug)

	#;Other subclass of %Studio.AbstractDocument
	If ..IsEnsembleEnabled() { //Ensemble enabled
		If $CLASSMETHOD("Ens.Util.SettingsDocument","Exists","Ens.Config.DefaultSettings.esd") 
		{
			Set tInternalName="Ens.Config.DefaultSettings.esd"
			Set extName=##class(%ZScc.Utils).ExportSingleItem(tInternalName,Directory,Debug)
		}
	}
	
	Quit $$$OK
}

ClassMethod ExportAllCSP(cspdir As %String, Directory As %String, Debug)
{
	Set defapp=$SYSTEM.CSP.GetDefaultApp($NAMESPACE)

	Set tRS=##class(%ResultSet).%New("%File:FileSet")
	Do tRS.Execute(cspdir,$$$CSPEXPORTTGT,"",1)
	while tRS.Next() {
		Set cspfile=tRS.Get("Name") 
 		If tRS.Get("Type")="D" Do ..ExportAllCSP(cspfile,Directory,Debug) Continue
 		Set itemname=tRS.Get("ItemName")

		Set cspfullpathList=$SYSTEM.CSP.FilenameToUrls(cspfile)  // it returns in lower case only....
		For i=1:1:$ListLength(cspfullpathList) {
			Set cspfullpath=$LIST(cspfullpathList,i)
			Set path=$P(cspfullpath,"/",1,$L(cspfullpath,"/")-1)
			// export files under a default app only
			If path=defapp { 
				Set cspurl=path_"/"_itemname
				Set extName=##class(%ZScc.Utils).ExportSingleItem(cspurl,Directory,Debug)
			}
		}
	}
}

ClassMethod ExportSingleItem(InternalName As %String, path As %String, Debug) As %String
{
	If Debug { 
		w "InternalName:",InternalName,!
		w "ExternalName:",##class(%ZScc.Utils).ExternalName(InternalName,path),!
	} 
	
	Set qualifier="/diffexport"
	If 'Debug { Set qualifier=qualifier_"/nodisplaylog" }
	
	Set ItemType=##class(%ZScc.Utils).GetItemType(InternalName)
	#; don't export these items as is. 
	If (ItemType="bpl")!(ItemType="dtl") {
		Set InternalName=##class(%ZScc.Utils).GetItemName(InternalName)_".cls"
	}

	Set ext=##class(%ZScc.Utils).ExternalName(InternalName,path)
	Set extName=##class(%ZScc.Utils).ExternalName(InternalName,"")
	If ..SaveFormat(ItemType)="xml" {
		Do $System.OBJ.Export(InternalName,ext,qualifier)
	}
	Else {
		Do $System.OBJ.ExportUDL(InternalName,ext,qualifier)
	}	
	Quit extName
}

ClassMethod IsEnsembleEnabled()
{
	If $D(^Ens.Configuration)'=0 { Return $$$YES }
	Return $$$NO
}

/// <PRE>
/// Follow thses steps.
/// 0)optional. Set ^SYS("SourceControl","GIT","LocalWorkspaceRoot") value to point to workspace root directory.
/// Example.  
/// USER> Set ^SYS("SourceControl","GIT","LocalWorkspaceRoot")="c:\var\git\work\"
/// 1)Call this method.
/// Example.  
/// C:\var\git\work>SET LocalWorkspaceRoot=%CD%  (optional)
/// C:\var\git\work>\InterSystems\HSAP20181\bin\Ccontrol.exe runw hsap20181 ##class(%ZScc.Utils).CLExportAll() MYAPP
/// HSAP20172 is an instance name. MYAPP is a namespace.
/// 2)Open DOS console.  CD to workspace directory such as 'C:\var\git\work\HSAP20181\MYAPP'
/// 3) git init
/// 3) git add *
/// 3) git commit -m "message"
/// </PRE>
ClassMethod CLExportAll()
{
	Set outdir=$SYSTEM.Util.GetEnviron("LocalWorkspaceRoot")
	If outdir="" { Set outdir=$G(^SYS("SourceControl","GIT","LocalWorkspaceRoot")) }
	If outdir="" { W "LocalWorkspaceRoot is not defined." Quit '$$$OK }

	Set instance=##class(%SYS.System).GetInstanceName()
	Set outdir=outdir_"\"_instance_"\"_$NAMESPACE_"\"
	D ##class(%ZScc.Utils).ExportAllItems(outdir)
	
	;git init
	;git add *
	;git commit
}

/// <PRE>
/// Almost identical to CLExportAll() except
/// 1)Call this method. Pass a project name as a parameter.
/// Example.  
/// C:\var\git\work>SET LocalWorkspaceRoot=%CD%  (optional)
/// C:\var\git\work>\InterSystems\HSAP20181\bin\Ccontrol.exe runw hsap20181 ##class(%ZScc.Utils).CLExportProject(\"project1\") MYAPP
/// project1 is a project name to be exported.
/// </PRE>
ClassMethod CLExportProject(ProjectName = "")
{
	If ProjectName="" Quit
	Set ProjectName=ProjectName_".prj"
	Set outdir=$SYSTEM.Util.GetEnviron("LocalWorkspaceRoot")
	If outdir="" { Set outdir=$G(^SYS("SourceControl","GIT","LocalWorkspaceRoot")) }
	If outdir="" { W "LocalWorkspaceRoot is not defined." Quit '$$$OK }
	
	Set instance=##class(%SYS.System).GetInstanceName()
	Set outdir=outdir_"\"_instance_"\"_$NAMESPACE_"\"
	Set tSC=##class(%ZScc.Utils).ExportProjectItems(ProjectName,outdir)
	If $$$ISERR(tSC) { W "Project "_ProjectName_" doesn't exist.",! }

	;git init
	;git add *
	;git commit
}

/// <PRE>
/// C:\var\git\work>SET LocalWorkspaceRoot=%CD%  (optional)
/// C:\var\git\work\HSAP20181\MYAPP>\InterSystems\hsap20181\bin\Ccontrol.exe runw hsap20181 ##class(%ZScc.Utils).CLImportAll() MYAPP
/// </PRE>
ClassMethod CLImportAll()
{
	Set indir=$SYSTEM.Util.GetEnviron("LocalWorkspaceRoot")
	If indir="" { Set outdir=$G(^SYS("SourceControl","GIT","LocalWorkspaceRoot")) }
	If indir="" { W "LocalWorkspaceRoot is not defined." Quit '$$$OK }
	
	Set instance=##class(%SYS.System).GetInstanceName()
	Set indir=indir_"\"_instance_"\"_$NAMESPACE_"\"
	If ##class(%File).Exists(indir) {
		Do $SYSTEM.OBJ.ImportDir(indir,"*.mac;*.cls;*.xml","ck",.e,1,.imp)
		zw e
	}
}

}
