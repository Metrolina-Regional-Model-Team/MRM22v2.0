Dbox "MasterDBox" center, center Title: "Metrolina Regional Model: MRM2001 (May, 2020)"
	Init do

		//TU DU

		// MOVED TOD1 OFFPEAK FROM BEFORE TO AFTER FEEDBACK (HBW and NHB offpeak change in feedback),  JWM 11/22/16
		// Arguments revisions,  JWM 1/24/16
		// Repair to TC_log to write createdir messages 1/29/18
		//9/9/20, moved transit stats to after HOT assign
				
		//Icons from bmp\\buttons - see \macros\utilities\FindButtons.rsc
		//  	Green light			bmp\\buttons|105
		//  	Yellow light		bmp\\buttons|528
		//  	Red light			bmp\\buttons|127
		//  	Check mark 			bmp\\buttons|419
		//  	X mark 				bmp\\buttons|440
		//  	Emphatic X			bmp\\buttons|620 
		//  	Continue arrows     bmp\\buttons|361
		//formats
		//	Text "MRM Directory:" 7,1 
		//	Text 20, 1 Variable: MRMUser Framed
		// 	button x + 1.4, y -0.3
		//  buttons.bmp 
		//		group 1 = 1-33,
		//  	divider (34-35), 36-67 (32 icons)
		//		divider (68-69), 70-102

		// Runs trip model for commercial vehicles (COM, MTK, HTK)
		// Selects either Trip or Tour mode split Constants files

		ModelBaseYear = 2015

		Dir = null
		METDir = null
		MRMDir = null
		RunYear = null
		TAZFile = null
		LandUseFile = null
		ScenName = null
		AMPkHwyName = null
		PMPkHwyName = null
		OPHwyName = null

		DirUser = null
		METUser = null
		MRMUser = null
		YearUser = null
		TAZUser = null
		LUUser = null
		ScenNameUser = null
		AMPkHwyNameUser = null
		PMPkHwyNameUser = null
		OPHwyNameUser = null
	
		DirArgs = null
		METArgs = null
		MRMArgs = null
		YearArgs = null
		TAZArgs = null
		LUArgs = null
		ScenNameArgs = null
		AMPkHwyNameArgs = null
		PMPkHwyNameArgs = null
		OPHwyNameArgs = null

		EditArgs = null
			
		DirSignalStatus = 1
		MRMSignalStatus = 1
		YearSignalStatus = 1
		TAZSignalStatus = 1
		LUSignalStatus = 1

		DirExist = 0
		METExist = 0
		MRMExist = 0

		NumTAZ = 0
		NumIntTAZ = 0
		NumExtTAZ = 0
//		NutTAZArgs = 0
//		NumIntTAZArgs = 0
//		NumExtTAZArgs = 0
		checkLUTAZ = "False"	//added
		
		modeltype = null

		CreateDirectory = 0
		Message = null
		Args = null

		keepgoing = "Yes"
			
		sysdir = GetSystemDirectory()

		//TransCad version and build
		ProgLoc = GetProgram()
		ProgPath = SplitPath(ProgLoc[1])
		ProgDir = ProgPath[1] + ProgPath[2]
		ProgVersion = ProgLoc[5]
		ProgBuild = ProgLoc[4]

		// MRM default - in \TransCad directory
		RunMacro("GetMRMDefault")

		MRMUser = MRMDefault
		if MRMDefault <> null then MRMSignalStatus = 2

//********************* Start of Directory / File section *************************************************

		//*******Arrays of job (program) names - macro name and jobstatus in Args are same ********************
	//Trip Model
		runbasejobs = {"Build_Networks", "Area_Type", "CapSpd", "RouteSystemSetUp", 
				"HwySkim_Peak", "HwySkim_Free", 
				"Prepare_Transit_Files", "FillParkCost", "AutoSkims_Free", "AutoSkims_Peak",  "Reg_NonMotorized", 
				"Reg_PPrmW", "Reg_PPrmD", "Reg_PPrmDrop", "Reg_PBusW", "Reg_PBusD", "Reg_PBusDrop", 
				"Reg_OPPrmW", "Reg_OPPrmD", "Reg_OPPrmDrop", "Reg_OPBusW", "Reg_OPBusD", "Reg_OPBusDrop",
				"ExtStaforTripGen", "Trip_Generation", "Aggregate_TripGen", "EE_Trips", 
				"TD_TranPath_Peak", "TD_TranPath_Free", 
				"TDHBW1", "TDHBW2", "TDHBW3", "TDHBW4", 
				"TDHBS1", "TDHBS2", "TDHBS3", "TDHBS4", "TDHBO1", "TDHBO2", "TDHBO3", "TDHBO4", 
				"TDJTW", "TDATW", "TDNWK",  
				"TDSCH", "TDHBU",
				"TDCOM", "TDMTK", "TDHTK", 
				"TDEIW", "TDEIN", "TDEIC", "TDEIM", "TDEIH", 
				"TDIEW","TDIEN", "TDIEC", "TDIEM", "TDIEH",
				"TOD1_HBW_Peak", "TOD1_HBO_Peak", "TOD1_NHB_Peak", "TOD1_HBU_Peak",
				"MS_RunPeak", "TOD2_COM_MTK_HTK", "TOD2_AMPeak", "HwyAssn_RunAMPeak"}
			
		runfeedbackjobs = {"Feedback_TravelTime", "HwySkim_Peak", "AutoSkims_Peak", 
				"Reg_PPrmW", "Reg_PPrmD", "Reg_PPrmDrop", "Reg_PBusW", "Reg_PBusD", "Reg_PBusDrop",
				"TD_TranPath_Peak", "TDHBW1", "TDHBW2", "TDHBW3", "TDHBW4", "TDJTW", "TDEIW", "TDIEW",
				"TOD1_HBW_Peak", "TOD1_NHB_Peak", 
				"MS_RunPeak", "TOD2_AMPeak", "HwyAssn_RunAMPeak"}
				
		runpostfeedbackjobs = {"TDMatrixStats",
				// This line switchd from runbasejobs to run runpostfeedback jobs (TOD1_ppp_OFFPEAK)
				"TOD1_HBW_OffPeak", "TOD1_HBO_OffPeak", "TOD1_NHB_OffPeak", "TOD1_HBU_OffPeak",
				"MS_RunOffPeak", "MSMatrixStats", "TOD2_PMPeak", "TOD2_Midday", "TOD2_Night", 
				"HwyAssn_RunPMPeak", "HwyAssn_RunMidday", "HwyAssn_RunNight"}

	 	runtranassnjobs = {"Transit_Input", 
 				"PPrmW_Assign", "PPrmD_Assign", "PPrmDrop_Assign", "PBusW_Assign", "PBusD_Assign", "PBusDrop_Assign", 
 				"OPPrmW_Assign", "OPPrmD_Assign", "OPPrmDrop_Assign", "OPBusW_Assign", "OPBusD_Assign", "OPBusDrop_Assign"}

	 	runHOTassnjobs = {"HwyAssn_RunHOTAMPeak", "HwyAssn_RunHOTPMPeak", "HwyAssn_RunHOTMidday", "HwyAssn_RunHOTNight", 
 				"HwyAssn_RunHOTTotAssn", "Transit_Pax_Stats", "Transit_Operations_Stats", "Transit_Boardings", "Transit_RunStats", 
 				"ODMatrixStats", "VMTAQ", "AvgTripLenTrips"}
 	
		hwycalibrationjobs = {"HighwayCalibrationStats"}


 		// all jobs in model stream - but no duplicates for feedback - used in dbox lists
		runbasefeedback = runbasejobs + {"Feedback_TravelTime"} + runpostfeedbackjobs + runtranassnjobs + runHOTassnjobs

		// array for passing jobname arrays
		dim runjobsets[5]
	 	runjobsets[1] = runbasejobs
		runjobsets[2] = runfeedbackjobs
		runjobsets[3] = runpostfeedbackjobs
		runjobsets[4] = runtranassnjobs
		runjobsets[5] = runHOTassnjobs

	//Tour Model
		runbasejobs_tour = {"Build_Networks", "Area_Type", "CapSpd", "RouteSystemSetUp", 
				"HwySkim_Peak", "HwySkim_Free", 
				"Prepare_Transit_Files", "FillParkCost", "AutoSkims_Free", "AutoSkims_Peak",  "Reg_NonMotorized", 
				"Reg_PPrmW", "Reg_PPrmD", "Reg_PPrmDrop", "Reg_PBusW", "Reg_PBusD", "Reg_PBusDrop", 
				"Reg_OPPrmW", "Reg_OPPrmD", "Reg_OPPrmDrop", "Reg_OPBusW", "Reg_OPBusD", "Reg_OPBusDrop",
				"ExtStaforTripGen", "HHMET", "Tour_Accessibility", "Tour_XX", "Tour_Frequency",
				"TD_TranPath_Peak", "TD_TranPath_Free", 
				"Tour_DestinationChoice", "Tour_IS", "Tour_IS_Location", "Tour_TruckTGTD", 
				"Tour_ToD1", "Tour_TripAccumulator", "MS_RunPeak",
				"Tour_TOD2_AMPeak", "HwyAssn_RunAMPeak"}
						
		runfeedbackjobs_tour = {"Feedback_TravelTime", "HwySkim_Peak", "AutoSkims_Peak", 
				"Reg_PPrmW", "Reg_PPrmD", "Reg_PPrmDrop", "Reg_PBusW", "Reg_PBusD", "Reg_PBusDrop",
				"Tour_DC_FB", "Tour_IS_FB", "Tour_IS_Location_FB",
				"Tour_ToD1_FB", "Tour_TripAccumulator_FB", "MS_RunPeak", 
				"Tour_TOD2_AMPeak", "HwyAssn_RunAMPeak"}

		runpostfeedbackjobs_tour = {"MS_RunOffPeak", "MSMatrixStats", //"Tour_TF_CountySummaryStats", 
				"Tour_TOD2_PMPeak", "Tour_TOD2_Midday", "Tour_TOD2_Night", 
				"HwyAssn_RunPMPeak", "HwyAssn_RunMidday", "HwyAssn_RunNight"}
