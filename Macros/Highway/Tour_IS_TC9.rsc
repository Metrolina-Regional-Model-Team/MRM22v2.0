Macro "Tour_IS" (Args)

// 1/17, mk: changed from .dbf to .bin 
// 7/18, mk: changed coefficients for HBS, EXT (ATW matched) per BA's 7/6/18 email
// 7/23, mk: fixed HBS_tours and ATW_tours variables per BA's 7/23/18 email
// 2/25/19, mk: HBO, XIN and XIW coeffs per Bill's 2/25/19 email
// 5/30/19, mk: There are now three distinct networks; can use offpeak here (doesn't really matter, just uses to get distances)
// 7/20/20, mk: fixed accessibility variables (was short, which caused null values for dense area; changed to float)

	on error goto badquit
	LogFile = Args.[Log File].value
	ReportFile = Args.[Report File].value
	SetLogFileName(LogFile)
	SetReportFileName(ReportFile)
	
	sedata_file = Args.[LandUse file].value
	Dir = Args.[Run Directory].value
	theyear = Args.[Run Year].value
	net_file = Args.[Offpeak Hwy Name].value
	msg = null
	datentime = GetDateandTime()
	AppendToLogFile(1, "Tour Intermediate Stops: " + datentime)
	RunMacro("TCB Init")

	RunMacro("G30 File Close All") 

	DirArray  = Dir + "\\TG"
 	DirOutDC  = Dir + "\\TD"
	
 	yr_str = Right(theyear,2)
	yr = s2i(yr_str)

//Output zone distance matrix (below will do distance matrix for external stations)

     Opts = null
     Opts.Input.[Origin Set] = {Dir + "\\" + net_file + ".dbd|Node", "Node", "Cent","Select * where Centroid = 1"}
     Opts.Input.[Destination Set] = {Dir + "\\" + net_file + ".dbd|Node", "Node", "Cent","Select * where Centroid = 1"}
     Opts.Global.[Map Unit Label] = "Miles"
     Opts.Global.[Map Unit Size] = 1
     Opts.Output.[Output Matrix].Label = "Output Matrix"
     Opts.Output.[Output Matrix].Compression = 0				//Choose no compression so can open as memory-based
     Opts.Output.[Output Matrix].[File Name] = DirOutDC + "\\zonedist.mtx"
     ret_value = RunMacro("TCB Run Procedure", "EUCMat", Opts, &Ret)

  CreateProgressBar("Tour Intermediate Stop Model...Opening files", "TRUE")

//open node layer to get centroid and external station coordinates
	info = GetDBInfo(Dir + "\\" + net_file + ".dbd")
	scope = info[1]
	layers = GetDBLayers(Dir + "\\" + net_file + ".dbd")
	CreateMap(layers[1], {{"Scope", scope},{"Auto Project", "True"}})
	AddLayer(layers[1], layers[1], Dir + "\\" + net_file + ".dbd", layers[1])
	SetIcon(layers[1]+"|", "Font Character", "Caliper Cartographic|2", 36)
	SetLayerVisibility(layers[1], "True")
	centview = GetLayers()
	SetLayer(centview[1][1])
	qry = "Select * where Centroid = 1"
	SelectByQuery("Centroids", "Several", qry,)
	SortSet("Centroids", "ID")
	ExportView(layers[1] + "|Centroids", "DBASE", DirOutDC + "\\centroids.dbf", {"ID", "Longitude", "Latitude"}, {{"Indexed Fields", {"ID"}}})
	qry2 = "Select * where Centroid = 2"
	SelectByQuery("extsta", "Several", qry2,)
	SortSet("extsta", "ID")
	ExportView(layers[1] + "|extsta", "DBASE", DirOutDC + "\\extsta_coord.dbf", {"ID", "Longitude", "Latitude"}, {{"Indexed Fields", {"ID"}}})
maps = GetMapNames()
for i = 1 to maps.length do
     CloseMap(maps[i])
end

	se_vw = OpenTable("SEFile", "dBASE", {sedata_file,})
//	access_peak = OpenTable("access_peak", "FFB", {DirArray + "\\ACCESS_PEAK.bin",})
//	access_free = OpenTable("access_free", "FFB", {DirArray + "\\ACCESS_FREE.bin",})
	areatype = OpenTable("areatype", "DBASE", {Dir + "\\landuse\\SE" + theyear + "_DENSITY.dbf",})  

	se_vectors = GetDataVectors(se_vw+"|", {"TAZ", "HH", "POP_HHS", "LOIND", "HIIND", "RTL", "HWY", "LOSVC", "HISVC", "OFFGOV", 
						"EDUC", "STU_K8", "STU_HS", "STU_CU", "MED_INC", "AREA", "TOTEMP", "STCNTY", "SEQ", "POP"},{{"Sort Order", {{"TAZ","Ascending"}}}})
	taz = se_vectors[1]
	hh = se_vectors[2]
	pophhs = se_vectors[3]
	pop = se_vectors[20]
	loind = se_vectors[4]
	hiind = se_vectors[5]
	rtl = se_vectors[6]
	hwy = se_vectors[7]
	losvc = se_vectors[8]
	hisvc = se_vectors[9]
	offgov = se_vectors[10]
	educ = se_vectors[11]
	stuk8 = se_vectors[12]
	stuhs = se_vectors[13]
	stucu = se_vectors[14]
	medinc = se_vectors[15]
	area = se_vectors[16]
	totemp = se_vectors[17]
	stcnty = se_vectors[18]
	tazseq = se_vectors[19]
	retail = rtl + hwy
	k12enr = stuk8 + stuhs
//	ddensp = (800 * pophhs + 300 * totemp) / ( area * 640)		//area is in acres
	ddensp = (800 * pop + 300 * totemp) / ( area * 640)		//area is in acres
	cbddum = if (taz = 10001 or taz = 10002 or taz = 10003 or taz = 10004 or taz = 10005 or taz = 10006 or taz = 10007 or taz = 10008 or taz = 10009 or 
			taz = 10010 or taz = 10011 or taz = 10012 or taz = 10013 or taz = 10014 or taz = 10015 or taz = 10016 or taz = 10017 or taz = 10018 or taz = 10019 or 
			taz = 10020 or taz = 10021 or taz = 10022 or taz = 10023 or taz = 10024 or taz = 10025 or taz = 10026 or taz = 10027 or taz = 10028 or taz = 10029 or
			taz = 10030 or taz = 10031 or taz = 10032 or taz = 10033 or taz = 10034 or taz = 10035 or 
			taz = 10052 or taz = 10086 or taz = 10116 or taz = 10117 or taz = 10118 or taz = 10119 or  
			taz = 10144 or taz = 10145 or taz = 10146 or taz = 10160 or taz = 10161 or taz = 10164 or taz = 10165 or taz = 10235) then 1 else 0

	atype = GetDataVector(areatype+"|", "AREATYPE", {{"Sort Order", {{"TAZ","Ascending"}}}}) 
	atype1dum = if (atype = 1) then 1 else 0
	atype5dum = if (atype = 5) then 1 else 0
	rural = if (atype = 5) then 1 else 0

	autofree = OpenMatrix(Dir + "\\Skims\\TThwy_free.mtx", "False")			//open as memory-based
	autofreecur = CreateMatrixCurrency(autofree, "TotalTT", "Rows", "Columns", )

	zonedist_m = OpenMatrix(DirOutDC + "\\zonedist.mtx", "False")	
	zonedist_mc = CreateMatrixCurrency(zonedist_m, "Miles", "Origin-Destination", "Origin-Destination", )	
	ret30_m = CreateMatrix({se_vw+"|", "TAZ","Row Index"}, {se_vw+"|", "TAZ","Column Index"},
					{{"File Name", DirOutDC + "\\ret30.mtx"}, {"Label", "retail emp within 3 miles"},{"Type", "Long"}, {"Tables", {"ret30"}}})	//,{"File Based", "No"}
	ret30_mc = CreateMatrixCurrency(ret30_m, "ret30", "Row Index", "Column Index", )

	influence_area = 3		//influence area for production/attractions zones is 3 miles; do for production (Row) and attraction (Column) zones.
	ret30_mc := if (zonedist_mc > influence_area) then 0 else (retail)	//zeros out zones that are outside the influence area (3 miles); retail + hwy employment within the influence area of each zone
//	ind30_mc := if (zonedist_mc > influence_area) then 0 else (loind + hiind)	//zeros out zones that are outside the influence area (3 miles); retail + hwy employment within the influence area of each zone
  
 	ret30_ar = GetMatrixMarginals(ret30_mc, "Sum", "row")
	ret30 = a2v(ret30_ar)							//this is total retail within each zone's influence area
 
	tour_files = {"hbwdestii", "schdestii", "hbudestii", "hbsdestii", "hbodestii", "atwdestii", "extdest", "xiw", "xin"}


