DBox "AssnonExistingTripTables" (Args) center, center Title: "Highway Assignment on Existing Trip Tables"

// Use / Copy / Create alternate highway network and assign on using existing trip tables in this directory
//      Creates new subdir <new_name>/HwyAssn and <new name>/HwyAssn/HOT for assignments

	Init do
		dim JobsToRun[1]
		dim hwyassnarguments[11]

		Dir = Args.[Run Directory].Value
		BaseYear = Args.[Run Year].Value
		BaseHwyNameAM = Args.[AM Peak Hwy Name].value
		BaseHwyNamePM = Args.[PM Peak Hwy Name].value
		BaseHwyNameOP = Args.[Offpeak Hwy Name].value
		sysdir = GetSystemDirectory()

//		BaseHwyFile = Dir + "\\" + BaseHwyName + ".dbd"
		BaseHwyFileAM = Dir + "\\" + BaseHwyNameAM + ".dbd"
		baseinfoAM = GetDBInfo(BaseHwyFileAM)
		BaseHwyFilePM = Dir + "\\" + BaseHwyNamePM + ".dbd"
		baseinfoPM = GetDBInfo(BaseHwyFilePM)
		BaseHwyFileOP = Dir + "\\" + BaseHwyNameOP + ".dbd"
		baseinfoOP = GetDBInfo(BaseHwyFileOP)

		AltHwyName = null
		AltHwyNameAM = null
		AltHwyFileAM = null
		AltHwyNamePM = null
		AltHwyFilePM = null
		AltHwyNameOP = null
		AltHwyFileOP = null
		AltHwyYear = BaseYear
		CopyFromFileAM = null
		CopyFromFilePM = null
		CopyFromFileOP = null
		AltSubDir = null

		keepgoing = "Yes"
		CreateAlt = "No"
		message = null

		dboxtext = " Area type from this folder is used and CapSpd re-run on alternate network "
		createmsgtext = "Create alt highway file"
		dboxaltsubdirtext = " Assignment output put in subfolder Dir\\<AltSubDir>\\HwyAssn "
		dboxaltsubdirtext2 = " Enter only name - no \\ \\ !" 

/*		DisableItem("dboxcopyhwyfileAM")
		HideItem("dboxcopyhwyfileAM")
		DisableItem("dboxcopyhwyfilePM")
		HideItem("dboxcopyhwyfilePM")
		DisableItem("dboxcopyhwyfileOP")
		HideItem("dboxcopyhwyfileOP")
		DisableItem("dboxcopyhwybuttonAM")
		HideItem("dboxcopyhwybuttonAM")
		DisableItem("dboxcopyhwybuttonPM")
		HideItem("dboxcopyhwybuttonPM")
		DisableItem("dboxcopyhwybuttonOP")
		HideItem("dboxcopyhwybuttonOP")
*/		HideItem("dboxcreatemsg")
		DisableItem("dboxalthwyfileAM")
		HideItem("dboxalthwyfileAM")
		DisableItem("dboxalthwyfilePM")
		HideItem("dboxalthwyfilePM")
		DisableItem("dboxalthwyfileOP")
		HideItem("dboxalthwyfileOP")
		DisableItem("dboxalthwybuttonAM")
		HideItem("dboxalthwybuttonAM")
		DisableItem("dboxalthwybuttonPM")
		HideItem("dboxalthwybuttonPM")
		DisableItem("dboxalthwybuttonOP")
		HideItem("dboxalthwybuttonOP")
		DisableItem("dboxalthwyyear")
		HideItem("dboxalthwyyear")
		DisableItem(" Set Alt Hwy ")
		HideItem("altsubdirtext1")
		HideItem("altsubdirtext2")
		DisableItem("dboxaltsubdir")
		DisableItem(" Run Hwy Assn ")

		LogFile = Args.[Log File].value
		SetLogFileName(LogFile)
		ReportFile = Args.[Report File].value
		SetReportFileName(ReportFile)

		datentime = GetDateandTime()
		AppendToLogFile(1, "Enter HwyAssn on existing trip tables: " + datentime)
	EndItem

	Text "argsdir" 25, 1.5, 35 Framed Prompt: "Run Directory" Variable: Dir
	Text "argshwyAM" 25, after, 20 Framed Prompt: "Base AM Peak Highway Name" Variable: BaseHwyNameAM 
	Text "argshwyPM" 25, after, 20 Framed Prompt: "Base PM Peak Highway Name" Variable: BaseHwyNamePM 
	Text "argshwyOP" 25, after, 20 Framed Prompt: "Base Offpeak Highway Name" Variable: BaseHwyNameOP 
	Text "argsyear" 25, after, 15 Framed Prompt: "Base Run Year" Variable: BaseYear		

//	Text " " same, after, , 0.5												
	Text  1.0, after Variable: dboxtext 									//~8.0

