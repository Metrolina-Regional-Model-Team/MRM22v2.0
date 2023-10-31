Macro "Build_Networks" (Args)
//This macro and Build_HwyNet replace regional_network.rsc
// call build_networks dbox, macro call from runjob to conform to other calls

// 5/30/19, mk: This version is set up to create three distinct networks: AM peak, PM peak, and offpeak

	runrtn = RunDBox("build_ntwks", Args)
	return(runrtn)

EndMacro

DBox "build_ntwks" (Args)
//Interface to get master files etc for building a highway network
// This was part of work to build a master transit network in Jan, 2015 - the transit stuff 
// was too complex and cumbersome to be practical, but some of the code may be worthwhile
// New theory on transit master is 
//   1.  Macro to pull check highway links in each project that either are added or subtracted
//          build an array of all transit routes on that link
//   2.  Macro to do transit route editing - remove links and add (shortest path) 
//   I have not tested this.


init do
	createhwy = 0
	createtrn = 0
	MRMDir = Args.[MRM Directory].value
	Dir = Args.[Run Directory].value
	RunYear = Args.[Run Year].value
	TAZFile = Args.[TAZ File].value
	AMPkHwyName = Args.[AM Peak Hwy Name].value		
	PMPkHwyName = Args.[PM Peak Hwy Name].value		
	OPHwyName = Args.[Offpeak Hwy Name].value		
	ReportFile = Args.[Report File].value
	LogFile = Args.[Log File].value
	
	ProgLoc = GetProgram()
	ProgVersion = ProgLoc[5]

	SetLogFileName(LogFile)
	SetReportFileName(ReportFile)

	HideItem("mstrhwygood")	
	HideItem("prjfilegood")	
	HideItem("tollfilegood")	
	HideItem("mstrhwyerror")	
	HideItem("prjfileerror")	
	HideItem("tollfileerror")
	HideItem(" Error/Warning messages ")
	HideItem("netmessageslist")	

	msg = null
	datentime = GetDateandTime()
	AppendToLogFile(1, "Enter Build_Networks: " + datentime)


AppendToLogFile(0, " AM Network name used in BuildNetwork = " + AMPkHwyName)
AppendToLogFile(0, " PM Network name used in BuildNetwork = " + PMPkHwyName)
AppendToLogFile(0, " Offpeak Network name used in BuildNetwork = " + OPHwyName)



enditem

// each file has a button (file open), and "ok" (green light) and "bad" (red light).  Both buttons are hidden until you
// hit the "create networks" button, where all of the checks are done.   buttons - ok and bad are in the same location and don't do anything

//	1	MasterHwyFile	Master Highway Network		highway side required.  Optional on transit
//	2	ProjectFile	Project File			always required
//	3	TollFile	Toll file			highway side required
//	4	Transit_Master	Transit Master route system	transit side required
//	5	Routes_Master	Routes_Master.dbf		transit side required


// button x + 1.4, y -0.3


	Frame 1, 1, 70, 14 Prompt: "Build Highway Network"

	Text "MRM Directory: " 2.0, 3.0
	Text 20.0, 3.0, 30.0 Variable: MRMDir Framed
	Text "Run Directory: " 2.0, 4.5
	Text 20.0, 4.5, 30.0 Variable: Dir Framed
	Text "Run Year: " 2.0, 6.0
	Text 20.0, 6.0, 30.0 Variable: RunYear Framed


