Macro "Tour_RunStats" (Args)

//Creates the "ProductionsByCo" and "AttractionsByCo" files (.bin)
//Creates the "StopsByCoPA" and "StopsByCoAP" files (.bin)
//Creates the "TF_NUM" file (.bin)
//Creates a second runstats output file for Tour Frequency (TF_NumByCounty.bin)
//Creates DC_output, ODtime_dist & StopsDistr files
//Creates TOD1 output files

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

	purp = {"HBW", "SCH", "HBU", "HBS", "HBO", "ATW", "EXT", "XIW", "XIN"}
	purp_tab = {"dcHBW", "dcSCH", "dcHBU", "dcHBS", "dcHBO", "dcATW", "dcEXT", "dcXIW", "dcXIN"}
	fields = {"HBW1", "HBW2", "HBW3", "HBW4", "SCH", "HBU", "HBS1", "HBS2", "HBS3", "HBS4", "HBO1", "HBO2", "HBO3", "HBO4", "ATW", "IXW", "IXN", "XIW", "XIN"}


/*	counties = {{37025, "Cabarrus"}, {37035, "Catawba"}, {37045, "Cleveland"}, {37071, "Gaston"}, {37097, "Iredell"}, {37109, "Lincoln"}, {37119, "Mecklenburg"}, 
			{37159, "Rowan"}, {37167, "Stanly"}, {37179, "Union"}, {45057, "Lancaster"}, {45091, "York"}, {99999, "External"}}
*/	stcnty_tab = OpenTable("stcnty_tab", "DBASE", {MetDir + "\\STCNTY_ID.dbf",})
	stcnty = GetDataVector(stcnty_tab + "|", "STCNTY",)
	counties = GetDataVector(stcnty_tab + "|", "NAME",)

	se_vw = OpenTable("SEFile", "dBASE", {sedata_file,})

//*******************************************************************************************************************************************************************https://open.spotify.com/track/3UJ19S4NV2C6Z9834aOgwi
//Create the "ProductionsByCo" and "AttractionsByCo" files (.bin)
//Macro "Tour_ProdAttrByCounty"

  UpdateProgressBar("Productions and Attractions By County", 10) 

	datentime = GetDateandTime()
	AppendToLogFile(1, "Runstats ProdAttrByCounty: " + datentime)

//create Productions and Attractions tables
	prod_tab = CreateTable("prod_tab", DirReport + "\\ProductionsByCo.bin", "FFB", {{"STCNTY", "Integer", 5, , "No"}, {"County", "String", 15, , "No"}}) 
	rh = AddRecords("prod_tab", , ,{{"Empty Records", counties.length}})
	pstrct = GetTableStructure(prod_tab)					
	attr_tab = CreateTable("attr_tab", DirReport + "\\AttractionsByCo.bin", "FFB", {{"STCNTY", "Integer", 5, , "No"}, {"County", "String", 15, , "No"}}) 
	rh = AddRecords("attr_tab", , ,{{"Empty Records", counties.length}})
	astrct = GetTableStructure(attr_tab)					
	for j = 1 to pstrct.length do
 		pstrct[j] = pstrct[j] + {pstrct[j][1]}
 		astrct[j] = astrct[j] + {astrct[j][1]}
 	end
	for j = 1 to fields.length do
		pstrct = pstrct + {{fields[j], "Integer", 8,,,,,,,,,}}
		astrct = astrct + {{fields[j], "Integer", 8,,,,,,,,,}}
 	end
	ModifyTable(prod_tab, pstrct)
	ModifyTable(attr_tab, astrct)

// fill in STCNTY and County name	
	for j = 1 to counties.length do
		SetDataVectors("prod_tab|", {{"STCNTY", stcnty}, {"County", counties}},)
		SetDataVectors("attr_tab|", {{"STCNTY", stcnty}, {"County", counties}},)
	end

	counter = 1	
