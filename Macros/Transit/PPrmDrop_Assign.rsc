Macro "PPrmDrop_Assign" (Args)

	//Macro to assign Peak Premium dropoff approach trips
	//Modified for new UI, McLelland, Jan 2016
	//Modified sum of tasn_wfl fields for TC ver 7.  McLelland, Sept 2016
	// 5/30/19, mk: There are now three distinct networks: AM peak, PM peak, and offpeak; use AM for peak

	LogFile = Args.[Log File].value
	ReportFile = Args.[Report File].value
	SetLogFileName(LogFile)
	SetReportFileName(ReportFile)

	METDir = Args.[MET Directory].value
	Dir = Args.[Run Directory].value
	taz_file = Args.[TAZ File].value
	theyear = Args.[Run Year].value
	netname = Args.[AM Peak Hwy Name].value
		
	msg = null
	PPrmDropAssnOK = 1
	datentime = GetDateandTime()
	AppendToLogFile(1, "Enter PPrmDrop_Assign: " + datentime)

	RunMacro("TCB Init")

	shared route_file, routename, net_file, link_lyr, node_lyr

	yearnet = Substring(theyear, 3, 2)
	analysis_year = yearnet

//$$$$$$$$$$$$$$$$$$$

	mktsegrtn = RunMacro("Market_Segment", Args) 
	if mktsegrtn[1] = 0 
		then do
			msg = msg + mktsegrtn[2]
			goto nomktseg
		end

     OM = OpenMatrix(Dir + "\\tranassn\\Transit Assign DropOff.mtx",)
     core_list = GetMatrixCoreNames(OM)
     midx  = GetMatrixIndex(OM)

// Look for a core named "CBD Attractions"

     pos = ArrayPosition(core_list, {"CBD Attractions"}, )

// If there isn’t one, add it;
     if pos = 0 then AddMatrixCore(OM, "CBD Attractions")

// Look for a core named "NonCBD Attractions"

     pos = ArrayPosition(core_list, {"NonCBD Attractions"}, )

// If there isn’t one, add it;
     if pos = 0 then AddMatrixCore(OM, "NonCBD Attractions")

     OM=Null

     // Split trips between CBD and Non-CBD Attractions
     Opts = null
     Opts.Input.[Matrix Currency] = { Dir + "\\tranassn\\Transit Assign DropOff.mtx", "CBD Attractions",      midx[1], midx[2]}
     Opts.Input.[Core Currencies] = {{Dir + "\\tranassn\\Transit Assign DropOff.mtx", "PprmDropOff",          midx[1], midx[2]},
                                     {Dir + "\\tranassn\\Transit Assign DropOff.mtx", "CBD Attractions Flag", midx[1], midx[2]}}
     Opts.Global.Method = 9
     Opts.Global.[Cell Range] = 2
     Opts.Global.[Matrix K] = {1, 1}
     Opts.Global.[Force Missing] = "No"

     if !RunMacro("TCB Run Operation", 1, "Fill Matrices", Opts) then goto badfill

     
     Opts = null
     Opts.Input.[Matrix Currency] = { Dir + "\\tranassn\\Transit Assign DropOff.mtx", "NonCBD Attractions", midx[1], midx[2]}
     Opts.Input.[Core Currencies] = {{Dir + "\\tranassn\\Transit Assign DropOff.mtx", "PprmDropOff",        midx[1], midx[2]},
                                     {Dir + "\\tranassn\\Transit Assign DropOff.mtx", "CBD Attractions",    midx[1], midx[2]}}
     Opts.Global.Method = 8
     Opts.Global.[Cell Range] = 2
     Opts.Global.[Matrix K] = {1, 1}
     Opts.Global.[Force Missing] = "No"

     if !RunMacro("TCB Run Operation", 2, "Fill Matrices", Opts) then goto badfill

     Opts = null

     RunMacro("G30 File Close All")

//$$$$$$$$$$$$$$$$$$$


//	if taz_file = null then taz_file = ChooseFile({{"Standard", "*.dbd"}},"Specify the input TAZ layer (e.g. metrolina_taz2999.dbd", )

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


//-- Set up the network names

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

