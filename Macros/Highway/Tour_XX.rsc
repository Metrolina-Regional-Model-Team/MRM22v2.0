macro "Tour_XX" (Args)
//Run prior to Destination Choice,
// since the tour model uses XX trips to calculate XI tours for autos in that model
//Results for COM, MTK, HTK will be used in the Tour_Truck model
//Creates & fills EEA, EEC, EEM, & EEH matrices
// 1/17, mk: changed from .dbf to .bin

	on error goto badquit
	LogFile = Args.[Log File].value
	ReportFile = Args.[Report File].value
	SetLogFileName(LogFile)
	SetReportFileName(ReportFile)
	
	sedata_file = Args.[LandUse file].value
	Dir = Args.[Run Directory].value
	MetDir = Args.[MET Directory].value
	theyear = Args.[Run Year].value
	msg = null
	datentime = GetDateandTime()
	AppendToLogFile(1, "XX Tours: " + datentime)
	RunMacro("TCB Init")

	RunMacro("G30 File Close All") 

	DirArray  = Dir + "\\TG"
 	DirOutDC  = Dir + "\\TD"
 	
 	yr_str = Right(theyear,2)
	yr = s2i(yr_str)


/*EnableProgressBar("Trip Generation", 2)	// Double progress bar
CreateProgressBar("Calculating...", "True")
*/

//____CREATE EE MATRICES_______________________CHANGE SOURCE TO TEMPLATE_____________

OM = OpenMatrix(MetDir + "\\taz\\matrix_template.mtx", "False")
mc1 = CreateMatrixCurrency(OM, "Table", "Rows", "Columns", )

CopyMatrixStructure({mc1}, {{"File Name", Dir + "\\tg\\tdeea.mtx"},
    {"Label", "tdeea"},
    {"File Based", "No"},
    {"Tables", {"Trips"}},
    {"Operation", "Union"}})

CopyMatrixStructure({mc1}, {{"File Name", Dir + "\\tg\\tdeec.mtx"},
    {"Label", "tdeec"},
    {"File Based", "No"},
    {"Tables", {"Trips"}},
    {"Operation", "Union"}})

CopyMatrixStructure({mc1}, {{"File Name", Dir + "\\tg\\tdeem.mtx"},
    {"Label", "tdeem"},
    {"File Based", "No"},
    {"Tables", {"Trips"}},
    {"Operation", "Union"}})

CopyMatrixStructure({mc1}, {{"File Name", Dir + "\\tg\\tdeeh.mtx"},
    {"Label", "tdeeh"},
    {"File Based", "No"},
    {"Tables", {"Trips"}},
    {"Operation", "Union"}})


//______Open tables, etc______

	xvolbase_table = OpenTable("xvolbase_table", "FFA", {MetDir + "\\extsta\\extstavol18_base.asc",})
	extstavol_table = OpenTable("extstavol_table", "FFA", {Dir + "\\ext\\extstavol" + yr_str + ".asc",})
	vt_extstavol_ar = {"TOT_AUTO", "TOT_CV", "TOT_MT", "TOT_HT"}

	bvthru_table = OpenTable("bvthru_table", "FFA", {MetDir + "\\extsta\\bvthru.asc",})
	extsta_num = GetDataVector(bvthru_table+"|", "MODEL_STA", {{"Sort Order", {{"MODEL_STA","Ascending"}}}}) 
	vt_thru_ar = {"auto", "com", "mtk", "htk"}
	thrubase_ar = {"auto", "cv", "mt", "ht"}
	xx_field_ar = {"EEA", "EEC", "EEM", "EEH"} 
	mat_ar = {"tdeea", "tdeec", "tdeem", "tdeeh"}

	//create a temp file to store xxfactor before joining
	temp_tab = CreateTable("temp_tab", Dir + "\\ext\\temp_tab.bin", "FFB", {{"MODEL_STA", "Integer", 5, null, "Yes"}, {"xxfac", "Real", 10,8, "No"}})
	rh = AddRecords("temp_tab", null, null, {{"Empty Records", extsta_num.length}})
	SetDataVector(temp_tab+"|", "MODEL_STA", extsta_num,)

