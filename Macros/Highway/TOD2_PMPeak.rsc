Macro "TOD2_PMPeak" (Args)


//PA-AP fractions updated 10/2/13; 3+ occupancy rates derived from 2012 HHTS

	LogFile = Args.[Log File].value
	ReportFile = Args.[Report File].value
	SetLogFileName(LogFile)
	SetReportFileName(ReportFile)

	METDir = Args.[MET Directory].value
	Dir = Args.[Run Directory].value
	msg = null
	TOD2_PMPeakOK = 1

	datentime = GetDateandTime()
	AppendToLogFile(1, "Enter TOD2_PMPeak: " + datentime)

	RunMacro("TCB Init")
	
	//template matrix

	TemplateMat = null
	templatecore = null

	TemplateMat = OpenMatrix(METDir + "\\TAZ\\matrix_template.mtx", "True")
	templatecore = CreateMatrixCurrency(TemplateMat, "Table", "Rows", "Columns", )



	CopyMatrixStructure({templatecore}, {{"File Name", Dir + "\\tod2\\PAHwyVeh_PMPeak.mtx"},
	    {"Label", "PAveh_PMPeak"},
	    {"File Based", "Yes"},
	    {"Tables", {"SOV", "Pool2", "Pool3"}},
	    {"Operation", "Union"}})

	CopyMatrixStructure({templatecore}, {{"File Name", Dir + "\\tod2\\APHwyVeh_PMPeak.mtx"},
	    {"Label", "APveh_PMPeak"},
	    {"File Based", "Yes"},
	    {"Tables", {"SOV", "Pool2", "Pool3"}},
	    {"Operation", "Union"}})

	CopyMatrixStructure({templatecore}, {{"File Name", Dir + "\\tod2\\ODHwyVeh_PMPeak.mtx"},
	    {"Label", "ODveh_PMPeak"},
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
    SCH =  openmatrix(Dir + "\\TD\\tdSCH.mtx", "True")
	EIW = openmatrix(Dir + "\\TD\\tdeiw.mtx", "True")
	IEW = openmatrix(Dir + "\\TD\\tdiew.mtx", "True")
	EIN = openmatrix(Dir + "\\TD\\tdein.mtx", "True")
	IEN = openmatrix(Dir + "\\TD\\tdien.mtx", "True")

	PMPA = openmatrix(Dir + "\\tod2\\PAHwyVeh_PMPeak.mtx", "True")
	PMAP = openmatrix(Dir + "\\tod2\\APHwyVeh_PMPeak.mtx", "True")

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
	pmpa1  = CreateMatrixCurrency(PMPA, "SOV", "Rows", "Columns",)
	pmpa2  = CreateMatrixCurrency(PMPA, "Pool2", "Rows", "Columns",)
	pmpa3  = CreateMatrixCurrency(PMPA, "Pool3", "Rows", "Columns",)
	pmap1  = CreateMatrixCurrency(PMAP, "SOV", "Rows", "Columns",)
	pmap2  = CreateMatrixCurrency(PMAP, "Pool2", "Rows", "Columns",)
	pmap3  = CreateMatrixCurrency(PMAP, "Pool3", "Rows", "Columns",)
	dahbu  = CreateMatrixCurrency(HBU, "Drive Alone", "Rows", "Columns",)
	p2hbu  = CreateMatrixCurrency(HBU, "Carpool 2", "Rows", "Columns",)
	p3hbu  = CreateMatrixCurrency(HBU, "Carpool 3", "Rows", "Columns",)

//P to A and A to P percentages should be recalculated upon completion of a new External Travel Survey and/or HHTS
//Percentages are currently based on the 2012 HHTS and 2013 External Survey (nonfreeway) and 2003 External Survey (freeway)
//Calculations for internal P to A and A to P percentages are in calibration\TRIPPROP_MRM14v1.0.xls
//Caclulation for EI/IE P to A and A to P percentages are in calibration\EI_newarea_TOD2_MRM14v1.0.xls

//P to A - drive alone
        MatrixOperations(pmpa1, {dahbw,dahbo,danhb,tsch,teiw,tiew,tein,tien,dahbu}, {0.0270,0.2093,0.2899,0.0389,0.0316,0.0082,0.0403,0.0233,0.0192},,, {{"Operation", "Add"}, {"Force Missing", "No"}})

//P to A - pool 2
        MatrixOperations(pmpa2, {p2hbw,p2hbo,p2nhb,tsch,teiw,tiew,tein,tien,p2hbu}, {0.0135,0.1047,0.1450,0.0522,0.0042,0.0011,0.0205,0.0119,0.0096},,, {{"Operation", "Add"}, {"Force Missing", "No"}})

//P to A - pool 3+
        MatrixOperations(pmpa3, {p3hbw,p3hbo,p3nhb,tsch,teiw,tiew,tein,tien,p3hbu}, {0.0076,0.0586,0.0792,0.0401,0.0008,0.0002,0.0059,0.0034,0.0057},,, {{"Operation", "Add"}, {"Force Missing", "No"}})

//A to P - drive alone
        MatrixOperations(pmap1, {dahbw,dahbo,danhb,tsch,teiw,tiew,tein,tien,dahbu}, {0.4881,0.3510,0.2899,0.0165,0.1498,0.1486,0.0655,0.0612,0.4576},,, {{"Operation", "Add"}, {"Force Missing", "No"}})

//A to P - pool 2
        MatrixOperations(pmap2, {p2hbw,p2hbo,p2nhb,tsch,teiw,tiew,tein,tien,p2hbu}, {0.2441,0.1755,0.1450,0.0222,0.0200,0.0198,0.0333,0.0311,0.2288},,, {{"Operation", "Add"}, {"Force Missing", "No"}})

//A to P - pool 3+
        MatrixOperations(pmap3, {p3hbw,p3hbo,p3nhb,tsch,teiw,tiew,tein,tien,p3hbu}, {0.1372,0.0983,0.0792,0.0170,0.0036,0.0036,0.0095,0.0089,0.1363},,, {{"Operation", "Add"}, {"Force Missing", "No"}})

	HBW = null
	HBO = null
	NHB = null
        SCH = null
	EIW = null
	IEW = null
	EIN = null
	IEN = null
        HBU = null

	PMPA = null
	PMAP = null

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

	pmpa1  = null
	pmpa2  = null
        pmpa3  = null
	pmap1  = null
	pmap2  = null
        pmap3  = null


//______________________Transpose_PM_Peak_______________________________


     Opts = null
     Opts.Input.[Input Matrix] = Dir + "\\tod2\\APHwyVeh_PMPeak.mtx"
     Opts.Output.[Transposed Matrix].Label = "Transpose_PMPeak"
     Opts.Output.[Transposed Matrix].[File Name] = Dir + "\\tod2\\Transpose_PMPeak.mtx"

     ret_value = RunMacro("TCB Run Operation", 1, "Transpose Matrix", Opts)

     if !ret_value then goto badtranspose


//________OD tables:  AM Peak SOV and pool:  Sum PA and transposed matrices, 
//        Com, MTK, HTK - td tables and transposed table - use pcts of each


	PA  = openmatrix(Dir + "\\tod2\\PAHwyVeh_PMPeak.mtx", "True")
	TR  = openmatrix(Dir + "\\tod2\\Transpose_PMPeak.mtx", "True")
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

	OD  = openmatrix(Dir + "\\tod2\\ODHwyVeh_PMPeak.mtx", "True")

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
	msg = msg + {"TOD2_PMPeak - bad transpose"}
    TOD2_PMPeakOK = 0         


quit:

	datentime = GetDateandTime()
	AppendToLogFile(1, "Exit TOD2_PMPeak: " + datentime)
	return({TOD2_PMPeakOK, msg})

endmacro