//"TDMatrixStats", 
	 	runHOTassnjobs_tour = {"HwyAssn_RunHOTAMPeak", "HwyAssn_RunHOTPMPeak", "HwyAssn_RunHOTMidday", "HwyAssn_RunHOTNight", 
 				"HwyAssn_RunHOTTotAssn", "Transit_Pax_Stats", "Transit_Operations_Stats", "Transit_Boardings", "Transit_RunStats", 
 				"ODMatrixStats", "VMTAQ", "AvgTripLenTrips_tour", "Tour_RunStats"}

		hwycalibrationjobs_tour = {"HighwayCalibrationStats_tour"}


 		// all jobs in model stream - but no duplicates for feedback - used in dbox lists
		runbasefeedback = runbasejobs_tour + {"Feedback_TravelTime"} + runpostfeedbackjobs_tour + runtranassnjobs + runHOTassnjobs_tour

		// array for passing jobname arrays
		dim runjobsets_tour[5]
	 	runjobsets_tour[1] = runbasejobs_tour
		runjobsets_tour[2] = runfeedbackjobs_tour
		runjobsets_tour[3] = runpostfeedbackjobs_tour
		runjobsets_tour[4] = runtranassnjobs
		runjobsets_tour[5] = runHOTassnjobs_tour
	


		//Subdirectories
		MRMSubDir = 
			{"\\ExtSta", "\\HOT", "\\MasterNet", "\\MS_Control_Template", "\\ParkCost", "\\Pgm", "\\Pgm\\ModeChoice", 
			 "\\Pgm\\CapSpdFactors", "\\Pgm\\FrictionFactors", "\\TAZ"}	

		MRMRunYearSubDir =
			{"\\Ext", "\\LandUse"}

		METSubDir = 
			{"\\ExtSta", "\\MS_Control_Template", "\\Pgm", "\\Pgm\\ModeChoice", "\\Pgm\\CapSpdFactors",
			 "\\Pgm\\FrictionFactors", "\\Pgm\\Param", "\\TAZ"}

		RunDirSubDir = 
			{"\\AutoSkims", "\\Ext", "\\HwyAssn", "\\LandUse", "\\ModeSplit", "\\Report", "\\Skims", "\\TD", "\\TG", "\\TOD2",
			 "\\TranAssn", "\\TripTables", "\\HwyAssn\\HOT",
			 "\\TranAssn\\PPrmW", "\\TranAssn\\PPrmD", "\\TranAssn\\PPrmDrop", "\\TranAssn\\OPPrmW", "\\TranAssn\\OPPrmD",
			 "\\TranAssn\\OPPrmDrop", "\\TranAssn\\PBusW", "\\TranAssn\\PBusD", "\\TranAssn\\PBusDrop", "\\TranAssn\\OPBusW", 
			 "\\TranAssn\\OPBusD", "\\TranAssn\\OPBusDrop",
			 "\\ModeSplit\\Inputs","\\ModeSplit\\Inputs\\Controls", "\\ModeSplit\\Results"}	


		//Metrolina files  - array: [1] = SubDir name [2] = array of files in subdir
		//added taz_atype.asc.def - required for mode choice - copied into <year> folder
		//Added 2 sets of mode choice bias and mode constant for different versions of TransCad (see METFiles in macro "Create Dir" below)
		METFiles =
			{
		 	 {"\\MS_Control_Template", 
			 {"ALTNAME_HBW_PEAK.bat", "ALTNAME_HBW_OFFPEAK.bat", "ALTNAME_HBW_PEAK.ctl", "ALTNAME_HBW_OFFPEAK.ctl",
			  "ALTNAME_HBO_PEAK.bat", "ALTNAME_HBO_OFFPEAK.bat", "ALTNAME_HBO_PEAK.ctl", "ALTNAME_HBO_OFFPEAK.ctl",
			  "ALTNAME_NHB_PEAK.bat", "ALTNAME_NHB_OFFPEAK.bat", "ALTNAME_NHB_PEAK.ctl", "ALTNAME_NHB_OFFPEAK.ctl",
			  "ALTNAME_HBU_PEAK.bat", "ALTNAME_HBU_OFFPEAK.bat", "ALTNAME_HBU_PEAK.ctl", "ALTNAME_HBU_OFFPEAK.ctl",
			  "Mode_Choice_Script.txt", "Segment_Map.txt", "Segment_Map.txt.def",
			  "TAZ_ATYPE_TRANSIT_FLAGS.dbf", "TAZ_ATYPE.asc.def"}},

		 	 {"\\MS_Control_Template\\Trip", 
			  {"HBW_PEAK_Bias.txt", "HBW_PEAK_Bias.txt.def", "HBW_PEAK_Constant.txt", "HBW_PEAK_Constant.txt.def",
			   "HBW_OFFPEAK_Bias.txt", "HBW_OFFPEAK_Bias.txt.def", "HBW_OFFPEAK_Constant.txt", "HBW_OFFPEAK_Constant.txt.def",
			   "HBO_PEAK_Bias.txt", "HBO_PEAK_Bias.txt.def", "HBO_PEAK_Constant.txt", "HBO_PEAK_Constant.txt.def",
			   "HBO_OFFPEAK_Bias.txt", "HBO_OFFPEAK_Bias.txt.def", "HBO_OFFPEAK_Constant.txt", "HBO_OFFPEAK_Constant.txt.def",
			   "NHB_PEAK_Bias.txt", "NHB_PEAK_Bias.txt.def", "NHB_PEAK_Constant.txt", "NHB_PEAK_Constant.txt.def",
			   "NHB_OFFPEAK_Bias.txt", "NHB_OFFPEAK_Bias.txt.def", "NHB_OFFPEAK_Constant.txt", "NHB_OFFPEAK_Constant.txt.def",
			   "HBU_PEAK_Bias.txt", "HBU_PEAK_Bias.txt.def", "HBU_PEAK_Constant.txt", "HBU_PEAK_Constant.txt.def",
			   "HBU_OFFPEAK_Bias.txt", "HBU_OFFPEAK_Bias.txt.def", "HBU_OFFPEAK_Constant.txt", "HBU_OFFPEAK_Constant.txt.def",
			   "modes.dbf", "modexfer.dbf"}},


		 	 {"\\MS_Control_Template\\Tour", 
			  {"HBW_PEAK_Bias.txt", "HBW_PEAK_Bias.txt.def", "HBW_PEAK_Constant.txt", "HBW_PEAK_Constant.txt.def",
			   "HBW_OFFPEAK_Bias.txt", "HBW_OFFPEAK_Bias.txt.def", "HBW_OFFPEAK_Constant.txt", "HBW_OFFPEAK_Constant.txt.def",
			   "HBO_PEAK_Bias.txt", "HBO_PEAK_Bias.txt.def", "HBO_PEAK_Constant.txt", "HBO_PEAK_Constant.txt.def",
			   "HBO_OFFPEAK_Bias.txt", "HBO_OFFPEAK_Bias.txt.def", "HBO_OFFPEAK_Constant.txt", "HBO_OFFPEAK_Constant.txt.def",
			   "NHB_PEAK_Bias.txt", "NHB_PEAK_Bias.txt.def", "NHB_PEAK_Constant.txt", "NHB_PEAK_Constant.txt.def",
			   "NHB_OFFPEAK_Bias.txt", "NHB_OFFPEAK_Bias.txt.def", "NHB_OFFPEAK_Constant.txt", "NHB_OFFPEAK_Constant.txt.def",
			   "HBU_PEAK_Bias.txt", "HBU_PEAK_Bias.txt.def", "HBU_PEAK_Constant.txt", "HBU_PEAK_Constant.txt.def",
			   "HBU_OFFPEAK_Bias.txt", "HBU_OFFPEAK_Bias.txt.def", "HBU_OFFPEAK_Constant.txt", "HBU_OFFPEAK_Constant.txt.def",
			   "modes.dbf", "modexfer.dbf"}},


			{"\\TAZ", 
		 	 {"TAZNeighbors_pct.asc", "TAZNeighbors_pct.dct", "Parking_Cost_Base06.dbf", "PUMAequiv.prn"}},

			{"\\Pgm",
		 	 {"CaliperMTXF.dll","CaliperMTXF.lib","capspd.exe","SHW32.DLL",
			  "tdmet_mtx.exe", "tgmet2015_171013.exe"}},

			{"\\Pgm\\ModeChoice",  
			 {"Add_Shadow_Price.exe","CALIBMS.exe","Caliperb.dll","CaliperMTX.dll","CaliperMTXF.dll","CaliperMTXF.lib",
			  "DFORMD.DLL","Drv2PNR2Attr.exe","ExportUBMatrix.exe","HA312W32.dll","KNR_Loc_CAT.exe","SHW32.DLL", "ModeChoice.exe",
			  "UPD_DA_Dist_Time_Costv1.exe","UPD_DA_Dist_Time_Costv2.exe"}},

			{"\\Pgm\\CapspdFactors", 
			 {"capspd_factors.prn", "capspd_nodeerrors.asc", "capspd_nodeerrors.dct", "guideway20.prn"}},

			{"\\Pgm\\FrictionFactors\\Trip",  
			 {"ffhbw1.prn", "ffhbw2.prn", "ffhbw3.prn", "ffhbw4.prn", 
			  "ffhbo1.prn", "ffhbo2.prn", "ffhbo3.prn", "ffhbo4.prn",
			  "ffhbs1.prn", "ffhbs2.prn", "ffhbs3.prn", "ffhbs4.prn", 
			  "ffhbu.prn",  "ffsch.prn",  
			  "ffjtw.prn",  "ffatw.prn",  "ffnwk.prn",
			  "ffcom.prn",  "ffmtk.prn",  "ffhtk.prn",  
			  "ffeiw.prn",  "ffein.prn",  "ffeic.prn", "ffeim.prn", "ffeih.prn",
			  "ffiew.prn",  "ffien.prn",  "ffiec.prn", "ffiem.prn", "ffieh.prn"}},

			{"\\Pgm\\FrictionFactors\\Tour",  
			 {"ffcom.bin", "ffcom.dcb", "ffmtk.bin", "ffmtk.dcb",  "ffhtk.bin", "ffhtk.dcb",  
			  "ffeic.bin", "ffeic.dcb", "ffeim.bin", "ffeim.dcb", "ffeih.bin", "ffeih.dcb",
			  "ffiec.bin", "ffiec.dcb", "ffiem.bin", "ffiem.dcb", "ffieh.bin", "ffieh.dcb"}},

			{"\\ExtSta", 
			 {"thrubase_auto.asc", "thrubase_auto.dct", "thrubase_com.asc", "thrubase_com.dct",
			  "thrubase_mtk.asc",  "thrubase_mtk.dct",  "thrubase_htk.asc", "thrubase_htk.dct",
			  "bvthru.asc", "bvthru.dct", "extstavol18_base.asc", "extstavol18_base.dct"}},

			{"\\",
			 {"ATFUN_ID.dbf", "COATFUN_ID.dbf", "County_ATFun.bin","County_ATFun.dcb","County_ATFunID.bin", 
			  "County_ATFunID.dcb", "FUNAQ_ID.dbf", "ScreenlineID.bin", "ScreenlineID.dcb", "STCNTY_ID.dbf", 
			  "trnpnlty.bin", "trnpnlty.dcb", "HOT_Table.hot"}}
			}
		
		// \\Ext\\ExtstaVolsYY added below once year is established
		rundir_files = 
			{"station_database.dbf", "transit_corridor_id.dbf", "routes.dbf", "Track_ID.dbf", 
			 "transys.rtg", "transys.rts","transysc.bin", "transysc.BX", "transysc.DCB", "transysL.bin",
			 "transysL.BX", "transysL.DCB", "transysR.bin", "transysR.BX", "transysR.DCB", "transysS.bin",
			 "transysS.BX", "transysS.cdd", "transysS.cdk", "transysS.dbd", "transysS.DCB", "transysS.dsc",		
			 "transysS.dsk","transysS.grp", "transysS.lok", "transysS.pnk", "transysS.r0"}

		hotassn_dcb =
			{"Assn_template.dcb"}

	
		//Signals on master dbox	
		DirSignals =  {"dirred",  "diryellow",  "dirgreen"}
