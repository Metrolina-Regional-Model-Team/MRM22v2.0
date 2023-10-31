Macro "EE_Trips" (Args)
// Moved from Trip Gen macro - Aug 2015
// Moved EE trip tables (TDeeA, TDeeC, TDeeM, TDeeH) from TG subdirector to TD subdirectory

	LogFile = Args.[Log File].value
	SetLogFileName(LogFile)
	ReportFile = Args.[Report File].value
	SetReportFileName(ReportFile)

	METDir = Args.[MET Directory].value
	Dir = Args.[Run Directory].value
	sedata_dbf = Args.[LandUse File].value
	theyear = Args.[Run Year].value
	yearnet = right(theyear,2)
	msg = null
	TripGenOK = 1

	datentime = GetDateandTime()
	AppendToLogFile(1, "Enter EE_Trips: " + datentime)


//____CREATE EE MATRICES_______________________CHANGE SOURCE TO TEMPLATE_____________

	OM = OpenMatrix(METDir + "\\TAZ\\Matrix_Template.mtx", "True")
	mc1 = CreateMatrixCurrency(OM, "Table", "Rows", "Columns", )

	CopyMatrixStructure({mc1}, {{"File Name", Dir + "\\TD\\TDeeA.mtx"},
		{"Label", "TDeeA"},
		{"File Based", "Yes"},
		{"Tables", {"Trips"}},
		{"Operation", "Union"}})

	CopyMatrixStructure({mc1}, {{"File Name", Dir + "\\TD\\TDeeC.mtx"},
		{"Label", "TDeeC"},
		{"File Based", "Yes"},
		{"Tables", {"Trips"}},
    	{"Operation", "Union"}})

	CopyMatrixStructure({mc1}, {{"File Name", Dir + "\\TD\\TDeeM.mtx"},
		{"Label", "TDeeM"},
		{"File Based", "Yes"},
		{"Tables", {"Trips"}},
		{"Operation", "Union"}})

	CopyMatrixStructure({mc1}, {{"File Name", Dir + "\\TD\\TDeeH.mtx"},
		{"Label", "TDeeH"},
		{"File Based", "Yes"},
		{"Tables", {"Trips"}},
		{"Operation", "Union"}})


//_____________AUTOMOBILES____WRROOOOMMMMM_____WRRRROOOMMMMMMMMMMMMMMMM______
     
	opentable("auto", "FFA", {METDir + "\\ExtSta\\thrubase_auto.asc",})
	opentable("factor", "FFA", {Dir + "\\TG\\xxfactor.asc",})

	JoinViews("auto + factor", "auto.From", "factor.Station", )
	setview("auto + factor")
	ExportView("auto + factor|", "DBASE", Dir + "\\TG\\extfac_auto.dbf", {"From", "To", "Station", "autoRthru", "[PC FACTOR]"},)

	closeview("auto")
	closeview("factor")
	closeview("auto + factor")

	opentable("auto + factor", "DBASE", {Dir + "\\TG\\extfac_auto.dbf",})
	setview("auto + factor")


	strct = GetTableStructure("auto + factor")
	for i = 1 to strct.length do
		// Copy the current name to the end of strct
		strct[i] = strct[i] + {strct[i][1]}
	end
	new_struct = strct + {{"eeA", "Real", 12, 4, "True",,,, null}}
	ModifyTable("auto + factor", new_struct)

	closeview("auto + factor")

	tab = opentable("auto + factor", "DBASE", {Dir + "\\TG\\extfac_auto.dbf",})


	setview("auto + factor")

	hi = GetFirstRecord("auto + factor|",)
	while hi <> null do
		mval = GetRecordValues("auto + factor", hi, {"autoRthru", "PC_FACTOR"})

		auto = mval[1][2]
		factor = mval[2][2]

		SetRecordValues("auto + factor",null,{{"eeA", (auto*factor)}})

		hi = GetNextRecord("auto + factor|", null,)
	end

	FM = OpenMatrix(Dir + "\\TD\\TDeeA.mtx", "True")

	viewset = tab + "|"
	update_flds = {tab+".eeA"}

	UpdateMatrixFromView(FM, viewset, "From", "To", null, update_flds, "Replace",
    	{{"Missing is zero", "Yes"}})

	FM = null
	tab = null
	viewset = null
	update_flds = null

	closeview("auto + factor")

//_________COMMMERCIAL_________RARARARARRARARRRRRRRRRRAAAA

	opentable("com", "FFA", {METDir + "\\ExtSta\\thrubase_com.asc",})
	opentable("factor", "FFA", {Dir + "\\TG\\xxfactor.asc",})
	JoinViews("com + factor", "com.From", "factor.Station", )
	setview("com + factor")
	ExportView("com + factor|", "DBASE", Dir + "\\TG\\extfac_com.dbf", {"From", "To", "Station", "cvRthru", "[COM FACTOR]"},)

	closeview("com")
	closeview("factor")
	closeview("com + factor")
	opentable("com + factor", "DBASE", {Dir + "\\TG\\extfac_com.dbf",})
	
	strct = GetTableStructure("com + factor")
	for i = 1 to strct.length do
		// Copy the current name to the end of strct
		strct[i] = strct[i] + {strct[i][1]}
	end
	new_struct = strct + {{"eeC", "Real", 12, 4, "True",,,, null}}
		
	ModifyTable("com + factor", new_struct)

	closeview("com + factor")

	tab = opentable("com + factor", "DBASE", {Dir + "\\TG\\extfac_com.dbf",})

	setview("com + factor")

	hi = GetFirstRecord("com + factor|",)
	while hi <> null do
		mval = GetRecordValues("com + factor", hi, {"cvRthru", "COM_FACTOR"})

		com = mval[1][2]
		factor = mval[2][2]

		SetRecordValues("com + factor",null,{{"eeC", (com*factor)}})

		hi = GetNextRecord("com + factor|", null,)
	end

	FM = OpenMatrix(Dir + "\\TD\\TDeeC.mtx", "True")

	viewset = tab + "|"
	update_flds = {tab+".eeC"}
	UpdateMatrixFromView(FM, viewset, "From", "To", null, update_flds, "Replace",
    	{{"Missing is zero", "Yes"}})

	FM = null
	tab = null
	viewset = null
	update_flds = null

	closeview("com + factor")