//	Text " " same, after, , 0.5												
	Edit Text "altyhwyname" 20.0, after, 38 Prompt: "Alt Hwy name: " Variable: AltHwyName Align: Center 
		Help:"Leave off AM/PM/Offpeak in name "    

	// Radio list to set alternate hwy files
	Radio List 11.0, 15.0, 40, 4.5 Prompt: "Get Alternate Highway Networks" Variable: selectoption	
	Radio Button "check1" 12.0, 16.5 Prompt: "Use existing alternate highway files" do		
		EnableItem("dboxalthwyfileAM")
		ShowItem("dboxalthwyfileAM")
		EnableItem("dboxalthwyfilePM")
		ShowItem("dboxalthwyfilePM")
		EnableItem("dboxalthwyfileOP")
		ShowItem("dboxalthwyfileOP")
		HideItem("dboxcreatemsg")
		EnableItem("dboxalthwybuttonAM")
		ShowItem("dboxalthwybuttonAM")
		EnableItem("dboxalthwybuttonPM")
		ShowItem("dboxalthwybuttonPM")
		EnableItem("dboxalthwybuttonOP")
		ShowItem("dboxalthwybuttonOP")
		EnableItem(" Set Alt Hwy ")

/*		DisableItem("dboxcopyhwyfileAM")
		HideItem("dboxcopyhwyfileAM")
		DisableItem("dboxcopyhwyfilePM")
		HideItem("dboxcopyhwyfilePM")
		DisableItem("dboxcopyhwyfileOP")
		HideItem("dboxcopyhwyfileOP")
		DisableItem("dboxcopyhwybuttonAM")
		HideItem("dboxcopyhwybuttonAM")
		DisableItem("dboxcopyhwybuttonPM")
		HideItem("dboxcopyhwybuttonPM")
		DisableItem("dboxcopyhwybuttonOP")
		HideItem("dboxcopyhwybuttonOP")
		DisableItem("dboxalthwyyear")
*/		HideItem("dboxalthwyyear")
		HideItem("altsubdirtext1")
		HideItem("altsubdirtext2")
		DisableItem("dboxaltsubdir")
		DisableItem(" Run Hwy Assn ")
	enditem

/*	Radio Button "check2" 12.0, 17.5 Prompt: "Copy alternate hwy files from other folder" do	
		EnableItem("dboxcopyhwyfileAM")
		ShowItem("dboxcopyhwyfileAM")
		EnableItem("dboxcopyhwyfilePM")
		ShowItem("dboxcopyhwyfilePM")
		EnableItem("dboxcopyhwyfileOP")
		ShowItem("dboxcopyhwyfileOP")
		EnableItem("dboxcopyhwybuttonAM")
		ShowItem("dboxcopyhwybuttonAM")
		EnableItem("dboxcopyhwybuttonPM")
		ShowItem("dboxcopyhwybuttonPM")
		EnableItem("dboxcopyhwybuttonOP")
		ShowItem("dboxcopyhwybuttonOP")
		HideItem("dboxcreatemsg")
		EnableItem("dboxalthwyfileAM")
		ShowItem("dboxalthwyfileAM")
		EnableItem("dboxalthwyfilePM")
		ShowItem("dboxalthwyfilePM")
		EnableItem("dboxalthwyfileOP")
		ShowItem("dboxalthwyfileOP")
		EnableItem("dboxalthwybuttonAM")
		ShowItem("dboxalthwybuttonAM")
		EnableItem("dboxalthwybuttonPM")
		ShowItem("dboxalthwybuttonPM")
		EnableItem("dboxalthwybuttonOP")
		ShowItem("dboxalthwybuttonOP")
		EnableItem(" Set Alt Hwy ")

		DisableItem("dboxalthwyyear")
		HideItem("dboxalthwyyear")
		HideItem("altsubdirtext1")
		HideItem("altsubdirtext2")
		DisableItem("dboxaltsubdir")
		DisableItem(" Run Hwy Assn ")

	enditem
*/
//	Radio Button "check3" 12.0, 18.5 Prompt: "Create new alternate highway files" do		
	Radio Button "check3" 12.0, 17.5 Prompt: "Create new alternate highway files" do		
		EnableItem("dboxalthwyfileAM")
		ShowItem("dboxalthwyfileAM")
		EnableItem("dboxalthwyfilePM")
		ShowItem("dboxalthwyfilePM")
		EnableItem("dboxalthwyfileOP")
		ShowItem("dboxalthwyfileOP")

		if AltHwyName <> null 
			then do
				ShowItem("dboxcreatemsg")
				AltHwyFileAM = Dir + "\\" + AltHwyName + "_AMPeak.dbd"
				AltHwyFilePM = Dir + "\\" + AltHwyName + "_PMPeak.dbd"
				AltHwyFileOP = Dir + "\\" + AltHwyName + "_Offpeak.dbd"
			end
			else message = message + {"You must enter Alt Highway Name!"}
		EnableItem("dboxalthwybuttonAM")
		ShowItem("dboxalthwybuttonAM")
		EnableItem("dboxalthwybuttonPM")
		ShowItem("dboxalthwybuttonPM")
		EnableItem("dboxalthwybuttonOP")
		ShowItem("dboxalthwybuttonOP")
		EnableItem("dboxalthwyyear")
		ShowItem("dboxalthwyyear")
		EnableItem(" Set Alt Hwy ")

