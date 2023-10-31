Macro "Transit_Boardings" (Args)

	// *********************************************************************************
	//  AECOM version allowed choosing group 1-4 
	//   or a route list or selecting all
	//	This version selects GRP_LIST = 1,2,3,4,    
	//	SEE REG_BOARDING_SUMMARY IN OLDER VERSION OF MRM 
	//************************************************************************************
	//	Includes Naveen's updates (1-4, 2016)
	// ***********************************************************************************

// 6/20/19, mk: There are now three distinct networks, use offpeak initially for transit set-up

	Dir = Args.[Run Directory].value
	netname = Args.[Offpeak Hwy Name].value
	LogFile = Args.[Log File].value
	SetLogFileName(LogFile)

	msg = null
	TransitBoardsOK = 1
	datentime = GetDateandTime()
	AppendToLogFile(1, "Enter Transit_Boardings: " + datentime)


	net_file = Dir + "\\"+netname+".dbd"
	routename = "TranSys"
	route_file = Dir + "\\"+routename+".rts"

	//*************************************************************************
	//  put this either into Args or list from interface
	//************************************************************************
	select_group = {1,2,3,4}

	dim pprmwalk_boards[2], pprmdrive_boards[2], pprmdrop_boards[2]
	dim opprmwalk_boards[2], opprmdrive_boards[2], opprmdrop_boards[2]

	dim pbuswalk_boards[2], pbusdrive_boards[2], pbusdrop_boards[2]
	dim opbuswalk_boards[2], opbusdrive_boards[2], opbusdrop_boards[2]

	dim temp[10], route_id_list[1000]

	if select_group.length = 0 then goto skipALL	
	

	// -- create a table to store the ON/OFF Boards Information for all Buses/Premium Services
	// -- Naveen, 2016

	all_boards_info = {
		{"Route_ID", "Integer", 8, null, "Yes"},		
		{"Route_Name", "String", 25, null, "Yes"},	
		{"Track", "Integer", 6, null, "No"},	
		{"Corr", "Integer", 6, null, "No"},	
		{"Key", "Integer", 8, null, "No"},	
		{"IO", "String", 2, null, "No"},	
		{"MODE", "Integer", 8, null, "No"},		
		{"AM_HEAD", "Real", 8, 2, "No"},		
		{"MID_HEAD", "Real", 8, 2, "No"},		
		{"STOP_ID", "Integer", 8, null, "No"},		
		{"NODE_ID", "Integer", 8, null, "No"},		
		{"STOP_NAME", "String", 25, null, "No"},			
		{"MILEPOST", "Real", 10, 4, "No"},
		{"PEAK_IVTT", "Real", 10, 4, "No"},
		{"OFPK_IVTT", "Real", 10, 4, "No"},
		{"PWLK_ON", "Real", 10, 2, "No"},			
		{"PWLK_OF", "Real", 10, 2, "No"},			
		{"PDRV_ON", "Real", 10, 2, "No"},
		{"PDRV_OF", "Real", 10, 2, "No"},
		{"PDRP_ON", "Real", 10, 2, "No"},
		{"PDRP_OF", "Real", 10, 2, "No"},
		{"OPWLK_ON", "Real", 10, 2, "No"},			
		{"OPWLK_OF", "Real", 10, 2, "No"},			
		{"OPDRV_ON", "Real", 10, 2, "No"},
		{"OPDRV_OF", "Real", 10, 2, "No"},
		{"OPDRP_ON", "Real", 10, 2, "No"},
		{"OPDRP_OF", "Real", 10, 2, "No"},
		{"PEAK_ON", "Real", 10, 2, "No"},
		{"PEAK_OFF", "Real", 10, 2, "No"},
		{"PEAK_RIDES", "Real", 10, 2, "No"},
		{"OFPK_ON", "Real", 10, 2, "No"},
		{"OFPK_OFF", "Real", 10, 2, "No"},
		{"OFPK_RIDES", "Real", 10, 2, "No"},
		{"PWLKDON", "Real", 10, 2, "No"},			
		{"PWLKDOF", "Real", 10, 2, "No"},			
		{"PDRVDON", "Real", 10, 2, "No"},
		{"PDRVDOF", "Real", 10, 2, "No"},
		{"PDRPDON", "Real", 10, 2, "No"},
		{"PDRPDOF", "Real", 10, 2, "No"},
		{"OPWLKDON", "Real", 10, 2, "No"},			
		{"OPWLKDOF", "Real", 10, 2, "No"},			
		{"OPDRVDON", "Real", 10, 2, "No"},
		{"OPDRVDOF", "Real", 10, 2, "No"},
		{"OPDRPDON", "Real", 10, 2, "No"},
		{"OPDRPDOF", "Real", 10, 2, "No"},
		{"PWLKXON", "Real", 10, 2, "No"},			
		{"PWLKXOF", "Real", 10, 2, "No"},			
		{"PDRVXON", "Real", 10, 2, "No"},
		{"PDRVXOF", "Real", 10, 2, "No"},
		{"PDRPXON", "Real", 10, 2, "No"},
		{"PDRPXOF", "Real", 10, 2, "No"},
		{"OPWLKXON", "Real", 10, 2, "No"},			
		{"OPWLKXOF", "Real", 10, 2, "No"},			
		{"OPDRVXON", "Real", 10, 2, "No"},
		{"OPDRVXOF", "Real", 10, 2, "No"},
		{"OPDRPXON", "Real", 10, 2, "No"},
		{"OPDRPXOF", "Real", 10, 2, "No"}
	}

	all_boards_name = "ALL_BOARDINGS"	
	all_boards_file = Dir + "\\Report\\ALL_BOARDINGS.dbf"
	all_boards_view = CreateTable (all_boards_name, all_boards_file, "DBASE", all_boards_info)

