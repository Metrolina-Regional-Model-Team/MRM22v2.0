Macro "Tour_IS_FB" (Args)

//The Intermediate Stops macro just for HBW & ATW (internal tours only) and IX, XIW, and XIN.  
// 1/17, mk: changed from .dbf to .bin
// 2/25/19, mk: HBO, XIN and XIW coeffs per Bill's 2/25/19 email
// 7/20/20, mk: fixed accessibility variables (was short, which caused null values for dense area; changed to float)


	on error goto badquit
	LogFile = Args.[Log File].value
	ReportFile = Args.[Report File].value
	SetLogFileName(LogFile)
	SetReportFileName(ReportFile)
	
	sedata_file = Args.[LandUse file].value
	Dir = Args.[Run Directory].value
	theyear = Args.[Run Year].value
//	net_file = Args.[Hwy Name].value
	curiter = Args.[Current Feedback Iter].value
	msg = null
	datentime = GetDateandTime()
	AppendToLogFile(1, "Tour Intermediate Stops Feedback Loop " + i2s(curiter) + ": " + datentime)
	RunMacro("TCB Init")

	RunMacro("G30 File Close All") 

	DirArray  = Dir + "\\TG"
 	DirOutDC  = Dir + "\\TD"
 	
 	yr_str = Right(theyear,2)
	yr = s2i(yr_str)


  CreateProgressBar("Tour Intermediate Stop Model...Opening files", "TRUE")

	se_vw = OpenTable("SEFile", "dBASE", {sedata_file,})
	areatype = OpenTable("areatype", "DBASE", {Dir + "\\landuse\\SE" + theyear + "_DENSITY.dbf",})  
	hbwdestii = OpenTable("hbwdestii", "FFB", {DirOutDC + "\\dcHBW.bin",})

	se_vectors = GetDataVectors(se_vw+"|", {"TAZ", "HH", "RTL", "HWY"},{{"Sort Order", {{"TAZ","Ascending"}}}})
	taz = se_vectors[1]
	hh = se_vectors[2]
	rtl = se_vectors[3]
	hwy = se_vectors[4]
	retail = rtl + hwy
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

//	tour_files = {"hbwdestii", "schdestii", "hbudestii", "hbsdestii", "hbodestii", "atwdestii", "extdest", "xiw", "xin"}


//************************** HBW INTERMEDIATE STOP MODEL **************************************************************************************************

//Add new IS field to tour records file  
	strct = GetTableStructure("hbwdestii")					
	for j = 1 to strct.length do
 		strct[j] = strct[j] + {strct[j][1]}
 	end
	strct = strct + {{"IS_PA", "Integer", 2,,,,,,,,,}}
	strct = strct + {{"IS_AP", "Integer", 2,,,,,,,,,}}
	ModifyTable("hbwdestii", strct)

	tour_vectors = GetDataVectors("hbwdestii|", {"ID", "TAZ", "INCOME", "LIFE", "HBW", "ORIG_TAZ", "ORIG_SEQ", "DEST_TAZ", "DEST_SEQ"},{{"Sort Order", {{"ID","Ascending"}}}})
	tourtaz = tour_vectors[2]
	tourincome = tour_vectors[3]
	tourlc = tour_vectors[4]
	hbwtours = tour_vectors[5]
	tourorigtaz = tour_vectors[6]
	tourorigtazseq = tour_vectors[7]
	tourdesttaz = tour_vectors[8]
	tourdesttazseq = tour_vectors[9]
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
SetRandomSeed(16618)
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
	SetDataVector("hbwdestii|", "IS_PA", choice_v,)

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
	SetDataVector("hbwdestii|", "IS_AP", choice_v,)
	CloseView("hbwdestii")	


//************************** ATW INTERMEDIATE STOP MODEL **************************************************************************************************
  UpdateProgressBar("Intermediate Stop Model Feedback Iter " + i2s(curiter) + ": ATW", 10) 

