Macro "Tour_TOD2_Night" (Args)
 
//PA-AP fractions updated 10/2/13; 3+ occupancy rates derived from 2012 HHTS

// 1/16/18, mk: this version uses the Trip model for commercial vehicles (rewritten in GISDK in the Truck_Trip_for_Tour.rsc macro).  The outputs are identical to the trip model for CVs.

	on error goto badquit
	LogFile = Args.[Log File].value
	ReportFile = Args.[Report File].value
	SetLogFileName(LogFile)
	SetReportFileName(ReportFile)
	
	sedata_file = Args.[LandUse file].value
	Dir = Args.[Run Directory].value
	MetDir = Args.[MET Directory].value
	theyear = Args.[Run Year].value
	net_file = Args.[Hwy Name].value
	msg = null
	datentime = GetDateandTime()
	AppendToLogFile(1, "Tour TOD2_Night: " + datentime)
	RunMacro("TCB Init")

	RunMacro("G30 File Close All") 

 	yr_str = Right(theyear,2)
	yr = s2i(yr_str)
	
	//template matrix

	TemplateMat = null
	templatecore = null

	TemplateMat = OpenMatrix(MetDir + "\\taz\\matrix_template.mtx", "True")
	templatecore = CreateMatrixCurrency(TemplateMat, "Table", "Rows", "Columns", )


	CopyMatrixStructure({templatecore}, {{"File Name", Dir + "\\tod2\\ODHwyVeh_Night.mtx"},
	    {"Label", "ODveh_Night"},
	    {"File Based", "Yes"},
	    {"Tables", {"SOV", "Pool2", "Pool3", "COM", "MTK", "HTK"}},
	    {"Operation", "Union"}})


//______Peak _________________________
//    HBW, HBO, NHB from mode choice - offpeak tables
//    school, EI, IE from distribution - already in vehicles by occupancy for the 4 time periods
//

	HBW = openmatrix(Dir + "\\ModeSplit\\HBW_OFFPEAK_MS.mtx", "True")
	HBO = openmatrix(Dir + "\\ModeSplit\\HBO_OFFPEAK_MS.mtx", "True")
	NHB =  openmatrix(Dir + "\\ModeSplit\\NHB_OFFPEAK_MS.mtx", "True")
	HBU =  openmatrix(Dir + "\\ModeSplit\\HBU_OFFPEAK_MS.mtx", "True")
        SCH =  openmatrix(Dir + "\\TripTables\\SCH_NT_TRIPS.mtx", "True")
	IE = openmatrix(Dir + "\\TripTables\\IE_NT_TRIPS.mtx", "True")
	EI = openmatrix(Dir + "\\TripTables\\EI_NT_TRIPS.mtx", "True")

	NTOD = openmatrix(Dir + "\\tod2\\ODHwyVeh_Night.mtx", "True")

	dahbw  = CreateMatrixCurrency(HBW, "Drive Alone", "Rows", "Columns",)
	p2hbw  = CreateMatrixCurrency(HBW, "Carpool 2", "Rows", "Columns",)
	p3hbw  = CreateMatrixCurrency(HBW, "Carpool 3", "Rows", "Columns",)
	dahbo  = CreateMatrixCurrency(HBO, "Drive Alone", "Rows", "Columns",)
	p2hbo  = CreateMatrixCurrency(HBO, "Carpool 2", "Rows", "Columns",)
	p3hbo  = CreateMatrixCurrency(HBO, "Carpool 3", "Rows", "Columns",)
	danhb  = CreateMatrixCurrency(NHB, "Drive Alone", "Rows", "Columns",)
	p2nhb  = CreateMatrixCurrency(NHB, "Carpool 2", "Rows", "Columns",)
	p3nhb  = CreateMatrixCurrency(NHB, "Carpool 3", "Rows", "Columns",)
	dasch   = CreateMatrixCurrency(SCH, "SOV", "Rows", "Columns",)
	p2sch   = CreateMatrixCurrency(SCH, "Pool2", "Rows", "Columns",)
	p3sch   = CreateMatrixCurrency(SCH, "Pool3", "Rows", "Columns",)
	daie   = CreateMatrixCurrency(IE, "SOV", "Rows", "Columns",)
	p2ie   = CreateMatrixCurrency(IE, "Pool2", "Rows", "Columns",)
	p3ie   = CreateMatrixCurrency(IE, "Pool3", "Rows", "Columns",)
	daei   = CreateMatrixCurrency(EI, "SOV", "Rows", "Columns",)
	p2ei   = CreateMatrixCurrency(EI, "Pool2", "Rows", "Columns",)
	p3ei   = CreateMatrixCurrency(EI, "Pool3", "Rows", "Columns",)
	dahbu  = CreateMatrixCurrency(HBU, "Drive Alone", "Rows", "Columns",)
	p2hbu  = CreateMatrixCurrency(HBU, "Carpool 2", "Rows", "Columns",)
	p3hbu  = CreateMatrixCurrency(HBU, "Carpool 3", "Rows", "Columns",)
 
	ntod1  = CreateMatrixCurrency(NTOD, "SOV", "Rows", "Columns",)
	ntod2  = CreateMatrixCurrency(NTOD, "Pool2", "Rows", "Columns",)
	ntod3  = CreateMatrixCurrency(NTOD, "Pool3", "Rows", "Columns",)



