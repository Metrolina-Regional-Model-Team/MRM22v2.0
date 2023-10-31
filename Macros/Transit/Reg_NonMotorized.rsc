Macro "Reg_NonMotorized" (Args) 

//Non-motorized skims = walk and bike 
// McLelland - Sept, 2015
// 5/30/19, mk: There are now three distinct networks, use offpeak for Nonmotorized

	LogFile = Args.[Log File].value
	ReportFile = Args.[Report File].value
	SetLogFileName(LogFile)
	SetReportFileName(ReportFile)

	METDir = Args.[MET Directory].value
	Dir = Args.[Run Directory].value
	theyear = Args.[Run Year].value
	yearnet = right(theyear,2)
	netname = Args.[Offpeak Hwy Name].value
	msg = null
	RegNonMotorizedOK = 1

	datentime = GetDateandTime()
	AppendToLogFile(1, "Enter Reg_NonMotorized: " + datentime)

	analysis_year = yearnet

	routename = "TranSys"

	ID = "Key"

	// Get the scope of a geographic file

	info = GetDBInfo(Dir + "\\"+netname+".dbd")
	scope = info[1]

	// Create a map using this scope
	CreateMap(net, {{"Scope", scope},{"Auto Project", "True"}})

	file = Dir + "\\"+netname+".dbd"
	layers = GetDBLayers(file)
	addlayer(net, "Node", file, layers[1])
	link_layer = addlayer(net, netname, file, layers[2])
	rtelyr = AddRouteSystemLayer(net, "Vehicle Routes", Dir + "\\" + routename + ".rts", )
	RunMacro("Set Default RS Style", rtelyr, "TRUE", "TRUE")
	SetLayerVisibility("Node", "False")
	SetIcon("Node|", "Font Character", "Caliper Cartographic|4", 36)
	SetIcon("Route Stops|", "Font Character", "Caliper Cartographic|4", 36)
	SetLayerVisibility(link_layer, "True")
	solid = LineStyle({{{1, -1, 0}}})
	SetLineStyle(link_layer+"|", solid)
	SetLineColor(link_layer+"|", ColorRGB(0, 0, 32000))
	SetLineWidth(link_layer+"|", 0)
	SetLayerVisibility("Route Stops", "False")

	setview(link_layer)

	walk_links = "Select * where TTWalkAB <> NULL"
	SelectByQuery("WalkApproach", "Several", walk_links,)

	CreateNetwork("", Dir + "\\NonMotorized.net", "Nonmotorized", {
		{"Length", link_layer+".length"},
		{"TTWalk*", link_layer+".TTWalkAB", link_layer+".TTWalkBA"},
		{"TTBike*", link_layer+".TTBikeAB", link_layer+".TTBikeBA"}},,)

	setview("Node")

   RunMacro("TCB Init")

// STEP 1: Walk Skims - Walk Skims

    Opts = {{"Input",    {{"Network",           Dir + "\\Nonmotorized.net"},
                           {"Origin Set",        {Dir + "\\"+netname+".DBD|Node",
                                                  "Node",
                                                  "centroids",
                                                  "Select * where centroid = 1 or [External Station] = 1"}},
                          {"Destination Set",   {Dir + "\\"+netname+".DBD|Node",
                                                  "Node",
                                                  "centroids",
                                                  "Select * where centroid = 1 or [External Station] = 1"}},
                           {"Via Set",           {Dir + "\\"+netname+".DBD|Node",
                                                  "Node"}}}},
             {"Field",    {{"Minimize",          "TTwalk*"},
                           {"Nodes",             "Node.ID"},
                           {"Skim Fields",       {{"Length",
                                                  "All"}}}}},
             {"Output",   {{"Output Matrix",     {{"Label",
                                                  "Walk Skims"},
                                                  {"File Name",
                                                  Dir + "\\Skims\\TR_Walk.mtx"}}}}}}

     ret_value = RunMacro("TCB Run Procedure", 1, "TCSPMAT", Opts)

     if !ret_value then goto badquit