//--------------------------------- Joining Node Layer with Station Database-----------------------------------

	on notfound default
	setview(node_lyr)

	opentable("STATION_DATABASE", "DBASE", {Dir + "\\STATION_DATABASE.dbf",})

	nodes_view = joinviews("Nodes+Stations", node_lyr + ".ID", "STATION_DATABASE.ID",)


//--------------------------------- Joining Vehicle Routes and Routes -----------------------------------

	on notfound default
	setview("Vehicle Routes")

	opentable("Routes", "DBASE", {Dir + "\\Routes.dbf",})

	view_name = joinviews("Vehicle Routes+ROUTES", "[Vehicle Routes].Key", "ROUTES.KEY",)

// ----------------------------------- STEP 1: Build Transit Network  -----------------------------------


	Opts = RunMacro("create_tnet", "peak", "premium", "dropoff", Dir)
	ret_value = RunMacro("TCB Run Operation", 3, "Build Transit Network", Opts) 

	if !ret_value then goto badbuildtrannet

// ----------------------------------- STEP 2: Transit Network Setting  -----------------------------------

	Opts = RunMacro("set_tnet", "peak", "premium", "dropoff", Dir)
	tnwOpts = Opts

	ret_value = RunMacro("TCB Run Operation", 4, "Transit Network Setting PF", Opts)

	if !ret_value then goto badtransettings1


// STEP 3a: Non CBD Transit Assignment

     Opts = null
     Opts.Input.[Transit RS] = route_file
     Opts.Input.Network = Dir + "\\PprmDrop.tnw"
     Opts.Input.[OD Matrix Currency] = {Dir + "\\tranassn\\Transit Assign DropOff.mtx", "NonCBD Attractions", "Rows", "Columns"}
     Opts.Input.[From Stop Set] = {Dir+"\\"+routename+"S.DBD|Route Stops", "Route Stops", "From", "Select * where PRM_FLAG=1"}
     Opts.Input.[To Stop Set] = {Dir+"\\"+routename+"S.DBD|Route Stops", "Route Stops", "To", "Select * where PRM_FLAG=1"}
     Opts.Flag.[Report Linked Trips] = 0
     Opts.Output.[Flow Table] = Dir + "\\tranassn\\PprmDrop\\TASN_FLW.bin"
     Opts.Output.[Walk Flow Table] = Dir + "\\tranassn\\PprmDrop\\TASN_WFL.bin"
     Opts.Output.[OnOff Table] = Dir + "\\tranassn\\PprmDrop\\TASN_ONO.bin"
     Opts.Output.[Stop-stop Matrix].Label = "PprmDrop Stop-stop Matrix"
     Opts.Output.[Stop-stop Matrix].[File Name] = Dir + "\\tranassn\\PprmDrop\\TASN_S2S.mtx"

     ret_value = RunMacro("TCB Run Procedure", 5, "Transit Assignment PF", Opts)

     if !ret_value then goto badtranassn1

// STEP 3b: CBD Transit Assignment
//-- Set up the network names


//        vws = GetViewNames()
//        for i = 1 to vws.length do
//            CloseView(vws[i])
//        end

	closemap()
	RunMacro("G30 File Close All")

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

//--------------------------------- Joining Node Layer with Station Database-----------------------------------

      on notfound default
      setview(node_lyr)

      opentable("STATION_DATABASE", "DBASE", {Dir + "\\STATION_DATABASE.dbf",})

      nodes_view = joinviews("Nodes+Stations", node_lyr + ".ID", "STATION_DATABASE.ID",)


