Macro "Tour_RunStats" (Args)

//Creates the "ProductionsByCo" and "AttractionsByCo" files (.bin)

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
	AppendToLogFile(1, "Tour_ProdAttrByCounty: " + datentime)
	RunMacro("TCB Init")

	RunMacro("G30 File Close All") 

	DirTG  = Dir + "\\TG"
 	DirOutDC  = Dir + "\\TD"
	DirReport  = Dir + "\\Report"
 	
 	yr_str = Right(theyear,2)
	yr = s2i(yr_str)

  CreateProgressBar("Tour Run Stats", "TRUE")

/*	counties = {{37025, "Cabarrus"}, {37035, "Catawba"}, {37045, "Cleveland"}, {37071, "Gaston"}, {37097, "Iredell"}, {37109, "Lincoln"}, {37119, "Mecklenburg"}, 
			{37159, "Rowan"}, {37167, "Stanly"}, {37179, "Union"}, {45057, "Lancaster"}, {45091, "York"}, {99999, "External"}}
	stcnty_tab = OpenTable("stcnty_tab", "DBASE", {MetDir + "\\STCNTY_ID.dbf",})
	stcnty = GetDataVector(stcnty_tab + "|", "STCNTY",)
	counties = GetDataVector(stcnty_tab + "|", "NAME",)

	se_vw = OpenTable("SEFile", "dBASE", {sedata_file,})
*/

//*******************************************************************************************************************************************************************
//Creates DC_output, ODtime_dist & StopsDistr files

//Macro "DC_output"

  UpdateProgressBar("Runstats DC_output", 10) 

	purp = {"EXT", "XIW", "XIN"}	// IMPORTANT, USE THIS ORDER, otherwise need to change loop below

	maxtimeslots = 36	//this is the number of time ranges in ten minute increments: ie, 18 would be "0-5" to "170+"
	
	//create a table to output the number of tours in 5 minute bins
	ODtime_tab = CreateTable("ODtime_tab", DirReport + "\\Ext_distr.bin", "FFB", {{"TimeDistr", "String", 10, , "No"}}) 
	tabstrct = GetTableStructure(ODtime_tab)						
	for j = 1 to tabstrct.length do
 		tabstrct[j] = tabstrct[j] + {tabstrct[j][1]}
 	end
	for j = 1 to purp.length do
		tabstrct = tabstrct + {{purp[j], "Integer", 8,,,,,,,,,}}
 	end
	ModifyTable(ODtime_tab, tabstrct)
	rh = AddRecords("ODtime_tab", , ,{{"Empty Records", (maxtimeslots)}})
	dim time_ar[maxtimeslots]
	buck = 0
	for t = 1 to (maxtimeslots - 1) do
		time_ar[t] = "[" + i2s(buck) + "_" + i2s(buck+5) + "]"
		buck = buck +5
	end
	time_ar[maxtimeslots] = "[" + i2s((maxtimeslots-1)*5) + "+]"
	time_v = a2v(time_ar)
	SetDataVector("ODtime_tab|", "TimeDistr",time_v,)
	
	//create a temp file with number of time slots in order to join to DC file
	temp_tab = CreateTable("temp_tab", "temptab", "MEM", {{"Num", "Short", 2, , "No"}}) 
//	temp_tab = CreateTable("temp_tab", "temptab.bin", "FFB", {{"Num", "Short", 2, , "No"}}) 
	rh = AddRecords("temp_tab", , ,{{"Empty Records", (maxtimeslots)}})
	num_v = Vector(maxtimeslots, "short", {{"Sequence", 0, 1}})
	SetDataVector("temp_tab|", "Num", num_v,)

	ix_file = OpenTable("ix_file", "FFB", {DirOutDC + "\\dcEXT.bin",})
	for p = 1 to purp.length do	// IXs selected by purpose as part of this loop; XIW and XIN in the next loop
		current_file = OpenTable("current_file", "FFB", {DirOutDC + "\\dc" + purp[p] + ".bin",})
		SetView(current_file)