// -- create a table to store the Stop-To-Stop Travel Times for all Routes

	ttimes_info = {
		{"Route_ID", "Integer", 8, null, "Yes"},		
		{"STOP_ID", "Integer", 8, null, "No"},		
		{"MILEPOST", "Real", 10, 4, "No"},		
		{"PEAK_IVTT", "Real", 10, 4, "No"},
		{"OFPK_IVTT", "Real", 10, 4, "No"}
	}

	ttimes_name = "TRAVEL_TIMES"	
	ttimes_file = Dir + "\\Report\\TRAVEL_TIMES.dbf"
	ttimes_view = CreateTable (ttimes_name, ttimes_file, "DBASE", ttimes_info)


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
	SetLayerVisibility(node_lyr, "True")
	SetIcon(node_lyr + "|", "Font Character", "Caliper Cartographic|4", 36)
	SetIcon("Route Stops|", "Font Character", "Caliper Cartographic|4", 36)
	SetLayerVisibility(link_lyr, "True")
	solid = LineStyle({{{1, -1, 0}}})
	SetLineStyle(link_lyr+"|", solid)
	SetLineColor(link_lyr+"|", ColorRGB(0, 0, 32000))
	SetLineWidth(link_lyr+"|", 0)
	SetLayerVisibility("Route Stops", "False")

// --open the Routes.DBF file and create Key_Num field to store the "Key" values.
// -- this is necessary as TransCAD doesnt allow using the key field for reading as its a primary key

// -- check whether a field "Key_Num" exists to store key values

	routes1 = opentable("Routes", "DBASE", {Dir + "\\Routes.dbf",})

	field_array = GetFields (routes1, "All")

	fld_names = field_array [1]
	fld_specs = field_array [2]

	field_flag = 0

	for k = 1 to fld_names.length do
		if (fld_names [k] = "KEY_NUM") then do
			field_flag = 1
			goto continue10
		end
	end

continue10:

	if (field_flag = 0) then do
		// Get the structure of the routes
		strct = GetTableStructure(routes1)
		for i = 1 to strct.length do
		// Copy the current name to the end of strct
		strct[i] = strct[i] + {strct[i][1]}
		end
		// Add a field for Passenger Hours
		new_struct = strct + {{"KEY_NUM", "Integer", 8, null, "False",,,, null}}

		// Modify the table
		ModifyTable(routes1, new_struct)
	end

// --- Fill the newly added field with the "Key" values

	record = GetFirstRecord (routes1 + "|", null)

	while record <> null do
		routes1.KEY_NUM = routes1.key
		record = GetNextRecord(routes1 + "|", null, null)
	end


//--------------------------------- Joining Vehicle Routes and Routes -----------------------------------

	on notfound default
	setview("Vehicle Routes")

	opentable("Routes", "DBASE", {Dir + "\\Routes.dbf",})

	routes_view = joinviews("Vehicle Routes+ROUTES", "[Vehicle Routes].Key", "ROUTES.KEY",)
	SetView(routes_view)

// create selection set of routes to gather boardings

	rtesquery = "Select * where GRP_LIST = " + i2s(select_group[1])
	if select_group.length > 1 then do
		for i = 2 to select_group.length do
			rtesquery = rtesquery + " or GRP_LIST = " + i2s(select_group[i])
		end
	end
	numrtes = SelectByQuery("BoardRtes", "Several", rtesquery,)

	if numrtes = 0 then goto noroutesingroup

	// select_routes - list of routes to process
	select_routes = null
	record = GetFirstRecord (routes_view + "|BoardRtes", null)

	while record <> null do
		recval = GetRecordValues(routes_view, record, {"Route_ID"})
		rteID = recval[1][2]
		select_routes = select_routes + {rteID} 
		record = GetNextRecord(routes_view + "|BoardRtes", null, null)
	end
	
	// ----- Set the paths for the TASN_FLOW files

	pprmw_TASN_FLW = Dir + "\\tranassn\\PprmW\\TASN_FLW.bin"
	pbusw_TASN_FLW = Dir + "\\tranassn\\PbusW\\TASN_FLW.bin"
	pprmd_TASN_FLW = Dir + "\\tranassn\\PprmD\\TASN_FLW.bin"
	pbusd_TASN_FLW = Dir + "\\tranassn\\PbusD\\TASN_FLW.bin"
	pprmdrop_TASN_FLW = Dir + "\\tranassn\\PprmDrop\\TASN_FLW.bin"
	pbusdrop_TASN_FLW = Dir + "\\tranassn\\PbusDrop\\TASN_FLW.bin"

	opprmw_TASN_FLW = Dir + "\\tranassn\\OPprmW\\TASN_FLW.bin"
	opbusw_TASN_FLW = Dir + "\\tranassn\\OPbusW\\TASN_FLW.bin"
	opprmd_TASN_FLW = Dir + "\\tranassn\\OPprmD\\TASN_FLW.bin"
	opbusd_TASN_FLW = Dir + "\\tranassn\\OPbusD\\TASN_FLW.bin"
	opprmdrop_TASN_FLW = Dir + "\\tranassn\\OPprmDrop\\TASN_FLW.bin"
	opbusdrop_TASN_FLW = Dir + "\\tranassn\\OPbusDrop\\TASN_FLW.bin"