// Open DC tables, join to get county totals (by income if required)	
	for p = 1 to purp.length do	//purp.length
		dc_tab = OpenTable("dc_tab", "FFB", {DirOutDC + "\\dc" + purp[p] + ".bin",})
		if (purp[p] <> "XIW" and purp[p] <> "XIN") then do
			pjoin = JoinViews("pjoin", "dc_tab.ORIG_TAZ", "SEFile.TAZ",)
		end
		ajoin = JoinViews("ajoin", "dc_tab.DEST_TAZ", "SEFile.TAZ",)
		if (purp[p] = "HBW" or purp[p] = "HBS" or purp[p] = "HBO") then do
			for i = 1 to 4 do
				//productions, by income
				qry = "Select * where INCOME = " + i2s(i)
				SetView(pjoin)
				precs = SelectByQuery("precs", "Several", qry)
				ExportView("pjoin|precs", "MEM", "thispurp",,)
				SetView("thispurp")
				pjoin2 = JoinViews("pjoin2", "stcnty_tab.STCNTY", "thispurp.STCNTY", {{"A",}})
				pnumtours = GetDataVector(pjoin2+"|", "[N thispurp]", {{"Sort Order", {{"stcnty_tab.STCNTY","Ascending"}}}}) 
				SetDataVector(prod_tab+"|", fields[counter], pnumtours, {{"Sort Order", {{"STCNTY","Ascending"}}}})
				CloseView("pjoin2")
				CloseView("thispurp")
				thispurp = null
				//attractions, by income
				SetView(ajoin)
				arecs = SelectByQuery("arecs", "Several", qry)
				ExportView("ajoin|arecs", "MEM", "thispurp",,)
				SetView("thispurp")
				ajoin2 = JoinViews("ajoin2", "stcnty_tab.STCNTY", "thispurp.STCNTY", {{"A",}})
				anumtours = GetDataVector(ajoin2+"|", "[N thispurp]", {{"Sort Order", {{"stcnty_tab.STCNTY","Ascending"}}}}) 
				SetDataVector(attr_tab+"|", fields[counter], anumtours, {{"Sort Order", {{"STCNTY","Ascending"}}}})
				SetView("dc_tab")
				CloseView("ajoin2")
				CloseView("thispurp")

				counter = counter + 1
			end
			CloseView("pjoin")
			CloseView("ajoin")
			CloseView("dc_tab")
			dc_tab = null
		end
		else if (purp[p] = "EXT") then do
			//fill IXW first, productions & attractions
			qry = "Select * where Purp = 'HBW'"
			SetView(pjoin)
			precs = SelectByQuery("precs", "Several", qry)
			ExportView("pjoin|precs", "MEM", "thispurp",,)
			SetView("thispurp")
			pjoin2 = JoinViews("pjoin2", "stcnty_tab.STCNTY", "thispurp.STCNTY", {{"A",}})
			pnumtours = GetDataVector(pjoin2+"|", "[N thispurp]", {{"Sort Order", {{"stcnty_tab.STCNTY","Ascending"}}}}) 
			SetDataVector(prod_tab+"|", fields[counter], pnumtours, {{"Sort Order", {{"STCNTY","Ascending"}}}})	//set productions
			SetView(attr_tab)
			rh = GetLastRecord(attr_tab+"|", )	//last record is external stations
			SetRecordValues(attr_tab, rh, {{fields[counter], precs}})	//set attractions
			CloseView("pjoin2")
			CloseView("thispurp")
			thispurp = null
			counter = counter + 1	//count up to get to IXN
			//next IXN, productions & attractions
			qry = "Select * where Purp <> 'HBW'"
			SetView(pjoin)
			precs = SelectByQuery("precs", "Several", qry)
			ExportView("pjoin|precs", "MEM", "thispurp",,)
			SetView("thispurp")
			pjoin2 = JoinViews("pjoin2", "stcnty_tab.STCNTY", "thispurp.STCNTY", {{"A",}})
			pnumtours = GetDataVector(pjoin2+"|", "[N thispurp]", {{"Sort Order", {{"stcnty_tab.STCNTY","Ascending"}}}}) 
			SetDataVector(prod_tab+"|", fields[counter], pnumtours, {{"Sort Order", {{"STCNTY","Ascending"}}}})	//set productions
			rh = GetLastRecord(attr_tab+"|", )	//last record is external stations
			SetRecordValues(attr_tab, rh, {{fields[counter], precs}})	//set attractions
			CloseView("pjoin2")
			thispurp = null
			SetView("dc_tab")
			CloseView("thispurp")
			counter = counter + 1
			CloseView("pjoin")
			CloseView("ajoin")
			CloseView("dc_tab")
			dc_tab = null
		end
		else if (purp[p] = "XIW" or purp[p] = "XIN") then do
			//productions & attractions 
			ajoin2 = JoinViews("ajoin2", "stcnty_tab.STCNTY", "ajoin.STCNTY", {{"A",}})
			numtours = GetDataVector(ajoin2+"|", "[N ajoin]", {{"Sort Order", {{"stcnty_tab.STCNTY","Ascending"}}}}) 
			SetDataVector(attr_tab+"|", fields[counter], numtours, {{"Sort Order", {{"STCNTY","Ascending"}}}})	//set attractions
			precs = VectorStatistic(numtours, "Sum",)
			rh = GetLastRecord(prod_tab+"|", )	//last record is external stations
			SetRecordValues(prod_tab, rh, {{fields[counter], precs}})	//set productions
			CloseView("ajoin2")
			counter = counter + 1
			CloseView("ajoin")
			CloseView("dc_tab")
			dc_tab = null
		end
		else do
			//productions
			pjoin2 = JoinViews("pjoin2", "stcnty_tab.STCNTY", "pjoin.STCNTY", {{"A",}})
			numtours = GetDataVector(pjoin2+"|", "[N pjoin]", {{"Sort Order", {{"stcnty_tab.STCNTY","Ascending"}}}}) 
			SetDataVector(prod_tab+"|", fields[counter], numtours, {{"Sort Order", {{"STCNTY","Ascending"}}}})
			CloseView("pjoin2")
			//attractions
			ajoin2 = JoinViews("ajoin2", "stcnty_tab.STCNTY", "ajoin.STCNTY", {{"A",}})
			numtours = GetDataVector(ajoin2+"|", "[N ajoin]", {{"Sort Order", {{"stcnty_tab.STCNTY","Ascending"}}}}) 
			SetDataVector(attr_tab+"|", fields[counter], numtours, {{"Sort Order", {{"STCNTY","Ascending"}}}})
			CloseView("ajoin2")
			counter = counter + 1
			CloseView("pjoin")
			CloseView("ajoin")
			CloseView("dc_tab")
			dc_tab = null
		end
	end		
			
	prod_tab2 = ExportView("prod_tab|", "CSV", DirReport + "\\ProductionsByCo.csv", {"STCNTY", "County", "HBW1", "HBW2", "HBW3", "HBW4", "SCH", "HBU", "HBS1", "HBS2", "HBS3", "HBS4", "HBO1", "HBO2", "HBO3", "HBO4", "ATW", "IXW", "IXN", "XIW", "XIN"},	{ {"CSV Header", "True"} } )
	attr_tab2 = ExportView("attr_tab|", "CSV", DirReport + "\\AttractionsByCo.csv",{"STCNTY", "County", "HBW1", "HBW2", "HBW3", "HBW4", "SCH", "HBU", "HBS1", "HBS2", "HBS3", "HBS4", "HBO1", "HBO2", "HBO3", "HBO4", "ATW", "IXW", "IXN", "XIW", "XIN"},	{ {"CSV Header", "True"} } )

