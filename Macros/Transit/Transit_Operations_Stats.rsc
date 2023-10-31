Macro "Transit_Operations_Stats" (Args)
	

	Dir = Args.[Run Directory].value
	LogFile = Args.[Log File].value
	SetLogFileName(LogFile)

	msg = null
	TransitOpsOK = 1
	datentime = GetDateandTime()
	AppendToLogFile(1, "Enter Transit_Operations_Stats: " + datentime)

	routename = "TranSys"

	//  --- set the peak factor to be used for estimating peak load
	// -- peak loading factor set as 25%

	peak_factor = 0.25 
	dim peak_riders[150]

	route_file = Dir + "\\"+routename+".rts"

	// --- Open the Transit Assignment ONO files to summarize ridership data

	// ------- Set the paths for ONO files

	// --- Peak Boardings
	
	pprmw_ONOS = Dir + "\\tranassn\\PprmW\\TASN_ONO.bin"
	pbusw_ONOS = Dir + "\\tranassn\\PbusW\\TASN_ONO.bin"
	pprmd_ONOS = Dir + "\\tranassn\\PprmD\\TASN_ONO.bin"
	pbusd_ONOS = Dir + "\\tranassn\\PbusD\\TASN_ONO.bin"
	pprmdrop_ONOS = Dir + "\\tranassn\\PprmDrop\\TASN_ONO.bin"
	pbusdrop_ONOS = Dir + "\\tranassn\\PbusDrop\\TASN_ONO.bin"

	// --- Off-Peak Boardings
	
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



// ---------------------------------------------
//   Generate Ridership By Route"
// ---------------------------------------------

	// -- open the table that contains the corridor names
	corr_id_file = Dir + "\\transit_corridor_id.dbf"

	info = GetFileInfo(corr_id_file)
	if ( info = null) then do
		msg = msg + {"Transit_Operations_Stats:  ERROR! - transit_corridor_id.dbf not found"}
		AppendToLogFile(2, "Transit_Operations_Stats:  ERROR! - transit_corridor_id.dbf not found")
		goto badend
	end

	corrname_view = opentable("transit_corridor_id", "DBASE", {Dir + "\\transit_corridor_id.dbf",})

	// -- enter the duration in Hours
	// Updated based on 2007 operations data, JainM, 09.25.08
	
	AM_DURATION_Prem     = 3.25  // 3.25 
	MID_DURATION_Prem    = 5.75  // 7.62 
	PM_DURATION_Prem     = 3.25  // 3.25
	NIGHT_DURATION_Prem  = 7.73  // 4.81
		
	AM_DURATION_Xpr      = 3.25  // 2.10 
	MID_DURATION_Xpr     = 5.75  // 7.64
	PM_DURATION_Xpr      = 3.25  // 2.10
	NIGHT_DURATION_Xpr   = 6.23  // 3.45 

	AM_DURATION_Local    = 3.25  // 3.25 
	MID_DURATION_Local   = 5.75  // 7.62 
	PM_DURATION_Local    = 3.25  // 3.25
	NIGHT_DURATION_Local = 8.93  // 4.81

	AM_DURATION_Fdr      = 3.25  //  3.25 
	MID_DURATION_Fdr     = 5.75  //  8.72
	PM_DURATION_Fdr      = 3.25  //  3.25
	NIGHT_DURATION_Fdr   = 8.90  //  3.98 

	// Duration in mins 

	am_service_prem    = AM_DURATION_Prem* 60
	mid_service_prem   = MID_DURATION_Prem* 60
	pm_service_prem    = PM_DURATION_Prem* 60
	night_service_prem = NIGHT_DURATION_Prem* 60
	
	am_service_xpr     = AM_DURATION_Xpr* 60
	mid_service_xpr    = MID_DURATION_Xpr* 60
	pm_service_xpr     = PM_DURATION_Xpr* 60
	night_service_xpr  = NIGHT_DURATION_Xpr* 60
	
	am_service_loc     = AM_DURATION_Local* 60
	mid_service_loc    = MID_DURATION_Local* 60
	pm_service_loc     = PM_DURATION_Local* 60
	night_service_loc  = NIGHT_DURATION_Local* 60

	am_service_fdr     = AM_DURATION_Fdr* 60
	mid_service_fdr    = MID_DURATION_Fdr* 60
	pm_service_fdr     = PM_DURATION_Fdr* 60
	night_service_fdr  = NIGHT_DURATION_Fdr* 60


	// -- Define the calibration Factors for  adjusting Vehicle Hours and Vehicle Miles
	//   Set to 1.0 - McLelland, June, 2016
	
	vehhrs_calib_factor    = 1.0  //1.099702 //1.2968
	vehmiles_calib_factor  = 1.0  //1.052243 //1.1650
	
	prm_vehhrs_calib_factor    = 1.0 //1.335849 // Factors calibrated based on 2008 LRT numbers
	prm_vehmiles_calib_factor  = 1.0 //0.934006 // Factors calibrated based on 2008 LRT numbers

	// define other global values
	
	num_weekdays           = 252
	vehhrs_annual_factor   = 1.183413 //1.1913	// factor converts weekday values to weekly (weekday + weekend) values
	vehmiles_annual_factor = 1.137672 //1.1895      // factor converts weekday values to weekly (weekday + weekend) values
		
	prm_vehhrs_annual_factor   = 1.431195 		// factor converts weekday values to weekly (weekday + weekend) values
	prm_vehmiles_annual_factor = 1.270015           // factor converts weekday values to weekly (weekday + weekend) values
			
	// -- create a table to store the Peak Ridership information for inbound routes

	ridersbyroute_info = {
		{"Key", "Integer", 8, null, "Yes"},		
		{"Route_ID", "Integer", 8, null, "Yes"},		
		{"Route_Name", "String", 25, null, "No"},		
		{"CORR", "Integer", 8, null, "No"},
		{"CORR_NAME", "String", 35, null, "No"},
		{"TRACK", "Integer", 8, null, "No"},
		{"MODE", "Integer", 8, null, "No"},
		{"IO", "String", 3, null, "No"},
		{"PK_IVTT", "Real", 10, 2, "No"},
		{"AM_HEAD", "Real", 8, 2, "No"},	
		{"PK_LOAD", "Real", 10, 2, "No"},
		{"PK_FACTOR", "Real", 10, 2, "No"},
		{"PKHR_LOAD", "Real", 10, 2, "No"},
		{"PK_UNITS", "Integer", 8, null, "No"},
		{"UNITLOAD","Integer", 8, null, "No"}
	}

		peak_riders_name = "PEAK_RIDERS"	
		peak_riders_file = Dir + "\\Report\\PEAK_RIDERS.dbf"

	//---- close open view ----

	on notfound do
		goto continue2
	end
	              
	tmp = GetViews ()
	if (tmp <> null) then do
		views = tmp [1]
		for k = 1 to views.length do
			if (views [k] = peak_riders_name) then 
				CloseView (views [k])
		end
	end

	continue2:

	peakriders_view = CreateTable (peak_riders_name, peak_riders_file, "DBASE", ridersbyroute_info)
	