//--------------------------------- Joining Vehicle Routes and Routes -----------------------------------

     on notfound default
     setview("Vehicle Routes")

     opentable("Routes", "DBASE", {Dir + "\\Routes.dbf",})

     view_name = joinviews("Vehicle Routes+ROUTES", "[Vehicle Routes].Key", "ROUTES.KEY",)

     tnwOpts.Input.[OP Time Currency] = {Dir + "\\skims\\skim_knr_peak_noCBD.mtx", "TTPkAssn*", "Origin", "Destination"}

     ret_value = RunMacro("TCB Run Operation", 6, "Transit Network Setting PF", tnwOpts)

     if !ret_value then goto badtransettings2
  

     Opts = null
     Opts.Input.[Transit RS] = route_file
     Opts.Input.Network = Dir + "\\PprmDrop.tnw"
     Opts.Input.[OD Matrix Currency] = {Dir + "\\tranassn\\Transit Assign DropOff.mtx", "CBD Attractions", "Rows", "Columns"}
     Opts.Input.[From Stop Set] = {Dir+"\\"+routename+"S.DBD|Route Stops", "Route Stops", "From", "Select * where PRM_FLAG=1"}
     Opts.Input.[To Stop Set] = {Dir+"\\"+routename+"S.DBD|Route Stops", "Route Stops", "To", "Select * where PRM_FLAG=1"}
     Opts.Flag.[Report Linked Trips] = 0
     Opts.Output.[Flow Table] = Dir + "\\tranassn\\PprmDrop\\TASN_FLW_CBD.bin"
     Opts.Output.[Walk Flow Table] = Dir + "\\tranassn\\PprmDrop\\TASN_WFL_CBD.bin"
     Opts.Output.[OnOff Table] = Dir + "\\tranassn\\PprmDrop\\TASN_ONO_CBD.bin"
     Opts.Output.[Stop-stop Matrix].Label = "PprmDrop_CBD Stop-stop Matrix"
     Opts.Output.[Stop-stop Matrix].[File Name] = Dir + "\\tranassn\\PprmDrop\\TASN_S2S_CBD.mtx"

     ret_value = RunMacro("TCB Run Procedure", 7, "Transit Assignment PF", Opts)

     if !ret_value then goto badtranassn2

     closemap()

// Merge FLW Files
     Opts = null
     Opts.Input.[Dataview Set] = {{Dir + "\\tranassn\\PprmDrop\\TASN_FLW.bin", Dir + "\\tranassn\\PprmDrop\\TASN_FLW_CBD.bin", {"From_Stop"}, {"From_Stop"}}, "TASN_FLW+TASN_FLW_CBD"}
     Opts.Global.Fields = {"TASN_FLW.TransitFlow"}
     Opts.Global.Method = "Formula"
     Opts.Global.Parameter = "nz(TASN_FLW.TransitFlow)+nz(TASN_FLW_CBD.TransitFlow)"
   
     if !RunMacro("TCB Run Operation", 8, "Fill Dataview", Opts) then goto badfill

