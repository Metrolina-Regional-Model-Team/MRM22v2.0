Macro "HwySkim_Free" (Args)

//Version runs GISDK Terminal_IntrazonalTT - replacing fortran Irntraterm
//build skims - same as before
//add cores (intraterm, impterm) to skims matrix
//intraterm adds intrazonal time / terminal time to intraterm matrix
//matrix will go to tdmet program, rewritten to accept matrices
//McLelland - June, 2017

//Added turn penalties to skims (highway network settings) McLelland,  Sept. 30, 2008 

//Modified for new UI , Aug 2015, McLelland

// 5/30/19, mk: There are now three distinct networks, use offpeak network for Free


	LogFile = Args.[Log File].value
	ReportFile = Args.[Report File].value
	SetLogFileName(LogFile)
	SetReportFileName(ReportFile)

	METDir = Args.[MET Directory].value
	Dir = Args.[Run Directory].value
	netview = Args.[Offpeak Hwy Name].value	// here's the only change for new networks
	msg = null
	SkimOK = 1

	datentime = GetDateandTime()
	AppendToLogFile(1, "Enter HwySkim_Free: " + datentime)

   	RunMacro("TCB Init")
			
			
	//template matrix

	TemplateMat = null
	templatecore = null

	TemplateMat = OpenMatrix(METDir + "\\TAZ\\Matrix_Template.mtx", "True")
	templatecore = CreateMatrixCurrency(TemplateMat, "Table", "Rows", "Columns", )


//Build Highway Network
	Opts = null
	Opts.Input.[Link Set] = {Dir + "\\"+netview+".DBD|"+netview, netview, "hwyskim", "Select * where (funcl > 0 and funcl < 10) or funcl =90"}
	Opts.Global.[Network Options].[Node ID] = "Node.ID"
	Opts.Global.[Network Options].[Link ID] = netview+".ID"
	Opts.Global.[Network Options].[Turn Penalties] = "Yes"
	Opts.Global.[Network Options].[Keep Duplicate Links] = "FALSE"
	Opts.Global.[Network Options].[Ignore Link Direction] = "FALSE"
	Opts.Global.[Link Options] = {{"Length", netview+".Length", netview+".Length"}, {"ImpFree*", netview+".ImpFreeAB", netview+".ImpFreeBA"}, {"ImpPk*", netview+".ImpPkAB", netview+".ImpPkBA"}, {"TTfree*", netview+".TTfreeAB", netview+".TTfreeBA"}, {"TTPkAssn*", netview+".TTPkAssnAB", netview+".TTPkAssnBA"}}
	Opts.Global.[Node Options].ID = "Node.ID"
	Opts.Output.[Network File] = Dir + "\\net_highway_op.net"

	ret_value = RunMacro("TCB Run Operation", 1, "Build Highway Network", Opts)

	if !ret_value then goto badnetbuild

//Highway Network Setting
	Opts = null
	Opts.Input.Database = Dir + "\\"+netview+".DBD"
	Opts.Input.Network = Dir + "\\net_highway_op.net"
	Opts.Input.[Centroids Set] = {Dir + "\\"+netview+".DBD|Node", "Node", "centroid", "Select * where centroid = 1 or centroid = 2"}
	Opts.Input.[Spc Turn Pen Table]= {METDir + "\\trnpnlty.bin"}
	Opts.Global.[Global Turn Penalties] = {0, 0, 0, -1}
	Opts.Input.[Toll Set]= {Dir + "\\"+netview+".DBD|"+netview, netview, "tollset", "Select * where TollAB > 0 or TollBA > 0"}
	
	ret_value = RunMacro("TCB Run Operation", 2, "Highway Network Setting", Opts)

	if !ret_value then goto notolls
	goto skipnotolls

	notolls:
	
	Opts = null
	Opts.Input.Database = Dir + "\\"+netview+".DBD"
	Opts.Input.Network = Dir + "\\net_highway_op.net"
	Opts.Input.[Centroids Set] = {Dir + "\\"+netview+".DBD|Node", "Node", "centroid", "Select * where centroid = 1 or centroid = 2"}
	Opts.Input.[Spc Turn Pen Table]= {METDir + "\\trnpnlty.bin"}
	Opts.Global.[Global Turn Penalties] = {0, 0, 0, -1}

	ret_value = RunMacro("TCB Run Operation", 3, "Highway Network Setting", Opts)
	
	if !ret_value then goto badnetsettings