// --- Create Views for TASN_FLOW files

     pprmw_flow_view=OpenTable("pprmw_flow_view","FFB",{pprmw_TASN_FLW,})
     pbusw_flow_view=OpenTable("pbusw_flow_view","FFB",{pbusw_TASN_FLW,})
     pprmd_flow_view=OpenTable("pprmd_flow_view","FFB",{pprmd_TASN_FLW,})
     pbusd_flow_view=OpenTable("pbusd_flow_view","FFB",{pbusd_TASN_FLW,})
     pprmdrop_flow_view=OpenTable("pprmdrop_flow_view","FFB",{pprmdrop_TASN_FLW,})
     pbusdrop_flow_view=OpenTable("pbusdrop_flow_view","FFB",{pbusdrop_TASN_FLW,})

     opprmw_flow_view=OpenTable("opprmw_flow_view","FFB",{opprmw_TASN_FLW,})
     opbusw_flow_view=OpenTable("opbusw_flow_view","FFB",{opbusw_TASN_FLW,})
     opprmd_flow_view=OpenTable("opprmd_flow_view","FFB",{opprmd_TASN_FLW,})
     opbusd_flow_view=OpenTable("opbusd_flow_view","FFB",{opbusd_TASN_FLW,})
     opprmdrop_flow_view=OpenTable("opprmdrop_flow_view","FFB",{opprmdrop_TASN_FLW,})
     opbusdrop_flow_view=OpenTable("opbusdrop_flow_view","FFB",{opbusdrop_TASN_FLW,})

// ------- Set the paths for ONO files

	pprmw_ONOS = Dir + "\\tranassn\\PprmW\\TASN_ONO.bin"
	pbusw_ONOS = Dir + "\\tranassn\\PbusW\\TASN_ONO.bin"
	pprmd_ONOS = Dir + "\\tranassn\\PprmD\\TASN_ONO.bin"
	pbusd_ONOS = Dir + "\\tranassn\\PbusD\\TASN_ONO.bin"
	pprmdrop_ONOS = Dir + "\\tranassn\\PprmDrop\\TASN_ONO.bin"
	pbusdrop_ONOS = Dir + "\\tranassn\\PbusDrop\\TASN_ONO.bin"

	opprmw_ONOS = Dir + "\\tranassn\\OPprmW\\TASN_ONO.bin"
	opbusw_ONOS = Dir + "\\tranassn\\OPbusW\\TASN_ONO.bin"
	opprmd_ONOS = Dir + "\\tranassn\\OPprmD\\TASN_ONO.bin"
	opbusd_ONOS = Dir + "\\tranassn\\OPbusD\\TASN_ONO.bin"
	opprmdrop_ONOS = Dir + "\\tranassn\\OPprmDrop\\TASN_ONO.bin"
	opbusdrop_ONOS = Dir + "\\tranassn\\OPbusDrop\\TASN_ONO.bin"

// --- Create Views for ONO files

     pprmw_view=OpenTable("pprmw_view","FFB",{pprmw_ONOS,})
     pbusw_view=OpenTable("pbusw_view","FFB",{pbusw_ONOS,})
     pprmd_view=OpenTable("pprmd_view","FFB",{pprmd_ONOS,})
     pbusd_view=OpenTable("pbusd_view","FFB",{pbusd_ONOS,})
     pprmdrop_view=OpenTable("pprmdrop_view","FFB",{pprmdrop_ONOS,})
     pbusdrop_view=OpenTable("pbusdrop_view","FFB",{pbusdrop_ONOS,})

     opprmw_view=OpenTable("opprmw_view","FFB",{opprmw_ONOS,})
     opbusw_view=OpenTable("opbusw_view","FFB",{opbusw_ONOS,})
     opprmd_view=OpenTable("opprmd_view","FFB",{opprmd_ONOS,})
     opbusd_view=OpenTable("opbusd_view","FFB",{opbusd_ONOS,})
     opprmdrop_view=OpenTable("opprmdrop_view","FFB",{opprmdrop_ONOS,})
     opbusdrop_view=OpenTable("opbusdrop_view","FFB",{opbusdrop_ONOS,})