//		METSignals =  {"metred",  "metyellow",  "metgreen"}  
		MRMSignals =  {"mrmred",  "mrmyellow",  "mrmgreen"}
		YearSignals = {"yearred", "yearyellow", "yeargreen"}
		TAZSignals =  {"tazred",  "tazyellow",  "tazgreen"}
		LUSignals =   {"lured",   "luyellow",   "lugreen"}

		for i = 1 to 3 do
			HideItem(DirSignals[i])
			HideItem(MRMSignals[i])
			HideItem(YearSignals[i])
			HideItem(TAZSignals[i])
			HideItem(LUSignals[i])
		end

	DisableItem(" Run Trips Model ")
	DisableItem(" Run Partial Trips Model ")
	DisableItem(" Run Tour Model ")
	DisableItem(" Run Partial Tour Model ")

	HideItem(" Run Trips Model ")
	HideItem(" Run Partial Trips Model ")
	HideItem(" Run Tour Model ")
	HideItem(" Run Partial Tour Model ")

	DisableItem(" Hwy Assn - existing trip tables ")
	DisableItem(" Highway Select Link Analysis ")

	EndItem //Init



//********Get Directory for run **********************************************************************

	Frame 1, 1, 66, 20.0 

//		Dir		Run Directory			
	Edit Text "dirloc" 15.5, 2.5, 30 Prompt: "Run Directory:" Variable: DirUser Help:"Dir. for run (e.g. ...\\metrolina\\20yy), type-in if necessary"
	
	Button "chgdirloc" after, same Icon: "bmp\\buttons|148" Help: "Change the run directory" do
		DirUser  = ChooseDirectory("Choose directory for model run", )
	enditem

	// signals 
	Button "dirgreen" 51.5, same Icon: "bmp\\buttons|105" Help: "Run directory found" Hidden do	
		enditem
	Button "diryellow" 51.5, same Icon: "bmp\\buttons|528" Help: "Run directory not valid for most applications" Hidden do	
		enditem
	Button "dirred" 51.5, same Icon: "bmp\\buttons|127" Help: "Run directory not found.  Try again" Hidden do	
		enditem


//	RunYear			

	Edit Text "runyear" 15.5, after, 10  Prompt: "Run Year:" Variable: YearUser Help:"Run Year for MRM networks"   

	Button "yeargreen" 26.4, same Icon: "bmp\\buttons|105" Help: "Year OK" Hidden do	
		enditem
	Button "yearyellow" 26.4, same Icon: "bmp\\buttons|528" Help: "Please enter a year." Hidden do	
		enditem
	Button "yearred" 26.4, same Icon: "bmp\\buttons|127" Help: "Please enter a year." Hidden do	
		enditem

// 	MRMDir		MRM Directory 		  

	Text " " same, after, , 0.5
	Edit Text "mrmdir" 15.5, after, 30 Prompt: "MRM Directory:" Variable: MRMUser Help:"Master MRM Directory (e.g. L:\\MRM1502)" 
	Button "chgmrm" after, same Icon: "bmp\\buttons|148" Help: "Change the MRM directory" do
		MRMUser  = ChooseDirectory("Choose MRM (master) directory", )
	enditem
		
	Button "mrmgreen" 51.5, same Icon: "bmp\\buttons|105" Help: "MRM master directory found" Hidden do	
		enditem
	Button "mrmyellow" 51.5, same Icon: "bmp\\buttons|528" Help: "MRM not legitimate MRM directory" Hidden do	
		enditem
	Button "mrmred" 51.5, same Icon: "bmp\\buttons|127" Help: "MRM directory not found.  Try again" Hidden do	
		enditem

	
//	Create new directory

	Text " " same, after, , 0.5
	Button " Create Trips Dir " 15.5, after, 16 Help: "Create a new run directory for trips (4 step) model " do
		modeltype = "Trip"
		CreateDirectory = 1
		RunMacro("GetDir")
		if DirExist = 1
			then do
				button = MessageBox("OVERWRITE Run Dir: " + DirUser + " ? - All files to recycle bin", 
					{{Caption, "\\Overwrite run dir"}, {"Buttons", "YesNo"},
	 				 {"Icon", "Warning"}})
				PlaySound(sysdir + "\\media\\Windows Notify.wav", "null")
				if button = "No" 
					then do
						Message = Message + {"Run Dir: " + DirUser + " NOT overwritten"}
						goto quitcreatedirbutton
					end
					else PutInRecycleBin(DirUser)
			end  //DirExist > 1

		if keepgoing = "Yes" then RunMacro("GetMRM")
		if keepgoing = "Yes" then RunMacro("GetYear")
		if keepgoing = "Yes" then RunMacro("CreateDir")
		if keepgoing = "Yes" then RunMacro("GetTAZ")
		if keepgoing = "Yes" then RunMacro("GetLU")
		if keepgoing = "Yes" 
			then do
				Args = RunMacro("InitializeArgs")

				// Report and Log files initialized
				datentime = GetDateandTime()
				ReportFile = DirUser + "\\Report\\TC_Report.xml"
				SetReportFileName(ReportFile)
				AppendtoReportFile(1, "Create Directory: " + DirUser + ",  " + datentime)
				AppendtoReportFile(1, " ") 
				LogFile = DirUser + "\\Report\\TC_Log.xml"
				SetLogFileName(LogFile)
				AppendtoLogFile(1, "Create Trips Directory: " + DirUser + ",  " + datentime)
				AppendtoLogFile(1, " ") 
				AppendtoLogFile(1, "Create Trips Directory messages")
				for i = 1 to Message.length do
					AppendtoLogFile(2, Message[i])
				end
				AppendtoLogFile(2, " ")				
				
				RunMacro("SetArguments")
			end
		RunMacro("SetSignals")

		ShowItem(" Run Trips Model ")	
		ShowItem(" Run Partial Trips Model ")	
		EnableItem(" Run Trips Model ")	
		EnableItem(" Run Partial Trips Model ")	

		HideItem(" Run Tour Model ")	
		HideItem(" Run Partial Tour Model ")	
		DisableItem(" Run Tour Model ")	
		DisableItem(" Run Partial Tour Model ")	
		
		DisableItem(" Hwy Assn - existing trip tables ")
		DisableItem(" Highway Select Link Analysis ")

		quitcreatedirbutton:

	enditem  //Create directory button


	// Create tour directory
	Button " Create Tour Dir " 37.5, same, 16 Help: "Create a new run directory for tour based model " do
		modeltype = "Tour"
		CreateDirectory = 1
		RunMacro("GetDir")
		if DirExist = 1
			then do
				button = MessageBox("OVERWRITE Tour Run Dir: " + DirUser + " ? - All files to recycle bin", 
					{{Caption, "\\Overwrite tour run dir"}, {"Buttons", "YesNo"},
	 				 {"Icon", "Warning"}})
				PlaySound(sysdir + "\\media\\Windows Notify.wav", "null")
				if button = "No" 
					then do
						Message = Message + {"Run Dir: " + DirUser + " NOT overwritten"}
						goto quitcreatedirtourbutton
					end
					else PutInRecycleBin(DirUser)
			end  //DirExist > 1

		if keepgoing = "Yes" then RunMacro("GetMRM")
		if keepgoing = "Yes" then RunMacro("GetYear")
		if keepgoing = "Yes" then RunMacro("CreateDir")
		if keepgoing = "Yes" then RunMacro("GetTAZ")
		if keepgoing = "Yes" then RunMacro("GetLU")
		if keepgoing = "Yes" 
			then do
				Args = RunMacro("InitializeArgs")

				// Report and Log files initialized
				datentime = GetDateandTime()
				ReportFile = DirUser + "\\Report\\TC_Report.xml"
				SetReportFileName(ReportFile)
				AppendtoReportFile(1, "Create Directory: " + DirUser + ",  " + datentime)
				AppendtoReportFile(1, " ") 
				LogFile = DirUser + "\\Report\\TC_Log.xml"
				SetLogFileName(LogFile)
				AppendtoLogFile(1, "Create Tour Directory: " + DirUser + ",  " + datentime)
				AppendtoLogFile(1, " ") 
				AppendtoLogFile(1, "Create Tour Directory messages")
				for i = 1 to Messages.length do
					AppendtoLogFile(2, Messages[i])
				end
				AppendtoLogFile(2, " ")				
				
				RunMacro("SetArguments")
			end
		RunMacro("SetSignals")

		ShowItem(" Run Tour Model ")	
		ShowItem(" Run Partial Tour Model ")	
		EnableItem(" Run Tour Model ")	
		EnableItem(" Run Partial Tour Model ")	
		
		HideItem(" Run Trips Model ")	
		HideItem(" Run Partial Trips Model ")	
		DisableItem(" Run Trips Model ")	
		DisableItem(" Run Partial Trips Model ")	

		DisableItem(" Hwy Assn - existing trip tables ")
		DisableItem(" Highway Select Link Analysis ")

		quitcreatedirtourbutton:

	enditem  //Create directory tour button

