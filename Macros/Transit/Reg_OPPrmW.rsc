Macro "Reg_OPPrmW" (Args)

// Modified for new UI - Nov, 2015 - McLelland
// Commented out pkzip for skim file and delete - (lines 542+)
// 5/30/19, mk: There are now three distinct networks, use offpeak since was used to setup route system

	LogFile = Args.[Log File].value
	ReportFile = Args.[Report File].value
	SetLogFileName(LogFile)
	SetReportFileName(ReportFile)

	METDir = Args.[MET Directory].value
	Dir = Args.[Run Directory].value
	taz_file = Args.[TAZ File].value
	theyear = Args.[Run Year].value
	netname = Args.[Offpeak Hwy Name].value
		
	msg = null
	RegOPPrmWOK = 1
	datentime = GetDateandTime()
	AppendToLogFile(1, "Enter Reg_OPPrmW: " + datentime)


	shared route_file, routename, net_file, link_lyr, node_lyr

	yearnet = Substring(theyear, 3, 2)
	analysis_year = yearnet


	//	Invoke "XPR_StopFlags" macro to flag express stops as board/alight only and premium stops
	//	Enable stop access coding for modes 5 and 6 for use with TransCAD5, JainM, 07.20.08
	//	Updated for TransCad7, McLelland 09.12.16
	//	Returns 1 for clean run, 2 for warning about flags (run continues), 3 for fatal error 

    stopflagrtn = RunMacro("XPR_StopFlags", Args)
	rtnerr = stopflagrtn[1]
	rtnmsg = stopflagrtn[2]
	
	if runerr = 3 
		then goto badxpr_stopflags

	if runerr = 2
		then do
			msg = msg + {rtnmsg}
			AppendToLogFile(2, rtnmsg)
		end


	// -- Set the network names

	routename = "TranSys"

	route_file = Dir + "\\"+routename+".rts"
	net_file = Dir + "\\"+netname+".dbd"

	ModifyRouteSystem(route_file, {{"Geography", net_file, netname},{"Link ID", "ID"}})

	ID = "Key"

	// Get the scope of a geographic file

	info = GetDBInfo(net_file)
	scope = info[1]

	// Create a map using this scope
	CreateMap(net, {{"Scope", scope},{"Auto Project", "True"}})
	layers = GetDBLayers(net_file)
	node_lyr = addlayer(net, layers[1], net_file, layers[1])
	link_lyr = addlayer(net, layers[2], net_file, layers[2])
	rtelyr = AddRouteSystemLayer(net, "Vehicle Routes", route_file, )
	RunMacro("Set Default RS Style", rtelyr, "TRUE", "TRUE")
	SetLayerVisibility(node_lyr, "False")
	SetIcon(node_lyr + "|", "Font Character", "Caliper Cartographic|4", 36)
	SetIcon("Route Stops|", "Font Character", "Caliper Cartographic|4", 36)
	SetLayerVisibility(link_lyr, "True")
	solid = LineStyle({{{1, -1, 0}}})
	SetLineStyle(link_lyr+"|", solid)
	SetLineColor(link_lyr+"|", ColorRGB(0, 0, 32000))
	SetLineWidth(link_lyr+"|", 0)
	SetLayerVisibility("Route Stops", "False")

//--------------------------------- Joining Vehicle Routes and Routes -----------------------------------

on notfound default
setview("Vehicle Routes")

opentable("Routes", "DBASE", {Dir + "\\Routes.dbf",})

view_name = joinviews("Vehicle Routes+ROUTES", "[Vehicle Routes].Key", "ROUTES.KEY",)

// ----------------------------------- STEP 1: Build Transit Network  -----------------------------------

	RunMacro("TCB Init")

	Opts = RunMacro("create_tnet", "offpeak", "premium", "walk", Dir)
	ret_value = RunMacro("TCB Run Operation", 1, "Build Transit Network", Opts) 

	if !ret_value then goto badbuildtrannet

// ----------------------------------- STEP 2: Transit Network Setting  -----------------------------------

	Opts = RunMacro("set_tnet", "offpeak", "premium", "walk", Dir)
      ret_value = RunMacro("TCB Run Operation", 2, "Transit Network Setting PF", Opts)

	if !ret_value then goto badtransettings


