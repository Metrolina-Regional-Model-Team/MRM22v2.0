macro "MSMatrixStats" (Args)

	LogFile = Args.[Log File].value
	SetLogFileName(LogFile)

	Dir = Args.[Run Directory].value
	msg = null
	MSStatsOK = 1

	DirReport  = Dir + "\\Report"
	RunMacro("TCB Init")

	datentime = GetDateandTime()
	AppendToLogFile(1, "Enter MSMatrixStats: " + datentime)

	MatArray = {"HBW_Peak_MS.mtx",
		    "HBW_Offpeak_MS.mtx",
		    "HBO_Peak_MS.mtx",
		    "HBO_Offpeak_MS.mtx",
		    "NHB_Peak_MS.mtx",
		    "NHB_Offpeak_MS.mtx",
		    "HBU_Peak_MS.mtx",
		    "HBU_Offpeak_MS.mtx"}
	MatCode = {"HBW Peak   ",
		   "HBW Offpeak",
		   "HBO Peak   ",
		   "HBO Offpeak",
		   "NHB Peak   ",
		   "NHB Offpeak",
		   "HBU Peak   ",
		   "HBU Offpeak"}


	MS_Statistics = CreateTable("MS_Statistics", DirReport + "\\MS_Statistics.bin", "FFB", {{"Purpose_TOD", "String", 16, , "No"}, {"Mode", "String", 8, , "No"}, {"Trips", "Real", 10, 2, "No"}, {"IntraTrips", "Real", 10, 2, "No"}}) 

	for mcnt = 1 to MatArray.length do

		hit = GetFileInfo(Dir + "\\ModeSplit\\" + MatArray[mcnt])
		if hit = null then goto badmat

		M = OpenMatrix(Dir + "\\ModeSplit\\" + MatArray[mcnt],)
		StatArray = MatrixStatistics(M,)
		for j = 1 to StatArray.length do
			Mode = StatArray[j][1]
			Trips = r2s(StatArray[j][2][2][2])
			IntraTrips = r2s(StatArray[j][2][7][2])
			
			rh = AddRecord("MS_Statistics", {{"Purpose_TOD",MatCode[mcnt]}, {"Mode",Mode}, {"Trips",Trips}, {"IntraTrips",IntraTrips}})
		end
	end
	
	MS_Statistics_tab1 = ExportView("MS_Statistics|", "CSV", DirReport + "\\MS_Statistics.csv",{"Purpose_TOD", "Mode", "Trips", "IntraTrips"}, { {"CSV Header", "True"} } )
	
	RunMacro("G30 File Close All")
	goto quit
		
	badmat: 
	msg = msg + {"MSMatrixStats:  Error - matrix " + MatArray[mcnt] + " not found"}
	AppendToLogFile(1, "MSMatrixStats:  Error - matrix " + MatArray[mcnt] + " not found")
	MSStatsOK = 0
	goto quit 
	
	quit: 
	datentime = GetDateandTime()
	AppendToLogFile(1, "Exit MSMatrixStats: " + datentime)
	return({MSStatsOK, msg})

endmacro