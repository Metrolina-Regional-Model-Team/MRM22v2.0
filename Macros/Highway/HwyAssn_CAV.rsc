macro "HwyAssn_CAV" (Args, hwyassnarguments, timeperiod)

//*********************************************************************************************************************

/* 		SCENARIO PLANNING:

this macro does NOT do HOT assignment

rather, it uses the HOT priciples to restrict use of the managed lanes to only CAV vehicles (funcl 25 and 83)

instead of dividing the OD tables into HOT/non-HOT, the tables are divided into CAV (60%) and non-CAV


*/
//********************************************************************************************************************

	on error goto TCError
	on escape goto UserKill

	METDir = "C:\\1ScenarioPlanning\\Metrolina"				//   NEED to HARD CODE  
	Dir = "C:\\1ScenarioPlanning\\Metrolina\\2050"									//

	ODDir = Dir + "\\TOD2\\"
	assnDir = Dir + "\\HwyAssn"	//"\\HwyAssn\\CAV"			

	timeweight = 1
	distweight = 0

	PERIOD_ar  = {"AM", "PM", "MD", "NT"} 
	hwyassn_ar = {"AMPeak", "PMPeak", "Midday", "Night"} 
	cap_field_ar  = {"CapPk3hr", "CapPk3hr", "CapMid", "CapNight"}
	od_matrix_ar  = {"ODHwyVeh_AMPeak.mtx", "ODHwyVeh_PMPeak.mtx", "ODHwyVeh_Midday.mtx", "ODHwyVeh_Night.mtx"} 
	od_cav_matrix_ar = {"ODHwyVeh_AMPeakCAV.mtx", "ODHwyVeh_PMPeakCAV.mtx", "ODHwyVeh_MiddayCAV.mtx", "ODHwyVeh_NightCAV.mtx"}
	netview_ar = {"RegNet50_AMPeak", "RegNet50_PMPeak", "RegNet50_Offpeak", "RegNet50_Offpeak"}

	hwyassnmaxiter = 25000
	hwyassnconverge = 0.0001
	hwyassntype = "BPR"

	CAVPERCENT = 0.6	//Assumes the CAV population is 60% for all vehicles  (if change by vehicle class, then would need to create array)

  	RunMacro("TCB Init")


//*******************************************************************
//*
//*  LOOP THROUGH time periods	(AM, PM, MD, NT)	(not ITERATIONS) 
//*
//*******************************************************************

	for tp = 1 to 4 do	//  

			netview = netview_ar[tp]
		
			cap_fields = "[" + cap_field_ar[tp] + "AB / " + cap_field_ar[tp] + "BA]"
			od_matrix = ODDir + od_matrix_ar[tp]
			od_cav_matrix = ODDir + od_cav_matrix_ar[tp]		
//			input_bin = Dir + "\\HwyAssn\\Assn_" + hwyassn_ar[tp] + ".bin"		
			output_bin = Dir + "\\HwyAssn\\Assn_" + hwyassn_ar[tp] + "CAV.bin"		
		
/*			temp = SplitPath(input_bin)
			input_name = temp[3]
		
			temp = SplitPath(output_bin)
			output_dcb = temp[1] + temp[2] + temp[3] + ".dcb"
*/		
			timewgtassn = sqrt(timeweight)
			
			net_file = Dir + "\\" + netview + ".dbd"
		
			info = GetDBInfo(net_file)
			scope = info[1]
			CreateMap(netview, {{"Scope", scope},{"Auto Project", "True"}})
			layers = GetDBLayers(net_file)
			node_lyr = addlayer(netview, layers[1], net_file, layers[1])
			link_lyr = addlayer(netview, layers[2], net_file, layers[2])
			SetLayerVisibility(node_lyr, "False")
			SetIcon(node_lyr + "|", "Font Character", "Caliper Cartographic|4", 36)
			SetLayerVisibility(link_lyr, "True")
			solid = LineStyle({{{1, -1, 0}}})
			SetLineStyle(link_lyr+"|", solid)
			SetLineColor(link_lyr+"|", ColorRGB(0, 0, 32000))
			SetLineWidth(link_lyr+"|", 0)
		
			setview(netview)
		
				//create .dcb file for assignment
