Macro "Tour_Accessibility" (Args)

//Hwy accessibility includes intrazonal HHs, but Transit does not
// 3/21/18: fix to HHHwy15 and EmpT2Hwy

/*This macro only calculates accessibility required by the Tour model as described below.  The full macro is "Tour_Accessibility_full.rsc".  
	Composite time for all income groups is calculated and included in output matrix.
	
	- DC HBW, HBO, ATW, XIW, XIN: acc to employment within 15 min by composite time (all incomes)
  		(peak composite time for HBW, XIW, off-peak for HBO, ATW, XIN)

	- DC HBS: acc to HH within 15 min by off-peak composite time (all incomes)

	- SL models 2 and 4: acc to employment within 15 min by composite time (all incomes)
  		(peak composite time for model 2, off-peak for model 4)

	- SL model 5: acc to HH within 15 min by composite time (all incomes)
		(off-peak composite time)

	- ToD HBW, SCH, HBS, XIW: acc to HH within 15 min by composite time (all incomes)
  		(peak composite time for HBW, XIW, off-peak for SCH, HBS)

	- ToD ATW: acc to employment within 15 min by composite time (all incomes)
  		(off-peak)

*/
	on error goto badquit
	LogFile = Args.[Log File].value
	ReportFile = Args.[Report File].value
	SetLogFileName(LogFile)
	SetReportFileName(ReportFile)
	
	sedata_file = Args.[LandUse file].value
	Dir = Args.[Run Directory].value
	msg = null
	datentime = GetDateandTime()
	AppendToLogFile(1, "Enter Accessibility Calcs: " + datentime)
	RunMacro("TCB Init")

	RunMacro("G30 File Close All") 

	DirArray  = Dir + "\\TG"

	se_vw = OpenTable("SEFile", "dBASE", {sedata_file,})
	se_vectors = GetDataVectors(se_vw+"|", {"TAZ", "HH", "TOTEMP", "SEQ"},{{"Sort Order", {{"TAZ","Ascending"}}}})
	taz = se_vectors[1]
	hh = se_vectors[2]
	totemp = se_vectors[3]
	tazseq = se_vectors[4]
 

//**************** START OF ACCESSIBILITY CALCULATIONS ****************************************************

//Open skims
	autopk = OpenMatrix(Dir + "\\Skims\\TThwy_peak.mtx", "False")			//open as memory-based
	int_index = CreateMatrixIndex("Internals", autopk, "Both", se_vw+"|", "TAZ", "TAZ" )	//just internal zones
	autopkintcur = CreateMatrixCurrency(autopk, "TotalTT", "Internals", "Internals", )
	autopkcur = CreateMatrixCurrency(autopk, "TotalTT", "Rows", "Columns", )
	autofree = OpenMatrix(Dir + "\\Skims\\TThwy_free.mtx", "False")			//open as memory-based
	autofreecur = CreateMatrixCurrency(autofree, "TotalTT", "Rows", "Columns", )
	int_index = CreateMatrixIndex("Internals", autofree, "Both", se_vw+"|", "TAZ", "TAZ" )	//just internal zones
	autofreeintcur = CreateMatrixCurrency(autofree, "TotalTT", "Internals", "Internals", )
	tranpk_orig = OpenMatrix(Dir + "\\Skims\\TR_SKIM_pbusd.mtx", "False")			//open as memory-based
	trpkcur_orig = CreateMatrixCurrency(tranpk_orig, "Generalized Cost", "RCIndex", "RCIndex", )
	tranpk = CopyMatrix(trpkcur_orig, {{"File Name", Dir + "\\Skims\\transkimpk.mtx"}, {"Label", "Skim Matrix"}, {"Compression", 0}, {"Table", "Generalized Cost"}, {"File Based", "No"}})
	trpkcur = CreateMatrixCurrency(tranpk, "Generalized Cost", "RCIndex", "RCIndex", )
	tranfree_orig = OpenMatrix(Dir + "\\Skims\\TR_SKIM_opbusd.mtx", "False")			//open as memory-based
	trfreecur_orig = CreateMatrixCurrency(tranfree_orig, "Generalized Cost", "RCIndex", "RCIndex", )
	tranfree = CopyMatrix(trfreecur_orig, {{"File Name", Dir + "\\Skims\\transkimfree.mtx"}, {"Label", "Skim Matrix"}, {"Compression", 0}, {"Table", "Generalized Cost"}, {"File Based", "No"}})
	trfreecur = CreateMatrixCurrency(tranfree, "Generalized Cost", "RCIndex", "RCIndex", )

	tranpk_orig = null
	tranfree_orig = null

