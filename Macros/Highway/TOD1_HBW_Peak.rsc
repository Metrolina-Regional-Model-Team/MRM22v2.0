Macro "TOD1_HBW_Peak" (Args)

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
	AppendToLogFile(1, "Enter TOD1_HBW_Peak: " + datentime)
	AppendToLogFile(2, "AM Peak feedback iteration: " + i2s(curiter))

	RunMacro("TCB Init")
	
	//template matrix
	TemplateMat = null
	templatecore = null
	TemplateMat = OpenMatrix(METDir + "\\TAZ\\matrix_template.mtx", "True")
	templatecore = CreateMatrixCurrency(TemplateMat, "Table", "Rows", "Columns", )


	CopyMatrixStructure({templatecore}, {{"File Name", Dir + "\\TripTables\\HBW_PEAK_TRIPS.mtx"},
		{"Label", "hbw_peak_person"},
		{"File Based", "Yes"},
		{"Tables", {"INCOME1","INCOME2","INCOME3","INCOME4"}},
		{"Operation", "Union"}})

	//_________HBW__HBW_INC1_includes_HBU________________

	FM1 = OpenMatrix(Dir + "\\TD\\TDhbw1.mtx", "True")
	FM2 = OpenMatrix(Dir + "\\TD\\TDhbw2.mtx", "True")
	FM3 = OpenMatrix(Dir + "\\TD\\TDhbw3.mtx", "True")
	FM4 = OpenMatrix(Dir + "\\TD\\TDhbw4.mtx", "True")
	PM = openmatrix(Dir + "\\TripTables\\HBW_PEAK_TRIPS.mtx", "True")
	dm1 = CreateMatrixCurrency(FM1, "Trips", "Rows", "Columns",)
	dm2 = CreateMatrixCurrency(FM2, "Trips", "Rows", "Columns",)
	dm3 = CreateMatrixCurrency(FM3, "Trips", "Rows", "Columns",)
	dm4 = CreateMatrixCurrency(FM4, "Trips", "Rows", "Columns",)
	pm1 = CreateMatrixCurrency(PM, "INCOME1", "Rows", "Columns",)
	pm2 = CreateMatrixCurrency(PM, "INCOME2", "Rows", "Columns",)
	pm3 = CreateMatrixCurrency(PM, "INCOME3", "Rows", "Columns",)
	pm4 = CreateMatrixCurrency(PM, "INCOME4", "Rows", "Columns",)

	MatrixOperations(pm1, {dm1}, {0.6386},,, {{"Operation", "Add"}, {"Force Missing", "No"}})
	MatrixOperations(pm2, {dm2}, {0.6386},,, {{"Operation", "Add"}, {"Force Missing", "No"}})
	MatrixOperations(pm3, {dm3}, {0.6386},,, {{"Operation", "Add"}, {"Force Missing", "No"}})
	MatrixOperations(pm4, {dm4}, {0.6386},,, {{"Operation", "Add"}, {"Force Missing", "No"}})

	dm1 = null
	dm2 = null
	dm3 = null
	dm4 = null
	pm1 = null
	pm2 = null
	pm3 = null
	pm4 = null
	FM1 = null
	FM2 = null
	FM3 = null
	FM4 = null
	PM  = null

	// zero fill matrices
		Opts = null
		Opts.Input.[Matrix Currency] = {Dir + "\\TripTables\\HBW_PEAK_TRIPS.mtx", "INCOME1", "Rows", "Columns"}
		Opts.Global.Method = 11
		Opts.Global.[Cell Range] = 2
		Opts.Global.[Expression Text] = "nz([INCOME1])"
		Opts.Global.[Force Missing] = "Yes"
	ret_value = RunMacro("TCB Run Operation", 1, "Fill Matrices", Opts)
	if !ret_value then goto badfill

		Opts = null
		Opts.Input.[Matrix Currency] = {Dir + "\\TripTables\\HBW_PEAK_TRIPS.mtx", "INCOME2", "Rows", "Columns"}
		Opts.Global.Method = 11
		Opts.Global.[Cell Range] = 2
		Opts.Global.[Expression Text] = "nz([INCOME2])"
		Opts.Global.[Force Missing] = "Yes"
	ret_value = RunMacro("TCB Run Operation", 2, "Fill Matrices", Opts)
	if !ret_value then goto badfill

		Opts = null
		Opts.Input.[Matrix Currency] = {Dir + "\\TripTables\\HBW_PEAK_TRIPS.mtx", "INCOME3", "Rows", "Columns"}
		Opts.Global.Method = 11
		Opts.Global.[Cell Range] = 2
		Opts.Global.[Expression Text] = "nz([INCOME3])"
		Opts.Global.[Force Missing] = "Yes"
	ret_value = RunMacro("TCB Run Operation", 3, "Fill Matrices", Opts)
	if !ret_value then goto badfill

		Opts = null
		Opts.Input.[Matrix Currency] = {Dir + "\\TripTables\\HBW_PEAK_TRIPS.mtx", "INCOME4", "Rows", "Columns"}
		Opts.Global.Method = 11
		Opts.Global.[Cell Range] = 2
		Opts.Global.[Expression Text] = "nz([INCOME4])"
		Opts.Global.[Force Missing] = "Yes"
	ret_value = RunMacro("TCB Run Operation", 4, "Fill Matrices", Opts)
	if !ret_value then goto badfill

	goto quit

	badfill:
	TOD1OK = 0
	msg = msg + {"TOD1_HBW_Peak - zero fill matrix failed"}
	RunMacro("TCB Closing", ret_value, "TRUE" )
	goto quit

	quit:

	datentime = GetDateandTime()
	AppendToLogFile(1, "Exit TOD1_HBW_Peak: " + datentime)
	return({TOD1OK, msg})

endmacro 