//	Load Arguments directory and files

	Text " " same, after, , 0.5
	Button " Load Args for this Dir " 20.0, after, 30 Help: "Confirm that directory and files are what you want " do

		RunMacro("GetDir")
		if keepgoing = "Yes" then RunMacro("GetArguments")
		if keepgoing = "Yes" then RunMacro("GetMRM")
		if keepgoing = "Yes" then RunMacro("GetYear")
		if keepgoing = "Yes" then RunMacro("GetTAZ")
		if keepgoing = "Yes" then RunMacro("GetLU")
		if keepgoing = "Yes" then RunMacro("SetArguments")		
		RunMacro("SetSignals")
		// Report and Log files initialized
		if DirSignalStatus = 3
			then do
				datentime = GetDateandTime()
				LogFile = DirUser + "\\Report\\TC_Log.xml"
				SetLogFileName(LogFile)
				AppendtoLogFile(1, "Set Dir and Files, " + datentime)
				AppendtoLogFile(1, " ") 
				if CreateDirectory = 0
					then do
						AppendtoLogFile(1, "Set Dir and Files messages")
						for i = 1 to Messages.length do
							AppendtoLogFile(2, Messages[i])
						end
						AppendtoLogFile(2, " ")				
				end
			end
		if Args.[Model Type].value = "Trip" 
			then do
				ShowItem(" Run Trips Model ")	
				ShowItem(" Run Partial Trips Model ")	
				EnableItem(" Run Trips Model ")	
				EnableItem(" Run Partial Trips Model ")	

				HideItem(" Run Tour Model ")	
				HideItem(" Run Partial Tour Model ")
				DisableItem(" Run Tour Model ")	
				DisableItem(" Run Partial Tour Model ")
			end
			else do
				ShowItem(" Run Tour Model ")	
				ShowItem(" Run Partial Tour Model ")
				EnableItem(" Run Tour Model ")	
				EnableItem(" Run Partial Tour Model ")

				HideItem(" Run Trips Model ")	
				HideItem(" Run Partial Trips Model ")	
				DisableItem(" Run Trips Model ")	
				DisableItem(" Run Partial Trips Model ")	
			end

		EnableItem(" Hwy Assn - existing trip tables ")
		DisableItem(" Highway Select Link Analysis ")

	enditem  //Set Dir button


//	TAZ file - stays disabled if run hasn't started previously - TAZ is filled in DirFiles		

	Edit Text "tazsel" 15.5, after, 40 Prompt: "TAZ file:" Variable: TAZUser Help:"TAZ file for run" 
	Button "chgtaz" after, same Icon: "bmp\\buttons|148" Help: "Change the TAZ file" do
		TAZUser = ChooseFile({{"Standard","*.dbd"}},"Choose the TAZ File",{{"Initial Directory", MRMUser +"\\TAZ"}})
	enditem
		
	Button "tazgreen" 61.5, same Icon: "bmp\\buttons|105" Help: "TAZ file found" Hidden do	
		enditem
	Button "tazyellow" 61.5, same Icon: "bmp\\buttons|528" Help: "TAZ file not legitimate" Hidden do	
		enditem
	Button "tazred" 61.5, same Icon: "bmp\\buttons|127" Help: "TAZ file not found.  Try again" Hidden do	
		enditem


//	Land Use (SE) file - stays disabled if run hasn't started previously - Land Use file is filled in DirFiles

	Edit Text "lusel" 15.5, after, 40 Prompt: "Land Use file:" Variable: LUUser Help:"Land Use file for run" 
	Button "chglu" after, same Icon: "bmp\\buttons|148" Help: "Change the Land Use file" do
		LUUser = ChooseFile({{"DBASE","*.dbf"}},"Choose the Land Use File",{{"Initial Directory", DirUser +"\\LandUse"}})
	enditem

	Button "lugreen" 61.25, same Icon: "bmp\\buttons|105" Help: "Land Use file found" Hidden do	
		enditem
	Button "luyellow" 61.25, same Icon: "bmp\\buttons|528" Help: "Land Use file not legitimate" Hidden do	
		enditem
	Button "lured" 61.25, same Icon: "bmp\\buttons|127" Help: "Land Use file not found.  Try again" Hidden do	
		enditem

	Text " " same, after, , 0.25
	Text "Scenario name:" 2.0, after 
	Edit Text "scenname" 15.5, same, 48 Variable: ScenNameUser Help:"Name of scenario (optional)" do
	enditem

	Text " " same, after, , 0.25
	Text "AM Peak Highway name:" 2.0, after 
	Edit Text "ampkhwyname" 25.0, same, 38 Variable: AMPkHwyNameUser Align: Center Help:"AM Peak Highway file .dbd" do
	enditem

	Text " " same, after, , 0.25
	Text "PM Peak Highway name:" 2.0, after 
	Edit Text "pmpkhwyname" 25.0, same, 38 Variable: PMPkHwyNameUser Align: Center Help:"PM Peak Highway file .dbd" do
	enditem

	Text " " same, after, , 0.25
	Text "Offpeak Highway name:" 2.0, after 
	Edit Text "ophwyname" 25.0, same, 38 Variable: OPHwyNameUser Align: Center Help:"Offpeak Highway file .dbd" do
	enditem

	Text " " same, after, , 0.25
	Text "Model type:" 2.0, after 
	Text 15.5, same, 38 Variable: modeltype Framed Align: Center Help:"Trip or tour model" 


	//*****************************************************************************
	// Start model 
	Frame "modelframe" 1, 22.5, 65, 10.5 Prompt: "Run MRM Models" 
	
	//Trips and Tour Model buttons occupy same space - enabled or disabled based on Model type
	
	Button " Run Trips Model " 20.5, 23.5, 30  Help: "Run Full TRIPS feedback model with directories and files above" do	

		//Add run_complete test here and ask about completing previously started job - probably need to pass a variable to 
		// select_fullrun - may want to back up 1 unless I can find a way to get a code from mode choice 

		//If already have a completed run - ask if you want to re-do - if so - clear datetime and iter
		Message = null
		if DirSignalStatus < 3 
			then do
				Message = Message + {"Full Run ERROR! - Directory status"}
				keepgoing = "No"
			end
		if MRMSignalStatus < 3  
			then do
				Message = Message + {"Full Run ERROR! - MRM Directory status"}
				keepgoing = "No"
			end
		if YearSignalStatus < 2  
			then do
				Message = Message + {"Full Run ERROR! - Run Year status"}
				keepgoing = "No"
			end
		if TAZSignalStatus < 3  
			then do
				Message = Message + {"Full Run ERROR! - TAZ file status"}
				keepgoing = "No"
			end
		if LUSignalStatus < 3  
			then do
				Message = Message + {"Full Run ERROR! - Land Use file status"}
				keepgoing = "No"
			end

		if keepgoing = "Yes" then RunMacro("SetArguments")
	
		if keepgoing = "No" 
			then do
				PlaySound(sysdir + "\\media\\Windows Critical Stop.wav", "null")
				goto quitFullRun
			end

		// full run - fill JobsToRun array		
		maxfeedbackiter = Args.[Feedback Iterations].value
	
		JobsToRun = runbasejobs
		if maxfeedbackiter < 2 then goto skipfeedback
		for i = 2 to maxfeedbackiter do
			JobsToRun = JobsToRun + runfeedbackjobs
		end
		skipfeedback:
		JobsToRun = JobsToRun + runpostfeedbackjobs	
		JobsToRun = JobsToRun + runtranassnjobs
		JobsToRun = JobsToRun + runHOTassnjobs
		iRunYear = s2i(RunYear)
		if iRunYear <= ModelBaseYear 
			then JobsToRun = JobsToRun + hwycalibrationjobs
	
		rtn = RunMacro("RunJob", Args, JobsToRun)
		if rtn[1] = 1 
			then PlaySound(sysdir + "\\media\\Windows Notify.wav", "null")
			else PlaySound(sysdir + "\\media\\Windows Critical Stop.wav", "null")
		Message = Message + rtn[2]

		JobsToRun = null
		
		quitFullRun:
		
	enditem


	// Full tour model

	Button " Run Tour Model " 20.5, same, 30  Help: "Run Full TOUR feedback model with directories and files above" do	

		//Add run_complete test here and ask about completing previously started job - probably need to pass a variable to 
		// select_fullrun - may want to back up 1 unless I can find a way to get a code from mode choice 

		//If already have a completed run - ask if you want to re-do - if so - clear datetime and iter
		Message = null
		if DirSignalStatus < 3 
			then do
				Message = Message + {"Full Run ERROR! - Directory status"}
				keepgoing = "No"
			end
		if MRMSignalStatus < 3  
			then do
				Message = Message + {"Full Run ERROR! - MRM Directory status"}
				keepgoing = "No"
			end
		if YearSignalStatus < 2  
			then do
				Message = Message + {"Full Run ERROR! - Run Year status"}
				keepgoing = "No"
			end
		if TAZSignalStatus < 3  
			then do
				Message = Message + {"Full Run ERROR! - TAZ file status"}
				keepgoing = "No"
			end
		if LUSignalStatus < 3  
			then do
				Message = Message + {"Full Run ERROR! - Land Use file status"}
				keepgoing = "No"
			end
	
		if keepgoing = "Yes" then RunMacro("SetArguments")
	
		if keepgoing = "No" 
			then do
				PlaySound(sysdir + "\\media\\Windows Critical Stop.wav", "null")
				goto quitFullRun
			end

		// full run - fill JobsToRun array		
		maxfeedbackiter = Args.[Feedback Iterations].value
	
		JobsToRun = runbasejobs_tour
		if maxfeedbackiter < 2 then goto skipfeedback
		for i = 2 to maxfeedbackiter do
			JobsToRun = JobsToRun + runfeedbackjobs_tour
		end
		skipfeedback:
		JobsToRun = JobsToRun + runpostfeedbackjobs_tour	
		JobsToRun = JobsToRun + runtranassnjobs
		JobsToRun = JobsToRun + runHOTassnjobs_tour
		iRunYear = s2i(RunYear)
		if iRunYear <= ModelBaseYear 
			then JobsToRun = JobsToRun + hwycalibrationjobs_tour
	
		rtn = RunMacro("RunJob_Tour", Args, JobsToRun)
		if rtn[1] = 1 
			then PlaySound(sysdir + "\\media\\Windows Notify.wav", "null")
			else PlaySound(sysdir + "\\media\\Windows Critical Stop.wav", "null")
		Message = Message + rtn[2]

		JobsToRun = null
		
		quitFullRun:
		
	enditem

	// Partial trip and tour model buttons occupy same space - enabled / disabled by model type
	// Partial trip model

	Button " Run Partial Trips Model " 20.5, 25.5, 30 Help: "Continue partial run, or run individual steps" do	

		if keepgoing = "Yes" then RunMacro("SetArguments")
		if keepgoing = "No" 
			then do
				PlaySound(sysdir + "\\media\\Windows Critical Stop.wav", "null")
				Message = Message + {"User stop after reviewing arguments"}	
				goto skippartialtrips
			end
		rtn = RunDBox("Select_PartialRun", Args, runjobsets)
		if rtn = null 
			then do
				PlaySound(sysdir + "\\media\\Windows Critical Stop.wav", "null")
				Message = Message + {"Null return from Partial run"}
			end	
		else if rtn[1] = 1 
			then do
				PlaySound(sysdir + "\\media\\Windows Notify.wav", "null")
				Message = Message + rtn[2]
			end	
		else do
				PlaySound(sysdir + "\\media\\Windows Critical Stop.wav", "null")
				Message = Message + rtn[2]
		end	
		skippartialtrips:
	enditem

	// Partial tour model

	Button " Run Partial Tour Model " 20.5, 25.5, 30 Help: "Continue partial run, or run individual steps" do	
		if keepgoing = "Yes" then RunMacro("SetArguments")
		if keepgoing = "No" 
			then do
				PlaySound(sysdir + "\\media\\Windows Critical Stop.wav", "null")
				Message = Message + {"User stop after reviewing arguments"}	
				goto skippartialtour
			end
		rtn = RunDBox("Select_PartialRun_Tour", Args, runjobsets_tour)
		if rtn = null 
			then do
				PlaySound(sysdir + "\\media\\Windows Critical Stop.wav", "null")
				Message = Message + {"Null return from Partial run"}
			end	
		else if rtn[1] = 1 
			then do
				PlaySound(sysdir + "\\media\\Windows Notify.wav", "null")
				Message = Message + rtn[2]
			end	
		else do
				PlaySound(sysdir + "\\media\\Windows Critical Stop.wav", "null")
				Message = Message + rtn[2]
		end	
		skippartialtour:

	enditem

	// Special run sets

	Text " " 20.5, 26.75, , 0.5
	Button " Hwy Assn - existing trip tables " 20.5, after, 30  Help: "HOT Highway assignment with existing trip tables" Disabled do	
		rtn = RunDBox("AssnonExistingTripTables", Args) 
	enditem

	Text " " same, after, , 0.5
	Button " Highway Select Link Analysis " 20.5, after, 30  Help: "Highway assignment - with select link enabled" Disabled do	
		ShowMessage("MRM Utilities -Highway Assign Select Link" + "\n" + "NEED TO ADD THIS JOB (old: HwyAssn_SelectLink)") 

	enditem

	Text " " same, after, , 0.5
	Button " MRM Utilities menu " 20.5, after, 30  Help: "Utilities" do
		rtnutilities = RunDBox("MRMUtilities", Args)
		if rtnutilities[1] = 2 
			then PlaySound(sysdir + "\\media\\Windows Notify.wav", "null")
		else if rtnutilities[1] = 3 
			then PlaySound(sysdir + "\\media\\Windows Critical Stop.wav", "null")
		Message = Message + rtnutilities[2] 
	enditem

	Text " " same, after, , 1.5
	Text " Messages " 3.0, after
	Scroll List "messageslist" 2.0, 35, 62, 3.0 List: Message 

	Button " Show Args " 26.0, after, 15 Help: "Show / modify Arguments file contents." do	
		Message = Message  + RunDBox("showargs", Args)
	enditem

	Text " Exit" 50, same
	Button "Exit" 56, same Icon: "bmp\\buttons|440" Help: "Exit MRM." Cancel do	
		Args = null
		RunMacro("G30 File Close All")
		return()
	enditem

	Text " " same, after, , 0.5