// STEP 2: Bike Skims

    Opts = {{"Input",    {{"Network",           Dir + "\\Nonmotorized.net"},
                           {"Origin Set",        {Dir + "\\"+netname+".DBD|Node",
                                                  "Node",
                                                  "centroids",
                                                  "Select * where centroid = 1 or [External Station] = 1"}},
                          {"Destination Set",   {Dir + "\\"+netname+".DBD|Node",
                                                  "Node",
                                                  "centroids",
                                                  "Select * where centroid = 1 or [External Station] = 1"}},
                           {"Via Set",           {Dir + "\\"+netname+".DBD|Node",
                                                  "Node"}}}},
             {"Field",    {{"Minimize",          "TTBike*"},
                           {"Nodes",             "Node.ID"},
                           {"Skim Fields",       {{"Length",
                                                  "All"}}}}},
             {"Output",   {{"Output Matrix",     {{"Label",
                                                  "Bike Skims"},
                                                  {"File Name",
                                                  Dir + "\\Skims\\TR_Bike.mtx"}}}}}}

     ret_value = RunMacro("TCB Run Procedure", 2, "TCSPMAT", Opts)

     if !ret_value then goto badquit

// STEP 3: Combine Matrix Files
  

	on error do
		msg = msg + {"Reg_NonMotorized: taz\\matrix_template.mtx not found.  Please run Create Matrix Template"}
		AppendToLogFile(1, "Reg_NonMotorized: taz\\matrix_template.mtx not found.  Please run Create Matrix Template")
	    RegNonMotorizedOK = 0
	end

// --- Copy TR_NonMotorized Matrix from the Template Directory

	OM = OpenMatrix(METDir + "\\taz\\matrix_template.mtx", "True")
	mc1 = CreateMatrixCurrency(OM, "Table", "Rows", "Columns", )
	on error default
	CopyMatrixStructure({mc1}, {{"File Name", Dir+"\\Skims\\TR_NonMotorized.MTX"},
	    {"Label", "Non Motorized"},
	    {"File Based", "Yes"},
	    {"Tables", {"TTWalk*", "TTBike*"}},
	    {"Operation", "Union"}})
	OM=null
	mc1=null

	 M = OpenMatrix(Dir + "\\Skims\\TR_NonMotorized.mtx", "True")
	M1 = OpenMatrix(Dir + "\\Skims\\TR_Walk.mtx", "True")
	M2 = OpenMatrix(Dir + "\\Skims\\TR_Bike.mtx", "True")
        
        midx=getmatrixindex(M)
        midx1=getmatrixindex(M1)
        midx2=getmatrixindex(M2)
        
        mc1= CreateMatrixCurrency(M, "TTWalk*", midx[1], midx[2],)
        mc2= CreateMatrixCurrency(M, "TTBike*", midx[1], midx[2],)
        
        c11 = CreateMatrixCurrency(M1, "TTWalk*", midx1[1], midx1[2],)
        c12 = CreateMatrixCurrency(M2, "TTBike*", midx2[1], midx2[2],)

        MatrixOperations(mc1, {c11}, {1},,, {{"Operation", "Add"}, {"Force Missing", "Yes"}})
        MatrixOperations(mc2, {c12}, {1},,, {{"Operation", "Add"}, {"Force Missing", "Yes"}})

	mc1 = null
	mc2 = null
	c11 = null
	c12 = null
	M=null
	M1=null
	M2=null


	CloseMap()
	goto quit

	badquit:
    RunMacro("TCB Closing", 0, "TRUE" ) 
	RunMacro("G30 File Close All")
	RegNonMotorizedOK = 0
	
    quit:

	datentime = GetDateandTime()
	AppendToLogFile(1, "Exit Reg_NonMotorized: " + datentime)
	AppendToLogFile(1, " ")

	return({RegNonMotorizedOK, msg})


endMacro