//_____________MEDIUM_TRRRUUUCCCKKKSSSSSS___________

	opentable("mtk", "FFA", {METDir + "\\ExtSta\\thrubase_mtk.asc",})
	opentable("factor", "FFA", {Dir + "\\TG\\xxfactor.asc",})

	JoinViews("mtk + factor", "mtk.From", "factor.Station", )
	setview("mtk + factor")
	ExportView("mtk + factor|", "DBASE", Dir + "\\TG\\extfac_mtk.dbf", {"From", "To", "Station", "mtRthru", "[mtk FACTOR]"},)

	closeview("mtk")
	closeview("factor")
	closeview("mtk + factor")
	opentable("mtk + factor", "DBASE", {Dir + "\\TG\\extfac_mtk.dbf",})
	setview("mtk + factor")
	strct = GetTableStructure("mtk + factor")
	for i = 1 to strct.length do
		// Copy the current name to the end of strct
		strct[i] = strct[i] + {strct[i][1]}
	end
	new_struct = strct + {{"eeM", "Real", 12, 4, "True",,,, null}}
		
	ModifyTable("mtk + factor", new_struct)

	closeview("mtk + factor")

	tab = opentable("mtk + factor", "DBASE", {Dir + "\\TG\\extfac_mtk.dbf",})

	setview("mtk + factor")
	hi = GetFirstRecord("mtk + factor|",)
	while hi <> null do
		mval = GetRecordValues("mtk + factor", hi, {"mtRthru", "mtk_FACTOR"})

		mtk = mval[1][2]
		factor = mval[2][2]

		SetRecordValues("mtk + factor",null,{{"eeM", (mtk*factor)}})

		hi = GetNextRecord("mtk + factor|", null,)
	end

	FM = OpenMatrix(Dir + "\\TD\\TDeeM.mtx", "True")

	viewset = tab + "|"
	update_flds = {tab+".eeM"}
	UpdateMatrixFromView(FM, viewset, "From", "To", null, update_flds, "Replace",
    	{{"Missing is zero", "Yes"}})

	FM = null
	tab = null
	viewset = null
	update_flds = null

	closeview("mtk + factor")

//_____HEAVVVEY_METAL_TRUCKS________

	opentable("htk", "FFA", {METDir + "\\ExtSta\\thrubase_htk.asc",})
	opentable("factor", "FFA", {Dir + "\\TG\\xxfactor.asc",})

	JoinViews("htk + factor", "htk.From", "factor.Station", )
	setview("htk + factor")
	ExportView("htk + factor|", "DBASE", Dir + "\\TG\\extfac_htk.dbf", {"From", "To", "Station", "htRthru", "[htk FACTOR]"},)

	closeview("htk")
	closeview("factor")
	closeview("htk + factor")
	opentable("htk + factor", "DBASE", {Dir + "\\TG\\extfac_htk.dbf",})
	setview("htk + factor")
	strct = GetTableStructure("htk + factor")
	for i = 1 to strct.length do
		// Copy the current name to the end of strct
		strct[i] = strct[i] + {strct[i][1]}
	end
	new_struct = strct + {{"eeH", "Real", 12, 4, "True",,,, null}}
		
	ModifyTable("htk + factor", new_struct)

	closeview("htk + factor")
	tab = opentable("htk + factor", "DBASE", {Dir + "\\TG\\extfac_htk.dbf",})

	setview("htk + factor")
	hi = GetFirstRecord("htk + factor|",)
	while hi <> null do
		mval = GetRecordValues("htk + factor", hi, {"htRthru", "htk_FACTOR"})

		htk = mval[1][2]
		factor = mval[2][2]

		SetRecordValues("htk + factor",null,{{"eeH", (htk*factor)}})

		hi = GetNextRecord("htk + factor|", null,)
	end

	FM = OpenMatrix(Dir + "\\TD\\TDeeH.mtx", "True")


	viewset = tab + "|"
	update_flds = {tab+".eeH"}
	UpdateMatrixFromView(FM, viewset, "From", "To", null, update_flds, "Replace",
    	{{"Missing is zero", "Yes"}})

	FM = null
	tab = null
	viewset = null
	update_flds = null

	closeview("htk + factor")

	RunMacro("G30 File Close All")

	quit:

	datentime = GetDateandTime()
	AppendToLogFile(1, "Exit EE_Trips: " + datentime)


	return({TripGenOK, msg})
endmacro