// ------- Create Stop to Stop Travel Times
//	getTTrtn - 0 if user kills on progrress bar in Get Trav Times

	getTTrtn = 1
	getTTrtn = RunMacro ("Get Travel Times", ttimes_view, pprmw_flow_view, 1, select_routes)
	if getTTrtn = 0 then goto UserKill
	
	getTTrtn = RunMacro ("Get Travel Times", ttimes_view, pbusw_flow_view, 1, select_routes)
	if getTTrtn = 0 then goto UserKill

	getTTrtn = RunMacro ("Get Travel Times", ttimes_view, opprmw_flow_view, 0, select_routes)
	if getTTrtn = 0 then goto UserKill

	getTTrtn = RunMacro ("Get Travel Times", ttimes_view, opbusw_flow_view, 0, select_routes)
	if getTTrtn = 0 then goto UserKill


/// -------- CREATE BOARDING SUMMARY --------------------------------
	
	SetView(routes_view)

		rec = 0
		nrec = GetRecordCount (routes_view, null)
		CreateProgressBar ("Processing Vehicle Route" + String(nrec) + " Transit Routes", "True")   
	
		routes_rec = GetFirstRecord (routes_view + "|BoardRtes", {{"Track", "Ascending"},{"IO", "Ascending"},{"Route_Name", "Ascending"}})

		while routes_rec <> null do

			rec = rec + 1
			percent = r2i (rec * 100 / nrec)
			cancel = UpdateProgressBar ("Processing Vehicle Route " + String (rec) + " of " + String (nrec) + " Transit Routes", percent)

			if cancel = "True" 
				then goto UserKill

//if ( rec > 1) then goto quit

			peak_boards_flag = 0
			offpeak_boards_flag = 0

			SetView(routes_view)
			route_id = routes_view.Route_ID
			route_name = routes_view.Route_Name
			track = routes_view.Track
			corr = routes_view.Corr
			key = routes_view.KEY_NUM
			mode = routes_view.MODE
			io = routes_view.IO
			peak_headway = routes_view.AM_HEAD
			offpeak_headway = routes_view.MID_HEAD

			check_flag = 0

			for m = 1 to select_routes.length do
				if select_routes[m] = route_id 
					then do
						check_flag = 1
						goto processroute
					end
			end

		processroute:

		if (check_flag = 1) then do

			stop_layer = "Route Stops"			
			SetView("Route Stops")
		
			select = "Select * where Route_ID = " + String(route_id)
			stop_selection = SelectByQuery ("Stops", "Several", select, )
	