//*******************************************************************************************************************************************************************
//Create the "StopsByCoPA" and "StopsByCoAP" files (.bin)
//Macro "Tour_StopsByCounty"

  UpdateProgressBar("Stops By County", 10) 

	datentime = GetDateandTime()
	AppendToLogFile(1, "Runstats Tour_StopsByCounty: " + datentime)

//	purp = {"HBW", "SCH", "HBU", "HBS", "HBO", "ATW", "EXT", "XIW", "XIN"}
//	purp_tab = {"dcHBW", "dcSCH", "dcHBU", "dcHBS", "dcHBO", "dcATW", "dcEXT", "dcXIW", "dcXIN"}
	fields = {"HBW", "SCH", "HBU", "HBS", "HBO", "ATW", "IXW", "IXN", "XIW", "XIN"}

/*	stcnty_tab = OpenTable("stcnty_tab", "DBASE", {MetDir + "\\STCNTY_ID.dbf",})
	stcnty = GetDataVector(stcnty_tab + "|", "STCNTY",)
	counties = GetDataVector(stcnty_tab + "|", "NAME",)
	se_vw = OpenTable("se_tab", "DBASE", {Dir + "\\LandUse\\LANDUSE_15_TAZ3490_MDINC10.dbf",})
*/
//create AP and PA tables
	ap_tab = CreateTable("ap_tab", DirReport + "\\StopsByCo_AP.bin", "FFB", {{"STCNTY", "Integer", 5, , "No"}, {"County", "String", 15, , "No"}}) 
	rh = AddRecords("ap_tab", , ,{{"Empty Records", counties.length}})
	apstrct = GetTableStructure(ap_tab)					
	
	pa_tab = CreateTable("pa_tab", DirReport + "\\StopsByCo_PA.bin", "FFB", {{"STCNTY", "Integer", 5, , "No"}, {"County", "String", 15, , "No"}}) 
	rh = AddRecords("pa_tab", , ,{{"Empty Records", counties.length}})
	pastrct = GetTableStructure(pa_tab)
						
	for j = 1 to apstrct.length do
 		apstrct[j] = apstrct[j] + {apstrct[j][1]}
 		pastrct[j] = pastrct[j] + {pastrct[j][1]}
 	end
	for j = 1 to fields.length do
		apstrct = apstrct + {{fields[j], "Integer", 8,,,,,,,,,}}
		pastrct = pastrct + {{fields[j], "Integer", 8,,,,,,,,,}}
 	end
	ModifyTable(ap_tab, apstrct)
	ModifyTable(pa_tab, pastrct)

// fill in STCNTY and County name	
	SetDataVectors("ap_tab|", {{"STCNTY", stcnty}, {"County", counties}},)
	SetDataVectors("pa_tab|", {{"STCNTY", stcnty}, {"County", counties}},)

	counter = 1
	apfield = {"SL_AP1","SL_AP2","SL_AP3","SL_AP4","SL_AP5","SL_AP6","SL_AP7"}
	pafield = {"SL_PA1","SL_PA2","SL_PA3","SL_PA4","SL_PA5","SL_PA6","SL_PA7"}
		
// Open DC tables, join to get county totals 
	for p = 1 to purp.length do	//purp.length
		dc_tab = OpenTable("dc_tab", "FFB", {DirOutDC + "\\dc" +purp[p] + ".bin",})
		apstop = GetDataVector(dc_tab+"|", "IS_AP", )
		apmax = VectorStatistic(apstop, "Max", )
		pastop = GetDataVector(dc_tab+"|", "IS_PA", )
		pamax = VectorStatistic(pastop, "Max", )

		
		if (purp[p] <> "XIW" and purp[p] <> "XIN" and purp[p] <> "EXT") then do // Calculate for internal-internal dc table
			//fill ap
			totaltours = vector(counties.length, "long",{{"Constant", 0}})
			for s = 1 to apmax do