//_________loop on vehicle type______________

	for vt = 1 to 4 do
		baseXvol = GetDataVector(xvolbase_table+"|", vt_extstavol_ar[vt], {{"Sort Order", {{"MODEL_STA","Ascending"}}}}) 
		yrXvol = GetDataVector(extstavol_table+"|", vt_extstavol_ar[vt], {{"Sort Order", {{"MODEL_STA","Ascending"}}}}) 

		xxfactor = if(baseXvol > 0) then (yrXvol / baseXvol) else 0

		SetDataVector(temp_tab+"|", "xxfac", xxfactor,)

		//create and fill total thru-volume table
		bthruvol = GetDataVector(bvthru_table+"|", vt_thru_ar[vt], {{"Sort Order", {{"MODEL_STA","Ascending"}}}})
		if vt = 1 then do 
			CopyTableFiles("bvthru_table", null, null, null, Dir + "\\tg\\thruvol.asc", null)			
		end
		yrthruvol_table = OpenTable("yrthruvol_table", "FFA", {Dir + "\\tg\\thruvol.asc",})				

		yrthruvol = bthruvol * xxfactor
		SetDataVector(yrthruvol_table+"|", vt_thru_ar[vt], yrthruvol,)

		//create and fill thru-volume OD table
		thrubase_table = OpenTable("thrubase_table", "FFA", {MetDir + "\\extsta\\thrubase_" + vt_thru_ar[vt] + ".asc",})
		JoinViews("joined", "thrubase_table.From", "temp_tab.MODEL_STA", )
		setview("joined")
		ExportView("joined|", "FFB", Dir + "\\tg\\extfac_" + vt_thru_ar[vt] + ".bin", {"From", "To", thrubase_ar[vt] + "thru", "xxfac"},)

		closeview("joined")
		closeview("thrubase_table")
		closeview("yrthruvol_table")

		yrthruXX_table = OpenTable("yrthruXX_table", "FFB", {Dir + "\\tg\\extfac_" + vt_thru_ar[vt] + ".bin",})					

		strct = GetTableStructure("yrthruXX_table")
		for i = 1 to strct.length do
			strct[i] = strct[i] + {strct[i][1]}
		end
		strct = strct + {{xx_field_ar[vt], "Real", 10, 4, "True",,,, null}}
		strct = strct + {{xx_field_ar[vt] + "_INT", "Integer", 6,,,,,,,,,}}
		ModifyTable("yrthruXX_table", strct)

		xxfac_v = GetDataVector(yrthruXX_table+"|", "xxfac", {{"Sort Order", {{"From","Ascending"}, {"To","Ascending"}}}})
		thru_v = GetDataVector(yrthruXX_table+"|", thrubase_ar[vt] + "thru", {{"Sort Order", {{"From","Ascending"}, {"To","Ascending"}}}})  
	
		EE_v = xxfac_v * thru_v
		EE_int_v = floor(EE_v + 0.5)

		SetDataVector(yrthruXX_table+"|", xx_field_ar[vt], EE_v,{{"Sort Order", {{"From","Ascending"}, {"To","Ascending"}}}})
		SetDataVector(yrthruXX_table+"|", xx_field_ar[vt] + "_INT", EE_int_v,{{"Sort Order", {{"From","Ascending"}, {"To","Ascending"}}}})

		//fill matrices (the thru volumes are already OD, so don't need to transpose as if it were PA/AP)
		mat = OpenMatrix(Dir + "\\tg\\" + mat_ar[vt] + ".mtx", "False")			//open as memory-based

		UpdateMatrixFromView(mat, yrthruXX_table+"|", "From", "To", null, {xx_field_ar[vt] + "_INT"}, "Add", {{"Missing is zero", "Yes"}})	

		closeview("yrthruXX_table")
		mat = null
	end
    RunMacro("G30 File Close All")

    goto quit

	badquit:
		on error, notfound default
		RunMacro("TCB Closing", ret_value, "TRUE" )
		msg = msg + {"XX Tours: Error somewhere"}
		AppendToLogFile(1, "XX Tours: Error somewhere")
		datentime = GetDateandTime()
		AppendToLogFile(1, "XX Tours " + datentime)

       	return({0, msg})

    quit:
		on error, notfound default
   		datentime = GetDateandTime()
		AppendToLogFile(1, "Exit XX Tours " + datentime)
    	return({1, msg})


endmacro