//	if (rec >= 3) then goto quit

				num_stops = GetRecordCount ("Route Stops", "Stops")

				stop_rec = GetFirstRecord ("Route Stops" + "|Stops", {{"Milepost", "Ascending"}})
				
				while stop_rec <> null do

					stop_id = stop_layer.ID
					node_id = stop_layer.UserID
					milepost = stop_layer.Milepost

					// --- get the milepost distances and travel times

					SetView(ttimes_view)

					selection = "Select * where ROUTE_ID = " + String(route_id) + " and STOP_ID = " + String(stop_id)
					select = SelectByQuery ("Select Record", "Several", selection,)
					num_select = GetRecordCount (ttimes_view, "Select Record")
	
					if (num_select <> 0) then do
						ttimes_record = GetFirstRecord (ttimes_view + "|Select Record", null)
						milepost = ttimes_view.MILEPOST
						peak_ttime = ttimes_view.PEAK_IVTT
						offpeak_ttime = ttimes_view.OFPK_IVTT
					end

					// Get the transit station name

					SetLayer(node_lyr)

					rh = LocateRecord (node_lyr + "|", "ID", {node_id},{{"Exact", "True"}})

					if ( rh <> null) then do
						if ( node_lyr.StaName = " " or node_lyr.StaName = null) then
							station_name = GetStopLocation(link_lyr + ".Strname", "Vehicle Routes", stop_id, 0.20)
						else
							station_name = node_lyr.StaName
					end
					
					// -- Naveen, 2016

					if (peak_headway = 0) then do

						pprmwalk_boards[1] = 0
						pprmwalk_boards[2] = 0
						pprmdrive_boards[1] = 0
						pprmdrive_boards[2] = 0
						pprmdrop_boards[1] = 0
						pprmdrop_boards[2] = 0

						pbuswalk_boards[1] = 0
						pbuswalk_boards[2] = 0
						pbusdrive_boards[1] = 0
						pbusdrive_boards[2] = 0
						pbusdrop_boards[1] = 0
						pbusdrop_boards[2] = 0

						pprmwalk_boards[3] = 0
						pprmwalk_boards[4] = 0
						pprmdrive_boards[3] = 0
						pprmdrive_boards[4] = 0
						pprmdrop_boards[3] = 0
						pprmdrop_boards[4] = 0

						pbuswalk_boards[3] = 0
						pbuswalk_boards[4] = 0
						pbusdrive_boards[3] = 0
						pbusdrive_boards[4] = 0
						pbusdrop_boards[3] = 0
						pbusdrop_boards[4] = 0

						pprmwalk_boards[5] = 0
						pprmwalk_boards[6] = 0
						pprmdrive_boards[5] = 0
						pprmdrive_boards[6] = 0
						pprmdrop_boards[5] = 0
						pprmdrop_boards[6] = 0

						pbuswalk_boards[5] = 0
						pbuswalk_boards[6] = 0
						pbusdrive_boards[5] = 0
						pbusdrive_boards[6] = 0
						pbusdrop_boards[5] = 0
						pbusdrop_boards[6] = 0

						pprmwalk_boards[7] = 0
						pprmwalk_boards[8] = 0
						pprmdrive_boards[7] = 0
						pprmdrive_boards[8] = 0
						pprmdrop_boards[7] = 0
						pprmdrop_boards[8] = 0

						pbuswalk_boards[7] = 0
						pbuswalk_boards[8] = 0
						pbusdrive_boards[7] = 0
						pbusdrive_boards[8] = 0
						pbusdrop_boards[7] = 0
						pbusdrop_boards[8] = 0

						peak_on = 0
						peak_off = 0
						peak_boards = 0
	
					end else do
							// -- Naveen, 2016
							pprmwalk_boards = RunMacro("Get Boardings", route_id, stop_id, pprmw_view, "Walk")
							pprmdrive_boards = RunMacro("Get Boardings", route_id, stop_id, pprmd_view, "Drive")
							pprmdrop_boards = RunMacro("Get Boardings", route_id, stop_id, pprmdrop_view, "DropOff")
		
							pbuswalk_boards = RunMacro("Get Boardings", route_id, stop_id, pbusw_view, "Walk")
							pbusdrive_boards = RunMacro("Get Boardings", route_id, stop_id, pbusd_view, "Drive")
							pbusdrop_boards = RunMacro("Get Boardings", route_id, stop_id, pbusdrop_view, "DropOff")


							// -- Compute the PEAK  - ON and OFF Boards
			
							peak_on = pprmwalk_boards[1] + pprmdrive_boards[1] + pprmdrop_boards[1] + pbuswalk_boards[1] + pbusdrive_boards[1] + pbusdrop_boards[1]
							peak_off = pprmwalk_boards[2] + pprmdrive_boards[2] + pprmdrop_boards[2] +  pbuswalk_boards[2] + pbusdrive_boards[2] + pbusdrop_boards[2]
			
							if peak_boards_flag = 0 then do
								peak_boards = peak_on
								peak_boards_flag = 1
							end else do
								peak_boards = peak_boards + peak_on - peak_off
							end
	
						end    // -- end of process for summarizing peak boards
		
					// -- Naveen, 2016
					if (offpeak_headway = 0) then do
						opprmwalk_boards[1] = 0
						opprmwalk_boards[2] = 0
						opprmdrive_boards[1] = 0
						opprmdrive_boards[2] = 0
						opprmdrop_boards[1] = 0
						opprmdrop_boards[2] = 0

						opbuswalk_boards[1] = 0
						opbuswalk_boards[2] = 0
						opbusdrive_boards[1] = 0
						opbusdrive_boards[2] = 0
						opbusdrop_boards[1] = 0
						opbusdrop_boards[2] = 0

						opprmwalk_boards[3] = 0
						opprmwalk_boards[4] = 0
						opprmdrive_boards[3] = 0
						opprmdrive_boards[4] = 0
						opprmdrop_boards[3] = 0
						opprmdrop_boards[4] = 0

						opbuswalk_boards[3] = 0
						opbuswalk_boards[4] = 0
						opbusdrive_boards[3] = 0
						opbusdrive_boards[4] = 0
						opbusdrop_boards[3] = 0
						opbusdrop_boards[4] = 0

						opprmwalk_boards[5] = 0
						opprmwalk_boards[6] = 0
						opprmdrive_boards[5] = 0
						opprmdrive_boards[6] = 0
						opprmdrop_boards[5] = 0
						opprmdrop_boards[6] = 0

						opbuswalk_boards[5] = 0
						opbuswalk_boards[6] = 0
						opbusdrive_boards[5] = 0
						opbusdrive_boards[6] = 0
						opbusdrop_boards[5] = 0
						opbusdrop_boards[6] = 0

						opprmwalk_boards[7] = 0
						opprmwalk_boards[8] = 0
						opprmdrive_boards[7] = 0
						opprmdrive_boards[8] = 0
						opprmdrop_boards[7] = 0
						opprmdrop_boards[8] = 0

						opbuswalk_boards[7] = 0
						opbuswalk_boards[8] = 0
						opbusdrive_boards[7] = 0
						opbusdrive_boards[8] = 0
						opbusdrop_boards[7] = 0
						opbusdrop_boards[8] = 0

						offpeak_on = 0
						offpeak_off = 0
						offpeak_boards = 0


					end else do
							// -- Naveen, 2016

							opprmwalk_boards = RunMacro("Get Boardings", route_id, stop_id, opprmw_view, "Walk")
							opprmdrive_boards = RunMacro("Get Boardings", route_id, stop_id, opprmd_view, "Drive")
							opprmdrop_boards = RunMacro("Get Boardings", route_id, stop_id, opprmdrop_view, "DropOff")
							opbuswalk_boards = RunMacro("Get Boardings", route_id, stop_id, opbusw_view, "Walk")
							opbusdrive_boards = RunMacro("Get Boardings", route_id, stop_id, opbusd_view, "Drive")
							opbusdrop_boards = RunMacro("Get Boardings", route_id, stop_id, opbusdrop_view, "DropOff")

							// -- Compute the OFF PEAK  - ON and OFF Boards
				
							offpeak_on = opprmwalk_boards[1] + opprmdrive_boards[1] + opprmdrop_boards[1] + opbuswalk_boards[1] + opbusdrive_boards[1] + opbusdrop_boards[1]
							offpeak_off = opprmwalk_boards[2] + opprmdrive_boards[2] + opprmdrop_boards[2] + opbuswalk_boards[2] + opbusdrive_boards[2] + opbusdrop_boards[2]

							if offpeak_boards_flag = 0 then do
								offpeak_boards = offpeak_on
								offpeak_boards_flag = 1
							end else do
								offpeak_boards = offpeak_boards + offpeak_on - offpeak_off
							end

					end  // -- end of processing off-peak boards
					
					SetView(all_boards_view)
				
					// --- Open Premium Walk ONO File
					// -- Naveen, 2016
				
					all_board_values = {
						{"Route_ID", route_id},		
						{"Route_Name", route_name},	
						{"Track", track},	
						{"Key", key},	
						{"Corr", corr},	
						{"IO", io},	
						{"MODE", mode},
						{"AM_HEAD", peak_headway},		
						{"MID_HEAD", offpeak_headway},		
						{"STOP_ID", stop_id},
						{"NODE_ID", node_id},
						{"STOP_NAME", station_name},			
						{"MILEPOST", milepost},
						{"PEAK_IVTT", peak_ttime},
						{"OFPK_IVTT", offpeak_ttime},
						{"PWLK_ON", pprmwalk_boards[1]+ pbuswalk_boards[1]},			
						{"PWLK_OF", pprmwalk_boards[2]+ pbuswalk_boards[2] },
						{"PDRV_ON", pprmdrive_boards[1] + pbusdrive_boards[1]},			
						{"PDRV_OF", pprmdrive_boards[2] + pbusdrive_boards[2]},
						{"PDRP_ON", pprmdrop_boards[1] + pbusdrop_boards[1]},			
						{"PDRP_OF", pprmdrop_boards[2] + pbusdrop_boards[2] },
						{"OPWLK_ON", opprmwalk_boards[1] + opbuswalk_boards[1]},			
						{"OPWLK_OF", opprmwalk_boards[2] + opbuswalk_boards[2]},
						{"OPDRV_ON", opprmdrive_boards[1] + opbusdrive_boards[1]},			
						{"OPDRV_OF", opprmdrive_boards[2] + opbusdrive_boards[2]},
						{"OPDRP_ON", opprmdrop_boards[1] + opbusdrop_boards[1]},			
						{"OPDRP_OF", opprmdrop_boards[2] + opbusdrop_boards[2]},
						{"PEAK_ON", peak_on},
						{"PEAK_OFF", peak_off},
						{"PEAK_RIDES", peak_boards},
						{"OFPK_ON", offpeak_on},
						{"OFPK_OFF", offpeak_off},
						{"OFPK_RIDES", offpeak_boards},
						{ "PWLKDON",   pprmwalk_boards[3] +  pbuswalk_boards[3]},			
						{ "PWLKDOF",   pprmwalk_boards[8] +   pbuswalk_boards[8]},
						{ "PDRVDON",  pprmdrive_boards[3] +  pbusdrive_boards[3]},			
						{ "PDRVDOF",  pprmdrive_boards[8] +  pbusdrive_boards[8]},
						{ "PDRPDON",   pprmdrop_boards[3] +   pbusdrop_boards[3]},			
						{ "PDRPDOF",   pprmdrop_boards[8] +   pbusdrop_boards[8]},
						{"OPWLKDON",  opprmwalk_boards[3] +  opbuswalk_boards[3]},			
						{"OPWLKDOF",  opprmwalk_boards[8] +  opbuswalk_boards[8]},
						{"OPDRVDON", opprmdrive_boards[3] + opbusdrive_boards[3]},			
						{"OPDRVDOF", opprmdrive_boards[8] + opbusdrive_boards[8]},
						{"OPDRPDON",  opprmdrop_boards[3] +  opbusdrop_boards[3]},			
						{"OPDRPDOF",  opprmdrop_boards[8] +  opbusdrop_boards[8]},
						{ "PWLKXON",   pprmwalk_boards[4] +   pbuswalk_boards[4] +   pprmwalk_boards[5] +   pbuswalk_boards[5]},
						{ "PWLKXOF",   pprmwalk_boards[6] +   pbuswalk_boards[6] +   pprmwalk_boards[7] +   pbuswalk_boards[7]},
						{ "PDRVXON",  pprmdrive_boards[4] +  pbusdrive_boards[4] +  pprmdrive_boards[5] +  pbusdrive_boards[5]},			
						{ "PDRVXOF",  pprmdrive_boards[6] +  pbusdrive_boards[6] +  pprmdrive_boards[7] +  pbusdrive_boards[7]},
						{ "PDRPXON",   pprmdrop_boards[4] +   pbusdrop_boards[4] +   pprmdrop_boards[5] +   pbusdrop_boards[5]},			
						{ "PDRPXOF",   pprmdrop_boards[6] +   pbusdrop_boards[6] +   pprmdrop_boards[7] +   pbusdrop_boards[7]},
						{"OPWLKXON",  opprmwalk_boards[4] +  opbuswalk_boards[4] +  opprmwalk_boards[5] +  opbuswalk_boards[5]},			
						{"OPWLKXOF",  opprmwalk_boards[6] +  opbuswalk_boards[6] +  opprmwalk_boards[7] +  opbuswalk_boards[7]},
						{"OPDRVXON", opprmdrive_boards[4] + opbusdrive_boards[4] + opprmdrive_boards[5] + opbusdrive_boards[5]},			
						{"OPDRVXOF", opprmdrive_boards[6] + opbusdrive_boards[6] + opprmdrive_boards[7] + opbusdrive_boards[7]},
						{"OPDRPXON",  opprmdrop_boards[4] +  opbusdrop_boards[4] +  opprmdrop_boards[5] +  opbusdrop_boards[5]},			
						{"OPDRPXOF",  opprmdrop_boards[6] +  opbusdrop_boards[6] +  opprmdrop_boards[7] +  opbusdrop_boards[7]}
					}

				AddRecord (all_boards_view, all_board_values)

				SetView(stop_layer)
				stop_rec = GetNextRecord ("Route Stops" + "|Stops", null, {{"Milepost", "Ascending"}})