//	1	MasterHwyFile	Master Highway Network		highway side required.  Optional on transit

	Edit Text "mstrhwy" 20, 8.0, 40  Prompt: "Master Highway File:" Variable: MasterHwyFile Help:"Choose master highway network"  
	Button "chgmstrhwy" 61.4, 7.7 Icon: "bmp\\buttons|148" Help: "Change the master hwy network" do
		on escape goto esc1
		MasterHwyFile = ChooseFile({{"Standard","*.dbd"}},"Choose the Master Network Geographic File",{{"Initial Directory", MRMDir +"\\MasterNet"}})
		esc1:
		on escape default
		enditem
	Button "mstrhwygood" 66.0, 7.7 Icon: "bmp\\buttons|105" Help: "Master highway file found" Hidden do	
		enditem
	Button "mstrhwyerror" 66.0, 7.7 Icon: "bmp\\buttons|127" Help: "Master highway file not found.  Try again" Hidden do	
		on escape goto esc11
		MasterHwyFile = ChooseFile({{"Standard","*.dbd"}},"Choose the Master Network Geographic File",{{"Initial Directory", MRMDir +"\\MasterNet"}})
		esc11:
		on escape default
		enditem


//	2	ProjectFile	Project File			always required

	Edit Text "prjfile" 20, 9.5, 40 Prompt: "Projects file:" Variable: ProjectFile Help:"Choose the project file"  
	Button "chgprjfile" 61.4, 9.2 Icon: "bmp\\buttons|148" Help: "Change the project file" do
		on escape goto esc2
		ProjectFile = ChooseFile({{"DBASE","*.dbf"}},"Choose the Project List File",{{"Initial Directory", MRMDir +"\\MasterNet"}})
		esc2:
		on escape default
		enditem
	Button "prjfilegood" 66.0, 9.2 Icon: "bmp\\buttons|105" Help: "Project file found" Hidden do	
		enditem
	Button "prjfileerror" 66.0, 9.2 Icon: "bmp\\buttons|127" Help: "Project file not found.  Try again" Hidden do	
		on escape goto esc21
		ProjectFile = ChooseFile({{"DBASE","*.dbf"}},"Choose the Project List File",{{"Initial Directory", MRMDir +"\\MasterNet"}})
		esc21:
		on escape default
		enditem


//	3	TollFile	Toll file			highway side required

	Edit Text "tollfile" 20, 11, 40 Prompt: "Toll file:" Variable: TollFile Help:"Choose toll file"  
	Button "chgtollfile" 61.4, 10.7 Icon: "bmp\\buttons|148" Help: "Change the toll file" do
		on escape goto esc3
		TollFile = ChooseFile({{"BIN","*.bin"}},"Choose the Toll Project File",{{"Initial Directory", MRMDir +"\\MasterNet"}})
		esc3:
		on escape default
		enditem
	Button "tollfilegood" 66.0, 10.7 Icon: "bmp\\buttons|105" Help: "Toll file found" Hidden do	
		enditem
	Button "tollfileerror" 66.0, 10.7 Icon: "bmp\\buttons|127" Help: "Toll file not found.  Try again" Hidden do	
		on escape goto esc31
		TollFile = ChooseFile({{"BIN","*.bin"}},"Choose the Toll Project File",{{"Initial Directory", MRMDir +"\\MasterNet"}})
		esc31:
		on escape default
		enditem


//	4	Transit_Master	Transit Master route system	transit side required

//	Edit Text "trnmstrfile" 20, 6, 80 Prompt: "Master Transit file:" Variable: Transit_Master Help:"Choose master transit route system (.rts)"  Hidden
//	Button "chgtrnmstrfile" 101.4, 5.7 Icon: "bmp\\buttons|148" Help: "Change the master transit rts" Hidden do
//		on escape goto esc4
//		Transit_Master = ChooseFile({{"Route System","*.rts"}},"Choose the Master Transit Route System",{{"Initial Directory", MRMDir +"\\MasterNet"}})
//		esc4:
//		on escape default
//		enditem
//	Button "oktrnmstrfile" 106.0, 5.7 Icon: "bmp\\buttons|105" Help: "Transit Master file found" Hidden do	
//		enditem
//	Button "badtrnmstrfile" 106.0, 5.7 Icon: "bmp\\buttons|127" Help: "Transit Master file not found.  Try again" Hidden do	
//		on escape goto esc41
//		Transit_Master = ChooseFile({{"Route System","*.rts"}},"Choose the Master Transit Route System",{{"Initial Directory", MRMDir +"\\MasterNet"}})
//		esc41:
//		on escape default
//		enditem