//************************** HBW INTERMEDIATE STOP MODEL **************************************************************************************************
  UpdateProgressBar("Intermediate Stop Model: HBW", 10) 

//Add new IS field to tour records file  
	hbwdestii = OpenTable("hbwdestii", "FFB", {DirOutDC + "\\dcHBW.bin",})
	strct = GetTableStructure(tour_files[1])					
	for j = 1 to strct.length do
 		strct[j] = strct[j] + {strct[j][1]}
 	end
	strct = strct + {{"IS_PA", "Integer", 2,,,,,,,,,}}
	strct = strct + {{"IS_AP", "Integer", 2,,,,,,,,,}}
	ModifyTable(tour_files[1], strct)

	tour_vectors = GetDataVectors(tour_files[1]+"|", {"ID", "TAZ", "TAZ_SEQ", "SIZE", "INCOME", "LIFE", "WRKRS", "SCH", "HBU", "HBW", "HBS", 
						"HBO", "ATW", "HHID", "ORIG_TAZ", "ORIG_SEQ", "DEST_TAZ", "DEST_SEQ", "PURP"},{{"Sort Order", {{"ID","Ascending"}}}})
	tourtaz = tour_vectors[2]
	tourincome = tour_vectors[5]
	tourlc = tour_vectors[6]
	hbwtours = tour_vectors[10]
	tourorigtaz = tour_vectors[15]
	tourorigtazseq = tour_vectors[16]
	tourdesttaz = tour_vectors[17]
	tourdesttazseq = tour_vectors[18]
	tourinc4dum = if (tourincome = 4) then 1 else 0
	tourlc2dum = if (tourlc = 2) then 1 else 0

	choice_v = Vector(tourtaz.length, "short", {{"Constant", 0}}) 
	ret30_orig = Vector(tourtaz.length, "float", ) 
	ret30_dest = Vector(tourtaz.length, "float", ) 
	AT_dest = Vector(tourtaz.length, "short", ) 
	at1dumP = Vector(tourtaz.length, "short", ) 
	rand_v1 = Vector(tourtaz.length, "float", ) 	//for PA, 0-1+ tour selection
	rand_v2 = Vector(tourtaz.length, "float", ) 	//for PA, 2-5 tour selection
	rand_v3 = Vector(tourtaz.length, "float", ) 	//for AP, 0-1+ tour selection
	rand_v4 = Vector(tourtaz.length, "float", ) 	//for AP, 2-7 tour selection

//Loop to get retail employment within 30 minutes of origin & destination zones. Also, fill in random number vectors for probability
SetRandomSeed(454)
	for n = 1 to tourtaz.length do			//tourtaz.length	
		otazseq = tourorigtazseq[n]
		dtazseq = tourdesttazseq[n]
		ret30_orig[n] = ret30[otazseq]
		ret30_dest[n] = ret30[dtazseq]
		AT_dest[n] = atype[dtazseq]
		at1dumP[n] = atype1dum[otazseq]
		rand_val = RandomNumber()
		rand_v1[n] = rand_val
		rand_val = RandomNumber()
		rand_v2[n] = rand_val
		rand_val = RandomNumber()
		rand_v3[n] = rand_val
		rand_val = RandomNumber()
		rand_v4[n] = rand_val
	end

//Apply the PA model
	U1 = -1.182  + 0.2392 * tourinc4dum + 0.9609 * tourlc2dum + 0.00004341 * ret30_orig + 0.00001594 * ret30_dest - 0.2817 * hbwtours - 0.5 * AT_dest
	U2 = -2.552  + 0.2392 * tourinc4dum + 0.9609 * tourlc2dum + 0.00004341 * ret30_orig + 0.00001594 * ret30_dest - 0.3017 * hbwtours - 0.5 * AT_dest

	E2U0 = 1
	E2U1 = exp(U1)				
	E2U2 = exp(U2)				//Initial alternatives are 0, 1 & 2+ HBW Intermediate stops
	E2U_cum = E2U0 + E2U1+ E2U2

	prob0 = E2U0 / E2U_cum
	prob1 = E2U1 / E2U_cum
	prob2 = E2U2 / E2U_cum
	prob1c = prob0 + prob1
	prob2c = prob1c + prob2

//The 2+ categories are 2 (66.0% of all 2+ is), 3 (20.0%), 4 (8.0%) & 5 (6.0%)
	choice_v = if (rand_v1 < prob0) then 0 else if (rand_v1 < prob1c) then 1 else if (rand_v2 < 0.660) then 2 else if (rand_v2 < 0.860) then 3 else if (rand_v2 < 0.940) then 4 else 5
	SetDataVector(tour_files[1]+"|", "IS_PA", choice_v,)

//Repeat above logic for AP direction
	U1 = -2.114  + 0.4851 * choice_v + 0.3553 * tourinc4dum + 0.00003103 * ret30_orig + 1.0 * at1dumP
	U2 = -2.744  + 0.4851 * choice_v + 0.3553 * tourinc4dum + 0.00003103 * ret30_orig + 1.0 * at1dumP

	E2U0 = 1
	E2U1 = exp(U1)				
	E2U2 = exp(U2)				//Initial alternatives are 0, 1 & 2+ HBW Intermediate stops
	E2U_cum = E2U0 + E2U1+ E2U2

	prob0 = E2U0 / E2U_cum
	prob1 = E2U1 / E2U_cum
	prob2 = E2U2 / E2U_cum
	prob1c = prob0 + prob1
	prob2c = prob1c + prob2

//The 2+ categories are 2 (70.5% of all 2+ is), 3 (19.1%), 4 (4.8%), 5 (3.4%), 6 (1.1%) & 7 (1.1%)
	choice_v = if (rand_v3 < prob0) then 0 else if (rand_v3 < prob1c) then 1 else if (rand_v4 < 0.705) then 2 else if (rand_v4 < 0.896) then 3 else if (rand_v4 < 0.944) then 4 else if (rand_v4 < 0.978) then 5 else if (rand_v4 < 0.989) then 6 else 7
	SetDataVector(tour_files[1]+"|", "IS_AP", choice_v,)
	CloseView(tour_files[1])	

//************************** SCHOOL INTERMEDIATE STOP MODEL **************************************************************************************************
  UpdateProgressBar("Intermediate Stop Model: School", 10) 

//Add new IS field to tour records file  
	schdestii = OpenTable("schdestii", "FFB", {DirOutDC + "\\dcSCH.bin",})
	strct = GetTableStructure(tour_files[2])					
	for j = 1 to strct.length do
 		strct[j] = strct[j] + {strct[j][1]}
 	end
	strct = strct + {{"IS_PA", "Integer", 2,,,,,,,,,}}
	strct = strct + {{"IS_AP", "Integer", 2,,,,,,,,,}}
	ModifyTable(tour_files[2], strct)
	tour_vectors = GetDataVectors(tour_files[2]+"|", {"ID", "TAZ", "TAZ_SEQ", "SIZE", "INCOME", "LIFE", "WRKRS", "SCH", "HBU", "HBW", "HBS", 
						"HBO", "ATW", "HHID", "ORIG_TAZ", "ORIG_SEQ", "DEST_TAZ", "DEST_SEQ", "PURP"},{{"Sort Order", {{"ID","Ascending"}}}})
	tourtaz = tour_vectors[2]
	toursize = tour_vectors[4]
//	tourincome = tour_vectors[5]
//	tourlc = tour_vectors[6]
	hbwtours = tour_vectors[10]
	schtours = tour_vectors[8]
	hbutours = tour_vectors[9]
	hbstours = tour_vectors[11]
	hbotours = tour_vectors[12]
	tourorigtaz = tour_vectors[15]
	tourorigtazseq = tour_vectors[16]
	tourdesttaz = tour_vectors[17]
	tourdesttazseq = tour_vectors[18]
	tours = hbwtours + schtours + hbutours + hbstours + hbotours	//TOURS = all tours (HBW+SCH+HBU+HBS+HBO)
//	tourlc2dum = if (tourlc = 2) then 1 else 0

	choice_v = Vector(tourtaz.length, "short", {{"Constant", 0}}) 
	cbddum_dest = Vector(tourtaz.length, "short", ) 
	ret30_orig = Vector(tourtaz.length, "float", ) 
	rural_dest = Vector(tourtaz.length, "short", ) 
	htime = Vector(tourtaz.length, "float", ) 
	atype_orig = Vector(tourtaz.length, "short", ) 
	rand_v1 = Vector(tourtaz.length, "float", ) 	//for PA, 0-1+ tour selection
	rand_v2 = Vector(tourtaz.length, "float", ) 	//for PA, 2-3 tour selection
	rand_v3 = Vector(tourtaz.length, "float", ) 	//for AP, 0-1+ tour selection
	rand_v4 = Vector(tourtaz.length, "float", ) 	//for AP, 2-6 tour selection

