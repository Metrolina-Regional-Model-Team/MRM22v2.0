Macro "TOD2_COM_MTK_HTK" (Args)

//Transpose matrix of commercial vehicles, medium and heavy trucks.  

	LogFile = Args.[Log File].value
	ReportFile = Args.[Report File].value
	SetLogFileName(LogFile)
	SetReportFileName(ReportFile)

	METDir = Args.[MET Directory].value
	Dir = Args.[Run Directory].value
	msg = null
	TOD2_COMMTKHTKOK = 1

	datentime = GetDateandTime()
	AppendToLogFile(1, "Enter TOD2_COM_MTK_HTK: " + datentime)

	RunMacro("TCB Init")
	
	//template matrix

	TemplateMat = null
	templatecore = null

	TemplateMat = OpenMatrix(METDir + "\\TAZ\\matrix_template.mtx", "True")
	templatecore = CreateMatrixCurrency(TemplateMat, "Table", "Rows", "Columns", )


	CopyMatrixStructure({templatecore}, {{"File Name", Dir + "\\tod2\\ToTranspose.mtx"},
	    {"Label", "ToTranspose"},
	    {"File Based", "Yes"},
	    {"Tables", {"TransposeCOM", "TransposeMTK", "TransposeHTK"}},
	    {"Operation", "Union"}})



//_________COM, MTK, HTK:  Transpose_all_II_EI_IE_com trips______________________


	M1 = openmatrix(Dir + "\\tod2\\ToTranspose.mtx", "True")
	M2 = openmatrix(Dir + "\\TD\\tdcom.mtx", "True")
	M3 = openmatrix(Dir + "\\TD\\tdeic.mtx", "True")
	M4 = openmatrix(Dir + "\\TD\\tdiec.mtx", "True")
	M5 = openmatrix(Dir + "\\TD\\tdmtk.mtx", "True")
	M6 = openmatrix(Dir + "\\TD\\tdeim.mtx", "True")
	M7 = openmatrix(Dir + "\\TD\\tdiem.mtx", "True")
	M8 = openmatrix(Dir + "\\TD\\tdhtk.mtx", "True")
	M9 = openmatrix(Dir + "\\TD\\tdeih.mtx", "True")
	M10 = openmatrix(Dir + "\\TD\\tdieh.mtx", "True")

	c1 = CreateMatrixCurrency(M1, "TransposeCOM", "Rows", "Columns",)
	c2 = CreateMatrixCurrency(M1, "TransposeMTK", "Rows", "Columns",)
	c3 = CreateMatrixCurrency(M1, "TransposeHTK", "Rows", "Columns",)
	c4 = CreateMatrixCurrency(M2, "Trips", "Rows", "Columns",)
	c5 = CreateMatrixCurrency(M3, "Trips", "Rows", "Columns",)
	c6 = CreateMatrixCurrency(M4, "Trips", "Rows", "Columns",)
	c7 = CreateMatrixCurrency(M5, "Trips", "Rows", "Columns",)
	c8 = CreateMatrixCurrency(M6, "Trips", "Rows", "Columns",)
	c9 = CreateMatrixCurrency(M7, "Trips", "Rows", "Columns",)
	c10 = CreateMatrixCurrency(M8, "Trips", "Rows", "Columns",)
	c11 = CreateMatrixCurrency(M9, "Trips", "Rows", "Columns",)
	c12 = CreateMatrixCurrency(M10, "Trips", "Rows", "Columns",)

        MatrixOperations(c1, {c4,c5,c6}, {1.0,1.0,1.0},,, {{"Operation", "Add"}, {"Force Missing", "No"}})
        MatrixOperations(c2, {c7,c8,c9}, {1.0,1.0,1.0},,, {{"Operation", "Add"}, {"Force Missing", "No"}})
        MatrixOperations(c3, {c10,c11,c12}, {1.0,1.0,1.0},,, {{"Operation", "Add"}, {"Force Missing", "No"}})

    c1 = null
    c2 = null
    c3 = null
    c4 = null
    c6 = null
    c7 = null
    c8 = null
    c9 = null
    c10 = null
    c11 = null
    c12 = null
    c13 = null
    M1 = null
    M2 = null
    M3 = null
    M4 = null
    M5 = null
    M6 = null
    M7 = null
    M8 = null
    M9 = null
    M10 = null



//__________Transpose_COM_____________________________________________________

     Opts = null
     Opts.Input.[Input Matrix] = Dir + "\\tod2\\ToTranspose.mtx"
     Opts.Output.[Transposed Matrix].Label = "TransposeCOM_MTK_HTK"
     Opts.Output.[Transposed Matrix].[File Name] = Dir + "\\tod2\\Transpose_COM_MTK_HTK.mtx"

     ret_value = RunMacro("TCB Run Operation", 1, "Transpose Matrix", Opts)

     if !ret_value then goto badtranspose

goto quit

badtranspose:
	msg = msg + {"TOD2_COM_MTK_HTK - bad transpose"}
    TOD2_COMMTKHTKOK = 0         


quit:

	datentime = GetDateandTime()
	AppendToLogFile(1, "Exit TOD2_COM_MTK_HTK: " + datentime)
	return({TOD2_COMMTKHTKOK, msg})

endmacro