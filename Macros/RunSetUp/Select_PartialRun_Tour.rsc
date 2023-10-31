DBox "Select_PartialRun_Tour" (Args, runjobsets_tour) right, top Title: "Select Metrolina Tour sections or steps to run"
//  DBox to select partial run of MRM	

	Init do
		dim JobsToRun[1]
		dim jobslist[1]

		maxfeedbackiter = Args.[Feedback Iterations].value

		runbasejobs_tour = runjobsets_tour[1]
		runfeedbackjobs_tour = runjobsets_tour[2]
		runpostfeedbackjobs_tour = runjobsets_tour[3]
		runtranassnjobs = runjobsets_tour[4]
		runHOTassnjobs = runjobsets_tour[5]
	
		
		//runjobsorder - list of jobs in order without feedback - used to run singly selected jobs in proper order
		//   it also includes solo mode choice runs - at end of list 

		netspathsjobs = {"Build_Networks", "Area_Type", "CapSpd", "RouteSystemSetUp", 
				"HwySkim_Free", "HwySkim_Peak", 
				"Prepare_Transit_Files", "FillParkCost", "AutoSkims_Free", "AutoSkims_Peak",  "Reg_NonMotorized", 
				"Reg_PPrmW", "Reg_PPrmD", "Reg_PPrmDrop", "Reg_PBusW", "Reg_PBusD", "Reg_PBusDrop", 
				"Reg_OPPrmW", "Reg_OPPrmD", "Reg_OPPrmDrop", "Reg_OPBusW", "Reg_OPBusD", "Reg_OPBusDrop", "TD_TranPath_Peak", "TD_TranPath_Free"}

		gendistribjobs = {"Tour_XX", "ExtStaforTripGen", "HHMET", "Tour_Accessibility", "Tour_Frequency", 
				"Tour_DestinationChoice", "Tour_IS", "Tour_IS_Location", "Tour_DC_FB", "Tour_TruckTGTD"}

		msjobs = {"Tour_TOD1", "Tour_TripAccumulator", "MS_RunPeak", "MS_RunOffPeak", "MSMatrixStats"} 

		mssolojobs = {"MS_HBWPeak", "MS_HBWOffPeak", "MS_HBOPeak", "MS_HBOOffPeak", "MS_NHBPeak", "MS_NHBOffPeak", 
				"MS_HBUPeak", "MS_HBUOffPeak"}

		hwyassnjobs = {"Tour_TOD2_AMPeak", "Tour_TOD2_Midday", "Tour_TOD2_Night", "Tour_TOD2_PMPeak",  
				"HwyAssn_RunAMPeak", "HwyAssn_RunMidday", "HwyAssn_RunPMPeak", "HwyAssn_RunNight", 
				"HwyAssn_RunTotAssn", "Feedback_TravelTime",
				"HwyAssn_RunHOTAMPeak", "HwyAssn_RunHOTPMPeak", "HwyAssn_RunHOTMidday", "HwyAssn_RunHOTNight", 
				"HwyAssn_RunHOTTotAssn"}

		hwyassnsolojobs = {"HighwayCalibrationStats_tour"}


		//runjobsorder - list of jobs in order without feedback - used to run singly selected jobs in proper order
		//   it also includes solo mode choice runs - at end of list 