/*		TTpa_v = GetDatavector(current_file + "|", "TourTT_PA",)
		ttpa = VectorStatistic(TTpa_v, "Mean",)		
		TTap_v = GetDatavector(current_file + "|", "TourTT_AP",)
		ttap = VectorStatistic(TTap_v, "Mean",)		
		if p < 7 then do	// II, IX, intrazonals:
			iirec = GetRecordCount("current_file", )
			OD_v = GetDatavector(current_file + "|", "OD_Time",)
			avgtimeii = VectorStatistic(OD_v, "Mean",)		
			qry1 = "Select * where ORIG_TAZ = DEST_TAZ"
			intrarec = SelectByQuery("intrarec", "Several", qry1)
			SetView(ix_file)
			qry2 = "Select * where PURP = '" + purp[p] + "'"
			ixrec = SelectByQuery("ixrec", "Several", qry2)
			ODix_v = GetDatavector("ix_file|ixrec", "OD_Time",)
			avgtimeix = VectorStatistic(ODix_v, "Mean",)
			SetRecordValues("DCout_tab", i2s(p), {{"II_Tours", iirec}, {"IX_Tours", ixrec}, {"Intrazonal", intrarec}, {"AVG_Time_II", avgtimeii}, {"AVG_Time_IX", avgtimeix}, {"AVGTourTT_PA", ttpa}, {"AVGTourTT_AP", ttap}})
		end
		else do		// XI	
			xirec = GetRecordCount("current_file", )
			OD_v = GetDatavector(current_file + "|", "OD_Time",)
			avgtimexi = VectorStatistic(OD_v, "Mean",)		
			SetRecordValues("DCout_tab", i2s(p), {{"XI_Tours", xirec}, {"AVG_Time_XI", avgtimexi}, {"AVGTourTT_PA", ttpa}, {"AVGTourTT_AP", ttap}})
		end
*/		
		// OD time distribution:
		OD_floor = CreateExpression("current_file", "ODFloor", "if OD_Time > " + i2s(maxtimeslots*5) + " then (" + i2s(maxtimeslots) + " - 1) else Floor(OD_Time/5)",)	//divide by 5 to get bucket			
		join = JoinViews("join", "temp_tab.Num", "current_file.ODFloor",{{"A", }})
		od_dist = GetDataVector("join|", "[N current_file]",)
		SetDataVector("ODtime_tab|", purp[p], od_dist,)
		CloseView(join)
		// Stops Distribution:
		SetView(current_file)
		counter = 1
		for d = 1 to 2 do
			for s = 1 to 8 do				
				qry = "Select * where IS_" + appa[d] + " = " + i2s(s - 1)
				numstops = SelectByQuery("stopsarr", "Several", qry)
				SetRecordValues("stopsdistr_tab", i2s(p), {{appa[d] + i2s(s-1) + "Stops", numstops}})
			end
		end

		CloseView(current_file)
	end
	DCout_tab2 = ExportView("DCout_tab|", "CSV", DirReport + "\\DC_output.csv",{"PURP", "II_Tours", "IX_Tours", "XI_Tours", "Intrazonal", "AVG_TIME_II", "AVG_Time_IX", "AVG_Time_XI", "AVGTourTT_PA", "AVGTourTT_AP"}, { {"CSV Header", "True"} } )
	ODtime_tab2 = ExportView("ODtime_tab|", "CSV", DirReport + "\\ODtime_distr.csv",{"TimeDistr", "HBW", "SCH", "HBU", "HBS", "HBO", "ATW", "XIW", "XIN"}, { {"CSV Header", "True"} } )
	stopsdistr_tab2 = ExportView("stopsdistr_tab|", "CSV", DirReport + "\\StopsDistr.csv",{"PURP", "PA0Stops", "PA1Stops", "PA2Stops", "PA3Stops", "PA4Stops", "PA5Stops", "PA6Stops", "PA7Stops", "AP0Stops", "AP1Stops", "AP2Stops", "AP3Stops", "AP4Stops", "AP5Stops", "AP6Stops", "AP7Stops"}, { {"CSV Header", "True"} } ) 


//*******************************************************************************************************************************************************************
//Creates TOD1 output files

//Macro _________

//Note: includes IXW and IXN fields

  UpdateProgressBar("Runstats TOD1_output", 10) 

	purptab = {"HBW", "SCH", "HBU", "HBS", "HBO", "ATW", "EXT", "EXT", "XIW", "XIN"}	
	purp = {"HBW", "SCH", "HBU", "HBS", "HBO", "ATW", "IXW", "IXN", "XIW", "XIN"}	

	//create another table to output the number of tours in 10 minute bins
	TOD1_tab = CreateTable("TOD1_tab", DirReport + "\\TOD1_output.bin", "FFB", {{"Purpose", "String", 4, , "No"}, {"PAPK_APPK", "Integer", 7, , "No"}, {"PAPK_APOP", "Integer", 7, , "No"}, {"PAOP_APPK", "Integer", 7, , "No"}, {"PAOP_APOP", "Integer", 7, , "No"}}) 

	paap2 = {"PAper", "APper"}
	tod1num = {"2", "1"}	// 1= offpeak, 2 = peak
	dim recs_ar[4]

	for p = 1 to purp.length do
		current_file = OpenTable("current_file", "FFB", {DirOutDC + "\\dc" + purptab[p] + ".bin",})
		rh = AddRecord("TOD1_tab", {{"Purpose", purp[p]}})

		addon = null		
		if purp[p] = "IXW" then do
			addon = " and Purp = 'HBW'"
		end
		else if purp[p] = "IXN" then do
			addon = " and Purp <> 'HBW'"
		end

		counter = 0
		for t1 = 1 to 2 do
			for t2 = 1 to 2 do
				counter = counter + 1
				qry = "Select * where PAper = " + tod1num[t1] + " and APper = " + tod1num[t2] + addon
				SetView(current_file)
				recs_ar[counter] = SelectByQuery("recs", "Several", qry)
			end
		end
