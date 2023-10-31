Macro "Transit_RunStats" (Args)

	LogFile = Args.[Log File].value
	ReportFile = Args.[Report File].value
	SetLogFileName(LogFile)
	SetReportFileName(ReportFile)
	TransitRunStatsOK = 1

	datentime = GetDateandTime()
	AppendToLogFile(1, "Enter Transit_RunStats: " + datentime)

	Dir = Args.[Run Directory].value
	TrackIDFile = Dir + "\\Track_ID.dbf"
	RouteOutFile = Dir  + "\\Report\\RouteOut.dbf"
	OpStatsFile = Dir  + "\\Report\\Operation_Statistics.dbf"
	RunStatsFile = Dir + "\\Report\\Transit_RunStats.csv"	 
	RouteOutSum = Dir  + "\\Report\\RouteOut_Summary.dbf"
	OpStatsSum = Dir  + "\\Report\\Operation_Statistics_Summary.dbf"
	TrackSum = Dir  + "\\Report\\Transit_RunStats_Summary.dbf"
	msg = null

	IDView = OpenTable("IDView", "dBASE", {TrackIDFile,})
	RouteOutView = OpenTable("RouteOutView", "dBASE", {RouteOutFile,})
	OpStatsView = OpenTable("OpStatsView", "dBASE", {OpStatsFile,})

	RouteOutSumView = ComputeStatistics(RouteOutView + "|", "RouteOutSumView", RouteOutSum, "dBASE", )
		

	KeyView = JoinViews("KeyView", RouteOutView+".KEY", OpStatsView+".KEY",)
		
    TrackView = JoinViews("TrackView", IDView+".Track", KeyView+".RouteOutView"+".Track",  
    	{{"A",}, 
    	 {"Fields", 
    	 {"Company", {{"Copy"}}},
    	 {"PASS", {{"Sum",,,}}}, {"PASSHOUR", {{"Sum"}}}, {"PASSMILE", {{"Sum"}}},
		 {"PPRMW_PASS", {{"Sum"}}}, {"PBUSW_PASS", {{"Sum"}}}, {"PPRMD_PASS", {{"Sum"}}}, {"PBUSD_PASS", {{"Sum"}}},
		 {"OPPRMW_PAS", {{"Sum"}}}, {"OPBUSW_PAS", {{"Sum"}}}, {"OPPRMD_PAS", {{"Sum"}}}, {"OPBUSD_PAS", {{"Sum"}}},
		 {"PPRMDO_PAS", {{"Sum"}}}, {"PBUSDO_PAS", {{"Sum"}}}, {"OPPRMDO_PA", {{"Sum"}}}, {"OPBUSDO_PA", {{"Sum"}}},
		 {"AM_TRIPS", {{"Sum"}}}, {"MID_TRIPS", {{"Sum"}}}, {"PM_TRIPS", {{"Sum"}}}, {"NIGHT_TRIP", {{"Sum"}}},
		 {"AM_VEHRS", {{"Sum"}}}, {"MID_VEHRS", {{"Sum"}}}, {"PM_VEHRS", {{"Sum"}}}, {"NIG_VEHRS", {{"Sum"}}},
		 {"AM_VEHMIL", {{"Sum"}}}, {"MID_VEHMIL", {{"Sum"}}}, {"PM_VEHMIL", {{"Sum"}}}, {"NIG_VEHMIL", {{"Sum"}}}
		}})

//	ExportView(TrackView + "|", "dBASE", Dir + "\\Report\\Holdher.dbf",,)
//	TrackSumView = ComputeStatistics(TrackView + "|", "TrackSumView", TrackSum, "dBASE", )

	SetView(TrackView)	
	sortorder	= CreateExpression(TrackView, "SortOrder", "IDView.Company * 10000 + IDView.Mode * 1000 + IDView.Track",)
	passprem = CreateExpression(TrackView, "PassPrem", "PPRMW_PASS + PPRMD_PASS + OPPRMW_PAS + OPPRMD_PAS + PPRMDO_PAS + OPPRMDO_PA", )  
	passbus  = CreateExpression(TrackView, "PassBus", "PBUSW_PASS + PBUSD_PASS + OPBUSW_PAS + OPBUSD_PAS + PBUSDO_PAS + OPBUSDO_PA", ) 
	passwalk  = CreateExpression(TrackView, "PassWalk", "PPRMW_PASS + PBUSW_PASS + OPPRMW_PAS + OPBUSW_PAS", ) 
	passdrive = CreateExpression(TrackView, "PassDrive", "PPRMD_PASS + PBUSD_PASS + OPPRMD_PAS + OPBUSD_PAS", )
	passdropoff  = CreateExpression(TrackView, "PassDropOff", "PPRMDO_PAS + PBUSDO_PAS + OPPRMDO_PA + OPBUSDO_PA", ) 
	passpeak  = CreateExpression(TrackView, "PassPeak", "PPRMW_PASS + PBUSW_PASS + PPRMD_PASS + PBUSD_PASS + PPRMDO_PAS + PBUSDO_PAS", ) 
	passoffpeak  = CreateExpression(TrackView, "PassOffPeak", "OPPRMW_PAS + OPBUSW_PAS + OPPRMD_PAS + OPBUSD_PAS + OPPRMDO_PA + OPBUSDO_PA", )


	ExportView(TrackView + "|", "CSV", RunStatsFile, 
		{"IDView.Company", "IDView.Mode", "IDView.Track", "RTENAME", 
		 "PASS", "PASSHOUR", "PASSMILE", 
		 "PassPeak", "PassOffPeak", "PassPrem", "PassBus", "PassWalk", "PassDrive", "PassDropOff" , 
	 	 "PPRMW_PASS", "PBUSW_PASS", "PPRMD_PASS", "PBUSD_PASS", 
		 "OPPRMW_PAS", "OPBUSW_PAS", "OPPRMD_PAS", "OPBUSD_PAS", "PPRMDO_PAS", "PBUSDO_PAS",
		 "OPPRMDO_PA", "OPBUSDO_PA", 
		 "AM_TRIPS", "MID_TRIPS", "PM_TRIPS", "NIGHT_TRIP", 
		 "AM_VEHRS", "MID_VEHRS", "PM_VEHRS", "NIG_VEHRS", 
		 "AM_VEHMIL", "MID_VEHMIL", "PM_VEHMIL", "NIG_VEHMIL", "SortOrder"}, 
		{
			{"CSV Header", "True"},
	//		{"Row Order", {"SortOrder","Ascending"}}
		})

		
	
	CloseView(IDView)
	CloseView(RouteOutView)
	CloseView(OpStatsView)
	CloseView(KeyView)
	CloseView(TrackView)
	CloseView(RouteOutSumView)

	datentime = GetDateandTime()
	AppendToLogFile(1, "Exit Transit_RunStats: " + datentime)

	return ({TransitRunStatsOK, msg})

endMacro