//		runjobsorder = runbasejobs_tour +  {"Feedback_TravelTime"} + {"Tour_DC_FB"} + runpostfeedbackjobs_tour + msjobs + mssolojobs + hwyassnjobs + runtranassnjobs + runHOTassnjobs
//12/1/16, mk; changed from above, wasn't allowing IS feedback to be run singly
		runjobsorder = runbasejobs_tour +  runfeedbackjobs_tour + runpostfeedbackjobs_tour + msjobs + mssolojobs + hwyassnjobs + runtranassnjobs + runHOTassnjobs + hwyassnsolojobs

		DisableItem("StartPartialRun")
		DisableItem("ClearPartialRun")
		
		pick_jobindex = 1
		
		alljobs = runbasejobs_tour
		if maxfeedbackiter < 2 then goto skipfeedback1
		for i = 2 to maxfeedbackiter do
			alljobs = alljobs + runfeedbackjobs_tour
		end
		skipfeedback1:
		alljobs = alljobs + runpostfeedbackjobs_tour	+ runtranassnjobs + runHOTassnjobs
			
		jobslist = null
		for j = 1 to runbasejobs_tour.length do
			jobslist = jobslist + {runbasejobs_tour[j]+ " / iter 1"}
		end
		if maxfeedbackiter < 2 then goto skipfeedback2
		for i = 2 to maxfeedbackiter do
			iteradd = " / iter " + i2s(i)
			for j = 1 to runfeedbackjobs_tour.length do
				jobslist = jobslist + {runfeedbackjobs_tour[j] + iteradd}		
			end
		end
		skipfeedback2:
		for j = 1 to runpostfeedbackjobs_tour.length do
			jobslist = jobslist + {runpostfeedbackjobs_tour[j]}
		end
		for j = 1 to runtranassnjobs.length do
			jobslist = jobslist + {runtranassnjobs[j]}
		end
		for j = 1 to runHOTassnjobs.length do
			jobslist = jobslist + {runHOTassnjobs[j]}
		end

			
	enditem	
	
	Frame "partialmodelframe" 8, 1, 58, 8.0 Prompt: "Run Metrolina Tour Model starting with program" 

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
		rtn = RunMacro("RunJob_Tour", Args, JobsToRun)
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
	Frame 1, 10, 72, 34.5 prompt: "Select individual jobs " 
	Text "Run selections" 3.0, 11.0, 26
	Button " " after, same Icon: "bmp\\buttons|419"  Help: "Run jobs selected on tabs below" do
		JobsToRun = null
		for i = 1 to runjobsorder.length do
			job = runjobsorder[i]
			if jobstatus.(job).runsel = 1 
				then do 
					JobsToRun = JobsToRun + {job}
					jobstatus.(job).runsel = 0
				end
		end