//				apjoin = JoinViews("apjoin", "dc_tab." + apfield[s], "se_vw.TAZ",)
				apjoin = JoinViews("apjoin", "dc_tab." + apfield[s], "SEFile.TAZ",)
				apjoin2 = JoinViews("apjoin2", "stcnty_tab.STCNTY", "apjoin.STCNTY", {{"A",}}) 
				numtours = GetDataVector(apjoin2+"|", "[N apjoin]", {{"Sort Order", {{"stcnty_tab.STCNTY","Ascending"}}}}) 
				totaltours = totaltours + numtours
				CloseView("apjoin")
				CloseView("apjoin2")
			end
			SetDataVector("ap_tab|", fields[counter], totaltours, {{"Sort Order", {{"STCNTY","Ascending"}}}})
			//fill pa
			totaltours = vector(counties.length, "long",{{"Constant", 0}})
			for s = 1 to pamax do
				pajoin = JoinViews("pajoin", "dc_tab." + pafield[s], "SEFile.TAZ",)
				pajoin2 = JoinViews("pajoin2", "stcnty_tab.STCNTY", "pajoin.STCNTY", {{"A",}}) 
				numtours = GetDataVector(pajoin2+"|", "[N pajoin]", {{"Sort Order", {{"stcnty_tab.STCNTY","Ascending"}}}}) 
				totaltours = totaltours + numtours
				CloseView("pajoin")
				CloseView("pajoin2")
			end
			SetDataVector("pa_tab|", fields[counter], totaltours, {{"Sort Order", {{"STCNTY","Ascending"}}}})	
		counter = counter + 1
		CloseView("dc_tab")
		dc_tab = null
		end
		
		else if (purp[p] = "EXT") then do // Calculate for internal-external dc table
			//fill IXW first, ap & pa direction
			SetView(dc_tab)
			qry = "Select * where Purp = 'HBW'"
			precs = SelectByQuery("precs", "Several", qry)
			ExportView("dc_tab|precs", "MEM", "IXW",,)
			SetView("IXW")
			//fill ap
			totaltours = vector(counties.length, "long",{{"Constant", 0}})
			for s = 1 to apmax do
				apjoin = JoinViews("apjoin", "IXW." + apfield[s], "SEFile.TAZ",)
				apjoin2 = JoinViews("apjoin2", "stcnty_tab.STCNTY", "apjoin.STCNTY", {{"A",}}) 
				numtours = GetDataVector(apjoin2+"|", "[N apjoin]", {{"Sort Order", {{"stcnty_tab.STCNTY","Ascending"}}}}) 
				totaltours = totaltours + numtours
				CloseView("apjoin")
				CloseView("apjoin2")
			end
			SetDataVector("ap_tab|", fields[counter], totaltours, {{"Sort Order", {{"STCNTY","Ascending"}}}})
			
			//fill pa
			totaltours = vector(counties.length, "long",{{"Constant", 0}})
			for s = 1 to pamax do
				pajoin = JoinViews("pajoin", "IXW." + pafield[s], "SEFile.TAZ",)
				pajoin2 = JoinViews("pajoin2", "stcnty_tab.STCNTY", "pajoin.STCNTY", {{"A",}}) 
				numtours = GetDataVector(pajoin2+"|", "[N pajoin]", {{"Sort Order", {{"stcnty_tab.STCNTY","Ascending"}}}}) 
				totaltours = totaltours + numtours
				CloseView("pajoin")
				CloseView("pajoin2")
			end
			SetDataVector("pa_tab|", fields[counter], totaltours, {{"Sort Order", {{"STCNTY","Ascending"}}}})    //set productions
			
			CloseView("IXW")
			IXW = null
			counter = counter + 1
			
			//next IXN, ap & pa direction
			SetView(dc_tab)
			qry = "Select * where Purp <> 'HBW'"
			precs = SelectByQuery("precs", "Several", qry)
			ExportView("dc_tab|precs", "MEM", "IXN",,)
			SetView("IXN")
			//fill ap
			totaltours = vector(counties.length, "long",{{"Constant", 0}})
			for s = 1 to apmax do
				apjoin = JoinViews("apjoin", "IXN." + apfield[s], "SEFile.TAZ",)
				apjoin2 = JoinViews("apjoin2", "stcnty_tab.STCNTY", "apjoin.STCNTY", {{"A",}}) 
				numtours = GetDataVector(apjoin2+"|", "[N apjoin]", {{"Sort Order", {{"stcnty_tab.STCNTY","Ascending"}}}}) 
				totaltours = totaltours + numtours
				CloseView("apjoin")
				CloseView("apjoin2")
			end
			SetDataVector("ap_tab|", fields[counter], totaltours, {{"Sort Order", {{"STCNTY","Ascending"}}}})
			//fill pa
			totaltours = vector(counties.length, "long",{{"Constant", 0}})
			for s = 1 to pamax do
				pajoin = JoinViews("pajoin", "IXN." + pafield[s], "SEFile.TAZ",)
				pajoin2 = JoinViews("pajoin2", "stcnty_tab.STCNTY", "pajoin.STCNTY", {{"A",}}) 
				numtours = GetDataVector(pajoin2+"|", "[N pajoin]", {{"Sort Order", {{"stcnty_tab.STCNTY","Ascending"}}}}) 
				totaltours = totaltours + numtours
				CloseView("pajoin")
				CloseView("pajoin2")
			end
			SetDataVector("pa_tab|", fields[counter], totaltours, {{"Sort Order", {{"STCNTY","Ascending"}}}})    //set productions
			
			counter = counter + 1
			CloseView("IXN")
			IXN = null
			CloseView("dc_tab")
			dc_tab = null
		end
		else do // Calculate for external-external dc table
			//fill ap
			totaltours = vector(counties.length, "long",{{"Constant", 0}})
			for s = 1 to apmax do
				apjoin = JoinViews("apjoin", "dc_tab." + apfield[s], "SEFile.TAZ",)
				apjoin2 = JoinViews("apjoin2", "stcnty_tab.STCNTY", "apjoin.STCNTY", {{"A",}}) 
				numtours = GetDataVector(apjoin2+"|", "[N apjoin]", {{"Sort Order", {{"stcnty_tab.STCNTY","Ascending"}}}}) 
				totaltours = totaltours + numtours
				CloseView("apjoin")
				CloseView("apjoin2")
			end
			SetDataVector("ap_tab|", fields[counter], totaltours, {{"Sort Order", {{"STCNTY","Ascending"}}}})
			//fill pa
			totaltours = vector(counties.length, "long",{{"Constant", 0}})
			for s = 1 to pamax do
				pajoin = JoinViews("pajoin", "dc_tab." + pafield[s], "SEFile.TAZ",)
				pajoin2 = JoinViews("pajoin2", "stcnty_tab.STCNTY", "pajoin.STCNTY", {{"A",}}) 
				numtours = GetDataVector(pajoin2+"|", "[N pajoin]", {{"Sort Order", {{"stcnty_tab.STCNTY","Ascending"}}}}) 
				totaltours = totaltours + numtours
				CloseView("pajoin")
				CloseView("pajoin2")
			end
			SetDataVector("pa_tab|", fields[counter], totaltours, {{"Sort Order", {{"STCNTY","Ascending"}}}})
			
			counter = counter + 1
			CloseView("dc_tab")
			dc_tab = null
		end
		
	end		
		
	pa_tab2 = ExportView("pa_tab|", "CSV", DirReport + "\\StopsByCo_PA.csv",{"STCNTY", "County", "HBW", "SCH", "HBU", "HBS", "HBO", "ATW", "IXW", "IXN", "XIW", "XIN"}, { {"CSV Header", "True"} } )
	ap_tab2 = ExportView("ap_tab|", "CSV", DirReport + "\\StopsByCo_AP.csv",{"STCNTY", "County", "HBW", "SCH", "HBU", "HBS", "HBO", "ATW", "IXW", "IXN", "XIW", "XIN"}, { {"CSV Header", "True"} } )

