DBox "Select_PartialRun" (Args, runjobsets) right, top Title: "Select MRM sections or steps to run"
//  DBox to select partial run of MRM	

//	EDIT - 11/20/16 - added HighwayCalibrationStats to Select Individual Jobs (JWM)

	Init do
		dim JobsToRun[1]
		dim jobslist[1]

		maxfeedbackiter = Args.[Feedback Iterations].value

		runbasejobs = runjobsets[1]
		runfeedbackjobs = runjobsets[2]
		runpostfeedbackjobs = runjobsets[3]
		runtranassnjobs = runjobsets[4]
		runHOTassnjobs = runjobsets[5]
	
	

		netspathsjobs = {"Build_Networks", "Area_Type", "CapSpd", "RouteSystemSetUp", 
				"HwySkim_Free", "HwySkim_Peak", 
				"Prepare_Transit_Files", "FillParkCost", "AutoSkims_Free", "AutoSkims_Peak",  "Reg_NonMotorized", 
				"Reg_PPrmW", "Reg_PPrmD", "Reg_PPrmDrop", "Reg_PBusW", "Reg_PBusD", "Reg_PBusDrop", 
				"Reg_OPPrmW", "Reg_OPPrmD", "Reg_OPPrmDrop", "Reg_OPBusW", "Reg_OPBusD", "Reg_OPBusDrop"}

		gendistribjobs = {"ExtStaforTripGen", "Trip_Generation", "Aggregate_TripGen", "EE_Trips", 
				"TD_TranPath_Peak", "TD_TranPath_Free", 
				"TDHBW1", "TDHBW2", "TDHBW3", "TDHBW4", 
				"TDHBS1", "TDHBS2", "TDHBS3", "TDHBS4", "TDHBO1", "TDHBO2", "TDHBO3", "TDHBO4", 
				"TDJTW", "TDATW", "TDNWK",  
				"TDSCH", "TDHBU",
				"TDCOM", "TDMTK", "TDHTK", 
				"TDEIW", "TDEIN", "TDEIC", "TDEIM", "TDEIH", 
				"TDIEW","TDIEN", "TDIEC", "TDIEM", "TDIEH", "TDMatrixStats"}

		msjobs = {"TOD1_HBW_Peak", "TOD1_HBO_Peak", "TOD1_NHB_Peak", "TOD1_HBU_Peak",
				"TOD1_HBW_OffPeak", "TOD1_HBO_OffPeak", "TOD1_NHB_OffPeak", "TOD1_HBU_OffPeak",
				"MS_RunPeak", "MS_RunOffPeak", "MSMatrixStats"} 

		mssolojobs = {"MS_HBWPeak", "MS_HBWOffPeak", "MS_HBOPeak", "MS_HBOOffPeak", "MS_NHBPeak", "MS_NHBOffPeak", 
				"MS_HBUPeak", "MS_HBUOffPeak"}

		hwyassnjobs = {"TOD2_COM_MTK_HTK", "TOD2_AMPeak", "TOD2_Midday", "TOD2_Night", "TOD2_PMPeak", "ODMatrixStats",  
				"HwyAssn_RunAMPeak", "HwyAssn_RunMidday", "HwyAssn_RunPMPeak", "HwyAssn_RunNight", 
				"HwyAssn_RunTotAssn", "Feedback_TravelTime",
				"HwyAssn_RunHOTAMPeak", "HwyAssn_RunHOTPMPeak", "HwyAssn_RunHOTMidday", "HwyAssn_RunHOTNight", 
				"HwyAssn_RunHOTTotAssn", "ODMatrixStats", "VMTAQ", "AvgTripLenTrips"}

		hwyassnsolojobs = {"HighwayCalibrationStats"}

		//runjobsorder - list of jobs in order without feedback - used to run singly selected jobs in proper order
		//   it also includes solo mode choice runs - at end of list 
		runjobsorder = runbasejobs +  {"Feedback_TravelTime"} + runpostfeedbackjobs + mssolojobs + runtranassnjobs + runHOTassnjobs + hwyassnsolojobs



		DisableItem("StartPartialRun")
		DisableItem("ClearPartialRun")
		
		pick_jobindex = 1
		
		alljobs = runbasejobs
		if maxfeedbackiter < 2 then goto skipfeedback1
		for i = 2 to maxfeedbackiter do
			alljobs = alljobs + runfeedbackjobs
		end
		skipfeedback1:
		alljobs = alljobs + runpostfeedbackjobs	+ runtranassnjobs + runHOTassnjobs
			
		jobslist = null
		for j = 1 to runbasejobs.length do
			jobslist = jobslist + {runbasejobs[j]+ " / iter 1"}
		end
		if maxfeedbackiter < 2 then goto skipfeedback2
		for i = 2 to maxfeedbackiter do
			iteradd = " / iter " + i2s(i)
			for j = 1 to runfeedbackjobs.length do
				jobslist = jobslist + {runfeedbackjobs[j] + iteradd}		
			end
		end
		skipfeedback2:
		for j = 1 to runpostfeedbackjobs.length do
			jobslist = jobslist + {runpostfeedbackjobs[j]}
		end
		for j = 1 to runtranassnjobs.length do
			jobslist = jobslist + {runtranassnjobs[j]}
		end
		for j = 1 to runHOTassnjobs.length do
			jobslist = jobslist + {runHOTassnjobs[j]}
		end

		JobSel = {}

	enditem	
	
	Frame "partialmodelframe" 8, 1, 58, 8.0 Prompt: "Run MRM starting with program" 

	//********************************************************
	
	Popdown Menu "startjob" 12, 3, 30 List: jobslist Variable: pick_jobindex do
		if pick_jobindex > 0 and pick_jobindex <= jobslist.length
			then do
				pick_job = jobslist[pick_jobindex]
				EnableItem("StartPartialRun") 
				EnableItem("ClearPartialRun") 
				JobsToRun = null
			end
			else do
				pick_job = "NO job selected"
				DisableItem("StartPartialRun")
				DisableItem("ClearPartialRun") 
				JobsToRun = null
			end
	enditem

	Text " " same, after, , 0.5
	Text "Resume run with job: " 12, after 
	Text 12, after, 35 variable: pick_job framed

	Button "StartPartialRun" after, same Icon: "bmp\\buttons|419" Help: "Start run from this job" Disabled do
		//check if everything complete up to selected start
		for j = pick_jobindex to alljobs.length do
			JobsToRun = JobsToRun + {alljobs[j]}
		end
		showarray(JobsToRun)
		rtn = RunMacro("RunJob", Args, JobsToRun)
		JobsToRun = null
		return(rtn)
	enditem 				

	Text "      Clear   " after, same 
	Button "ClearPartialRun" after, same Icon: "bmp\\buttons|23" Help: "Exit to main menu" do	
		pick_jobindex = 0
		pick_job = null
		JobsToRun = null
		DisableItem("StartPartialRun")
		DisableItem("ClearPartialRun") 
	enditem

	//***************************************************************************************************************
	Frame 1, 10, 72, 37.5 prompt: "Select individual jobs " 
	Text "Run selections" 3.0, 11.0, 26
	Button " " after, same Icon: "bmp\\buttons|419"  Help: "Run jobs selected on tabs below" do
		JobsToRun = null
		for i = 1 to runjobsorder.length do
			job = runjobsorder[i]
			if JobSel.(job) = 1 
				then do 
					JobsToRun = JobsToRun + {job}
					JobSel.(job) = 0
				end
		end