//			end

			end

	end   // -- end for check flag
	
			SetView(routes_view)
			routes_rec = GetNextRecord (routes_view + "|", null, {{"Track", "Ascending"},{"IO", "Ascending"},{"Route_Name", "Ascending"}})
		end
	goto quit

	noroutesingroup:
		msg = msg + {"Transit_Boardings: No routes selected in routes.dbf.GRPLIST"}
		AppendToLogFile(2, "Transit_Boardings: No routes selected in routes.dbf.GRPLIST ")
	skipALL:

	goto quit
	UserKill:
		TransitBoardsOK = 0
		msg = msg + {"Transit_Boarding_Summary: User stopped run"}
		AppendToLogFile(2, "Transit_Boarding_Summary: User stopped run ")
		goto quit

	quit:
		DestroyProgressBar () 
		CloseMap()
		RunMacro("G30 File Close All")

		datentime = GetDateandTime()
		AppendToLogFile(1, "Exit Transit_Boardings " + datentime)
        	return({TransitBoardsOK, msg})

endMacro


// **************************************
//   Macro to Summarize Boardings
// ***************************************

Macro "Get Boardings" (route_id, stop_id, view_name, access_mode)
	
	// -- Naveen, 2016

	dim boards[8]

	SetView(view_name)

	selection = "Select * where ROUTE = " + String(route_id) + " and STOP = " + String(stop_id)
	record_selection = SelectByQuery ("Select Record", "Several", selection,)
	num_select = GetRecordCount (view_name, "Select Record")
	
	if (num_select > 1) then 
		ShowMessage("More than one record Selected...PROBLEM HERE")
	else if (num_select = 0) then do		// --- no records are found in the boardings file
			boards[1] = 0.0
			boards[2] = 0.0

			boards[3] = 0.0
			boards[4] = 0.0
			boards[5] = 0.0
			boards[6] = 0.0
			boards[7] = 0.0
			boards[8] = 0.0
	end else do
		selected_record = GetFirstRecord (view_name + "|Select Record", null)
		boards[1] = view_name.On
		boards[2] = view_name.Off

		if (access_mode = "Walk") then boards[3] = view_name.WalkAccessOn
		else boards[3] = view_name.DriveAccessOn
		boards[4] = view_name.DirectTransferOn
		boards[5] = view_name.WalkTransferOn
		boards[6] = view_name.DirectTransferOff
		boards[7] = view_name.WalkTransferOff
		boards[8] = view_name.EgressOff
	end
	
	Return(boards)