//				CopyFile(assnDir + "\\Assn_template.dcb", assnDir + "\\Assn_" + PERIOD_ar[tp] + ".dcb")
		
		m = OpenMatrix(od_matrix, )
		mc = CreateMatrixCurrency(m, "SOV", "Rows", "Columns",)
		new_mat = CopyMatrix(mc, {{"File Name", od_cav_matrix},
		    {"Label", "ODHwyVeh_"+PERIOD_ar[tp]+"cav"},
		    {"File Based", "Yes"}})
		
				if GetView()<>netview then do
		
					info = GetDBInfo(net_file)
					scope = info[1]
					CreateMap(netview, {{"Scope", scope},{"Auto Project", "True"}})
					layers = GetDBLayers(net_file)
					node_lyr = addlayer(netview, layers[1], net_file, layers[1])
					link_lyr = addlayer(netview, layers[2], net_file, layers[2])
					SetLayerVisibility(node_lyr, "False")
					SetIcon(node_lyr + "|", "Font Character", "Caliper Cartographic|4", 36)
					SetLayerVisibility(link_lyr, "True")
					solid = LineStyle({{{1, -1, 0}}})
					SetLineStyle(link_lyr+"|", solid)
					SetLineColor(link_lyr+"|", ColorRGB(0, 0, 32000))
					SetLineWidth(link_lyr+"|", 0)
		
					setview(netview)
				end
				
		//***************************************************************
		//								*
		//   Create highway network with CAV lanes			*
		//								*
		//***************************************************************
		// Build Highway Network
		     	Opts = null
		     	Opts.Input.[Link Set] = {Dir + "\\"+netview+".DBD|"+netview, netview, "CAV", "Select * where (funcl > 0 and funcl < 10) or funcl = 90 or funcl = 22 or funcl = 24 or funcl = 82 or funcl = 23 or funcl = 25 or funcl = 83"}
		     	Opts.Global.[Network Options].[Node ID] = "Node.ID"
		     	Opts.Global.[Network Options].[Link ID] = netview+".ID"
		     	Opts.Global.[Network Options].[Turn Penalties] = "Yes"
		     	Opts.Global.[Network Options].[Keep Duplicate Links] = "FALSE"
		     	Opts.Global.[Network Options].[Ignore Link Direction] = "FALSE"
		