//P to A and A to P percentages should be recalculated upon completion of a new External Travel Survey and/or HHTS
//Percentages are currently based on the 2012 HHTS and 2013 External Survey (nonfreeway) and 2003 External Survey (freeway)
//Calculations for internal P to A and A to P percentages are in calibration\TRIPPROP_MRM14v1.0.xls
//Caclulation for EI/IE P to A and A to P percentages are in calibration\EI_newarea_TOD2_MRM14v1.0.xls
//For Tour model, PAs and APs are combined for all purposes.  Only HBW, HBU, HBO & NHB need to be split from offpeak to NT (& MD in the MD TOD2 macro).

//Drive alone
        MatrixOperations(ntod1, {dahbw,dahbo,danhb,dasch,daei,daie,dahbu}, {0.5658,0.3627,0.1000,1.0,1.0,1.0,0.2200},,, {{"Operation", "Add"}, {"Force Missing", "No"}})

//Pool 2
        MatrixOperations(ntod2, {p2hbw,p2hbo,p2nhb,p2sch,p2ei,p2ie,p2hbu}, {0.2829,0.1814,0.0500,1.0,1.0,1.0,0.1100},,, {{"Operation", "Add"}, {"Force Missing", "No"}})

//Pool 3+
        MatrixOperations(ntod3, {p3hbw,p3hbo,p3nhb,p3sch,p3ei,p3ie,p3hbu}, {0.1590,0.1016,0.0273,1.0,1.0,1.0,0.0655},,, {{"Operation", "Add"}, {"Force Missing", "No"}})


	HBW = null
	HBO = null
	NHB = null
        SCH = null
	EIW = null
	IE = null
	EI = null

	NTOD = null

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
	dasch   = null
	p2sch   = null
	p3sch   = null
	daie   = null
	p2ie   = null
	p3ie   = null
	daei   = null
	p2ei   = null
	p3ei   = null

	ntod1  = null
	ntod2  = null
        ntod3  = null


//________OD tables:  Add EE vehicles and COM/TRUCK cores


	EEA = openmatrix(Dir + "\\tg\\tdeea.mtx", "True")
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

	OD  = openmatrix(Dir + "\\tod2\\ODHwyVeh_Night.mtx", "True")

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
	odcom = CreateMatrixCurrency(OD, "COM", "Rows", "Columns",)
	odmtk = CreateMatrixCurrency(OD, "MTK", "Rows", "Columns",)
	odhtk = CreateMatrixCurrency(OD, "HTK", "Rows", "Columns",)

        MatrixOperations(odsov,{odsov,eeat}, {1.0,0.20},,, {{"Operation", "Add"}, {"Force Missing", "No"}})
        MatrixOperations(odcom, {c1,c2,c3,c4,tc}, {0.100,0.100,0.100,0.20,0.100},,, {{"Operation", "Add"}, {"Force Missing", "No"}})
        MatrixOperations(odmtk, {m1,m2,m3,m4,tm}, {0.100,0.100,0.100,0.20,0.100},,, {{"Operation", "Add"}, {"Force Missing", "No"}})
        MatrixOperations(odhtk, {h1,h2,h3,h4,th}, {0.100,0.100,0.100,0.20,0.100},,, {{"Operation", "Add"}, {"Force Missing", "No"}})

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

    odsov = null
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

	badquit:
		on error, notfound default
		RunMacro("TCB Closing", ret_value, "TRUE" )
		msg = msg + {"Tour TOD2_Night: Error somewhere"}
		AppendToLogFile(1, "Tour TOD2_Night: Error somewhere")
		datentime = GetDateandTime()
		AppendToLogFile(1, "Tour TOD2_Night " + datentime)

       	return({0, msg})

    quit:
		on error, notfound default
   		datentime = GetDateandTime()
		AppendToLogFile(1, "Exit Tour TOD2_Night " + datentime)
    	return({1, msg})

    DestroyProgressBar()
    RunMacro("G30 File Close All")

endmacro