/*		DisableItem("dboxcopyhwyfileAM")
		HideItem("dboxcopyhwyfileAM")
		DisableItem("dboxcopyhwyfilePM")
		HideItem("dboxcopyhwyfilePM")
		DisableItem("dboxcopyhwyfileOP")
		HideItem("dboxcopyhwyfileOP")
		DisableItem("dboxcopyhwybuttonAM")
		HideItem("dboxcopyhwybuttonAM")
		DisableItem("dboxcopyhwybuttonPM")
		HideItem("dboxcopyhwybuttonPM")
		DisableItem("dboxcopyhwybuttonOP")
		HideItem("dboxcopyhwybuttonOP")
*/		HideItem("altsubdirtext1")
		HideItem("altsubdirtext2")
		DisableItem("dboxaltsubdir")
		DisableItem(" Run Hwy Assn ")
	enditem

	// Copy hwy files - hidden unless copy selected										
//	Text " " same, after, , 0.5											
/*	Edit Text "dboxcopyhwyfileAM" 20.0, after, 40 Prompt: "Copy this AM peak hwy file: " Variable: CopyFromFileAM
			 Help:"AM Peak Highway network file to copy into current Dir" Disabled Hidden

	Button "dboxcopyhwybuttonAM" after, same Icon: "bmp\\buttons|148" 
		Help: "Find the AM Peak .dbd you want to copy" Disabled Hidden do
			CopyFromFileAM = ChooseFile({{"Standard","*.dbd"}},"Choose AM Peak highway file to copy",	
				{{"Initial Directory", Dir}}) 
	enditem

	Edit Text "dboxcopyhwyfilePM" 20.0, after, 40 Prompt: "Copy this PM peak hwy file: " Variable: CopyFromFilePM
			 Help:"PM Peak Highway network file to copy into current Dir" Disabled Hidden

	Button "dboxcopyhwybuttonPM" after, same Icon: "bmp\\buttons|148" 
		Help: "Find the PM Peak .dbd you want to copy" Disabled Hidden do
			CopyFromFilePM = ChooseFile({{"Standard","*.dbd"}},"Choose PM Peak highway file to copy",	
				{{"Initial Directory", Dir}}) 
	enditem

	Edit Text "dboxcopyhwyfileOP" 20.0, after, 40 Prompt: "Copy this Offpeak hwy file: " Variable: CopyFromFileOP
			 Help:"Offpeak Highway network file to copy into current Dir" Disabled Hidden

	Button "dboxcopyhwybuttonOP" after, same Icon: "bmp\\buttons|148" 
		Help: "Find the Offpeak .dbd you want to copy" Disabled Hidden do
			CopyFromFileOP = ChooseFile({{"Standard","*.dbd"}},"Choose Offpeak highway file to copy",	
				{{"Initial Directory", Dir}}) 
	enditem
*/
	// Alternative highway files (in current directory)
	Text "dboxcreatemsg" 1.0, same Variable: createmsgtext 
//	Text " " same, after, , 0.5														
	Edit Text "dboxalthwyfileAM" 20.0, after, 40 Prompt: "Use this AM peak hwy file: " Variable: AltHwyFileAM		
			 Help:"Alternate AM highway file for assignment" Disabled Hidden

	Button "dboxalthwybuttonAM" after, same Icon: "bmp\\buttons|148" Help: "Choose alternate AM hwy .dbd" Disabled Hidden do
			AltHwyFileAM = ChooseFile({{"Standard","*.dbd"}},"Choose alternate AM Peak hwy file",	
				{{"Initial Directory", Dir}})
	enditem

	Edit Text "dboxalthwyfilePM" 20.0, after, 40 Prompt: "Use this PM peak hwy file: " Variable: AltHwyFilePM		
			 Help:"Alternate PM highway file for assignment" Disabled Hidden

	Button "dboxalthwybuttonPM" after, same Icon: "bmp\\buttons|148" Help: "Choose alternate PM hwy .dbd" Disabled Hidden do
			AltHwyFilePM = ChooseFile({{"Standard","*.dbd"}},"Choose alternate PM Peak hwy file",	
				{{"Initial Directory", Dir}})
	enditem

	Edit Text "dboxalthwyfileOP" 20.0, after, 40 Prompt: "Use this Offpeak hwy file: " Variable: AltHwyFileOP		
			 Help:"Alternate Offpeak highway file for assignment" Disabled Hidden

	Button "dboxalthwybuttonOP" after, same Icon: "bmp\\buttons|148" Help: "Choose alternate Offpeak hwy .dbd" Disabled Hidden do
			AltHwyFileOP = ChooseFile({{"Standard","*.dbd"}},"Choose alternate Offpeak hwy file",	
				{{"Initial Directory", Dir}})
	enditem

	//	Altyear (ONLY for create)		