//	5	Routes_Master	Routes_Master.dbf		transit side required

//	Edit Text "rtesmstrfile" 20, 7.5, 80 Prompt: "Routes.dbf master:" Variable: Routes_Master Help:"Choose routes_master dbf" Hidden  
//	Button "chgrtesmstrfile" 101.4, 7.2 Icon: "bmp\\buttons|148" Help: "Change the routes_master dbf" Hidden do
//		on escape goto esc5
//		Routes_Master = ChooseFile({{"DBASE","*.dbf"}},"Choose the ROUTES_Master DBF",{{"Initial Directory", MRMDir +"\\MasterNet"}})
//		esc5:
//		on escape default
//		enditem
//	Button "okrtesmstrfile" 106.0, 7.2 Icon: "bmp\\buttons|105" Help: "Master routes.dbf file found" Hidden do	
//		enditem
//	Button "badrtesmstrfile" 106.0, 7.2 Icon: "bmp\\buttons|127" Help: "Master routes.dbf file not found.  Try again" Hidden do	
//		on escape goto esc51
//		Routes_Master = ChooseFile({{"DBASE","*.dbf"}},"Choose the ROUTES_Master DBF",{{"Initial Directory", MRMDir +"\\MasterNet"}})
//		esc51:
//		on escape default
//		enditem



//Run the model	
	Text "Build Highway networks:"  1.5, 22.0
	Button "buildhwy" 25, 22.0 Icon: "bmp\\buttons|419" Help: "Build Run year highway networks." do	
		HwyOK = 1

//	1	MasterHwyFile	Master Highway Network		highway side required.  Optional on transit


		InfoMstrHwy = GetFileInfo(MasterHwyFile)
		if InfoMstrHwy <> null 
			then do
				ShowItem("mstrhwygood")
				HideItem("mstrhwyerror")
			end
			else do
				errcount = errcount + 1
				msg = msg + {"Master Hwy file: " + MasterHwyFile + " not found"}
				AppendToLogFile(1, "Master Hwy file: " + MasterHwyFile + " not found")
				HideItem("mstrhwygood")
				ShowItem("mstrhwyerror")
			end

		if MasterHwyFile <> null
			then do
				MasterInfo = GetDBInfo(MasterHwyFile)
				MasterVersion = MasterInfo[3]
				if ProgVersion > 5 and MasterVersion < 7
					then do 	
						errcount = errcount + 1
						msg = msg + {"Master Hwy file: " + MasterHwyFile + " NOT suitable for TransCad version 7"}
						AppendToLogFile(1, "Master Hwy file: " + MasterHwyFile + " NOT suitable for TransCad version 7")
						HideItem("mstrhwygood")
						ShowItem("mstrhwyerror")
					end		
				if ProgVersion < 6 and MasterVersion > 5
					then do 	
						errcount = errcount + 1
						msg = msg + {"Master Hwy file: " + MasterHwyFile + " NOT suitable for TransCad version 5"}
						AppendToLogFile(1, "Master Hwy file: " + MasterHwyFile + " NOT suitable for TransCad version 5")
						HideItem("mstrhwygood")
						ShowItem("mstrhwyerror")
					end		
			end

//	2 ProjectFile	Project File			always required

		InfoPrjFile = GetFileInfo(ProjectFile)
		if InfoPrjFile <> null 
			then do
				ShowItem("prjfilegood")
				HideItem("prjfileerror")
			end	
			else do
				errcount = errcount + 1
				msg = msg + {"Project file: " + ProjectFile + " not found"}
				AppendToLogFile(1, "Project file: " + ProjectFile + " not found")
				HideItem("prjfilegood")
				ShowItem("prjfileerror")
			end