// ----------------------------------- STEP 3: Transit Skim Path Finder  -----------------------------------


     Opts = null
     Opts.Input.Database = net_file 
     Opts.Input.Network = Dir + "\\OPprmW.tnw"
     Opts.Input.[Origin Set] = {net_file + "|" + node_lyr, node_lyr,"Centroids","Select * where centroid = 1 or [External Station] = 1"}
     Opts.Input.[Destination Set] = {net_file + "|" + node_lyr, node_lyr,"Centroids"}
     Opts.Global.[Skim Var] = {"Generalized Cost", "Fare", "In-Vehicle Time", "Initial Wait Time", "Transfer Wait Time", "Transfer Penalty Time", "Transfer Walk Time", "Access Walk Time", "Egress Walk Time", "Dwelling Time", "Number of Transfers", "In-Vehicle Distance", "Length", "BRT_Flag", "TTFrLoc*", "TTWalk*"}
     Opts.Global.[OD Layer Type] = 2
     Opts.Global.[Skim Modes] = {1, 2, 3, 4, 5, 6, 10, 11}
     Opts.Output.[Skim Matrix].Label = "Skim Matrix (Pathfinder)"
     Opts.Output.[Skim Matrix].[File Name] = Dir + "\\skims\\TR_SKIM_OPPrmW.mtx"

     ret_value = RunMacro("TCB Run Procedure", 3, "Transit Skim PF", Opts)

     if !ret_value then goto badtranskim

	// Check for local matrix cores (JWM 16.09.16) - add if necessary and initialize to null (clear)
	// 	matrix assignment ":=" please see help documentation for "Matrix Assignment Statement"

	OM = OpenMatrix(Dir + "\\skims\\TR_SKIM_OPPrmW.mtx", "True")

	matcores = GetMatrixCoreNames(OM)

	corepos = ArrayPosition(matcores, {"IVTT"},)
	if corepos = 0 then addmatrixcore(OM,"IVTT")
	c = CreateMatrixCurrency(OM, "IVTT",,,)
	c := null

	corepos = ArrayPosition(matcores, {"InVehGT5"},)
	if corepos = 0 then addmatrixcore(OM,"InVehGT5")
	c = CreateMatrixCurrency(OM, "InVehGT5",,,)
	c := null

	corepos = ArrayPosition(matcores, {"Approach"},)
	if corepos = 0 then addmatrixcore(OM,"Approach")
	c = CreateMatrixCurrency(OM, "Approach",,,)
	c := null

	corepos = ArrayPosition(matcores, {"Cost"},)
	if corepos = 0 then addmatrixcore(OM,"Cost")
	c = CreateMatrixCurrency(OM, "Cost",,,)
	c := null

	corepos = ArrayPosition(matcores, {"Highway Skim"},)
	if corepos = 0 then addmatrixcore(OM,"Highway Skim")
	c = CreateMatrixCurrency(OM, "Highway Skim",,,)
	c := null

	OM = null
	c = null


 //--- include the highway skim matrix as a part of Transit Skim Matrices

	hwyskim_matrix = Dir + "\\AutoSkims\\SPMAT_free.mtx"

	M1 = OpenMatrix(Dir+"\\skims\\TR_SKIM_OPPrmW.mtx", "True")
	M2 = OpenMatrix(hwyskim_matrix, "True")

	c1 = CreateMatrixCurrency(M2, "Non HOV Length", "Rows", "Columns",)
	c2 = CreateMatrixCurrency(M1, "Highway Skim", "RCIndex", "RCIndex",)
	MatrixOperations(c2, {c1}, {1},,, {{"Operation", "Add"}, {"Force Missing", "Yes"}})

	c1 = null
      c2 = null
      M1 = null
      M2 = null

// Compute BRT_Flag
        OM=null
	OM = OpenMatrix(Dir + "\\skims\\TR_SKIM_OPPrmW.mtx", "True")
	on notfound do
		addmatrixcore(OM,"BRT_Flag")
		goto brtflg
	end
