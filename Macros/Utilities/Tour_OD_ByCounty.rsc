Macro "Tour_OD_ByCounty"

//Creates the "ProductionsByCo" and "AttractionsByCo" files (.bin)

/*	on error goto badquit
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
*/	RunMacro("TCB Init")

	RunMacro("G30 File Close All") 

	MetDir = "C:\\MRM19v1.0\\Metrolina"						// <---- HAND CODE
	Dir = MetDir + "\\2015"								// <---- HAND CODE
	sedata_file = Dir + "\\LandUse\\LANDUSE_15_TAZ3490_MDINC10.dbf"			// <---- HAND CODE


	DirTG  = Dir + "\\TG"
 	DirOutDC  = Dir + "\\TD"
	DirReport  = Dir + "\\Report"
 	
 	yr_str = Right(theyear,2)
	yr = s2i(yr_str)

	purp = {"HBW", "SCH", "HBU", "HBS", "HBO", "ATW"}
//	purp_tab = {"dcHBW", "dcSCH", "dcHBU", "dcHBS", "dcHBO", "dcATW"}


/*	counties = {{37025, "Cabarrus"}, {37035, "Catawba"}, {37045, "Cleveland"}, {37071, "Gaston"}, {37097, "Iredell"}, {37109, "Lincoln"}, {37119, "Mecklenburg"}, 
			{37159, "Rowan"}, {37167, "Stanly"}, {37179, "Union"}, {45057, "Lancaster"}, {45091, "York"}, {99999, "External"}}
*/	stcnty_tab = OpenTable("stcnty_tab", "DBASE", {MetDir + "\\STCNTY_ID.dbf",})
	stcnty = GetDataVector(stcnty_tab + "|", "STCNTY",)
	counties = GetDataVector(stcnty_tab + "|", "NAME",)
	stcnty_ar = v2a(stcnty)
		
	se_vw = OpenTable("SEFile", "dBASE", {sedata_file,})

//**************************************************************************************************************************************************************
//Create a total OD table for all tour types (combined) (.bin)

//create OD table
/*	OD_tab = CreateTable("OD_tab", DirReport + "\\ODbyCo.bin", "FFB", {{"County", "String", 15, , "No"}}) 
	rh = AddRecords("OD_tab", , ,{{"Empty Records", counties.length}})
	strct = GetTableStructure(OD_tab)					
	for j = 1 to strct.length do
 		strct[j] = strct[j] + {strct[j][1]}
 	end
	for j = 1 to counties_ar.length do
		strct = strct + {{counties_ar[j], "Integer", 8,,,,,,,,,}}
 	end
	ModifyTable(OD_tab, strct)
*/

//Create matrix
	OD_mat = CreateMatrix({"stcnty_tab|", "stcnty_tab.STCNTY", "Rows"}, {"stcnty_tab|", "stcnty_tab.STCNTY", "Columns"}, 
				{{"File Name", DirReport + "\\OD_PersonTours.mtx"}, {"Type", "Long"}})
	OD_mc = CreateMatrixCurrency(OD_mat, "Table", "Rows", "Columns", )
	FillMatrix(OD_mc, , , {"Copy", 0},)
	
	
// fill in County name	
//	SetDataVectors("OD_tab|", {{"County", counties}},)

// Open DC tables, join to get county totals (by income if required)	
	for p = 1 to purp.length do	//purp.length
		dc_tab = OpenTable("dc_tab", "FFB", {DirOutDC + "\\dc" + purp[p] + ".bin",})
		Ojoin = JoinViews("Ojoin", "dc_tab.ORIG_TAZ", "SEFile.TAZ",)
		Djoin = JoinViews("Djoin", "dc_tab.DEST_TAZ", "SEFile.TAZ",)
		ODjoin = JoinViews("ODjoin", "Ojoin.ID", "Djoin.ID",)

		for c = 1 to counties.length do
			for c2 = 1 to counties.length do
				qry = "Select * where Ojoin.SEFile.STCNTY = " + i2s(stcnty_ar[c]) + " and Djoin.SEFile.STCNTY = " + i2s(stcnty_ar[c2])
				SetView(ODjoin)
				recs = SelectByQuery("recs", "Several", qry)
//				SetMatrixValue(OD_mc, i2s(stcnty_ar[c]), i2s(stcnty_ar[c2]), recs)
				FillMatrix(OD_mc, {i2s(stcnty_ar[c])}, {i2s(stcnty_ar[c2])}, {"Add", recs},)
			end
		end
		CloseView("ODjoin")
		CloseView("Djoin")
		CloseView("Ojoin")
		CloseView("dc_tab")
		dc_tab = null
	end		
			
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