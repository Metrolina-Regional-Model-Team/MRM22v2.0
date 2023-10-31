Macro "Transit_Pax_Stats" (Args)
// Generate Report\\RouteOut.dbf - Passenger hours and passenger miles

	Dir = Args.[Run Directory].value
	LogFile = Args.[Log File].value
	SetLogFileName(LogFile)

	msg = null
	TransitPaxOK = 1
	datentime = GetDateandTime()
	AppendToLogFile(1, "Enter Transit_Pax_Stats: " + datentime)


	on error default

//_____________________________________________________________________
//	Add Passenger Hours and Passenger Miles fields to TASN_FLW tables 

	PathArray = {"PPrmW",  "PPrmD",  "PPrmDrop",  "PBusW",  "PBusD",  "PBusDrop",
	            "OPPrmW", "OPPrmD", "OPPrmDrop", "OPBusW", "OPBusD", "OPBusDrop"}

	vws = GetViewNames()
	for i = 1 to vws.length do
		CloseView(vws[i])
	end

	for p = 1 to PathArray.length do
	
		on notfound goto badpath1
		path = PathArray[p]
		view_name = OPenTable ("TASN_FLW","FFB",{Dir + "\\tranassn\\"+path+"\\TASN_FLW.bin"})

		on notfound goto PHcalc
		getfield(view_name+".PH")
		goto PM

		PHcalc:
		// Add a field for Passenger Hours -  PprmW FLow Table
		strct = GetTableStructure(view_name)
		for i = 1 to strct.length do
			strct[i] = strct[i] + {strct[i][1]}
		end
		new_struct = strct + {{"PH", "Real", 10, 2, "False",,,, null}}
		ModifyTable(view_name, new_struct)

		PM:
		on notfound goto PMcalc
		getfield(view_name+".PM")
		goto nextpath1

		PMcalc:
		// Add a field for Passenger Miles, PprmW FLow Table 
		strct = GetTableStructure(view_name)
		for i = 1 to strct.length do
			strct[i] = strct[i] + {strct[i][1]}
		end
		new_struct = strct + {{"PM", "Real", 10, 2, "False",,,, null}}
		ModifyTable(view_name, new_struct)

		CloseView(view_name)
		goto nextpath1
		
		badpath1:
		msg = msg + {"Transit_Pax_Stats-WARNING - Missing File " + PathArray[i] + "\\TASN_FLW.bin"}
		AppendToLogFile(2, "Transit_Pax_Stats-WARNING - Missing File " + PathArray[i] + "\\TASN_FLW.bin")

		nextpath1:
	end // for i 


	//	Open route system - join routes.dbf

	routename = "TranSys"

	route_file = Dir + "\\"+routename+".rts"

	// --- get the name of the line layer

	info = GetRouteSystemInfo(route_file)
	netname = info[2]

	net_file = Dir + "\\"+netname+".dbd"

	view = "TranSys"
	ID = "KEY"

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

	setview("Vehicle Routes")

	opentable("Routes", "DBASE", {Dir + "\\ROUTES.dbf",})

	joinviews("Vehicle Routes+ROUTES", "[Vehicle Routes].key" , "ROUTES.KEY",)

	closemap()


	//Fill the passenger miles and passenger hours fields

	//PprmW Passenger Hours
	RunMacro("TCB Init")

	vws = GetViewNames()
	for i = 1 to vws.length do
		CloseView(vws[i])
	end

	// PathArray - list of Paths - line 11
	for i = 1 to PathArray.length do
	
		path = PathArray[i]
		on notfound goto badpath2

    	view_name = OpenTable ("TASN_FLW","FFB",{Dir + "\\tranassn\\"+path+"\\TASN_FLW.bin"})

			Opts = null
			Opts.Input.[Dataview Set] = {Dir + "\\tranassn\\"+path+"\\TASN_FLW.bin", "TASN_FLW"}
			Opts.Global.Fields = {view_name + ".PH"}
			Opts.Global.Method = "Formula"
			Opts.Global.Parameter =  "((BaseIVTT)/60)*TransitFLOW"

		ret_value = RunMacro("TCB Run Operation", i*2-1, "Fill Dataview", Opts)
		if !ret_value then goto badfilltasnflow

		//PprmW Passenger Miles
			Opts = null
			Opts.Input.[Dataview Set] = {Dir + "\\tranassn\\"+path+"\\TASN_FLW.bin", "TASN_FLW"}
			Opts.Global.Fields = {view_name + ".PM"}
			Opts.Global.Method = "Formula"
			Opts.Global.Parameter =  "((TO_MP-FROM_MP)*TransitFLOW)"

		ret_value = RunMacro("TCB Run Operation", i*2, "Fill Dataview", Opts)
		if !ret_value then goto badfilltasnflow

		CloseView(view_name)
		goto nextpath2

		badpath2:
		msg = msg + {"Transit_Pax_Stats-WARNING - Missing File " + path + "\\TASN_FLW.bin"}
		AppendToLogFile(2, "Transit_Pax_Stats-WARNING - Missing File " + path + "\\TASN_FLW.bin")


		nextpath2:
		
	end // for i 
	