// **************************  Macros section of DBox *******************************
//
//	GetDir - Get file name of run directory 
//	GetArguments - Read arguments file or initialize 
//	SetArguments - Save arguments to file file 
//	CheckArguments - Last check called by run model buttons
//	GetMRM - Get file name of MRM directory
//		GetMRMDefault - Get MRM default from \TransCad dir
//	GetYear - Get year of run
//	CreateDir - Create run directory
//	GetTAZ - get TAZ file - copy to \\Metrolina if nec.
//	GetLU - get land use file
//	SetSignals

//	CheckDirFiles - check MRM, Year, TAZ, LU files - set signals 
//  CreateRunDirectory - Create run directory and fill.   If necessary - create \Metrolina also
//*************************************************************************************************

	Macro "GetDir" do
	// returns flag if directory exists and resets if Dir changes

		keepgoing = "Yes"
		DirSignalStatus = 3
		if DirUser = null 
			then do
				Message = {"GetDir ERROR!  Run Directory required"}
				goto badDir
			end

		//Does directory exist? 
		DirInfo = GetDirectoryInfo(DirUser, "Directory")
		if DirInfo = null 
			then DirExist = 0
			else DirExist = 1

		//Get rid of anything in memory
		if Dir <> null
			then do
				Args = null
				Dir = null
				METDir = null
				MRMDir = null
				RunYear = null
				TAZFile = null
				LandUseFile = null
				ScenName = null
				AMPkHwyName = null
				PMPkHwyName = null
				OPHwyName = null
								
				DirArgs = null
				METArgs = null
				MRMArgs = null
				YearArgs = null
				TAZArgs = null
				LUArgs = null
				ScenNameArgs = null
				AMPkHwyNameArgs = null
				PMPkHwyNameArgs = null
				OPHwyNameArgs = null
			end			

		//Parse and reassemble to get rid of forward slashes and extraneous backslashes 
		dirparse = ParseString(DirUser,"/\\")
		vol = dirparse[1] 
		dirname = vol
		metloc = 0
		if dirparse.length > 1 
			then do
				for i = 2 to dirparse.length do
					if upper(dirparse[i]) = "METROLINA" then metloc = i
					dirname = dirname + "\\" + dirparse[i]
				end
			end

		// bad volume
		volinfo = GetDirectoryInfo(vol + "\\", "Directory")
		if volinfo = null 
			then do
				Message = {"GetDir ERROR! Illegal volume: " + vol + " for Run Directory"}
				goto badDir
			end

		//reject directories without \\metrolina
		if metloc = 0 
			then do 
				Message = {"GetDir ERROR! Run Dir must include \\Metrolina"}
				goto badDir
			end

		//Reject any except Metrolina as next to last subdir
		if upper(dirparse[dirparse.length-1]) <> "METROLINA"
			then do
				Message = {"GetDir ERROR! Run Dir - \\Metrolina must be parent directory of run dir"} 
				goto badDir
			end

		//Name is OK
		DirUser = dirname
		
		// Check \Metrolina directory
		METUser = vol
		for i = 2 to metloc do
			METUser = METUser + "\\" + dirparse[i]
		end
		METInfo = GetDirectoryInfo(METUser, "Directory")
		if METInfo = null 
			then METExist = 0
			else METExist = 1
		
		goto quitGetDir

		// run directory bad	
		badDir:
		DirSignalStatus = 1
		keepgoing = "No"
		PlaySound(sysdir + "\\media\\Windows Critical Stop.wav", "null")
		goto quitGetDir

		quitGetDir:

	enditem  //Macro GetDir

	Macro "GetArguments" do
	// Read arguments 
		keepgoing = "Yes"
		on error goto badfile
		on notfound goto nofile
		Args = LoadArray(DirUser + "\\Arguments.args")

		DirArgs = Args.[Run Directory].value
		METArgs = Args.[MET Directory].value
		MRMArgs = Args.[MRM Directory].value
		YearArgs = Args.[Run Year].value
		TAZArgs = Args.[TAZ File].value
		LUArgs = Args.[LandUse File].value
		ScenNameArgs = Args.[Scenario Name].value
		AMPkHwyNameArgs = Args.[AM Peak Hwy Name].value
		PMPkHwyNameArgs = Args.[PM Peak Hwy Name].value
		OPHwyNameArgs = Args.[Offpeak Hwy Name].value
		ReportFile = Args.[Report File].value
		LogFile = Args.[Log File].value
		modeltype = Args.[Model Type].value
		goto quitGetArguments

		badfile:
		dboxmsg = (DirUser + "\\Arguments.args is invalid file")
		goto initargs

		nofile:
		dboxmsg = (DirUser + "\\Arguments.args does not exist")
		
		goto initargs

		initargs:
		button = MessageBox("Initialize arguments? ", 
					{{"Caption", dboxmsg}, {"Buttons", "YesNo"},
	 				 {"Icon", "Warning"}})
		PlaySound(sysdir + "\\media\\Windows Notify.wav", "null")
		if button = "Yes"
			then do
				Args = RunMacro("InitializeArgs")
				DirArgs = null
				METArgs = null
				MRMArgs = null
				YearArgs = null
				TAZArgs = null
				LUArgs = null
				ReportFile = DirUser + "\\Report\\TC_Report.html"
				LogFile = DirUser + "\\Report\\TC_Log.html"
				AMPkHwyNameArgs = null
				PMPkHwyNameArgs = null
				OPHwyNameArgs = null
				ScenNameArgs = null				

				goto quitGetArguments
			end
			else do	
				Message = Message + {"ERROR! Must have Arguments array!"}
				keepgoing = "No"
				goto quitGetArguments
			end
		quitGetArguments:
		on error, notfound default
	enditem

	Macro "SetArguments" do