SetRandomSeed(894)
	for n = 1 to tourtaz.length do			//tourtaz.length	
		otazseq = tourorigtazseq[n]
		dtazseq = tourdesttazseq[n]
		cbddum_dest[n] = cbddum[dtazseq]
		ret30_orig[n] = ret30[otazseq]
		rural_dest[n] = rural[dtazseq]
		htime[n] = GetMatrixValue(autofreecur, i2s(tourorigtaz[n]), i2s(tourdesttaz[n]))
		atype_orig[n] = atype[otazseq]
		rand_val = RandomNumber()
		rand_v1[n] = rand_val
		rand_val = RandomNumber()
		rand_v2[n] = rand_val
		rand_val = RandomNumber()
		rand_v3[n] = rand_val
		rand_val = RandomNumber()
		rand_v4[n] = rand_val
	end

//Apply the PA model
	U1 = -3.705 + 0.0253 * htime + 0.7772 * rural_dest + 0.0000429 * ret30_orig + 0.1217 * tours + 0.2 * cbddum_dest
	U2 = -6.030 + 0.0253 * htime + 0.3872 * rural_dest + 0.0000429 * ret30_orig + 0.1217 * tours + 3.5 * cbddum_dest

	E2U0 = 1
	E2U1 = exp(U1)				
	E2U2 = exp(U2)				//Initial alternatives are 0, 1 & 2+ SCH Intermediate stops
	E2U_cum = E2U0 + E2U1+ E2U2

	prob0 = E2U0 / E2U_cum
	prob1 = E2U1 / E2U_cum
	prob2 = E2U2 / E2U_cum
	prob1c = prob0 + prob1
	prob2c = prob1c + prob2

//The 2+ categories are 2 (82.0% of all 2+ is) & 3 (18.0%)
	choice_v = if (rand_v1 < prob0) then 0 else if (rand_v1 < prob1c) then 1 else if (rand_v2 < 0.820) then 2 else 3
	SetDataVector(tour_files[2]+"|", "IS_PA", choice_v,)

//Repeat above logic for AP direction
	U1 = -3.416 + 0.9709 * choice_v + 0.02292 * htime - 0.1922 * toursize + 0.2626 * atype_orig + 0.00006084 * ret30_orig + 0.11723 * tours
	U2 = -4.189 + 0.9709 * choice_v + 0.02292 * htime - 0.1922 * toursize + 0.2626 * atype_orig + 0.00006084 * ret30_orig + 0.11723 * tours

	E2U0 = 1
	E2U1 = exp(U1)				
	E2U2 = exp(U2)				//Initial alternatives are 0, 1 & 2+ SCH Intermediate stops
	E2U_cum = E2U0 + E2U1+ E2U2

	prob0 = E2U0 / E2U_cum
	prob1 = E2U1 / E2U_cum
	prob2 = E2U2 / E2U_cum
	prob1c = prob0 + prob1
	prob2c = prob1c + prob2

//The 2+ categories are 2 (72.8% of all 2+ is), 3 (19.2%), 4 (1.5%), 5 (3.5%) & 6 (3.0%)
	choice_v = if (rand_v3 < prob0) then 0 else if (rand_v3 < prob1c) then 1 else if (rand_v4 < 0.728) then 2 else if (rand_v4 < 0.920) then 3 else if (rand_v4 < 0.935) then 4 else if (rand_v4 < 0.970) then 5 else 6
	SetDataVector(tour_files[2]+"|", "IS_AP", choice_v,)
	CloseView(tour_files[2])	

//************************** HBU INTERMEDIATE STOP MODEL **************************************************************************************************
  UpdateProgressBar("Intermediate Stop Model: HBU", 10) 

//Add new IS field to tour records file  
	hbudestii = OpenTable("hbudestii", "FFB", {DirOutDC + "\\dcHBU.bin",})
	strct = GetTableStructure(tour_files[3])					
	for j = 1 to strct.length do
 		strct[j] = strct[j] + {strct[j][1]}
 	end
	strct = strct + {{"IS_PA", "Integer", 2,,,,,,,,,}}
	strct = strct + {{"IS_AP", "Integer", 2,,,,,,,,,}}
	ModifyTable(tour_files[3], strct)

	tour_vectors = GetDataVectors(tour_files[3]+"|", {"ID", "TAZ", "TAZ_SEQ", "SIZE", "INCOME", "LIFE", "WRKRS", "SCH", "HBU", "HBW", "HBS", 
						"HBO", "ATW", "HHID", "ORIG_TAZ", "ORIG_SEQ", "DEST_TAZ", "DEST_SEQ", "PURP"},{{"Sort Order", {{"ID","Ascending"}}}})
	tourtaz = tour_vectors[2]
//	toursize = tour_vectors[4]
	tourincome = tour_vectors[5]
//	tourlc = tour_vectors[6]
	hbwtours = tour_vectors[10]
	schtours = tour_vectors[8]
	hbutours = tour_vectors[9]
	hbstours = tour_vectors[11]
	hbotours = tour_vectors[12]
	tourorigtaz = tour_vectors[15]
	tourorigtazseq = tour_vectors[16]
	tourdesttaz = tour_vectors[17]
	tourdesttazseq = tour_vectors[18]
	tours = hbwtours + schtours + hbutours + hbstours + hbotours	//TOURS = all tours (HBW+SCH+HBU+HBS+HBO)
	tourinc4dum = if (tourincome = 4) then 1 else 0

	choice_v = Vector(tourtaz.length, "short", {{"Constant", 0}}) 
	ret30_dest = Vector(tourtaz.length, "float", ) 
	at5dum = Vector(tourtaz.length, "short", ) 
	rand_v1 = Vector(tourtaz.length, "float", ) 	//for PA, 0-2 tour selection
//	rand_v2 = Vector(tourtaz.length, "float", ) 	// no 2+ stops
	rand_v3 = Vector(tourtaz.length, "float", ) 	//for AP, 0-1+ tour selection
	rand_v4 = Vector(tourtaz.length, "float", ) 	//for AP, 2-4 tour selection

SetRandomSeed(7844)
	for n = 1 to tourtaz.length do			//tourtaz.length	
		otazseq = tourorigtazseq[n]
		dtazseq = tourdesttazseq[n]
		ret30_dest[n] = ret30[dtazseq]
		at5dum[n] = atype5dum[dtazseq]
		rand_val = RandomNumber()
		rand_v1[n] = rand_val
//		rand_val = RandomNumber()
//		rand_v2[n] = rand_val
		rand_val = RandomNumber()
		rand_v3[n] = rand_val
		rand_val = RandomNumber()
		rand_v4[n] = rand_val
	end

//Apply the PA model
	U1 = -2.790 - 1.154 * tourinc4dum + 0.1311 * tours - 0.4 * at5dum
	U2 = -3.835 - 1.154 * tourinc4dum + 0.1311 * tours - 0.4 * at5dum

	E2U0 = 1
	E2U1 = exp(U1)				
	E2U2 = exp(U2)				//Initial alternatives are 0, 1 & 2+ HBU Intermediate stops
	E2U_cum = E2U0 + E2U1+ E2U2

	prob0 = E2U0 / E2U_cum
	prob1 = E2U1 / E2U_cum
	prob2 = E2U2 / E2U_cum
	prob1c = prob0 + prob1
	prob2c = prob1c + prob2

	choice_v = if (rand_v1 < prob0) then 0 else if (rand_v1 < prob1c) then 1 else 2
	SetDataVector(tour_files[3]+"|", "IS_PA", choice_v,)

//Repeat above logic for AP direction
	U1 = -1.280 + 0.5613 * choice_v + 0.00004232 * ret30_dest - 0.1311 * tours
	U2 = -1.979 + 0.5613 * choice_v + 0.00004232 * ret30_dest - 0.1311 * tours

	E2U0 = 1
	E2U1 = exp(U1)				
	E2U2 = exp(U2)				//Initial alternatives are 0, 1 & 2+ HBU Intermediate stops
	E2U_cum = E2U0 + E2U1+ E2U2

	prob0 = E2U0 / E2U_cum
	prob1 = E2U1 / E2U_cum
	prob2 = E2U2 / E2U_cum
	prob1c = prob0 + prob1
	prob2c = prob1c + prob2

