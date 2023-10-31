Macro "TOD1_HBU_Peak"  (Args)

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
	AppendToLogFile(1, "Enter TOD1_HBU_Peak: " + datentime)

	RunMacro("TCB Init")
	
	//template matrix
	TemplateMat = null
	templatecore = null
	TemplateMat = OpenMatrix(METDir + "\\TAZ\\matrix_template.mtx", "True")
	templatecore = CreateMatrixCurrency(TemplateMat, "Table", "Rows", "Columns", )

	CopyMatrixStructure({templatecore}, {{"File Name", Dir + "\\TripTables\\HBU_PEAK_TRIPS.mtx"},
		{"Label", "hbu_peak_person"},
		{"File Based", "Yes"},
		{"Tables", {"HBU_PEAK"}},
		{"Operation", "Union"}})

	//_________HBU________________

	FM1 = OpenMatrix(Dir + "\\TD\\TDhbu.mtx", "True")
	PM = openmatrix(Dir + "\\TripTables\\HBU_PEAK_TRIPS.mtx", "True")
	dm1 = CreateMatrixCurrency(FM1, "Trips", "Rows", "Columns",)
	pm1 = CreateMatrixCurrency(PM, "HBU_PEAK", "Rows", "Columns",)

	MatrixOperations(pm1, {dm1}, {0.7056},,, {{"Operation", "Add"}, {"Force Missing", "No"}})

	dm1 = null
	pm1 = null
	FM1 = null
	PM  = null

	// zero fill matrices
		Opts = null
		Opts.Input.[Matrix Currency] = {Dir + "\\TripTables\\HBU_PEAK_TRIPS.mtx", "HBU_PEAK", "Rows", "Columns"}
		Opts.Global.Method = 11
		Opts.Global.[Cell Range] = 2
		Opts.Global.[Expression Text] = "nz([HBU_PEAK])"
		Opts.Global.[Force Missing] = "Yes"
	ret_value = RunMacro("TCB Run Operation", 1, "Fill Matrices", Opts)
	if !ret_value then goto badfill

	goto quit

	badfill:
	TOD1OK = 0
	msg = msg + {"TOD1_HBU_Peak - zero fill matrix failed"}
	RunMacro("TCB Closing", ret_value, "TRUE" )
	goto quit

	quit:

	datentime = GetDateandTime()
	AppendToLogFile(1, "Exit TOD1_HBU_Peak: " + datentime)
	return({TOD1OK, msg})

endmacro 