//	Text " " same, after, , 0.5														
	Edit Text "dboxalthwyyear" 20.0, after, 10  Prompt: "Alt network year:" Variable: AltHwyYear 		
		Help:"Run Year for alternative network.  Folder year used for area type." Disabled Hidden  


	//****************************************************************************************************************************************
	// Set highway network
	Button " Set Alt Hwy " 20.0, after, 20 Help: "Check highway files - either create or copy, check if network ready for assignment" Disabled do  

		keepgoing = "Yes"

		// reconcile altname and altpath
		
		//loop on 3 networks (AM, PM, OP)
		AltHwyFile_ar = {AltHwyFileAM, AltHwyFilePM, AltHwyFileOP}

//this is null now:
		AltHwyName_ar = {AltHwyNameAM, AltHwyNamePM, AltHwyNameOP}


//		CopyFromFile_ar = {CopyFromFileAM, CopyFromFilePM, CopyFromFileOP}
		BaseHwyName_ar = {BaseHwyNameAM, BaseHwyNamePM, BaseHwyNameOP}

		//loop on 3 networks (AM, PM, OP)
		for tp = 1 to 3 do	
		
			altpath = SplitPath(AltHwyFile_ar[tp])
	
			if altpath[3] <> null 
				then altinfo = GetDBInfo(AltHwyFile_ar[tp])
				else altinfo = null
	
			if AltHwyName_ar[tp] = null 
				then do 
					if altpath[3] = null 
						then do		//CREATE REMOVED IN LAPTOP VERSION *********************
/*
							// can use copy from filename if you don't have one
							if selectoption=2 
								then do
									copypath = SplitPath(CopyFromFile_ar[tp])
									if copypath[3] <> null 
										then copyinfo = GetDBInfo(CopyFromFile_ar[tp])
										else copyinfo = null
									copyinfo = GetDBInfo(CopyFromFile_ar[tp])
									AltHwyName_ar[tp] = copypath[3]
									if AltHwyName_ar[tp] = null 
										then do
											message = message + {"Alternate Highway File required!"}
											keepgoing = "No"
											goto badfiles
										end
									AltHwyFile_ar[tp] = Dir + "\\" + AltHwyName_ar[tp] + ".dbd" 
									altpath = SplitPath(AltHwyFile_ar[tp])
									message = message + {"Using copy file name: " + copypath[3]}
								end  // selectoption = 2
							else if selectoption <> 2 
								then do
*/									message = message + {"Alternate Highway File required!"}
									keepgoing = "No"
									goto badfiles
//								end
						end // altpath[3] = null
					else if altpath[3] <> null 
						then do
							AltHwyName_ar[tp] = altpath[3]
							message = message + {"Set AltHwyName to: " + altpath[3]}
						end
				end // AltHwyName = null
			else if AltHwyName_ar[tp] <> null 
				then do
					if altpath[3] = null 
						then do
							AltHwyFile_ar[tp] = Dir + "\\" + AltHwyName_ar[tp] + ".dbd" 
							altpath = SplitPath(AltHwyFile_ar[tp])
							message = message + {"AltHwyFile set to dir + althwyname"}	
						end
					else if altpath[3] <> null 
						then do
							if upper(AltHwyName_ar[tp]) <> upper(altpath[3]) 
								then do
									message = message + {"You must reconcile AltHwyName and AltHwyFile!"} 
									keepgoing = "No"
									goto badfiles
								end
						end //altpath[3] <> null
				end //AltHwyName <> null
			// AltHwyName and AltHwyFile should agree 
	
			// Must have different name than base name 
/*			if AltHwyName_ar[tp] = BaseHwyName_ar[tp] 
				then do
					message = message + {"AltHwyName MUST be different from BaseHwyName (" + BaseHwyName_ar[tp] + ")!"}
					keepgoing = "No"
					goto badfiles
				end
*/	 
			// Alt file must be in Dir
			altdir = altpath[1] + altpath[2]
			if upper(altdir) <> upper(Dir) + "\\" 
				then do
					message =  message + {"AltHwyFile MUST be in run directory: " + Dir}
					keepgoing = "No"
					goto badfiles
				end
	
			// check if areatype output is present 	 	
			atinfo = GetFileInfo(Dir+ "\\LandUse\\TAZ_AREATYPE.asc")
			if atinfo = null 
				then runareatype = "Yes"
				else runareatype = "No"
	
			//* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
			// Selectoptions (use, copy, create) -- COPY REMOVED FOR LAPTOP VERSION
			// Use - AltHwyFile must be there
			if selectoption = 1 //"Use existing alt"
				then do 
					altinfo = GetDBInfo(AltHwyFile_ar[tp])
					if altinfo = null 
						then do
							message = message + {"AltHwyFile required!"}
							keepgoing = "No"
							goto badfiles
						end
	
				// Modify arguments in memory - NOT in arguments file to create file, will reset args to originals later
				// Run Build, Areatype, Capspd as needed
				if tp = 1 then do
					Args.[AM Peak Hwy Name].value = AltHwyName_ar[tp]
				end 
				else if tp = 2 then do
					Args.[PM Peak Hwy Name].value = AltHwyName_ar[tp]
				end 
				else do
					Args.[Offpeak Hwy Name].value = AltHwyName_ar[tp]
				end 	
				Args.[Run Year].value = AltHwyYear
	
			if tp = 3 then do
				if runareatype = "Yes"
					then do
						message = message + {"Use network " + AltHwyName_ar[1] + ".  Run Area_Type (" + BaseYear + "), CapSpd"}
						AppendToLogFile(2, "Use network " + AltHwyName_ar[1] + ".  Run Area_Type (" + BaseYear + "), CapSpd")
						JobsToRun = {"Area_Type", "CapSpd"}
					end
					else do
						message = message + {"Use network " + AltHwyName_ar[1] + ", areaytype (" + BaseYear + "). Run CapSpd"}
						AppendToLogFile(2, "Use network " + AltHwyName_ar[1] + ", areaytype (" + BaseYear + "). Run CapSpd")
						JobsToRun = {"CapSpd"}
					end
				rtn = RunMacro("RunJob", Args, JobsToRun)
	
				if rtn[1] = 1 
					then do
						PlaySound(sysdir + "\\media\\Windows Notify.wav", "null")
						message = message + rtn[2]
						JobsToRun = null
					end
					else do
						PlaySound(sysdir + "\\media\\Windows Critical Stop.wav", "null")
						message = message + rtn[2]
						JobsToRun = null
						goto badfiles
					end
			end //if tp =3 (capspeed run just once)
				end  //selectoption = 1
	
			// Copy - check file to copy from