//The 2+ categories are 2 (63.2% of all 2+ is), 3 (27.8%) & 4 (9.0%)
	choice_v = if (rand_v3 < prob0) then 0 else if (rand_v3 < prob1c) then 1 else if (rand_v4 < 0.632) then 2 else if (rand_v4 < 0.910) then 3 else 4
	SetDataVector(tour_files[3]+"|", "IS_AP", choice_v,)
	CloseView(tour_files[3])	

//************************** HBS INTERMEDIATE STOP MODEL **************************************************************************************************
  UpdateProgressBar("Intermediate Stop Model: HBS", 10) 

//Add new IS field to tour records file  
	hbsdestii = OpenTable("hbsdestii", "FFB", {DirOutDC + "\\dcHBS.bin",})
	strct = GetTableStructure(tour_files[4])					
	for j = 1 to strct.length do
 		strct[j] = strct[j] + {strct[j][1]}
 	end
	strct = strct + {{"IS_PA", "Integer", 2,,,,,,,,,}}
	strct = strct + {{"IS_AP", "Integer", 2,,,,,,,,,}}
	ModifyTable(tour_files[4], strct)

	tour_vectors = GetDataVectors(tour_files[4]+"|", {"ID", "TAZ", "TAZ_SEQ", "SIZE", "INCOME", "LIFE", "WRKRS", "SCH", "HBU", "HBW", "HBS", 
						"HBO", "ATW", "HHID", "ORIG_TAZ", "ORIG_SEQ", "DEST_TAZ", "DEST_SEQ", "PURP"},{{"Sort Order", {{"ID","Ascending"}}}})
	tourtaz = tour_vectors[2]
//	toursize = tour_vectors[4]
	tourincome = tour_vectors[5]
//	tourlc = tour_vectors[6]
	hbwtours = tour_vectors[10]
	schtours = tour_vectors[8]
	hbutours = tour_vectors[9]
	hbstours = tour_vectors[11]
	hbotours = tour_vectors[12]
	tourorigtaz = tour_vectors[15]
	tourorigtazseq = tour_vectors[16]
	tourdesttaz = tour_vectors[17]
	tourdesttazseq = tour_vectors[18]
//	tours = hbwtours + schtours + hbutours + hbstours + hbotours
	tourinc1dum = if (tourincome = 1) then 1 else 0
	tourinc4dum = if (tourincome = 4) then 1 else 0

	choice_v = Vector(tourtaz.length, "short", {{"Constant", 0}}) 
	ddensp_orig = Vector(tourtaz.length, "float", ) 
	ret30_dest = Vector(tourtaz.length, "float", ) 
	htime = Vector(tourtaz.length, "float", ) 
	at1dumP = Vector(tourtaz.length, "short", ) 
	at1dumA = Vector(tourtaz.length, "short", ) 
	rand_v1 = Vector(tourtaz.length, "float", ) 	//for PA, 0-2+ tour selection
	rand_v2 = Vector(tourtaz.length, "float", ) 	//for PA, 3-6 tour selection
	rand_v3 = Vector(tourtaz.length, "float", ) 	//for AP, 0-2+ tour selection
	rand_v4 = Vector(tourtaz.length, "float", ) 	//for AP, 3-6 tour selection

SetRandomSeed(9543)
	for n = 1 to tourtaz.length do			//tourtaz.length	
		otazseq = tourorigtazseq[n]
		dtazseq = tourdesttazseq[n]
		ddensp_orig[n] = ddensp[otazseq]
		ret30_dest[n] = ret30[dtazseq]
		htime[n] = GetMatrixValue(autofreecur, i2s(tourorigtaz[n]), i2s(tourdesttaz[n]))
		at1dumP[n] = atype1dum[otazseq]
		at1dumA[n] = atype1dum[dtazseq]
		rand_val = RandomNumber()
		rand_v1[n] = rand_val
		rand_val = RandomNumber()
		rand_v2[n] = rand_val
		rand_val = RandomNumber()
		rand_v3[n] = rand_val
		rand_val = RandomNumber()
		rand_v4[n] = rand_val
	end


//Apply the PA model
	U1 = -1.855 + 0.03799 * htime - 0.6824 * tourinc1dum + 0.0000362 * ddensp_orig - 0.1139 * hbstours + 0.13 * tourinc4dum
	U2 = -2.867 + 0.03799 * htime - 0.7324 * tourinc1dum + 0.0000362 * ddensp_orig - 0.1139 * hbstours + 0.30 * tourinc4dum - 1.0 * at1dumP - 1.0 * at1dumA
	U3 = -3.478 + 0.03799 * htime - 0.7124 * tourinc1dum + 0.0000362 * ddensp_orig - 0.1139 * hbstours + 0.20 * tourinc4dum - 1.0 * at1dumP - 1.0 * at1dumA

	E2U0 = 1
	E2U1 = exp(U1)				
	E2U2 = exp(U2)				
	E2U3 = exp(U3)				//Initial alternatives are 0, 1, 2, & 3+ HBS Intermediate stops
	E2U_cum = E2U0 + E2U1 + E2U2 + E2U3

	prob0 = E2U0 / E2U_cum
	prob1 = E2U1 / E2U_cum
	prob2 = E2U2 / E2U_cum
	prob3 = E2U3 / E2U_cum
	prob1c = prob0 + prob1
	prob2c = prob1c + prob2
	prob3c = prob2c + prob3

//The 3+ categories are 3 (75.0% of all 3+ is), 4 (20.4%), 5 (2.6%) & 6 (2.0%)
	choice_v = if (rand_v1 < prob0) then 0 else if (rand_v1 < prob1c) then 1 else if (rand_v1 < prob2c) then 2 else if (rand_v2 < 0.750) then 3 else if (rand_v2 < 0.954) then 4 else if (rand_v2 < 0.980) then 5 else 6
	SetDataVector(tour_files[4]+"|", "IS_PA", choice_v,)

//Repeat above logic for AP direction
	stop4dum = if (choice_v > 4) then 1 else 0

	U1 = -1.768 + 0.2972 * choice_v + 0.01944 * htime - 0.5592 * tourinc1dum + 0.00004218 * ret30_dest - 0.1683 * hbstours - 2.0 * stop4dum
	U2 = -3.105 + 0.2972 * choice_v + 0.01944 * htime - 0.5592 * tourinc1dum + 0.00004218 * ret30_dest - 0.1683 * hbstours - 2.0 * stop4dum
	U3 = -3.755 + 0.2972 * choice_v + 0.01944 * htime - 0.5592 * tourinc1dum + 0.00004218 * ret30_dest - 0.1683 * hbstours - 2.0 * stop4dum

	E2U0 = 1
	E2U1 = exp(U1)				
	E2U2 = exp(U2)				
	E2U3 = exp(U3)				//Initial alternatives are 0, 1, 2, & 3+ HBS Intermediate stops
	E2U_cum = E2U0 + E2U1 + E2U2 + E2U3

	prob0 = E2U0 / E2U_cum
	prob1 = E2U1 / E2U_cum
	prob2 = E2U2 / E2U_cum
	prob3 = E2U3 / E2U_cum
	prob1c = prob0 + prob1
	prob2c = prob1c + prob2
	prob3c = prob2c + prob3

//The 3+ categories are 3 (64.0% of all 3+ is), 4 (28.0%), 5 (6.0%) & 6 (2.0%)
	choice_v = if (rand_v3 < prob0) then 0 else if (rand_v3 < prob1c) then 1 else if (rand_v3 < prob2c) then 2 else if (rand_v4 < 0.640) then 3 else if (rand_v4 < 0.920) then 4 else if (rand_v4 < 0.980) then 5 else 6
	SetDataVector(tour_files[4]+"|", "IS_AP", choice_v,)
	CloseView(tour_files[4])	

//************************** HBO INTERMEDIATE STOP MODEL **************************************************************************************************
  UpdateProgressBar("Intermediate Stop Model: HBO", 10) 