endMacro


//----------------------------------------------------------------
//  Macro to Generate Stop-to-Stop travel Times
//----------------------------------------------------------------

Macro "Get Travel Times" (ttimes_view, flow_view, peak_flag, group_list)
	
	dim traveltime[100000]

	SetView(flow_view)

	rec = 0	
	nrec = GetRecordCount(flow_view, null)
	CreateProgressBar ("Processing " + String (nrec) + " Records", "True")   
	record = GetFirstRecord (flow_view + "|", null)
				
	while (record <> null) do

			route_id = flow_view.ROUTE

			check_flag = 0

			for m = 1 to group_list.length do
				if group_list[m] = route_id 
					then do
						check_flag = 1
						goto continueprocess
					end
			end
			
	continueprocess:

	// --- calculate the cumulative travel time

	if ( check_flag = 1) then do

			select = "Select * where ROUTE = " + String(route_id)
			stop_selection = SelectByQuery ("Stops", "Several", select, )

	//-- added new

			SetView(ttimes_view)
			selection = "Select * where ROUTE_ID = " + String(route_id) 
			select = SelectByQuery ("Check Route", "Several", selection,)
			num_select = GetRecordCount (ttimes_view, "Check Route")
			if ( num_selected >0) then goto skiproute
	
			num_stops = GetRecordCount (flow_view, "Stops")
			stop_rec = GetFirstRecord (flow_view + "|Stops", {{"FROM_MP", "Ascending"}})

			traveltime[1] = 0.0
			milepost = 0
			rec_num = 0

			while stop_rec <> null do

			rec = rec + 1
			percent = r2i (rec * 100 / nrec)
			cancel = UpdateProgressBar ("Processing " + String (rec) + " of " + String (nrec) + " Records", percent)
				if cancel = "True" 
					then goto UserKill
				
			 	current_rec = GetRecord()
				rec_num = rec_num + 1
				stop_id = flow_view.FROM_STOP
				to_stop_id = flow_view.TO_STOP
				to_MP = flow_view.TO_MP
			