//	3	TollFile	Toll file			highway side required

		InfoTollFile = GetFileInfo(TollFile)
		if InfoTollFile <> null 
			then do
				ShowItem("tollfilegood")
				HideItem("tollfileerror")
			end
			else do
				errcount = errcount + 1
				msg = msg + {"Toll file: " + TollFile + " not found"}
				AppendToLogFile(1, "Toll file: " + TollFile + " not found")
				HideItem("tollfilegood")
				ShowItem("tollfileerror")
			end

//	7	Transit_Master	Transit Master route system	transit side required

//		checkfiles7 :
//		if createtrn = 0 then goto checkfiles8
//		infotrnmstrfile = GetFileInfo(Transit_Master)
//		if infotrnmstrfile = null then goto badinfotrnmstrfile
//		else do
//			HideItem("badtrnmstrfile")
//			ShowItem("oktrnmstrfile")
//			goto checkfiles8
//		end
//		badinfotrnmstrfile:
//			errcount = errcount + 1
//			HideItem("oktrnmstrfile")
//			ShowItem("badtrnmstrfile")


//	8	Routes_Master	Routes_Master.dbf		transit side required

//		checkfiles8 :
//		if createtrn = 0 then goto checkedfiles
//		infortesmstrfile = GetFileInfo(Routes_Master)
//		if infotrnmstrfile = null then goto badinfortesmstrfile
//		else do
//			HideItem("badrtesmstrfile")
//			ShowItem("okrtesmstrfile")
//			goto checkedfiles
//		end
//		badinfortesmstrfile:
//			errcount = errcount + 1
//			HideItem("okrtesmstrfile")
//			ShowItem("badrtesmstrfile")
//


	//  	files ok
//		checkedfiles:

		if errcount > 0 then do		
			msg = msg + {"Error setting files for build highway"}
			AppendToLogFile(1, "Error setting files for build highway")
//			showarray(rtsmstrinfo)
			HwyOK = 0
		end

		if HwyOK = 0 then goto NoRun

//	2	Dir		Metrolina Directory		always required
//	3	theyear		RunYear				always required
//	4	MasterHwyFile	Master Highway Network		highway side required.  Optional on transit
//	5	ProjectFile	Project File			always required
//	6	TollFile	Toll file			highway side required
//	7	Transit_Master	Transit Master route system	transit side required
//	8	Routes_Master	Routes_Master.dbf		transit side required

		MasterInfo = GetFileInfo(MasterHwyFile)
		MasterTimeStamp = MasterInfo[7] + " " + MasterInfo[8]
		ProjInfo = GetFileInfo(ProjectFile)
		ProjTimeStamp = ProjInfo[7] + " " + ProjInfo[8]
		TollInfo = GetFileInfo(TollFile)
		TollTimeStamp = TollInfo[7] + " " + TollInfo[8]

		AppendToReportFile(1, "Build Highway Networks")
		AppendToReportFile(2, "Master Highway File:   " + MasterHwyFile + "  TimeStamp: " + MasterTimeStamp)
		AppendToReportFile(2, "Project File:                " + ProjectFile + "  TimeStamp: " + ProjTimeStamp)
		AppendToReportFile(2, "Toll File:                     " + TollFile + "  TimeStamp: " + TollTimeStamp)
		
//	Read project file - create prj_year array - used by both highway and transit
		datentime = GetDateandTime()
		AppendtoLogFile(2, " ")
		AppendToLogFile(2, "Enter Fill_prj_year: " + datentime)

		prj_year = RunMacro("Fill_prj_year", ProjectFile)

		if prj_year = null then goto badprjyear
		datentime = GetDateandTime()
		AppendToLogFile(2, "Exit Fill_prj_year: " + datentime)
		NumProj = prj_year.length
		AppendToReportFile(2, "Number of projects for " + RunYear + ":   " + i2s(NumProj))
		
