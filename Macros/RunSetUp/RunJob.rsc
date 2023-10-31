Macro "RunJob" (Args, JobsToRun)

// Sept 19. 2016	Added run start to message box & log file
// 6/11/19, mk: This version is set up to create three distinct networks: AM peak, PM peak, and offpeak--change Args.[Hwy Name] to Args.[AM Peak Hwy Name]


//Macro to run a job
//  check pre-requisites first
//  returns array {[1]= 0 (bombed), 1 (non-feedback OK), 2 (feedback run ok), 9 (Kill run)  and [2] messages}

//	progressbarjobs = {"Build_Networks", "CapSpd", "HwySkim_Peak", "HwySkim_Free", 
//				"Reg_NonMotorized", 
//				"Reg_PPrmW", "Reg_PPrmD", "Reg_PPrmDrop", "Reg_PBusW", "Reg_PBusD", "Reg_PBusDrop", 
//				"Reg_OPPrmW", "Reg_OPPrmD", "Reg_OPPrmDrop", "Reg_OPBusW", "Reg_OPBusD", "Reg_OPBusDrop",
//				"Trip_Generation", "TDHBW1", "TDSCH",  "TDIEW", "TOD1_HBW_Peak", "TOD1_HBW_OffPeak", 
//				"MS_RunPeak", "TOD2_AMPeak", "HwyAssn_RunAMPeak", "Feedback_TravelTime", 	
//				"MS_RunOffPeak", "TOD2_PMPeak", "HwyAssn_RunPMPeak", "HwyAssn_RunMidday", "HwyAssn_RunNight", 
//				"Transit_Input", "PPrmW_Assign", "PPrmD_Assign", "PPrmDrop_Assign", "PBusW_Assign", "PBusD_Assign", "PBusDrop_Assign", 
//				"OPPrmW_Assign", "OPPrmD_Assign", "OPPrmDrop_Assign", "OPBusW_Assign", "OPBusD_Assign", "OPBusDrop_Assign", 
//				"HwyAssn_RunHOTAMPeak", "HwyAssn_RunHOTPMPeak", "HwyAssn_RunHOTMidday", "HwyAssn_RunHOTNight"}


	//JobReq - array of job requirements - input files (sometimes fields) / output files (sometimes fields)   
	// four potential fields - infiles, outfiles, infields, outfields
	// infiles - input files to check before running - do not need all, just a representative sample, fields checked if indentified in infields
	//  3 special files - LandUseFile, TAZFile, HwyFile - all from Args (or in case of hwy - built from Args)
	//  OTHER THAN TAZFile - all infiles MUST be in run directory (Dir) - e.g.  build_networks doesn't have infiles (all from MRM)		

	JobReq = {
		// first element in array indicates how far model has successfully run
		{"Build_Networks",		{{"outfiles",{"HwyFile"}}}},
								 
		{"Area_Type",			{{"infiles", {"LandUseFile"}},
							 {"outfiles", {"\\LandUse\\TAZ_AREATYPE.asc", "\\TAZ_ATYPE.asc"}},
							 {"outfields", {"ATYPE", "PARK_INF"}}}},
								 
		{"CapSpd",			{{"infiles", {"HwyFile", "\\LandUse\\TAZ_AREATYPE.asc"}},
							 {"outfiles", {"HwyFile"}}, 
							 {"outfields", {"TTPeakAB", "TTPeakBA"}}}}, 
								 
		{"RouteSystemSetUp",	{{"infiles", {"\\transys.rts"}},
							 {"outfiles", {"\\transysS.bin"}},
							 {"outfields", {"UserID"}}}}, 
								 
		{"HwySkim_Free",		{{"infiles", {"HwyFile", "\\LandUse\\TAZ_AREATYPE.asc"}},
							 {"infields", {"ImpFreeAB",}},
							 {"outfiles", {"\\Skims\\SPMAT_Free.mtx"}}}}, 
								 
		{"HwySkim_Peak",		{{"infiles", {"HwyFile", "\\LandUse\\TAZ_AREATYPE.asc"}},
							 {"infields", {"ImpPkAB",}},
							 {"outfiles", {"\\Skims\\SPMAT_Peak.mtx"}}}}, 

		{"FillParkCost",		{{"infiles", {"LandUseFile"}},
							 {"outfiles", {"\\AutoSkims\\parkingcost.mtx"}}}},
		 
		{"AutoSkims_Free",		{{"infiles",{"HwyFile", "\\skims\\SPMAT_Free.mtx"}},
							 {"outfiles", {"\\AutoSkims\\SPMAT_free.mtx"}},
							 {"outfields", {"Non HOV TTFree"}}}},
								  
		{"AutoSkims_Peak",		{{"infiles",{"HwyFile", "\\skims\\SPMAT_Peak.mtx"}}, 
							 {"outfiles", {"\\AutoSkims\\SPMAT_auto.mtx"}},
							 {"outfields", {"Non HOV TTPeak"}}}},
								 
		{"Reg_NonMotorized",	{{"outfiles", {"\\Skims\\TR_NonMotorized.mtx"}},
							 {"outfields", {"TTBike*"}}}},
		 
		{"Reg_PPrmW",			{{"infiles", {"HwyFile", "\\transys.rts", "\\AutoSkims\\SPMAT_Free.mtx"}},
							 {"outfiles", {"\\Skims\\PK_WKTRAN_SKIMS.mtx"}},
							 {"outfields", {"IVTT - Prem Walk"}}}},
								  
		{"Reg_PPrmD",			{{"infiles", {"HwyFile", "\\transys.rts", "\\AutoSkims\\SPMAT_Free.mtx"}},
							 {"outfiles", {"\\Skims\\PK_DRVTRAN_SKIMS.mtx"}},
							 {"outfields", {"IVTT - Prem Drive"}}}},
								  
		{"Reg_PPrmDrop",		{{"infiles", {"HwyFile", "\\transys.rts", "\\AutoSkims\\SPMAT_Free.mtx"}}, 
							 {"outfiles", {"\\Skims\\PK_DROPTRAN_SKIMS.mtx"}},
							 {"outfields", {"IVTT - Prem Dropoff"}}}},
								 
		{"Reg_PBusW",			{{"infiles", {"HwyFile", "\\transys.rts", "\\AutoSkims\\SPMAT_Free.mtx"}}, 
							 {"outfiles", {"\\Skims\\PK_WKTRAN_SKIMS.mtx"}},
							 {"outfields", {"IVTT - Prem Walk"}}}},
								 
		{"Reg_PBusD",			{{"infiles", {"HwyFile", "\\transys.rts", "\\AutoSkims\\SPMAT_Free.mtx"}}, 
							 {"outfiles", {"\\Skims\\PK_DRVTRAN_SKIMS.mtx"}},
							 {"outfields", {"IVTT - Bus Drive"}}}},
								 
		{"Reg_PBusDrop",		{{"infiles", {"HwyFile", "\\transys.rts", "\\AutoSkims\\SPMAT_Free.mtx"}}, 
							 {"outfiles", {"\\Skims\\PK_DROPTRAN_SKIMS.mtx"}},
							 {"outfields", {"IVTT - Bus Dropoff"}}}},
								 
		{"Reg_OPPrmW",			{{"infiles", {"HwyFile", "\\transys.rts", "\\AutoSkims\\SPMAT_Free.mtx"}}, 
							 {"outfiles", {"\\Skims\\OFFPK_WKTRAN_SKIMS.mtx"}},
							 {"outfields", {"IVTT - Prem Walk"}}}},
						 		 
		{"Reg_OPPrmD",			{{"infiles", {"HwyFile", "\\transys.rts", "\\AutoSkims\\SPMAT_Free.mtx"}}, 
							 {"outfiles", {"\\Skims\\OFFPK_DRVTRAN_SKIMS.mtx"}},
							 {"outfields", {"IVTT - Prem Drive"}}}},
								 
		{"Reg_OPPrmDrop",		{{"infiles", {"HwyFile", "\\transys.rts", "\\AutoSkims\\SPMAT_Free.mtx"}}, 
							 {"outfiles", {"\\Skims\\OFFPK_DROPTRAN_SKIMS.mtx"}},
							 {"outfields", {"IVTT - Prem Dropoff"}}}},
								 
		{"Reg_OPBusW",			{{"infiles", {"HwyFile", "\\transys.rts", "\\AutoSkims\\SPMAT_Free.mtx"}}, 
							 {"outfiles", {"\\Skims\\OFFPK_WKTRAN_SKIMS.mtx"}},
							 {"outfields", {"IVTT - Bus Walk"}}}},
								 
		{"Reg_OPBusD",			{{"infiles", {"HwyFile", "\\transys.rts", "\\AutoSkims\\SPMAT_Free.mtx"}}, 
							 {"outfiles", {"\\Skims\\OFFPK_DRVTRAN_SKIMS.mtx"}},
							 {"outfields", {"IVTT - Bus Drive"}}}},
								 
		{"Reg_OPBusDrop",		{{"infiles", {"HwyFile", "\\transys.rts", "\\AutoSkims\\SPMAT_Free.mtx"}}, 
							 {"outfiles", {"\\Skims\\OFFPK_DROPTRAN_SKIMS.mtx"}},
							 {"outfields", {"IVTT - Bus Dropoff"}}}},
								 
		{"ExtStaforTripGen",			{{"infiles", {"\\Skims\\SPMAT_Free.mtx"}},
							 {"outfiles", {"\\Ext\\Dist_to_Closest_ExtSta.asc", "\\LandUse\\Dist_to_CBD.asc"}}}},
								 
		{"Trip_Generation",		{{"infiles", {"LandUseFile", "\\Ext\\dist_to_closest_extsta.asc"}}, 
							 {"outfiles", {"\\TG\\productions.asc", "\\TG\\attractions.asc"}}}}, 
								 
		{"Aggregate_TripGen",	{{"infiles", {"\\TG\\productions.asc"}}}}, 

		{"EE_Trips",			{{"infiles", {"\\TG\\xxfactor.asc"}},
							 {"outfiles", {"\\TD\\TDeeA.mtx", "\\TD\\TDeeC.mtx", "\\TD\\TDeeM.mtx", "\\TD\\TDeeH.mtx"}},
							 {"outfields", {"Trips", "Trips", "Trips", "Trips"}}}}, 
								  
		{"TD_TranPath_Peak",	{{"infiles", {"\\Skims\\TR_SKIM_PPrmW.mtx"}}, 
							 {"outfiles", {"\\Skims\\TTTran_Peak.mtx"}},
							 {"outfields", {"TTTranPk"}}}}, 

		{"TD_TranPath_Free",	{{"infiles", {"\\Skims\\TR_SKIM_OPPrmW.mtx"}}, 
							 {"outfiles", {"\\Skims\\TTTran_Free.mtx"}},
							 {"outfields", {"TTTranFr"}}}}, 
								 
		{"TDHBW1",			{{"infiles", {"\\TG\\productions.asc", "\\Skims\\TThwy_Peak.mtx", "\\Skims\\TTTran_Peak.mtx"}},
							 {"outfiles", {"\\TD\\TDhbw1.mtx"}}, {"outfields", {"Trips"}}}}, 
								 
		{"TDHBW2",			{{"infiles", {"\\TG\\productions.asc", "\\Skims\\TThwy_Peak.mtx", "\\Skims\\TTTran_Peak.mtx"}},
							 {"outfiles", {"\\TD\\TDhbw2.mtx"}}, {"outfields", {"Trips"}}}}, 
								  
		{"TDHBW3",			{{"infiles", {"\\TG\\productions.asc", "\\Skims\\TThwy_Peak.mtx", "\\Skims\\TTTran_Peak.mtx"}},
							 {"outfiles", {"\\TD\\TDhbw3.mtx"}}, {"outfields", {"Trips"}}}}, 
								  
		{"TDHBW4",			{{"infiles", {"\\TG\\productions.asc", "\\Skims\\TThwy_Peak.mtx", "\\Skims\\TTTran_Peak.mtx"}}, 
							 {"outfiles", {"\\TD\\TDhbw4.mtx"}}, {"outfields", {"Trips"}}}}, 
								 
		{"TDHBS1",			{{"infiles", {"\\TG\\productions.asc", "\\Skims\\TThwy_Free.mtx", "\\Skims\\TTTran_Free.mtx"}},
							 {"outfiles", {"\\TD\\TDhbs1.mtx"}}, {"outfields", {"Trips"}}}}, 

		{"TDHBS2",			{{"infiles", {"\\TG\\productions.asc", "\\Skims\\TThwy_Free.mtx", "\\Skims\\TTTran_Free.mtx"}}, 
							 {"outfiles", {"\\TD\\TDhbs2.mtx"}}, {"outfields", {"Trips"}}}}, 
								 
		{"TDHBS3",			{{"infiles", {"\\TG\\productions.asc", "\\Skims\\TThwy_Free.mtx", "\\Skims\\TTTran_Free.mtx"}}, 
							 {"outfiles", {"\\TD\\TDhbs3.mtx"}}, {"outfields", {"Trips"}}}}, 
								 
		{"TDHBS4",			{{"infiles", {"\\TG\\productions.asc", "\\Skims\\TThwy_Free.mtx", "\\Skims\\TTTran_Free.mtx"}}, 
							 {"outfiles", {"\\TD\\TDhbs4.mtx"}}, {"outfields", {"Trips"}}}}, 
								 
		{"TDHBO1",			{{"infiles", {"\\TG\\productions.asc", "\\Skims\\TThwy_Free.mtx", "\\Skims\\TTTran_Free.mtx"}}, 
							 {"outfiles", {"\\TD\\TDhbo1.mtx"}}, {"outfields", {"Trips"}}}}, 
								 
		{"TDHBO2",			{{"infiles", {"\\TG\\productions.asc", "\\Skims\\TThwy_Free.mtx", "\\Skims\\TTTran_Free.mtx"}}, 
							 {"outfiles", {"\\TD\\TDhbo2.mtx"}}, {"outfields", {"Trips"}}}}, 
								 
		{"TDHBO3",			{{"infiles", {"\\TG\\productions.asc", "\\Skims\\TThwy_Free.mtx", "\\Skims\\TTTran_Free.mtx"}}, 
							 {"outfiles", {"\\TD\\TDhbo3.mtx"}}, {"outfields", {"Trips"}}}}, 
								 
		{"TDHBO4",			{{"infiles", {"\\TG\\productions.asc", "\\Skims\\TThwy_Free.mtx", "\\Skims\\TTTran_Free.mtx"}}, 
							 {"outfiles", {"\\TD\\TDhbo4.mtx"}}, {"outfields", {"Trips"}}}}, 
								 
		{"TDJTW", 			{{"infiles", {"\\TG\\productions.asc", "\\Skims\\TThwy_Peak.mtx", "\\Skims\\TTTran_Peak.mtx"}}, 
							 {"outfiles", {"\\TD\\TDjtw.mtx"}}, {"outfields", {"Trips"}}}}, 
								 
		{"TDATW", 			{{"infiles", {"\\TG\\productions.asc", "\\Skims\\TThwy_Free.mtx", "\\Skims\\TTTran_Free.mtx"}}, 
							 {"outfiles", {"\\TD\\TDatw.mtx"}}, {"outfields", {"Trips"}}}}, 
								 
		{"TDNWK",				{{"infiles", {"\\TG\\productions.asc", "\\Skims\\TThwy_Free.mtx", "\\Skims\\TTTran_Free.mtx"}}, 
							 {"outfiles", {"\\TD\\TDnwk.mtx"}}, {"outfields", {"Trips"}}}}, 
								 
		{"TDSCH",				{{"runsel", 0}, {"runstatus", 0}, {"datetime", }, 
							 {"infiles", {"\\TG\\productions.asc", "\\Skims\\TThwy_Free.mtx", "\\Skims\\TTTran_Free.mtx"}}, 
							 {"outfiles", {"\\TD\\TDsch.mtx"}}, {"outfields", {"Trips"}}}}, 
								 
		{"TDHBU",				{{"infiles", {"\\TG\\productions.asc", "\\Skims\\TThwy_Free.mtx", "\\Skims\\TTTran_Free.mtx"}}, 
							 {"outfiles", {"\\TD\\TDhbu.mtx"}}, {"outfields", {"Trips"}}}}, 
								 
		{"TDCOM",				{{"infiles", {"\\TG\\productions.asc", "\\Skims\\TThwy_Free.mtx", "\\Skims\\TTTran_Free.mtx"}}, 
							 {"outfiles", {"\\TD\\TDcom.mtx"}}, {"outfields", {"Trips"}}}}, 
								 
		{"TDMTK",				{{"infiles", {"\\TG\\productions.asc", "\\Skims\\TThwy_Free.mtx", "\\Skims\\TTTran_Free.mtx"}}, 
							 {"outfiles", {"\\TD\\TDmtk.mtx"}}, {"outfields", {"Trips"}}}}, 
								 
		{"TDHTK",				{{"infiles", {"\\TG\\productions.asc", "\\Skims\\TThwy_Free.mtx", "\\Skims\\TTTran_Free.mtx"}}, 
							 {"outfiles", {"\\TD\\TDhtk.mtx"}}, {"outfields", {"Trips"}}}}, 
								 
		{"TDEIW",				{{"infiles", {"\\TG\\productions.asc", "\\Skims\\TThwy_Peak.mtx", "\\Skims\\TTTran_Peak.mtx"}}, 
							 {"outfiles", {"\\TD\\TDeiw.mtx"}}, {"outfields", {"Trips"}}}}, 
								 
		{"TDEIN",				{{"infiles", {"\\TG\\productions.asc", "\\Skims\\TThwy_Free.mtx", "\\Skims\\TTTran_Free.mtx"}}, 
							 {"outfiles", {"\\TD\\TDein.mtx"}}, {"outfields", {"Trips"}}}}, 
								 
		{"TDEIC",				{{"infiles", {"\\TG\\productions.asc", "\\Skims\\TThwy_Free.mtx", "\\Skims\\TTTran_Free.mtx"}},
							 {"outfiles", {"\\TD\\TDeic.mtx"}}, {"outfields", {"Trips"}}}}, 
								  
		{"TDEIM",				{{"infiles", {"\\TG\\productions.asc", "\\Skims\\TThwy_Free.mtx", "\\Skims\\TTTran_Free.mtx"}}, 
							 {"outfiles", {"\\TD\\TDeim.mtx"}}, {"outfields", {"Trips"}}}}, 
								 
		{"TDEIH",				{{"infiles", {"\\TG\\productions.asc", "\\Skims\\TThwy_Free.mtx", "\\Skims\\TTTran_Free.mtx"}},
							 {"outfiles", {"\\TD\\TDeih.mtx"}}, {"outfields", {"Trips"}}}}, 
								  
		{"TDIEW",				{{"infiles", {"\\TG\\productions.asc", "\\Skims\\TThwy_Peak.mtx", "\\Skims\\TTTran_Peak.mtx"}}, 
							 {"outfiles", {"\\TD\\TDiew.mtx"}}, {"outfields", {"Trips"}}}}, 
								 
		{"TDIEN",				{{"infiles", {"\\TG\\productions.asc", "\\Skims\\TThwy_Free.mtx", "\\Skims\\TTTran_Free.mtx"}},
							 {"outfiles", {"\\TD\\TDien.mtx"}}, {"outfields", {"Trips"}}}}, 
								  
		{"TDIEC",				{{"infiles", {"\\TG\\productions.asc", "\\Skims\\TThwy_Free.mtx", "\\Skims\\TTTran_Free.mtx"}}, 
							 {"outfiles", {"\\TD\\TDiec.mtx"}}, {"outfields", {"Trips"}}}}, 

		{"TDIEM",				{{"infiles", {"\\TG\\productions.asc", "\\Skims\\TThwy_Free.mtx", "\\Skims\\TTTran_Free.mtx"}}, 
							 {"outfiles", {"\\TD\\TDiem.mtx"}}, {"outfields", {"Trips"}}}}, 
								 
		{"TDIEH",				{{"infiles", {"\\TG\\productions.asc", "\\Skims\\TThwy_Free.mtx", "\\Skims\\TTTran_Free.mtx"}}, 
							 {"outfiles", {"\\TD\\TDieh.mtx"}}, {"outfields", {"Trips"}}}}, 

		{"TOD1_HBW_Peak",		{{"infiles", {"\\TD\\TDhbw1.mtx", "\\TD\\TDhbw2.mtx", "\\TD\\TDhbw3.mtx", "\\TD\\TDhbw4.mtx"}},
							 {"outfiles", {"\\TripTables\\HBW_Peak_Trips.mtx"}}, {"outfields", {"Income1"}}}}, 
								 
		{"TOD1_HBO_Peak",		{{"infiles", {"\\TD\\TDhbs1.mtx", "\\TD\\TDhbs2.mtx", "\\TD\\TDhbs3.mtx", "\\TD\\TDhbs4.mtx", 
							 		    "\\TD\\TDhbo1.mtx", "\\TD\\TDhbo2.mtx", "\\TD\\TDhbo3.mtx", "\\TD\\TDhbo4.mtx"}}, 
							 {"outfiles", {"\\TripTables\\HBO_Peak_Trips.mtx"}}, {"outfields", {"Income1"}}}}, 
											  
		{"TOD1_NHB_Peak",		{{"infiles", {"\\TD\\TDjtw.mtx", "\\TD\\TDatw.mtx", "\\TD\\TDnwk.mtx"}}, 
							 {"outfiles", {"\\TripTables\\NHB_Peak_Trips.mtx"}}, {"outfields", {"NHB_Peak"}}}}, 
								 
		{"TOD1_HBU_Peak",		{{"infiles", {"\\TD\\TDhbu.mtx"}}, 
							 {"outfiles", {"\\TripTables\\HBU_Peak_Trips.mtx"}}, {"outfields", {"HBU_Peak"}}}}, 
								 
		{"TOD1_HBW_OffPeak",	{{"infiles", {"\\TD\\TDhbw1.mtx", "\\TD\\TDhbw2.mtx", "\\TD\\TDhbw3.mtx", "\\TD\\TDhbw4.mtx"}}, 
							 {"outfiles", {"\\TripTables\\HBW_OffPeak_Trips.mtx"}}, {"outfields", {"Income1"}}}}, 
								 
		{"TOD1_HBO_OffPeak",	{{"infiles", {"\\TD\\TDhbs1.mtx", "\\TD\\TDhbs2.mtx", "\\TD\\TDhbs3.mtx", "\\TD\\TDhbs4.mtx", 
									    "\\TD\\TDhbo1.mtx", "\\TD\\TDhbo2.mtx", "\\TD\\TDhbo3.mtx", "\\TD\\TDhbo4.mtx"}}, 
							 {"outfiles", {"\\TripTables\\HBO_OffPeak_Trips.mtx"}}, {"outfields", {"Income1"}}}}, 
											  
		{"TOD1_NHB_OffPeak",	{{"infiles", {"\\TD\\TDjtw.mtx", "\\TD\\TDatw.mtx", "\\TD\\TDnwk.mtx"}}, 
							 {"outfiles", {"\\TripTables\\NHB_OffPeak_Trips.mtx"}}, {"outfields", {"NHB_OffPeak"}}}}, 
								 
		{"TOD1_HBU_OffPeak",	{{"infiles", {"\\TD\\TDhbu.mtx"}}, 
							 {"outfiles", {"\\TripTables\\HBU_OffPeak_Trips.mtx"}}, {"outfields", {"HBU_OffPeak"}}}}, 

		{"MS_RunPeak",			{{"infiles", {"\\AutoSkims\\SPMAT_AUTO.mtx", 
							              "\\Skims\\TR_NONMOTORIZED.mtx", "\\Skims\\PK_WKTRAN_SKIMS.mtx",
									    "\\Skims\\PK_DRVTRAN_SKIMS.mtx", "\\Skims\\PK_DROPTRAN_SKIMS.mtx", 
								 	    "\\TripTables\\HBW_PEAK_TRIPS.MTX", "\\TripTables\\HBO_PEAK_TRIPS.MTX",
								 	    "\\TripTables\\NHB_PEAK_TRIPS.MTX","\\TripTables\\HBU_PEAK_TRIPS.MTX"}},
							 {"infields", {,,"IVTT - Prem Walk", "IVTT - Prem Drive", "IVTT - Prem Dropoff",,,,}},
							 {"outfiles", {"\\ModeSplit\\HBW_PEAK_MS.mtx", "\\ModeSplit\\HBO_PEAK_MS.mtx", 
										"\\ModeSplit\\NHB_PEAK_MS.mtx", "\\ModeSplit\\HBU_PEAK_MS.mtx"}},
							 {"outfields", {"Drive Alone", "Drive Alone", "Drive Alone", "Drive Alone"}}}},
								 			   
		{"MS_RunOffPeak",		{{"infiles", {"\\AutoSkims\\SPMAT_FREE.mtx", "\\Skims\\TR_NONMOTORIZED.mtx", 
									    "\\Skims\\OFFPK_WKTRAN_SKIMS.mtx",
									    "\\Skims\\OFFPK_DRVTRAN_SKIMS.mtx", "\\Skims\\OFFPK_DROPTRAN_SKIMS.mtx", 
									    "\\TripTables\\HBW_OFFPEAK_TRIPS.MTX", "\\TripTables\\HBO_OFFPEAK_TRIPS.MTX",
								 	    "\\TripTables\\NHB_OFFPEAK_TRIPS.MTX", "\\TripTables\\HBU_OFFPEAK_TRIPS.MTX"}}, 
							 {"infields", {,,"IVTT - Prem Walk", "IVTT - Prem Drive", "IVTT - Prem Dropoff",,,,}},
							 {"outfiles", {"\\ModeSplit\\HBW_OFFPEAK_MS.mtx", "\\ModeSplit\\HBO_OFFPEAK_MS.mtx", 
										"\\ModeSplit\\NHB_OFFPEAK_MS.mtx", "\\ModeSplit\\HBU_OFFPEAK_MS.mtx"}},
							 {"outfields", {"Drive Alone", "Drive Alone", "Drive Alone", "Drive Alone"}}}},

		{"MS_HBWPeak",			{{"infiles", {"\\AutoSkims\\SPMAT_AUTO.mtx", 
							              "\\Skims\\TR_NONMOTORIZED.mtx", "\\Skims\\PK_WKTRAN_SKIMS.mtx",
									    "\\Skims\\PK_DRVTRAN_SKIMS.mtx", "\\Skims\\PK_DROPTRAN_SKIMS.mtx", 
								 	    "\\TripTables\\HBW_PEAK_TRIPS.MTX"}},
							  {"infields", {,,"IVTT - Prem Walk", "IVTT - Prem Drive", "IVTT - Prem Dropoff",,,,}},
							  {"outfiles", {"\\ModeSplit\\HBW_PEAK_MS.mtx"}}, {"outfields", {"Drive Alone"}}}},
								 			   
		{"MS_HBWOffPeak",		{{"infiles", {"\\AutoSkims\\SPMAT_FREE.mtx", "\\Skims\\TR_NONMOTORIZED.mtx", 
							 	  	    "\\Skims\\OFFPK_WKTRAN_SKIMS.mtx",
									    "\\Skims\\OFFPK_DRVTRAN_SKIMS.mtx", "\\Skims\\OFFPK_DROPTRAN_SKIMS.mtx", 
									    "\\TripTables\\HBW_OFFPEAK_TRIPS.MTX"}}, 
							 {"infields", {,,"IVTT - Prem Walk", "IVTT - Prem Drive", "IVTT - Prem Dropoff",,,,}},
							 {"outfiles", {"\\ModeSplit\\HBW_OFFPEAK_MS.mtx"}}, {"outfields", {"Drive Alone"}}}},
								   
		{"MS_HBOPeak",			{{"infiles", {"\\AutoSkims\\SPMAT_AUTO.mtx", 
							              "\\Skims\\TR_NONMOTORIZED.mtx", "\\Skims\\PK_WKTRAN_SKIMS.mtx",
									    "\\Skims\\PK_DRVTRAN_SKIMS.mtx", "\\Skims\\PK_DROPTRAN_SKIMS.mtx", 
								 	    "\\TripTables\\HBO_PEAK_TRIPS.MTX"}},
							 {"infields", {,,"IVTT - Prem Walk", "IVTT - Prem Drive", "IVTT - Prem Dropoff",,,,}},
							 {"outfiles", {"\\ModeSplit\\HBO_PEAK_MS.mtx"}}, {"outfields", {"Drive Alone"}}}},
								 			   
		{"MS_HBOOffPeak",		{{"infiles", {"\\AutoSkims\\SPMAT_FREE.mtx", "\\Skims\\TR_NONMOTORIZED.mtx", 
									    "\\Skims\\OFFPK_WKTRAN_SKIMS.mtx",
									    "\\Skims\\OFFPK_DRVTRAN_SKIMS.mtx", "\\Skims\\OFFPK_DROPTRAN_SKIMS.mtx", 
									    "\\TripTables\\HBO_OFFPEAK_TRIPS.MTX"}}, 
							 {"infields", {,,"IVTT - Prem Walk", "IVTT - Prem Drive", "IVTT - Prem Dropoff",,,,}},
							 {"outfiles", {"\\ModeSplit\\HBO_OFFPEAK_MS.mtx"}}, {"outfields", {"Drive Alone"}}}},
								   
		{"MS_NHBPeak",			{{"infiles", {"\\AutoSkims\\SPMAT_AUTO.mtx", 
							              "\\Skims\\TR_NONMOTORIZED.mtx", "\\Skims\\PK_WKTRAN_SKIMS.mtx",
									    "\\Skims\\PK_DRVTRAN_SKIMS.mtx", "\\Skims\\PK_DROPTRAN_SKIMS.mtx", 
								 	    "\\TripTables\\NHB_PEAK_TRIPS.MTX"}},
							 {"infields", {,,"IVTT - Prem Walk", "IVTT - Prem Drive", "IVTT - Prem Dropoff",,,,}},
							 {"outfiles", {"\\ModeSplit\\NHB_PEAK_MS.mtx"}}, {"outfields", {"Drive Alone"}}}},
								 			   
		{"MS_NHBOffPeak",		{{"infiles", {"\\AutoSkims\\SPMAT_FREE.mtx", "\\Skims\\TR_NONMOTORIZED.mtx", 
									    "\\Skims\\OFFPK_WKTRAN_SKIMS.mtx",
									    "\\Skims\\OFFPK_DRVTRAN_SKIMS.mtx", "\\Skims\\OFFPK_DROPTRAN_SKIMS.mtx", 
									    "\\TripTables\\NHB_OFFPEAK_TRIPS.MTX"}}, 
							 {"infields", {,,"IVTT - Prem Walk", "IVTT - Prem Drive", "IVTT - Prem Dropoff",,,,}},
							 {"outfiles", {"\\ModeSplit\\NHB_OFFPEAK_MS.mtx"}}, {"outfields", {"Drive Alone"}}}},
								   
		{"MS_HBUPeak",			{{"infiles", {"\\AutoSkims\\SPMAT_AUTO.mtx", 
							              "\\Skims\\TR_NONMOTORIZED.mtx", "\\Skims\\PK_WKTRAN_SKIMS.mtx",
									    "\\Skims\\PK_DRVTRAN_SKIMS.mtx", "\\Skims\\PK_DROPTRAN_SKIMS.mtx", 
								 	    "\\TripTables\\HBU_PEAK_TRIPS.MTX"}},
							 {"infields", {,,"IVTT - Prem Walk", "IVTT - Prem Drive", "IVTT - Prem Dropoff",,,,}},
							 {"outfiles", {"\\ModeSplit\\HBU_PEAK_MS.mtx"}}, {"outfields", {"Drive Alone"}}}},
								 			   
		{"MS_HBUOffPeak",		{{"infiles", {"\\AutoSkims\\SPMAT_FREE.mtx", "\\Skims\\TR_NONMOTORIZED.mtx", 
									    "\\Skims\\OFFPK_WKTRAN_SKIMS.mtx",
									    "\\Skims\\OFFPK_DRVTRAN_SKIMS.mtx", "\\Skims\\OFFPK_DROPTRAN_SKIMS.mtx", 
									    "\\TripTables\\HBU_OFFPEAK_TRIPS.MTX"}}, 
							 {"infields", {,,"IVTT - Prem Walk", "IVTT - Prem Drive", "IVTT - Prem Dropoff",,,,}},
							 {"outfiles", {"\\ModeSplit\\HBU_OFFPEAK_MS.mtx"}}, {"outfields", {"Drive Alone"}}}},

		{"TOD2_COM_MTK_HTK",	{{"infiles", {"\\TD\\tdcom.mtx", "\\TD\\tdeic.mtx", "\\TD\\tdiec.mtx", "\\TD\\tdmtk.mtx",
									    "\\TD\\tdeim.mtx", "\\TD\\tdiem.mtx", "\\TD\\tdhtk.mtx", "\\TD\\tdeih.mtx", "\\TD\\tdieh.mtx"}},
							 {"outfiles", {"\\tod2\\ToTranspose.mtx"}}, {"outfields", {"TransposeCOM"}}}},

		{"TOD2_AMPeak",		{{"infiles", {"\\ModeSplit\\HBW_PEAK_MS.mtx", "\\ModeSplit\\HBO_PEAK_MS.mtx", 
									    "\\ModeSplit\\NHB_PEAK_MS.mtx", "\\ModeSplit\\HBU_PEAK_MS.mtx", 
									    "\\td\\tdSCH.mtx", "\\td\\tdeiw.mtx", "\\td\\tdiew.mtx", "\\td\\tdein.mtx","\\td\\tdien.mtx"}},
							 {"infields", {"Drive Alone", "Drive Alone", "Drive Alone", "Drive Alone",,,,,}},
							 {"outfiles", {"\\tod2\\ODHwyVeh_AMPeak.mtx"}}, {"outfields", {"SOV"}}}},

		{"TOD2_PMPeak",		{{"infiles", {"\\ModeSplit\\HBW_PEAK_MS.mtx", "\\ModeSplit\\HBO_PEAK_MS.mtx", 
									    "\\ModeSplit\\NHB_PEAK_MS.mtx", "\\ModeSplit\\HBU_PEAK_MS.mtx", 
									    "\\td\\tdSCH.mtx", "\\td\\tdeiw.mtx", "\\td\\tdiew.mtx", "\\td\\tdein.mtx","\\td\\tdien.mtx"}},
							 {"infields", {"Drive Alone", "Drive Alone", "Drive Alone", "Drive Alone",,,,,}},
							 {"outfiles", {"\\tod2\\ODHwyVeh_PMPeak.mtx"}}, {"outfields", {"SOV"}}}},
 
		{"TOD2_Midday",		{{"infiles", {"\\ModeSplit\\HBW_OFFPEAK_MS.mtx", "\\ModeSplit\\HBO_OFFPEAK_MS.mtx", 
									    "\\ModeSplit\\NHB_OFFPEAK_MS.mtx", "\\ModeSplit\\HBU_OFFPEAK_MS.mtx", 
									    "\\td\\tdSCH.mtx", "\\td\\tdeiw.mtx", "\\td\\tdiew.mtx", "\\td\\tdein.mtx","\\td\\tdien.mtx"}},
							 {"infields", {"Drive Alone", "Drive Alone", "Drive Alone", "Drive Alone",,,,,}},
							 {"outfiles", {"\\tod2\\ODHwyVeh_Midday.mtx"}}, {"outfields", {"SOV"}}}},

		{"TOD2_Night",			{{"infiles", {"\\ModeSplit\\HBW_OFFPEAK_MS.mtx", "\\ModeSplit\\HBO_OFFPEAK_MS.mtx", 
									    "\\ModeSplit\\NHB_OFFPEAK_MS.mtx", "\\ModeSplit\\HBU_OFFPEAK_MS.mtx", 
									    "\\td\\tdSCH.mtx", "\\td\\tdeiw.mtx", "\\td\\tdiew.mtx",
									    "\\td\\tdein.mtx","\\td\\tdien.mtx"}},
							 {"infields", {"Drive Alone", "Drive Alone", "Drive Alone", "Drive Alone",,,,,}},
							 {"outfiles", {"\\tod2\\ODHwyVeh_Night.mtx"}}, {"outfields", {"SOV"}}}},

		{"HwyAssn_RunAMPeak",	{{"infiles", {"\\tod2\\ODHwyVeh_AMPeak.mtx"}}, {"infields", {,"SOV"}}}}, 

		{"HwyAssn_RunPMPeak",	{{"infiles", {"\\tod2\\ODHwyVeh_PMPeak.mtx"}}, {"infields", {,"SOV"}}}}, 

		{"HwyAssn_RunMidday",	{{"infiles", {"\\tod2\\ODHwyVeh_Midday.mtx"}}, {"infields", {,"SOV"}}}}, 

		{"HwyAssn_RunNight",	{{"infiles", {"\\tod2\\ODHwyVeh_Night.mtx"}}, {"infields", {,"SOV"}}}}, 

		{"Feedback_TravelTime",	{{"infiles", {"HwyFile"}}}}, 

		{"HwyAssn_RunTotAssn",	{{"infiles", {"\\HwyAssn\\Assn_AMPeak.bin", "\\HwyAssn\\Assn_PMPeak.bin",
									    "\\HwyAssn\\Assn_Midday.bin","\\HwyAssn\\Assn_Night.bin"}}}}, 

		{"Transit_Input",		{{"infiles", {"\\ModeSplit\\HBW_PEAK_MS.mtx", "\\ModeSplit\\HBO_PEAK_MS.mtx", 
								 	    "\\ModeSplit\\NHB_PEAK_MS.mtx", "\\ModeSplit\\HBU_PEAK_MS.mtx"}},
							 {"infields", {"Wk-Bus", "Wk-Bus", "Wk-Bus", "Wk-Bus"}},
							 {"outfiles", {"\\TranAssn\\Transit Assign Walk.mtx","\\TranAssn\\Transit Assign Drive.mtx",
								 		"\\TranAssn\\Transit Assign Dropoff.mtx"}}, 
							 {"outfields", {"PBusW","PBusD","PBusDropOff"}}}},

		{"Market_Segment",		{{"infiles", {"\\TAZ_ATYPE.asc"}}}}, 

		{"PPrmW_Assign",		{{"infiles", {"\\TranAssn\\Transit Assign Walk.mtx"}}}},
								  
		{"PPrmD_Assign",		{{"infiles", {"\\TranAssn\\Transit Assign Drive.mtx"}}}},
								  
		{"PPrmDrop_Assign",		{{"infiles", {"\\TranAssn\\Transit Assign Dropoff.mtx"}}}},
								  
		{"OPPrmW_Assign",		{{"infiles", {"\\TranAssn\\Transit Assign Walk.mtx"}}}},
								  
		{"OPPrmD_Assign",		{{"infiles", {"\\TranAssn\\Transit Assign Drive.mtx"}}}},
								  
		{"OPPrmDrop_Assign",	{{"infiles", {"\\TranAssn\\Transit Assign Dropoff.mtx"}}}},
								  
		{"PBusW_Assign",		{{"infiles", {"\\TranAssn\\Transit Assign Walk.mtx"}}}},
								  
		{"PBusD_Assign",		{{"infiles", {"\\TranAssn\\Transit Assign Drive.mtx"}}}},
								  
		{"PBusDrop_Assign",		{{"infiles", {"\\TranAssn\\Transit Assign Dropoff.mtx"}}}},
								  
		{"OPBusW_Assign",		{{"infiles", {"\\TranAssn\\Transit Assign Walk.mtx"}}}},
								  
		{"OPBusD_Assign",		{{"infiles", {"\\TranAssn\\Transit Assign Drive.mtx"}}}},
								  
		{"OPBusDrop_Assign",	{{"infiles", {"\\TranAssn\\Transit Assign Dropoff.mtx"}}}},
								  
		{"HwyAssn_RunHOTAMPeak", {{"infiles", {"HwyFile", "\\HwyAssn\\HOT\\assn_template.dcb", 
									    "\\TOD2\\ODHwyVeh_AMPeak.mtx", "\\HwyAssn\\Assn_AMPeak.bin"}}}}, 

		{"HwyAssn_RunHOTPMPeak", {{"infiles", {"HwyFile", "\\HwyAssn\\HOT\\assn_template.dcb", 
									    "\\TOD2\\ODHwyVeh_PMPeak.mtx", "\\HwyAssn\\Assn_PMPeak.bin"}}}}, 
											  
		{"HwyAssn_RunHOTMidday", {{"infiles", {"HwyFile", "\\HwyAssn\\HOT\\assn_template.dcb", 
									    "\\TOD2\\ODHwyVeh_Midday.mtx", "\\HwyAssn\\Assn_Midday.bin"}}}},
											   
		{"HwyAssn_RunHOTNight",	{{"infiles", {"HwyFile", "\\HwyAssn\\HOT\\assn_template.dcb", 
									    "\\TOD2\\ODHwyVeh_Night.mtx", "\\HwyAssn\\Assn_Night.bin"}}}}, 

		{"HwyAssn_RunHOTTotAssn",{{"infiles", {"HwyFile", "\\HwyAssn\\HOT\\Assn_AMPeakhot.bin", "\\HwyAssn\\HOT\\Assn_PMPeakhot.bin",
							 		    "\\HwyAssn\\HOT\\Assn_Middayhot.bin","\\HwyAssn\\HOT\\Assn_Nighthot.bin"}}}}, 

		{"RunStats_HwyAssnHOT",	{{"infiles", {"HwyFile", "\\HwyAssn\\HOT\\TOT_ASSN_HOT.dbf","\\skims\\SPMAT_peak_hov.mtx",
							 			  "\\skims\\SPMAT_peak_hov.mtx"}}}}
								  
	    }

	Dir = Args.[Run Directory].value
	LogFile = Args.[Log File].value
	SetLogFileName(LogFile)
	msg = null

	EnableProgressBar("Metrolina Regional Model", 2)	// Double progress bar
	CreateProgressBar("Running...", "True")

	// Loop through all jobs selected
	
	datentime = GetDateandTime()
	if JobsToRun.length > 0 
		then Job1 = JobsToRun[1]
		else Job1 = null 
	msg = msg + {"Run MRM Trips, Job 1= " + Job1 + ", " + datentime}
	AppendToLogFile(1, "Run MRM Trips, Job 1= " + Job1 + ", " + datentime)

	for i = 1 to JobsToRun.length do

		job = JobsToRun[i]

		realk = (i / JobsToRun.length) * 100
		k = r2i(realk)
		stat = UpdateProgressBar("Running job : " + job,k)
		if stat = "True" then do
			ShowMessage("You Quit!")
			goto killjob
		end

		// pull job info from Args.job status array
		jobinfiles = JobReq.(job).infiles
		jobinfields = JobReq.(job).infields

		PreRunStatus = 1
	
		SetStatus(2, "MRM job " + job + " running",)

		// check input files and sometimes specific fields or matrix cores	
		if jobinfiles = null then goto skipinfiles 
		for j = 1 to jobinfiles.length do
			infile = jobinfiles[j]

			// special names - hwyfile, taz or landuse file - can change by run, otherwise Dir + infile
			if upper(infile) = "HWYFILE" 
				then infile = Dir + "\\" + Args.[AM Peak Hwy Name].value + ".dcb"
			else if upper(infile) = "TAZFILE"
				then infile = Args.[TAZ File].value
			else if upper(infile) = "LANDUSEFILE"
				then infile = Args.[LandUse File].value			

			else infile = Dir + infile
								
			exist = GetFileInfo(infile)
			if exist = null
				then do 
					msg = msg + {"RunJob: " + job + " input file missing: " + infile}
					AppendToLogFile(1, "RunJob: " + job + " input file missing: " + infile)
					PreRunStatus = 0
				end
			// if field required - get it	
			if jobinfields <> null 
				then do 
					fieldname = jobinfields[j]
					rtn = RunMacro("GetFieldCore", infile, fieldname)
				fieldok = rtn[1]
				if fieldok = 0 
					then do
						msg = msg + {"RunJob: " + job + ", Error in GetFieldCore infile/infield" + infile + "/" + fieldname + ", " + rtn[2]}
						AppendToLogFile(1, "RunJob: " + job + ", Error in GetFieldCore infile/infield" + infile + "/" + fieldname + ", " + rtn[2])
						PreRunStatus = 0
					end
			end // infields <> null
		end	// for j (infiles)

		skipinfiles:
		if PreRunStatus = 0 
			then do
				msg = msg + {"RunJob: " + job + " Run input files bad, job not run"}
				AppendToLogFile(1, "RunJob: " + job + " Run input files bad, job not run")
				goto killjob
			end
			
		// run job
		runreturn = RunMacro(job, Args)
		RunStatus = runreturn[1]
		msg = msg + runreturn[2]
	
		// fill run status array 
		if RunStatus = 0
			then goto killjob

		// check outfiles/fields if necessary 
		PostRunStatus = 1 
		joboutfiles = JobReq.(job).outfiles
		joboutfields = JobReq.(job).outfields

		if joboutfiles = null then goto skipoutfiles 
		for j = 1 to joboutfiles.length do
			outfile = joboutfiles[j]

			// special names - hwyfile, taz or landuse file - can change by run, otherwise Dir + outfile
			if upper(outfile) = "HWYFILE" 
				then outfile = Dir + "\\" + Args.[AM Peak Hwy Name].value + ".dcb"
			else if upper(outfile) = "TAZFILE"
				then outfile = Args.[TAZ File].value
			else if upper(outfile) = "LANDUSEFILE"
				then outfile = Args.[LandUse File].value			
			else outfile = Dir + outfile
								
			exist = GetFileInfo(outfile)
			if exist = null
				then do 
					msg = msg + {"RunJob: " + job + " output file missing: " + outfile}
					AppendToLogFile(1, "RunJob: " + job + " output file missing: " + outfile)
					PostRunStatus = 0
					goto skipoutfieldcheck
				end

			// if field required - get it	
			if joboutfields <> null 
				then do 
					fieldname = joboutfields[j]

					rtn = RunMacro("GetFieldCore", outfile, fieldname)
					fieldok = rtn[1]
					if fieldok = 0 
						then do
							msg = msg + {"RunJob: " + job + ", Error in GetFieldCore outfile/outfield" + outfile + "/" + fieldname + ", " + rtn[2]}
							AppendToLogFile(1, "RunJob: " + job + ", Error in GetFieldCore outfile/outfield" + outfile + "/" + fieldname + ", " + rtn[2])
							PostRunStatus = 0
						end
				end // outfields <> null

			skipoutfieldcheck:
			if PostRunStatus = 0 
				then do
					msg = msg + {"RunJob: " + job + " Run output files bad"}
					AppendToLogFile(1, "RunJob: " + job + " Run output files bad")
					goto killjob
				end

		end	// for j (outfiles)

		skipoutfiles:
			
		getnext:
		jobinfiles = null
		jobinfields = null
		joboutfiles = null
		joboutfields = null
		SetStatus(2, "@system0",)
	end // for i (JobsToRun)		

	JobsToRun = null
	DestroyProgressBar()
	DisableProgressBar()
	return({1, msg})			
			
	killjob:
	msg = msg + {"RunJob: " + job + " RUN KILLED"}
	AppendToLogFile(1, "RunJob: " + job + " RUN KILLED")
//	SaveArray(Args, Dir + "\\Arguments.args")
	JobsToRun = null
	SetStatus(2, "@system0",)
	DestroyProgressBar()
	DisableProgressBar()
	return({9, msg})		
EndMacro