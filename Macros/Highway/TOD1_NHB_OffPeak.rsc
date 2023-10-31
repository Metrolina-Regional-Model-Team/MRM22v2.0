Macro "TOD1_NHB_OffPeak" (Args)

	//Percentages are currently based on the 2012 HHTS 
	//Calculations for percentages are in calibration\TRIPPROP_MRM14v1.0.xls, tab TOD1
	//Modified for new UI, Oct, 2015
	
	LogFile = Args.[Log File].value
	ReportFile = Args.[Report File].value
	SetLogFileName(LogFile)
	SetReportFileName(ReportFile)

	METDir = Args.[MET Directory].value
	Dir = Args.[Run Directory].value
	msg = null
	TOD1OK = 1
	
	datentime = GetDateandTime()
	AppendToLogFile(1, "Enter TOD1_NHB_OffPeak: " + datentime)

	RunMacro("TCB Init")
	
	//template matrix
	TemplateMat = null
	templatecore = null
	TemplateMat = OpenMatrix(METDir + "\\TAZ\\matrix_template.mtx", "True")
	templatecore = CreateMatrixCurrency(TemplateMat, "Table", "Rows", "Columns", )


	CopyMatrixStructure({templatecore}, {{"File Name", Dir + "\\TripTables\\NHB_OFFPEAK_TRIPS.mtx"},
		{"Label", "nhb_offpeak_person"},
		{"File Based", "Yes"},
		{"Tables", {"NHB_OFFPEAK"}},
		{"Operation", "Union"}})


	//________NHB________JTW+ATW+NWK____________


	FM1 = OpenMatrix(Dir + "\\TD\\TDjtw.mtx", "True")
	FM2 = OpenMatrix(Dir + "\\TD\\TDatw.mtx", "True")
	FM3 = OpenMatrix(Dir + "\\TD\\TDnwk.mtx", "True")
	OPM = openmatrix(Dir + "\\triptables\\NHB_OFFPEAK_TRIPS.mtx", "True")
	c1 = CreateMatrixCurrency(FM1, "Trips", "Rows", "Columns",)
	c2 = CreateMatrixCurrency(FM2, "Trips", "Rows", "Columns",)
	c3 = CreateMatrixCurrency(FM3, "Trips", "Rows", "Columns",)
	c5 = CreateMatrixCurrency(OPM, "NHB_OFFPEAK", "Rows", "Columns",)

	MatrixOperations(c5, {c1,c2,c3}, {0.4734,0.8676,0.6711},,, {{"Operation", "Add"}, {"Force Missing", "No"}})

	c1 = null
	c2 = null
	c3 = null
	c5 = null
	FM1 = null
	FM2 = null
	FM3 = null
	OPM = null

	// zero fill matrices
		Opts = null
		Opts.Input.[Matrix Currency] = {Dir + "\\TripTables\\NHB_OFFPEAK_TRIPS.mtx", "NHB_OFFPEAK", "Rows", "Columns"}
		Opts.Global.Method = 11
		Opts.Global.[Cell Range] = 2
		Opts.Global.[Expression Text] = "nz([NHB_OFFPEAK])"
		Opts.Global.[Force Missing] = "Yes"
	ret_value = RunMacro("TCB Run Operation", 1, "Fill Matrices", Opts)
	if !ret_value then goto badfill

	goto quit

	badfill:
	TOD1OK = 0
	msg = msg + {"TOD1_NHB_OffPeak - zero fill matrix failed"}
	RunMacro("TCB Closing", ret_value, "TRUE" )
	goto quit

	quit:
	datentime = GetDateandTime()
	AppendToLogFile(1, "Exit TOD1_NHB_OffPeak: " + datentime)
	return({TOD1OK, msg})

endmacro 