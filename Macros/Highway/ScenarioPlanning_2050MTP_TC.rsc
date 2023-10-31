Macro "ScenarioPlanning_2050MTP_TC" (Args)

// Sets up file folders, recalculates HBW & XIW files based on set telecommuting percentages (can change below), 
// and runs 3 different assignments based on CAV scenarios

// Telecommuting (first loop):
// Uses the ratio of Off/Gov employees to TotEmp of the tour's Destination zone to determine probability that tour is an Off/Gov job
// For HBW, if tour is determined to be a telecommute and has stops, the either the last stop in the PA direction or first stop in the AP direction
//      (if there's no PA stops) becomes the Destination zone.  All stops are then moved to the Offpeak.
// For XIW, if tour is determined to be a telecommute, all stops are removed (since stops likely to take place outside the region).
// If either HBW or XIW tour is a telecommute, any associated ATW tours are removed


/*	on error goto badquit
	LogFile = Args.[Log File].value
	ReportFile = Args.[Report File].value
	SetLogFileName(LogFile)
	SetReportFileName(ReportFile)
	
	sedata_file = Args.[LandUse file].value
	Dir = Args.[Run Directory].value
	theyear = Args.[Run Year].value
	net_file = Args.[Hwy Name].value
	msg = null
	datentime = GetDateandTime()
	AppendToLogFile(1, "Tour Trip Accumulator: " + datentime)
*/	RunMacro("TCB Init")

	RunMacro("G30 File Close All") 

	sedata_file = "C:\\1ScenarioPlanning\\Metrolina\\2045\\LandUse\\SE_2045_200710_final.dbf"
	Dir = "C:\\1ScenarioPlanning\\Metrolina\\2045"
	theyear = "2045"


	DirArray  = Dir + "\\TG"
 	DirOutDC  = Dir + "\\TD"
 	DirOutTripTab  = Dir + "\\TripTables"
 	
 	yr_str = Right(theyear,2)
	yr = s2i(yr_str)

// ***  Can change telecommuting percentages here:    ***
	telecommute_ar = {0.10, 0.25, 0.35}


  CreateProgressBar("Starting Scenario Planning Macro", "TRUE")
  

//Calculate percent of Off/Gov to TotEmp for each TAZ
	se_vw = OpenTable("SEFile", "dBASE", {sedata_file,})
  
  	offgovpct = CreateExpression("SEFile", "OFFGOVPCT", "if totemp <> 0 then OFFGOV/TOTEMP else 0",)

		runbasejobs_tour = {"Tour_TripAccumulator", "MS_RunPeak",
				"Tour_TOD2_AMPeak", "HwyAssn_RunAMPeak"}
		runpostfeedbackjobs_tour = {"MS_RunOffPeak", "MSMatrixStats", //"Tour_TF_CountySummaryStats", 
				"Tour_TOD2_PMPeak", "Tour_TOD2_Midday", "Tour_TOD2_Night", 
				"HwyAssn_RunPMPeak", "HwyAssn_RunMidday", "HwyAssn_RunNight"}
	 	runHOTassnjobs_tour = {"HwyAssn_RunHOTAMPeak", "HwyAssn_RunHOTPMPeak", "HwyAssn_RunHOTMidday", "HwyAssn_RunHOTNight", 
 				"HwyAssn_RunHOTTotAssn", "ODMatrixStats", "VMTAQ", "AvgTripLenTrips_tour", "Tour_RunStats"}
						