//		ShowArray(JobsToRun)
		rtn = RunMacro("RunJob_Tour", Args, JobsToRun)
		JobsToRun = null
		return(rtn)
	enditem		

	Text " Exit   " 58.0, same
	Button " " after, same Icon: "bmp\\buttons|440" Help: "Exit to main menu" do	
		JobsToRun = null
		return()
	enditem
	
	//***************************************************************************************************************
	// Tab list of jobs
	Tab List 2,13,70,31 variable: tab_index

	Tab prompt: "Networks/Paths"
	
	Frame 1, 0.5, 67.5, 2.5
	Text "Select All" 2, 1.5, 26
	Checkbox "all_sel_flag1" after, same prompt: "" variable: all_sel1 do
		if (all_sel1 = 1) 
			then do
				for i = 1 to netspathsjobs.length do
					job = netspathsjobs[i]
					jobstatus.(job).runsel = 1
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
					jobstatus.(job).runsel = 0
				end
				all_sel1 = 0
			end
	enditem	

	// column 1
	Text "HIGHWAY PATHS" 2.0, 3.5
	
	Text " " same, after, , 0.5
	Text "Build highway file" 2.0, after, 26
	Checkbox " " after, same Variable: jobstatus.Build_Networks.runsel  Help: "Build highway dcb from master" do
	enditem

	Text " " same, after, , 0.25
	Text "Area Type" 2.0, after, 26
	Checkbox " " after, same Variable: jobstatus.Area_Type.runsel  Help: "TAZ area type (1-5) based on land use data" do
	enditem

	Text " " same, after, , 0.25
	Text "CapSpeed" 2.0, after, 26
	Checkbox " " after, same Variable: jobstatus.CapSpd.runsel  Help: "Highway network capacities and speeds" do
	enditem

	Text " " same, after, , 0.25
	Text "Route System Set Up" 2.0, after, 26
	Checkbox " " after, same Variable: jobstatus.RouteSystemSetUp.runsel  Help: "Reload, verify and tag stops to nodes" do
	enditem

	Text " " same, after, , 0.25
	Text "Highway Skim - Peak" 2.0, after, 26
	Checkbox " " after, same Variable: jobstatus.HwySkim_Peak.runsel  Help: "Highway skims - peak speed" do
	enditem

	Text " " same, after, , 0.25
	Text "Highway Skim - Free" 2.0, after, 26
	Checkbox " " after, same Variable: jobstatus.HwySkim_Free.runsel  Help: "Highway skims - free speed" do
	enditem

	Text " " same, after, , 0.25
	Text "AutoSkims for Transit-Peak" 2.0, after, 26
	Checkbox " " after, same Variable: jobstatus.AutoSkims_Peak.runsel  Help: "Highway skims for Transit - Peak speed" do
	enditem

	Text " " same, after, , 0.25
	Text "AutoSkims for Transit-Free " 2.0, after, 26
	Checkbox " " after, same Variable: jobstatus.AutoSkims_Free.runsel  Help: "Highway skims for Transit - Ffree speed (offpeak)" do
	enditem

	Text " " same, after, , 1.0

	// column 2
	Text "TRANSIT PATHS" 38.0, 3.5
	
	Text " " same, after, , 0.5
	Text "Prepare transit files" 38.0, after, 26
	Checkbox " " after, same Variable: jobstatus.Prepare_Transit_Files.runsel  Help: "Prepare transit skim / modechoice matrices & control files" do
	enditem

	Text " " same, after, , 0.25
	Text "Fill Parking Cost " 38.0, after, 26
	Checkbox " " after, same Variable: jobstatus.FillParkCost.runsel  Help: "Fill parking cost matricies" do
	enditem

	Text " " same, after, , 0.25
	Text "Non-motorized skims" 38.0, after, 26
	Checkbox " " after, same Variable: jobstatus.Reg_NonMotorized.runsel  Help: "Walk and bike trips (entire trip)" do
	enditem

	Text " " same, after, , 0.25
	Text "PPrmW transit skims" 38.0, after, 26
	Checkbox " " after, same Variable: jobstatus.Reg_PPrmW.runsel  Help: "Peak Walk to Premium transit skims" do
	enditem

	Text " " same, after, , 0.25
	Text "PPrmD transit skim" 38.0, after, 26
	Checkbox " " after, same Variable: jobstatus.Reg_PPrmD.runsel  Help: "Peak Drive to Premium transit skims" do
	enditem

	Text " " same, after, , 0.25
	Text "PPrmDrop transit skim" 38.0, after, 26
	Checkbox " " after, same Variable: jobstatus.Reg_PPrmDrop.runsel  Help: "Peak Dropoff to Premium transit skims" do
	enditem

	Text " " same, after, , 0.25
	Text "PBusW transit skim" 38.0, after, 26
	Checkbox " " after, same Variable: jobstatus.Reg_PBusW.runsel  Help: "Peak Walk to Bus transit skims" do
	enditem

	Text " " same, after, , 0.25
	Text "PBusD transit skim" 38.0, after, 26
	Checkbox " " after, same Variable: jobstatus.Reg_PBusD.runsel  Help: "Peak Drive to Bus transit skims" do
	enditem

	Text " " same, after, , 0.25
	Text "PBusDrop transit skim" 38.0, after, 26
	Checkbox " " after, same Variable: jobstatus.Reg_PBusDrop.runsel  Help: "Peak Dropoff to Bus transit skims" do
	enditem

	Text " " same, after, , 0.25
	Text "OPPrmW transit skims" 38.0, after, 26
	Checkbox " " after, same Variable: jobstatus.Reg_OPPrmW.runsel  Help: "Offpeak Walk to Premium transit skims" do
	enditem

	Text " " same, after, , 0.25
	Text "OPPrmD transit skims" 38.0, after, 26
	Checkbox " " after, same Variable: jobstatus.Reg_OPPrmD.runsel  Help: "Offpeak Drive to Premium transit skims" do
	enditem

	Text " " same, after, , 0.25
	Text "OPPrmDrop transit skim" 38.0, after, 26
	Checkbox " " after, same Variable: jobstatus.Reg_OPPrmDrop.runsel  Help: "Offpeak Dropoff to Premium transit skims" do
	enditem

	Text " " same, after, , 0.25
	Text "OPBusW transit skim" 38.0, after, 26
	Checkbox " " after, same Variable: jobstatus.Reg_OPBusW.runsel  Help: "Offpeak Walk to Bus transit skims" do
	enditem

	Text " " same, after, , 0.25
	Text "OPBusD transit skim" 38.0, after, 26
	Checkbox " " after, same Variable: jobstatus.Reg_OPBusD.runsel  Help: "Offpeak Drive to Bus transit skims" do
	enditem

	Text " " same, after, , 0.25
	Text "OPBusDrop transit skim" 38.0, after, 26
	Checkbox " " after, same Variable: jobstatus.Reg_OPBusDrop.runsel  Help: "Offpeak Dropoff to Bus transit skims" do
	enditem


	Text " " same, after, , 0.5
	Text "Peak transit for Trip Dist" 38.0, after, 26
	Checkbox " " after, same Variable: jobstatus.TD_TranPath_Peak.runsel  Help: "Transit times for trip distribution (from PPrmW)" do
	enditem


	Text " " same, after, , 0.25
	Text "OP transit for Trip Dist" 38.0, after, 26
	Checkbox " " after, same Variable: jobstatus.TD_TranPath_Free.runsel  Help: "Transit times for trip distribution (from OPPrmW)" do
	enditem

	Text " " same, after, , 1.0
	//***************************************************************************************************************

	Tab prompt: "TripGen/TripDist"

	Frame 1, 0.5, 67.5, 2.5
	Text "Select All" 2, 1.5, 26
	Checkbox "all_sel_flag2" after, same prompt: "" variable: all_sel2 do
		if (all_sel2 = 1) 
			then do
				for i = 1 to gendistribjobs.length do
					job = gendistribjobs[i]
					jobstatus.(job).runsel = 1
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
					jobstatus.(job).runsel = 0
				end
				all_sel2 = 0
			end
	enditem	


	// column 1
	Text "TOUR GENERATION" 2.0, 3.5
	
	Text " " same, after, , 0.25
	Text "External-External tours" 2.0, after, 26
	Checkbox " " after, same Variable: jobstatus.Tour_XX.runsel  Help: "External - external (through) tours" do
	enditem

	Text " " same, after, , 0.5
	Text "External Sta CBD" 2.0, after, 26
	Checkbox " " after, same Variable: jobstatus.ExtStaforTripGen.runsel  Help: "External sta to CBD and nearest TAZ" do
	enditem

	Text " " same, after, , 0.25
	Text "HHMET" 2.0, after, 26
	Checkbox " " after, same Variable: jobstatus.HHMET.runsel  Help: "Household Synthesis" do
	enditem

	Text " " same, after, , 0.25
	Text "Accessibility Calcs" 2.0, after, 26
	Checkbox " " after, same Variable: jobstatus.Tour_Accessibility.runsel  Help: "Calculate Accessibility" do
	enditem

	Text " " same, after, , 0.25
	Text "Tour Frequency" 2.0, after, 26
	Checkbox " " after, same Variable: jobstatus.Tour_Frequency.runsel  Help: "Tour Frequency" do
	enditem

	Text " " same, after, , 0.5
	Text "TOUR Destincation Choice" 2.0, after

	Text " " same, after, , 0.25
	Text "Tour Destination Choice" 2.0, after, 26
	Checkbox " " after, same Variable: jobstatus.Tour_DestinationChoice.runsel  Help: "Tour Destination Choice" do
	enditem

	Text " " same, after, , 0.5
	Text "Intermediate Stops" 2.0, after, 26
	Checkbox " " after, same Variable: jobstatus.Tour_IS.runsel  Help: "Intermediate Stops Frequency" do
	enditem

	Text " " same, after, , 0.5
	Text "Intermediate Stop Location" 2.0, after, 26
	Checkbox " " after, same Variable: jobstatus.Tour_IS_Location.runsel  Help: "Intermediate Stops Location" do
	enditem

	Text " " same, after, , 0.25
	Text "Tour DC Feedback" 2.0, after, 26
	Checkbox " " after, same Variable: jobstatus.Tour_DC_FB.runsel  Help: "Run DC Work Feedback" do
	enditem

	Text " " same, after, , 0.25
	Text "Tour IS Feedback" 2.0, after, 26
	Checkbox " " after, same Variable: jobstatus.Tour_IS_FB.runsel  Help: "Run DC IS Feedback" do
	enditem

	Text " " same, after, , 0.25
	Text "Tour IS Loc Feedback" 2.0, after, 26
	Checkbox " " after, same Variable: jobstatus.Tour_IS_Location_FB.runsel  Help: "Run IS Location Feedback" do
	enditem


	Text " " same, after, , 0.5
	Text "TRUCK MODEL" 2.0, after

	Text " " same, after, , 0.25