//		     	Opts.Global.[Link Options] = {{"Length", netview+".Length", netview+".Length"}, {"[ImpCAVAB / ImpCAVBA]", netview+".ImpCAVAB", netview+".ImpCAVBA"}, {"[TTCAVAB / TTCAVBA] ", netview+".TTCAVAB", netview+".TTCAVBA"}, {"[CAVAB / CAVBA]", netview+".CAVAB", netview+".CAVBA"}}
				Opts.Global.[Link Options] = 
					{{"Length", {netview+".Length", netview+".Length", , , "False"}}, 
					 {"alpha", {netview+".alpha", netview+".alpha", , , "False"}},
					 {"beta", {netview+".beta", netview+".beta", , , "False"}}, 
					 {"[TTFreeAB / TTFreeBA]", {netview+".TTFreeAB", netview+".TTFreeBA", , , "True"}},
					 {"[CapPk3hrAB / CapPk3hrBA]", {netview+".CapPk3hrAB", netview+".CapPk3hrBA", , , "False"}},
					 {"[capMidAB / capMidBA]", {netview+".capMidAB", netview+".capMidBA", , , "False"}},
					 {"[capNightAB / capNightBA]", {netview+".capNightAB", netview+".capNightBA", , , "False"}},
					 {"[TollAB / TollBA]", {netview+".TollAB", netview+".TollBA", , , "False"}}}
		     	Opts.Output.[Network File] = Dir + "\\net_cav.net"
		
		     	ret_value = RunMacro("TCB Run Operation", 6, "Build Highway Network", Opts)
		     	if !ret_value then goto badnetbuild
		
		//Highway Network Setting
		    	Opts = null
		     	Opts.Input.Database = Dir + "\\"+netview+".DBD"
		     	Opts.Input.Network = Dir + "\\net_cav.net"
		     	Opts.Input.[Centroids Set] = {Dir + "\\"+netview+".DBD|Node", "Node", "centroid", "Select * where centroid = 1 or centroid = 2"}
				Opts.Input.[Spc Turn Pen Table]= {METDir + "\\trnpnlty.bin"}
		    	Opts.Global.[Global Turn Penalties] = {0, 0, 0, -1}
		
		     	ret_value = RunMacro("TCB Run Operation", 7, "Highway Network Setting", Opts)
		
		
				//***************************************************************Gallup
				//		
				// Add 6 cores to OD matricies CAV				changed to 6 cores for CAV only
				//  								
				//***************************************************************Gallup
				CAV = OpenMatrix(od_cav_matrix,)
		
				CAV_Cores = GetMatrixCoreNames(CAV)
			
				gotSOV = "False"
				gotP2 = "False"
				gotP3 = "False"
				gotCOM = "False"
				gotMTK = "False"
				gotHTK = "False"
		
				for i = 1 to CAV_Cores.length do
					if CAV_Cores[i] = "CAVSOV" then gotSOV = "True"
					if CAV_Cores[i] = "CAVPOOL2" then gotP2 = "True"
					if CAV_Cores[i] = "CAVPOOL3" then gotP3 = "True"		//added for CAV only
					if CAV_Cores[i] = "CAVCOM" then gotCOM = "True"
					if CAV_Cores[i] = "CAVMTK" then gotMTK = "True"
					if CAV_Cores[i] = "CAVHTK" then gotHTKM = "True"
				end
		
				if gotSOV = "False" then AddMatrixCore(CAV, "CAVSOV")
				if gotP2 = "False" then AddMatrixCore(CAV, "CAVPOOL2")
				if gotP3 = "False" then AddMatrixCore(CAV, "CAVPOOL3")		//added for CAV only
				if gotCOM = "False" then AddMatrixCore(CAV, "CAVCOM")
				if gotMTK = "False" then AddMatrixCore(CAV, "CAVMTK")
				if gotHTK = "False" then AddMatrixCore(CAV, "CAVHTK")
		
		
				//***************************************************************
				//								*
				// Fill CAV cores with cores * CAVPERCENT				*
				//  								*
				//***************************************************************
		
				mc_array = CreateMatrixCurrencies(CAV,,,)
				mc1 = mc_array.SOV
				mc2 = mc_array.POOL2
				mc3 = mc_array.POOL3
				mc4 = mc_array.COM
				mc5 = mc_array.MTK
				mc6 = mc_array.HTK
				mc7 = mc_array.CAVSOV
				mc8 = mc_array.CAVPOOL2
				mc9 = mc_array.CAVPOOL3
				mc10 = mc_array.CAVCOM
				mc11 = mc_array.CAVMTK
				mc12 = mc_array.CAVHTK
		
				mc7 := mc1 * CAVPERCENT		//CAV = 60% of total
				mc8 := mc2 * CAVPERCENT
				mc9 := mc3 * CAVPERCENT
				mc10 := mc4 * CAVPERCENT
				mc11 := mc5 * CAVPERCENT
				mc12 := mc6 * CAVPERCENT
		
				mc1 := mc1 - mc7			//remove CAVs from total
				mc2 := mc2 - mc8
				mc3 := mc3 - mc9
				mc4 := mc4 - mc10
				mc5 := mc5 - mc11
				mc6 := mc6 - mc12
		
		
				//***************************************************************
				//								*
				//  Assignment							*
				//								*
				//***************************************************************
		
				//Build Highway Network
				Opts = null
		     	Opts.Input.[Link Set] = {Dir + "\\"+netview+".DBD|"+netview, netview, "hwynet", "Select * where (funcl > 0 and funcl < 10) or funcl = 22 or funcl = 23 or funcl = 24 or funcl = 25 or funcl = 82 or funcl = 83 or funcl = 90"}
				Opts.Global.[Network Options].[Link Type] = {"funcl", netview+".funcl", netview+".funcl"}
				Opts.Global.[Network Options].[Time Unit] = "Minutes"
				Opts.Global.[Network Options].[Node ID] = "Node.ID"
				Opts.Global.[Network Options].[Link ID] = netview+".ID"
				Opts.Global.[Network Options].[Turn Penalties] = "Yes"
				Opts.Global.[Network Options].[Keep Duplicate Links] = "FALSE"
				Opts.Global.[Network Options].[Ignore Link Direction] = "FALSE"
				Opts.Global.[Link Options] = 
					{{"Length", {netview+".Length", netview+".Length", , , "False"}}, 
					 {"alpha", {netview+".alpha", netview+".alpha", , , "False"}},
					 {"beta", {netview+".beta", netview+".beta", , , "False"}}, 
					 {"[TTFreeAB / TTFreeBA]", {netview+".TTFreeAB", netview+".TTFreeBA", , , "True"}},
					 {"[CapPk3hrAB / CapPk3hrBA]", {netview+".CapPk3hrAB", netview+".CapPk3hrBA", , , "False"}},
					 {"[capMidAB / capMidBA]", {netview+".capMidAB", netview+".capMidBA", , , "False"}},
					 {"[capNightAB / capNightBA]", {netview+".capNightAB", netview+".capNightBA", , , "False"}},
					 {"[TollAB / TollBA]", {netview+".TollAB", netview+".TollBA", , , "False"}}}
				Opts.Global.[Length Unit] = "Miles"
				Opts.Global.[Time Unit] = "Minutes"
		 		Opts.Output.[Network File] = Dir + "\\net_highway.net"
		
				ret_value = RunMacro("TCB Run Operation", 22, "Build Highway Network", Opts, &Ret)
		    	if !ret_value then goto badnetbuild
		
				// Highway Network Setting
			
				// determine if toll links present
				SetView(netview)
				tollquery = "Select * where TollAB > 0 or TollBA > 0"
				ntolls = SelectByQuery("TollLinks", "Several", tollquery,)
				 
				if ntolls = 0 then goto notolls2
		
				Opts = null
				Opts.Input.Database = Dir + "\\"+netview+".DBD"
				Opts.Input.Network = Dir + "\\net_highway.net"
				Opts.Input.[Centroids Set] = {Dir + "\\"+netview+".DBD|Node", "Node", "centroid", "Select * where centroid = 1 or centroid = 2"}
				Opts.Input.[Spc Turn Pen Table]= {METDir + "\\trnpnlty.bin"}
				Opts.Input.[Toll Set]= {Dir + "\\"+netview+".DBD|"+netview, netview, "tollset", "Select * where TollAB > 0 or TollBA > 0"}
				Opts.Global.[Global Turn Penalties] = {0, 0, 0, -1}
		
				ret_value = RunMacro("TCB Run Operation", 23, "Highway Network Setting", Opts, &Ret)
				if !ret_value then goto badnetsettings
		
				// MMA Assignment 
				//exclude link sets for 12 vol classes
				// 1 = sov - exclude from all managed lanes (funcl 22,82 & 25,83 & 23=noncavexclude)
				// 2 = pool2 - exclude from all managed lanes (noncavexclude)
				// 3 = pool3 - exclude from all managed lanes (noncavexclude)
				// 4 = COM - exclude from all managed lanes (noncavexclude)
				// 5 = MTK - exclude from all managed lanes & funcl 24 (truckexclude)
				// 6 = HTK - exclude from all managed lanes & funcl 24 (truckexclude)
				// 7 = CAVSOV - no exclude 
				// 8 = CAVPOOL2 - no exclude
				// 9 = CAVPOOL3 - no exclude
				// 10 = CAVCOM - no exclude
				// 11 = CAVMTK - exclude from funcl 24 (truck24exclude)
				// 12 = CAVHTK - exclude from funcl 24 (truck24exclude)
		
				//showmessage(od_cav_matrix+" "+cap_fields+" "+output_bin+" "+netview+" "+Dir+" "+METDir)
				Opts = null
				Opts.Input.Database = Dir + "\\"+netview+".DBD"
				Opts.Input.Network = Dir + "\\net_highway.net"
				Opts.Input.[OD Matrix Currency] = {od_cav_matrix, "SOV", "Rows", "Columns"}
				Opts.Input.[Exclusion Link Sets] = 
					{{Dir + "\\"+netview+".DBD|"+netview, netview, "noncavexclude", 
									"Select * where funcl = 22 or funcl = 23 or funcl = 25"}, 
					 {Dir + "\\"+netview+".DBD|"+netview, netview, "noncavexclude"},
					 {Dir + "\\"+netview+".DBD|"+netview, netview, "noncavexclude"},
					 {Dir + "\\"+netview+".DBD|"+netview, netview, "noncavexclude"},
					 {Dir + "\\"+netview+".DBD|"+netview, netview, "trkexclude", 
					 				"Select * where funcl = 22 or funcl = 23 or funcl = 24 or funcl = 25 or funcl = 82 or funcl = 83"}, 
					 {Dir + "\\"+netview+".DBD|"+netview, netview, "trkexclude"}, , , , , 
					 {Dir + "\\"+netview+".DBD|"+netview, netview, "trk24exclude", 
					 				"Select * where funcl = 24"},
					 {Dir + "\\"+netview+".DBD|"+netview, netview, "trk24exclude"}}
				Opts.Field.[Vehicle Classes] = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12}
		 		Opts.Field.[PCE Fields] = {"None", "None", "None", "None", "None", "None", "None", "None", "None", "None", "None", "None"}
				Opts.Global.[Number of Classes] = 12
				Opts.Field.[Fixed Toll Fields] = {"[TollAB / TollBA]", "[TollAB / TollBA]", "[TollAB / TollBA]", "[TollAB / TollBA]",  "[TollAB / TollBA]", "[TollAB / TollBA]",
									"[TollAB / TollBA]", "[TollAB / TollBA]", "[TollAB / TollBA]", "[TollAB / TollBA]", "[TollAB / TollBA]", "[TollAB / TollBA]"}
				Opts.Global.[Class PCEs] = {1, 1, 1, 1, 1.5, 2.5, 1, 1, 1, 1, 1.5, 2.5}
				Opts.Global.[Class VOIs] = {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1}
		
		// *********************************************************
		//	Change from gc_mrm.vdf to bpr.vdf, Sept 2016
		
				if hwyassntype = "BPR" 
					then do
						Opts.Global.[Cost Function File] = "bpr.vdf"
						Opts.Global.[VDF Defaults] = {, , 0.15, 4, }
						Opts.Field.[VDF Fld Names] = {"[TTfreeAB / TTfreeBA]", cap_fields, "alpha", "beta", "None"}
					end
					else do
						Opts.Global.[Cost Function File] = "gc_mrm.vdf"
						Opts.Global.[VDF Defaults] = {, , 0.15, 4, 0, distweight, timeweight, , 0}
						Opts.Field.[VDF Fld Names] = {"[TTfreeAB / TTfreeBA]", cap_fields, "alpha", "beta", "None", "[TollAB / TollBA]", "None", "Length", "None"}
					end
		
				Opts.Global.Convergence = hwyassnconverge
				Opts.Global.Iterations = hwyassnmaxiter
		
				Opts.Flag.[Do Critical] = 0
				Opts.Flag.[Do Share Report] = 1   
				Opts.Output.[Flow Table] = output_bin
				
				ret_value = RunMacro("TCB Run Procedure", 25, "MMA", Opts)
		
				if !ret_value then goto badassign				
				closemap()
				