SetRandomSeed(42837)

  for tc = 1 to 3 do 	//loop on telecommuting scenarios 
	  UpdateProgressBar("Telecommuting Scenario " + i2s(tc), 10) 
	  
		DirTCscen = Dir + "\\TC_Scenario" + i2s(tc)
	
	// start with HBW
		hbw_file = OpenTable("hbw_file", "FFB", {DirTCscen + "\\TD\\dcHBW.bin",})
		desttaz = GetDataVector(hbw_file+"|", "DEST_TAZ",{{"Sort Order", {{"ID","Ascending"}}}})
	
		strct = GetTableStructure(hbw_file)
		for j = 1 to strct.length do			
	 		strct[j] = strct[j] + {strct[j][1]}	
	 	end
		strct = strct + {{"OG_job", "Integer", 1,,,,,,,,,}}
		strct = strct + {{"telecommute", "Integer", 1,,,,,,,,,}}
		strct = strct + {{"randnumOG", "Real", 10,8,,,,,,,,}}
		strct = strct + {{"randnumC", "Real", 10,8,,,,,,,,}}
		ModifyTable(hbw_file, strct)
		randnumOG = Vector(desttaz.length, "float", )
		randnumTC = Vector(desttaz.length, "float", )
		telecommute = Vector(desttaz.length, "short", )
		for n = 1 to desttaz.length do
				rand_val = RandomNumber()
				randnumOG[n] = rand_val
				rand_val = RandomNumber()
				randnumTC[n] = rand_val
		end
	
		// Join HBW file to SE file to determine if it is a OffGov job
		jointab = JoinViews("jointab", "hbw_file.DEST_TAZ", "SEFile.TAZ", )
		OGpct = GetDataVector(jointab+"|", "OFFGOVPCT",{{"Sort Order", {{"ID","Ascending"}}}})
		OG = if randnumOG >= OGpct then 1 else 0
		telecommute = if (OG = 1 and randnumTC <= telecommute_ar[tc]) then 1 else 0
		CloseView("jointab")
		SetDataVectors(hbw_file+"|", {{"OG_job", OG}, {"telecommute", telecommute}, {"randnumOG", randnumOG}, {"randnumC", randnumTC}}, {{"Sort Order", {{"ID"}}}})
		
		// Make a copy of the file, holding on to all the original results
		CopyTableFiles("hbw_file", null, null, null, DirTCscen + "\\TD\\dcHBW_preCommute.bin", null)
	
		CloseView("hbw_file")
		
		//Open new table, select if a telecommute tour, then remove from revised dcHBW table
		// also, create a new HBO append table if it is a telecommute tour but there are stops
		temp_file = OpenTable("temp_file", "FFB", {DirTCscen + "\\TD\\dcHBW_preCommute.bin",})
		qry = "Select * where telecommute <> 1"
		qry2 = "Select * where (telecommute = 1 and IS_PA <> 0 and IS_AP <> 0)"
		SetView("temp_file")
		nonTCset = SelectByQuery("nonTCset", "Several", qry)
		ExportView("temp_file|nonTCset", "FFB", DirTCscen + "\\TD\\dcHBW.bin",,)
		HBOaddset = SelectByQuery("HBOaddset", "Several", qry2)
		ExportView("temp_file|HBOaddset", "FFB", DirTCscen + "\\TD\\dcHBO_TCadd.bin",,)
		CloseView("temp_file")
	
		// edit new HBO add file (for former HBW tours with stops)
		// if there are IS_PA stops, then the last stop will be made the Dest_Taz and the this stop will be removed from the stops
		// if there is not IS_PA stops but are IS_AP stops, then the first stop will become the Dest_TAZ and all other stops will be moved up an order
		dcHBO_TCadd_file = OpenTable("dcHBO_TCadd_file", "FFB", {DirTCscen + "\\TD\\dcHBO_TCadd.bin",})
		opts = {}
		opts.[Return Options Array] = True
		hboAdd_v = GetDataVectors(dcHBO_TCadd_file+"|", {"ID", "TAZ", "DEST_TAZ", "DEST_SEQ", "IS_PA", "IS_AP", "SL_PA1", "SL_PA2","SL_PA3", 
					"SL_PA4","SL_PA5", "SL_AP1","SL_AP2", "SL_AP3","SL_AP4", "SL_AP5","SL_AP6","SL_AP7", "PAper", "APper"},opts)
		hboAdd_v.DEST_TAZ = if (hboAdd_v.IS_PA = 5) then hboAdd_v.SL_PA5 else if (hboAdd_v.IS_PA = 4) then hboAdd_v.SL_PA4 
					else if (hboAdd_v.IS_PA = 3) then hboAdd_v.SL_PA3 else if (hboAdd_v.IS_PA = 2) then hboAdd_v.SL_PA2  
					else if (hboAdd_v.IS_PA = 1) then hboAdd_v.SL_PA1 else  hboAdd_v.SL_AP1
	
		hboAdd_v.DEST_SEQ = null //we don't have SEQ saved in the stops fields
		hboAdd_v.SL_PA1 = hboAdd_v.SL_PA2
	 	hboAdd_v.SL_PA2 = hboAdd_v.SL_PA3
		hboAdd_v.SL_PA3 = hboAdd_v.SL_PA4
		hboAdd_v.SL_PA4 = hboAdd_v.SL_PA5
		hboAdd_v.SL_PA5 = null   //no more 7th stop
	
		hboAdd_v.SL_AP1 = hboAdd_v.SL_AP2
	 	hboAdd_v.SL_AP2 = hboAdd_v.SL_AP3
		hboAdd_v.SL_AP3 = hboAdd_v.SL_AP4
		hboAdd_v.SL_AP4 = hboAdd_v.SL_AP5
		hboAdd_v.SL_AP5 = hboAdd_v.SL_AP6
	 	hboAdd_v.SL_AP6 = hboAdd_v.SL_AP7
		hboAdd_v.SL_AP7 = null	//no more 7th stop
		null_v = Vector(hboAdd_v.DEST_TAZ.length,"float",)
		
		hboAdd_v.IS_PA = if (hboAdd_v.IS_PA = 0) then 0 else (hboAdd_v.IS_PA - 1)	//minus a stop
		hboAdd_v.IS_AP = if (hboAdd_v.IS_AP = 0) then 0 else (hboAdd_v.IS_AP - 1)
		// move all stops to Offpeak
		hboAdd_v.PAper = if hboAdd_v.PAper = 2 then 1 else hboAdd_v.PAper	// 1 = off-peak
		hboAdd_v.APper = if hboAdd_v.APper = 2 then 1 else hboAdd_v.APper	
		
		SetDataVectors(dcHBO_TCadd_file+"|", {{"DEST_TAZ", hboAdd_v.DEST_TAZ}, {"DEST_SEQ", null_v}, {"IS_PA", hboAdd_v.IS_PA}, {"IS_AP", hboAdd_v.IS_AP}, {"SL_PA1", hboAdd_v.SL_PA1}, {"SL_PA2", hboAdd_v.SL_PA2}, {"SL_PA3", hboAdd_v.SL_PA3},
						{"SL_PA3", hboAdd_v.SL_PA3}, {"SL_PA4", hboAdd_v.SL_PA4}, {"SL_PA5", null_v}, {"SL_AP1", hboAdd_v.SL_AP1}, {"SL_AP2", hboAdd_v.SL_AP2}, 
						{"SL_AP3", hboAdd_v.SL_AP3},{"SL_AP4", hboAdd_v.SL_AP4}, {"SL_AP5", hboAdd_v.SL_AP5}, {"SL_AP6", hboAdd_v.SL_AP6}, {"SL_AP7", null_v},
						{"PAper", hboAdd_v.PAper},{"APper", hboAdd_v.APper}}, {{"Sort Order", {{"ID"}}}})
	
		//merge the stops table from HBW telecommute tours to the dcHBO file
		dcHBO = OpenTable("dcHBO", "FFB", {DirTCscen + "\\TD\\dchbo.bin",})
		
		fields_ar = GetFields("dcHBO_TCadd_file", null)
		num = (fields_ar[1].length - 4)	//there are 4 extra fields in HBO_TCadd
		dim fieldnames[num] 
		for i = 1 to num do
			fieldnames[i] = fields_ar[1][i]
		end
	//	addixtables = {"hbwdestix|", "schdestix|", "hbudestix|", "hbsdestix|", "hbodestix|", "atwdestix|"}
		rh = GetFirstRecord("dcHBO_TCadd_file|", {{"ID", "Ascending"}})
		vals = GetRecordsValues("dcHBO_TCadd_file|", rh, null, null, null, "Row", null)
		filltable = AddRecords("dcHBO", fieldnames, vals, null)
		id_v = GetDataVector(dcHBO+"|", "ID",)
		new_id_v = Vector(id_v.length, "long", {{"Sequence", 1,1}})
		SetDataVector(dcHBO+"|", "ID", new_id_v,)
		CloseView("dcHBO_TCadd_file")
		CloseView("dcHBO")
	
	// now do XIW
		xiw_file = OpenTable("xiw_file", "FFB", {DirTCscen + "\\TD\\dcXIW.bin",})
		desttazxi = GetDataVector(xiw_file+"|", "DEST_TAZ",{{"Sort Order", {{"ID","Ascending"}}}})	
	
		strct = GetTableStructure(xiw_file)
		for j = 1 to strct.length do			
	 		strct[j] = strct[j] + {strct[j][1]}	
	 	end
		strct = strct + {{"OG_job", "Integer", 1,,,,,,,,,}}
		strct = strct + {{"telecommute", "Integer", 1,,,,,,,,,}}
		strct = strct + {{"randnumOG", "Real", 10,8,,,,,,,,}}
		strct = strct + {{"randnumC", "Real", 10,8,,,,,,,,}}
		ModifyTable(xiw_file, strct)
		randnumOG = Vector(desttazxi.length, "float", )
		randnumTC = Vector(desttazxi.length, "float", )
		telecommute = Vector(desttaz.length, "short", )
		for n = 1 to desttazxi.length do
				rand_val = RandomNumber()
				randnumOG[n] = rand_val
				rand_val = RandomNumber()
				randnumTC[n] = rand_val
		end
	
		// Join XIW file to SE file to determine if it is a OffGov job
		jointab = JoinViews("jointab", "xiw_file.DEST_TAZ", "SEFile.TAZ", )  
		OGpct = GetDataVector(jointab+"|", "OFFGOVPCT",{{"Sort Order", {{"ID","Ascending"}}}})
		OG = if randnumOG >= OGpct then 1 else 0
		telecommute = if (OG = 1 and randnumTC <= telecommute_ar[tc]) then 1 else 0
		CloseView("jointab")
		SetDataVectors(xiw_file+"|", {{"OG_job", OG}, {"telecommute", telecommute}, {"randnumOG", randnumOG}, {"randnumC", randnumTC}}, {{"Sort Order", {{"ID"}}}})
		
		// Make a copy of the file, holding on to all the original results
		CopyTableFiles("xiw_file", null, null, null, DirTCscen + "\\TD\\dcXIW_preCommute.bin", null)
	
		CloseView("xiw_file")
		
		//Open new table, select if a telecommute tour, then remove from revised dcXIW table
		temp_file = OpenTable("temp_file", "FFB", {DirTCscen + "\\TD\\dcXIW_preCommute.bin",})
		qry = "Select * where telecommute <> 1"
		SetView("temp_file")
		nonTCset = SelectByQuery("nonTCset", "Several", qry)
		ExportView("temp_file|nonTCset", "FFB", DirTCscen + "\\TD\\dcXIW.bin",,)
		CloseView("temp_file")
	
	// now do ATW, start with ii
		atw_file = OpenTable("atw_file", "FFB", {DirTCscen + "\\TD\\dcATW.bin",})
		hbw_file = OpenTable("hbw_file", "FFB", {DirTCscen + "\\TD\\dcHBW_preCommute.bin",})
	
		strct = GetTableStructure(atw_file)
		for j = 1 to strct.length do			
	 		strct[j] = strct[j] + {strct[j][1]}	
	 	end
		strct = strct + {{"HBW_TC", "Integer", 1,,,,,,,,,}}
		ModifyTable(atw_file, strct)
	
		// Make a copy of the file, holding on to all the original results
		CopyTableFiles("atw_file", null, null, null, DirTCscen + "\\TD\\dcATW_preCommute.bin", null)
		CloseView("atw_file")	
	
		//Now open the new file, then join with HBW file to denote telecommuting tours, select only those that are not telecommute, and re-save as the new dcATW
		atw_file = OpenTable("atw_file", "FFB", {DirTCscen + "\\TD\\dcATW_preCommute.bin",})
		jointab = JoinViews("jointab", "atw_file.HBWID", "hbw_file.ID", )
		TC_v = GetDataVector(jointab+"|", "telecommute", ) // {{"Sort Order", {{"ID","Ascending"}}}})	
		CloseView("jointab")
		CloseView("hbw_file")
		SetDataVector(atw_file+"|", "HBW_TC", TC_v,{{"Sort Order", {{"ID","Ascending"}}}})	
	
		qry = "Select * where HBW_TC <> 1"
		SetView("atw_file")
		nonTCset = SelectByQuery("nonTCset", "Several", qry)
		ExportView("atw_file|nonTCset", "FFB", DirTCscen + "\\TD\\dcATW.bin",,)
		CloseView("atw_file")	
	
	 //now do ATW_EXT: same as above, but also need to remove the ATWs from the dcEXT table, then re-merge with the new non-telecommuting records
		atwext_file = OpenTable("atwext_file", "FFB", {DirTCscen + "\\TD\\dcATWext.bin",})
		atwextID_v = GetDataVector(atwext_file+"|", "ID", ) // Will use later
		hbw_file = OpenTable("hbw_file", "FFB", {DirTCscen + "\\TD\\dcHBW_preCommute.bin",})
	
		strct = GetTableStructure(atwext_file)
		for j = 1 to strct.length do			
	 		strct[j] = strct[j] + {strct[j][1]}	
	 	end
		strct = strct + {{"HBW_TC", "Integer", 1,,,,,,,,,}}
		ModifyTable(atwext_file, strct)
	
		// Make a copy of the file, holding on to all the original results
		CopyTableFiles("atwext_file", null, null, null, DirTCscen + "\\TD\\dcATWext_preCommute.bin", null)
		CloseView("atwext_file")	
	
		//Now open the new file, then join with HBW file to denote telecommuting tours, select only those that are not telecommute, and re-save as the new dcATW
		atwext_file = OpenTable("atwext_file", "FFB", {DirTCscen + "\\TD\\dcATWext_preCommute.bin",})
		jointab = JoinViews("jointab", "atwext_file.HBWID", "hbw_file.ID", )
		TC_v = GetDataVector(jointab+"|", "telecommute", ) // {{"Sort Order", {{"ID","Ascending"}}}})	
		CloseView("jointab")
		CloseView("hbw_file")
		SetDataVector(atwext_file+"|", "HBW_TC", TC_v,)  //{{"Sort Order", {{"ID","Ascending"}}}})	
	
		//Open the dcEXT file and save only the ATW records.  Also, create a temp table without any ATW records.
	 	ext_file = OpenTable("ext_file", "FFB", {DirTCscen + "\\TD\\dcEXT.bin",})
		qry = "Select * where Purp = 'ATW'"
		qry2 = "Select * where Purp <> 'ATW'"
		SetView("ext_file")
		ATWset = SelectByQuery("ATWset", "Several", qry)
		nonATWset = SelectByQuery("nonATWset", "Several", qry2)
		ExportView("ext_file|ATWset", "FFB", DirTCscen + "\\TD\\dcATWonly.bin",,)	//dcEXT with only ATWs
	//	ExportView("ext_file|ATWset", "FFB", DirTCscen + "\\TD\\dcATWonly.bin",,{"Additional Fields", {{"NEWID", "Integer", 10, null, "No"},{"HBW_TC", "Integer", 1, null, "No"}}})	//dcEXT with only ATWs
		ExportView("ext_file|nonATWset", "FFB", DirTCscen + "\\TD\\dcEXT_temp.bin",,)	//dcEXT with original ATW removed
	//	ExportView("atw_file|nonTCset", "FFB", DirTCscen + "\\TD\\dcATW.bin",,)
		CloseView("ext_file")	
	
		//FIll in NEWID (the original ID of the ATWext table), then join the pre-commute file to the only ATW dcEXT file
	 	dcATWonly = OpenTable("dcATWonly", "FFB", {DirTCscen + "\\TD\\dcATWonly.bin",})
		strct = GetTableStructure(dcATWonly)
		for j = 1 to strct.length do			
	 		strct[j] = strct[j] + {strct[j][1]}	
	 	end
		strct = strct + {{"NEWID", "Integer", 10,,,,,,,,,}}
		ModifyTable(dcATWonly, strct)
		SetDataVector(dcATWonly+"|", "NEWID", atwextID_v,)  //{{"Sort Order", {{"ID","Ascending"}}}})	
		jointab = JoinViews("jointab", "dcATWonly.NEWID", "atwext_file.ID", )
		TC_v = GetDataVector(jointab+"|", "HBW_TC", ) // {{"Sort Order", {{"ID","Ascending"}}}})	
		CloseView("jointab")
		strct = GetTableStructure(dcATWonly)
		for j = 1 to strct.length do			
	 		strct[j] = strct[j] + {strct[j][1]}	
	 	end
		strct = strct + {{"HBW_TC", "Integer", 1,,,,,,,,,}}
		ModifyTable(dcATWonly, strct)
		SetDataVector(dcATWonly+"|", "HBW_TC", TC_v,)  //{{"Sort Order", {{"ID","Ascending"}}}})	
	
		qry = "Select * where HBW_TC <> 1"
		SetView("dcATWonly")
		TCset = SelectByQuery("TCset", "Several", qry)
		ExportView("dcATWonly|TCset", "FFB", DirTCscen + "\\TD\\dcATWextNONTC.bin",,)	//this is the temp ATWext file 
		CloseView("dcATWonly")	
	
	 	//Open dcEXT and remove ATW tours.  Then add the new records back in
		//merge the stops table from ATWext telecommute tours to the dcEXT file
	 	ext_file = OpenTable("ext_file", "FFB", {DirTCscen + "\\TD\\dcEXT_temp.bin",})
	 	newatwext_file = OpenTable("newatwext_file", "FFB", {DirTCscen + "\\TD\\dcATWextNONTC.bin",})
		
		fields_ar = GetFields("ext_file", null)

		num = (fields_ar[1].length) 
		dim fieldnames[num] 
		for i = 1 to num do
			fieldnames[i] = fields_ar[1][i]
		end
		rh = GetFirstRecord("newatwext_file|", {{"ID", "Ascending"}})
		vals = GetRecordsValues("newatwext_file|", rh, null, null, null, "Row", null)
		filltable = AddRecords("ext_file", fieldnames, vals, null)
		id_v = GetDataVector(ext_file+"|", "ID",)
		new_id_v = Vector(id_v.length, "long", {{"Sequence", 1,1}})
		SetDataVector(ext_file+"|", "ID", new_id_v,)
		ExportView("ext_file|", "FFB", DirTCscen + "\\TD\\dcEXT.bin",,)	
		CloseView("ext_file")	
		CloseView("newatwext_file")	
	

end   //loop on TC scenarios



    DestroyProgressBar()
    RunMacro("G30 File Close All")

endmacro