//Compute composite time (transit coefficients for each Income group: 1=0.15, 2=0.05, 3=0.05, 4=0.01, all=0.03) 
//Matrix needs to include all internal and external zones (so uses autofreecur currency to create new matrix)
	comp_cores = {"comphwypk", "comphwyfr", "comptrpk", "comptrpk1", "comptrpk23", "comptrpk4", "comptrfr", "comptrfr1", "comptrfr23", "comptrfr4", 
			"comppeak", "comppeak1", "comppeak23", "comppeak4", "compfree", "compfree1", "compfree23", "compfree4"}
	CopyMatrixStructure({autofreecur}, {{"File Name", Dir + "\\tg\\composite.mtx"}, 
			{"Label", "Composite Time"},
			{"File Based", "No"},
			{"Tables", comp_cores},
			})
	comp_mat = OpenMatrix(Dir + "\\tg\\composite.mtx", "False")
	comp_array = CreateMatrixCurrencies(comp_mat, , , )
	comphwypk = comp_array.(comp_cores[1])
	comphwypk := 1 / autopkcur
	comphwyfr = comp_array.(comp_cores[2])
	comphwyfr := 1 / autofreecur
	comptrpk = comp_array.(comp_cores[3])
	comptrpk := if (trpkcur = null) then 0 else 0.03 / trpkcur
	comptrpk1 = comp_array.(comp_cores[4])
	comptrpk1 := if (trpkcur = null) then 0 else 0.15 / trpkcur
	comptrpk23 = comp_array.(comp_cores[5])
	comptrpk23 := if (trpkcur = null) then 0 else 0.05 / trpkcur
	comptrpk4 = comp_array.(comp_cores[6])
	comptrpk4 := if (trpkcur = null) then 0 else 0.01 / trpkcur
	comptrfr = comp_array.(comp_cores[7])
	comptrfr := if (trfreecur = null) then 0 else 0.03 / trfreecur
	comptrfr1 = comp_array.(comp_cores[8])
	comptrfr1 := if (trfreecur = null) then 0 else 0.15 / trfreecur
	comptrfr23 = comp_array.(comp_cores[9])
	comptrfr23 := if (trfreecur = null) then 0 else 0.05 / trfreecur
	comptrfr4 = comp_array.(comp_cores[10])
	comptrfr4 := if (trfreecur = null) then 0 else 0.01 / trfreecur
	comppeak = comp_array.(comp_cores[11])
	comppeak := 1 / (comphwypk + comptrpk)
	comppeak1 = comp_array.(comp_cores[12])
	comppeak1 := 1 / (comphwypk + comptrpk1)
	comppeak23 = comp_array.(comp_cores[13])
	comppeak23 := 1 / (comphwypk + comptrpk23)
	comppeak4 = comp_array.(comp_cores[14])
	comppeak4 := 1 / (comphwypk + comptrpk4)
	compfree = comp_array.(comp_cores[15])
	compfree := 1 / (comphwyfr + comptrfr)
	compfree1 = comp_array.(comp_cores[16])
	compfree1 := 1 / (comphwyfr + comptrfr1)
	compfree23 = comp_array.(comp_cores[17])
	compfree23 := 1 / (comphwyfr + comptrfr23)
	compfree4 = comp_array.(comp_cores[18])
	compfree4 := 1 / (comphwyfr + comptrfr4)

//Create blank matrix with required cores

	//These are all the accessibility calculations for sample accessibility factors, not all of which are currently used
	/*	mat_cores = {"HHHwy15", "HHTr15", "HHCmp15", "HHHwy45", "HHTr45", "HHCmp45", "EmpHwy15", "EmpTr15", "EmpCmp15", "EmpHwy45", "EmpTr45", "EmpCmp45", 
			"HHT2Hwy", "HHT2Tr", "HHT2Cmp", "EmpT2Hwy", "EmpT2Tr", "EmpT2Cmp", "HHT3Hwy", "HHT3Tr", "HHT3Cmp", "EmpT3Hwy", "EmpT3Tr", "EmpT3Cmp", 
			"HHT2HwyI1", "HHT2TrI1", "HHT2CmpI1", "HHT2HwyI4", "HHT2TrI4", "HHT2CmpI4", "HHHwy30", "EmpHwy30"} 
	*/
	//Below are just the ones that are currently used in all the Tour models.  Note that the composite times are subdivided by income (Truck model uses EmpHwy30)