//	Text "Tour Truck Model" 2.0, after, 26		Tour truck model not ready
	Text "Truck Model (Trip-based)" 2.0, after, 26
	Checkbox " " after, same Variable: jobstatus.Tour_TruckTGTD.runsel  Help: "Run Trip Gen & Dist for Trucks" do
	enditem
	Text " " same, after, , 1.0

	//**********************************************************************************************************************
	
	Tab prompt: "ModeChoice"
	
	Frame 1, 0.5, 67.5, 2.5
	Text "Select All" 2, 1.5, 26
	Checkbox "all_sel_flag3" after, same prompt: "" variable: all_sel3 do
		if (all_sel3 = 1) 
			then do
				for i = 1 to msjobs.length do
					job = msjobs[i]
					jobstatus.(job).runsel = 1
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
					jobstatus.(job).runsel = 0
				end
				all_sel3 = 0
			end
	enditem	

	// column 1
	Text "TIME-OF-DAY 1" 2.0, 3.5
	
	Text " " same, after, , 0.5
	Text "TOD1 (all)" 2.0, after, 26
	Checkbox " " after, same Variable: jobstatus.Tour_ToD1.runsel Help: "Time-of-day 1, all Tour types" do
	enditem

	Text " " same, after, , 0.5
	Text "Trip Accumulator" 2.0, after, 26
	Checkbox " " after, same Variable: jobstatus.Tour_TripAccumulator.runsel Help: "Get Tour files into Trips for Mode Choice" do
	enditem

	Text " " same, after, , 0.5
	Text "TOD1 Feedback" 2.0, after, 26
	Checkbox " " after, same Variable: jobstatus.Tour_ToD1_FB.runsel Help: "Time-of-day 1, feedback" do
	enditem

	Text " " same, after, , 0.5
	Text "Trip Accumulator Feedback" 2.0, after, 26
	Checkbox " " after, same Variable: jobstatus.Tour_TripAccumulator_FB.runsel Help: "Get Tour files into Trips for Mode Choice" do
	enditem