/*			else if selectoption = 2 
				then do
					copyinfo = GetDBInfo(CopyFromFile_ar[tp])
					if copyinfo = null 
						then do
							message =  message + {"Copy FROM file ERROR!"}
							keepgoing = "No"
							goto badfiles
						end
	
					// Overwrite?
					altinfo = getDBInfo(AltHwyFile_ar[tp])
					if altinfo <> null 
						then do
							btn = MessageBox("AltHwyFile already exists" + "\n" + "Overwrite?", 
								{{"Caption", "Warning"}, {"Buttons", "YesNo"},
			 					 {"Icon", "Warning"}})
							if btn = "No" 
								then do
									message =  message + {"User exit"}
									keepgoing = "No"
									goto badfiles
								end
								else DeleteDatabase(AltHwyFile_ar[tp])
						end // altinfo <> null
	
					// Get the scope of Copy from file
					info = GetDBInfo(CopyFromFile_ar[tp])
					scope = info[1]
					// Create a map with new name using this scope
					CreateMap(AltHwyName_ar[tp], {{"Scope", scope},{"Auto Project", "True"}})
	
					file = CopyFromFile_ar[tp]
					layers = GetDBLayers(file)
					addlayer(AltHwyName_ar[tp], "Endpoints", file, layers[1])
					addlayer(AltHwyName_ar[tp], "MetroRoads", file, layers[2])
					SetLayerVisibility("Endpoints", "False")
					SetIcon("Endpoints|", "Font Character", "Caliper Cartographic|4", 36)
					SetLayerVisibility("MetroRoads", "True")
					solid = LineStyle({{{1, -1, 0}}})
					SetLineStyle("MetroRoads|", solid)
					SetLineColor("MetroRoads|", ColorRGB(0, 0, 32000))
					SetLineWidth("MetroRoads|", 0)
	 				RenameLayer("MetroRoads", AltHwyName_ar[tp], )
	
					flds = GetFields(AltHwyName_ar[tp], "All")
					nodes = GetFields("Endpoints", "All")
	
					message = message + {"Copy " + CopyFromFile_ar[tp] + " to " + AltHwyFile_ar[tp]}
					ExportGeography(AltHwyName_ar[tp] +"|", AltHwyFile_ar[tp],{{"Field Spec",flds[2]}, {"Node Field Spec", nodes[2]}})
	
					CloseMap()
	
					// Modify arguments in memory - NOT in arguments file to create file, will reset args to originals later
					// Run Build, Areatype, Capspd as needed
					Args.[AM Peak Hwy Name].value = AltHwyNameAM
					Args.[PM Peak Hwy Name].value = AltHwyNamePM
					Args.[Offpeak Hwy Name].value = AltHwyNameOP
					Args.[Run Year].value = AltHwyYear
	
					if runareatype = "Yes"
						then do
							message = message + {"Use copied network " + AltHwyName_ar[tp] + ".  Run Area_Type (" + BaseYear + "), CapSpd"}
							AppendToLogFile(2, "Use copied network " + AltHwyName_ar[tp] + ".  Run Area_Type (" + BaseYear + "), CapSpd")
							JobsToRun = {"Area_Type", "CapSpd"}
						end
						else do
							message = message + {"Use copied network " + AltHwyName_ar[tp] + ", areaytype (" + BaseYear + "). Run CapSpd"}
							AppendToLogFile(2, "Use copied network " + AltHwyName_ar[tp] + ", areaytype (" + BaseYear + "). Run CapSpd")
							JobsToRun = {"CapSpd"}
						end
					rtn = RunMacro("RunJob", Args, JobsToRun)
	
					if rtn[1] = 1 
						then do
							PlaySound(sysdir + "\\media\\Windows Notify.wav", "null")
							message = message + rtn[2]
							JobsToRun = null
						end
						else do
							PlaySound(sysdir + "\\media\\Windows Critical Stop.wav", "null")
							message = message + rtn[2]
							JobsToRun = null
							goto badfiles
						end
	
				end // selectoption 2 (copy)
*/	
			// Create new network
