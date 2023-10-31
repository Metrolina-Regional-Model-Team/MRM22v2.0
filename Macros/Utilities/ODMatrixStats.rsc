macro "ODMatrixStats" (Args)

	LogFile = Args.[Log File].value
	SetLogFileName(LogFile)

	Dir = Args.[Run Directory].value
	msg = null
	ODStatsOK = 1

	DirReport  = Dir + "\\Report"
	RunMacro("TCB Init")

	datentime = GetDateandTime()
	AppendToLogFile(1, "Enter ODMatrixStats: " + datentime)


	MatArray = {"ODHwyVeh_AMPeakhot.mtx",
		    "ODHwyVeh_PMPeakhot.mtx",
		    "ODHwyVeh_Middayhot.mtx",
		    "ODHwyVeh_Nighthot.mtx"}
	MatCode = {"AM Peak",
		   "PM Peak",
		   "Midday ",
		   "Night  "}


/*	StatOutName = Dir + "\\Report\\OD_Statistics.csv"
  	exist = GetFileInfo(StatOutName)
  	if (exist <> null) then DeleteFile(StatOutName)
 */ 

	OD_Statistics = CreateTable("OD_Statistics", DirReport + "\\OD_Statistics.bin", "FFB", {{"TOD", "String", 7, , "No"}, {"Mode", "String", 8, , "No"}, {"Trips", "Real", 10, 2, "No"}, {"IntraTrips", "Real", 10, 2, "No"}}) 

	for mcnt = 1 to MatArray.length do

		hit = GetFileInfo(Dir + "\\TOD2\\" + MatArray[mcnt])
		if hit = null then goto badmat

		M = OpenMatrix(Dir + "\\TOD2\\" + MatArray[mcnt],)
		StatArray = MatrixStatistics(M,)
		for j = 1 to StatArray.length do
			Mode = StatArray[j][1]
			Trips = r2s(StatArray[j][2][2][2])
			IntraTrips = r2s(StatArray[j][2][7][2])

/*v=Vector(4,"Float",)
ShowArray(v)
*/
		
			rh = AddRecord("OD_Statistics", {{"TOD",MatCode[mcnt]}, {"Mode",Mode}, {"Trips",Trips}, {"IntraTrips",IntraTrips}})

		end

	end
	
	OD_Statistics_tab1 = ExportView("OD_Statistics|", "CSV", DirReport + "\\OD_Statistics.csv",{"TOD", "Mode", "Trips", "IntraTrips"}, { {"CSV Header", "True"} } )

	RunMacro("G30 File Close All")
	goto quit
		
	badmat: 
	msg = msg + {"ODMatrixStats:  Error - matrix " + MatArray[mcnt] + " not found"}
	AppendToLogFile(1, "ODMatrixStats:  Error - matrix " + MatArray[mcnt] + " not found")
	ODStatsOK = 0
	goto quit 
	
	quit: 
	datentime = GetDateandTime()
	AppendToLogFile(1, "Exit ODMatrixStats: " + datentime)
	return({ODStatsOK, msg})

endmacro