//	do AM Peak highway network first
			datentime = GetDateandTime()
			AppendtoLogFile(2, " ")
			AppendToLogFile(2, "Enter Build_HwyNet (AM): " + datentime)
			timeperiod = "AMpeak"

			HwyName = AMPkHwyName
			AMPkHwyName = RunMacro("Build_HwyNet", MRMDir, Dir, RunYear, MasterHwyFile, prj_year, TollFile, HwyName, timeperiod)			
			datentime = GetDateandTime()
			AppendToLogFile(2, "Exit Build_HwyNet (AM): " + datentime)

			Args.[AM Peak Hwy Name].value = AMPkHwyName

		if AMPkHwyName = null 
			then do
				msg = msg + {"Error return from Build_HwyNet (AM Peak)"}
				AppendToLogFile(1, "Error return from Build_HwyNet (AM Peak)")
				HwyOK = 0
				goto didnotwork
			end
			timeperiod = null
			
//	next do PM Peak highway network
			datentime = GetDateandTime()
			AppendtoLogFile(2, " ")
			AppendToLogFile(2, "Enter Build_HwyNet (PM): " + datentime)
			timeperiod = "PMpeak"

			HwyName = PMPkHwyName
			PMPkHwyName = RunMacro("Build_HwyNet", MRMDir, Dir, RunYear, MasterHwyFile, prj_year, TollFile, HwyName, timeperiod)			
			datentime = GetDateandTime()
			AppendToLogFile(2, "Exit Build_HwyNet (PM): " + datentime)

			Args.[PM Peak Hwy Name].value = PMPkHwyName

		if PMPkHwyName = null 
			then do
				msg = msg + {"Error return from Build_HwyNet (PM Peak)"}
				AppendToLogFile(1, "Error return from Build_HwyNet (PM Peak)")
				HwyOK = 0
				goto didnotwork
			end
			timeperiod = null

//	next do Offpeak highway network
			datentime = GetDateandTime()
			AppendtoLogFile(2, " ")
			AppendToLogFile(2, "Enter Build_HwyNet (Offpeak): " + datentime)
			timeperiod = "Offpeak"

			HwyName = OPHwyName
			OPHwyName = RunMacro("Build_HwyNet", MRMDir, Dir, RunYear, MasterHwyFile, prj_year, TollFile, HwyName, timeperiod)			
			timeperiod = null
			datentime = GetDateandTime()
			AppendToLogFile(2, "Exit Build_HwyNet (Offpeak): " + datentime)

			Args.[Offpeak Hwy Name].value = OPHwyName

		if OPHwyName = null 
			then do
				msg = msg + {"Error return from Build_HwyNet (Offpeak)"}
				AppendToLogFile(1, "Error return from Build_HwyNet (Offpeak)")
				HwyOK = 0
				goto didnotwork
			end

			else goto didwork
			
		badprjyear:
		HwyOK = 0
		msg = msg + {"Build_Networks: Error - prj_year array not created"}
		AppendToLogFile(1, "Build_Networks: Error: - prj_year array not created")
		goto didnotwork
		
		NoRun:
		didnotwork:
		if HwyOK = 0
			then do	
				ShowItem(" Error/Warning messages ")
				ShowItem("netmessageslist")
			end	
		goto quit
		
		didwork:
			datentime = GetDateandTime()
			AppendToLogFile(1, "Exit Build_Networks: " + datentime)

		return({1, msg})
		quit:
enditem

	Text " Error/Warning messages " 5.0, 16.0 Hidden
	Scroll List "netmessageslist" 5.0, 17.0, 50, 3.0 List: msg Hidden


	Text "Exit:" 60.0, 22.0
	Button "exit2" 66.0, 22.0 Icon: "bmp\\buttons|440" Help: "Return to MRM." do	
		datentime = GetDateandTime()
		AppendToLogFile(1, "Exit Build_Networks: " + datentime)
		return({0, msg})
	enditem

endDBox


