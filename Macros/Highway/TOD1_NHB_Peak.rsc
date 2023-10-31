Macro "TOD1_NHB_Peak" (Args)

	//Percentages are currently based on the 2012 HHTS 
	//Calculations for percentages are in calibration\TRIPPROP_MRM14v1.0.xls, tab TOD1
	//Modified for new UI, Oct, 2015
	
	LogFile = Args.[Log File].value
	ReportFile = Args.[Report File].value
	SetLogFileName(LogFile)
	SetReportFileName(ReportFile)

	METDir = Args.[MET Directory].value
	Dir = Args.[Run Directory].value

	curiter = Args.[Current Feedback Iter].value
	TOD1OK = 1
	msg = null
	
	datentime = GetDateandTime()
	AppendToLogFile(1, "Enter TOD1_NHB_Peak: " + datentime)
	AppendToLogFile(2, "AM Peak feedback iteration: " + i2s(curiter))

	RunMacro("TCB Init")
	
	//template matrix
	TemplateMat = null
	templatecore = null
	TemplateMat = OpenMatrix(METDir + "\\TAZ\\matrix_template.mtx", "True")
	templatecore = CreateMatrixCurrency(TemplateMat, "Table", "Rows", "Columns", )

	CopyMatrixStructure({templatecore}, {{"File Name", Dir + "\\TripTables\\NHB_PEAK_TRIPS.mtx"},
		{"Label", "nhb_peak_person"},
		{"File Based", "Yes"},
		{"Tables", {"NHB_PEAK"}},
		{"Operation", "Union"}})


//________NHB________JTW+ATW+NWK____________


	FM1 = OpenMatrix(Dir + "\\TD\\TDjtw.mtx", "True")
	FM2 = OpenMatrix(Dir + "\\TD\\TDatw.mtx", "True")
	FM3 = OpenMatrix(Dir + "\\TD\\TDnwk.mtx", "True")
	PM = openmatrix(Dir + "\\TripTables\\NHB_PEAK_TRIPS.mtx", "True")
	c1 = CreateMatrixCurrency(FM1, "Trips", "Rows", "Columns",)
	c2 = CreateMatrixCurrency(FM2, "Trips", "Rows", "Columns",)
	c3 = CreateMatrixCurrency(FM3, "Trips", "Rows", "Columns",)
	c4 = CreateMatrixCurrency(PM, "NHB_PEAK", "Rows", "Columns",)

	MatrixOperations(c4, {c1,c2,c3}, {0.5266,0.1324,0.3289},,, {{"Operation", "Add"}, {"Force Missing", "No"}})

	c1 = null
	c2 = null
	c3 = null
	c4 = null
	FM1 = null
	FM2 = null
	FM3 = null
	PM = null

	// zero fill matrices
		Opts = null
		Opts.Input.[Matrix Currency] = {Dir + "\\TripTables\\NHB_PEAK_TRIPS.mtx", "NHB_PEAK", "Rows", "Columns"}
		Opts.Global.Method = 11
		Opts.Global.[Cell Range] = 2
		Opts.Global.[Expression Text] = "nz([NHB_PEAK])"
		Opts.Global.[Force Missing] = "Yes"
	ret_value = RunMacro("TCB Run Operation", 1, "Fill Matrices", Opts)
	if !ret_value then goto badfill

	goto quit

	badfill:
	TOD1OK = 0
	msg = msg + {"TOD1_NHB_Peak - zero fill matrix failed"}
	RunMacro("TCB Closing", ret_value, "TRUE" )
	goto quit

	quit:

	datentime = GetDateandTime()
	AppendToLogFile(1, "Exit TOD1_NHB_Peak: " + datentime)
	return({TOD1OK, msg})

endmacro 