SetMatrixCore(OM,"BRT_Flag")
brtflg:
	M1 = OpenMatrix(Dir + "\\skims\\TR_SKIM_OPPrmW.mtx", "True")
	c1 = CreateMatrixCurrency(M1, "BRT_Flag (BRT)", "RCIndex", "RCIndex",)
	c2 = CreateMatrixCurrency(M1, "BRT_Flag (XPR)", "RCIndex", "RCIndex",)
	c3 = CreateMatrixCurrency(M1, "BRT_Flag (XCM)", "RCIndex", "RCIndex",)
	c4 = CreateMatrixCurrency(M1, "BRT_Flag (SKS)", "RCIndex", "RCIndex",)
	c5 = CreateMatrixCurrency(M1, "BRT_Flag", "RCIndex", "RCIndex",)
        MatrixOperations(c5, {c1, c2, c3, c4}, {1, 1, 1, 1},,, {{"Operation", "Add"}, {"Force Missing", "No"}})
    c1 = null
    c2 = null
    c3 = null
    c4 = null
    c5 = null

    M1 = null

///////////////////////////////////
// -- path gets retained in the skims if the premium length exists and off-peak highway skim length is greater than 0.5 miles

	// Method 11 - Formula
     Opts = {{"Input",    {{"Matrix Currency",   {Dir + "\\skims\\TR_SKIM_OPPrmW.mtx",
                                                  "InVehGT5",
                                                  "RCIndex",
                                                  "RCIndex"}}}},
		             {"Global",   {{"Method",            11},
        		                   {"Cell Range",        2},
								   {"Matrix K",          {1,1}},
            		               {"Expression Text",   "if (((nz([Length (LRT)]) + nz([Length (STR)]) + nz([Length (CMR)]) + nz([Length (BRT)])) > 0.0) or [BRT_Flag] > 0) and [Highway Skim] > 0.75 then [In-Vehicle Time]"},
                          		   {"Force Missing",     "Yes"}}}}

     ret_value = RunMacro("TCB Run Operation", 9, "Fill Matrices", Opts)
     if !ret_value then goto badmatrixop


	M1 = OpenMatrix(Dir + "\\skims\\TR_SKIM_OPPrmW.mtx", "True")
	c2 = CreateMatrixCurrency(M1, "Dwelling Time", "RCIndex", "RCIndex",)
	c3 = CreateMatrixCurrency(M1, "InVehGT5", "RCIndex", "RCIndex",)
	c4 = CreateMatrixCurrency(M1, "IVTT", "RCIndex", "RCIndex",)
        MatrixOperations(c4, {c2, c3}, {1, 1},,, {{"Operation", "Add"}, {"Force Missing", "Yes"}})
    c2 = null
    c3 = null
    c4 = null
    M1 = null


	M1 = OpenMatrix(Dir + "\\skims\\TR_SKIM_OPPrmW.mtx", "True")
	c1 = CreateMatrixCurrency(M1, "Transfer Wait Time", "RCIndex", "RCIndex",)
	c2 = CreateMatrixCurrency(M1, "Transfer Walk Time", "RCIndex", "RCIndex",)
	c3 = CreateMatrixCurrency(M1, "Access Walk Time", "RCIndex", "RCIndex",)
	c4 = CreateMatrixCurrency(M1, "Egress Walk Time", "RCIndex", "RCIndex",)
	c5 = CreateMatrixCurrency(M1, "Approach", "RCIndex", "RCIndex",)
        MatrixOperations(c5, {c1, c2, c3, c4}, {1, 1, 1, 1},,, {{"Operation", "Add"}, {"Force Missing", "No"}})
    c1 = null
    c2 = null
    c3 = null
    c4 = null
    c5 = null
    M1 = null


	M1 = OpenMatrix(Dir + "\\skims\\TR_SKIM_OPPrmW.mtx", "True")
        c1 = CreateMatrixCurrency(M1, "Fare", "RCIndex", "RCIndex",)
	c2 = CreateMatrixCurrency(M1, "Cost", "RCIndex", "RCIndex",)
        MatrixOperations(c2, {c1}, {100},,, {{"Operation", "Add"}, {"Force Missing", "Yes"}})
    c1 = null
    c2 = null
    M1 = null


// Compute the mode hierarchy and populate the matrix
        OM=null
	OM = OpenMatrix(Dir + "\\skims\\TR_SKIM_OPPrmW.mtx", "True")
	on notfound do
		addmatrixcore(OM,"ModeFlag")
		goto modeflg
	end