//	mat_cores = {"HHCmp15",	"EmpCmp15", "EmpT2Hwy", "EmpT2Cmp", "EmpHwy30"} 

	//create new matrix to do calcs.  Accessibility is just for internal zones, so first create an internal zone index to copy from
	//Composite time internal indices for compfree and comppeak will also be used in Accessibility equations below
	int_index = CreateMatrixIndex("Internals", comp_mat, "Both", se_vw+"|", "TAZ", "TAZ" )	//just internal zones
	comppeakintcur = CreateMatrixCurrency(comp_mat, "comppeak", "Internals", "Internals", )
	compfreeintcur = CreateMatrixCurrency(comp_mat, "compfree", "Internals", "Internals", )
	CopyMatrixStructure({compfreeintcur}, {{"File Name", Dir + "\\tg\\tour_access_calc.mtx"}, 
			{"Label", "Tour Accessibility"},
			{"File Based", "No"},
			{"Tables", {"FillCore"}}})

//Create three tables for results (need external zones for Truck model only)
	access_peak = CreateTable("access_peak", DirArray + "\\access_peak.bin", "FFB", {{"TAZ", "Integer", 5,,"Yes"},{"SEQ", "Integer", 5,,"Yes"},
				{"HHCmp15", "Integer", 8,,"No"}, {"EmpCmp15", "Integer", 8,,"No"}, {"EmpT2Cmp", "Real", 7,2,"No"} })					  	   

	access_free = CreateTable("access_free", DirArray + "\\access_free.bin", "FFB", {{"TAZ", "Integer", 5,,"Yes"},{"SEQ", "Integer", 5,,"Yes"},{"HHHwy15", "Integer", 8,,"No"}, 
				{"HHCmp15", "Integer", 8,,"No"}, {"EmpCmp15", "Integer", 8,,"No"}, {"EmpHwy30", "Integer", 8,,"No"}, {"EmpT2Cmp", "Real", 7,2,"No"} , {"EmpT2Hwy", "Real", 7,2,"No"} })					  	   

	access_free_withEXT = CreateTable("access_free_withEXT", DirArray + "\\access_free_withEXT.bin", "FFB", {{"TAZ", "Integer", 5,,"Yes"},{"SEQ", "Integer", 5,,"Yes"},
				{"EmpHwy30", "Integer", 8,,"No"} })					  	   

	addrec = AddRecords("access_peak", null, null, {{"Empty Records", taz.length}})
	addrec = AddRecords("access_free", null, null, {{"Empty Records", taz.length}})
	matl = GetMatrixVector(comphwypk, {{"Index", "Row"}})
	addrec2 = AddRecords("access_free_withEXT", null, null, {{"Empty Records", matl.length}})
	SetDataVectors(access_peak+"|", {{"TAZ", taz},{"SEQ", tazseq}},)
	SetDataVectors(access_free+"|", {{"TAZ", taz},{"SEQ", tazseq}},)
	SetDataVector(access_free_withEXT+"|", "TAZ", matl,)

//Open matrix for filling, also calc length so can add records to Inc arrays	
	matcalcs = OpenMatrix(Dir + "\\tg\\tour_access_calc.mtx", "False")

