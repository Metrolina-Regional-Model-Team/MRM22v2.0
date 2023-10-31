Macro "TOD1_HBO_OffPeak" (Args)

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
	AppendToLogFile(1, "Enter TOD1_HBO_OffPeak: " + datentime)

	RunMacro("TCB Init")
	
	//template matrix
	TemplateMat = null
	templatecore = null
	TemplateMat = OpenMatrix(METDir + "\\TAZ\\matrix_template.mtx", "True")
	templatecore = CreateMatrixCurrency(TemplateMat, "Table", "Rows", "Columns", )

	CopyMatrixStructure({templatecore}, {{"File Name", Dir + "\\TripTables\\HBO_OFFPEAK_TRIPS.mtx"},
		{"Label", "hbo_offpeak_person"},
		{"File Based", "Yes"},
		{"Tables", {"INCOME1","INCOME2","INCOME3","INCOME4"}},
		{"Operation", "Union"}})

	//_________HBO_______________HBS+HBO___________________

	OPM = openmatrix(Dir + "\\TripTables\\HBO_OFFPEAK_TRIPS.mtx", "True")

	FM1 = OpenMatrix(Dir + "\\TD\\TDhbs1.mtx", "True")
	FM2 = OpenMatrix(Dir + "\\TD\\TDhbo1.mtx", "True")
	c1 = CreateMatrixCurrency(FM1, "Trips", "Rows", "Columns",)
	c2 = CreateMatrixCurrency(FM2, "Trips", "Rows", "Columns",)
	c4 = CreateMatrixCurrency(OPM, "INCOME1", "Rows", "Columns",)

	MatrixOperations(c4, {c1,c2}, {0.5203,0.5739},,, {{"Operation", "Add"}, {"Force Missing", "No"}})

	c1 = null
	c2 = null
	c4 = null
	FM1 = null
	FM2 = null

	FM1 = OpenMatrix(Dir + "\\TD\\TDhbs2.mtx", "True")
	FM2 = OpenMatrix(Dir + "\\TD\\TDhbo2.mtx", "True")
	c1 = CreateMatrixCurrency(FM1, "Trips", "Rows", "Columns",)
	c2 = CreateMatrixCurrency(FM2, "Trips", "Rows", "Columns",)
	c4 = CreateMatrixCurrency(OPM, "INCOME2", "Rows", "Columns",)

	MatrixOperations(c4, {c1,c2}, {0.5203,0.5739},,, {{"Operation", "Add"}, {"Force Missing", "No"}})

	c1 = null
	c2 = null
	c4 = null
	FM1 = null
	FM2 = null

	FM1 = OpenMatrix(Dir + "\\TD\\TDhbs3.mtx", "True")
	FM2 = OpenMatrix(Dir + "\\TD\\TDhbo3.mtx", "True")
	c1 = CreateMatrixCurrency(FM1, "Trips", "Rows", "Columns",)
	c2 = CreateMatrixCurrency(FM2, "Trips", "Rows", "Columns",)
	c4 = CreateMatrixCurrency(OPM, "INCOME3", "Rows", "Columns",)

	MatrixOperations(c4, {c1,c2}, {0.5203,0.5739},,, {{"Operation", "Add"}, {"Force Missing", "No"}})

	c1 = null
	c2 = null
	c4 = null
	FM1 = null
	FM2 = null
 
	FM1 = OpenMatrix(Dir + "\\TD\\TDhbs4.mtx", "True")
	FM2 = OpenMatrix(Dir + "\\TD\\TDhbo4.mtx", "True")
	c1 = CreateMatrixCurrency(FM1, "Trips", "Rows", "Columns",)
	c2 = CreateMatrixCurrency(FM2, "Trips", "Rows", "Columns",)
	c4 = CreateMatrixCurrency(OPM, "INCOME4", "Rows", "Columns",)

	MatrixOperations(c4, {c1,c2}, {0.5203,0.5739},,, {{"Operation", "Add"}, {"Force Missing", "No"}})

	c1 = null
	c2 = null
	c4 = null
	FM1 = null
	FM2 = null
	OPM = null

	// zero fill matrices

		Opts = null
		Opts.Input.[Matrix Currency] = {Dir + "\\TripTables\\HBO_OFFPEAK_TRIPS.mtx", "INCOME1", "Rows", "Columns"}
		Opts.Global.Method = 11
		Opts.Global.[Cell Range] = 2
		Opts.Global.[Expression Text] = "nz([INCOME1])"
		Opts.Global.[Force Missing] = "Yes"
	ret_value = RunMacro("TCB Run Operation", 1, "Fill Matrices", Opts)
	if !ret_value then goto badfill

		Opts = null
		Opts.Input.[Matrix Currency] = {Dir + "\\TripTables\\HBO_OFFPEAK_TRIPS.mtx", "INCOME2", "Rows", "Columns"}
		Opts.Global.Method = 11
		Opts.Global.[Cell Range] = 2
		Opts.Global.[Expression Text] = "nz([INCOME2])"
		Opts.Global.[Force Missing] = "Yes"
	ret_value = RunMacro("TCB Run Operation", 2, "Fill Matrices", Opts)
	if !ret_value then goto badfill

		Opts = null
		Opts.Input.[Matrix Currency] = {Dir + "\\TripTables\\HBO_OFFPEAK_TRIPS.mtx", "INCOME3", "Rows", "Columns"}
		Opts.Global.Method = 11
		Opts.Global.[Cell Range] = 2
		Opts.Global.[Expression Text] = "nz([INCOME3])"
		Opts.Global.[Force Missing] = "Yes"
	ret_value = RunMacro("TCB Run Operation", 3, "Fill Matrices", Opts)
	if !ret_value then goto badfill

		Opts = null
		Opts.Input.[Matrix Currency] = {Dir + "\\TripTables\\HBO_OFFPEAK_TRIPS.mtx", "INCOME4", "Rows", "Columns"}
		Opts.Global.Method = 11
		Opts.Global.[Cell Range] = 2
		Opts.Global.[Expression Text] = "nz([INCOME4])"
		Opts.Global.[Force Missing] = "Yes"
	ret_value = RunMacro("TCB Run Operation", 4, "Fill Matrices", Opts)
	if !ret_value then goto badfill

	goto quit

	badfill:
	TOD1OK = 0
	msg = msg + {"TOD1_HBO_OffPeak - zero fill matrix failed"}
	RunMacro("TCB Closing", ret_value, "TRUE" )
	goto quit

	quit:
	datentime = GetDateandTime()
	AppendToLogFile(1, "Exit TOD1_HBO_OffPeak: " + datentime)
	return({TOD1OK, msg})

endmacro 