//---- Create RouteOut File - open transit rts and join to ROUTES.dbf

	view = "TranSys"
	ID = "KEY"

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

	setview("Vehicle Routes")

	opentable("Routes", "DBASE", {Dir + "\\ROUTES.dbf",})

	joinviews("Vehicle Routes+ROUTES", "[Vehicle Routes].key" , "Routes.KEY",)
	

	query = "Select * where ALT_FLAG = 1"
	n_select = SelectByQuery("Selection", "Several", query,)

	ExportView("Vehicle Routes+ROUTES|Selection", "DBASE", Dir + "\\Report\\RouteOut.DBF", {"Route_ID", "Routes.Key" , "Track", "RTE_Name", "Time", "Distance", "IO", "Rtecomb", "Corr", "MODE", "DWELL", "Routes.COMPANY", "AM_HEAD", "MID_HEAD", "PM_HEAD", "NIGHT_HEAD"},
			{{"Additional Fields",{
			 {"NUMSTOP", "Integer", 11, , "False"},
			 {"PASS", "Real", 10, 2, "False"},
			 {"PASSHOUR", "Real", 10, 2, "False"},
			 {"PASSMILE", "Real", 10, 2, "False"},
			 {"PPRMW_PASS", "Real", 10, 2, "False"},
			 {"PPRMW_PM", "Real", 10, 2, "False"},
			 {"PPRMW_PH", "Real", 10, 2, "False"},
			 {"PBUSW_PASS", "Real", 10, 2, "False"},
			 {"PBUSW_PM", "Real", 10, 2, "False"},
			 {"PBUSW_PH", "Real", 10, 2, "False"},
			 {"PPRMD_PASS", "Real", 10, 2, "False"},
			 {"PPRMD_PM", "Real", 10, 2, "False"},
			 {"PPRMD_PH", "Real", 10, 2, "False"},
			 {"PBUSD_PASS", "Real", 10, 2, "False"},
			 {"PBUSD_PM", "Real", 10, 2, "False"},
			 {"PBUSD_PH", "Real", 10, 2, "False"},
			 {"OPPRMW_PAS", "Real", 10, 2, "False"},
			 {"OPPRMW_PM", "Real", 10, 2, "False"},
			 {"OPPRMW_PH", "Real", 10, 2, "False"},
			 {"OPBUSW_PAS", "Real", 10, 2, "False"},
			 {"OPBUSW_PM", "Real", 10, 2, "False"},
			 {"OPBUSW_PH", "Real", 10, 2, "False"},
			 {"OPPRMD_PAS", "Real", 10, 2, "False"},
			 {"OPPRMD_PM", "Real", 10, 2, "False"},
			 {"OPPRMD_PH", "Real", 10, 2, "False"},
			 {"OPBUSD_PAS", "Real", 10, 2, "False"},
			 {"OPBUSD_PM", "Real", 10, 2, "False"},
			 {"OPBUSD_PH", "Real", 10, 2, "False"},
			 {"PPRMDO_PAS", "Real", 10, 2, "False"},
			 {"PPRMDO_PM", "Real", 10, 2, "False"},
			 {"PPRMDO_PH", "Real", 10, 2, "False"},
			 {"PBUSDO_PAS", "Real", 10, 2, "False"},
			 {"PBUSDO_PM", "Real", 10, 2, "False"},
			 {"PBUSDO_PH", "Real", 10, 2, "False"},
			 {"OPPRMDO_PA", "Real", 10, 2, "False"},
			 {"OPPRMDO_PM", "Real", 10, 2, "False"},
			 {"OPPRMDO_PH", "Real", 10, 2, "False"},
			 {"OPBUSDO_PA", "Real", 10, 2, "False"},
			 {"OPBUSDO_PM", "Real", 10, 2, "False"},
			 {"OPBUSDO_PH", "Real", 10, 2, "False"}}}}
)