//		SetRecordValues("TOD1_tab", rh, {{"XI_Tours", xirec}, {"PAPK_APPK", recs_ar[1]}, {"PAPK_APOP", recs_ar[2]}, {"PAOP_APPK", recs_ar[3]}, {"PAOP_APOP", recs_ar[4]}})
		SetRecordValues("TOD1_tab", rh, {{"PAPK_APPK", recs_ar[1]}, {"PAPK_APOP", recs_ar[2]}, {"PAOP_APPK", recs_ar[3]}, {"PAOP_APOP", recs_ar[4]}})
				
	end

	TOD1_tab2 = ExportView("TOD1_tab|", "CSV", DirReport + "\\TOD1_output.csv",{"Purpose", "PAPK_APPK", "PAPK_APOP", "PAOP_APPK", "PAOP_APOP"}, { {"CSV Header", "True"} } )

//*******************************************************************************************************************************************************************
//Creates VolGroupStats output files

	volgroup_tab = CreateTable("volgroup_tab", DirReport + "\\volgroup_tab.bin", "FFB", {{"STCNTY", "Integer", 5, , "No"}, {"VolGrpID", "Integer", 2, , "No"},
	{"LinksCount", "Integer", 10, , "No"}, {"Length", "Real", 21, 4, "No"}, {"CALIB15", "Real", 21, 4, "No"}, {"Tot_Vol", "Real", 21, 4, "No"}, {"TOT_VMT", "Real", 21, 4, "No"},
	{"TOT_VHT", "Real", 21, 4, "No"}, {"CNTMCSQ", "Real", 21, 4, "No"}})

		
	totassn_tab = OpenTable("totassn_tab", "FFB", {Dir + "\\HwyAssn\\HOT\\Tot_Assn_HOT.bin",}) 
	
	
	//Define Variables - Arrays for STCNTY and VolGroup

	stcnty_ar = { "37025", "37035", "37045", "37071", "37097", "37109", "37119", "37159", "37167", "37179", "45057", "45091"}

	volgroup_ar = { 0, 1000, 2500, 5000, 10000, 25000, 50000, 1000000 }


		for c = 1 to stcnty_ar.length do 
			counter = 0
			for vg = 1 to (volgroup_ar.length - 1) do	
					counter = counter + 1
					
					SetView("totassn_tab")
					qry1 = "Select * where STCNTY = " + stcnty_ar[c] + " and CALIB15 between " + i2s(volgroup_ar[vg]+1) + " and " + i2s(volgroup_ar[vg+1]) // 1-1000, 1001 - 2500
					numlinks = SelectByQuery("numlinks", "Several", qry1, )

					stats_tab = ComputeStatistics("totassn_tab|numlinks", "stats_tab", Dir +"\\stats_tab.bin", "FFB",) 
					
					SetView("stats_tab")
					qry2 = 'Select * where Field = "Length" or Field= "CALIB15" or Field = "Tot_Vol" or Field = "CNTMCSQ" or Field = "TOT_VMT" or Field = "TOT_VHT" '
					sumfields = SelectByQuery("sumfields", "Several", qry2, )

					stats_v = GetDataVector(stats_tab +"|sumfields", "Sum",)
					lengthval = stats_v[1]
					calib15val = stats_v[2]
					tot_volval = stats_v[3]
					TOT_VMTval = stats_v[4]
					TOT_VHTval = stats_v[5]	
					CNTMCSQval = stats_v[6]			
	
					rh = AddRecord("volgroup_tab", {{"STCNTY", s2i(stcnty_ar[c])}, {"VolGrpID", counter}, {"LinksCount", numlinks}, {"Length", lengthval}, {"CALIB15", calib15val},
						{"Tot_Vol", tot_volval}, {"TOT_VMT", TOT_VMTval}, {"TOT_VHT", TOT_VHTval}, {"CNTMCSQ", CNTMCSQval}})      
					CloseView(stats_tab)
				end
			end
		

		volgroup_tab2 = ExportView("volgroup_tab|", "CSV", DirReport + "\\VolGroupStats.csv",{"STCNTY", "VolGrpID", "LinksCount", "Length", "CALIB15", "Tot_Vol", "CNTMCSQ", "TOT_VMT", "TOT_VHT"}, { {"CSV Header", "True"} } )		
	
    

    DestroyProgressBar()
    RunMacro("G30 File Close All")

    goto quit

	badquit:
		on error, notfound default
		RunMacro("TCB Closing", ret_value, "TRUE" )
		msg = msg + {"Tour Run Stats: Error somewhere"}
		AppendToLogFile(1, "Tour Run Stats: Error somewhere")
		datentime = GetDateandTime()
		AppendToLogFile(1, "Tour Run Stats " + datentime)

       	return({0, msg})

    quit:
		on error, notfound default
   		datentime = GetDateandTime()
		AppendToLogFile(1, "Exit Tour Run Stats " + datentime)
    	return({1, msg})
	
endmacro