//			else if selectoption = 3  // COPY REMOVED IN LAPTOP VERSION
			else if selectoption = 2 
				then do

				if tp = 3 then do		// only want to create new networks once, so no loop here; will create networks out of loop below
					goto skip2createnetworks
				end
				
			end // selectoption = 3
	
		end	//end tp loop on 3 time periods
		
		goto skipcreatenetworks		//skip create networks if selectoption <> 3
		
		skip2createnetworks:		//Create networks

			//check alt year
			iAltHwyYear = s2i(AltHwyYear)
			if (iAltHwyYear < 2000 or iAltHwyYear > 2100) 
				then do
					message = message + {"AltUserYear: " + AltHwyYear + " is not a valid year"}
					keepgoing = "No"
					goto badfiles
				end
			// Overwrite?


//needs fixing
		altinfo = getDBInfo(AltHwyFile_ar[1])

		if altinfo <> null 
			then do
				btn = MessageBox("AltHwyFile already existss" + "\n" + "Overwrite?", 
					{{"Caption", "Warning"}, {"Buttons", "YesNo"},
 					 {"Icon", "Warning"}})
				if btn = "No" 
					then do
						message =  message + {"User exit"}
						keepgoing = "No"
						goto badfiles
					end
					else DeleteDatabase(AltHwyFile_ar[tp])
			end // altinfo <> null

		// Modify arguments in memory - NOT in arguments file to create file, will reset args to originals later
		// Run Build, Areatype, Capspd as needed
		AltHwyNameAM = AltHwyName_ar[1]
		AltHwyNamePM = AltHwyName_ar[2]
		AltHwyNameOP = AltHwyName_ar[3]

		Args.[AM Peak Hwy Name].value = AltHwyNameAM
		Args.[PM Peak Hwy Name].value = AltHwyNamePM
		Args.[Offpeak Hwy Name].value = AltHwyNameOP
		Args.[Run Year].value = AltHwyYear

AppendToLogFile(0, " AM Network name sent to BuildNetwork = " + Args.[AM Peak Hwy Name].value)
AppendToLogFile(0, " PM Network name sent to BuildNetwork = " + Args.[PM Peak Hwy Name].value)
AppendToLogFile(0, " Offpeak Network name sent to BuildNetwork = " + Args.[Offpeak Hwy Name].value)

		if runareatype = "Yes"
			then do
				message = message + {" Create network " + AltHwyName_ar[tp] + ".  Run Build_Networks, Area_Type (" + BaseYear + "), CapSpd"}
				AppendToLogFile(2, " Create network " + AltHwyName_ar[tp] + ".  Run Build_Networks, Area_Type (" + BaseYear + "), CapSpd")
				JobsToRun = {"Build_Networks", "Area_Type", "CapSpd"}
			end
			else do
				message = message + {" Create network " + AltHwyName_ar[tp] + ".  Run Build_Networks, Use areatype(" + BaseYear + "), run CapSpd"}
				AppendToLogFile(2, " Create network " + AltHwyName_ar[tp] + ".  Run Build_Networks, Use areatype(" + BaseYear + "), run CapSpd")
				JobsToRun = {"Build_Networks", "CapSpd"}
			end

		rtn = RunMacro("RunJob", Args, JobsToRun)
			
		if rtn[1] = 1 
			then do
				PlaySound(sysdir + "\\media\\Windows Notify.wav", "null")
				message = message + rtn[2]
				JobsToRun = null
			end
			else do
				PlaySound(sysdir + "\\media\\Windows Critical Stop.wav", "null")
				message = message + rtn[2]
				JobsToRun = null
				goto badfiles
			end
		
		skipcreatenetworks:	// if selectoption <> 3

		ShowItem("altsubdirtext1")
		ShowItem("altsubdirtext2")
		EnableItem("dboxaltsubdir")
		EnableItem(" Run Hwy Assn ")
		goto goodfiles

		badfiles:
		PlaySound(sysdir + "\\media\\Windows Critical Stop.wav", "null")
		DisableItem(" Run Hwy Assn ")
		goodfiles:	


			
	EndItem // Set Alt Hwy

//	Text " " same, after, , 0.5														//18.0
	Text  "altsubdirtext1" 1.0, after Variable: dboxaltsubdirtext 										//19.0
	Text  "altsubdirtext2" 1.0, after Variable: dboxaltsubdirtext2 										//20.0

	// ASSIGNMENT SUB DIRECTORY
	Edit Text "dboxaltsubdir" 20.0, after, 38 Prompt: "Folder name: " Variable: AltSubDir Align: Center 
		Help:"Name of Alternative Subdirectory to create HwyAssn folder SUBDIR ONLY - no path" Disabled 

	// Run Hwy Assn BUTTON
