macro "TDMatrixStats" (Args)

	LogFile = Args.[Log File].value
	SetLogFileName(LogFile)

	Dir = Args.[Run Directory].value
	msg = null
	TDStatsOK = 1
	
	DirReport  = Dir + "\\Report"
	RunMacro("TCB Init")

	datentime = GetDateandTime()
	AppendToLogFile(1, "Enter TDMatrixStats: " + datentime)

	MatArray = {"TDhbw1.mtx",
		    "TDhbw2.mtx",
		    "TDhbw3.mtx",
		    "TDhbw4.mtx",
		    "TDhbs1.mtx",
		    "TDhbs2.mtx",
		    "TDhbs3.mtx",
		    "TDhbs4.mtx",
		    "TDhbo1.mtx",
		    "TDhbo2.mtx",
		    "TDhbo3.mtx",
		    "TDhbo4.mtx",
		    "TDsch.mtx",
		    "TDhbu.mtx",
		    "TDjtw.mtx",
		    "TDatw.mtx",
		    "TDnwk.mtx",
		    "TDcom.mtx",
		    "TDmtk.mtx",
		    "TDhtk.mtx",
		    "TDeiw.mtx",
		    "TDein.mtx",
		    "TDeic.mtx",
		    "TDeim.mtx",
		    "TDeih.mtx",
		    "TDiew.mtx",
		    "TDien.mtx",
		    "TDiec.mtx",
		    "TDiem.mtx",
		    "TDieh.mtx",
		    "TDeea.mtx",
		    "TDeec.mtx",
		    "TDeem.mtx",
		    "TDeeh.mtx"}
	MatCode = {"HBW Inc1",
		   "HBW Inc2",
		   "HBW Inc3",
		   "HBW Inc4",
		   "HBS Inc1",
		   "HBS Inc2",
		   "HBS Inc3",
		   "HBS Inc4",
		   "HBO Inc1",
		   "HBO Inc2",
		   "HBO Inc3",
		   "HBO Inc4",
		   "SCHOOL  ",
		   "HB UNIV ",
		   "JTW     ",
		   "ATW     ",
		   "NWK     ",
		   "COM     ",
		   "MTK     ",
		   "HTK     ",
		   "EI WK   ",
		   "EI NW   ",
		   "EI COM  ",
		   "EI MTK  ",
		   "EI HTK  ",
		   "IE WK   ",
		   "IE NW   ",
		   "IE COM  ",
		   "IE MTK  ",
		   "IE HTK  ",
		   "EE AUTO ",
		   "EE COM  ",
		   "EE MTK  ",
		   "EE HTK  "}


	TD_Statistics = CreateTable("TD_Statistics", DirReport + "\\TD_Statistics.bin", "FFB", {{"Purpose", "String", 10, , "No"}, {"Mode", "String", 8, , "No"}, {"Trips", "Real", 10, 2, "No"}, {"IntraTrips", "Real", 10, 2, "No"}}) 
 
  	StatOut = OpenFile(StatOutName, "w")

	for mcnt = 1 to MatArray.length do

		hit = GetFileInfo(Dir + "\\TD\\" + MatArray[mcnt])
		if hit = null then goto badmat

		M = OpenMatrix(Dir + "\\TD\\" + MatArray[mcnt],)
		StatArray = MatrixStatistics(M,)
		for j = 1 to StatArray.length do
			Mode = StatArray[j][1]
			Trips = r2s(StatArray[j][2][2][2])
			IntraTrips = r2s(StatArray[j][2][7][2])
			
			rh = AddRecord("TD_Statistics", {{"Purpose",MatCode[mcnt]}, {"Mode",Mode}, {"Trips",Trips}, {"IntraTrips",IntraTrips}})
		end
	end
	
	TD_Statistics_tab1 = ExportView("TD_Statistics|", "CSV", DirReport + "\\TD_Statistics.csv",{"Purpose_TOD", "Mode", "Trips", "IntraTrips"}, { {"CSV Header", "True"} } )
	
	RunMacro("G30 File Close All")
	goto quit
		
		
	badmat: 
	msg = msg + {"TDMatrixStats:  Error - matrix " + MatArray[mcnt] + " not found"}
	AppendToLogFile(1, "TDMatrixStats:  Error - matrix " + MatArray[mcnt] + " not found")
	TDStatsOK = 0
	goto quit 
	
	quit: 
	datentime = GetDateandTime()
	AppendToLogFile(1, "Exit TDMatrixStats: " + datentime)
	return({TDStatsOK, msg})

endmacro