//		showmessage("SetArgs: HwyNameUser = " + HwyNameUser)
		Dir = DirUser
		METDir = METUser
		MRMDir = MRMUser
		RunYear = YearUser
		TAZFile = TAZUser
		LandUseFile = LUUser
		AMPkHwyName = AMPkHwyNameUser
		PMPkHwyName = PMPkHwyNameUser
		OPHwyName = OPHwyNameUser
		ScenName = ScenNameUser
	
		// Recheck
		WarnBox = null
		
		if Args.[Run Directory].value <> null and Args.[Run Directory].value <> Dir
			then WarnBox = WarnBox + "Replace Arguments Run Directory with: " + Dir + "?" + "\n"
		if Args.[MET Directory].value <> null and Args.[MET Directory].value <> METDir
			then WarnBox = WarnBox + "Replace Arguments MET Directory with: " + METDir + "?" + "\n"
		if Args.[MRM Directory].value <> null and Args.[MRM Directory].value <> MRMDir
			then WarnBox = WarnBox + "Replace Arguments MRM Directory with: " + MRMDir + "?" + "\n"
		if Args.[TAZ File].value <> null and Args.[TAZ File].value <> TAZFile
			then WarnBox = WarnBox + "Replace Arguments TAZ File with: " + TAZFile + "?" + "\n"
		if Args.[LandUse File].value <> null and Args.[LandUse File].value <> LandUseFile
			then WarnBox = WarnBox + "Replace Arguments Land Use File with: " + LandUseFile + "?" + "\n"
		if Args.[RunYear].value <> null and Args.[RunYear].value <> RunYear
			then WarnBox = WarnBox + "Replace Arguments Run Year with: " + RunYear + "?" + "\n"
		if Args.[Model Type].value <> null and Args.[Model Type].value <> modeltype
			then WarnBox = WarnBox + "Replace Arguments Model Type with: " + modeltype + "?" + "\n"
		if Args.[AM Peak Hwy Name].value <> null and Args.[AM Peak Hwy Name].value <> AMPkHwyName
			then WarnBox = WarnBox + "Replace Arguments AM Peak highway file name with: " + AMPkHwyName + "?" + "\n"
		if Args.[PM Peak Hwy Name].value <> null and Args.[PM Peak Hwy Name].value <> PMPkHwyName
			then WarnBox = WarnBox + "Replace Arguments PM Peak highway file name with: " + PMPkHwyName + "?" + "\n"
		if Args.[Offpeak Hwy Name].value <> null and Args.[Offpeak Hwy Name].value <> OPHwyName
			then WarnBox = WarnBox + "Replace Arguments Offpeak highway file name with: " + OPHwyName + "?" + "\n"
		if Args.[Scenario Name].value <> null and ScenName <> null and Args.[Scenario Name].value <> ScenName
			then WarnBox = WarnBox + "Replace Arguments Scenario Name with: " + ScenName + "?" + "\n"
				
		if WarnBox <> null
			then do
				warnresponse = MessageBox(Warnbox, {{"Caption", "Update Arguments?"},{"Buttons", "YesNo"}})
				if warnresponse = "No" 
					then do
						keepgoingresponse = MessageBox("Continue with existing arguments?", 
							{{"Caption", "Continue run?"},{"Buttons","YesNo"}})
						if keepgoingresponse = "Yes" 
							then keepgoing = "Yes"
						else if keepgoingresponse = "No"
							then do
								keepgoing = "No"
								goto skipsetargs
							end
					end //warnresponse
			end // warnbox
		if keepgoing = "Yes"
			then do
				Args.[MRM Directory].value = MRMDir
				Args.[MET Directory].value = METDir
				Args.[Run Directory].value = Dir
				Args.[Run Year].value = RunYear
				Args.[TAZ File].value = TAZFile
				Args.[TAZ Count].value = {NumTAZ, NumIntTAZ, NumExtTAZ}
				Args.[LandUse File].value = LandUseFile
				Args.[AM Peak Hwy Name].value = AMPkHwyName
				Args.[PM Peak Hwy Name].value = PMPkHwyName
				Args.[Offpeak Hwy Name].value = OPHwyName
				Args.[Model Type].value = modeltype
				Args.[Scenario Name].value = ScenName
				Args.[Report File].value = ReportFile
				Args.[Log File].value = LogFile
				Args.[Version].value = ProgVersion
				Args.[Build].value = ProgBuild
				SaveArray(Args, Dir + "\\Arguments.args")
			end // keepgoing
		skipsetargs:
	enditem //Macro SetArguments	


	Macro "GetMRM" do
	// Gets Master MRM directory - required for most operations
	// if multiple MRMs out there - order is User, Args, Default 
	
		keepgoing = "Yes"
		MRMSignalStatus = 3
		if MRMDefault = null then RunMacro("GetMRMDefault")

		// Up to 3 MRMs - User, Args, Default.  That is order for use
		// Each potential has array of - null/0/1 - file null, matches user, matches default

		//all three MRM User, Args, Default are null - error
		if MRMUser = null and MRMArgs = null and MRMDefault = null  
			then do
				Message = Message + {"GetMRM ERROR! MRM directory is null!"}
				goto badMRM
			end

		//  MRMUser and Args null,  MRM Default present = use default 
		if MRMUser = null and MRMArgs = null and MRMDefault <> null  
			then do 
				MRMUser = MRMDefault
				Message = Message + {"GetMRM, MRM Default: " + MRMUser + " used"}
				goto gotMRM
			end

		//  MRMUser null, Args present, default null = Use Args  
		if MRMUser = null and MRMArgs = null and MRMDefault <> null  
			then do 
				MRMUser = MRMArgs	
				Message = Message + {"GetMRM, MRMArgs: " + MRMUser + " used, (MRM Default null)"}
				goto gotMRM
			end	

		//  MRMUser null, Args & Default are same = use default  
		if MRMUser = null and MRMArgs <> null and MRMDefault <> null and upper(MRMArgs) = upper(MRMDefault)
			then do 
				MRMUser = MRMDefault	
				Message = Message + {"GetMRM, MRM Default: " + MRMUser + " used"}
				goto gotMRM
			end

		//  MRMUser null, Args & Default are different = ask which you want  
		if MRMUser = null and MRMArgs <> null and MRMDefault <> null and upper(MRMArgs) <> upper(MRMDefault)
			then do 
				rtn = RunDBox("ChooseAB", "MRM default differs from MRM in Arguments", MRMDefault, MRMArgs)
				if rtn = "A" 
					then do
						MRMUser = MRMDefault
						Message = Message + {"GetMRM, MRM Default: " + MRMUser + " selected"}
						goto gotMRM
					end
					else do
						MRMUser = MRMArgs
						Message = Message + {"GetMRM, MRM: " + MRMArgs + " selected (not MRMDefault)"}
						goto gotMRM
					end
			end 
			
		//  MRMUser <> null, Args & Default are null = go with user - warn about default  
		if MRMUser <> null and MRMArgs = null and MRMDefault = null 
			then do
				Message = Message + {"GetMRM, User MRM: " + MRMUser + " selected (MRMDefault null)"}
				goto gotMRM
			end

		//  MRMUser <> null, Args = null, Default <> null - User and default match - ok  
		if MRMUser <> null and MRMArgs = null and MRMDefault <> null and upper(MRMUser) = upper(MRMDefault)
			then goto gotMRM

		//  MRMUser <> null, Args = null, Default <> null  - User and default do not match - pick which  
		if MRMUser <> null and MRMArgs = null and MRMDefault <> null and upper(MRMUser) <> upper(MRMDefault)
			then do
				rtn = RunDBox("ChooseAB", "MRM default differs from MRMUser", MRMDefault, MRMUser)
				if rtn = "A" 
					then do
						MRMUser = MRMDefault
						Message = Message + {"GetMRM, MRM Default: " + MRMUser + " selected"}
						goto gotMRM
					end
					else do
						Message = Message + {"GetMRM, MRM: " + MRMUser + " selected (not MRMDefault)"}
						goto gotMRM
					end
			end 

		//  MRMUser <> null, Args <> null, Default = null  - User and args match = ok, warn about default   
		if MRMUser <> null and MRMArgs <> null and MRMDefault = null and upper(MRMUser) = upper(MRMArgs)
			then do
				Message = Message + {"GetMRM, User MRM: " + MRMUser + " selected (MRMDefault null)"}
				goto gotMRM
			end

		//  MRMUser <> null, Args <> null, Default = null  - User and args do not match = pick which, warn about default   
		if MRMUser <> null and MRMArgs <> null and MRMDefault = null and upper(MRMUser) <> upper(MRMArgs)
			then do
				rtn = RunDBox("ChooseAB", "MRM User differs from MRM Args", MRMUser, MRMArgs)
				if rtn = "A" 
					then do
						Message = Message + {"GetMRM, MRM: " + MRMUser + " selected (MRMDefault null)"}
						goto gotMRM
					end
					else do
						MRMUser = MRMArgs
						Message = Message + {"GetMRM, MRM: " + MRMUser + " selected (MRMDefault null)"}
						goto gotMRM
					end
			end 

		//  MRMUser, Args, Default all filled, all match = ok   
		if MRMUser <> null and MRMArgs <> null and MRMDefault <> null and upper(MRMUser) = upper(MRMArgs) and upper(MRMUser) = upper(MRMDefault)
			then goto gotMRM

		//  MRMUser, Args, Default all filled,  user matches default - args different = ok, warn about args   
		if MRMUser <> null and MRMArgs <> null and MRMDefault <> null and upper(MRMUser) <> upper(MRMArgs) and upper(MRMUser) = upper(MRMDefault)
			then do
				Message = Message + {"GetMRM, User MRM: " + MRMUser + " selected (MRMArgs is different)"}
				goto gotMRM
			end

		//  MRMUser, Args, Default all filled, user matches args, default different = ok, warn about default   
		if MRMUser <> null and MRMArgs <> null and MRMDefault <> null and upper(MRMUser) = upper(MRMArgs) and upper(MRMUser) <> upper(MRMDefault)
			then do
				Message = Message + {"GetMRM, User MRM: " + MRMUser + " selected (MRMdefault is different)"}
				goto gotMRM
			end

		//  MRMUser, Args, Default all filled, user different, but Args and Default match = ok, warn about default   
		if MRMUser <> null and MRMArgs <> null and MRMDefault <> null and upper(MRMUser) <> upper(MRMArgs) and upper(MRMUser) <> upper(MRMDefault) and upper(MRMArgs) = upper(MRMDefault)
			then do
				Message = Message + {"GetMRM, User MRM: " + MRMUser + " selected (Arguments & Default different)"}
				goto gotMRM
			end

		//  MRMUser, Args, Default all filled, all different - choose   
		if MRMUser <> null and MRMArgs <> null and MRMDefault <> null and upper(MRMUser) <> upper(MRMArgs) and upper(MRMUser) <> upper(MRMDefault) and upper(MRMArgs) <> upper(MRMDefault)
			then do
				rtn = RunDBox("ChooseABC", "MRMDefault, MRMUser, and MRMArgs all differ", MRMDefault, MRMUser, MRMArgs)
				if rtn = "A" then do 
					MRMUser = MRMDefault
					Message = Message + {"GetMRM, MRM Default: " + MRMUser + " selected (MRMDefault)"}
					goto gotMRM
				end
				if rtn = "B" then do 
					Message = Message + {"GetMRM, MRM: " + MRMUser + " selected (not MRMDefault)"}
					goto gotMRM
				end
				else do
					MRMUser = MRMArgs
					Message = Message + {"GetMRM, MRM: " + MRMUser + " selected (not MRMDefault)"}
					goto gotMRM
				end
			end 		
					
		Message = Message + {"GetMRM, There is no way that I should be here"}			
						
		gotMRM:
		MRMSignalStatus = 2
		goto quitGetMRM

		// MRM bad	
		badMRM:
		keepgoing = " No"
		MRMSignalStatus = 1
		PlaySound(sysdir + "\\media\\Windows Critical Stop.wav", "null")
		goto quitGetMRM

		quitGetMRM:

	enditem //Macro GetMRM

	Macro "GetMRMDefault" do
		// MRM default - in \TransCad directory
		exist = GetFileInfo(ProgDir + "\\MRMDir.txt")
		if exist 
			then do
				ptr = OpenFile(ProgDir + "\\MRMDir.txt", "r")
				if not FileAtEOF(ptr) then MRMDefault = ReadLine(ptr)
					             	  else MRMDefault = null
				CloseFile(ptr)
			end
	enditem //Macro GetMRMDefault

	Macro "GetYear" do
	// Get run year 

		keepgoing = "Yes"
		YearSignalStatus = 1

		if YearUser = null and YearArgs <> null
			then YearUser = YearArgs
		
		iyearuser = s2i(YearUser)

		if YearArgs <> null 
			then do
				iyearargs = s2i(YearArgs)
				if iyearuser <> iyearargs 
					then do
						Message = Message + {"WARNING! Year User: " + YearUser + " differs from Year in Arguments: " + YearArgs}
						Message = Message + {"  " + YearUser + " will be used for current run"}
						PlaySound(sysdir + "\\media\\Windows Notify.wav", "null")
					end	
			end	
				
		if (iyearuser < 2000 or iyearuser > 2100) 
			then do
				Message = Message + {"GetYear, RunYear: " + YearUser + " is not a valid year"}
				goto badYear
			end
		// check year in MRM - subdirectory MUST be named by year
		MRMInfo = GetDirectoryInfo(MRMUser + "\\" + YearUser, "Directory")
		If MRMInfo = null 
			then do
				Message = Message + {"GetYear, Year directory: " + YearUser + " not found in MRM"}
				goto badYear
			end	
			else do
				//Got a hit on year
				YearSignalStatus = 3
				MRMSignalStatus = 3	
				
				// Create default AM & PM Peaks and Offpeak hwyname (RegNetYY) - use in order - User / Args / Default
				AMPkHwyNameDefault = "RegNet" + SubString(YearUser, 3, 2) + "_AMPeak"
				if AMPkHwyNameUser = null
					then do
						if AMPkHwyNameArgs = null
							then do
								AMPkHwyNameUser = AMPkHwyNameDefault
								Message = Message + {"GetYear:  Default AM peak highway name (" + AMPkHwyNameUser + ") set"}
							end
							// HwyNameArgs <> null
							else do
								AMPkHwyNameUser = AMPkHwyNameArgs
								Message = Message + {"GetYear: AM peak highway name (" + AMPkHwyNameUser + ") from Arguments set"}
							end
						end //HwyNameUser = null
					//HwyNameUser <> null
					else do								 
						Message = Message + {"GetYear: AM peak highway name (" + AMPkHwyNameUser + ") set"}
					end
				PMPkHwyNameDefault = "RegNet" + SubString(YearUser, 3, 2) + "_PMPeak"
				if PMPkHwyNameUser = null
					then do
						if PMPkHwyNameArgs = null
							then do
								PMPkHwyNameUser = PMPkHwyNameDefault
								Message = Message + {"GetYear:  Default PM peak highway name (" + PMPkHwyNameUser + ") set"}
							end
							// HwyNameArgs <> null
							else do
								PMPkHwyNameUser = PMPkHwyNameArgs
								Message = Message + {"GetYear: PM peak highway name (" + PMPkHwyNameUser + ") from Arguments set"}
							end
						end //HwyNameUser = null
					//HwyNameUser <> null
					else do								 
						Message = Message + {"GetYear: PM peak highway name (" + PMPkHwyNameUser + ") set"}
					end
				OPHwyNameDefault = "RegNet" + SubString(YearUser, 3, 2) + "_Offpeak"
				if OPHwyNameUser = null
					then do
						if OPHwyNameArgs = null
							then do
								OPHwyNameUser = OPHwyNameDefault
								Message = Message + {"GetYear:  Default offpeak highway name (" + OPHwyNameUser + ") set"}
							end
							// HwyNameArgs <> null
							else do
								OPHwyNameUser = OPHwyNameArgs
								Message = Message + {"GetYear:  offpeak highway name (" + OPHwyNameUser + ") from Arguments set"}
							end
						end //HwyNameUser = null
					//HwyNameUser <> null
					else do								 
						Message = Message + {"GetYear:  offpeak highway name (" + OPHwyNameUser + ") set"}
					end
				goto quitGetYear
			end

		badyear:
		keepgoing = "No"
		YearSignalStatus = 1
		PlaySound(sysdir + "\\media\\Windows Critical Stop.wav", "null")
		goto quitGetYear
		
		quitGetYear:
	enditem  //Macro GetYear


	// *************************************Create Directory ************************************		
	
	Macro "CreateDir" do
	// Creates run directory and subdirectories, fills files from MRM
	
		//If Metrolina does not exist create it and subdirs (not year yet), otherwise check for msg files 
		keepgoing = "Yes"
		METSignalStatus = 3
		DirSignalStatus = 3

		METMissing = null

		if METExist = 0 then CreateDirectory(METUser) 

		for i = 1 to METSubDir.length do
			METInfo = GetDirectoryInfo(METUser + METSubDir[i], "Directory")	
			if METInfo = null then CreateDirectory(METUser + METSubDir[i])
		end // for i	

		// ADDED condition to pull different sets of mode choice constants based on version (Trip vs Tour)
		// ALSO checks datestamp and pulls one matching MRM

		for i = 1 to METFiles.length do	
			MRMSubDir = METFiles[i][1]

			TripPos = Position(MRMSubDir,"\\Trip")
			TourPos = Position(MRMSubDir,"\\Tour")

			// Trip/Tour not specified
			if TripPos =  0 and TourPos = 0 then METSubDir = MRMSubDir
			
			else do
				// Trip model
				if modeltype = "Trip" then do
					if TourPos <> 0 then goto skipsubdir
					else do
						METSubDir = Left(MRMSubDir,	TripPos -1)
						Message = Message + {"CreateDir Info:  Using Trips model subdir " + MRMSubDir}
					end
				end
				
				// Tour model
				if modeltype = "Tour" then do
					if TripPos <> 0 then goto skipsubdir
					else do
						METSubDir = Left(MRMSubDir,	TourPos -1)
						Message = Message + {"CreateDir Info:  Using Tour model subdir " + MRMSubDir}
					end
				end
			end 

			// Check files - if MET created, all the files should be listed here 
			for j = 1 to METFiles[i][2].length do
				MRMdatestamp = null
				METdatestamp = null
				MRMInfo = GetFileInfo(MRMUser + MRMSubDir + "\\" + METFiles[i][2][j])
				if MRMInfo = null
					then Message = Message + {"CreateDir Warning! MRM! " + MRMUser + MRMSubSir + "\\" +  METFiles[i][2][j] + " not found"}
					else MRMdatestamp = MRMInfo[7] + " " + MRMInfo[8]

				METInfo = GetFileInfo(METUser + METSubDir + "\\" + METFiles[i][2][j])
				if METInfo = null
					then METMissing = METMissing + {"copy " + MRMUser + MRMSubDir + "\\" +  METFiles[i][2][j] + " " +  METUser + METSubDir +  "\\" +  METFiles[i][2][j]}
					else do
						METdatestamp = METInfo[7] + " " + METInfo[8]
						if MRMdatestamp = null 
							then do
								METSignalStatus = 2
								Message = Message + {"CreateDir Warning! " + METFiles[i][2][j] + " not found in either MRM or MET, Run Will Bomb if file needed!"}
							end
						else if MRMdatestamp <> METdatestamp
								then do
									METMissing = METMissing + {"copy " + MRMUser + MRMSubDir + "\\" +  METFiles[i][2][j] + " " +  METUser + METSubDir +  "\\" +  METFiles[i][2][j]}
									Message = Message + {"CreateDir Warning! " + MRMSubDir  + "\\" + METFiles[i][2][j] + " datestamp: " + MRMdatestamp + " replaced MET file - datestamp: " + METdatestamp}
								end
					end // else METInfo <> null
			end  // for j
			skipsubdir:
		end // for i