SetMatrixCore(OM,"ModeFlag")
modeflg:
on notfound default
	//Method 11 - Formula

      Opts = {{"Input",    {{"Matrix Currency",   {Dir + "\\skims\\TR_SKIM_OPPrmW.mtx",
                                                  "ModeFlag",
                                                  "RCIndex",
                                                  "RCIndex"}}}},
			             {"Global",   {{"Method",            11},
            			               {"Cell Range",        2},
            		   				   {"Matrix K",          {1,1}},
                    			       {"Expression Text",   "if (nz([Length (CMR)])>0 and IVTT>0) then 1 else if (nz([Length (LRT)])>0  and IVTT>0) then 2 else if (nz([Length (BRT)])>0  and IVTT>0) then 3  else if (nz([BRT_Flag])>0  and IVTT>0) then 3  else if (nz([Length (STR)])>0  and IVTT>0) then 4 else null"},
                  				       {"Force Missing",     "Yes"}}}}

	ret_value = RunMacro("TCB Run Operation", 10, "Fill Matrices", Opts)
     if !ret_value then goto badmatrixop


// --- Update the ModFlag for StreetCar
// --- StreetCar Mode Flag reset to null if the length of the trip on Street Car is less than 1.2 miles 
// --  and one of the trip end is in CBD area

skim_matrix = Dir + "\\skims\\TR_SKIM_OPPrmW.mtx"

// RunMacro("Update ModeFlag", Dir, skim_matrix)

/////////////////////////////////////////////////mj


	// -- Populate the Skim Values in the Output Skim Matrix for use as an input to the Mode Split Model

	input_matrix = Dir + "\\skims\\TR_SKIM_OPPRMW.mtx"
	modesplit_matrix = Dir + "\\skims\\OFFPK_WKTRAN_SKIMS.mtx"

	
	Opts = null

     Opts.Input.[Target Currency] = { modesplit_matrix, "IVTT - Prem Walk", "Rows", "Columns"}
     Opts.Input.[Source Currencies] = {{input_matrix, "IVTT", "RCIndex", "RCIndex"}}
     Opts.Global.[Missing Option].[Force Missing] = "Yes"

     ret_value = RunMacro("TCB Run Operation", 11, "Merge Matrices", Opts) 
     if !ret_value then goto badmatrixop

//Opts = null
//
//   Opts.Input.[Target Currency] = { modesplit_matrix, "Approach - Prem Walk", "Rows", "Columns"}
//     Opts.Input.[Source Currencies] = {{input_matrix, "Approach", "RCIndex", "RCIndex"}}
//     Opts.Global.[Missing Option].[Force Missing] = "Yes"
//
//     ret_value = RunMacro("TCB Run Operation", 1, "Merge Matrices", Opts) 

Opts = null

     Opts.Input.[Target Currency] = { modesplit_matrix, "Cost - Prem Walk", "Rows", "Columns"}
     Opts.Input.[Source Currencies] = {{input_matrix, "Cost", "RCIndex", "RCIndex"}}
     Opts.Global.[Missing Option].[Force Missing] = "Yes"

     ret_value = RunMacro("TCB Run Operation", 12, "Merge Matrices", Opts) 
     if !ret_value then goto badmatrixop

//Opts = null
//
//     Opts.Input.[Target Currency] = { modesplit_matrix, "Xfers - Prem Walk", "Rows", "Columns"}
//     Opts.Input.[Source Currencies] = {{input_matrix, "Number of Transfers", "RCIndex", "RCIndex"}}
//    Opts.Global.[Missing Option].[Force Missing] = "Yes"
//
//     ret_value = RunMacro("TCB Run Operation", 1, "Merge Matrices", Opts) 

Opts = null

     Opts.Input.[Target Currency] = { modesplit_matrix, "Initial Wait - Prem Walk", "Rows", "Columns"}
     Opts.Input.[Source Currencies] = {{input_matrix, "Initial Wait Time", "RCIndex", "RCIndex"}}
     Opts.Global.[Missing Option].[Force Missing] = "Yes"

     ret_value = RunMacro("TCB Run Operation", 13, "Merge Matrices", Opts) 
     if !ret_value then goto badmatrixop

Opts = null

     Opts.Input.[Target Currency] = { modesplit_matrix, "Transfer Penalty Time - Prem Walk", "Rows", "Columns"}
     Opts.Input.[Source Currencies] = {{input_matrix, "Transfer Penalty Time", "RCIndex", "RCIndex"}}
     Opts.Global.[Missing Option].[Force Missing] = "Yes"

     ret_value = RunMacro("TCB Run Operation", 14, "Merge Matrices", Opts) 
     if !ret_value then goto badmatrixop

