Macro "TOD2_Midday" (Args)

//PA-AP fractions updated 10/2/13; 3+ occupancy rates derived from 2012 HHTS

	LogFile = Args.[Log File].value
	ReportFile = Args.[Report File].value
	SetLogFileName(LogFile)
	SetReportFileName(ReportFile)

	METDir = Args.[MET Directory].value
	Dir = Args.[Run Directory].value
	msg = null
	TOD2_MiddayOK = 1

	datentime = GetDateandTime()
	AppendToLogFile(1, "Enter TOD2_Midday: " + datentime)

	RunMacro("TCB Init")
	
	//template matrix

	TemplateMat = null
	templatecore = null

	TemplateMat = OpenMatrix(METDir + "\\TAZ\\matrix_template.mtx", "True")
	templatecore = CreateMatrixCurrency(TemplateMat, "Table", "Rows", "Columns", )




	CopyMatrixStructure({templatecore}, {{"File Name", Dir + "\\tod2\\PAHwyVeh_Midday.mtx"},
	    {"Label", "PAveh_Midday"},
	    {"File Based", "Yes"},
	    {"Tables", {"SOV", "Pool2", "Pool3"}},
	    {"Operation", "Union"}})

	CopyMatrixStructure({templatecore}, {{"File Name", Dir + "\\tod2\\APHwyVeh_Midday.mtx"},
	    {"Label", "APveh_Midday"},
	    {"File Based", "Yes"},
	    {"Tables", {"SOV", "Pool2", "Pool3"}},
	    {"Operation", "Union"}})


	CopyMatrixStructure({templatecore}, {{"File Name", Dir + "\\tod2\\ODHwyVeh_Midday.mtx"},
	    {"Label", "ODveh_Midday"},
	    {"File Based", "Yes"},
	    {"Tables", {"SOV", "Pool2", "Pool3", "COM", "MTK", "HTK"}},
	    {"Operation", "Union"}})



	HBW = openmatrix(Dir + "\\ModeSplit\\HBW_OFFPEAK_MS.mtx", "True")
	HBO = openmatrix(Dir + "\\ModeSplit\\HBO_OFFPEAK_MS.mtx", "True")
	NHB = openmatrix(Dir + "\\ModeSplit\\NHB_OFFPEAK_MS.mtx", "True")
	HBU =  openmatrix(Dir + "\\ModeSplit\\HBU_OFFPEAK_MS.mtx", "True")
    SCH = openmatrix(Dir + "\\TD\\tdSCH.mtx", "True")
	EIW = openmatrix(Dir + "\\TD\\tdeiw.mtx", "True")
	IEW = openmatrix(Dir + "\\TD\\tdiew.mtx", "True")
	EIN = openmatrix(Dir + "\\TD\\tdein.mtx", "True")
	IEN = openmatrix(Dir + "\\TD\\tdien.mtx", "True")

	MIPA = openmatrix(Dir + "\\tod2\\PAHwyVeh_Midday.mtx", "True")
	MIAP = openmatrix(Dir + "\\tod2\\APHwyVeh_Midday.mtx", "True")

	dahbw  = CreateMatrixCurrency(HBW, "Drive Alone", "Rows", "Columns",)
	p2hbw  = CreateMatrixCurrency(HBW, "Carpool 2", "Rows", "Columns",)
	p3hbw  = CreateMatrixCurrency(HBW, "Carpool 3", "Rows", "Columns",)
	dahbo  = CreateMatrixCurrency(HBO, "Drive Alone", "Rows", "Columns",)
	p2hbo  = CreateMatrixCurrency(HBO, "Carpool 2", "Rows", "Columns",)
	p3hbo  = CreateMatrixCurrency(HBO, "Carpool 3", "Rows", "Columns",)
	danhb  = CreateMatrixCurrency(NHB, "Drive Alone", "Rows", "Columns",)
	p2nhb  = CreateMatrixCurrency(NHB, "Carpool 2", "Rows", "Columns",)
	p3nhb  = CreateMatrixCurrency(NHB, "Carpool 3", "Rows", "Columns",)
	tsch   = CreateMatrixCurrency(SCH, "Trips", "Rows", "Columns",)
	teiw   = CreateMatrixCurrency(EIW, "Trips", "Rows", "Columns",)
	tiew   = CreateMatrixCurrency(IEW, "Trips", "Rows", "Columns",)
    tein   = CreateMatrixCurrency(EIN, "Trips", "Rows", "Columns",)
	tien   = CreateMatrixCurrency(IEN, "Trips", "Rows", "Columns",)
	dahbu  = CreateMatrixCurrency(HBU, "Drive Alone", "Rows", "Columns",)
	p2hbu  = CreateMatrixCurrency(HBU, "Carpool 2", "Rows", "Columns",)
	p3hbu  = CreateMatrixCurrency(HBU, "Carpool 3", "Rows", "Columns",)

	mipa1  = CreateMatrixCurrency(MIPA, "SOV", "Rows", "Columns",)
	mipa2  = CreateMatrixCurrency(MIPA, "Pool2", "Rows", "Columns",)
	mipa3  = CreateMatrixCurrency(MIPA, "Pool3", "Rows", "Columns",)
	miap1  = CreateMatrixCurrency(MIAP, "SOV", "Rows", "Columns",)
	miap2  = CreateMatrixCurrency(MIAP, "Pool2", "Rows", "Columns",)
	miap3  = CreateMatrixCurrency(MIAP, "Pool3", "Rows", "Columns",)