//				if ( rec_num > 4) then	goto quitting	

					if (rec_num = 1) then 
						traveltime[rec_num] = flow_view.BaseIVTT
					else
						traveltime[rec_num] = traveltime[rec_num-1] + flow_view.BaseIVTT

					milepost = flow_view.FROM_MP

					// --- store the travel time between the last two stops
						
					if ( rec_num = num_stops) then 
						last_tt = flow_view.BaseIVTT

					if (peak_flag = 1) then do

						SetView(ttimes_view)
						selection = "Select * where ROUTE_ID = " + String(route_id) + " and STOP_ID = " + String(stop_id)
						select = SelectByQuery ("Select Record", "Several", selection,)
						num_select = GetRecordCount (ttimes_view, "Select Record")
	
						if (num_select = 0) then do
						
							if (rec_num = 1) then 
								cumulative_ivtt = 0
							else 
								cumulative_ivtt = traveltime[rec_num-1]

							ttimes_value = {
								{"Route_ID", route_id},		
								{"STOP_ID", stop_id},		
								{"MILEPOST", milepost},		
								{"PEAK_IVTT", cumulative_ivtt},
								{"OFPK_IVTT", 0.0}
							}

							AddRecord (ttimes_view, ttimes_value)

							if (rec_num = num_stops) then do

								stop_id = to_stop_id
								milepost = to_MP

								ttimes_value = {
									{"Route_ID", route_id},		
									{"STOP_ID", stop_id},		
									{"MILEPOST", milepost},		
									{"PEAK_IVTT", cumulative_ivtt+last_tt},
									{"OFPK_IVTT", 0.0}
								}

								AddRecord (ttimes_view, ttimes_value)
	
							end 
						end
					end else do
						
						SetView(ttimes_view)

						selection = "Select * where ROUTE_ID = " + String(route_id) + " and STOP_ID = " + String(stop_id)
						select = SelectByQuery ("Select Record", "Several", selection,)
						num_select = GetRecordCount (ttimes_view, "Select Record")

						if (num_select = 0) then do

						// --- The route runs only during off peak period

							if (rec_num = 1) then 
								cumulative_ivtt = 0
							else 
								cumulative_ivtt = traveltime[rec_num-1]

							ttimes_value = {
								{"Route_ID", route_id},		
								{"STOP_ID", stop_id},		
								{"MILEPOST", milepost},		
								{"PEAK_IVTT", 0.0},
								{"OFPK_IVTT", cumulative_ivtt}
							}

							AddRecord (ttimes_view, ttimes_value)

							if (rec_num = num_stops) then do

								stop_id = to_stop_id
								milepost = to_MP

								ttimes_value = {
									{"Route_ID", route_id},		
									{"STOP_ID", stop_id},		
									{"MILEPOST", milepost},		
									{"PEAK_IVTT", 0.0},
									{"OFPK_IVTT", cumulative_ivtt+last_tt}
								}

								AddRecord (ttimes_view, ttimes_value)
	
							end 
						
						end else do

							if (rec_num = 1) then 
								cumulative_ivtt = 0
							else 
								cumulative_ivtt = traveltime[rec_num-1]

							ttimes_record = GetFirstRecord (ttimes_view + "|Select Record", null)
							ttimes_view.OFPK_IVTT = cumulative_ivtt

							if (rec_num = num_stops) then 
								cumulative_ivtt = cumulative_ivtt+last_tt

							selection = "Select * where ROUTE_ID = " + String(route_id) + " and STOP_ID = " + String(to_stop_id)
							select = SelectByQuery ("Select Record", "Several", selection,)
							num_select = GetRecordCount (ttimes_view, "Select Record")

							ttimes_record = GetFirstRecord (ttimes_view + "|Select Record", null)
							ttimes_view.OFPK_IVTT = cumulative_ivtt

						end
					end


				SetView(flow_view)
				stop_rec = GetNextRecord (flow_view + "|Stops", null, {{"FROM_MP", "Ascending"}})

			end
	
			SetRecord(flow_view,current_rec)
	
		end	// end of check flag

		skiproute:
		record = GetNextRecord (flow_view + "|", null, null)

	end

	goto quitting
	UserKill:
		DestroyProgressBar () 
		return(0)
	
	quitting:


	DestroyProgressBar () 
	return(1)
endMacro