//Add new IS field to tour records file  
	hbodestii = OpenTable("hbodestii", "FFB", {DirOutDC + "\\dcHBO.bin",})
	strct = GetTableStructure(tour_files[5])					
	for j = 1 to strct.length do
 		strct[j] = strct[j] + {strct[j][1]}
 	end
	strct = strct + {{"IS_PA", "Integer", 2,,,,,,,,,}}
	strct = strct + {{"IS_AP", "Integer", 2,,,,,,,,,}}
	ModifyTable(tour_files[5], strct)

	tour_vectors = GetDataVectors(tour_files[5]+"|", {"ID", "TAZ", "TAZ_SEQ", "SIZE", "INCOME", "LIFE", "WRKRS", "SCH", "HBU", "HBW", "HBS", 
						"HBO", "ATW", "HHID", "ORIG_TAZ", "ORIG_SEQ", "DEST_TAZ", "DEST_SEQ", "PURP"},{{"Sort Order", {{"ID","Ascending"}}}})
	tourtaz = tour_vectors[2]
	toursize = tour_vectors[4]
	tourincome = tour_vectors[5]
	tourlc = tour_vectors[6]
	hbwtours = tour_vectors[10]
	schtours = tour_vectors[8]
	hbutours = tour_vectors[9]
	hbstours = tour_vectors[11]
	hbotours = tour_vectors[12]
	tourorigtaz = tour_vectors[15]
	tourorigtazseq = tour_vectors[16]
	tourdesttaz = tour_vectors[17]
	tourdesttazseq = tour_vectors[18]
	tours = hbwtours + schtours + hbutours + hbstours + hbotours	//TOURS = all tours (HBW+SCH+HBU+HBS+HBO)
	tourinc1dum = if (tourincome = 1) then 1 else 0
	intraz = if (tourorigtazseq = tourdesttazseq) then 1 else 0

	choice_v = Vector(tourtaz.length, "short", {{"Constant", 0}}) 
	ret30_orig = Vector(tourtaz.length, "float", ) 
	cbddum_dest = Vector(tourtaz.length, "short", ) 
	rural_dest = Vector(tourtaz.length, "short", ) 
	rural_orig = Vector(tourtaz.length, "short", ) 
	htime = Vector(tourtaz.length, "float", ) 
	origAT = Vector(tourtaz.length, "float", ) 
	rand_v1 = Vector(tourtaz.length, "float", ) 	//for PA, 0-2+ tour selection
	rand_v2 = Vector(tourtaz.length, "float", ) 	//for PA, 3-7 tour selection
	rand_v3 = Vector(tourtaz.length, "float", ) 	//for AP, 0-2+ tour selection
	rand_v4 = Vector(tourtaz.length, "float", ) 	//for AP, 3-7 tour selection

SetRandomSeed(1548)
	for n = 1 to tourtaz.length do			//tourtaz.length	
		otazseq = tourorigtazseq[n]
		dtazseq = tourdesttazseq[n]
		ret30_orig[n] = ret30[otazseq]
		cbddum_dest[n] = cbddum[dtazseq]
		rural_dest[n] = rural[dtazseq]
		rural_orig[n] = rural[otazseq]
		htime[n] = GetMatrixValue(autofreecur, i2s(tourorigtaz[n]), i2s(tourdesttaz[n]))
		origAT[n] = atype[otazseq]
		rand_val = RandomNumber()
		rand_v1[n] = rand_val
		rand_val = RandomNumber()
		rand_v2[n] = rand_val
		rand_val = RandomNumber()
		rand_v3[n] = rand_val
		rand_val = RandomNumber()
		rand_v4[n] = rand_val
	end

//Apply the PA model
	U1 = -0.947 + 0.03097 * htime - 0.62 * intraz - 1.3354 * cbddum_dest + 0.5026 * rural_dest + 0.00003275 * ret30_orig 			- 0.4 * origAT - 0.1 * tours
	U2 = -3.849 + 0.03097 * htime - 0.62 * intraz - 1.3354 * cbddum_dest + 0.1026 * rural_dest + 0.00003275 * ret30_orig + 0.5 * tourincome - 0.4 * origAT - 0.1 * tours
	U3 = -4.435 + 0.03097 * htime - 0.62 * intraz - 2.2354 * cbddum_dest + 0.9526 * rural_dest + 0.00003275 * ret30_orig + 0.5 * tourincome - 0.4 * origAT - 0.1 * tours

	E2U0 = 1
	E2U1 = exp(U1)				
	E2U2 = exp(U2)				
	E2U3 = exp(U3)				//Initial alternatives are 0, 1, 2, & 3+ HBO Intermediate stops
	E2U_cum = E2U0 + E2U1 + E2U2 + E2U3

	prob0 = E2U0 / E2U_cum
	prob1 = E2U1 / E2U_cum
	prob2 = E2U2 / E2U_cum
	prob3 = E2U3 / E2U_cum
	prob1c = prob0 + prob1
	prob2c = prob1c + prob2
	prob3c = prob2c + prob3

//The 3+ categories are 3 (50.0% of all 3+ is), 4 (27.8%), 5 (11.1%), 6 (5.5%) & 7 (5.6%)
	choice_v = if (rand_v1 < prob0) then 0 else if (rand_v1 < prob1c) then 1 else if (rand_v1 < prob2c) then 2 else if (rand_v2 < 0.500) then 3 else if (rand_v2 < 0.778) then 4 else if (rand_v2 < 0.889) then 5 else if (rand_v2 < 0.944) then 6 else 7
	SetDataVector(tour_files[5]+"|", "IS_PA", choice_v,)

//Repeat above logic for AP direction
	U1 = -1.555 + 0.3102 * choice_v + 0.02345 * htime - 0.4550 * intraz - 0.3154 * tourinc1dum - 0.2879 * rural_orig - 0.06909 * tours
	U2 = -2.745 + 0.3102 * choice_v + 0.02345 * htime - 0.4550 * intraz - 0.3154 * tourinc1dum - 0.2879 * rural_orig - 0.06909 * tours
	U3 = -3.134 + 0.3102 * choice_v + 0.02345 * htime - 0.4550 * intraz - 0.3154 * tourinc1dum - 0.2879 * rural_orig - 0.06909 * tours

	E2U0 = 1
	E2U1 = exp(U1)				
	E2U2 = exp(U2)				
	E2U3 = exp(U3)				//Initial alternatives are 0, 1, 2, & 3+ HBO Intermediate stops
	E2U_cum = E2U0 + E2U1 + E2U2 + E2U3

	prob0 = E2U0 / E2U_cum
	prob1 = E2U1 / E2U_cum
	prob2 = E2U2 / E2U_cum
	prob3 = E2U3 / E2U_cum
	prob1c = prob0 + prob1
	prob2c = prob1c + prob2
	prob3c = prob2c + prob3

//The 3+ categories are 3 (59.4% of all 3+ is), 4 (23.9%), 5 (9.6%), 6 (1.1%) & 7 (4.8%)
	choice_v = if (rand_v3 < prob0) then 0 else if (rand_v3 < prob1c) then 1 else if (rand_v3 < prob2c) then 2 else if (rand_v4 < 0.606) then 3 else if (rand_v4 < 0.845) then 4 else if (rand_v4 < 0.941) then 5 else if (rand_v4 < 0.952) then 6 else 7
	SetDataVector(tour_files[5]+"|", "IS_AP", choice_v,)
    	CloseView(tour_files[5])	

//************************** ATW INTERMEDIATE STOP MODEL **************************************************************************************************
  UpdateProgressBar("Intermediate Stop Model: ATW", 10) 

//Add new IS field to tour records file  
	atwdestii = OpenTable("atwdestii", "FFB", {DirOutDC + "\\dcATW.bin",})
	strct = GetTableStructure(tour_files[6])					
	for j = 1 to strct.length do
 		strct[j] = strct[j] + {strct[j][1]}
 	end
	strct = strct + {{"IS_PA", "Integer", 2,,,,,,,,,}}
	strct = strct + {{"IS_AP", "Integer", 2,,,,,,,,,}}
	ModifyTable(tour_files[6], strct)

	tour_vectors = GetDataVectors(tour_files[6]+"|", {"ID", "TAZ", "TAZ_SEQ", "SIZE", "INCOME", "LIFE", "WRKRS", "SCH", "HBU", "HBW", "HBS", 
						"HBO", "ATW", "HHID", "ORIG_TAZ", "ORIG_SEQ", "DEST_TAZ", "DEST_SEQ", "PURP"},{{"Sort Order", {{"ID","Ascending"}}}})
	tourtaz = tour_vectors[2]
	toursize = tour_vectors[4]
	tourincome = tour_vectors[5]
	tourlc = tour_vectors[6]
	hbwtours = tour_vectors[10]
	schtours = tour_vectors[8]
	hbutours = tour_vectors[9]
	hbstours = tour_vectors[11]
	hbotours = tour_vectors[12]
	atwtours = tour_vectors[13]
	tourorigtaz = tour_vectors[15]
	tourorigtazseq = tour_vectors[16]
	tourdesttaz = tour_vectors[17]
	tourdesttazseq = tour_vectors[18]
	tours = hbwtours + schtours + hbutours + hbstours + hbotours	//TOURS = all tours, excluding ATW (HBW+SCH+HBU+HBS+HBO)
	//the non-resident ATW tours don't have records of the number of tours, so set those = 3.56:
	tours = if (tours = null) then 3.56 else tours
	tours_vec = Vector(tourtaz.length, "float", {{"Constant", 0.0}})
	tours_vec = tours_vec + tours
	tourinc4dum = if (tourincome = 4) then 1 else 0

	choice_v = Vector(tourtaz.length, "short", {{"Constant", 0}}) 
	ret30_orig = Vector(tourtaz.length, "float", ) 
	cbddum_dest = Vector(tourtaz.length, "short", ) 
	rural_dest = Vector(tourtaz.length, "short", ) 
	rural_orig = Vector(tourtaz.length, "short", ) 
	htime = Vector(tourtaz.length, "float", ) 
	rand_v1 = Vector(tourtaz.length, "float", ) 	//for PA, 0-0+ tour selection
	rand_v2 = Vector(tourtaz.length, "float", ) 	//for PA, 1-4 tour selection
	rand_v3 = Vector(tourtaz.length, "float", ) 	//for AP, 0-1+ tour selection
	rand_v4 = Vector(tourtaz.length, "float", ) 	//for AP, 2-5 tour selection