//	Text " " same, after, , 0.5														//22.0
	Button " Run Hwy Assn " 20.0, after, 20 Help: "Run Hwy Assn (HOT, all four TOD) and totassn" do    //23.0

		keepgoing = "Yes"

		// Check if user entered alt subdir
		if AltSubDir = null
			then do
				btn = MessageBox("You must enter a subfolder for assignment", 
							{{"Caption", "Need a subfolder"}, {"Buttons", "OKCancel"},
		 					 {"Icon", "Warning"}})
						if btn = "OK" 
							then do
								keepgoing = "No"
								goto noassn
							end
						else if btn = "Cancel"
							then do 	
								keepgoing = "No"
								message = message + {"User cancel highway assignment"}
								goto noassn
							end
			end // altsubdir = null

		// check assignment subdir, create if necessary
		on error, notfound goto badcreate
		dirinfo = GetDirectoryInfo(Dir + "\\" + AltSubDir + "\\HwyAssn", "Directory")
		if dirinfo = null then CreateDirectory(Dir + "\\" + AltSubDir + "\\HwyAssn")
		dirinfo = GetDirectoryInfo(Dir + "\\" + AltSubDir + "\\HwyAssn\\HOT", "Directory")
		if dirinfo = null then CreateDirectory(Dir + "\\" + AltSubDir + "\\HwyAssn\\HOT")
		fileinfo = GetFileInfo(Dir + "\\" + AltSubDir + "\\HwyAssn\\HOT\\Assn_template.dcb")

		//*********************************************************************************************
		fileinfo2 = GetFileInfo(Dir + "\\HwyAssn\\HOT\\Assn_template.dcb")
		if fileinfo2 = null then showmessage("This is where I am bombing")
		//*********************************************************************************************

		if fileinfo = null then CopyFile(Dir + "\\HwyAssn\\HOT\\Assn_template.dcb", Dir + "\\" + AltSubDir + "\\HwyAssn\\HOT\\Assn_template.dcb")
		on error, notfound default
		
		//**************************************************************
		//goto noassn
		//**************************************************************

		// Highway assignment
		HwyAssnOK = 1
		
		TODnames1 = {"AMPeak","Midday","PMPeak","Night"}
		capfields = {"CapPk3hr","capMid","CapPk3hr","capNight"}
		TODnames2 = {"AM", "MI", "PM", "NI"}

		// Pre HOT Assign
		for i = 1 to 4 do
			datentime = GetDateandTime()
			AppendToLogFile(2, "Pre HOT Highway Assn on existing trip tables - " + TODnames1[i] + ": " + datentime)
			od_matrix = Dir + "\\tod2\\ODHwyVeh_" + TODnames1[i] + ".mtx"
			cap_field = capfields[i]
			output_bin = Dir + "\\" + AltSubDir + "\\HwyAssn\\Assn_" + TODnames1[i] + ".bin"
			if i = 1 then do
				timeperiod = "AMpeak"
			end
			else if i = 3 then do
				timeperiod = "PMpeak"
			end
			else do
				timeperiod = "Offpeak"
			end
			HwyAssnOK = RunMacro("HwyAssn_MMA", Args, od_matrix, cap_field, output_bin, timeperiod)
			od_matrix = null
			cap_field = null
			output_bin = null

			if HwyAssnOK = 0
				then do
					message = message + {"Base Highway Assn on existing trip tables - " + TODnames1[i] + " Highway Assign error"}
					AppendToLogFile(2, "Base Highway Assn on existing trip tables - " + TODnames1[i] + " Highway Assign error")
					goto noassn
				end
		end // for i (base assign)

		//HOT Assign	
		for i = 1 to 4 do	
			datentime = GetDateandTime()
			AppendToLogFile(2, "HOT Highway Assn on existing trip tables - " + TODnames1[i] + ": " + datentime)
			hwyassnarguments[1]  = TODnames2[i]
			hwyassnarguments[2]  = capfields[i]
			hwyassnarguments[3]  = "\\TOD2\\ODHwyVeh_" + TODnames1[i] + ".mtx"
			hwyassnarguments[4]  = "\\TOD2\\ODHwyVeh_" + TODnames1[i] + "hot.mtx"
			hwyassnarguments[5]  = "\\TOD2\\ODHwyVeh_" + TODnames1[i] + "hotonly.mtx"
			hwyassnarguments[6]  = "\\TOD2"
			hwyassnarguments[7]  = "\\" + AltSubDir + "\\HwyAssn"
			hwyassnarguments[8]  = "\\" + AltSubDir + "\\HwyAssn\\HOT"
			hwyassnarguments[9]  = "\\" + AltSubDir + "\\HwyAssn\\Assn_" + TODnames1[i] + ".bin"
			hwyassnarguments[10] = "\\" + AltSubDir + "\\HwyAssn\\HOT\\Assn_" + TODnames1[i] + "hot.bin"
			hwyassnarguments[11] = "HOT3"
	
			if i = 1 then do
				timeperiod = "AMpeak"
			end
			else if i = 3 then do
				timeperiod = "PMpeak"
			end
			else do
				timeperiod = "Offpeak"
			end
							

			HwyAssnOK = runmacro("HwyAssn_HOT", Args, hwyassnarguments, timeperiod)
			if HwyAssnOK = 0
				then do
					message = message + {"HOT Highway Assn on existing trip tables - " + TODnames1[i] + " Highway Assign error"}
					AppendToLogFile(2, "HOT Highway Assn on existing trip tables - " + TODnames1[i] + " Highway Assign error")
					goto noassn
				end
		end // for i (HOT)

		// TotAssn
		datentime = GetDateandTime()
		AppendToLogFile(2, "HOT Highway Assn on existing trip tables - TotAssn: " + datentime)
		AssnSubDir = Dir + "\\" + AltSubDir + "\\hwyassn\\HOT"
		assntype = "HOT3+"
	
		TotAssnOK = RunMacro("TotAssn", Args, AssnSubDir, assntype)
 		AssnSubDir = null
		assntype = null

		datentime = GetDateandTime()
		message = msessage + {"Hwy Assn on existing trip tables complete" + datentime}
		AppendToLogFile(2, "User exit, HwyAssn on existing trip tables: " + datentime)

		goto noassn

		badcreate:
		message = msessage + {"Error / notfound creating " + AltSubDir}
				
		noassn:
		
	enditem

	// message box