//P to A and A to P percentages should be recalculated upon completion of a new External Travel Survey and/or HHTS
//Percentages are currently based on the 2012 HHTS and 2013 External Survey (nonfreeway) and 2003 External Survey (freeway)
//Calculations for internal P to A and A to P percentages are in calibration\TRIPPROP_MRM14v1.0.xls
//Caclulation for EI/IE P to A and A to P percentages are in calibration\EI_newarea_TOD2_MRM14v1.0.xls

//P to A - drive alone
        MatrixOperations(mipa1, {dahbw,dahbo,danhb,tsch,teiw,tiew,tein,tien,dahbu}, {0.2379,0.3663,0.4500,0.0584,0.0887,0.0573,0.0801,0.0838,0.3487},,, {{"Operation", "Add"}, {"Force Missing", "No"}})

//P to A - pool 2
        MatrixOperations(mipa2, {p2hbw,p2hbo,p2nhb,tsch,teiw,tiew,tein,tien,p2hbu}, {0.1190,0.1832,0.2250,0.0784,0.0118,0.0076,0.0407,0.0426,0.1744},,, {{"Operation", "Add"}, {"Force Missing", "No"}})

//P to A - pool 3+
        MatrixOperations(mipa3, {p3hbw,p3hbo,p3nhb,tsch,teiw,tiew,tein,tien,p3hbu}, {0.0669,0.1026,0.1230,0.0298,0.0021,0.0014,0.0117,0.0109,0.1039},,, {{"Operation", "Add"}, {"Force Missing", "No"}})

//A to P - drive alone
        MatrixOperations(miap1, {dahbw,dahbo,danhb,tsch,teiw,tiew,tein,tien,dahbu}, {0.1963,0.2710,0.4500,0.0516,0.0769,0.0763,0.0802,0.0749,0.4313},,, {{"Operation", "Add"}, {"Force Missing", "No"}})

//A to P - pool 2
        MatrixOperations(miap2, {p2hbw,p2hbo,p2nhb,tsch,teiw,tiew,tein,tien,p2hbu}, {0.0982,0.1355,0.2250,0.0693,0.0103,0.0102,0.0408,0.0381,0.2157},,, {{"Operation", "Add"}, {"Force Missing", "No"}})

