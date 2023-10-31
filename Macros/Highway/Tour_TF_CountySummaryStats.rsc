Macro "Tour_TF_CountySummaryStats"

//Creates the "Productions" and "Attractions" files (.bin)

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
	AppendToLogFile(1, "Tour TOD1: " + datentime)
	RunMacro("TCB Init")

	RunMacro("G30 File Close All") 

	DirTG  = Dir + "\\TG"
 	DirOutDC  = Dir + "\\TD"
 	
 	yr_str = Right(theyear,2)
	yr = s2i(yr_str)

  CreateProgressBar("TF County Summary Stats", "TRUE")

	purp = {"HBW", "SCH", "HBU", "HBS", "HBO", "ATW", "EXT", "XIW", "XIN"}
	purp_tab = {"dcHBW", "dcSCH", "dcHBU", "dcHBS", "dcHBO", "dcATW", "dcEXT", "dcXIW", "dcXIN"}
	fields = {"HBW1", "HBW2", "HBW3", "HBW4", "SCH", "HBU", "HBS1", "HBS2", "HBS3", "HBS4", "HBO1", "HBO2", "HBO3", "HBO4", "ATW", "IXW", "IXN", "XIW", "XIN"}


/*	counties = {{37025, "Cabarrus"}, {37035, "Catawba"}, {37045, "Cleveland"}, {37071, "Gaston"}, {37097, "Iredell"}, {37109, "Lincoln"}, {37119, "Mecklenburg"}, 
			{37159, "Rowan"}, {37167, "Stanly"}, {37179, "Union"}, {45057, "Lancaster"}, {45091, "York"}, {99999, "External"}}
*/	stcnty_tab = OpenTable("stcnty_tab", "DBASE", {MetDir + "\\STCNTY_ID.dbf",})
	stcnty = GetDataVector(stcnty_tab + "|", "STCNTY",)
	counties = GetDataVector(stcnty_tab + "|", "NAME",)

	se_vw = OpenTable("SEFile", "dBASE", {sedata_file,})

//create Productions and Attractions tables
	prod_tab = CreateTable("prod_tab", DirTG + "\\Productions.bin", "FFB", {{"STCNTY", "Integer", 5, , "No"}, {"County", "String", 15, , "No"}}) 
	rh = AddRecords("prod_tab", , ,{{"Empty Records", counties.length}})
	pstrct = GetTableStructure(prod_tab)					
	attr_tab = CreateTable("attr_tab", DirTG + "\\Attractions.bin", "FFB", {{"STCNTY", "Integer", 5, , "No"}, {"County", "String", 15, , "No"}}) 
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
			

    DestroyProgressBar()
    RunMacro("G30 File Close All")

    goto quit

	badquit:
		on error, notfound default
		RunMacro("TCB Closing", ret_value, "TRUE" )
		msg = msg + {"Tour TOD1: Error somewhere"}
		AppendToLogFile(1, "Tour TOD1: Error somewhere")
		datentime = GetDateandTime()
		AppendToLogFile(1, "Tour TOD1 " + datentime)

       	return({0, msg})

    quit:
		on error, notfound default
   		datentime = GetDateandTime()
		AppendToLogFile(1, "Exit Tour TOD1 " + datentime)
    	return({1, msg})
	
endmacro