//Fill matrix core and accessibility table with zonal total HHs by income group (transit neglects intrazonal trips for now)
	//HHs within 15 min by composite time (HHCmp15)
		//peak first
		fillmat = CreateMatrixCurrency(matcalcs, "FillCore", "Rows", "Columns", )
		fillmat := if (comppeakintcur = null) then 0 else if (comppeakintcur < 15) then 1 else 0	
		fillmat := fillmat * hh
		matsum = GetMatrixVector(fillmat, {{"Marginal","Row Sum"}})
		SetDataVector(access_peak+"|","HHCmp15", matsum,)
		//next offpeak
		fillmat = CreateMatrixCurrency(matcalcs, "FillCore", "Rows", "Columns", )
		fillmat := if (compfreeintcur = null) then 0 else if (compfreeintcur < 15) then 1 else 0	
		fillmat := fillmat * hh
		matsum = GetMatrixVector(fillmat, {{"Marginal","Row Sum"}})
		SetDataVector(access_free+"|","HHCmp15", matsum,)

	//Employment within 15 min by composite time (EmpCmp15)
		//peak first
		fillmat = CreateMatrixCurrency(matcalcs, "FillCore", "Rows", "Columns", )
		fillmat := if (comppeakintcur = null) then 0 else if (comppeakintcur < 15) then 1 else 0	
		fillmat := fillmat * totemp
		matsum = GetMatrixVector(fillmat, {{"Marginal","Row Sum"}})
		SetDataVector(access_peak+"|","EmpCmp15", matsum,)
		//next offpeak
		fillmat = CreateMatrixCurrency(matcalcs, "FillCore", "Rows", "Columns", )
		fillmat := if (compfreeintcur = null) then 0 else if (compfreeintcur < 15) then 1 else 0	
		fillmat := fillmat * totemp
		matsum = GetMatrixVector(fillmat, {{"Marginal","Row Sum"}})
		SetDataVector(access_free+"|","EmpCmp15", matsum,)

	//Employment within 30 min by highway time (EmpHwy30)	(for Truck Model, offpeak only, need for both without and with external stations)
		//first without external stations
		fillmat = CreateMatrixCurrency(matcalcs, "FillCore", "Rows", "Columns", )
		fillmat := if (autofreeintcur = null) then 0 else if (autofreeintcur < 30) then 1 else 0	
		fillmat := fillmat * totemp
		matsum = GetMatrixVector(fillmat, {{"Marginal","Row Sum"}})
		SetDataVector(access_free+"|","EmpHwy30", matsum,)
	 	//next with extsta (have to add external station records to totemp vector)
	  	 emp_v = Vector(matl.length, "short", {{"Constant", 0}})	//matl includes external stations	
	   	for i = 1 to totemp.length do
	      		emp_v[i] = totemp[i]
	   	end   
		AddMatrixCore(comp_mat, "temp")
		fillmat = CreateMatrixCurrency(comp_mat, "temp", "Rows", "Columns", )
		fillmat := if (autofreecur = null) then 0 else if (autofreecur < 30) then 1 else 0	
		fillmat := fillmat * emp_v
		matsum = GetMatrixVector(fillmat, {{"Marginal","Row Sum"}})
		SetDataVector(access_free_withEXT+"|","EmpHwy30", matsum,)
		SetMatrixCore(comp_mat, "compfree")
		DropMatrixCore(comp_mat, "temp")

	//HHs within 15 min by highway time (HHHwy15)	(for Truck Model, offpeak only, does not include external stations)
		fillmat = CreateMatrixCurrency(matcalcs, "FillCore", "Rows", "Columns", )
		fillmat := if (autofreeintcur = null) then 0 else if (autofreeintcur <= 15) then 1 else 0	
		fillmat := fillmat * hh
		matsum = GetMatrixVector(fillmat, {{"Marginal","Row Sum"}})
		SetDataVector(access_free+"|","HHHwy15", matsum,)


	//EMPT2Cmp
		//peak first
		AddMatrixCore(comp_mat, "temp")
		tempfill = CreateMatrixCurrency(comp_mat, "temp", "Internals", "Internals", )
		MultiplyMatrixElements(tempfill, "comppeak", "comppeak", , , {{"Force Missing", "Yes"}})
		fillmat = CreateMatrixCurrency(matcalcs, "FillCore", "Rows", "Columns", )
		fillmat := if (tempfill = null) then 0 else tempfill
		fillmat := totemp / fillmat
		matsum = GetMatrixVector(fillmat, {{"Marginal","Row Sum"}})
		SetDataVector(access_peak+"|","EMPT2Cmp", matsum,)
		//next offpeak
		MultiplyMatrixElements(tempfill, "compfree", "compfree", , , {{"Force Missing", "Yes"}})
		fillmat := if (tempfill = null) then 0 else tempfill
		fillmat := totemp / fillmat
		matsum = GetMatrixVector(fillmat, {{"Marginal","Row Sum"}})
		SetDataVector(access_free+"|","EMPT2Cmp", matsum,)
		SetMatrixCore(comp_mat, "compfree")
		DropMatrixCore(comp_mat, "temp")

	//EmpT2Hwy (for Truck model only, without extsta)
		AddMatrixCore(autofree, "temp")
		tempfill = CreateMatrixCurrency(autofree, "temp", "Internals", "Internals", )
		MultiplyMatrixElements(tempfill, "TotalTT", "TotalTT", , , {{"Force Missing", "Yes"}})
		fillmat = CreateMatrixCurrency(matcalcs, "FillCore", "Rows", "Columns", )
		fillmat := if (tempfill = null) then 0 else tempfill
		fillmat := totemp / fillmat
		matsum = GetMatrixVector(fillmat, {{"Marginal","Row Sum"}})
		SetDataVector(access_free+"|","EmpT2Hwy", matsum,)
		SetMatrixCore(autofree, "TotalTT")
		DropMatrixCore(autofree, "temp")


	//remove internal zone indices from skims
	SetMatrixIndex(autopk, "Rows", "Columns")
	DeleteMatrixIndex(autopk, "Internals")
	SetMatrixIndex(autofree, "Rows", "Columns")
	DeleteMatrixIndex(autofree, "Internals")
	