//*******************************************************************************************************************************************************************
//Create the "HHTOUR_ALLOCATION" file (.bin)
//Macro "Tour_Num"

  UpdateProgressBar("Number of Tours", 10) 

	datentime = GetDateandTime()
	AppendToLogFile(1, "Runstats HHTOUR_ALLOCATION: " + datentime)

	DirTF  = Dir + "\\TG"

	purp = {"HBW", "SCH", "HBU", "HBS", "HBO"}

	HHTOUR_ALLOCATION = CreateTable("HHTOUR_ALLOCATION", DirReport + "\\HHTOUR_ALLOCATION.bin", "FFB", {{"Tours", "Integer", 2, , "No"}, {"SCH", "Integer", 8, , "No"}, {"HBU", "Integer", 8, , "No"}, 
			{"HBW", "Integer", 8, , "No"}, {"HBS", "Integer", 8, , "No"}, {"HBO", "Integer", 8, , "No"}})
	rh = AddRecords("HHTOUR_ALLOCATION", {"Tours"}, {{0},{1},{2},{3},{4},{5},{6},{7},{8},{9},{10}},)
			
	tf_file = OpenTable("tf_file", "FFB", {DirTF + "\\TourRecords.bin",})

	for p =  1 to purp.length do
		for n =  1 to 11 do
			qry = "Select * where " + purp[p] + " = " + i2s(n-1)
			SetView("tf_file")
			numT = SelectByQuery("numT", "Several", qry)
			rh = LocateRecord("HHTOUR_ALLOCATION|", "Tours", {i2s(n-1)}, )
			SetRecordValues("HHTOUR_ALLOCATION", rh, {{purp[p], numT}})
		end
	end
		
	TFnum_tab2 = ExportView("HHTOUR_ALLOCATION|", "CSV", DirReport + "\\HHTOUR_ALLOCATION.csv",{"Tours", "SCH", "HBU", "HBW", "HBS", "HBO"}, { {"CSV Header", "True"} } )