//A to P - pool 3+
        MatrixOperations(miap3, {p3hbw,p3hbo,p3nhb,tsch,teiw,tiew,tein,tien,p3hbu}, {0.0552,0.0759,0.1230,0.0532,0.0019,0.0018,0.0117,0.0109,0.1285},,, {{"Operation", "Add"}, {"Force Missing", "No"}})


	HBW = null
	HBO = null
	NHB = null
        SCH = null
	EIW = null
	IEW = null
	EIN = null
	IEN = null
        HBU = null

	MIPA = null
	MIAP = null

	dahbw  = null
	p2hbw  = null
	p3hbw  = null
	dahbo  = null
	p2hbo  = null
	p3hbo  = null
	danhb  = null
	p2nhb  = null
	p3nhb  = null
	tsch   = null
	teiw   = null
	tiew   = null
        tein   = null
	tien   = null
	dahbu  = null
	p2hbu  = null
	p3hbu  = null

	mipa1  = null
	mipa2  = null
	mipa3  = null
	miap1  = null
	miap2  = null
	miap3  = null


//___________________Transpose_Midday_________________________________________________

     Opts = null
     Opts.Input.[Input Matrix] = Dir + "\\tod2\\APHwyVeh_Midday.mtx"
     Opts.Output.[Transposed Matrix].Label = "Transpose_Midday"
     Opts.Output.[Transposed Matrix].[File Name] = Dir + "\\tod2\\Transpose_Midday.mtx"

     ret_value = RunMacro("TCB Run Operation", 1, "Transpose Matrix", Opts)

     if !ret_value then goto quit