//		showarray(METMissing)
		if METMissing = null then goto endMET
	
		//Add MET files - loaded with subdir into METMissing array in step above

		// DOS copy to preserve file dates
//		batchname = METUser + "\\holdher.txt"
		batchname  = METUser + "\\copy_file.bat"
		exist = GetFileInfo(batchname)
		if (exist <> null) then DeleteFile(batchname)
		batchhandle = OpenFile(batchname, "w")
		for i = 1 to METMissing.length do
			WriteLine(batchhandle, METMissing[i])
		end // for i
		CloseFile(batchhandle)

		status = RunProgram(batchname, )
		if (status <> 0) 
			then do
				Message = Message + {"CreateDir WARNING! Error in batch copy from MRM to \\Metrolina, status=" +i2s(status)}
				METSignalStatus = 2
			end
			else DeleteFile(batchname)
		endMET:

		// ****************Create Run Directory ***************************************************

		//Make sure year exists in MRM
		MRMInfo = GetDirectoryInfo(MRMUser + "\\" + YearUser, "Directory")
		if MRMInfo = null then do
			MRMSignalStatus = 1
			Message = Message + {"CreateDir ERROR! Year: " + YearUser + " does not exist in MRM: " + MRMUser}
			goto badCreateDir
		end
		CreateDirectory(DirUser)

		LandUseStatus = 1
	
		for i = 1 to RunDirSubDir.length do
			CreateDirectory(DirUser + RunDirSubDir[i])
		end
				
		//Copy files	
		batchname  = DirUser + "\\copy_file.bat"
		exist = GetFileInfo(batchname)
		if (exist <> null) then DeleteFile(batchname)
		batchhandle = OpenFile(batchname, "w")

		// need to add year onto extsta vol files	
		YearTwo = Right(YearUser,2)
		rundir_files = rundir_files + {"Ext\\extstavol" + YearTwo + ".asc"} + {"Ext\\extstavol" + YearTwo + ".dct"}   

		//Standard runyear files
		MRMpath = MRMUser + "\\" + YearUser + "\\"
		for i = 1 to rundir_files.length do	
			MRMInfo = GetFileInfo(MRMpath + rundir_files[i])
			if MRMInfo <> null
				then WriteLine(batchhandle, "copy " + MRMpath + rundir_files[i] + " " + DirUser + "\\" + rundir_files[i])
				else do
					Message = Message + {"MRM file: " + YearUser + "\\" + rundir_files[i] + " not found - not copied"}
					DirSignalStatus = 2
				end
		end // for i
		
		//Everything in TG subdirectory (ONLY for TOUR model files)
		if modeltype = "Tour" then do
			MRMpath = MRMUser + "\\TG\\"
			MRMInfo = GetDirectoryInfo(MRMpath + "*.*", "File")
			if MRMInfo <> null 
				then do
					for i = 1 to MRMInfo.length do
						WriteLine(batchhandle, "copy " + MRMpath + MRMInfo[i][1] + " " + DirUser + "\\TG\\" + MRMInfo[i][1])
					end
				end
				else do
					Message = Message + {MRMPath + " files missing, not copied"}
					DirSignalStatus = 2
				end
		end

		// HOT
		MRMpath = MRMUser + "\\HOT\\"
		for i = 1 to hotassn_dcb.length do	
			MRMInfo = GetFileInfo(MRMpath + hotassn_dcb[i])
			if MRMInfo <> null
				then WriteLine(batchhandle, "copy " + MRMpath + hotassn_dcb[i] + " " + DirUser + "\\HwyAssn\\HOT\\" + hotassn_dcb[i])
				else do
					Message = Message + {"MRM\\HOT dcb: " + hotassn_dcb[i] + " not found - not copied"}
					DirSignalStatus = 2
				end
		end // for i

		//Everything in landuse subdirectory
		MRMpath = MRMUser + "\\" + YearUser + "\\LandUse\\"
		MRMInfo = GetDirectoryInfo(MRMpath + "*.*", "File")
		if MRMInfo <> null 
			then do
				for i = 1 to MRMInfo.length do
					WriteLine(batchhandle, "copy " + MRMpath + MRMInfo[i][1] + " " + DirUser + "\\LandUse\\" + MRMInfo[i][1])
				end
			end	
			else do
				Message = Message + {MRMPath + " files missing, not copied"}
				DirSignalStatus = 2
			end

		// end of copy batch
		CloseFile(batchhandle)
		status = RunProgram(batchname, )
		if (status <> 0) 
			then do
				Message = Message + {"Error in batch copy from MRM to " + YearUser}
				DirSignalStatus = 2
			end
			else DeleteFile(batchname)

		goto quitCreateDir
		
		badCreateDir:
		DirSignalStatus = 1
		keepgoing = "No"
		
		quitCreateDir:
		
	enditem // Macro CreateDir

	Macro "GetTAZ" do
	// Macro to identify TAZ file, copy from MRM if necessary
		keepgoing = "Yes"
		TAZSignalStatus = 3
		on error goto notaz

		// Pull TAZ from Arguments
		if TAZUser = null and TAZArgs <> null
			then do
				TAZUser = TAZArgs
				tazpath = SplitPath(TAZUser)
				goto gottaz				
			end
				
		if TAZUser <> null and TAZArgs <> null and Upper(TAZUser) <> Upper(TAZArgs)
			then do
				Message = Message + {"GetTAZ WARNING!  User TAZ file: " + TAZUser + " differs from Args"}
				Message = Message + {"GetTAZ WARNING!  User TAZ file: " + TAZUser + " differs from Args"}
				PlaySound(sysdir + "\\media\\Windows Notify.wav", "null")
				TAZSignalStatus = 2
			end
			  
		TAZInfo = GetFileInfo(TAZUser)
		if TAZInfo = null 
			then goto gettaz

		tazpath = SplitPath(TAZUser)
		if Upper(tazpath[1] + tazpath[2]) = Upper(METUser + "\\TAZ\\") 
			then goto gottaz
		
		gettaz: 
		on escape goto notaz
	
		TAZDir = METDir + "\\TAZ\\*.dbd"
		dbdexist = GetDirectoryInfo(METDir,"File")
		if dbdexist = null 
			then InitDir = MRMUser + "\\TAZ"
			else InitDir = METUser + "\\TAZ"

		TAZUser = ChooseFile({{"Standard","*.dbd"}},"Choose the TAZ File",{{"Initial Directory", InitDir}})
		TAZInfo = GetFileInfo(TAZUser)
		if TAZInfo = null 
			then goto gettaz
			else do
				tazpath = SplitPath(TAZUser)
				if Upper(tazpath[1] + tazpath[2]) = Upper(METUser + "\\TAZ\\") 
					then goto gottaz
					else do
						CopyDataBase(TAZUser, METUser + "\\TAZ\\" + tazpath[3] + tazpath[4])
						TAZUser = METUser + "\\TAZ\\" + tazpath[3] + tazpath[4]
						Message = Message + {"Copied TAZ : " + tazpath[3] + " from MRM to \\Metrolina"} 
					end		
			end		
		gottaz:
		
		// Create/check TAZ template matrix and tazid files (1-good,2-warn,3-bad return)

		TAZrtn = RunMacro("Matrix_template", TAZUser)
		Message = Message + TAZrtn[2]
		TAZSignalStatus = TAZrtn[1]
		if TAZrtn[1] = 1 then goto notaz 
		
		TAZID = OpenTable("TAZID", "FFA", {METUser + "\\TAZ\\" + tazpath[3] + "_TAZID.asc",})
		SetView(TAZID)
		selinttaz = "Select * where TAZ < 12000"
		selexttaz = "Select * where TAZ >= 12000"
		NumIntTAZ = Selectbyquery("inttaz", "Several", selinttaz,)
		NumExtTAZ = Selectbyquery("exttaz", "Several", selexttaz,)
		NumTAZ = NumIntTAZ + NumExtTAZ
		Message = Message + {"TAZ file " + tazpath[3] + ": Internal TAZ="+i2s(NumIntTAZ)+" External TAZ="+i2s(NumExtTAZ)+" Total TAZ="+i2s(NumTAZ)}			
		CloseView(TAZID)
		
		goto quitGetTAZ

		notaz:
		TAZSignalStatus = 1
		Message = Message + {"error= " + GetLastError()}
		PlaySound(sysdir + "\\media\\Windows Critical Stop.wav", "null")
		keepgoing = "No"	
		goto quitGetTAZ

		quitGetTAZ:
		on error, escape default
		
	enditem  //Macro GetTAZ	

	Macro "GetLU" do
	// Macro to identify LU file 
		keepgoing = "Yes"
		LUSignalStatus = 3
		checkLUTAZ = "False"

		// Pull LU from Arguments
		if LUUser = null and LUArgs <> null
			then do
				LUUser = LUArgs
				goto gotLU
			end
		
		if LUUser <> null and LUArgs <> null and Upper(LUUser) <> Upper(LUArgs)
			then do
				Message = Message + {"GetLU WARNING!  User Land Use file: " + LUUser + " differs from"}
				Message = Message + {"   Args Land Use file: " + LUArgs}
				PlaySound(sysdir + "\\media\\Windows Notify.wav", "null")
				LUSignalStatus = 2
			end

		LUInfo = GetFileInfo(LUUser)
		if LUInfo = null 
			then goto getLU
			else goto gotLU
			
		// Get land use file
		getLU:
		on error goto getLU
		on escape goto noLU
		LUUser = ChooseFile({{"DBASE","*.dbf"}},"Choose the Land Use File",{{"Initial Directory", DirUser + "\\LandUse"}})
		LUInfo = GetFileInfo(LUUser)
		if LUInfo = null 
			then goto getLU
			else goto gotLU

		gotLU:

		// check against TAZ
		checkLUrtn = RunMacro("checkLU", LUUser, TAZUser)
		Message = Message + checkLUrtn[2]
		if checkLUrtn[1] = 0 then goto noLU

		goto quitGetLU
		
		noLU:
		TAZSignalStatus = 1
		PlaySound(sysdir + "\\media\\Windows Critical Stop.wav", "null")
		keepgoing = "No"	
		goto quitGetLU
		
		quitGetLU:
		on error, escape default
	enditem //Macro GetLU

	Macro "SetSignals" do
		//Set Signals
		for i = 1 to 3 do
			if i = DirSignalStatus  then ShowItem(DirSignals[i])
								    else HideItem(DirSignals[i])
			if i = MRMSignalStatus  then ShowItem(MRMSignals[i])
								    else HideItem(MRMSignals[i])
			if i = YearSignalStatus then ShowItem(YearSignals[i])
							 	    else HideItem(YearSignals[i])
			if i = TAZSignalStatus  then ShowItem(TAZSignals[i])
								    else HideItem(TAZSignals[i])
			if i = LUSignalStatus   then ShowItem(LUSignals[i])
								    else HideItem(LUSignals[i])
		end							
	enditem  //Macro SetSignals


//***************************************************************************************************

	Close Do
   		RunMacro("G30 File Close All")
   		return()
	EndItem  	


EndDbox