//__________________________________________________________________________________

	SetLayerVisibility("Route Stops", "True")

	setview("Route Stops")

	opentable("Routeout", "DBASE", {Dir + "\\Report\\RouteOut.dbf",})

	stopaggr = {{"STOP",{{"Sum"}}}}

	joinviews("Routeout+Route Stops", "[Routeout].Route_ID", "Route Stops.Route_ID",{{"A",},{"Fields", stopaggr}})
	v1 = GetDataVector("Routeout+Route Stops|", "STOP",{{"Missing as Zero", "True"}})
	SetDataVector("Routeout+Route Stops|", "NUMSTOP", v1, )
	v1 = null
	closeview("Routeout+Route Stops")
	closemap()


	// Sum ONs from TASN_ONO - Array PassCol contains field names of routeout table
	PassCol = {"PPrmW_PASS", "PPrmD_PASS", "PPrmDO_PAS", "PBusW_PASS", "PBusD_PASS", "PBusDO_PAS",
			 "OPPrmW_PAS", "OPPrmD_PAS", "OPPrmDO_PA", "OPBusW_PAS", "OPBusD_PAS", "OPBusDO_PA"}

	for p = 1 to PathArray.length do

		on notfound goto badpath3

		path = PathArray[p]
		opentable(path, "FFB", {Dir + "\\tranassn\\"+path+"\\TASN_ONO.bin",})
		onaggr = {{"ON",{{"Sum"}}}}
		joinviews("Routeout+"+path, "[Routeout].Route_ID", path+".Route",{{"A",},{"Fields", onaggr}})
		closeview(path)

		v1 = GetDataVector("Routeout+"+path+"|", "ON", {{"Missing as Zero", "True"}})
		SetDataVector("Routeout+"+path+"|", PassCol[p], v1, )
		v1 = null

		goto nextpath3

		badpath3:
		msg = msg + {"Transit_Pax_Stats-WARNING - Missing File " + path + "\\TASN_ONO.bin"}
		AppendToLogFile(2, "Transit_Pax_Stats-WARNING - Missing File " + path + "\\TASN_ONO.bin")

		nextpath3:
		CloseView("Routeout+"+path)
	end // for i


	// Fill RouteOut Pass Mile and Pass Hour fields from TASN_FLW (_PH and _PM created above)
	// Array PHCol and PMCol contains field names of routeout table
	PHCol = {"PPrmW_PH", "PPrmD_PH", "PPrmDO_PH", "PBusW_PH", "PBusD_PH", "PBusDO_PH",
		    "OPPrmW_PH", "OPPrmD_PH", "OPPrmDO_PH", "OPBusW_PH", "OPBusD_PH", "OPBusDO_PH"}

	PMCol = {"PPrmW_PM", "PPrmD_PM", "PPrmDO_PM", "PBusW_PM", "PBusD_PM", "PBusDO_PM",
		    "OPPrmW_PM", "OPPrmD_PM", "OPPrmDO_PM", "OPBusW_PM", "OPBusD_PM", "OPBusDO_PM"}


	for p = 1 to PathArray.length do

		on notfound goto badpath4

		path = PathArray[p]
		opentable(path, "FFB", {Dir + "\\tranassn\\"+path+"\\TASN_FLW.bin",})
		onaggr = {{"PM",{{"Sum"}}},{"PH",{{"Sum"}}}}
		joinviews("Routeout+"+path, "[Routeout].Route_ID", path+".Route",{{"A",},{"Fields", onaggr}})
		closeview(path)

		v1 = GetDataVector("Routeout+"+path+"|", "PH", {{"Missing as Zero", "True"}})
		v2 = GetDataVector("Routeout+"+path+"|", "PM", {{"Missing as Zero", "True"}})
		SetDataVector("Routeout+"+path+"|", PHCol[p], v1, )
		SetDataVector("Routeout+"+path+"|", PMCol[p], v2, )
		v1 = null
		v2 = null

		goto nextpath4

		badpath4:
		msg = msg + {"Transit_Pax_Stats-WARNING - Missing File " + path + "\\TASN_FLW.bin"}
		AppendToLogFile(2, "Transit_Pax_Stats-WARNING - Missing File " + path + "\\TASN_FLW.bin")

		nextpath4:
		CloseView("Routeout+"+path)
	end // for i


	//--- Tot Passenger Computation

		v1  = GetDataVector("Routeout|", "PPRMW_PASS", )
		v2  = GetDataVector("Routeout|", "PPRMD_PASS", )
		v3  = GetDataVector("Routeout|", "PPRMDO_PAS", )
		v4  = GetDataVector("Routeout|", "PBUSW_PASS", )
		v5  = GetDataVector("Routeout|", "PBUSD_PASS", )
		v6  = GetDataVector("Routeout|", "PBUSDO_PAS", )
		v7  = GetDataVector("Routeout|", "OPPRMW_PAS", )
		v8  = GetDataVector("Routeout|", "OPPRMD_PAS", )
		v9  = GetDataVector("Routeout|", "OPPRMDO_PA", )
		v10 = GetDataVector("Routeout|", "OPBUSW_PAS", )
		v11 = GetDataVector("Routeout|", "OPBUSD_PAS", )
		v12 = GetDataVector("Routeout|", "OPBUSDO_PA", )
		vPASS = v1 + v2 + v3 + v4 + v5 + v6 + v7 + v8 + v9 + v10 + v11 + v12
		SetDataVector("Routeout|", "PASS", vPASS, )
		v1  = null
		v2  = null
		v3  = null
		v4  = null
		v5  = null
		v6  = null
		v7  = null
		v8  = null
		v9  = null
		v10 = null
		v11 = null
		v12 = null
		vPASS  = null


	//--- Tot Passenger Hour Computation

		v1  = GetDataVector("Routeout|", "PPRMW_PH", )
		v2  = GetDataVector("Routeout|", "PPRMD_PH", )
		v3  = GetDataVector("Routeout|", "PPRMDO_PH", )
		v4  = GetDataVector("Routeout|", "PBUSW_PH", )
		v5  = GetDataVector("Routeout|", "PBUSD_PH", )
		v6  = GetDataVector("Routeout|", "PBUSDO_PH", )
		v7  = GetDataVector("Routeout|", "OPPRMW_PH", )
		v8  = GetDataVector("Routeout|", "OPPRMD_PH", )
		v9  = GetDataVector("Routeout|", "OPPRMDO_PH", )
		v10 = GetDataVector("Routeout|", "OPBUSW_PH", )
		v11 = GetDataVector("Routeout|", "OPBUSD_PH", )
		v12 = GetDataVector("Routeout|", "OPBUSDO_PH", )
		vPH = v1 + v2 + v3 + v4 + v5 + v6 + v7 + v8 + v9 + v10 + v11 + v12
		SetDataVector("Routeout|", "PASSHOUR", vPH, )
		v1  = null
		v2  = null
		v3  = null
		v4  = null
		v5  = null
		v6  = null
		v7  = null
		v8  = null
		v9  = null
		v10 = null
		v11 = null
		v12 = null
		vPH  = null


	//--- Tot Passenger Mile Computation

		v1  = GetDataVector("Routeout|", "PPRMW_PM", )
		v2  = GetDataVector("Routeout|", "PPRMD_PM", )
		v3  = GetDataVector("Routeout|", "PPRMDO_PM", )
		v4  = GetDataVector("Routeout|", "PBUSW_PM", )
		v5  = GetDataVector("Routeout|", "PBUSD_PM", )
		v6  = GetDataVector("Routeout|", "PBUSDO_PM", )
		v7  = GetDataVector("Routeout|", "OPPRMW_PM", )
		v8  = GetDataVector("Routeout|", "OPPRMD_PM", )
		v9  = GetDataVector("Routeout|", "OPPRMDO_PM", )
		v10 = GetDataVector("Routeout|", "OPBUSW_PM", )
		v11 = GetDataVector("Routeout|", "OPBUSD_PM", )
		v12 = GetDataVector("Routeout|", "OPBUSDO_PM", )
		vPM = v1 + v2 + v3 + v4 + v5 + v6 + v7 + v8 + v9 + v10 + v11 + v12
		SetDataVector("Routeout|", "PASSMILE", vPM, )
		v1  = null
		v2  = null
		v3  = null
		v4  = null
		v5  = null
		v6  = null
		v7  = null
		v8  = null
		v9  = null
		v10 = null
		v11 = null
		v12 = null
		vPM  = null
	
	vws = GetViewNames()
	for i = 1 to vws.length do
		CloseView(vws[i])
	end
	goto quit
	
	badfilltasnflow:
		TransitPaxOK = 0
		msg = msg + {"Transit_Pax Stats: ERROR filling PH / PM in Tasn_flow - path: " + path}
		AppendToLogFile(2, "Transit_Pax Stats: ERROR filling PH / PM in Tasn_flow - path: " + path)
		RunMacro("TCB Closing", ret_value, True )
		goto quit

	quit:
		datentime = GetDateandTime()
		AppendToLogFile(1, "Exit Transit_Pax_Stats " + datentime)
		return({TransitPaxOK, msg})
EndMacro