Opts = null

     Opts.Input.[Target Currency] = { modesplit_matrix, "Access Walk Time - Prem Walk", "Rows", "Columns"}
     Opts.Input.[Source Currencies] = {{input_matrix, "Access Walk Time", "RCIndex", "RCIndex"}}
     Opts.Global.[Missing Option].[Force Missing] = "Yes"

     ret_value = RunMacro("TCB Run Operation", 15, "Merge Matrices", Opts) 
     if !ret_value then goto badmatrixop

Opts = null

     Opts.Input.[Target Currency] = { modesplit_matrix, "Egress Walk Time - Prem Walk", "Rows", "Columns"}
     Opts.Input.[Source Currencies] = {{input_matrix, "Egress Walk Time", "RCIndex", "RCIndex"}}
     Opts.Global.[Missing Option].[Force Missing] = "Yes"

     ret_value = RunMacro("TCB Run Operation", 16, "Merge Matrices", Opts) 
     if !ret_value then goto badmatrixop

Opts = null

     Opts.Input.[Target Currency] = { modesplit_matrix, "Transfer Walk Time - Prem Walk", "Rows", "Columns"}
     Opts.Input.[Source Currencies] = {{input_matrix, "Transfer Walk Time", "RCIndex", "RCIndex"}}
     Opts.Global.[Missing Option].[Force Missing] = "Yes"

     ret_value = RunMacro("TCB Run Operation", 17, "Merge Matrices", Opts) 
     if !ret_value then goto badmatrixop

Opts = null

     Opts.Input.[Target Currency] = { modesplit_matrix, "Transfer Wait Time - Prem Walk", "Rows", "Columns"}
     Opts.Input.[Source Currencies] = {{input_matrix, "Transfer Wait Time", "RCIndex", "RCIndex"}}
     Opts.Global.[Missing Option].[Force Missing] = "Yes"

     ret_value = RunMacro("TCB Run Operation", 18, "Merge Matrices", Opts) 
     if !ret_value then goto badmatrixop

Opts = null

     Opts.Input.[Target Currency] = { modesplit_matrix, "ModeFlag", "Rows", "Columns"}
     Opts.Input.[Source Currencies] = {{input_matrix, "ModeFlag", "RCIndex", "RCIndex"}}
     Opts.Global.[Missing Option].[Force Missing] = "Yes"

     ret_value = RunMacro("TCB Run Operation", 19, "Merge Matrices", Opts) 
     if !ret_value then goto badmatrixop

// Add un-weighted total walk time, JainM, 09.20.11
Opts = null

     Opts.Input.[Target Currency] = { modesplit_matrix, "Total Walk UnWtd - Prem", "Rows", "Columns"}
     Opts.Input.[Source Currencies] = {{input_matrix, "TTWalk* (WALK)", "RCIndex", "RCIndex"}}
     Opts.Global.[Missing Option].[Force Missing] = "Yes"

     ret_value = RunMacro("TCB Run Operation", 20, "Merge Matrices", Opts) 
     if !ret_value then goto badmatrixop

// Add Premium in-vehicle time
    c1 = null
    c2 = null
    c3 = null
    c4 = null
    c5 = null

    M  = OpenMatrix(modesplit_matrix, "True")
    M1 = OpenMatrix(input_matrix, "True")

    c1 = CreateMatrixCurrency(M1, "TTFrLoc* (LRT)", "RCIndex", "RCIndex",)
    c2 = CreateMatrixCurrency(M1, "TTFrLoc* (STR)", "RCIndex", "RCIndex",)
    c3 = CreateMatrixCurrency(M1, "TTFrLoc* (CMR)", "RCIndex", "RCIndex",)
    c4 = CreateMatrixCurrency(M1, "TTFrLoc* (BRT)", "RCIndex", "RCIndex",)

    c5 = CreateMatrixCurrency(M , "Prem IVTT", "Rows", "Columns",)

    MatrixOperations(c5, {c1, c2, c3, c4}, {1, 1, 1, 0},,, {{"Operation", "Add"}, {"Force Missing", "No"}})

    c1 = null
    c2 = null
    c3 = null
    c4 = null
    c5 = null

    M=null
    M1=null

	//Method 11 - Formula
    Opts = {{"Input",    {{"Matrix Currency",   {modesplit_matrix,
                                                "PrmOnly Flag",
                                                "Rows",
                                                "Columns"}}}},
           {"Global",   {{"Method",            11},
                         {"Cell Range",        2},
                         {"Matrix K",          {1,1}},
                         {"Expression Text",   "if (nz([IVTT - Prem Walk]) > 0) then 1 else 0"},
                         {"Force Missing",     "No"}}}}

    ret_value = RunMacro("TCB Run Operation", 21, "Fill Matrices", Opts) 
    if !ret_value then goto badmatrixop

