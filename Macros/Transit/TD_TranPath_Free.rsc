Macro "TD_TranPath_Free" (Args)

//Altered to create new transit matrix for tdmet_mtx
//Current version uses the raw pprmw and opprmw skims.  Tables are the skim values BEFORE the path is 
//altered to require premium service in path
//McLelland - September, 2006
//Altered for new user interface, Split into peak and free speed versions Nov, 2015

	LogFile = Args.[Log File].value
	ReportFile = Args.[Report File].value
	SetLogFileName(LogFile)
	SetReportFileName(ReportFile)

	METDir = Args.[MET Directory].value
	Dir = Args.[Run Directory].value
	
	msg = null
	TDPathOK = 1

	datentime = GetDateandTime()
	AppendToLogFile(1, "Enter TD_TranPath_Free: " + datentime)

//template matrix

	TemplateMat = null
	templatecore = null

//	on error goto badquit

	TemplateMat = OpenMatrix(METDir + "\\TAZ\\matrix_template.mtx", "True")
	templatecore = CreateMatrixCurrency(TemplateMat, "Table", "Rows", "Columns", )


	// ----- Generate Off-Peak Transit Travel Times


// STEP 4  Create Transit travel time skim matrix for trip distribution (tttran_free)

	CopyMatrixStructure({templatecore}, {{"File Name", Dir + "\\Skims\\TTTran_Free.mtx"},
    		{"Label", "TTTran_free"},
    		{"File Based", "Yes"},
    		{"Tables", {"TTTranFr"}},
    		{"Operation", "Union"}})

	ISKIM = openmatrix(Dir + "\\Skims\\TR_SKIM_OPPrmW.mtx", "True")
	OSKIM = openmatrix(Dir + "\\Skims\\TTTran_Free.mtx", "True")

	ivtt   = CreateMatrixCurrency(ISKIM, "In-Vehicle Time", "RCIndex", "RCIndex",)
	wait1  = CreateMatrixCurrency(ISKIM, "Initial Wait Time", "RCIndex", "RCIndex",)
	waitx  = CreateMatrixCurrency(ISKIM, "Transfer Wait Time", "RCIndex", "RCIndex",)
	pnltyx = CreateMatrixCurrency(ISKIM, "Transfer Penalty Time", "RCIndex", "RCIndex",)
	walkx  = CreateMatrixCurrency(ISKIM, "Transfer Walk Time", "RCIndex", "RCIndex",)
	access = CreateMatrixCurrency(ISKIM, "Access Walk Time", "RCIndex", "RCIndex",)
	egress = CreateMatrixCurrency(ISKIM, "Egress Walk Time", "RCIndex", "RCIndex",)
	tottim = CreateMatrixCurrency(OSKIM, "TTTranFr", "Rows", "Columns",)

        MatrixOperations(tottim, {ivtt,wait1,waitx,pnltyx,walkx,access,egress}, {1,1,1,1,1,1,1},,, {{"Operation", "Add"}, {"Force Missing", "No"}})
	ISKIM = null
	OSKIM = null
	ivtt = null
	wait1 = null
	waitx = null
	pnltyx = null
	walkx = null
	access = null
	egress = null
	tottim = null
goto quit

badquit:
	ShowMessage(GetLastError({{"Reference Info", "True"}}))
	msg = msg + {"TD_TranPath_Free - Error"}
	AppendToLogFile(1, "TD_TranPath_Free - Error")
	TDPathOK = 0

quit:
	on error default
	datentime = GetDateandTime()
	AppendToLogFile(1, "Exit TD_TranPath_Free: " + datentime)
	AppendToLogFile(1, " ")
	return({TDPathOK, msg})





endMacro