/*	Text " " same, after, , 0.25
	Text "TOD1 HBO Peak" 2.0, after, 26
	Checkbox " " after, same Variable: jobstatus.TOD1_HBO_Peak.runsel Help: "Time-of-day 1, HBO Peak person trips" do
	enditem

	Text " " same, after, , 0.25
	Text "TOD1 NHB Peak" 2.0, after, 26
	Checkbox " " after, same Variable: jobstatus.TOD1_NHB_Peak.runsel Help: "Time-of-day 1, NHB Peak person trips" do
	enditem

	Text " " same, after, , 0.25
	Text "TOD1 HBU Peak" 2.0, after, 26
	Checkbox " " after, same Variable: jobstatus.TOD1_HBU_Peak.runsel Help: "Time-of-day 1, HBU Peak person trips" do
	enditem

	Text " " same, after, , 0.25
	Text "TOD1 HBW OffPeak" 2.0, after, 26
	Checkbox " " after, same Variable: jobstatus.TOD1_HBW_OffPeak.runsel Help: "Time-of-day 1, HBW OffPeak person trips" do
	enditem

	Text " " same, after, , 0.25
	Text "TOD1 HBO OffPeak" 2.0, after, 26
	Checkbox " " after, same Variable: jobstatus.TOD1_HBO_OffPeak.runsel Help: "Time-of-day 1, HBO OffPeak person trips" do
	enditem

	Text " " same, after, , 0.25
	Text "TOD1 NHB OffPeak" 2.0, after, 26
	Checkbox " " after, same Variable: jobstatus.TOD1_NHB_OffPeak.runsel Help: "Time-of-day 1, NHB OffPeak person trips" do
	enditem

	Text " " same, after, , 0.25
	Text "TOD1 HBU OffPeak" 2.0, after, 26
	Checkbox " " after, same Variable: jobstatus.TOD1_HBU_OffPeak.runsel Help: "Time-of-day 1, HBU OffPeak person trips" do
	enditem
*/
	// column 2
	Text "MODE CHOICE" 38.0, 3.5, 26

	Text " " same, after, , 0.25
	Text "Mode Choice Peak" 38.0, after, 26
	Checkbox " " after, same Variable: jobstatus.MS_RunPeak.runsel Help: "Mode Choice - Peak: HBW, HBO, NHB, HBU" do
	enditem

	Text " " same, after, , 0.25
	Text "Mode Choice Offpeak" 38.0, after, 26
	Checkbox " " after, same Variable: jobstatus.MS_RunOffPeak.runsel Help: "Mode Choice - offpeak: HBW, HBO, NHB, HBU" do
	enditem

	Text " " same, after, , 0.5
	Text "MODE CHOICE - SEPARATE" 38.0, after
	
	Text " " same, after, , 0.5
	Text "MS_HBW_Peak ONLY" 38.0, after, 26
	Checkbox " " after, same Variable: jobstatus.MS_HBWPeak.runsel Help: "Mode Choice - HBW Peak ONLY" do
	enditem
	
	Text " " same, after, , 0.25
	Text "MS_HBW_OffPeak ONLY" 38.0, after, 26
	Checkbox " " after, same Variable: jobstatus.MS_HBWOffPeak.runsel Help: "Mode Choice - HBW OffPeak ONLY" do
	enditem
	
	Text " " same, after, , 0.25
	Text "MS_HBO_Peak ONLY" 38.0, after, 26
	Checkbox " " after, same Variable: jobstatus.MS_HBOPeak.runsel Help: "Mode Choice - HBO Peak ONLY" do
	enditem
	
	Text " " same, after, , 0.25
	Text "MS_HBO_OffPeak ONLY" 38.0, after, 26
	Checkbox " " after, same Variable: jobstatus.MS_HBOOffPeak.runsel Help: "Mode Choice - HBO OffPeak ONLY" do
	enditem
	
	Text " " same, after, , 0.25
	Text "MS_NHB_Peak ONLY" 38.0, after, 26
	Checkbox " " after, same Variable: jobstatus.MS_NHBPeak.runsel Help: "Mode Choice - NHB Peak ONLY" do
	enditem
	
	Text " " same, after, , 0.25
	Text "MS_NHB_OffPeak ONLY" 38.0, after, 26
	Checkbox " " after, same Variable: jobstatus.MS_NHBOffPeak.runsel Help: "Mode Choice - NHB OffPeak ONLY" do
	enditem
	
	Text " " same, after, , 0.25
	Text "MS_HBU_Peak ONLY" 38.0, after, 26
	Checkbox " " after, same Variable: jobstatus.MS_HBUPeak.runsel Help: "Mode Choice - HBU Peak ONLY" do
	enditem
	
	Text " " same, after, , 0.25
	Text "MS_HBU_OffPeak ONLY" 38.0, after, 26
	Checkbox " " after, same Variable: jobstatus.MS_HBUOffPeak.runsel Help: "Mode Choice - HBU OffPeak ONLY" do
	enditem
	
	Text " " same, after, , 1.0

	//********************************************************
	Tab prompt: "Hwy/Tran Assignment"
	
	Frame 1, 0.5, 67.5, 2.5
	Text "Select All" 2, 1.5, 26
	Checkbox "all_sel_flag4" after, same prompt: "" variable: all_sel4 do
		if (all_sel4 = 1) 
			then do
				for i = 1 to hwyassnjobs.length do
					job = hwyassnjobs[i]
					jobstatus.(job).runsel = 1
				end
				for i = 1 to runtranassnjobs.length do
					job = runtranassnjobs[i]
					jobstatus.(job).runsel = 1
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
					jobstatus.(job).runsel = 0
				end
				for i = 1 to runtranassnjobs.length do
					job = runtranassnjobs[i]
					jobstatus.(job).runsel = 0
				end
				all_sel4 = 0
			end
	enditem	

	// column 1
	Text "TIME-OF-DAY 2" 2.0, 3.5
	
	Text " " same, after, , 0.25
	Text "TOD2 AM Peak" 2.0, after, 26
	Checkbox " " after, same Variable: jobstatus.Tour_TOD2_AMPeak.runsel Help: "Time-of-day 2 - AM Peak vehicle O&D trip tables" do
	enditem

	Text " " same, after, , 0.25
	Text "TOD2 Midday" 2.0, after, 26
	Checkbox " " after, same Variable: jobstatus.Tour_TOD2_Midday.runsel Help: "Time-of-day 2 - Midday vehicle O&D trip tables" do
	enditem

	Text " " same, after, , 0.25
	Text "TOD2 PMPeak" 2.0, after, 26
	Checkbox " " after, same Variable: jobstatus.Tour_TOD2_PMPeak.runsel Help: "Time-of-day 2 - PM Peak vehicle O&D trip tables" do
	enditem

	Text " " same, after, , 0.25
	Text "TOD2 Night" 2.0, after, 26
	Checkbox " " after, same Variable: jobstatus.Tour_TOD2_Night.runsel Help: "Time-of-day 2 - Night vehicle O&D trip tables" do
	enditem

	Text " " same, after, , 0.5
	Text "HIGHWAY ASSIGNMENT" 2.0, after
		
	Text " " same, after, , 0.25
	Text "Hwy Assn AM Peak" 2.0, after, 26
	Checkbox " " after, same Variable: jobstatus.HwyAssn_RunAMPeak.runsel Help: "Highway assignment - AM Peak" do
	enditem

	Text " " same, after, , 0.25
	Text "Hwy Assn Midday" 2.0, after, 26
	Checkbox " " after, same Variable: jobstatus.HwyAssn_RunMidday.runsel Help: "Highway assignment - Midday" do
	enditem

	Text " " same, after, , 0.25
	Text "Hwy Assn PMPeak" 2.0, after, 26
	Checkbox " " after, same Variable: jobstatus.HwyAssn_RunPMPeak.runsel Help: "Highway assignment - PM Peak" do
	enditem

	Text " " same, after, , 0.25
	Text "Hwy Assn Night" 2.0, after, 26
	Checkbox " " after, same Variable: jobstatus.HwyAssn_RunNight.runsel Help: "Highway assignment - Night" do
	enditem

	Text " " same, after, , 0.25
	Text "Feedback TravelTime" 2.0, after, 26
	Checkbox " " after, same Variable: jobstatus.Feedback_TravelTime.runsel Help: "Feedback AM HwyAssn travel time to peak minimum paths" do
	enditem

	Text " " same, after, , 0.25
	Text "TotAssn - Before HOT assign" 2.0, after, 26
	Checkbox " " after, same Variable: jobstatus.HwyAssn_RunTotAssn.runsel Help: "Aggregate pre-HOT AMPeak, Midday, PMPeak, Night highway assignments" do
	enditem

	Text " " same, after, , 0.5
	Text "HOT LANES HIGHWAY ASSIGNMENT" 2.0, after
		
	Text " " same, after, , 0.25
	Text "HOT HwyAssn AM Peak" 2.0, after, 26
	Checkbox " " after, same Variable: jobstatus.HwyAssn_RunHOTAMPeak.runsel Help: "HOT lanes highway assignment - AM Peak" do
	enditem

	Text " " same, after, , 0.25
	Text "HOT HwyAssn Midday" 2.0, after, 26
	Checkbox " " after, same Variable: jobstatus.HwyAssn_RunHOTMidday.runsel Help: "HOT lanes highway assignment - Midday" do
	enditem

	Text " " same, after, , 0.25
	Text "HOT HwyAssn PMPeak" 2.0, after, 26
	Checkbox " " after, same Variable: jobstatus.HwyAssn_RunHOTPMPeak.runsel Help: "HOT lanes highway assignment - PM Peak" do
	enditem

	Text " " same, after, , 0.25
	Text "HOT HwyAssn Night" 2.0, after, 26
	Checkbox " " after, same Variable: jobstatus.HwyAssn_RunHOTNight.runsel Help: "HOT lanes highway assignment - Night" do
	enditem

	Text " " same, after, , 0.25
	Text "TotAssn - Post HOT assign" 2.0, after, 26
	Checkbox " " after, same Variable: jobstatus.HwyAssn_RunHOTTotAssn.runsel Help: "Aggregate HOT AMPeak, Midday, PMPeak, Night highway assignments" do
	enditem

	Text " " same, after, , 0.25
	Text "VMT for Air Quality" 2.0, after, 26
	Checkbox " " after, same Variable: JobSel.VMTAQ Help: "Create VMT / VHT tables for air quality reporting" do
	enditem

	Text " " same, after, , 0.25
	Text "Highway Calibration stats" 2.0, after, 26
	Checkbox " " after, same Variable: JobSel.HighwayCalibrationStats_tour Help: "Build count to assigned volumes comparison sets (screenline, atfun, ...)" do
	enditem

	// column 2
	Text "TRANSIT ASSIGNMENT" 38.0, 3.5
	
	Text " " same, after, , 0.25
	Text "Transit_Input" 38.0, after, 26
	Checkbox " " after, same Variable: jobstatus.Transit_Input.runsel Help: "Prepare Mode Choice Transit trips for assigment" do
	enditem

	Text " " same, after, , 0.25
	Text "PPrmW Assign" 38.0, after, 26
	Checkbox " " after, same Variable: jobstatus.PPrmW_Assign.runsel Help: "Peak Premium Walk approach Transit assignment" do
	enditem

	Text " " same, after, , 0.25
	Text "PPrmD Assign" 38.0, after, 26
	Checkbox " " after, same Variable: jobstatus.PPrmD_Assign.runsel Help: "Peak Premium Drive approach Transit assignment" do
	enditem

	Text " " same, after, , 0.25
	Text "PPrmDrop Assign" 38.0, after, 26
	Checkbox " " after, same Variable: jobstatus.PPrmDrop_Assign.runsel Help: "Peak Premium Dropoff approach Transit assignment" do
	enditem

	Text " " same, after, , 0.25
	Text "PBusW Assign" 38.0, after, 26
	Checkbox " " after, same Variable: jobstatus.PBusW_Assign.runsel Help: "Peak Bus Walk approach Transit assignment" do
	enditem

	Text " " same, after, , 0.25
	Text "PBusD Assign" 38.0, after, 26
	Checkbox " " after, same Variable: jobstatus.PBusD_Assign.runsel Help: "Peak Bus Drive approach Transit assignment" do
	enditem

	Text " " same, after, , 0.25
	Text "PBusDrop Assign" 38.0, after, 26
	Checkbox " " after, same Variable: jobstatus.PBusDrop_Assign.runsel Help: "Peak Bus Dropoff approach Transit assignment" do
	enditem

	Text " " same, after, , 0.25
	Text "OPPrmW Assign" 38.0, after, 26
	Checkbox " " after, same Variable: jobstatus.OPPrmW_Assign.runsel Help: "OffPeak Premium Walk approach Transit assignment" do
	enditem

	Text " " same, after, , 0.25
	Text "OPPrmD Assign" 38.0, after, 26
	Checkbox " " after, same Variable: jobstatus.OPPrmD_Assign.runsel Help: "OffPeak Premium Drive approach Transit assignment" do
	enditem

	Text " " same, after, , 0.25
	Text "OPPrmDrop Assign" 38.0, after, 26
	Checkbox " " after, same Variable: jobstatus.OPPrmDrop_Assign.runsel Help: "OffPeak Premium Dropoff approach Transit assignment" do
	enditem

	Text " " same, after, , 0.25
	Text "OPBusW Assign" 38.0, after, 26
	Checkbox " " after, same Variable: jobstatus.OPBusW_Assign.runsel Help: "OffPeak Bus Walk approach Transit assignment" do
	enditem

	Text " " same, after, , 0.25
	Text "OPBusD Assign" 38.0, after, 26
	Checkbox " " after, same Variable: jobstatus.OPBusD_Assign.runsel Help: "OffPeak Bus Drive approach Transit assignment" do
	enditem

	Text " " same, after, , 0.25
	Text "OPBusDrop Assign" 38.0, after, 26
	Checkbox " " after, same Variable: jobstatus.OPBusDrop_Assign.runsel Help: "OffPeak Bus Dropoff approach Transit assignment" do
	enditem

	Text " " same, after, , 0.25
	Text "Transit Pax Stats" 38.0, after, 26
	Checkbox " " after, same Variable: JobSel.Transit_Pax_Stats Help: "Create transit \\RouteOut table" do
	enditem

	Text " " same, after, , 0.25
	Text "Transit Op Stats" 38.0, after, 26
	Checkbox " " after, same Variable: JobSel.Transit_Operations_Stats Help: "Create transit operations statistics tables" do
	enditem

/*	Text " " same, after, , 0.25
	Text "Transit Boardings" 38.0, after, 26
	Checkbox " " after, same Variable: JobSel.Transit_Boardings Help: "Route Ons/Offs by Stop (routes.dbf GRP_LIST = 1-4)" do
	enditem
*/
	Text " " same, after, , 0.25
	Text "Transit RunStats" 38.0, after, 26
	Checkbox " " after, same Variable: JobSel.Transit_RunStats Help: "Create download table for RunStats spreadsheet" do
	enditem

	Text " " same, after, , 1.0

enddbox