//Add new IS field to tour records file  
	atwdestii = OpenTable("atwdestii", "FFB", {DirOutDC + "\\dcATW.bin",})
	strct = GetTableStructure("atwdestii")					
	for j = 1 to strct.length do
 		strct[j] = strct[j] + {strct[j][1]}
 	end
	strct = strct + {{"IS_PA", "Integer", 2,,,,,,,,,}}
	strct = strct + {{"IS_AP", "Integer", 2,,,,,,,,,}}
	ModifyTable("atwdestii", strct)

	tour_vectors = GetDataVectors("atwdestii|", {"ID", "TAZ", "TAZ_SEQ", "SIZE", "INCOME", "LIFE", "WRKRS", "SCH", "HBU", "HBW", "HBS", 
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

SetRandomSeed(16519)
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
	SetDataVector("atwdestii|", "IS_PA", choice_v,)

//Repeat above logic for AP direction
	U1 = -2.209 + 1.161 * choice_v + 0.04672 * htime  + 1.525 * cbddum_dest - 0.00008081 * ret30_orig

	E2U0 = 1
	E2U1 = exp(U1)				//Initial alternatives are 0 & 1+ ATW Intermediate stops				
	E2U_cum = E2U0 + E2U1

	prob0 = E2U0 / E2U_cum
	prob1 = E2U1 / E2U_cum

//The 1+ categories are 1 (62.3% of all 3+ is), 2 (25.4%), 3 (10.3%) & 4 (2.0%)
	choice_v = if (rand_v3 < prob0) then 0 else if (rand_v4 < 0.623) then 1 else if (rand_v4 < 0.877) then 2 else if (rand_v4 < 0.980) then 3 else 4
	SetDataVector("atwdestii|", "IS_AP", choice_v,)
	CloseView("atwdestii")	


//************************** I/X INTERMEDIATE STOP MODEL **************************************************************************************************
  UpdateProgressBar("Intermediate Stop Model: I/X", 10) 

//Add new IS field to tour records file  
	extdest = OpenTable("extdest", "FFB", {DirOutDC + "\\dcEXT.bin",})
	strct = GetTableStructure("extdest")					
	for j = 1 to strct.length do
 		strct[j] = strct[j] + {strct[j][1]}
 	end
	strct = strct + {{"IS_PA", "Integer", 2,,,,,,,,,}}
	strct = strct + {{"IS_AP", "Integer", 2,,,,,,,,,}}
	ModifyTable("extdest", strct)

	tour_vectors = GetDataVectors("extdest|", {"ID", "TAZ", "TAZ_SEQ", "SIZE", "INCOME", "LIFE", "WRKRS", "SCH", "HBU", "HBW", "HBS", 
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
	tours = hbwtours + schtours + hbutours + hbstours + hbotours + atwtours
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

SetRandomSeed(784484)
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
	U1 = -2.744 + 1.250 * NWdum + 0.9095 * tourinc4dum - 4.263 * rural_orig + 0.6864 * tourlc2dum + 0.0001245 * ret30_orig - 0.3 * tours
	U2 = -2.736 + 1.250 * NWdum + 0.9095 * tourinc4dum - 4.263 * rural_orig - 0.2136 * tourlc2dum + 0.0001245 * ret30_orig - 0.3 * tours

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
	SetDataVector("extdest|", "IS_PA", choice_v,)

//Repeat above logic for AP direction
	U1 = -0.911 + 1.0979 * choice_v + 0.0125 * htime + 0.3412 * rural_orig - 0.1* origAT - 0.2 * tours
	U2 = -2.495 + 0.6979 * choice_v + 0.0125 * htime + 0.3412 * rural_orig - 0.1* origAT - 0.2 * tours

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
	SetDataVector("extdest|", "IS_AP", choice_v,)
	CloseView("extdest")	


//************************** X/I WORK INTERMEDIATE STOP MODEL **************************************************************************************************
  UpdateProgressBar("Intermediate Stop Model Feedback Iter " + i2s(curiter) + ": XIW", 10) 

//Add new IS field to tour records file  
	xiw = OpenTable("xiw", "FFB", {DirOutDC + "\\dcXIW.bin",})
	strct = GetTableStructure("xiw")					
	for j = 1 to strct.length do
 		strct[j] = strct[j] + {strct[j][1]}
 	end
	strct = strct + {{"IS_PA", "Integer", 2,,,,,,,,,}}
	strct = strct + {{"IS_AP", "Integer", 2,,,,,,,,,}}
	ModifyTable("xiw", strct)

	tour_vectors = GetDataVectors("xiw|", {"ID", "ORIG_TAZ", "ORIG_SEQ", "DEST_TAZ", "DEST_SEQ"},{{"Sort Order", {{"ID","Ascending"}}}})
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
 /*    	Opts = null
     	Opts.Input.[Origin Set] = {Dir + "\\" + net_file + ".dbd|Node", "Node", "ExtSta","Select * where Centroid = 2"}
     	Opts.Input.[Destination Set] = {Dir + "\\" + net_file + ".dbd|Node", "Node", "Cent","Select * where Centroid = 1"}
     	Opts.Global.[Map Unit Label] = "Miles"
     	Opts.Global.[Map Unit Size] = 1
     	Opts.Output.[Output Matrix].Label = "Output Matrix"
     	Opts.Output.[Output Matrix].Compression = 0				//Choose no compression so can open as memory-based
     	Opts.Output.[Output Matrix].[File Name] = DirOutDC + "\\extsta_dist.mtx"
     	ret_value = RunMacro("TCB Run Procedure", "EUCMat", Opts, &Ret)
*/
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

SetRandomSeed(5964)
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
	U2 = 0.198  + 0.2392 * inc4dum + 0.9609 * lc2dum + 0.00004341 * ret30_orig + 0.00001594 * ret30_dest - 0.3017 * tours - 0.5 * AT_dest

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
	SetDataVector("xiw|", "IS_PA", choice_v,)

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
	SetDataVector("xiw|", "IS_AP", choice_v,)
	CloseView("xiw")	


//************************** X/I NON-WORK INTERMEDIATE STOP MODEL **************************************************************************************************
  UpdateProgressBar("Intermediate Stop Model: XIN", 10) 

//Add new IS field to tour records file  
	xin = OpenTable("xin", "FFB", {DirOutDC + "\\dcXIN.bin",})
	strct = GetTableStructure("xin")					
	for j = 1 to strct.length do
 		strct[j] = strct[j] + {strct[j][1]}
 	end
	strct = strct + {{"IS_PA", "Integer", 2,,,,,,,,,}}
	strct = strct + {{"IS_AP", "Integer", 2,,,,,,,,,}}
	ModifyTable("xin", strct)

	tour_vectors = GetDataVectors("xin|", {"ID", "ORIG_TAZ", "ORIG_SEQ", "DEST_TAZ", "DEST_SEQ"},{{"Sort Order", {{"ID","Ascending"}}}})
	tourextsta = tour_vectors[2]
	tourextstaseq = tour_vectors[3]
	tourdesttaz = tour_vectors[4]
	tourdesttazseq = tour_vectors[5]

//We don't know the income or life cycle of X/I travellers or the number of tours from their HH.  Assume that none are income 1 and that half of the origins are rural.  
//Metrolina residents made 3.56 RT tours/HH, so assume that. For X/I, the tour can't be intrazonal.
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

SetRandomSeed(48)
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
	SetDataVector("xin|", "IS_PA", choice_v,)

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
	SetDataVector("xin|", "IS_AP", choice_v,)
	CloseView("xin")	


    DestroyProgressBar()
     RunMacro("G30 File Close All")

    goto quit

	badquit:
		on error, notfound default
		RunMacro("TCB Closing", ret_value, "TRUE" )
		msg = msg + {"Intermediate Stop Model Feedback Iter " + i2s(curiter) + ": Error somewhere"}
		AppendToLogFile(1, "Intermediate Stop Model Feedback Iter " + i2s(curiter) + ": Error somewhere")
		datentime = GetDateandTime()
		AppendToLogFile(1, "Intermediate Stop Model Feedback Iter " + i2s(curiter) + " " + datentime)

       	return({0, msg})

    quit:
		on error, notfound default
   		datentime = GetDateandTime()
		AppendToLogFile(1, "Exit Tour Intermediate Stops Feedback Iter " + i2s(curiter) + " " + datentime)
    	return({1, msg})
		

endmacro