SetRandomSeed(40880)
	for n = 1 to tourtaz.length do			//tourtaz.length	
		otazseq = tourorigtazseq[n]
		dtazseq = tourdesttazseq[n]
		ret30_orig[n] = ret30[otazseq]
		cbddum_dest[n] = cbddum[dtazseq]
		rural_dest[n] = rural[dtazseq]
		htime[n] = GetMatrixValue(autofreecur, i2s(tourorigtaz[n]), i2s(tourdesttaz[n]))
		rand_val = RandomNumber()
		rand_v1[n] = rand_val
		rand_val = RandomNumber()
		rand_v2[n] = rand_val
		rand_val = RandomNumber()
		rand_v3[n] = rand_val
		rand_val = RandomNumber()
		rand_v4[n] = rand_val
	end

//Apply the PA model
	U1 = -3.566 + 0.05033 * htime + 1.559 * rural_dest + 0.1313 * tours_vec

	E2U0 = 1
	E2U1 = exp(U1)				//Initial alternatives are 0 & 1+ ATW Intermediate stops				
	E2U_cum = E2U0 + E2U1

	prob0 = E2U0 / E2U_cum
	prob1 = E2U1 / E2U_cum

//The 1+ categories are 1 (77.6% of all 1+ is), 2 (9.0%), 3 (8.4%) & 4 (5.0%)
	choice_v = if (rand_v1 < prob0) then 0 else if (rand_v2 < 0.776) then 1 else if (rand_v2 < 0.866) then 2 else if (rand_v2 < 0.950) then 3 else 4
	SetDataVector(tour_files[6]+"|", "IS_PA", choice_v,)

//Repeat above logic for AP direction
	U1 = -2.209 + 1.161 * choice_v + 0.04672 * htime  + 1.525 * cbddum_dest - 0.00008081 * ret30_orig

	E2U0 = 1
	E2U1 = exp(U1)				//Initial alternatives are 0 & 1+ ATW Intermediate stops				
	E2U_cum = E2U0 + E2U1

	prob0 = E2U0 / E2U_cum
	prob1 = E2U1 / E2U_cum

//The 1+ categories are 1 (62.3% of all 3+ is), 2 (25.4%), 3 (10.3%) & 4 (2.0%)
	choice_v = if (rand_v3 < prob0) then 0 else if (rand_v4 < 0.623) then 1 else if (rand_v4 < 0.877) then 2 else if (rand_v4 < 0.980) then 3 else 4
	SetDataVector(tour_files[6]+"|", "IS_AP", choice_v,)
	CloseView(tour_files[6])	

//************************** I/X INTERMEDIATE STOP MODEL **************************************************************************************************
  UpdateProgressBar("Intermediate Stop Model: I/X", 10) 
skip2ix:
//Add new IS field to tour records file  
	extdest = OpenTable("extdest", "FFB", {DirOutDC + "\\dcEXT.bin",})
	strct = GetTableStructure(tour_files[7])					
	for j = 1 to strct.length do
 		strct[j] = strct[j] + {strct[j][1]}
 	end
	strct = strct + {{"IS_PA", "Integer", 2,,,,,,,,,}}
	strct = strct + {{"IS_AP", "Integer", 2,,,,,,,,,}}
	ModifyTable(tour_files[7], strct)

	tour_vectors = GetDataVectors(tour_files[7]+"|", {"ID", "TAZ", "TAZ_SEQ", "SIZE", "INCOME", "LIFE", "WRKRS", "SCH", "HBU", "HBW", "HBS", 
						"HBO", "ATW", "HHID", "ORIG_TAZ", "ORIG_SEQ", "DEST_TAZ", "DEST_SEQ", "PURP"},{{"Sort Order", {{"ID","Ascending"}}}})
	tourtaz = tour_vectors[2]
	tourincome = tour_vectors[5]
	tourlc = tour_vectors[6]
	hbwtours = tour_vectors[10]
	schtours = tour_vectors[8]
	hbutours = tour_vectors[9]
	hbstours = tour_vectors[11]
	hbotours = tour_vectors[12]
	atwtours = tour_vectors[13]
	atwtours = nz(atwtours)
	tourorigtaz = tour_vectors[15]
	tourorigtazseq = tour_vectors[16]
	tourdesttaz = tour_vectors[17]
	tourdesttazseq = tour_vectors[18]
	tours = hbwtours + schtours + hbutours + hbstours + hbotours + atwtours	//TOURS = all tours, including ATW (HBW+SCH+HBU+HBS+HBO+ATW)
	tourorigtaz = tour_vectors[15]
	tourorigtazseq = tour_vectors[16]
	tourdesttaz = tour_vectors[17]
	tourdesttazseq = tour_vectors[18]
	tourpurp = tour_vectors[19]
	tourinc4dum = if (tourincome = 4) then 1 else 0
	tourlc2dum = if (tourlc = 2) then 1 else 0
	NWdum = if (tourpurp <> "HBW") then 1 else 0

	choice_v = Vector(tourtaz.length, "short", {{"Constant", 0}}) 
	ret30_orig = Vector(tourtaz.length, "float", ) 
	rural_orig = Vector(tourtaz.length, "short", ) 
	origAT = Vector(tourtaz.length, "short", ) 
	htime = Vector(tourtaz.length, "float", ) 
	rand_v1 = Vector(tourtaz.length, "float", ) 	//for PA, 0-1+ tour selection
	rand_v2 = Vector(tourtaz.length, "float", ) 	//for PA, 2-5 tour selection
	rand_v3 = Vector(tourtaz.length, "float", ) 	//for AP, 0-1+ tour selection
	rand_v4 = Vector(tourtaz.length, "float", ) 	//for AP, 2-6 tour selection

SetRandomSeed(3450)
	for n = 1 to tourtaz.length do			//tourtaz.length	
		otazseq = tourorigtazseq[n]
		dtazseq = tourdesttazseq[n]
		ret30_orig[n] = ret30[otazseq]
		rural_orig[n] = rural[otazseq]
		htime[n] = GetMatrixValue(autofreecur, i2s(tourorigtaz[n]), i2s(tourdesttaz[n]))
		origAT[n] = atype[otazseq]
		rand_val = RandomNumber()
		rand_v1[n] = rand_val
		rand_val = RandomNumber()
		rand_v2[n] = rand_val
		rand_val = RandomNumber()
		rand_v3[n] = rand_val
		rand_val = RandomNumber()
		rand_v4[n] = rand_val
	end

//Apply the PA model
	U1 = -2.744 + 1.250 * NWdum + 0.9095 * tourinc4dum - 0.263 * rural_orig + 0.6864 * tourlc2dum + 0.0001245 * ret30_orig - 0.3 * tours
	U2 = -2.736 + 1.250 * NWdum + 0.9095 * tourinc4dum - 0.263 * rural_orig - 0.2136 * tourlc2dum + 0.0001245 * ret30_orig - 0.3 * tours

	E2U0 = 1
	E2U1 = exp(U1)				
	E2U2 = exp(U2)				//Initial alternatives are 0, 1 & 2+ I/X Intermediate stops
	E2U_cum = E2U0 + E2U1+ E2U2

	prob0 = E2U0 / E2U_cum
	prob1 = E2U1 / E2U_cum
	prob2 = E2U2 / E2U_cum
	prob1c = prob0 + prob1
	prob2c = prob1c + prob2

//The 2+ categories are 2 (53.3% of all 2+ is), 3 (19.5%), 4 (0.2%), 4 (20.0%) & 6 (7.0%)
	choice_v = if (rand_v1 < prob0) then 0 else if (rand_v1 < prob1c) then 1 else if (rand_v2 < 0.533) then 2 else if (rand_v2 < 0.728) then 3 else if (rand_v2 < 0.730) then 4 else if (rand_v2 < 0.930) then 5 else 6
	SetDataVector(tour_files[7]+"|", "IS_PA", choice_v,)

