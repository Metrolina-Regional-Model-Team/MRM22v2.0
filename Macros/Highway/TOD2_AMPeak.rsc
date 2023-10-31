Macro "TOD2_AMPeak" (Args)
 
//PA-AP fractions updated 10/2/13; 3+ occupancy rates derived from 2012 HHTS
//Modified for new UI , Aug 2015, McLelland

	LogFile = Args.[Log File].value
	ReportFile = Args.[Report File].value
	SetLogFileName(LogFile)
	SetReportFileName(ReportFile)

	METDir = Args.[MET Directory].value
	Dir = Args.[Run Directory].value

	curiter = Args.[Current Feedback Iter].value
	TOD2_AMPeakOK = 1
	msg = null

	datentime = GetDateandTime()
	AppendToLogFile(1, "Enter TOD2_AMPeak: " + datentime)
	AppendToLogFile(2, "AM Peak feedback iteration: " + i2s(curiter))

	RunMacro("TCB Init")
	
	//template matrix

	TemplateMat = null
	templatecore = null

	TemplateMat = OpenMatrix(METDir + "\\TAZ\\matrix_template.mtx", "True")
	templatecore = CreateMatrixCurrency(TemplateMat, "Table", "Rows", "Columns", )



	CopyMatrixStructure({templatecore}, {{"File Name", Dir + "\\tod2\\PAHwyVeh_AMPeak.mtx"},
	    {"Label", "PAveh_AMPeak"},
	    {"File Based", "Yes"},
	    {"Tables", {"SOV", "Pool2", "Pool3"}},
	    {"Operation", "Union"}})

	CopyMatrixStructure({templatecore}, {{"File Name", Dir + "\\tod2\\APHwyVeh_AMPeak.mtx"},
	    {"Label", "APveh_AMPeak"},
	    {"File Based", "Yes"},
	    {"Tables", {"SOV", "Pool2", "Pool3"}},
	    {"Operation", "Union"}})


	CopyMatrixStructure({templatecore}, {{"File Name", Dir + "\\tod2\\ODHwyVeh_AMPeak.mtx"},
	    {"Label", "ODveh_AMPeak"},
	    {"File Based", "Yes"},
	    {"Tables", {"SOV", "Pool2", "Pool3", "COM", "MTK", "HTK"}},
	    {"Operation", "Union"}})


//______Peak _________________________
//    HBW, HBO, NHB from mode choice - peak tables
//    school, EIW, EIN, IEW, IEN from distribution - use factors to apply VOR
//


	HBW = openmatrix(Dir + "\\ModeSplit\\HBW_PEAK_MS.mtx", "True")
	HBO = openmatrix(Dir + "\\ModeSplit\\HBO_PEAK_MS.mtx", "True")
	NHB =  openmatrix(Dir + "\\ModeSplit\\NHB_PEAK_MS.mtx", "True")
	HBU =  openmatrix(Dir + "\\ModeSplit\\HBU_PEAK_MS.mtx", "True")
        SCH =  openmatrix(Dir + "\\td\\tdSCH.mtx", "True")
	EIW = openmatrix(Dir + "\\td\\tdeiw.mtx", "True")
	IEW = openmatrix(Dir + "\\td\\tdiew.mtx", "True")
	EIN = openmatrix(Dir + "\\td\\tdein.mtx", "True")
	IEN = openmatrix(Dir + "\\td\\tdien.mtx", "True")

	AMPA = openmatrix(Dir + "\\tod2\\PAHwyVeh_AMPeak.mtx", "True")
	AMAP = openmatrix(Dir + "\\tod2\\APHwyVeh_AMPeak.mtx", "True")

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
 
	ampa1  = CreateMatrixCurrency(AMPA, "SOV", "Rows", "Columns",)
	ampa2  = CreateMatrixCurrency(AMPA, "Pool2", "Rows", "Columns",)
	ampa3  = CreateMatrixCurrency(AMPA, "Pool3", "Rows", "Columns",)
	amap1  = CreateMatrixCurrency(AMAP, "SOV", "Rows", "Columns",)
	amap2  = CreateMatrixCurrency(AMAP, "Pool2", "Rows", "Columns",)
	amap3  = CreateMatrixCurrency(AMAP, "Pool3", "Rows", "Columns",)

//P to A and A to P percentages should be recalculated upon completion of a new External Travel Survey and/or HHTS
//Percentages are currently based on the 2012 HHTS and 2013 External Survey (nonfreeway) and 2003 External Survey (freeway)
//Calculations for internal P to A and A to P percentages are in calibration\TRIPPROP_MRM14v1.0.xls
//Caclulation for EI/IE P to A and A to P percentages are in calibration\EI_newarea_TOD2_MRM14v1.0.xls

//P to A - drive alone
        MatrixOperations(ampa1, {dahbw,dahbo,danhb,tsch,teiw,tiew,tein,tien,dahbu}, {0.4730,0.2907,0.2101,0.0289,0.1794,0.2318,0.0455,0.0478,0.4808},,, {{"Operation", "Add"}, {"Force Missing", "No"}})