//*******************************************************************************************************************************************************************
//Create the second runstats output file for Tour Frequency (.bin)
//Macro "Tour_NumByCounty"

  UpdateProgressBar("Runstats Number of Tours", 10) 

	datentime = GetDateandTime()
	AppendToLogFile(1, "Tour_NumByCounty: " + datentime)

	DirTF  = Dir + "\\TG"

	purp = {"HBW", "SCH", "HBU", "HBS", "HBO"}


	TFnumXco = CreateTable("TFnumXco", DirReport + "\\TF_NumByCounty.bin", "FFB", {{"County", "Integer", 6, , "No"}, {"Tours", "Integer", 2, , "No"}, {"HBW", "Integer", 8, , "No"}, 
			{"SCH", "Integer", 8, , "No"}, {"HBU", "Integer", 8, , "No"}, {"HBS", "Integer", 8, , "No"}, {"HBO", "Integer", 8, , "No"}})

	pjoin = JoinViews("pjoin", "tf_file.TAZ", "SEFile.TAZ",)
	
	for c = 1 to counties.length do
		for n = 1 to 11 do	//10 is max number of stops
			rh = AddRecord("TFnumXco", {{"County", stcnty[c]}, {"Tours", i2s(n-1)}})
		end
	end
	for p = 1 to purp.length do	//purp.length
		counter = 1
		for c = 1 to counties.length do
			for n = 1 to 10 do	//10 is max number of stops
				qry = "Select * where STCNTY = " + i2s(stcnty[c]) + " and " + purp[p] + " = " + i2s(n-1)
				SetView(pjoin)
				numtours = SelectByQuery("numtours", "Several", qry)
				SetRecordValues("TFnumXco", i2s(counter), {{purp[p], numtours}})
				counter = counter + 1
			end
		end

	end

	TFnumXco_tab2 = ExportView("TFnumXco|", "CSV", DirReport + "\\TF_NumByCounty.csv",{"County", "Tours", "HBW", "SCH", "HBU", "HBS", "HBO"}, { {"CSV Header", "True"} } )
//*******************************************************************************************************************************************************************
//Creates the "StopsByCoPA" and "StopsByCoAP" files (.bin)
//Macro "Tour_StopsByCounty"