end // loop on time periods

	goto quit

	badnetbuild:
	msg = msg + {"HOT HwyAssn - ERROR building highway network, check for HOTAB & HOTBA network fields"}
	AppendToLogFile(2, "HOT HwyAssn - ERROR building highway network, check for HOTAB & HOTBA network fields")
	HOTHwyAssnOK = 0
	goto badquit
	
	badnetsettings:
	msg = msg + {"HOT HwyAssn - ERROR in highway network settings"}
	AppendToLogFile(2, "HOT HwyAssn - ERROR in highway network settings")
	HOTHwyAssnOK = 0
	goto badquit

	badassign:
	msg = msg + {"HOT HwyAssn - ERROR in highway assignment"}
	AppendToLogFile(2, "HOT HwyAssn - ERROR in highway assignment")
	HOTHwyAssnOK = 0
	goto badquit

	badquit:
	msg = msg + {"badquit: Last error message= " + GetLastError()}
	AppendToLogFile(2, "badquit: Last error message= " + GetLastError())
	RunMacro("TCB Closing", ret_value, "TRUE" )
	RunMacro("TCB Closing", ret_value, "TRUE" )
	goto quit

	TCError:
	errmsg = GetLastError()
	msg = msg + {"HOT HwyAssn - TC ERROR : "+ errmsg}
	AppendToLogFile(2, "HOT HwyAssn - TC ERROR : "+ errmsg)
	HOTHwyAssnOK = 0
	goto quit

	UserKill:
	msg = msg + {"HOT HwyAssn - User killed job" }
	AppendToLogFile(2, "HOT HwyAssn - User killed job")
	HOTHwyAssnOK = 0
	goto quit

	notolls2:
	
	quit:
	on error default
	on escape default
	RunMacro("G30 File Close All")
	datentime = GetDateandTime()
	AppendToLogFile(1, "Exit HwyAssn_HOT: " + datentime)
	return(HOTHwyAssnOK)

EndMacro