//		ShowArray(JobsToRun)
		rtn = RunMacro("RunJob", Args, JobsToRun)
		runstatus = rtn[1]
		msg = msg  + {rtn[2]}
		if runstatus = 1 
			then do
				msg = rtn[2] + {"Selected jobs completed!"}
				msg = msg + {"Last job run : " + JobsToRun[JobsToRun.length]} 				
			end
			else do
				msg = rtn[2] + {"Error running selected jobs!"}
				msg = msg + {"Please see \\Report\\TC_Log.html for details"}			
			end
		JobsToRun = null
		return({runstatus, msg})
	enditem		

	Text " Exit   " 58.0, same
	Button " " after, same Icon: "bmp\\buttons|440" Help: "Exit to main menu" Cancel do	
		JobsToRun = null
		return()
	enditem
	
	//***************************************************************************************************************
	// Tab list of jobs

	Tab List 2,13,70,35 variable: tab_index

	// First tab - Networks/Paths
	Tab prompt: "Networks/Paths"

	
	Frame 1, 0.5, 67.5, 2.5
	Text "Select All" 2, 1.5, 26
	Checkbox "all_sel_flag1" after, same prompt: "" variable: all_sel1 do
		if (all_sel1 = 1) 
			then do
				for i = 1 to netspathsjobs.length do
					job = netspathsjobs[i]
					JobSel.(job) = 1
				end
				none_sel1 = 0
			end
	enditem	

	Text "Select None" 38.0, same, 26 
	Checkbox "none_sel_flag1" after, same prompt: "" variable: none_sel1 do
		if (none_sel1 = 1) 
			then do
				for i = 1 to netspathsjobs.length do
					job = netspathsjobs[i]
					JobSel.(job) = 0
				end
				all_sel1 = 0
			end
	enditem	

	// column 1
	Text "HIGHWAY PATHS" 2.0, 3.5
	
	Text " " same, after, , 0.5
	Text "Build highway file" 2.0, after, 26
	Checkbox " " after, same Variable: JobSel.Build_Networks Help: "Build highway dcb from master" do
	enditem

	Text " " same, after, , 0.25
	Text "Area Type" 2.0, after, 26
	Checkbox " " after, same Variable: JobSel.Area_Type Help: "TAZ area type (1-5) based on land use data" do
	enditem

	Text " " same, after, , 0.25
	Text "CapSpeed" 2.0, after, 26
	Checkbox " " after, same Variable: JobSel.CapSpd Help: "Highway network capacities and speeds" do
	enditem

	Text " " same, after, , 0.25
	Text "Route System Set Up" 2.0, after, 26
	Checkbox " " after, same Variable: JobSel.RouteSystemSetUp Help: "Reload, verify and tag stops to nodes" do
	enditem

	Text " " same, after, , 0.25
	Text "Highway Skim - Peak" 2.0, after, 26
	Checkbox " " after, same Variable: JobSel.HwySkim_Peak Help: "Highway skims - peak speed" do
	enditem

	Text " " same, after, , 0.25
	Text "Highway Skim - Free" 2.0, after, 26
	Checkbox " " after, same Variable: JobSel.HwySkim_Free Help: "Highway skims - free speed" do
	enditem

	Text " " same, after, , 1.0

	// column 2
	Text "TRANSIT PATHS" 38.0, 3.5
	
	Text " " same, after, , 0.5
	Text "Prepare transit files" 38.0, after, 26
	Checkbox " " after, same Variable: JobSel.Prepare_Transit_Files Help: "Prepare transit skim / modechoice matrices & control files" do
	enditem

	Text " " same, after, , 0.25
	Text "Fill Parking Cost " 38.0, after, 26
	Checkbox " " after, same Variable: JobSel.FillParkCost Help: "Fill parking cost matricies" do
	enditem

	Text " " same, after, , 0.25
	Text "AutoSkims for Transit-Peak" 38.0, after, 26
	Checkbox " " after, same Variable: JobSel.AutoSkims_Peak Help: "Highway skims for Transit - Peak speed" do
	enditem

	Text " " same, after, , 0.25
	Text "AutoSkims for Transit-Free " 38.0, after, 26
	Checkbox " " after, same Variable: JobSel.AutoSkims_Free Help: "Highway skims for Transit - Ffree speed (offpeak)" do
	enditem

	Text " " same, after, , 0.25
	Text "Non-motorized skims" 38.0, after, 26
	Checkbox " " after, same Variable: JobSel.Reg_NonMotorized Help: "Walk and bike trips (entire trip)" do
	enditem

	Text " " same, after, , 0.25
	Text "PPrmW transit skims" 38.0, after, 26
	Checkbox " " after, same Variable: JobSel.Reg_PPrmW Help: "Peak Walk to Premium transit skims" do
	enditem

	Text " " same, after, , 0.25
	Text "PPrmD transit skim" 38.0, after, 26
	Checkbox " " after, same Variable: JobSel.Reg_PPrmD Help: "Peak Drive to Premium transit skims" do
	enditem

	Text " " same, after, , 0.25
	Text "PPrmDrop transit skim" 38.0, after, 26
	Checkbox " " after, same Variable: JobSel.Reg_PPrmDrop Help: "Peak Dropoff to Premium transit skims" do
	enditem

	Text " " same, after, , 0.25
	Text "PBusW transit skim" 38.0, after, 26
	Checkbox " " after, same Variable: JobSel.Reg_PBusW Help: "Peak Walk to Bus transit skims" do
	enditem

	Text " " same, after, , 0.25
	Text "PBusD transit skim" 38.0, after, 26
	Checkbox " " after, same Variable: JobSel.Reg_PBusD Help: "Peak Drive to Bus transit skims" do
	enditem

	Text " " same, after, , 0.25
	Text "PBusDrop transit skim" 38.0, after, 26
	Checkbox " " after, same Variable: JobSel.Reg_PBusDrop Help: "Peak Dropoff to Bus transit skims" do
	enditem

	Text " " same, after, , 0.25
	Text "OPPrmW transit skims" 38.0, after, 26
	Checkbox " " after, same Variable: JobSel.Reg_OPPrmW Help: "Offpeak Walk to Premium transit skims" do
	enditem

	Text " " same, after, , 0.25
	Text "OPPrmD transit skims" 38.0, after, 26
	Checkbox " " after, same Variable: JobSel.Reg_OPPrmD Help: "Offpeak Drive to Premium transit skims" do
	enditem

	Text " " same, after, , 0.25
	Text "OPPrmDrop transit skim" 38.0, after, 26
	Checkbox " " after, same Variable: JobSel.Reg_OPPrmDrop Help: "Offpeak Dropoff to Premium transit skims" do
	enditem

	Text " " same, after, , 0.25
	Text "OPBusW transit skim" 38.0, after, 26
	Checkbox " " after, same Variable: JobSel.Reg_OPBusW Help: "Offpeak Walk to Bus transit skims" do
	enditem

	Text " " same, after, , 0.25
	Text "OPBusD transit skim" 38.0, after, 26
	Checkbox " " after, same Variable: JobSel.Reg_OPBusD Help: "Offpeak Drive to Bus transit skims" do
	enditem

	Text " " same, after, , 0.25
	Text "OPBusDrop transit skim" 38.0, after, 26
	Checkbox " " after, same Variable: JobSel.Reg_OPBusDrop Help: "Offpeak Dropoff to Bus transit skims" do
	enditem

	Text " " same, after, , 1.0
	//***************************************************************************************************************
	//Tab 2 - Generation / Distribution

	Tab prompt: "TripGen/TripDist"

	Frame 1, 0.5, 67.5, 2.5
	Text "Select All" 2, 1.5, 26
	Checkbox "all_sel_flag2" after, same prompt: "" variable: all_sel2 do
		if (all_sel2 = 1) 
			then do
				for i = 1 to gendistribjobs.length do
					job = gendistribjobs[i]
					JobSel.(job) = 1
				end
				none_sel2 = 0
			end
	enditem	

	Text "Select None" 38.0, same, 26 
	Checkbox "none_sel_flag2" after, same prompt: "" variable: none_sel2 do
		if (none_sel2 = 1) 
			then do
				for i = 1 to gendistribjobs.length do
					job = gendistribjobs[i]
					JobSel.(job) = 0
				end
				all_sel2 = 0
			end
	enditem	


	// column 1
	Text "TRIP GENERATION" 2.0, 3.5
	
	Text " " same, after, , 0.5
	Text "External Sta CBD" 2.0, after, 26
	Checkbox " " after, same Variable: JobSel.ExtStaforTripGen Help: "External sta to CBD and nearest TAZ" do
	enditem

	Text " " same, after, , 0.25
	Text "Trip Generation" 2.0, after, 26
	Checkbox " " after, same Variable: JobSel.Trip_Generation Help: "Trip Generation" do
	enditem

	Text " " same, after, , 0.25
	Text "Aggregate P's & A's" 2.0, after, 26
	Checkbox " " after, same Variable: JobSel.Aggregate_TripGen Help: "Aggregate P's & A's to State / County" do
	enditem

	Text " " same, after, , 0.25
	Text "External-External trips" 2.0, after, 26
	Checkbox " " after, same Variable: JobSel.EE_Trips Help: "External - external (through) trips" do
	enditem

	Text " " same, after, , 0.75
	Text "TRIP DISTRIBUTION" 2.0, after

	Text " " same, after, , 0.5
	Text "Peak transit for Trip Dist" 2.0, after, 26
	Checkbox " " after, same Variable: JobSel.TD_TranPath_Peak Help: "Transit times for trip distribution (from PPrmW)" do
	enditem


	Text " " same, after, , 0.25
	Text "OP transit for Trip Dist" 2.0, after, 26
	Checkbox " " after, same Variable: JobSel.TD_TranPath_Free Help: "Transit times for trip distribution (from OPPrmW)" do
	enditem

	Text " " same, after, , 0.25
	Text "TDHBW - Inc 1" 2.0, after, 26
	Checkbox " " after, same Variable: JobSel.TDHBW1 Help: "Trip distribution - HBWork - income 1" do
	enditem

	Text " " same, after, , 0.25
	Text "TDHBW - Inc 2" 2.0, after, 26
	Checkbox " " after, same Variable: JobSel.TDHBW2 Help: "Trip distribution - HBWork - income 2" do
	enditem

	Text " " same, after, , 0.25
	Text "TDHBW - Inc 3" 2.0, after, 26
	Checkbox " " after, same Variable: JobSel.TDHBW3 Help: "Trip distribution - HBWork - income 3" do
	enditem

	Text " " same, after, , 0.25
	Text "TDHBW - Inc 4" 2.0, after, 26
	Checkbox " " after, same Variable: JobSel.TDHBW4 Help: "Trip distribution - HBWork - income 4" do
	enditem

	Text " " same, after, , 0.25
	Text "TDHBS - Inc 1 (shop)" 2.0, after, 26
	Checkbox " " after, same Variable: JobSel.TDHBS1 Help: "Trip distribution - HBShop - income 1" do
	enditem

	Text " " same, after, , 0.25
	Text "TDHBS - Inc 2 (shop)" 2.0, after, 26
	Checkbox " " after, same Variable: JobSel.TDHBS2 Help: "Trip distribution - HBShop - income 2" do
	enditem

	Text " " same, after, , 0.25
	Text "TDHBS - Inc 3 (shop)" 2.0, after, 26
	Checkbox " " after, same Variable: JobSel.TDHBS3 Help: "Trip distribution - HBShop - income 3" do
	enditem

	Text " " same, after, , 0.25
	Text "TDHBS - Inc 4 (shop)" 2.0, after, 26
	Checkbox " " after, same Variable: JobSel.TDHBS4 Help: "Trip distribution - HBShop - income 4" do
	enditem

	Text " " same, after, , 0.25
	Text "TDHBO - Inc 1" 2.0, after, 26
	Checkbox " " after, same Variable: JobSel.TDHBO1 Help: "Trip distribution - HBOther - income 1" do
	enditem

	Text " " same, after, , 0.25
	Text "TDHBO - Inc 2" 2.0, after, 26
	Checkbox " " after, same Variable: JobSel.TDHBO2 Help: "Trip distribution - HBOther - income 2" do
	enditem

	Text " " same, after, , 0.25
	Text "TDHBO - Inc 3" 2.0, after, 26
	Checkbox " " after, same Variable: JobSel.TDHBO3 Help: "Trip distribution - HBOther - income 3" do
	enditem

	Text " " same, after, , 0.25
	Text "TDHBO - Inc 4" 2.0, after, 26
	Checkbox " " after, same Variable: JobSel.TDHBO4 Help: "Trip distribution - HBOther - income 4" do
	enditem

	Text " " same, after, , 1.0

	// column 2
	Text "TDJTW - NHB-Journey to work" 38.0, 3.5, 26
	Checkbox " " after, same Variable: JobSel.TDJTW Help: "Trip distribution - NHB Journey to work" do
	enditem

	Text " " same, after, , 0.25
	Text "TDATW - NHB-At work" 38.0, after, 26
	Checkbox " " after, same Variable: JobSel.TDATW Help: "Trip distribution - NHB - At Work" do
	enditem

	Text " " same, after, , 0.25
	Text "TDNWK - NHB-Non work" 38.0, after, 26
	Checkbox " " after, same Variable: JobSel.TDNWK Help: "Trip distribution - NHB - Non-work related" do
	enditem

	Text " " same, after, , 0.25
	Text "TDSCH - HB School" 38.0, after, 26
	Checkbox " " after, same Variable: JobSel.TDSCH Help: "Trip distribution - HB School (k-12)" do
	enditem

	Text " " same, after, , 0.25
	Text "TDHBU - HB University" 38.0, after, 26
	Checkbox " " after, same Variable: JobSel.TDHBU Help: "Trip distribution - HB University" do
	enditem

	Text " " same, after, , 0.25
	Text "TDCOM - Commercial veh" 38.0, after, 26
	Checkbox " " after, same Variable: JobSel.TDCOM Help: "Trip distribution - Commercial vehicles" do
	enditem

	Text " " same, after, , 0.25
	Text "TDMTK - Medium truck" 38.0, after, 26
	Checkbox " " after, same Variable: JobSel.TDMTK Help: "Trip distribution - Medium trucks" do
	enditem

	Text " " same, after, , 0.25
	Text "TDHTK - Heavy truck" 38.0, after, 26
	Checkbox " " after, same Variable: JobSel.TDHTK Help: "Trip distribution - Heavy trucks" do
	enditem


	Text " " same, after, , 0.25
	Text "TDEIW - Ext-Int Work" 38.0, after, 26
	Checkbox " " after, same Variable: JobSel.TDEIW Help: "Trip distribution - External-internal - work" do
	enditem

	Text " " same, after, , 0.25
	Text "TDEIN - Ext-Int Non-work" 38.0, after, 26
	Checkbox " " after, same Variable: JobSel.TDEIN Help: "Trip distribution - External-internal - non work" do
	enditem

	Text " " same, after, , 0.25
	Text "TDEIC - Ext-Int Commercial" 38.0, after, 26
	Checkbox " " after, same Variable: JobSel.TDEIC Help: "Trip distribution - External-internal - commercial" do
	enditem

	Text " " same, after, , 0.25
	Text "TDEIM - Ext-Int Medium Truck" 38.0, after, 26
	Checkbox " " after, same Variable: JobSel.TDEIM Help: "Trip distribution - External-internal - medium truck" do
	enditem

	Text " " same, after, , 0.25
	Text "TDEIH - Ext-Int Heavy Truck" 38.0, after, 26
	Checkbox " " after, same Variable: JobSel.TDEIH Help: "Trip distribution - External-internal - heavy truck" do
	enditem

	Text " " same, after, , 0.25
	Text "TDIEW - Int-Ext Work" 38.0, after, 26
	Checkbox " " after, same Variable: JobSel.TDIEW Help: "Trip distribution - Internal-external - work" do
	enditem

	Text " " same, after, , 0.25
	Text "TDIEN - Int-Ext Non-work" 38.0, after, 26
	Checkbox " " after, same Variable: JobSel.TDIEN Help: "Trip distribution - Internal-external - non work" do
	enditem

	Text " " same, after, , 0.25
	Text "TDIEC - Int-Ext Commercial" 38.0, after, 26
	Checkbox " " after, same Variable: JobSel.TDIEC Help: "Trip distribution - Internal-external - commercial" do
	enditem

	Text " " same, after, , 0.25
	Text "TDIEM - Int-Ext Medium Truck" 38.0, after, 26
	Checkbox " " after, same Variable: JobSel.TDIEM Help: "Trip distribution - Internal-external - medium truck" do
	enditem

	Text " " same, after, , 0.25
	Text "TDIEH - Int-Ext Heavy Truck" 38.0, after, 26
	Checkbox " " after, same Variable: JobSel.TDIEH Help: "Trip distribution - Internal-external - heavy truck" do
	enditem

	Text " " same, after, , 0.25
	Text "TD Matrix Stats" 38.0, after, 26
	Checkbox " " after, same Variable: JobSel.TDMatrixStats Help: "Trip distribution - Matrix statistics for RunStats" do
	enditem
	Text " " same, after, , 1.0

	//**********************************************************************************************************************
	// Tab 3 - Mode Choice
	
	Tab prompt: "ModeChoice"

	Frame 1, 0.5, 67.5, 2.5
	Text "Select All" 2, 1.5, 26
	Checkbox "all_sel_flag3" after, same prompt: "" variable: all_sel3 do
		if (all_sel3 = 1) 
			then do
				for i = 1 to msjobs.length do
					job = msjobs[i]
					JobSel.(job) = 1
				end
				none_sel3 = 0
			end
	enditem	

	Text "Select None" 38.0, same, 26 
	Checkbox "none_sel_flag3" after, same prompt: "" variable: none_sel3 do
		if (none_sel3 = 1) 
			then do
				for i = 1 to msjobs.length do
					job = msjobs[i]
					JobSel.(job) = 0
				end
				all_sel3 = 0
			end
	enditem	

	// column 1
	Text "TIME-OF-DAY 1" 2.0, 3.5
	
	Text " " same, after, , 0.5
	Text "TOD1 HBW Peak" 2.0, after, 26
	Checkbox " " after, same Variable: JobSel.TOD1_HBW_Peak Help: "Time-of-day 1, HBW Peak person trips" do
	enditem

	Text " " same, after, , 0.25
	Text "TOD1 HBO Peak" 2.0, after, 26
	Checkbox " " after, same Variable: JobSel.TOD1_HBO_Peak Help: "Time-of-day 1, HBO Peak person trips" do
	enditem

	Text " " same, after, , 0.25
	Text "TOD1 NHB Peak" 2.0, after, 26
	Checkbox " " after, same Variable: JobSel.TOD1_NHB_Peak Help: "Time-of-day 1, NHB Peak person trips" do
	enditem

	Text " " same, after, , 0.25
	Text "TOD1 HBU Peak" 2.0, after, 26
	Checkbox " " after, same Variable: JobSel.TOD1_HBU_Peak Help: "Time-of-day 1, HBU Peak person trips" do
	enditem

	Text " " same, after, , 0.25
	Text "TOD1 HBW OffPeak" 2.0, after, 26
	Checkbox " " after, same Variable: JobSel.TOD1_HBW_OffPeak Help: "Time-of-day 1, HBW OffPeak person trips" do
	enditem

	Text " " same, after, , 0.25
	Text "TOD1 HBO OffPeak" 2.0, after, 26
	Checkbox " " after, same Variable: JobSel.TOD1_HBO_OffPeak Help: "Time-of-day 1, HBO OffPeak person trips" do
	enditem

	Text " " same, after, , 0.25
	Text "TOD1 NHB OffPeak" 2.0, after, 26
	Checkbox " " after, same Variable: JobSel.TOD1_NHB_OffPeak Help: "Time-of-day 1, NHB OffPeak person trips" do
	enditem

	Text " " same, after, , 0.25
	Text "TOD1 HBU OffPeak" 2.0, after, 26
	Checkbox " " after, same Variable: JobSel.TOD1_HBU_OffPeak Help: "Time-of-day 1, HBU OffPeak person trips" do
	enditem

	// column 2
	Text "MODE CHOICE" 38.0, 3.5, 26

	Text " " same, after, , 0.25
	Text "Mode Choice Peak" 38.0, after, 26
	Checkbox " " after, same Variable: JobSel.MS_RunPeak Help: "Mode Choice - Peak: HBW, HBO, NHB, HBU" do
	enditem

	Text " " same, after, , 0.25
	Text "Mode Choice Offpeak" 38.0, after, 26
	Checkbox " " after, same Variable: JobSel.MS_RunOffPeak Help: "Mode Choice - offpeak: HBW, HBO, NHB, HBU" do
	enditem

	Text " " same, after, , 0.25
	Text "MS Matrix Stats" 38.0, after, 26
	Checkbox " " after, same Variable: JobSel.MSMatrixStats Help: "Mode Choice - Matrix statistics for RunStats" do
	enditem

	Text " " same, after, , 0.75
	Text "MODE CHOICE - SEPARATE" 38.0, after
	
	Text " " same, after, , 0.5
	Text "MS_HBW_Peak ONLY" 38.0, after, 26
	Checkbox " " after, same Variable: JobSel.MS_HBWPeak Help: "Mode Choice - HBW Peak ONLY" do
	enditem
	
	Text " " same, after, , 0.25
	Text "MS_HBW_OffPeak ONLY" 38.0, after, 26
	Checkbox " " after, same Variable: JobSel.MS_HBWOffPeak Help: "Mode Choice - HBW OffPeak ONLY" do
	enditem
	
	Text " " same, after, , 0.25
	Text "MS_HBO_Peak ONLY" 38.0, after, 26
	Checkbox " " after, same Variable: JobSel.MS_HBOPeak Help: "Mode Choice - HBO Peak ONLY" do
	enditem
	
	Text " " same, after, , 0.25
	Text "MS_HBO_OffPeak ONLY" 38.0, after, 26
	Checkbox " " after, same Variable: JobSel.MS_HBOOffPeak Help: "Mode Choice - HBO OffPeak ONLY" do
	enditem
	
	Text " " same, after, , 0.25
	Text "MS_NHB_Peak ONLY" 38.0, after, 26
	Checkbox " " after, same Variable: JobSel.MS_NHBPeak Help: "Mode Choice - NHB Peak ONLY" do
	enditem
	
	Text " " same, after, , 0.25
	Text "MS_NHB_OffPeak ONLY" 38.0, after, 26
	Checkbox " " after, same Variable: JobSel.MS_NHBOffPeak Help: "Mode Choice - NHB OffPeak ONLY" do
	enditem
	
	Text " " same, after, , 0.25
	Text "MS_HBU_Peak ONLY" 38.0, after, 26
	Checkbox " " after, same Variable: JobSel.MS_HBUPeak Help: "Mode Choice - HBU Peak ONLY" do
	enditem
	
	Text " " same, after, , 0.25
	Text "MS_HBU_OffPeak ONLY" 38.0, after, 26
	Checkbox " " after, same Variable: JobSel.MS_HBUOffPeak Help: "Mode Choice - HBU OffPeak ONLY" do
	enditem
	
	Text " " same, after, , 1.0

	//********************************************************
	// Tab 4 - assignment - highway and transit

	Tab prompt: "Hwy/Tran Assignment"

	Frame 1, 0.5, 67.5, 2.5
	Text "Select All" 2, 1.5, 26
	Checkbox "all_sel_flag4" after, same prompt: "" variable: all_sel4 do
		if (all_sel4 = 1) 
			then do
				for i = 1 to hwyassnjobs.length do
					job = hwyassnjobs[i]
					JobSel.(job) = 1
				end
				for i = 1 to runtranassnjobs.length do
					job = runtranassnjobs[i]
					JobSel.(job) = 1
				end
				none_sel4 = 0
			end
	enditem	

	Text "Select None" 38.0, same, 26 
	Checkbox "none_sel_flag4" after, same prompt: "" variable: none_sel4 do
		if (none_sel4 = 1) 
			then do
				for i = 1 to hwyassnjobs.length do
					job = hwyassnjobs[i]
					JobSel.(job) = 0
				end
				for i = 1 to runtranassnjobs.length do
					job = runtranassnjobs[i]
					JobSel.(job) = 0
				end
				all_sel4 = 0
			end
	enditem	

	// column 1
	Text "TIME-OF-DAY 2" 2.0, 3.5
	
	Text " " same, after, , 0.5
	Text "TOD2 COM MTK HTK" 2.0, after, 26
	Checkbox " " after, same Variable: JobSel.TOD2_COM_MTK_HTK Help: "Time-of-day 2 - Commercial & truck transposed veh trip tables" do
	enditem

	Text " " same, after, , 0.25
	Text "TOD2 AM Peak" 2.0, after, 26
	Checkbox " " after, same Variable: JobSel.TOD2_AMPeak Help: "Time-of-day 2 - AM Peak vehicle O&D trip tables" do
	enditem

	Text " " same, after, , 0.25
	Text "TOD2 Midday" 2.0, after, 26
	Checkbox " " after, same Variable: JobSel.TOD2_Midday Help: "Time-of-day 2 - Midday vehicle O&D trip tables" do
	enditem

	Text " " same, after, , 0.25
	Text "TOD2 PMPeak" 2.0, after, 26
	Checkbox " " after, same Variable: JobSel.TOD2_PMPeak Help: "Time-of-day 2 - PM Peak vehicle O&D trip tables" do
	enditem

	Text " " same, after, , 0.25
	Text "TOD2 Night" 2.0, after, 26
	Checkbox " " after, same Variable: JobSel.TOD2_Night Help: "Time-of-day 2 - Night vehicle O&D trip tables" do
	enditem

	Text " " same, after, , 0.75
	Text "HIGHWAY ASSIGNMENT Prelim" 2.0, after
		
	Text " " same, after, , 0.25
	Text "Hwy Assn AM Peak" 2.0, after, 26
	Checkbox " " after, same Variable: JobSel.HwyAssn_RunAMPeak Help: "Preliminary (non-HOT) Highway assignment - AM Peak" do
	enditem

	Text " " same, after, , 0.25
	Text "Hwy Assn Midday" 2.0, after, 26
	Checkbox " " after, same Variable: JobSel.HwyAssn_RunMidday Help: "Preliminary (non-HOT) Highway assignment - Midday" do
	enditem

	Text " " same, after, , 0.25
	Text "Hwy Assn PMPeak" 2.0, after, 26
	Checkbox " " after, same Variable: JobSel.HwyAssn_RunPMPeak Help: "Preliminary (non-HOT) Highway assignment - PM Peak" do
	enditem

	Text " " same, after, , 0.25
	Text "Hwy Assn Night" 2.0, after, 26
	Checkbox " " after, same Variable: JobSel.HwyAssn_RunNight Help: "Preliminary (non-HOT) Highway assignment - Night" do
	enditem

	Text " " same, after, , 0.25
	Text "Feedback TravelTime" 2.0, after, 26
	Checkbox " " after, same Variable: JobSel.Feedback_TravelTime Help: "Feedback AM HwyAssn travel time to peak minimum paths" do
	enditem

	Text " " same, after, , 0.75
	Text "HOT LANES HIGHWAY ASSIGNMENT" 2.0, after
		
	Text " " same, after, , 0.25
	Text "HOT HwyAssn AM Peak" 2.0, after, 26
	Checkbox " " after, same Variable: JobSel.HwyAssn_RunHOTAMPeak Help: "HOT lanes highway assignment - AM Peak" do
	enditem

	Text " " same, after, , 0.25
	Text "HOT HwyAssn Midday" 2.0, after, 26
	Checkbox " " after, same Variable: JobSel.HwyAssn_RunHOTMidday Help: "HOT lanes highway assignment - Midday" do
	enditem

	Text " " same, after, , 0.25
	Text "HOT HwyAssn PMPeak" 2.0, after, 26
	Checkbox " " after, same Variable: JobSel.HwyAssn_RunHOTPMPeak Help: "HOT lanes highway assignment - PM Peak" do
	enditem

	Text " " same, after, , 0.25
	Text "HOT HwyAssn Night" 2.0, after, 26
	Checkbox " " after, same Variable: JobSel.HwyAssn_RunHOTNight Help: "HOT lanes highway assignment - Night" do
	enditem

	Text " " same, after, , 0.25
	Text "TotAssn - Post HOT assign" 2.0, after, 26
	Checkbox " " after, same Variable: JobSel.HwyAssn_RunHOTTotAssn Help: "Aggregate HOT AMPeak, Midday, PMPeak, Night highway assignments" do
	enditem

	Text " " same, after, , 0.25
	Text "OD Matrix Stats" 2.0, after, 26
	Checkbox " " after, same Variable: JobSel.ODMatrixStats Help: "Origin-Destination - Matrix statistics for RunStats" do
	enditem

	Text " " same, after, , 0.25
	Text "VMT for Air Quality" 2.0, after, 26
	Checkbox " " after, same Variable: JobSel.VMTAQ Help: "Create VMT / VHT tables for air quality reporting" do
	enditem

	Text " " same, after, , 0.25
	Text "Average trip length" 2.0, after, 26
	Checkbox " " after, same Variable: JobSel.AvgTripLenTrips Help: "Create Average trip length and time datasets" do
	enditem

	Text " " same, after, , 0.25
	Text "Highway Calibration stats" 2.0, after, 26
	Checkbox " " after, same Variable: JobSel.HighwayCalibrationStats Help: "Build count to assigned volumes comparison sets (screenline, atfun, ...)" do
	enditem

	// column 2
	Text "TRANSIT ASSIGNMENT" 38.0, 3.5
	
	Text " " same, after, , 0.25
	Text "Transit_Input" 38.0, after, 26
	Checkbox " " after, same Variable: JobSel.Transit_Input Help: "Prepare Mode Choice Transit trips for assigment" do
	enditem

	Text " " same, after, , 0.25
	Text "PPrmW Assign" 38.0, after, 26
	Checkbox " " after, same Variable: JobSel.PPrmW_Assign Help: "Peak Premium Walk approach Transit assignment" do
	enditem

	Text " " same, after, , 0.25
	Text "PPrmD Assign" 38.0, after, 26
	Checkbox " " after, same Variable: JobSel.PPrmD_Assign Help: "Peak Premium Drive approach Transit assignment" do
	enditem

	Text " " same, after, , 0.25
	Text "PPrmDrop Assign" 38.0, after, 26
	Checkbox " " after, same Variable: JobSel.PPrmDrop_Assign Help: "Peak Premium Dropoff approach Transit assignment" do
	enditem

	Text " " same, after, , 0.25
	Text "PBusW Assign" 38.0, after, 26
	Checkbox " " after, same Variable: JobSel.PBusW_Assign Help: "Peak Bus Walk approach Transit assignment" do
	enditem

	Text " " same, after, , 0.25
	Text "PBusD Assign" 38.0, after, 26
	Checkbox " " after, same Variable: JobSel.PBusD_Assign Help: "Peak Bus Drive approach Transit assignment" do
	enditem

	Text " " same, after, , 0.25
	Text "PBusDrop Assign" 38.0, after, 26
	Checkbox " " after, same Variable: JobSel.PBusDrop_Assign Help: "Peak Bus Dropoff approach Transit assignment" do
	enditem

	Text " " same, after, , 0.25
	Text "OPPrmW Assign" 38.0, after, 26
	Checkbox " " after, same Variable: JobSel.OPPrmW_Assign Help: "OffPeak Premium Walk approach Transit assignment" do
	enditem

	Text " " same, after, , 0.25
	Text "OPPrmD Assign" 38.0, after, 26
	Checkbox " " after, same Variable: JobSel.OPPrmD_Assign Help: "OffPeak Premium Drive approach Transit assignment" do
	enditem

	Text " " same, after, , 0.25
	Text "OPPrmDrop Assign" 38.0, after, 26
	Checkbox " " after, same Variable: JobSel.OPPrmDrop_Assign Help: "OffPeak Premium Dropoff approach Transit assignment" do
	enditem

	Text " " same, after, , 0.25
	Text "OPBusW Assign" 38.0, after, 26
	Checkbox " " after, same Variable: JobSel.OPBusW_Assign Help: "OffPeak Bus Walk approach Transit assignment" do
	enditem

	Text " " same, after, , 0.25
	Text "OPBusD Assign" 38.0, after, 26
	Checkbox " " after, same Variable: JobSel.OPBusD_Assign Help: "OffPeak Bus Drive approach Transit assignment" do
	enditem

	Text " " same, after, , 0.25
	Text "OPBusDrop Assign" 38.0, after, 26
	Checkbox " " after, same Variable: JobSel.OPBusDrop_Assign Help: "OffPeak Bus Dropoff approach Transit assignment" do
	enditem

	Text " " same, after, , 0.25
	Text "Transit Pax Stats" 38.0, after, 26
	Checkbox " " after, same Variable: JobSel.Transit_Pax_Stats Help: "Create transit \\RouteOut table" do
	enditem

	Text " " same, after, , 0.25
	Text "Transit Op Stats" 38.0, after, 26
	Checkbox " " after, same Variable: JobSel.Transit_Operations_Stats Help: "Create transit operations statistics tables" do
	enditem

	Text " " same, after, , 0.25
	Text "Transit Boardings" 38.0, after, 26
	Checkbox " " after, same Variable: JobSel.Transit_Boardings Help: "Route Ons/Offs by Stop (routes.dbf GRP_LIST = 1-4)" do
	enditem

	Text " " same, after, , 0.25
	Text "Transit RunStats" 38.0, after, 26
	Checkbox " " after, same Variable: JobSel.Transit_RunStats Help: "Create download table for RunStats spreadsheet" do
	enditem

	Text " " same, after, , 1.0

enddbox