//TCSPMAT FREE SPEED IMPEDANCE

	skipnotolls:

	Opts = null
	Opts.Input.Network = Dir + "\\net_highway_op.net"
	Opts.Input.[Origin Set] = {Dir + "\\"+netview+".DBD|Node", "Node", "centroid", "Select * where Centroid = 1 or centroid = 2"}
	Opts.Input.[Destination Set] = {Dir + "\\"+netview+".DBD|Node", "Node", "centroid"}
	Opts.Input.[Via Set] = {Dir + "\\"+netview+".DBD|Node", "Node"}
	Opts.Field.Minimize = "ImpFree*"
	Opts.Field.Nodes = "Node.ID"
	Opts.Field.[Skim Fields].Length = "All"
	Opts.Field.[Skim Fields].[TTfree*] = "All"
	Opts.Output.[Output Matrix].Label = "SPMAT_Free"
	Opts.Output.[Output Matrix].[File Name] = Dir + "\\Skims\\SPMAT_Free.mtx"

	ret_value = RunMacro("TCB Run Procedure", 4, "TCSPMAT", Opts)

	if !ret_value then goto badskim


//create new matrices for intrazonal + terminal times for transit and 
// total travel time (inter + intra + terminal) for distribution 

	TermIntraFile = Dir + "\\AutoSkims\\Terminal_IntraZonalTT_Free.mtx"
	CopyMatrixStructure({templatecore}, 
			{{"File Name", TermIntraFile},
			 {"Label", "IntraTerm_Free"},
 			 {"File Based", "Yes"},
			 {"Tables", {"Free"}},
			 {"Operation", "Union"}})

	TTHwyFile = Dir + "\\Skims\\TThwy_Free.mtx"
	CopyMatrixStructure({templatecore}, 
			{{"File Name", TTHwyFile},
			 {"Label", "TThwy_Free"},
			 {"File Based", "Yes"},
			 {"Tables", {"TotalTT"}},
			 {"Operation", "Union"}})


	//Call Terminal_IntrazonalTT to create file 
	SPMATFile = Dir + "\\Skims\\SPMAT_Free.mtx"
	SPMATCoreName = "TTFree* (Skim)"

//v=Vector(5,"short",)
//ShowArray(v)

	TTrtn = RunMacro("Terminal_Intrazonal_TT", Args, TermIntraFile, SPMATFile, SPMATCoreName, "Free")
	if TTrtn[1] = 0
		then goto badTermIntra
			 


	//***********************************************************************************
	// write TTHwy
	//**********************************************************************************
	IM1 = OpenMatrix(Dir + "\\Skims\\SPMAT_free.mtx", "True")
	IM2 = OpenMatrix(Dir + "\\AutoSkims\\Terminal_IntrazonalTT_Free.mtx", "True")
	OM =  Openmatrix(Dir + "\\Skims\\TThwy_Free.mtx", "True")
	ic1 = CreateMatrixCurrency(IM1, "TTFree* (Skim)", "Origin", "Destination",)
	ic2 = CreateMatrixCurrency(IM2, "Free", "Rows", "Columns",)
	oc1 = CreateMatrixCurrency(OM, "TotalTT", "Rows", "Columns",)

	MatrixOperations(oc1, {ic1, ic2}, {1,1},,, {{"Operation", "Add"}, {"Force Missing", "No"}})
	IM1 = null
	IM2 = null
	OM = null
	ic1 = null
	ic2 = null
	oc1 = null



	goto quit	


	badnetbuild:
	msg = msg + {"HwySkim_Free, Error building highway network"}
			AppendToLogFile(1, "HwySkim_Free, Error building highway network")
	SkimOK = 0
	goto TCbadquit 
 
	badnetsettings:
	msg = msg + {"HwySkim_Free, Error in highway network settings"}
			AppendToLogFile(1, "HwySkim_Free, Error in highway network settings")
	SkimOK = 0
	goto TCbadquit 

	badskim:
	msg = msg + {"HwySkim_Free, Error in highway skims"}
	AppendToLogFile(1, "HwySkim_Free, Error in highway skims")
	SkimOK = 0
	goto TCbadquit 

	TCbadquit:
	RunMacro("TCB Closing", ret_value, "TRUE" )

	badTermIntra:
	msg = msg + {TTrtn[2]}
	AppendToLogFile(1, "HwySkim_Peak, Error in terminal_intrazonal time!")
	SkimOK = 0
	goto quit 


	quit:

	ctlname = null
	exist = null
	ctlhandle = null
	ctl2name = null
	exist2 = null
	ctl2handle = null

	on error, notfound default
	datentime = GetDateandTime()
	AppendToLogFile(1, "Exit HwySkim_Free: " + datentime)
	return({SkimOK, msg})

endMacro