// -- create a table to store the Total Ridership for all the transit routes in the system

	ridership_info = {
		{"Key", "Integer", 8, null, "Yes"},		
		{"Route_ID", "Integer", 8, null, "Yes"},		
		{"Route_Name", "String", 25, null, "No"},		
		{"CORR", "Integer", 8, null, "No"},
		{"CORR_NAME", "String", 35, null, "No"},
		{"TRACK", "Integer", 8, null, "No"},
		{"MODE", "Integer", 8, null, "No"},
		{"IO", "String", 3, null, "No"},
		{"PK_RIDERS", "Real", 10, 2, "No"},
		{"OFPK_RIDER", "Real", 10, 2, "No"},	
		{"TOT_RIDERS", "Real", 10, 2, "No"}
	}

		ridership_name = "RIDERSHIP_SUMMARY"	
		ridership_file = Dir + "\\Report\\RIDERSHIP_SUMMARY.dbf"

	//---- close open view ----

	on notfound do
		goto continue2B
	end
	              
	tmp = GetViews ()
	if (tmp <> null) then do
		views = tmp [1]
		for k = 1 to views.length do
			if (views [k] = ridership_name) then 
				CloseView (views [k])
		end
	end

	continue2B:

	ridership_view = CreateTable (ridership_name, ridership_file, "DBASE", ridership_info)

	// -- create a table to store the Operation Statistics
	
	operations_info = {
			{"Key", "Integer", 8, null, "Yes"},		
			{"Route_ID", "Integer", 8, null, "Yes"},		
			{"Route_Name", "String", 25, null, "No"},		
			{"CORR", "Integer", 8, null, "No"},
			{"CORR_NAME", "String", 35, null, "No"},
			{"TRACK", "Integer", 8, null, "No"},
			{"MODE", "Integer", 8, null, "No"},
			{"IO", "String", 3, null, "No"},
			{"Length", "Real", 8, 2, "No"},
			{"PK_IVTT", "Real", 10, 2, "No"},
			{"OFPK_IVTT", "Real", 10, 2, "No"},
			{"AM_HEAD", "Real", 8, 2, "No"},	
			{"MID_HEAD", "Real", 8, 2, "No"},	
			{"PM_HEAD", "Real", 8, 2, "No"},	
			{"NIGHT_HEAD", "Real", 8, 2, "No"},	
			{"AM_TRIPS", "Integer", 8, null, "No"},	
			{"MID_TRIPS", "Integer", 8, null, "No"},	
			{"PM_TRIPS", "Integer", 8, null, "No"},	
			{"NIGHT_TRIP", "Integer", 8, null, "No"},
			{"AM_VEHRS", "Real", 8, 2, "No"},	
			{"MID_VEHRS", "Real", 8, 2, "No"},	
			{"PM_VEHRS", "Real", 8, 2, "No"},	
			{"NIG_VEHRS", "Real", 8, 2, "No"},	
			{"AM_VEHMIL", "Real", 8, 2, "No"},	
			{"MID_VEHMIL", "Real", 8, 2, "No"},	
			{"PM_VEHMIL", "Real", 8, 2, "No"},	
			{"NIG_VEHMIL", "Real", 8, 2, "No"},	
			{"WKDY_VEHHR", "Real", 12, 2, "No"},
			{"WKDY_VEHMI", "Real", 12, 2, "No"},
			{"ADJWD_VEHR", "Real", 14, 2, "No"},
			{"ADJWD_VEMI", "Real", 14, 2, "No"},				
			{"ANN_VEHRS", "Real", 14, 2, "No"},
			{"ANN_VEMIL", "Real", 14, 2, "No"},
			{"PAX_HOURS", "Real", 12, 2, "No"},
			{"PAX_MILES", "Real", 12, 2, "No"}		
			
	}

	
		operations_name = "OPERATION_STATISTICS"	
		operations_file = Dir + "\\Report\\OPERATION_STATISTICS.dbf"

	//---- close open view ----

	on notfound do
		goto continue3
	end
	              
	tmp = GetViews ()
	if (tmp <> null) then do
		views = tmp [1]
		for k = 1 to views.length do
			if (views [k] = operations_name) then 
				CloseView (views [k])
		end
	end

	continue3:

	operations_view = CreateTable (operations_name, operations_file, "DBASE", operations_info)


	// -- create a table to store the Operation Statistics Categorized by Transit Corridors
	
	corr_info = {
			{"CORR_ID", "Integer", 8, null, "No"},
			{"CORR_NAME", "String", 35, null, "No"},
			{"AM_TRIPS", "Integer", 8, null, "No"},	
			{"MID_TRIPS", "Integer", 8, null, "No"},	
			{"PM_TRIPS", "Integer", 8, null, "No"},	
			{"NIGHT_TRIP", "Integer", 8, null, "No"},
			{"AM_VEHRS", "Real", 8, 2, "No"},	
			{"MID_VEHRS", "Real", 8, 2, "No"},	
			{"PM_VEHRS", "Real", 8, 2, "No"},	
			{"NIG_VEHRS", "Real", 8, 2, "No"},	
			{"AM_VEHMIL", "Real", 8, 2, "No"},	
			{"MID_VEHMIL", "Real", 8, 2, "No"},	
			{"PM_VEHMIL", "Real", 8, 2, "No"},	
			{"NIG_VEHMIL", "Real", 8, 2, "No"},	
			{"WKDY_VEHHR", "Real", 12, 2, "No"},
			{"WKDY_VEHMI", "Real", 12, 2, "No"},
			{"ADJWD_VEHR", "Real", 14, 2, "No"},
			{"ADJWD_VEMI", "Real", 14, 2, "No"},				
			{"ANN_VEHRS", "Real", 14, 2, "No"},
			{"ANN_VEMIL", "Real", 14, 2, "No"},	
			{"PAX_HOURS", "Real", 12, 2, "No"},
			{"PAX_MILES", "Real", 12, 2, "No"}	
			
	}

	corr_name = "OPERATION_STATISTICS_ByCorr"	
	corr_file = Dir + "\\Report\\OPERATION_STATISTICS_ByCorr.dbf"

	//---- close open view ----

	on notfound do
		goto continue4
	end
	              
	tmp = GetViews ()
	if (tmp <> null) then do
		views = tmp [1]
		for k = 1 to views.length do
			if (views [k] = corr_name) then 
				CloseView (views [k])
		end
	end

	continue4:

	corr_view = CreateTable (corr_name, corr_file, "DBASE", corr_info)

	// --- get the name of the line layer

	info = GetRouteSystemInfo(route_file)
	netname = info[2]
	net_file = Dir + "\\"+netname+".dbd"

	ID = "Key"

	// --- Open the Route System

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



	//--------------------------------- Joining Vehicle Routes and Routes -----------------------------------

	on notfound default
	setview("Vehicle Routes")

	opentable("Routes", "DBASE", {Dir + "\\Routes.dbf",})

	// Fill Key_NUM, TC v.7 would not accept routes_view.routes.key below(maybe because of sort?)
	setview("Routes")
	vkey = GetDataVector("Routes|","KEY",) 	
	SetDataVector("Routes|","KEY_NUM", vkey,)
	setview("Vehicle Routes")

	routes_view = joinviews("routes_view", "[Vehicle Routes].Key", "ROUTES.KEY",)

	//--- Select Routes by variable \routes.dbf ALT_FLAG

	query = "Select * where ALT_FLAG = 1"
	n_select = SelectByQuery("Selection", "Several", query,)
	
	// --- Create the output file that summarizes the Ridership by Vehicle Routes

	rec = 0
	nrec = GetRecordCount (routes_view, "Selection")
	CreateProgressBar ("Processing Vehicle Route" + String(nrec) + " Transit Routes", "True")   
	
	routes_rec = GetFirstRecord (routes_view + "|Selection", {{"Track", "Ascending"},{"ROUTES.KEY", "Ascending"}})

	while routes_rec <> null do
		rec = rec + 1
		percent = r2i (rec * 100 / nrec)

		cancel = UpdateProgressBar ("Processing Vehicle Route " + String (rec) + " of " + String (nrec) + " Transit Routes", percent)

		if cancel = "True" then do
			DestroyProgressBar () 
			goto userkill
		end

		field_array = GetFields (routes_view, "All")
		fld_names = field_array [1]
			
		route_id = routes_view.Route_ID
		keynum = routes_view.KEY_NUM
			
		route_name = routes_view.Route_Name
		corr = routes_view.Corr
		track = routes_view.Track
		mode = routes_view.Mode
		io = routes_view.IO
		am_head = routes_view.AM_HEAD
		mid_head = routes_view.MID_HEAD
		pm_head = routes_view.PM_HEAD
		night_head = routes_view.NIGHT_HEAD
			
		peak_headway = routes_view.AM_HEAD
		offpeak_headway = routes_view.MID_HEAD

		// --- get the AM hourly trips for calculating peak loads

		if am_head > 0 
			then am_hourly_units = Round(60/am_head,0)
			else	am_hourly_units = 0

		// --- Set the time duration depending on the Mode


		if ( mode >= 1 and mode <= 4 or mode = 11) then do		// prem buses and skip stop services
			am_service = am_service_prem
			mid_service = mid_service_prem
			pm_service = pm_service_prem
			night_service = night_service_prem
		end 
		else if ( mode = 5 or mode = 6) then do		// express buses
			am_service = am_service_xpr
			mid_service = mid_service_xpr
			pm_service = pm_service_xpr
			night_service = night_service_xpr
		end 
		else if ( mode = 8 ) then do 
			am_service = am_service_loc
			mid_service = mid_service_loc
			pm_service = pm_service_loc
			night_service = night_service_loc
		end 
		else if ( mode = 7) then do            // feeder buses
			am_service = am_service_fdr
			mid_service = mid_service_fdr
			pm_service = pm_service_fdr
			night_service = night_service_fdr
		end 
		else if ( mode = 9) then do            // Gold Rush Shuttle
			am_service = 0
			mid_service = 0
			pm_service = 0
			night_service = 0
		end


		// --- get trips, AM, Midday, PM, Night

		if am_head > 0 
			then am_peak_units = Round(am_service/am_head,0)
			else am_peak_units = 0
	
		if mid_head > 0 
			then	mid_units = Round(mid_service/mid_head,0)
			else	mid_units = 0

		if pm_head > 0 
			then pm_peak_units = Round(pm_service/pm_head,0)
			else pm_peak_units = 0

		if night_head > 0 
			then night_units = Round(night_service/night_head,0)
			else night_units = 0

				
		// -- get the corridor name
			
		setview(corrname_view)
		rh = LocateRecord(corrname_view + "|", "CORR", {corr}, {{"Exact", "True"}})
			
		if ( rh<> null) then
			corr_name = corrname_view.CORRNAME
			
		// -- Get the route length and End-to-End Running Times

		setview("Vehicle Routes")
		links = GetRouteLinks("Vehicle Routes", route_name)

		// get the link travel times from the highway network

		rlength = 0.0
		peak_tt = 0.0
		offpeak_tt = 0.0
						
		SetLayer(link_lyr)
			
			
		for i = 1 to links.length do

			rh1 = LocateRecord(link_lyr + "|", "ID", {links[i][1]}, {{"Exact", "True"}})
			if (rh1 = null) then do 
				msg = msg + {"Transit_Operations_Stats:  ERROR! - transit link " +String(links[i][1]) + " not found in the highway file"}
				AppendToLogFile(2, "Transit_Operations_Stats:  ERROR! - transit link " +String(links[i][1]) + " not found in the highway file")
				goto badend
			end
				
			rlength = rlength + link_lyr.Length

			// -- check for link direction

			if ( links[i][2] = 1) then do
					
				// -- get travel times 
				if ( mode = 5 or mode = 6 or mode = 2) 	then do   
					// -- express and streetcar mode
					peak_tt = peak_tt + link_lyr.TTPkXprAB
					offpeak_tt = offpeak_tt + link_lyr.TTFrXprAB
				end 
				else if ( mode = 11) then do      // -- skip-stop service mode
					peak_tt = peak_tt + link_lyr.TTPkSkSAB
					offpeak_tt = offpeak_tt + link_lyr.TTFrSkSAB
				end 
				else do              // --locals and premium service
					peak_tt = peak_tt + link_lyr.TTPkLocAB
					offpeak_tt = offpeak_tt + link_lyr.TTFrLocAB
				end
			end 
			else if (links[i][2] = -1) then do

				if ( mode = 5 or mode = 6 or mode = 2) then do    // -- express and streetcar mode
					peak_tt = peak_tt + link_lyr.TTPkXprBA
					offpeak_tt = offpeak_tt + link_lyr.TTFrXprBA
				end 
				else if ( mode = 11) then do      // -- skip-stop service mode
					peak_tt = peak_tt + link_lyr.TTPkSkSBA
					offpeak_tt = offpeak_tt + link_lyr.TTFrSkSBA
				end 
				else do              // --locals and premium service
					peak_tt = peak_tt + link_lyr.TTPkLocBA
					offpeak_tt = offpeak_tt + link_lyr.TTFrLocBA
				end
			end
		
		end  // end if iloop to process all links


		// --- Get Peak Riders
					
		stop_layer = "Route Stops"			
		SetView("Route Stops")
		
		select = "Select * where Route_ID = " + String(route_id)
		stop_selection = SelectByQuery ("Stops", "Several", select, )
	
		num_stops = GetRecordCount ("Route Stops", "Stops")

		stop_rec = GetFirstRecord ("Route Stops" + "|Stops", {{"Milepost", "Ascending"}})
			
		peak_boards_flag = 0
		i = 0

		total_peak_on = 0
		total_offpeak_on = 0
			
		while stop_rec <> null do
			i = i+1

			stop_id = stop_layer.ID
			node_id = stop_layer.UserID

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

				peak_on = 0
				peak_off = 0
				peak_boards = 0
				peak_riders[i] = 0
	
			end 
			else do
				pprmwalk_boards = RunMacro("OpStat Get Boardings", view_name, route_id, stop_id, pprmw_view)
				pprmdrive_boards = RunMacro("OpStat Get Boardings", view_name, route_id, stop_id, pprmd_view)
				pprmdrop_boards = RunMacro("OpStat Get Boardings", view_name, route_id, stop_id, pprmdrop_view)
		
				pbuswalk_boards = RunMacro("OpStat Get Boardings", view_name, route_id, stop_id, pbusw_view)
				pbusdrive_boards = RunMacro("OpStat Get Boardings", view_name, route_id, stop_id, pbusd_view)
				pbusdrop_boards = RunMacro("OpStat Get Boardings", view_name, route_id, stop_id, pbusdrop_view)
		
				// -- Compute the PEAK  - ON and OFF Boards
			
				peak_on = pprmwalk_boards[1] + pprmdrive_boards[1] + pprmdrop_boards[1] + pbuswalk_boards[1] + pbusdrive_boards[1] + pbusdrop_boards[1]
				peak_off = pprmwalk_boards[2] + pprmdrive_boards[2] + pprmdrop_boards[2] +  pbuswalk_boards[2] + pbusdrive_boards[2] + pbusdrop_boards[2]
			
				total_peak_on = total_peak_on + peak_on
			
				if peak_boards_flag = 0 then do
					peak_boards = peak_on
					peak_boards_flag = 1
				end 
				else do
					peak_boards = peak_boards + peak_on - peak_off
				end

				peak_riders[i] = peak_boards
				
			end  //else peak headway <> 0
				
			// --- Get the Offpeak riders
				
			if (offpeak_headway = 0) then do
				
				opprmwalk_boards[1] = 0
				opprmdrive_boards[1] = 0
				opprmdrop_boards[1] = 0
				opbuswalk_boards[1] = 0
				opbusdrive_boards[1] = 0
				opbusdrop_boards[1] = 0
				
				opprmwalk_boards[1] = 0
				opprmdrive_boards[2] = 0
				opprmdrop_boards[2] = 0
				opbuswalk_boards[2] = 0
				opbusdrive_boards[2] = 0
				opbusdrop_boards[2] = 0

				offpeak_on = 0
					
			end 
			else do

				opprmwalk_boards = RunMacro("OpStat Get Boardings", view_name, route_id, stop_id, opprmw_view)
				opprmdrive_boards = RunMacro("OpStat Get Boardings", view_name, route_id, stop_id, opprmd_view)
				opprmdrop_boards = RunMacro("OpStat Get Boardings", view_name, route_id, stop_id, opprmdrop_view)
						
				opbuswalk_boards = RunMacro("OpStat Get Boardings", view_name, route_id, stop_id, opbusw_view)
				opbusdrive_boards = RunMacro("OpStat Get Boardings", view_name, route_id, stop_id, opbusd_view)
				opbusdrop_boards = RunMacro("OpStat Get Boardings", view_name, route_id, stop_id, opbusdrop_view)
				
				// --- Get the Offpeak riders

				offpeak_on = opprmwalk_boards[1] + opprmdrive_boards[1] + opprmdrop_boards[1] + opbuswalk_boards[1] + opbusdrive_boards[1] + opbusdrop_boards[1]
						
				total_offpeak_on = total_offpeak_on + offpeak_on
		
			end    // -- end of process for summarizing offpeak boards

			SetView(stop_layer)
			stop_rec = GetNextRecord ("Route Stops" + "|Stops", null, {{"Milepost", "Ascending"}})
		end	// while stop_rec

		// -- calculate the peak load

		max_value = 0
			
		for k = 1 to i do
			if peak_riders[k] > max_value then 
				max_value = peak_riders[k]
		end
				
		peak_loading = max_value
		pkhr_load = peak_factor * peak_loading
			
		if am_hourly_units = 0 
			then load_per_unit = 0
			else load_per_unit = Round(pkhr_load/am_hourly_units,0)

			// --- Update the output file

		SetView(peakriders_view)
				
		// --- Open Premium Walk ONO File
				
		peakriders_values = {
				{"Key", keynum},		
				{"Route_ID", route_id},		
				{"Route_Name", route_name},		
				{"CORR", corr},	
				{"CORR_NAME", corr_name},
				{"TRACK", track},
				{"MODE", mode},
				{"IO", io},
				{"AM_HEAD", am_head},	
				{"PK_IVTT", peak_tt},
				{"PK_LOAD", peak_loading},
				{"PK_FACTOR", peak_factor},
				{"PKHR_LOAD", pkhr_load},
				{"PK_UNITS", am_hourly_units},
				{"UNITLOAD", load_per_unit}
			}
	
		AddRecord (peakriders_view, peakriders_values)
					
					
		// --- Update the Ridership File
			
		total_riders = total_peak_on + total_offpeak_on	

		SetView(ridership_view)
			
		ridership_values = {
				{"Key", keynum},		
				{"Route_ID", route_id},		
				{"Route_Name", route_name},		
				{"CORR", corr},
				{"CORR_NAME", corr_name},
				{"TRACK", track},
				{"MODE", mode},
				{"IO", io},
				{"PK_RIDERS", total_peak_on},
				{"OFPK_RIDER", total_offpeak_on},	
				{"TOT_RIDERS", total_riders}
			}

		AddRecord (ridership_view, ridership_values)
		
		
		// --- Update the output file that contains the operation statistics

		// -- calculate operation statistics
				
		am_vehhrs = am_peak_units * (peak_tt/60.0)
		mid_vehhrs = mid_units * (offpeak_tt/60.0)
		pm_vehhrs = pm_peak_units * (peak_tt/60.0)
		night_vehhrs = night_units * (offpeak_tt/60.0)
		wkday_vehhrs = am_vehhrs + mid_vehhrs + pm_vehhrs + night_vehhrs
		if ( mode >= 1 and mode <= 4 or mode = 11) 
			then adj_weekday_vehhrs = wkday_vehhrs * prm_vehhrs_calib_factor
			else adj_weekday_vehhrs = wkday_vehhrs * vehhrs_calib_factor
		if ( mode >= 1 and mode <= 4 or mode = 11) 
			then total_annual_vehhrs = adj_weekday_vehhrs * num_weekdays * prm_vehhrs_annual_factor
			else total_annual_vehhrs = adj_weekday_vehhrs * num_weekdays * vehhrs_annual_factor
				
		am_vehmiles = am_peak_units * rlength
		mid_vehmiles = mid_units * rlength
		pm_vehmiles = pm_peak_units * rlength
		night_vehmiles = night_units * rlength
		wkday_vehmiles = am_vehmiles + mid_vehmiles + pm_vehmiles + night_vehmiles
		if ( mode >= 1 and mode <= 4 or mode = 11) 
			then adj_weekday_vehmiles = wkday_vehmiles * prm_vehmiles_calib_factor
			else adj_weekday_vehmiles = wkday_vehmiles * vehmiles_calib_factor
		if ( mode >= 1 and mode <= 4 or mode = 11) 
			then total_annual_vehmiles = adj_weekday_vehmiles * num_weekdays * prm_vehmiles_annual_factor
			else total_annual_vehmiles = adj_weekday_vehmiles * num_weekdays * vehmiles_annual_factor
		pax_temp=0.0
				
		SetView(operations_view)
				
		// --- Open Premium Walk ONO File
				
		operations_values = {
				{"Key", keynum},		
				{"Route_ID", route_id},		
				{"Route_Name", route_name},		
				{"CORR", corr},	
				{"CORR_NAME", corr_name},
				{"TRACK", track},
				{"MODE", mode},
				{"IO", io},
				{"Length", rlength},
				{"PK_IVTT", peak_tt},
				{"OFPK_IVTT", offpeak_tt},
				{"AM_HEAD", am_head},	
				{"MID_HEAD", mid_head},	
				{"PM_HEAD", pm_head},	
				{"NIGHT_HEAD", night_head},	
				{"AM_TRIPS", am_peak_units },	
				{"MID_TRIPS", mid_units},	
				{"PM_TRIPS", pm_peak_units},	
				{"NIGHT_TRIP", night_units},
				{"AM_VEHRS", am_vehhrs},	
				{"MID_VEHRS", mid_vehhrs},	
				{"PM_VEHRS", pm_vehhrs},	
				{"NIG_VEHRS", night_vehhrs},	
				{"AM_VEHMIL", am_vehmiles},	
				{"MID_VEHMIL", mid_vehmiles},	
				{"PM_VEHMIL", pm_vehmiles},	
				{"NIG_VEHMIL", night_vehmiles},	
				{"WKDY_VEHHR", wkday_vehhrs},
				{"WKDY_VEHMI", wkday_vehmiles},
				{"ADJWD_VEHR",adj_weekday_vehhrs },
				{"ADJWD_VEMI", adj_weekday_vehmiles},				
				{"ANN_VEHRS", total_annual_vehhrs},
				{"ANN_VEMIL", total_annual_vehmiles},	
				{"PAX_HOURS", pax_temp},
				{"PAX_MILES", pax_temp}	
			}
					
		AddRecord (operations_view, operations_values)

		SetView(routes_view)

		routes_rec = GetNextRecord (routes_view + "|Selection", null, {{"Track", "Ascending"},{"ROUTES.KEY", "Ascending"}})
	end  // while routes_rec

	DestroyProgressBar () 

	// RouteOut.dbf written by Transit_Pax_Stats

	opentable("PAX", "DBASE", {Dir + "\\Report\\RouteOut.dbf",})
	pax_view=joinviews(operations_view+"+PAX", "["+operations_view+"].Key", "PAX.Key",)

	// -- Populate values for PAX_HOURS and PAX_MILES

	record = GetFirstRecord (pax_view + "|", null)

	while record <> null do
		pax_view.PAX_HOURS = pax_view.PASSHOUR
		pax_view.PAX_MILES = pax_view.PASSMILE
		record = GetNextRecord(pax_view + "|", null, null)
	end
	closeview(pax_view)
	
	
	// ---------------------------------------------
	//   "Get Ridership By Corridor"
	// ---------------------------------------------

	corr_id_file = Dir + "\\transit_corridor_id.dbf"

	info = GetFileInfo(corr_id_file)
	if ( info = null) then do
		msg = msg + {"Transit_Operations_Stats:  ERROR! - transit_corridor_id.dbf not found"}
		AppendToLogFile(2, "Transit_Operations_Stats:  ERROR! - transit_corridor_id.dbf not found")
		goto badend
	end

	corr_file_view = opentable("Transit Corridors", "DBASE", {Dir + "\\transit_corridor_id.dbf",})	
		
	
	rec = 0
	nrec = GetRecordCount (operations_view, null)
	CreateProgressBar ("Processing Vehicle Route" + String(nrec) + " Transit Routes", "True")   
	
	routes_rec = GetFirstRecord (operations_view + "|", null)

	while routes_rec <> null do
		rec = rec + 1
		percent = r2i (rec * 100 / nrec)

		cancel = UpdateProgressBar ("Processing Vehicle Route " + String (rec) + " of " + String (nrec) + " Transit Routes", percent)

		if cancel = "True" then do
			DestroyProgressBar () 
			goto userkill
		end

		current_rec = GetRecord(operations_view)
			
		corr = operations_view.CORR
			
		// --- Get the Corridor Name
			
		SetView(corr_file_view)
			
		rh = LocateRecord (corr_file_view + "|", "CORR", {corr},{{"Exact", "True"}})
								
		if ( rh = null) 
			then corr_name = " " 
			else corr_name = corr_file_view.CORRNAME
					
		// -- initialize variables
			
		am_trips = 0
		mid_trips = 0
		pm_trips = 0
		night_trips = 0
		am_vehhrs = 0
		mid_vehhrs = 0
		pm_vehhrs = 0
		night_vehhrs = 0
		am_vehmiles = 0
		mid_vehmiles = 0
		pm_vehmiles = 0
		night_vehmiles = 0
		wkday_vehhrs = 0
		wkday_vehmiles = 0
		adjwkday_vehhrs = 0	
		adjwkday_vehmiles = 0
		annual_vehhrs = 0
		annual_vehmiles = 0
		pax_hrs = 0
		pax_miles = 0
			

		// --- identify all the routes that belong to this track
			
		SetView(operations_view)
		selection = "Select * where CORR = " + String(corr) 
		record_selection = SelectByQuery ("Selection", "Several", selection,)
		num_select = GetRecordCount (operations_view, "Selection")
			
		corrrec = GetFirstRecord (operations_view + "|Selection", null)
							
		while corrrec <> null do
					
			am_trips = am_trips + operations_view.AM_TRIPS
			mid_trips = mid_trips + operations_view.MID_TRIPS
			pm_trips = pm_trips + operations_view.PM_TRIPS
			night_trips = night_trips + operations_view.NIGHT_TRIP
				
			am_vehhrs = am_vehhrs + operations_view.AM_VEHRS
			mid_vehhrs = mid_vehhrs + operations_view.MID_VEHRS
			pm_vehhrs = pm_vehhrs + operations_view.PM_VEHRS
			night_vehhrs = night_vehhrs + operations_view.NIG_VEHRS
				
			am_vehmiles = am_vehmiles + operations_view.AM_VEHMIL
			mid_vehmiles = mid_vehmiles + operations_view.MID_VEHMIL
			pm_vehmiles = pm_vehmiles + operations_view.PM_VEHMIL
			night_vehmiles = night_vehmiles + operations_view.NIG_VEHMIL

			wkday_vehhrs = wkday_vehhrs + operations_view.WKDY_VEHHR
			wkday_vehmiles = wkday_vehmiles + operations_view.WKDY_VEHMI
				
			adjwkday_vehhrs = adjwkday_vehhrs + operations_view.ADJWD_VEHR
			adjwkday_vehmiles = adjwkday_vehmiles + operations_view.ADJWD_VEMI
				

			annual_vehhrs = annual_vehhrs + operations_view.ANN_VEHRS
			annual_vehmiles = annual_vehmiles + operations_view.ANN_VEMIL
					
			pax_hrs = pax_hrs + operations_view.PAX_HOURS
			pax_miles = pax_miles + operations_view.PAX_MILES

			corrrec = GetNextRecord (operations_view + "|Selection", null, null)
		end  // while correc
	

		// -- AddRecord
	
		SetView(corr_view)
			
		// --- Get the Corridor Name 
						
		rh = LocateRecord (corr_view + "|", "CORR_ID", {corr},{{"Exact", "True"}})
					
		if ( rh = null) then do
				
			corr_values = {
				{"CORR_ID", corr},
				{"CORR_NAME", corr_name},
				{"AM_TRIPS", am_trips},	
				{"MID_TRIPS", mid_trips},	
				{"PM_TRIPS", pm_trips},	
				{"NIGHT_TRIP", night_trips},
				{"AM_VEHRS", am_vehhrs},	
				{"MID_VEHRS", mid_vehhrs},	
				{"PM_VEHRS", pm_vehhrs},	
				{"NIG_VEHRS", night_vehhrs},	
				{"AM_VEHMIL", am_vehmiles},	
				{"MID_VEHMIL", mid_vehmiles},	
				{"PM_VEHMIL", pm_vehmiles},	
				{"NIG_VEHMIL", night_vehmiles},	
				{"WKDY_VEHHR", wkday_vehhrs},
				{"WKDY_VEHMI",  wkday_vehmiles},
				{"ADJWD_VEHR", adjwkday_vehhrs},
				{"ADJWD_VEMI", adjwkday_vehmiles},				
				{"ANN_VEHRS", annual_vehhrs},
				{"ANN_VEMIL", annual_vehmiles},	
				{"PAX_HOURS", pax_hrs},
				{"PAX_MILES", pax_miles}	
			}					

					
			AddRecord(corr_view, corr_values)
		end
	
	
		SetView(operations_view)
			
		SetRecord(operations_view, current_rec)
		routes_rec = GetNextRecord (operations_view + "|", null, null)
	end

	DestroyProgressBar () 

	closemap()
	vws = GetViewNames()
	for i = 1 to vws.length do
		CloseView(vws[i])
	end

	goto quit

	badend:
		TransitOpsOK = 0
		msg = msg + {"Transit_Operations_Stats: ERROR end"}
		AppendToLogFile(2, "Transit_Pax Stats: ERROR end")
		goto quit
		    
	userkill:
		TransitOpsOK = 0
		msg = msg + {"Transit_Operations_Stats: Killed by User"}
		AppendToLogFile(2, "Transit_Pax Stats: Killed by User")
		goto quit
		    
	quit:
		datentime = GetDateandTime()
		AppendToLogFile(1, "Exit Transit_Pax_Stats " + datentime)
		return({TransitPaxOK, msg})

EndMacro

// **************************************
//   Macro to Summarize Boardings
// ***************************************

Macro "OpStat Get Boardings" (view_name, route_id, stop_id, view_name)
	
	dim boards[2]
	SetView(view_name)

	selection = "Select * where ROUTE = " + String(route_id) + " and STOP = " + String(stop_id)
	record_selection = SelectByQuery ("Select Record", "Several", selection,)
	num_select = GetRecordCount (view_name, "Select Record")
	
	if (num_select > 1) then 
		ShowMessage("OpStat Get Boardings More than one record Selected...PROBLEM HERE")
	else if (num_select = 0) then do		// --- no records are found in the boardings file
			boards[1] = 0.0
			boards[2] = 0.0
	end 
	else do
		selected_record = GetFirstRecord (view_name + "|Select Record", null)
		boards[1] = view_name.On
		boards[2] = view_name.Off
	end
	
	Return(boards)

endMacro