/*  UpdateProgressBar("Runstats Tour_StopsByCounty", 10) 

	purp = {"HBW", "SCH", "HBU", "HBS", "HBO", "ATW", "EXT", "XIW", "XIN"}
	purp_tab = {"dcHBW", "dcSCH", "dcHBU", "dcHBS", "dcHBO", "dcATW", "dcEXT", "dcXIW", "dcXIN"}
	fields = {"HBW", "SCH", "HBU", "HBS", "HBO", "ATW", "IXW", "IXN", "XIW", "XIN"}


	stcnty_tab = OpenTable("stcnty_tab", "DBASE", {MetDir + "\\STCNTY_ID.dbf",})
	stcnty = GetDataVector(stcnty_tab + "|", "STCNTY",)
	counties = GetDataVector(stcnty_tab + "|", "NAME",)

	se_tab = OpenTable("se_tab", "DBASE", {Dir + "\\LandUse\\LANDUSE_15_TAZ3490_MDINC10.dbf",})

//create AP and PA tables
	ap_tab = CreateTable("ap_tab", DirReport + "\\StopsByCo_AP.bin", "FFB", {{"STCNTY", "Integer", 5, , "No"}, {"County", "String", 15, , "No"}}) 
	rh = AddRecords("ap_tab", , ,{{"Empty Records", counties.length}})
	apstrct = GetTableStructure(ap_tab)					
	
	pa_tab = CreateTable("pa_tab", DirReport + "\\StopsByCo_PA.bin", "FFB", {{"STCNTY", "Integer", 5, , "No"}, {"County", "String", 15, , "No"}}) 
	rh = AddRecords("pa_tab", , ,{{"Empty Records", counties.length}})
	pastrct = GetTableStructure(pa_tab)
						
	for j = 1 to apstrct.length do
 		apstrct[j] = apstrct[j] + {apstrct[j][1]}
 		pastrct[j] = pastrct[j] + {pastrct[j][1]}
 	end
	for j = 1 to fields.length do
		apstrct = apstrct + {{fields[j], "Integer", 8,,,,,,,,,}}
		pastrct = pastrct + {{fields[j], "Integer", 8,,,,,,,,,}}
 	end
	ModifyTable(ap_tab, apstrct)
	ModifyTable(pa_tab, pastrct)

// fill in STCNTY and County name	
	SetDataVectors("ap_tab|", {{"STCNTY", stcnty}, {"County", counties}},)
	SetDataVectors("pa_tab|", {{"STCNTY", stcnty}, {"County", counties}},)

	counter = 1
	apfield = {"SL_AP1","SL_AP2","SL_AP3","SL_AP4","SL_AP5","SL_AP6","SL_AP7"}
	pafield = {"SL_PA1","SL_PA2","SL_PA3","SL_PA4","SL_PA5","SL_PA6","SL_PA7"}
		
// Open DC tables, join to get county totals 
	for p = 1 to purp.length do	//purp.length
		dc_tab = OpenTable("dc_tab", "FFB", {DirOutDC + "\\dc" +purp[p] + ".bin",})
		apstop = GetDataVector(dc_tab+"|", "IS_AP", )
		apmax = VectorStatistic(apstop, "Max", )
		pastop = GetDataVector(dc_tab+"|", "IS_PA", )
		pamax = VectorStatistic(pastop, "Max", )

		
		if (purp[p] <> "XIW" and purp[p] <> "XIN" and purp[p] <> "EXT") then do // Calculate for internal-internal dc table
			//fill ap
			totaltours = vector(counties.length, "long",{{"Constant", 0}})
			for s = 1 to apmax do
				apjoin = JoinViews("apjoin", "dc_tab." + apfield[s], "se_tab.TAZ",)
				apjoin2 = JoinViews("apjoin2", "stcnty_tab.STCNTY", "apjoin.STCNTY", {{"A",}}) 
				numtours = GetDataVector(apjoin2+"|", "[N apjoin]", {{"Sort Order", {{"stcnty_tab.STCNTY","Ascending"}}}}) 
				totaltours = totaltours + numtours
				CloseView("apjoin")
				CloseView("apjoin2")
			end
			SetDataVector("ap_tab|", fields[counter], totaltours, {{"Sort Order", {{"STCNTY","Ascending"}}}})
			//fill pa
			totaltours = vector(counties.length, "long",{{"Constant", 0}})
			for s = 1 to pamax do
				pajoin = JoinViews("pajoin", "dc_tab." + pafield[s], "se_tab.TAZ",)
				pajoin2 = JoinViews("pajoin2", "stcnty_tab.STCNTY", "pajoin.STCNTY", {{"A",}}) 
				numtours = GetDataVector(pajoin2+"|", "[N pajoin]", {{"Sort Order", {{"stcnty_tab.STCNTY","Ascending"}}}}) 
				totaltours = totaltours + numtours
				CloseView("pajoin")
				CloseView("pajoin2")
			end
			SetDataVector("pa_tab|", fields[counter], totaltours, {{"Sort Order", {{"STCNTY","Ascending"}}}})	
		counter = counter + 1
		CloseView("dc_tab")
		dc_tab = null
		end
		
		else if (purp[p] = "EXT") then do // Calculate for internal-external dc table
			//fill IXW first, ap & pa direction
			SetView(dc_tab)
			qry = "Select * where Purp = 'HBW'"
			precs = SelectByQuery("precs", "Several", qry)
			ExportView("dc_tab|precs", "MEM", "IXW",,)
			SetView("IXW")
			//fill ap
			totaltours = vector(counties.length, "long",{{"Constant", 0}})
			for s = 1 to apmax do
				apjoin = JoinViews("apjoin", "IXW." + apfield[s], "se_tab.TAZ",)
				apjoin2 = JoinViews("apjoin2", "stcnty_tab.STCNTY", "apjoin.STCNTY", {{"A",}}) 
				numtours = GetDataVector(apjoin2+"|", "[N apjoin]", {{"Sort Order", {{"stcnty_tab.STCNTY","Ascending"}}}}) 
				totaltours = totaltours + numtours
				CloseView("apjoin")
				CloseView("apjoin2")
			end
			SetDataVector("ap_tab|", fields[counter], totaltours, {{"Sort Order", {{"STCNTY","Ascending"}}}})
			
			//fill pa
			totaltours = vector(counties.length, "long",{{"Constant", 0}})
			for s = 1 to pamax do
				pajoin = JoinViews("pajoin", "IXW." + pafield[s], "se_tab.TAZ",)
				pajoin2 = JoinViews("pajoin2", "stcnty_tab.STCNTY", "pajoin.STCNTY", {{"A",}}) 
				numtours = GetDataVector(pajoin2+"|", "[N pajoin]", {{"Sort Order", {{"stcnty_tab.STCNTY","Ascending"}}}}) 
				totaltours = totaltours + numtours
				CloseView("pajoin")
				CloseView("pajoin2")
			end
			SetDataVector("pa_tab|", fields[counter], totaltours, {{"Sort Order", {{"STCNTY","Ascending"}}}})    //set productions
			
			CloseView("IXW")
			IXW = null
			counter = counter + 1
			
			//next IXN, ap & pa direction
			SetView(dc_tab)
			qry = "Select * where Purp <> 'HBW'"
			precs = SelectByQuery("precs", "Several", qry)
			ExportView("dc_tab|precs", "MEM", "IXN",,)
			SetView("IXN")
			//fill ap
			totaltours = vector(counties.length, "long",{{"Constant", 0}})
			for s = 1 to apmax do
				apjoin = JoinViews("apjoin", "IXN." + apfield[s], "se_tab.TAZ",)
				apjoin2 = JoinViews("apjoin2", "stcnty_tab.STCNTY", "apjoin.STCNTY", {{"A",}}) 
				numtours = GetDataVector(apjoin2+"|", "[N apjoin]", {{"Sort Order", {{"stcnty_tab.STCNTY","Ascending"}}}}) 
				totaltours = totaltours + numtours
				CloseView("apjoin")
				CloseView("apjoin2")
			end
			SetDataVector("ap_tab|", fields[counter], totaltours, {{"Sort Order", {{"STCNTY","Ascending"}}}})
			//fill pa
			totaltours = vector(counties.length, "long",{{"Constant", 0}})
			for s = 1 to pamax do
				pajoin = JoinViews("pajoin", "IXN." + pafield[s], "se_tab.TAZ",)
				pajoin2 = JoinViews("pajoin2", "stcnty_tab.STCNTY", "pajoin.STCNTY", {{"A",}}) 
				numtours = GetDataVector(pajoin2+"|", "[N pajoin]", {{"Sort Order", {{"stcnty_tab.STCNTY","Ascending"}}}}) 
				totaltours = totaltours + numtours
				CloseView("pajoin")
				CloseView("pajoin2")
			end
			SetDataVector("pa_tab|", fields[counter], totaltours, {{"Sort Order", {{"STCNTY","Ascending"}}}})    //set productions
			
			counter = counter + 1
			CloseView("IXN")
			IXN = null
			CloseView("dc_tab")
			dc_tab = null
		end
		else do // Calculate for external-external dc table
			//fill ap
			totaltours = vector(counties.length, "long",{{"Constant", 0}})
			for s = 1 to apmax do
				apjoin = JoinViews("apjoin", "dc_tab." + apfield[s], "se_tab.TAZ",)
				apjoin2 = JoinViews("apjoin2", "stcnty_tab.STCNTY", "apjoin.STCNTY", {{"A",}}) 
				numtours = GetDataVector(apjoin2+"|", "[N apjoin]", {{"Sort Order", {{"stcnty_tab.STCNTY","Ascending"}}}}) 
				totaltours = totaltours + numtours
				CloseView("apjoin")
				CloseView("apjoin2")
			end
			SetDataVector("ap_tab|", fields[counter], totaltours, {{"Sort Order", {{"STCNTY","Ascending"}}}})
			//fill pa
			totaltours = vector(counties.length, "long",{{"Constant", 0}})
			for s = 1 to pamax do
				pajoin = JoinViews("pajoin", "dc_tab." + pafield[s], "se_tab.TAZ",)
				pajoin2 = JoinViews("pajoin2", "stcnty_tab.STCNTY", "pajoin.STCNTY", {{"A",}}) 
				numtours = GetDataVector(pajoin2+"|", "[N pajoin]", {{"Sort Order", {{"stcnty_tab.STCNTY","Ascending"}}}}) 
				totaltours = totaltours + numtours
				CloseView("pajoin")
				CloseView("pajoin2")
			end
			SetDataVector("pa_tab|", fields[counter], totaltours, {{"Sort Order", {{"STCNTY","Ascending"}}}})
			
			counter = counter + 1
			CloseView("dc_tab")
			dc_tab = null
		end
		
	end		
*/			