//Repeat above logic for AP direction
	U1 = -0.911 + 1.0979 * choice_v + 0.0125 * htime + 0.3412 * rural_orig - 0.1* origAT - 0.2 * tours
	U2 = -1.295 + 1.0979 * choice_v + 0.0125 * htime + 0.3412 * rural_orig - 0.1* origAT - 0.2 * tours

	E2U0 = 1
	E2U1 = exp(U1)				
	E2U2 = exp(U2)				//Initial alternatives are 0, 1 & 2+ I/X Intermediate stops
	E2U_cum = E2U0 + E2U1+ E2U2

	prob0 = E2U0 / E2U_cum
	prob1 = E2U1 / E2U_cum
	prob2 = E2U2 / E2U_cum
	prob1c = prob0 + prob1
	prob2c = prob1c + prob2

//The 2+ categories are 2 (68.5% of all 2+ is), 3 (16.2%), 4 (9.3%), 5 (1.5%) & 6 (4.5%)
	choice_v = if (rand_v3 < prob0) then 0 else if (rand_v3 < prob1c) then 1 else if (rand_v4 < 0.685) then 2 else if (rand_v4 < 0.847) then 3 else if (rand_v4 < 0.940) then 4 else if (rand_v4 < 0.955) then 5 else 6
	SetDataVector(tour_files[7]+"|", "IS_AP", choice_v,)
	CloseView(tour_files[7])	

//************************** X/I WORK INTERMEDIATE STOP MODEL **************************************************************************************************
  UpdateProgressBar("Intermediate Stop Model: XIW", 10) 
skip2xiw:
//Add new IS field to tour records file  
	xiw = OpenTable("xiw", "FFB", {DirOutDC + "\\dcXIW.bin",})
	strct = GetTableStructure(tour_files[8])					
	for j = 1 to strct.length do
 		strct[j] = strct[j] + {strct[j][1]}
 	end
	strct = strct + {{"IS_PA", "Integer", 2,,,,,,,,,}}
	strct = strct + {{"IS_AP", "Integer", 2,,,,,,,,,}}
	ModifyTable(tour_files[8], strct)

	tour_vectors = GetDataVectors(tour_files[8]+"|", {"ID", "ORIG_TAZ", "ORIG_SEQ", "DEST_TAZ", "DEST_SEQ"},{{"Sort Order", {{"ID","Ascending"}}}})
	tourextsta = tour_vectors[2]
	tourextstaseq = tour_vectors[3]
	tourdesttaz = tour_vectors[4]
	tourdesttazseq = tour_vectors[5]

//We don't know the income, origins, or life cycle of X/I travellers or the number of tours from their HH.  Assume that all are income 4 and that half of the origins are rural.  
//About 28% of Metrolina HHs are LC2, so use that fraction for the LC2dum variable.  Metrolina residents made 3.56 RT tours/HH, so assume that.
  	inc4dum = 1
  	origRur = 0.50
  	lc2dum  = 0.28
  	tours   = 3.56

//Have to get the total retail (retail + hwy) employment within 3 miles of external stations.  (TAZ done in the begining)
     	Opts = null
     	Opts.Input.[Origin Set] = {Dir + "\\" + net_file + ".dbd|Node", "Node", "ExtSta","Select * where Centroid = 2"}
     	Opts.Input.[Destination Set] = {Dir + "\\" + net_file + ".dbd|Node", "Node", "Cent","Select * where Centroid = 1"}
     	Opts.Global.[Map Unit Label] = "Miles"
     	Opts.Global.[Map Unit Size] = 1
     	Opts.Output.[Output Matrix].Label = "Output Matrix"
     	Opts.Output.[Output Matrix].Compression = 0				//Choose no compression so can open as memory-based
     	Opts.Output.[Output Matrix].[File Name] = DirOutDC + "\\extsta_dist.mtx"
     	ret_value = RunMacro("TCB Run Procedure", "EUCMat", Opts, &Ret)

	extstavol = OpenTable("extstavol", "FFA", {Dir + "\\Ext\\EXTSTAVOL" + yr_str + ".asc",})  
	extstanum = GetDataVector(extstavol+"|", "MODEL_STA", {{"Sort Order", {{"MODEL_STA","Ascending"}}}}) 
//	extsta_id = Vector(extstanum.length, "short", ) 

	extstadist_m = OpenMatrix(DirOutDC + "\\extsta_dist.mtx", "False")	
	extstadist_mc = CreateMatrixCurrency(extstadist_m, "Miles", "Origin", "Destination", )	
	ret30extsta_m = CreateMatrix({extstavol+"|", "MODEL_STA","Row Index"}, {se_vw+"|", "TAZ","Column Index"},
					{{"File Name", DirOutDC + "\\ret30extsta.mtx"}, {"Label", "retail emp within 3 miles"},{"Type", "Long"}, {"Tables", {"ret30extsta"}}})	//,{"File Based", "No"}
	ret30extsta_mc = CreateMatrixCurrency(ret30extsta_m, "ret30extsta", "Row Index", "Column Index", )

	influence_area = 3		//influence area for production/attractions zones is 3 miles; do for production (Row) and attraction (Column) zones.
	ret30extsta_mc := if (extstadist_mc > influence_area) then 0 else retail	//zeros out zones that are outside the influence area (3 miles); retail + hwy employment within the influence area of each zone

	ret30extsta_ar = GetMatrixMarginals(ret30extsta_mc, "Sum", "row")
	ret30extsta = a2v(ret30extsta_ar)							//this is total retail within each zone's influence area

	choice_v = Vector(tourextsta.length, "short", {{"Constant", 0}}) 
	ret30_dest = Vector(tourextsta.length, "float", ) 
	ret30_orig = Vector(tourextsta.length, "float", ) 
	AT_dest = Vector(tourextsta.length, "short", ) 
	rand_v1 = Vector(tourextsta.length, "float", ) 	//for PA, 0-1+ tour selection
	rand_v2 = Vector(tourextsta.length, "float", ) 	//for PA, 2-5 tour selection
	rand_v3 = Vector(tourextsta.length, "float", ) 	//for AP, 0-1+ tour selection
	rand_v4 = Vector(tourextsta.length, "float", ) 	//for AP, 2-5 tour selection

SetRandomSeed(156)
	for n = 1 to tourextsta.length do			//tourtaz.length	
		dtazseq = tourdesttazseq[n]
		ret30_dest[n] = ret30[dtazseq]
		ret30_orig[n] = ret30[tourextstaseq[n]]
		AT_dest[n] = atype[dtazseq]
		rand_val = RandomNumber()
		rand_v1[n] = rand_val
		rand_val = RandomNumber()
		rand_v2[n] = rand_val
		rand_val = RandomNumber()
		rand_v3[n] = rand_val
		rand_val = RandomNumber()
		rand_v4[n] = rand_val
	end

//Apply the PA model (same as HBW PA model, except for [see above])
	U1 = 0.568  + 0.2392 * inc4dum + 0.9609 * lc2dum + 0.00004341 * ret30_orig + 0.00001594 * ret30_dest - 0.2817 * tours - 0.5 * AT_dest
	U2 = 0.198  + 0.2392 * inc4dum + 0.9609 * lc2dum + 0.00004341 * ret30_orig + 0.00001594 * ret30_dest - 0.2817 * tours - 0.5 * AT_dest

	E2U0 = 1
	E2U1 = exp(U1)				
	E2U2 = exp(U2)				//Initial alternatives are 0, 1 & 2+ I/X Intermediate stops
	E2U_cum = E2U0 + E2U1+ E2U2

	prob0 = E2U0 / E2U_cum
	prob1 = E2U1 / E2U_cum
	prob2 = E2U2 / E2U_cum
	prob1c = prob0 + prob1
	prob2c = prob1c + prob2

//The 2+ categories are 2 (68.8% of all 2+ is), 3 (18.7%), 4 (9.4%), & 5 (3.1%)
	choice_v = if (rand_v1 < prob0) then 0 else if (rand_v1 < prob1c) then 1 else if (rand_v2 < 0.688) then 2 else if (rand_v2 < 0.875) then 3 else if (rand_v2 < 0.969) then 4 else 5
	SetDataVector(tour_files[8]+"|", "IS_PA", choice_v,)

//Repeat above logic for AP direction
	U1 = -2.214 + 0.4851 * choice_v + 0.3553 * inc4dum + 0.00003103 * ret30_orig	 // + 1.0*at1dum; Set AT1DUM to zero since we will assume that X/I tours don't begin in a CBD.
	U2 = -2.844 + 0.4851 * choice_v + 0.3553 * inc4dum + 0.00003103 * ret30_orig	 // + 1.0*at1dum; Set AT1DUM to zero since we will assume that X/I tours don't begin in a CBD.

	E2U0 = 1
	E2U1 = exp(U1)				
	E2U2 = exp(U2)				//Initial alternatives are 0, 1 & 2+ I/X Intermediate stops
	E2U_cum = E2U0 + E2U1+ E2U2

	prob0 = E2U0 / E2U_cum
	prob1 = E2U1 / E2U_cum
	prob2 = E2U2 / E2U_cum
	prob1c = prob0 + prob1
	prob2c = prob1c + prob2