/*
    Opts = null
    Opts.Input.[Matrix Currency] = {modesplit_matrix, "PrmOnly Flag", "Rows", "Columns"}
    Opts.Input.[Formula Currencies] = {{input_matrix, "Generalized Cost", "RCIndex", "RCIndex"}}
    Opts.Global.Method = 11
    Opts.Global.[Cell Range] = 2
    Opts.Global.[Expression Text] = "if((nz([SkmMat].[In-Vehicle Distance])-nz([SkmMat].[Length (LRT)])-nz([SkmMat].[Length (CMR)]))=0 and (nz([SkmMat].[Length (LRT)]+[SkmMat].[Length (CMR)]) > 0) then 1 else 0"
    Opts.Global.[Formula Labels] = {"SkmMat"}
    Opts.Global.[Force Missing] = "No"

    ret_value = RunMacro("TCB Run Operation", 1, "Fill Matrices", Opts)
*/

closemap()

// -- archive the transit skim to save space 
goto quit
//	pkzip_program = METDir + "\\pgm\\pkzip25\\pkzip25.exe"
//	status = RunProgram(pkzip_program + " " + Dir+"\\skims\\TR_SKIM_OPPrmW.zip " +Dir+"\\skims\\TR_Skim_OPPrmW.mtx -Add",{{"Minimize", "True"}})

//	if status = 0 then DeleteFile(Dir+"\\skims\\TR_Skim_OPPrmW.mtx")


	badbuildtrannet:
	msg = msg + {"Reg_OPPrmW - Error return build transit network"}
	AppendToLogFile(1, "Reg_OPPrmW - Error return build transit network") 
	goto badquit

	badtransettings:
	msg = msg + {"Reg_OPPrmW - Error return from transit network settings"}
	AppendToLogFile(1, "Reg_OPPrmW - Error return from transit network settings") 
	goto badquit

	badtranskim:
	msg = msg + {"Reg_OPPrmW - Error return from transit network skims"}
	AppendToLogFile(1, "Reg_OPPrmW - Error return from transit network skims")
	goto badquit

	badmatrixop:
	msg = msg + {"Reg_OPPrmW - Error in matrix operations"}
	AppendToLogFile(1, "Reg_OPPrmW - Error in matrix operations")
	goto badquit

	badxpr_stopflags:
	msg = msg + {rtnmsg}
	AppendToLogFile(2, rtnmsg)
	msg = msg + {"Reg_PPrmW - Error return from XPR_StopFlags"}
	AppendToLogFile(1, "Reg_PPrmW - Error return from XPR_StopFlags")
	goto badquit


badquit:
	msg = msg + {"badquit: Last error message= " + GetLastError()}
	AppendToLogFile(2, "badquit: Last error message= " + GetLastError())
    RunMacro("TCB Closing", 0, "TRUE" ) 
	RegOPPrmWOK = 0
	goto quit
 	
quit:

    RunMacro("close everything")
	datentime = GetDateandTime()
	AppendToLogFile(1, "Exit Reg_OPPrmW: " + datentime)
	AppendToLogFile(1, " ")

	return({RegOPPrmWOK, msg})

endMacro

Macro "close everything"
    maps = GetMaps()
    if maps <> null then do
        for i = 1 to maps[1].length do
            SetMapSaveFlag(maps[1][i],"False")
        end
    end
    RunMacro("G30 File Close All")
    mtxs = GetMatrices()
    if mtxs <> null then do
        handles = mtxs[1]
        for i = 1 to handles.length do
            handles[i] = null
        end
    end
endMacro