//	Text " " same, after, , 0.5
	Text " Messages " 3.0, after
	Scroll List "messageslist" 2.0, after, 62, 3.0 List: message 

	// User clear
//	Text " " same, after, , 0.5
	Button " Clear " 18.0, after Help: "Clear dialog box entries" do
		AltHwyNameAM = null
		AltHwyNamePM = null
		AltHwyNameOP = null
		AltHwyFileAM = null
		AltHwyFilePM = null
		AltHwyFileOP = null
		AltSubDir = null
		selectoption = 0
		DisableItem("dboxcopyhwyfileAM")
		HideItem("dboxcopyhwyfileAM")
		DisableItem("dboxcopyhwyfilePM")
		HideItem("dboxcopyhwyfilePM")
		DisableItem("dboxcopyhwyfileOP")
		HideItem("dboxcopyhwyfileOP")
		DisableItem("dboxcopyhwybuttonAM")
		HideItem("dboxcopyhwybuttonAM")
		DisableItem("dboxcopyhwybuttonPM")
		HideItem("dboxcopyhwybuttonPM")
		DisableItem("dboxcopyhwybuttonOP")
		HideItem("dboxcopyhwybuttonOP")
		HideItem("dboxcreatemsg")
		DisableItem("dboxalthwyfileAM")
		HideItem("dboxalthwyfileAM")
		DisableItem("dboxalthwyfilePM")
		HideItem("dboxalthwyfilePM")
		DisableItem("dboxalthwyfileOP")
		HideItem("dboxalthwyfileOP")
		DisableItem("dboxalthwybuttonAM")
		HideItem("dboxalthwybuttonAM")
		DisableItem("dboxalthwybuttonPM")
		HideItem("dboxalthwybuttonPM")
		DisableItem("dboxalthwybuttonOP")
		HideItem("dboxalthwybuttonOP")
		DisableItem("dboxalthwyyear")
		HideItem("dboxalthwyyear")
		DisableItem(" Set Alt Hwy ")
		HideItem("altsubdirtext1")
		HideItem("altsubdirtext2")
		DisableItem("dboxaltsubdir")
		DisableItem(" Run Hwy Assn ")
	enditem

	// User return
	Button " Return " 38.0, same Help: "Exit to main menu" Cancel do	
		message = message + {"Assign on Existing Trip Tables - User Exit"}
		JobsToRun = null
		// Reset Args so it doesn't overwrite originals
		Args.[Run Year].Value = BaseYear
		Args.[AM Peak HwyName].value = BaseHwyNameAM
		Args.[PM Peak HwyName].value = BaseHwyNamePM
		Args.[Offpeak HwyName].value = BaseHwyNameOP
		datentime = GetDateandTime()
		AppendToLogFile(2, "User exit, HwyAssn on existing trip tables: " + datentime)
		return({0,message})
	enditem
//	Text " " same, after, , 0.5
	

// **************************  Close DBox *******************************************

	Close do
		// Reset Args so it doesn't overwrite originals
		Args.[Run Year].Value = BaseYear
		Args.[AM Peak HwyName].value = BaseHwyNameAM
		Args.[PM Peak HwyName].value = BaseHwyNamePM
		Args.[Offpeak HwyName].value = BaseHwyNameOP
		datentime = GetDateandTime()
		AppendToLogFile(1, "Exit HwyAssn on existing trip tables: " + datentime)
		return({0,message})
	EndItem


EndDBox