//The 2+ categories are 2 (68.8% of all 2+ is), 3 (18.7%), 4 (9.4%), & 5 (3.1%)
	choice_v = if (rand_v3 < prob0) then 0 else if (rand_v3 < prob1c) then 1 else if (rand_v4 < 0.700) then 2 else if (rand_v4 < 0.888) then 3 else if (rand_v4 < 0.938) then 4 else if (rand_v4 < 0.975) then 5 else if (rand_v4 < 0.988) then 6 else 7
	SetDataVector(tour_files[8]+"|", "IS_AP", choice_v,)
	CloseView(tour_files[8])	

//************************** X/I NON-WORK INTERMEDIATE STOP MODEL **************************************************************************************************
  UpdateProgressBar("Intermediate Stop Model: XIN", 10) 
skip2xin:
//Add new IS field to tour records file  
	xin = OpenTable("xin", "FFB", {DirOutDC + "\\dcXIN.bin",})
	strct = GetTableStructure(tour_files[9])					
	for j = 1 to strct.length do
 		strct[j] = strct[j] + {strct[j][1]}
 	end
	strct = strct + {{"IS_PA", "Integer", 2,,,,,,,,,}}
	strct = strct + {{"IS_AP", "Integer", 2,,,,,,,,,}}
	ModifyTable(tour_files[9], strct)

	tour_vectors = GetDataVectors(tour_files[9]+"|", {"ID", "ORIG_TAZ", "ORIG_SEQ", "DEST_TAZ", "DEST_SEQ"},{{"Sort Order", {{"ID","Ascending"}}}})
	tourextsta = tour_vectors[2]
	tourextstaseq = tour_vectors[3]
	tourdesttaz = tour_vectors[4]
	tourdesttazseq = tour_vectors[5]

//We don't know the income or life cycle of X/I travellers or the number of tours from their HH.  Assume that none are income 1 and that half of the origins are rural.  
//Metrolina residents made 3.56 RT tours/HH, so assume that. For X/I, the tour can't be intrazonal.
//Added for HBO validation: origAT = assume 4 (suburban), income = assume 4.  origAT = 5  destRur = 0

  	inc1dum = 0
  	origAT = 5
  	tours  = 3.56
  	intraz  = 0
	tourincome  = 4
	rural_dest = 0
	
	
	choice_v = Vector(tourextsta.length, "short", {{"Constant", 0}}) 
	cbddum_dest = Vector(tourextsta.length, "short", ) 
	rural_dest = Vector(tourextsta.length, "short", ) 
	ret30_orig = Vector(tourextsta.length, "float", ) 
	htime = Vector(tourextsta.length, "float", ) 
	rand_v1 = Vector(tourextsta.length, "float", ) 	//for PA, 0-1+ tour selection
	rand_v2 = Vector(tourextsta.length, "float", ) 	//for PA, 2-5 tour selection
	rand_v3 = Vector(tourextsta.length, "float", ) 	//for AP, 0-1+ tour selection
	rand_v4 = Vector(tourextsta.length, "float", ) 	//for AP, 2-5 tour selection

SetRandomSeed(343)
	for n = 1 to tourextsta.length do			//tourtaz.length	
		dtazseq = tourdesttazseq[n]
		cbddum_dest[n] = cbddum[dtazseq]
		rural_dest[n] = rural[dtazseq]
		ret30_orig[n] = ret30[tourextstaseq[n]]
		htime[n] = GetMatrixValue(autofreecur, i2s(tourextsta[n]), i2s(tourdesttaz[n]))
		rand_val = RandomNumber()
		rand_v1[n] = rand_val
		rand_val = RandomNumber()
		rand_v2[n] = rand_val
		rand_val = RandomNumber()
		rand_v3[n] = rand_val
		rand_val = RandomNumber()
		rand_v4[n] = rand_val
	end

//Apply the PA model (same as the HBO PA model)
	U1 = -0.997 + 0.03097 * htime - 0.62 * intraz - 1.3354 * cbddum_dest + 0.5026 * rural_dest + 0.00003275 * ret30_orig 			- 0.4 * origAT - 0.1 * tours
	U2 = -3.899 + 0.03097 * htime - 0.62 * intraz - 1.3354 * cbddum_dest + 0.1026 * rural_dest + 0.00003275 * ret30_orig + 0.5 * tourincome - 0.4 * origAT - 0.1 * tours
	U3 = -4.485 + 0.03097 * htime - 0.62 * intraz - 2.2354 * cbddum_dest + 0.9526 * rural_dest + 0.00003275 * ret30_orig + 0.5 * tourincome - 0.4 * origAT - 0.1 * tours

	E2U0 = 1
	E2U1 = exp(U1)				
	E2U2 = exp(U2)				
	E2U3 = exp(U3)				//Initial alternatives are 0, 1, 2, & 3+ HBO Intermediate stops
	E2U_cum = E2U0 + E2U1 + E2U2 + E2U3

	prob0 = E2U0 / E2U_cum
	prob1 = E2U1 / E2U_cum
	prob2 = E2U2 / E2U_cum
	prob3 = E2U3 / E2U_cum
	prob1c = prob0 + prob1
	prob2c = prob1c + prob2
	prob3c = prob2c + prob3

//The 3+ categories are 3 (50.0% of all 3+ is), 4 (27.8%), 5 (11.1%), 6 (5.5%) & 7 (5.6%)
	choice_v = if (rand_v1 < prob0) then 0 else if (rand_v1 < prob1c) then 1 else if (rand_v1 < prob2c) then 2 else if (rand_v2 < 0.500) then 3 else if (rand_v2 < 0.778) then 4 else if (rand_v2 < 0.889) then 5 else if (rand_v2 < 0.944) then 6 else 7
	SetDataVector(tour_files[9]+"|", "IS_PA", choice_v,)

//Repeat above logic for AP direction
	U1 = -2.055 + 0.3102 * choice_v + 0.02345 * htime - 0.4550 * intraz - 0.3154 * inc1dum - 0.2879 * origRur - 0.06909 * tours
	U2 = -3.245 + 0.3102 * choice_v + 0.02345 * htime - 0.4550 * intraz - 0.3154 * inc1dum - 0.2879 * origRur - 0.06909 * tours
	U3 = -3.634 + 0.3102 * choice_v + 0.02345 * htime - 0.4550 * intraz - 0.3154 * inc1dum - 0.2879 * origRur - 0.06909 * tours

	E2U0 = 1
	E2U1 = exp(U1)				
	E2U2 = exp(U2)				
	E2U3 = exp(U3)				//Initial alternatives are 0, 1, 2, & 3+ HBO Intermediate stops
	E2U_cum = E2U0 + E2U1 + E2U2 + E2U3

	prob0 = E2U0 / E2U_cum
	prob1 = E2U1 / E2U_cum
	prob2 = E2U2 / E2U_cum
	prob3 = E2U3 / E2U_cum
	prob1c = prob0 + prob1
	prob2c = prob1c + prob2
	prob3c = prob2c + prob3

//The 3+ categories are 3 (60.6% of all 3+ is), 4 (23.9%), 5 (9.6%), 6 (1.1%) & 7 (4.8%)
	choice_v = if (rand_v3 < prob0) then 0 else if (rand_v3 < prob1c) then 1 else if (rand_v3 < prob2c) then 2 else if (rand_v4 < 0.594) then 3 else if (rand_v4 < 0.844) then 4 else if (rand_v4 < 0.938) then 5 else if (rand_v4 < 0.969) then 6 else 7
	SetDataVector(tour_files[9]+"|", "IS_AP", choice_v,)
	CloseView(tour_files[9])	

    DestroyProgressBar()
     RunMacro("G30 File Close All")

    goto quit

	badquit:
		on error, notfound default
		RunMacro("TCB Closing", ret_value, "TRUE" )
		msg = msg + {"Tour Intermediate Stops: Error somewhere"}
		AppendToLogFile(1, "Tour Intermediate Stops: Error somewhere")
		datentime = GetDateandTime()
		AppendToLogFile(1, "Tour Intermediate Stops " + datentime)

       	return({0, msg})

    quit:
		on error, notfound default
   		datentime = GetDateandTime()
		AppendToLogFile(1, "Exit Tour Intermediate Stops " + datentime)
    	return({1, msg})
		

endmacro