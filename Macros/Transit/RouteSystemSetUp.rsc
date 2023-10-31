Macro "RouteSystemSetUp" (Args)
// 5/30/19, mk: There are now three distinct networks, use offpeak initially for transit set-up

	Dir = Args.[Run Directory].value
	METDir = Args.[MET Directory].value
	netname = Args.[Offpeak Hwy Name].value
	theyear = Args.[Run Year].value

	LogFile = Args.[Log File].value
	SetLogFileName(LogFile)

	datentime = GetDateandTime()
	AppendToLogFile(1, "Enter RouteSystemSetUp:  " + datentime)

	msg = null

	on error, notfound goto badquit

	routename = "transys"
	route_file = Dir + "\\"+routename+".rts"
	net_file = Dir + "\\"+netname+".dbd"

	ModifyRouteSystem(route_file, {{"Geography", net_file, netname},{"Link ID", "ID"}})


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


	ReloadRouteSystem(route_file)
	VerifyRouteSystem(route_file, "Connected")
	nottagged = TagRouteStopsWithNode("Vehicle Routes", null, "UserID", 0.02)
	if nottagged > 0 
		then do
			msg = msg + {"RouteSystemSetUp ERROR!, " + i2s(nottagged) + " stops not tagged to node!"}
			AppendToLogFile(2, "RouteSystemSetUp ERROR!, " + i2s(nottagged) + " stops not tagged to node!")
			goto badquit2
		end	
	closemap()

	datentime = GetDateandTime()
	AppendToLogFile(1, "Build Networks: exit Route System Set Up  " + datentime)

	quit:
	on error, notfound default
	return({1, msg})
	
	badquit:
	msg = msg + {"error= " + GetLastError()}
	AppendToLogFile(2, "error= " + GetLastError())
	msg = msg + {"RouteSystemSetUp - check for transys*.err"}

	badquit2:
	AppendToLogFile(1, "Exit RouteSystemSetUp:  " + datentime)
	on error, notfound default
	return({0, msg})
	
endMacro