//________OD tables:  Midday SOV and pool:  Sum PA and transposed matrices, 
//        Com, MTK, HTK - td tables and transposed table - use pcts of each


	PA  = openmatrix(Dir + "\\tod2\\PAHwyVeh_Midday.mtx", "True")
	TR  = openmatrix(Dir + "\\tod2\\Transpose_Midday.mtx", "True")
	EEA = openmatrix(Dir + "\\TD\\tdeea.mtx", "True")
        TCMH = openmatrix(Dir + "\\tod2\\Transpose_COM_MTK_HTK.mtx", "True")

	COM = openmatrix(Dir + "\\TD\\tdcom.mtx", "True")
	EIC = openmatrix(Dir + "\\TD\\tdeic.mtx", "True")
	IEC = openmatrix(Dir + "\\TD\\tdiec.mtx", "True")
	EEC = openmatrix(Dir + "\\TD\\tdeec.mtx", "True")

	MTK = openmatrix(Dir + "\\TD\\tdmtk.mtx", "True")
	EIM = openmatrix(Dir + "\\TD\\tdeim.mtx", "True")
	IEM = openmatrix(Dir + "\\TD\\tdiem.mtx", "True")
	EEM = openmatrix(Dir + "\\TD\\tdeem.mtx", "True")

	HTK = openmatrix(Dir + "\\TD\\tdhtk.mtx", "True")
	EIH = openmatrix(Dir + "\\TD\\tdeih.mtx", "True")
	IEH = openmatrix(Dir + "\\TD\\tdieh.mtx", "True")
	EEH = openmatrix(Dir + "\\TD\\tdeeh.mtx", "True")

	OD  = openmatrix(Dir + "\\tod2\\ODHwyVeh_Midday.mtx", "True")

	pasov = CreateMatrixCurrency(PA, "SOV", "Rows", "Columns",)
	papool2 = CreateMatrixCurrency(PA, "Pool2", "Rows", "Columns",)
	papool3 = CreateMatrixCurrency(PA, "Pool3", "Rows", "Columns",)

	trsov = CreateMatrixCurrency(TR, "SOV", "Columns", "Rows",)
	trpool2 = CreateMatrixCurrency(TR, "Pool2", "Columns", "Rows",)
	trpool3 = CreateMatrixCurrency(TR, "Pool3", "Columns", "Rows",)

	eeat = CreateMatrixCurrency(EEA, "Trips", "Rows", "Columns",) 

	tc = CreateMatrixCurrency(TCMH, "TransposeCOM", "Columns", "Rows",)
	tm = CreateMatrixCurrency(TCMH, "TransposeMTK", "Columns", "Rows",)
	th = CreateMatrixCurrency(TCMH, "TransposeHTK", "Columns", "Rows",)

	c1 = CreateMatrixCurrency(COM, "Trips", "Rows", "Columns",)
	c2 = CreateMatrixCurrency(EIC, "Trips", "Rows", "Columns",)
	c3 = CreateMatrixCurrency(IEC, "Trips", "Rows", "Columns",)
	c4 = CreateMatrixCurrency(EEC, "Trips", "Rows", "Columns",)

	m1 = CreateMatrixCurrency(MTK, "Trips", "Rows", "Columns",)
	m2 = CreateMatrixCurrency(EIM, "Trips", "Rows", "Columns",)
	m3 = CreateMatrixCurrency(IEM, "Trips", "Rows", "Columns",)
	m4 = CreateMatrixCurrency(EEM, "Trips", "Rows", "Columns",)

	h1 = CreateMatrixCurrency(HTK, "Trips", "Rows", "Columns",)
	h2 = CreateMatrixCurrency(EIH, "Trips", "Rows", "Columns",)
	h3 = CreateMatrixCurrency(IEH, "Trips", "Rows", "Columns",)
	h4 = CreateMatrixCurrency(EEH, "Trips", "Rows", "Columns",)


	odsov = CreateMatrixCurrency(OD, "SOV", "Rows", "Columns",)
	odpool2 = CreateMatrixCurrency(OD, "Pool2", "Rows", "Columns",)
	odpool3 = CreateMatrixCurrency(OD, "Pool3", "Rows", "Columns",)
	odcom = CreateMatrixCurrency(OD, "COM", "Rows", "Columns",)
	odmtk = CreateMatrixCurrency(OD, "MTK", "Rows", "Columns",)
	odhtk = CreateMatrixCurrency(OD, "HTK", "Rows", "Columns",)

        MatrixOperations(odsov,{pasov,trsov,eeat}, {1,1,0.30},,, {{"Operation", "Add"}, {"Force Missing", "No"}})
        MatrixOperations(odpool2,{papool2,trpool2}, {1,1},,, {{"Operation", "Add"}, {"Force Missing", "No"}})
        MatrixOperations(odpool3,{papool3,trpool3}, {1,1},,, {{"Operation", "Add"}, {"Force Missing", "No"}})
        MatrixOperations(odcom, {c1,c2,c3,c4,tc}, {0.150,0.150,0.150,0.30,0.150},,, {{"Operation", "Add"}, {"Force Missing", "No"}})
        MatrixOperations(odmtk, {m1,m2,m3,m4,tm}, {0.150,0.150,0.150,0.30,0.150},,, {{"Operation", "Add"}, {"Force Missing", "No"}})
        MatrixOperations(odhtk, {h1,h2,h3,h4,th}, {0.150,0.150,0.150,0.30,0.150},,, {{"Operation", "Add"}, {"Force Missing", "No"}})


    PA = null
    TR = null
    EEA  = null
    TCMH = null
    COM  = null
    EIC  = null
    IEC  = null
    EEC  = null
    MTK  = null
    EIM  = null
    IEM  = null
    EEM  = null
    HTK  = null
    EIH  = null
    IEH  = null
    EEH  = null
    OD = null

    pasov = null
    papool2 = null
    papool3 = null
    trsov = null
    trpool2 = null
    trpool3 = null
    eeat = null

    odsov = null
    odpool2 = null
    odpool3 = null
    odcom = null
    odmtk = null
    odhtk = null

    tc = null
    tm = null
    th = null
    c1 = null
    c2 = null
    c3 = null
    c4 = null
    m1 = null
    m2 = null
    m3 = null
    m4 = null
    h1 = null
    h2 = null
    h3 = null
    h4 = null

goto quit

badtranspose:
	msg = msg + {"TOD2_Midday - bad transpose"}
    TOD2_MiddayOK = 0         


quit:

	datentime = GetDateandTime()
	AppendToLogFile(1, "Exit TOD2_Midday: " + datentime)
	return({TOD2_MiddayOK, msg})

endmacro