//P to A - pool 2
        MatrixOperations(ampa2, {p2hbw,p2hbo,p2nhb,tsch,teiw,tiew,tein,tien,p2hbu}, {0.2365,0.1454,0.1051,0.0388,0.0240,0.0309,0.0231,0.0243,0.2404},,, {{"Operation", "Add"}, {"Force Missing", "No"}})

//P to A - pool 3+
        MatrixOperations(ampa3, {p3hbw,p3hbo,p3nhb,tsch,teiw,tiew,tein,tien,p3hbu}, {0.1329,0.0814,0.0574,0.0298,0.0044,0.0056,0.0066,0.0069,0.1432},,, {{"Operation", "Add"}, {"Force Missing", "No"}})

//A to P - drive alone
        MatrixOperations(amap1, {dahbw,dahbo,danhb,tsch,teiw,tiew,tein,tien,dahbu}, {0.0119,0.1490,0.2101,0.0513,0.0202,0.0201,0.0079,0.0074,0.0424},,, {{"Operation", "Add"}, {"Force Missing", "No"}})

//A to P - pool 2
        MatrixOperations(amap2, {p2hbw,p2hbo,p2nhb,tsch,teiw,tiew,tein,tien,p2hbu}, {0.0060,0.0745,0.1051,0.0688,0.0027,0.0027,0.0040,0.0038,0.0212},,, {{"Operation", "Add"}, {"Force Missing", "No"}})

//A to P - pool 3+ 
        MatrixOperations(amap3, {p3hbw,p3hbo,p3nhb,tsch,teiw,tiew,tein,tien,p3hbu}, {0.0033,0.0417,0.0574,0.0529,0.0005,0.0005,0.0011,0.0011,0.0126},,, {{"Operation", "Add"}, {"Force Missing", "No"}})


	HBW = null
	HBO = null
	NHB = null
        SCH = null
	EIW = null
	IEW = null
	EIN = null
	IEN = null
        HBU = null

	AMPA = null
	AMAP = null

	dahbw  = null
	p2hbw  = null
	p3hbw  = null
	dahbo  = null
	p2hbo  = null
	p3hbo  = null
	dahbo  = null
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

	ampa1  = null
	ampa2  = null
        ampa3  = null
	amap1  = null
	amap2  = null
        amap3  = null



//transpose AP matrices 

//___________________Transpose_AM_Peak____________________________________


     Opts = null
     Opts.Input.[Input Matrix] = Dir + "\\tod2\\APHwyVeh_AMPeak.mtx"
     Opts.Output.[Transposed Matrix].Label = "Transpose_AMPeak"
     Opts.Output.[Transposed Matrix].[File Name] = Dir + "\\tod2\\Transpose_AMPeak.mtx"

     ret_value = RunMacro("TCB Run Operation", 1, "Transpose Matrix", Opts)

     if !ret_value then goto badtranspose


//________OD tables:  AM Peak SOV and pool:  Sum PA and transposed matrices, 
//        Com, MTK, HTK - td tables and transposed table - use pcts of each


	PA  = openmatrix(Dir + "\\tod2\\PAHwyVeh_AMPeak.mtx", "True")
	TR  = openmatrix(Dir + "\\tod2\\Transpose_AMPeak.mtx", "True")
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

	OD  = openmatrix(Dir + "\\tod2\\ODHwyVeh_AMPeak.mtx", "True")

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

        MatrixOperations(odsov,{pasov,trsov,eeat}, {1,1,0.25},,, {{"Operation", "Add"}, {"Force Missing", "No"}})
        MatrixOperations(odpool2,{papool2,trpool2}, {1,1},,, {{"Operation", "Add"}, {"Force Missing", "No"}})
        MatrixOperations(odpool3,{papool3,trpool3}, {1,1},,, {{"Operation", "Add"}, {"Force Missing", "No"}})
        MatrixOperations(odcom, {c1,c2,c3,c4,tc}, {0.125,0.125,0.125,0.25,0.125},,, {{"Operation", "Add"}, {"Force Missing", "No"}})
        MatrixOperations(odmtk, {m1,m2,m3,m4,tm}, {0.125,0.125,0.125,0.25,0.125},,, {{"Operation", "Add"}, {"Force Missing", "No"}})
        MatrixOperations(odhtk, {h1,h2,h3,h4,th}, {0.125,0.125,0.125,0.25,0.125},,, {{"Operation", "Add"}, {"Force Missing", "No"}})

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

	msg = msg + {"TOD2_AMPeak - bad transpose"}
    TOD2_AMPeakOK = 0         


quit:

	datentime = GetDateandTime()
	AppendToLogFile(1, "Exit TOD2_AMPeak: " + datentime)
	return({TOD2_AMPeakOK, msg})

endmacro