//*******************************************************************************************************************************************************************
//Creates DC_output, ODtime_dist & StopsDistr files

//Macro "DC_output"

  UpdateProgressBar("Runstats DC_output", 10) 

	purp = {"HBW", "SCH", "HBU", "HBS", "HBO", "ATW", "XIW", "XIN"}	// IMPORTANT, USE THIS ORDER, otherwise need to change loop below

	maxtimeslots = 18	//this is the number of time ranges in ten minute increments: ie, 18 would be "0-10" to "170+"
	
	//create one table to output number of tours by II/IX/XI, average (direct) OD times by purpose, and intrazonals
	DCout_tab = CreateTable("DCout_tab", DirReport + "\\DC_output.bin", "FFB", {{"PURP", "String", 4,,"No"}, {"II_Tours", "Integer", 9, , "No"}, {"IX_Tours", "Integer", 9, , "No"}, {"XI_Tours", "Integer", 9, , "No"}, 
					{"Intrazonal", "Integer", 9, , "No"}, {"AVG_Time_II", "Real", 8, 2, "No"}, {"AVG_Time_IX", "Real", 8, 2, "No"}, {"AVG_Time_XI", "Real", 8, 2, "No"},
					{"AVGTourTT_PA", "Real", 8, 2, "No"}, {"AVGTourTT_AP", "Real", 8, 2, "No"}}) 
	rh = AddRecords("DCout_tab", , ,{{"Empty Records", purp.length}})
	purp_v = a2v(purp)
	SetDataVector("DCout_tab|", "PURP", purp_v,)

	//create another table to output the number of tours in 10 minute bins
	ODtime_tab = CreateTable("ODtime_tab", DirReport + "\\ODtime_distr.bin", "FFB", {{"TimeDistr", "String", 10, , "No"}}) 
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
		time_ar[t] = "[" + i2s(buck) + "_" + i2s(buck+10) + "]"
		buck = buck +10
	end
	time_ar[maxtimeslots] = "[" + i2s((maxtimeslots-1)*10) + "+]"
	time_v = a2v(time_ar)
	SetDataVector("ODtime_tab|", "TimeDistr",time_v,)
	
	//create a third table to output the distribution of number of stops per half tours
	stopsdistr_tab = CreateTable("stopsdistr_tab", DirReport + "\\StopsDistr.bin", "FFB", {{"PURP", "String", 4,,"No"}}) 
	tabstrct = GetTableStructure(stopsdistr_tab)						
	for j = 1 to tabstrct.length do
 		tabstrct[j] = tabstrct[j] + {tabstrct[j][1]}
 	end
	appa = {"PA", "AP"}
	for d = 1 to 2 do // PA/AP
		for s = 1 to 8 do // 7 max stops
			tabstrct = tabstrct + {{appa[d] + i2s(s-1) + "Stops", "Integer", 8,,,,,,,,,}}
		end
 	end
	ModifyTable(stopsdistr_tab, tabstrct)
	rh = AddRecords("stopsdistr_tab", , ,{{"Empty Records", (purp.length)}})
	SetDataVector("stopsdistr_tab|", "PURP", purp_v,)

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
		TTpa_v = GetDatavector(current_file + "|", "TourTT_PA",)
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
		
		// OD time distribution:
		OD_floor = CreateExpression("current_file", "ODFloor", "if OD_Time > " + i2s(maxtimeslots*10) + " then (" + i2s(maxtimeslots) + " - 1) else Floor(OD_Time/10)",)	//divide by 10 to get bucket			
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