// Merge ONO Files
     Opts = null
     Opts.Input.[Dataview Set] = {{Dir + "\\tranassn\\PprmDrop\\TASN_ONO.bin", Dir + "\\tranassn\\PprmDrop\\TASN_ONO_CBD.bin", {"STOP"}, {"STOP"}}, "TASN_ONO+TASN_ONO_CBD"}
     Opts.Global.Fields = {"TASN_ONO.On"}
     Opts.Global.Method = "Formula"
     Opts.Global.Parameter = "nz(TASN_ONO.On)+nz(TASN_ONO_CBD.On)"
   
     if !RunMacro("TCB Run Operation", 9, "Fill Dataview", Opts) then goto badfill

     Opts = null
     Opts.Input.[Dataview Set] = {{Dir + "\\tranassn\\PprmDrop\\TASN_ONO.bin", Dir + "\\tranassn\\PprmDrop\\TASN_ONO_CBD.bin", {"STOP"}, {"STOP"}}, "TASN_ONO+TASN_ONO_CBD"}
     Opts.Global.Fields = {"TASN_ONO.Off"}
     Opts.Global.Method = "Formula"
     Opts.Global.Parameter = "nz(TASN_ONO.Off)+nz(TASN_ONO_CBD.Off)"
   
     if !RunMacro("TCB Run Operation", 10, "Fill Dataview", Opts) then goto badfill

     Opts = null
     Opts.Input.[Dataview Set] = {{Dir + "\\tranassn\\PprmDrop\\TASN_ONO.bin", Dir + "\\tranassn\\PprmDrop\\TASN_ONO_CBD.bin", {"STOP"}, {"STOP"}}, "TASN_ONO+TASN_ONO_CBD"}
     Opts.Global.Fields = {"TASN_ONO.DriveAccessOn"}
     Opts.Global.Method = "Formula"
     Opts.Global.Parameter = "nz(TASN_ONO.DriveAccessOn)+nz(TASN_ONO_CBD.DriveAccessOn)"
   
     if !RunMacro("TCB Run Operation", 11, "Fill Dataview", Opts) then goto badfill

     Opts = null
     Opts.Input.[Dataview Set] = {{Dir + "\\tranassn\\PprmDrop\\TASN_ONO.bin", Dir + "\\tranassn\\PprmDrop\\TASN_ONO_CBD.bin", {"STOP"}, {"STOP"}}, "TASN_ONO+TASN_ONO_CBD"}
     Opts.Global.Fields = {"TASN_ONO.WalkAccessOn"}
     Opts.Global.Method = "Formula"
     Opts.Global.Parameter = "nz(TASN_ONO.WalkAccessOn)+nz(TASN_ONO_CBD.WalkAccessOn)"
   
     if !RunMacro("TCB Run Operation", 12, "Fill Dataview", Opts) then goto badfill

     Opts = null
     Opts.Input.[Dataview Set] = {{Dir + "\\tranassn\\PprmDrop\\TASN_ONO.bin", Dir + "\\tranassn\\PprmDrop\\TASN_ONO_CBD.bin", {"STOP"}, {"STOP"}}, "TASN_ONO+TASN_ONO_CBD"}
     Opts.Global.Fields = {"TASN_ONO.DirectTransferOn"}
     Opts.Global.Method = "Formula"
     Opts.Global.Parameter = "nz(TASN_ONO.DirectTransferOn)+nz(TASN_ONO_CBD.DirectTransferOn)"
   
     if !RunMacro("TCB Run Operation", 13, "Fill Dataview", Opts) then goto badfill

     Opts = null
     Opts.Input.[Dataview Set] = {{Dir + "\\tranassn\\PprmDrop\\TASN_ONO.bin", Dir + "\\tranassn\\PprmDrop\\TASN_ONO_CBD.bin", {"STOP"}, {"STOP"}}, "TASN_ONO+TASN_ONO_CBD"}
     Opts.Global.Fields = {"TASN_ONO.WalkTransferOn"}
     Opts.Global.Method = "Formula"
     Opts.Global.Parameter = "nz(TASN_ONO.WalkTransferOn)+nz(TASN_ONO_CBD.WalkTransferOn)"
   
     if !RunMacro("TCB Run Operation", 14, "Fill Dataview", Opts) then goto badfill

     Opts = null
     Opts.Input.[Dataview Set] = {{Dir + "\\tranassn\\PprmDrop\\TASN_ONO.bin", Dir + "\\tranassn\\PprmDrop\\TASN_ONO_CBD.bin", {"STOP"}, {"STOP"}}, "TASN_ONO+TASN_ONO_CBD"}
     Opts.Global.Fields = {"TASN_ONO.DirectTransferOff"}
     Opts.Global.Method = "Formula"
     Opts.Global.Parameter = "nz(TASN_ONO.DirectTransferOff)+nz(TASN_ONO_CBD.DirectTransferOff)"
   
     if !RunMacro("TCB Run Operation", 15, "Fill Dataview", Opts) then goto badfill

     Opts = null
     Opts.Input.[Dataview Set] = {{Dir + "\\tranassn\\PprmDrop\\TASN_ONO.bin", Dir + "\\tranassn\\PprmDrop\\TASN_ONO_CBD.bin", {"STOP"}, {"STOP"}}, "TASN_ONO+TASN_ONO_CBD"}
     Opts.Global.Fields = {"TASN_ONO.WalkTransferOff"}
     Opts.Global.Method = "Formula"
     Opts.Global.Parameter = "nz(TASN_ONO.WalkTransferOff)+nz(TASN_ONO_CBD.WalkTransferOff)"
   
     if !RunMacro("TCB Run Operation", 16, "Fill Dataview", Opts) then goto badfill

     Opts = null
     Opts.Input.[Dataview Set] = {{Dir + "\\tranassn\\PprmDrop\\TASN_ONO.bin", Dir + "\\tranassn\\PprmDrop\\TASN_ONO_CBD.bin", {"STOP"}, {"STOP"}}, "TASN_ONO+TASN_ONO_CBD"}
     Opts.Global.Fields = {"TASN_ONO.EgressOff"}
     Opts.Global.Method = "Formula"
     Opts.Global.Parameter = "nz(TASN_ONO.EgressOff)+nz(TASN_ONO_CBD.EgressOff)"
   
     if !RunMacro("TCB Run Operation", 17, "Fill Dataview", Opts) then goto badfill
     Opts = null