//**************** END OF ACCESSIBILITY CALCULATIONS ****************************************************								
skiparound:

goto skiptoend

//skip below, done in ExtStaCBD.rsc macro

//**************** Calculate distance to CBD (TAZ 10002) & nearest external station *********************

	dist_mat = OpenMatrix(Dir + "\\AutoSkims\\SPMAT_auto.mtx", "False")
	dist_cur = CreateMatrixCurrency(dist_mat, "Non HOV Length", "Rows", "Columns", )

	taz_id = GetMatrixIndexIDs(dist_mat, "Columns")
	taz_v = a2v(taz_id)
	cbd_v = GetMatrixVector(dist_cur, {{"Column", 10002}})
 
//Add new core and fill with values from distance matrix
	AddMatrixCore(dist_mat, "temp")
	tempfill = CreateMatrixCurrency(dist_mat, "temp", "Rows", "Columns", )
	MergeMatrixElements(tempfill, {dist_cur}, , ,)

//Create new indices 
	qry_external = "Select * where TAZ > 11999"
	qry_internal = "Select * where TAZ < 12000"
	SetView(access_peak)
	set_ext = SelectByQuery("Extsta", "Several", qry_external,)
	View_set_ext = access_peak + "|Extsta"
	set_int = SelectByQuery("Internal", "Several", qry_internal,)
	View_set_int = access_peak + "|Internal"

//Pull out distance to cbd vector (no externals)
	cbd_index = CreateMatrixIndex("Internal_index", dist_mat, "Rows", View_set_int, "TAZ", "TAZ")
	cbd_cur = CreateMatrixCurrency(dist_mat, "temp", "Internal_index", "Columns", )
	cbd_v = GetMatrixVector(cbd_cur, {{"Column", 10002}})

//Calc min distance to extsta and pull out marginal vector
	exsta_index = CreateMatrixIndex("Extsta_index", dist_mat, "Columns", View_set_ext, "TAZ", "TAZ")
	exsta_cur = CreateMatrixCurrency(dist_mat, "temp", "Internal_index", "Extsta_index", )
	extsta_v = GetMatrixVector(exsta_cur, {{"Marginal", "Row Minimum"}})

//Drop indices and calc core
	SetMatrixIndex(dist_mat, "Rows", "Columns")
	DeleteMatrixIndex(dist_mat, "Extsta_index")
	DeleteMatrixIndex(dist_mat, "Internal_index")
	SetMatrixCore(dist_mat, "Non HOV Length")
	DropMatrixCore(dist_mat, "temp")

//Create & fill table
	dist_tab = CreateTable("dist_tab", DirArray + "\\Dist_to.bin", "FFB", {{"TAZ", "Integer", 5,,"Yes"}, {"Dst2CBD", "Real", 12,4,"No"}, {"Dst2EXTSTA", "Real", 12,4,"No"}})
	addrec = AddRecords("dist_tab", null, null, {{"Empty Records", hh.length}})
	SetDataVector(dist_tab+"|", "TAZ", taz,)
	SetDataVector(dist_tab+"|", "Dst2CBD", cbd_v,)
	SetDataVector(dist_tab+"|", "Dst2EXTSTA", extsta_v,)

skiptoend:
    RunMacro("G30 File Close All")

    goto quit
	badquit:
		on error, notfound default
		RunMacro("TCB Closing", ret_value, "TRUE" )
		msg = msg + {"Accessibility Calcs: Error somewhere"}
		AppendToLogFile(1, "Accessibility Calcs: Error somewhere")
		datentime = GetDateandTime()
		AppendToLogFile(1, "Exit Accessibility Calcs " + datentime)

       	return({0, msg})

    quit:
		on error, notfound default
   		datentime = GetDateandTime()
		AppendToLogFile(1, "Exit Accessibility Calcs " + datentime)
    	return({1, msg})
		

endmacro