// Merge WFL Files
//	Replaced field by field fill with sum all fields - field names differ in v.7  JWM Sept. 2016

	WFLnon = opentable("WFLnon", "FFB", {Dir + "\\TranAssn\\PPrmDrop\\TASN_WFL.bin",})
	SetView(WFLnon)
	WFLnonfield_array = GetFields (WFLnon, "All")
	WFLnonfld_names = WFLnonfield_array [1]

	WFLCBD = opentable("WFLCBD", "FFB", {Dir + "\\TranAssn\\PPrmDrop\\TASN_WFL_CBD.bin",})
	SetView(WFLCBD)
	WFLCBDfield_array = GetFields (WFLCBD, "All")
	WFLCBDfld_names = WFLCBDfield_array [1]

	//	Join WFLnon and WFLCBD
	WFLView = joinviews("WFLView", "WFLnon.ID1", "WFLCBD.ID1",)

	for i = 2 to WFLnonfld_names.length do
		v1 = GetDataVector("WFLView|", "WFLnon." + WFLnonfld_names[i],)
		v2 = GetDataVector("WFLView|", "WFLCBD." + WFLCBDfld_names[i],)
		v3 = v1 + v2
		SetDataVector("WFLView|", "WFLnon." + WFLnonfld_names[i], v3, )
		v1 = null
		v2 = null
		v3 = null
	end

	CloseView("WFLnon")
	CloseView("WFLCBD")
	CloseView("WFLView")


	goto quit
			
	nomktseg:
	msg = msg + {"PPrmDrop_Assign - Zero return from Market_Segment - No assignment"}
	AppendToLogFile(1, "PPrmDrop_Assign - Zero return from Market_Segment - No assignment") 
	goto badquit
			
	badfill:
	msg = msg + {"PPrmDrop_Assign - Error return from Fill Dataview - see TC_Report to determine step"}
	AppendToLogFile(1, "PPrmDrop_Assign - Error return from Fill Dataview - see TC_Report to determine step") 
	goto badquit

	badbuildtrannet:
	msg = msg + {"PPrmDrop_Assign - Error return build transit network"}
	AppendToLogFile(1, "PPrmDrop_Assign - Error return build transit network") 
	goto badquit

	badtransettings1:
	msg = msg + {"PPrmDrop_Assign - Error return from transit network settings - Non CBD"}
	AppendToLogFile(1, "PPrmDrop_Assign - Error return from transit network settings - Non CBD") 
	goto badquit

	badtranassn1:
	msg = msg + {"PPrmDrop_Assign - Error return from transit network skims - Non CBD"}
	AppendToLogFile(1, "PPrmDrop_Assign - Error return from transit network skims - Non CBD")
	goto badquit

	badtransettings2:
	msg = msg + {"PPrmDrop_Assign - Error return from transit network settings - CBD"}
	AppendToLogFile(1, "PPrmDrop_Assign - Error return from transit network settings - CBD") 
	goto badquit

	badtranassn2:
	msg = msg + {"PPrmDrop_Assign - Error return from transit network skims - CBD"}
	AppendToLogFile(1, "PPrmDrop_Assign - Error return from transit network skims - CBD")
	goto badquit

	badxpr_stopflags:
	msg = msg + {rtnmsg}
	AppendToLogFile(2, rtnmsg)
	msg = msg + {"PPrmDrop_Assign - Error return from XPR_StopFlags"}
	AppendToLogFile(1, "PPrmDrop_Assign - Error return from XPR_StopFlags")
	goto badquit

	badquit:
	msg = msg + {"badquit: Last error message= " + GetLastError()}
	AppendToLogFile(2, "badquit: Last error message= " + GetLastError())
	RunMacro("TCB Closing", 0, "TRUE" ) 
	PPrmDropAssnOK = 0
	goto quit
 	
	quit:
	
	datentime = GetDateandTime()
	AppendToLogFile(1, "Exit PPrmDrop_Assign: " + datentime)
	AppendToLogFile(1, " ")

	return({PPrmDropAssnOK, msg})

endMacro	
