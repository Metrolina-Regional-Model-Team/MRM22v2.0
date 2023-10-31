Macro "Tour_DC_FB" (Args)

//Feedback Tour DC model; HBW, ATW, EIW purposes
//This version does not split out IE tours; rather, it makes a backup (iter 1) copy of the dcHBW & dcATW files and re-runs dest choice just on those II tours.
//Coefficients are embedded below
// 1/17, mk: changed from .dbf to .bin
// 2/18, mk: added fields for O-D (and D-O) travel times
// 2/18, mk: this version changes the coefficient for intrazonal variable based on the origin/home zone's area type (HBW but not ATW)
// 2/22/18, mk: changes per BA's 2/21/18 email
// 2/26/18, mk: changes per BA's 2/26/18 email
// 5/2/18, mk: changes per BA's 5/1/18 email
// 5/4/18, mk: correct XIW & XIN
// 5/8/18, mk: randomally sort by Tours instead of by zones; were getting concentrated areas of long distance tours at end of each set of tours 
// 5/29/18, mk: coefficient changes per BA's 5/11/18 email
// 6/20/18, mk: changed double-contraint factor minimum from 0 to 0.01 for non-Work purposes
// 9/12/18, mk: fixed ATW DC error (tourset name)
// 2/25/19, mk: change HBW coeffs to match DCapp5 per Bill's 2/25/19 email

	on error goto badquit
	LogFile = Args.[Log File].value
	ReportFile = Args.[Report File].value
	SetLogFileName(LogFile)
	SetReportFileName(ReportFile)
	
	sedata_file = Args.[LandUse file].value
	Dir = Args.[Run Directory].value
	theyear = Args.[Run Year].value
	curiter = Args.[Current Feedback Iter].value
	msg = null
	datentime = GetDateandTime()
	AppendToLogFile(1, "Tour DC Feedback Loop " + i2s(curiter) + ": " + datentime)
	RunMacro("TCB Init")

	RunMacro("G30 File Close All") 

	yr_str = Right(theyear,2)
 	DirArray  = Dir + "\\TG"
 	DirOutDC  = Dir + "\\TD"	
 
  CreateProgressBar("Tour Destination Choice (Feedback)...Opening files", "TRUE")

//Make copies of HBW, ATW, & dcEXT tables
	CopyTableFiles(null, "FFB", DirOutDC + "\\dcHBW.bin", null, DirOutDC + "\\dcHBW_iter" + i2s(curiter - 1) + ".bin", null)
	CopyTableFiles(null, "FFB", DirOutDC + "\\dcATW.bin", , DirOutDC + "\\dcATW_iter" + i2s(curiter - 1) + ".bin", )
	CopyTableFiles(null, "FFB", DirOutDC + "\\dcATWext.bin", , DirOutDC + "\\dcATWext_iter" + i2s(curiter - 1) + ".bin", )
	CopyTableFiles(null, "FFB", DirOutDC + "\\dcXIW.bin", , DirOutDC + "\\dcXIW_iter" + i2s(curiter - 1) + ".bin", )
	CopyTableFiles(null, "FFB", DirOutDC + "\\dcXIN.bin", , DirOutDC + "\\dcXIN_iter" + i2s(curiter - 1) + ".bin", )
	CopyTableFiles(null, "FFB", DirOutDC + "\\dcEXT.bin", , DirOutDC + "\\dcEXT_iter" + i2s(curiter - 1) + ".bin", )
	
//Save only these fields from the previous iteration.  External-internal table gets totally redone, so don't need to remove fields.
//	hbw_fields = {"ID", "TAZ", "TAZ_SEQ", "SIZE", "INCOME", "LIFE", "WRKRS", "SCH", "HBU", "HBW", "HBS", "HBO", "ATW", "HHID", "ORIG_TAZ", "ORIG_SEQ", "DEST_TAZ", "DEST_SEQ", "PURP"}
	atw_fields = {"ID", "TAZ", "TAZ_SEQ", "SIZE", "INCOME", "LIFE", "WRKRS", "SCH", "HBU", "HBW", "HBS", "HBO", "ATW", "HHID", "ORIG_TAZ", "ORIG_SEQ", "DEST_TAZ", "DEST_SEQ", "PURP", "HBWID"}
	ix_fields = {"ID", "TAZ", "TAZ_SEQ", "SIZE", "INCOME", "LIFE", "WRKRS", "SCH", "HBU", "HBW", "HBS", "HBO", "ATW", "HHID", "ORIG_TAZ", "ORIG_SEQ", "DEST_TAZ", "DEST_SEQ", "PURP"}
	
	se_vw = OpenTable("SEFile", "dBASE", {sedata_file,})
	hhbyincome = OpenTable("hhbyincome", "FFB", {DirArray + "\\HH_INCOME.bin",})
	distExtsta_vw = OpenTable("distextsta", "FFA", {Dir + "\\Ext\\Dist_to_Closest_ExtSta.asc",})
	distCBD_vw = OpenTable("distcbd", "FFA", {Dir + "\\LandUse\\Dist_to_CBD.asc",})
//	access_peak = OpenTable("access_peak", "FFB", {DirArray + "\\ACCESS_PEAK.bin",})
	access_free = OpenTable("access_free", "FFB", {DirArray + "\\ACCESS_FREE.bin",})
	areatype = OpenTable("areatype", "DBASE", {Dir + "\\landuse\\SE" + theyear + "_DENSITY.dbf",})  

//pay attention to order.  Attractions (for doubly-constraining) are calculated by order.
	se_vectors = GetDataVectors(se_vw+"|", {"TAZ", "HH", "POP_HHS", "LOIND", "HIIND", "RTL", "HWY", "LOSVC", "HISVC", "OFFGOV", 
						"EDUC", "STU_K8", "STU_HS", "STU_CU", "MED_INC", "AREA", "TOTEMP", "STCNTY", "SEQ", "POP"},{{"Sort Order", {{"TAZ","Ascending"}}}})
	taz = se_vectors[1]
	hh = se_vectors[2]
	pophhs = se_vectors[3]
	loind = se_vectors[4]
	hiind = se_vectors[5]
	retail = se_vectors[6]
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
	pop = se_vectors[20]
	pop = max(pop, 1)
	k12enr = stuk8 + stuhs
	cbddum = if (taz = 10001 or taz = 10002 or taz = 10003 or taz = 10004 or taz = 10005 or taz = 10006 or taz = 10007 or taz = 10008 or taz = 10009 or 
			taz = 10010 or taz = 10011 or taz = 10012 or taz = 10013 or taz = 10014 or taz = 10015 or taz = 10016 or taz = 10017 or taz = 10018 or taz = 10019 or 
			taz = 10020 or taz = 10021 or taz = 10022 or taz = 10023 or taz = 10024 or taz = 10025 or taz = 10026 or taz = 10027 or taz = 10028 or taz = 10029 or
			taz = 10030 or taz = 10031 or taz = 10032 or taz = 10033 or taz = 10034 or taz = 10035 or 
			taz = 10052 or taz = 10086 or taz = 10116 or taz = 10117 or taz = 10118 or taz = 10119 or  
			taz = 10144 or taz = 10145 or taz = 10146 or taz = 10160 or taz = 10161 or taz = 10164 or taz = 10165 or taz = 10235) then 1 else 0
	ret = max(retail + hwy,1)
	nret = max(totemp - ret,1)
	retemp = retail + hwy
	dens = if (area * totemp * hh > 0) then 100 * log((1000 * totemp + 1900 * hh) / area) else 0		//density is in square miles
	empdens = totemp / (area * 640)		//employment per acre (area in sq. miles in SE file)


	dst2extsta = GetDataVector(distExtsta_vw+"|", "Len", {{"Sort Order", {{"From","Ascending"}}}}) 
	dst2cbd = GetDataVector(distCBD_vw+"|", "Len", {{"Sort Order", {{"From","Ascending"}}}}) 
	//to get rid of external stations:
	dim dist2extsta_ar[hh.length]
	dim dist2cbd_ar[hh.length]
	for i =  1 to hh.length do		//create a intracounty vector with all TAZs = 0 except for this TAZ (=1)
		dist2extsta_ar[i] = dst2extsta[i]
		dist2cbd_ar[i] = dst2cbd[i]
	end
	dist2extsta = a2v(dist2extsta_ar)
	dist2cbd = a2v(dist2cbd_ar)

	accfree_vectors = GetDataVectors(access_free+"|", {"EMPCMP15", "EMPT2CMP"},{{"Sort Order", {{"TAZ","Ascending"}}}}) 
	accE15cfr = accfree_vectors[1]
	accEt2cfr = accfree_vectors[2]

//Recalculate peak accessibility with updated (feedback) travel time
	//Open skims
	autopk = OpenMatrix(Dir + "\\Skims\\TThwy_peak.mtx", "False")			//open as memory-based
	matrix_indices = GetMatrixIndexNames(autopk)	
	for i = 1 to matrix_indices[1].length do
		if matrix_indices[1][i] = "Internals" then goto gotpkindex
	end
	int_pkindex = CreateMatrixIndex("Internals", autopk, "Both", se_vw+"|", "TAZ", "TAZ" )	//just internal zones
	gotpkindex:
	autopkcur = CreateMatrixCurrency(autopk, "TotalTT", "Rows", "Columns", )
	autopkintcur = CreateMatrixCurrency(autopk, "TotalTT", "Rows", "Internals", )
	autofree = OpenMatrix(Dir + "\\Skims\\TThwy_free.mtx", "False")			//open as memory-based
	matrix_indices = GetMatrixIndexNames(autofree)	
	for i = 1 to matrix_indices[1].length do
		if matrix_indices[1][i] = "Internals" then goto gotfreeindex
	end
	int_freeindex = CreateMatrixIndex("Internals", autofree, "Both", se_vw+"|", "TAZ", "TAZ" )	//just internal zones
	gotfreeindex:
	autofreecur = CreateMatrixCurrency(autofree, "TotalTT", "Rows", "Columns", )
	autofreeintcur = CreateMatrixCurrency(autofree, "TotalTT", "Internals", "Internals", )
	tranpk = OpenMatrix(Dir + "\\Skims\\TTTran_peak.mtx", "False")			//open as memory-based
	trpkcur = CreateMatrixCurrency(tranpk, "TTTranPk", "Rows", "Columns", )

	//Compute composite time (transit coefficients for each Income group: 1=0.15, 2=0.05, 3=0.05, 4=0.01, all=0.03) 
	comp_cores = {"comphwypk", "comptrpk", "comppeak"}
	CopyMatrixStructure({autopkcur}, {{"File Name", Dir + "\\tg\\composite_fb.mtx"}, 
			{"Label", "Composite Time"},
			{"File Based", "No"},
			{"Tables", comp_cores},
			})
	comp_mat = OpenMatrix(Dir + "\\tg\\composite_fb.mtx", "False")
	comp_array = CreateMatrixCurrencies(comp_mat, , , )
	comphwypk = comp_array.(comp_cores[1])
	comphwypk := 1 / autopkcur
	comptrpk = comp_array.(comp_cores[2])
	comptrpk := if (trpkcur = null) then 0 else 0.03 / trpkcur
	comppeak = comp_array.(comp_cores[3])
	comppeak := 1 / (comphwypk + comptrpk)

//	mat_cores = {"EmpCmp15", "EmpT2Cmp"} 

	//create new matrix to do calcs.  Accessibility is just for internal zones, so first create an internal zone index to copy from
	//Composite time internal indices for compfree and comppeak will also be used in Accessibility equations below
	
	matrix_indices = GetMatrixIndexNames(comp_mat)	
	for i = 1 to matrix_indices[1].length do
		if matrix_indices[1][i] = "Internals" then goto gotcompindex
	end
	int_index = CreateMatrixIndex("Internals", comp_mat, "Both", se_vw+"|", "TAZ", "TAZ" )	//just internal zones	gotpkindex:
	gotcompindex:
	comppeakintcur = CreateMatrixCurrency(comp_mat, "comppeak", "Internals", "Internals", )
	CopyMatrixStructure({comppeakintcur}, {{"File Name", Dir + "\\tg\\tour_access_calc_fb.mtx"}, 
			{"Label", "Tour Accessibility"},
			{"File Based", "No"},
			{"Tables", {"FillCore"}}})

	//Open matrix for filling, also calc length so can add records to Inc arrays	
	matcalcs = OpenMatrix(Dir + "\\tg\\tour_access_calc_fb.mtx", "False")

	//Employment within 15 min by composite time (EmpCmp15)
	fillmat = CreateMatrixCurrency(matcalcs, "FillCore", "Rows", "Columns", )
	fillmat := if (comppeakintcur = null) then 0 else if (comppeakintcur < 15) then 1 else 0	
	fillmat := fillmat * totemp
	accE15cpk = GetMatrixVector(fillmat, {{"Marginal","Row Sum"}})
	accE15cpk.rowbased = True

	// EMPT2Cmp (Emp/time^2)
	AddMatrixCore(comp_mat, "temp")
	tempfill = CreateMatrixCurrency(comp_mat, "temp", "Internals", "Internals", )
	MultiplyMatrixElements(tempfill, "comppeak", "comppeak", , , {{"Force Missing", "Yes"}})
	fillmat = CreateMatrixCurrency(matcalcs, "FillCore", "Rows", "Columns", )
	fillmat := if (tempfill = null) then 0 else tempfill
	fillmat := totemp / fillmat
	accEt2cpk = GetMatrixVector(fillmat, {{"Marginal","Row Sum"}})
	accEt2cpk.rowbased = True

	SetMatrixCore(comp_mat, "comppeak")
	DropMatrixCore(comp_mat, "temp")

//create currency for XI-Nonwork & ATW
	compfree = OpenMatrix(Dir + "\\tg\\composite.mtx", "False")
	compfreecur4 = CreateMatrixCurrency(compfree, "compfree4", "Rows", "Internals", )	//this matrix already has Internal index

	atype = GetDataVector(areatype+"|", "AREATYPE", {{"Sort Order", {{"TAZ","Ascending"}}}}) 

	hhbyincome_v = GetDataVectors(hhbyincome+"|", {"TAZ", "INC1", "INC2", "INC3", "INC4"},{{"Sort Order", {{"TAZ","Ascending"}}}}) 
	inc4 = hhbyincome_v[5]
	pct4 = if (hh = 0) then 0 else (inc4 / hh)

//Calculate attractions by tour purpose {order = HBW, ATW}.  Array {remain} is total attractions from which 1 will be removed after each tour to that destination zone.
	dim atfacta_ar[atype.length]
	dim atot[2]
	dim apurp[2]
	dim remain[2]
	dim sumattr[2]
	attr_v = {loind, hiind, retail, hwy, losvc, hisvc, offgov, educ, cbddum}

vws = GetViewNames()
for i = 1 to vws.length do
     CloseView(vws[i])
end

	//Attraction rate coeffs. 
	//	      HBW    ATW    
	loind_c =   {0.710, 0.000}		//loind
	hiind_c =   {0.710, 0.000}		//hiind
	retail_c =  {1.591, 0.553}		//offgov
	hwy_c =     {1.591, 0.000}		//pop
	losvc_c =   {0.597, 0.542}		//accH15
	hisvc_c =   {1.035, 0.000}		//distCBD
	offgov_c =  {0.597, 0.129}		//retail
	educ_c =    {1.035, 0.000}		//service
	cbd_c =     {649.0, 0.000}		//service
	arate =  {loind_c, hiind_c, retail_c, hwy_c, losvc_c, hisvc_c, offgov_c, educ_c, cbd_c}	

	//Attraction Area type factors. 
	//	    HBW    ATW    
	AT1_c =   {1.020, 1.100}	
	AT2_c =   {1.000, 1.000}
	AT3_c =   {0.990, 0.900}	
	AT4_c =   {1.000, 0.800}	
	AT5_c =   {1.020, 0.700}
	atfacta_c =  {AT1_c, AT2_c, AT3_c, AT4_c, AT5_c}	

	//Tour factors
	//	     HBW     ATW
	tourfac = {0.5749, 0.4155}
	
//Pull total number of productions for HBW & ATW
	prod_attr = OpenTable("prod_attr", "FFB", {DirArray + "\\Productions_Attractions.bin",})
	p_flds = {"P_HBW", "P_ATW"}
	p_vecs = GetDataVectors(prod_attr+"|", p_flds, )
	dim p_sums[2]
	for i = 1 to p_flds.length do
		p_sums[i] = VectorStatistic(p_vecs[i], "Sum", )
	end

//Calculate number of attractions
	for i = 1 to 2 do	//Loop on purposes (2)
		apurp[i] = Vector(hh.length, "short", {{"Constant", 0}})
		for j = 1 to atype.length do
			atfacta_ar[j] = atfacta_c[atype[j]][i]		//create a area type factor vector
		end
		atfacta = a2v(atfacta_ar)
		for j = 1 to 9 do	//9 (attraction rate coefficients)
			attrfill_v = if (totemp = 0) then 0 else r2i((attr_v[j] * arate[j][i]))		//For HBW, if no empl, then attr = 0
			apurp[i] = apurp[i] + attrfill_v
		end
//compare total attractions to total productions.  If not enough attractions, increase attractions so that there are 1% more attractions than productions.
		apurp[i] = r2i(max(apurp[i] * tourfac[i] * atfacta,0))
		apurp_sum = VectorStatistic(apurp[i], "Sum", )
		if (apurp_sum < p_sums[i]) then do
			apurp[i] = r2i((apurp[i] * (p_sums[i] / apurp_sum * 1.01) + 0.5))
		end
		remain[i] = apurp[i]
		sumattr[i] = Vector(hh.length, "short", {{"Constant", 0}})
		atot[i] = VectorStatistic(apurp[i], "Sum",)
		if i = 1 then do
			remain[i] = remain[i] 
		end
	end

//need to do the following steps in order to keep # of attractions by purpose constant
	hbwattr_ar = v2a(apurp[1])
	hbwattr = a2v(hbwattr_ar,)
	atwattr_ar = v2a(apurp[2])
	atwattr = a2v(atwattr_ar,)

//Create a temp file to do the probability sorting, and choice selection
	temp_prob = CreateTable("temp_prob", DirArray + "\\temp_prob.bin", "FFB", {{"TAZ1", "Integer", 10, null, "No"}, {"SEQ1", "Integer", 10, null, "No"}, 
				{"TAZ2", "Integer", 10, null, "No"}, {"SEQ2", "Integer", 10, null, "No"}, {"cumprob1", "Real", 10,8, "No"}, {"cumprob2", "Real", 10,8, "No"}})
	rh = AddRecords("temp_prob", null, null, {{"Empty Records", hh.length}})

	rmse_results = CreateTable("rmse_results", DirOutDC + "\\rmse_results_fb.bin", "FFB", {{"HBW_RMSE", "Real", 8, 2, "No"}, {"ATW_RMSE", "Real", 8, 2, "No"}}) 
	rmse_addrec = AddRecord("rmse_results", )

	//create a sequential vector to add to cumulative probability vector so that when it's sorted, the correct (first) TAZ is chosen
	aide_de_sort_vec = Vector(taz.length, "float", {{"Sequence", 0.001, 0.001}})

//******************************** HBW DESTINATION CHOICE ***************************************************************************************************************
  UpdateProgressBar("Destination Choice: HBW, Feedback Iter " + i2s(curiter), 10) 

//Open HBW tour II destination table and clear all destination fields and and all fields after PURP (20+)
	hbwdestii = OpenTable("hbwdestii", "FFB", {DirOutDC + "\\dcHBW.bin",})
	numrec = GetDataVector(hbwdestii+"|", "ID", )
	origtaz = GetDataVector(hbwdestii+"|", "ORIG_TAZ", )
	emp_v = Vector(numrec.length, "Short", )
	SetDataVectors(hbwdestii+"|", {{"DEST_TAZ", emp_v}, {"DEST_SEQ", emp_v}, {"OD_Time", emp_v}, {"DO_Time", emp_v}}, )	//clear out previous destinations and times

	fields_ar = GetFields("hbwdestii", null)
	num = fields_ar[1].length
	dim fieldnames[num] 
	for i = 1 to num do
		fieldnames[i] = fields_ar[1][i]
	end
	if num > 21 then do
		for i = 22 to fieldnames.length do
			SetDataVector(hbwdestii+"|", fieldnames[i], emp_v, )  //clear out all the other non-origin fields
		end
	end

//Add random number field to randomly sort by TAZ
	strct = GetTableStructure(hbwdestii)
	for j = 1 to (strct.length) do
 		strct[j] = strct[j] + {strct[j][1]}
 	end
	strct = strct + {{"tazrandnum", "Real", 10,8,,,,,,,,}}		
	ModifyTable(hbwdestii, strct)
	tazrandnum = Vector(numrec.length, "float", )

//Fill in random number for each TAZ set
//	rand_val = RandomNumber()
//	tazrandnum[1] = rand_val
SetRandomSeed(7)
	for n = 1 to numrec.length do
/*		if (origtaz[n] = origtaz[n-1]) then do
			tazrandnum[n] = tazrandnum[n-1]
		end
		else do
*/			rand_val = RandomNumber()
			tazrandnum[n] = rand_val
//		end
	end
	SetDataVector(hbwdestii+"|", "tazrandnum", tazrandnum,)

//Pull vectors sorted by randomized TAZ sets
	tourrecordset_v = GetDataVectors(hbwdestii+"|", {"TAZ", "TAZ_SEQ", "INCOME", "WRKRS", "tazrandnum"},{{"Sort Order", {{"tazrandnum","Ascending"},{"ID","Ascending"}}}}) 
	tourtazset = tourrecordset_v[1]
	tourtazseqset = tourrecordset_v[2]
	incset = tourrecordset_v[3]
	wrkrset = tourrecordset_v[4]
	tazrandnumset = tourrecordset_v[5]

	lasttaz = 0
	desttaz_v = Vector(numrec.length, "short", )
	desttazseq_v = Vector(numrec.length, "short", )
	odtime = Vector(numrec.length, "float", )
	dotime = Vector(numrec.length, "float", )
	
//Loop all tours
SetRandomSeed(8)
	for n = 1 to numrec.length do		
		thistaz = tourtazset[n]
		thistazseq = tourtazseqset[n]
		thiscnty = stcnty[thistazseq]
		thisAT = atype[thistazseq]
		intraco = if (stcnty = thiscnty) then 1 else 0
		intrazonal = if (taz <> thistaz) then 0 else if (thisAT = 1) then -0.7 else if (thisAT = 2) then 0.0 else if (thisAT < 5) then -2.0 else -0.3	//changed for validation
		if tourtazset[n] = lasttaz then do			//skip the probability array creation step if already been done for this TAZ
			goto skipprobhbw
		end
		htime = GetMatrixVector(autopkintcur, {{"Row", thistaz}})	//pull the TT vector for this TAZ from the peak speed matrix
		U1 = -0.06521*htime + 0.8109*intraco - 0.03048*cbddum - 0.001735*empdens + log(totemp) + 0.7*intrazonal  //calculate probability array -- U1 for Inc 1-3
		U2 = -0.04812*htime + 1.1500*intraco - 0.2652*cbddum - 0.0005294*empdens + log(totemp) + 0.7*intrazonal  //U2 for INC4
		fac = if (hbwattr > 0) then (remain[1] / hbwattr) else 0	//factor exp. utile by the ratio of remaining attrs to total attrs for this dest zone ([1] = HBW)
		eU1 = if (totemp = 0) then 0 else exp(U1) * fac
		eU2 = if (totemp = 0) then 0 else exp(U2) * fac						//zero out zones with no employment
		sumeU1 = VectorStatistic(eU1, "Sum",)
		sumeU2 = VectorStatistic(eU2, "Sum",)
		prob1 = eU1 / sumeU1
		prob2 = eU2 / sumeU2
		vecs1 = {prob1, taz, tazseq}
		cumprob1 = CumulativeVector(vecs1[1])		//cumulative sum of probabilities, not sorted
		cumprob1[U1.length] = 1
		vecs2 = {prob2, taz, tazseq}
		cumprob2 = CumulativeVector(vecs2[1])
		cumprob2[U1.length] = 1
		lasttaz = thistaz
		skipprobhbw:
		redo_randval_hbw:
		rand_val = RandomNumber()
		//redo if zero since dividing by zero below results in null ; redo if one since last element is defined as one from above, and will be choice whether or not it's eligible
		if (rand_val = 0 or rand_val = 1)  then do
			goto redo_randval_hbw
		end
		addnum = max(r2i(1/rand_val), 500)
		if (incset[n] <> 4) then do
			cumprob = cumprob1 / rand_val				//divide cumulative probabilities by random number; any number under 1.0 is not the chosen value and
			cumprob = if cumprob < 1.0 then addnum else cumprob		//is thus given a high number (100).  The first number greater than or equal to 1.0 is the chosen
			cumprob = cumprob + aide_de_sort_vec				//value, will be placed first in order in the sort, and is picked below:
			sorted_vecs = SortVectors({cumprob, vecs1[2], vecs1[3]})	
		end
		else do
			cumprob = cumprob2 / rand_val
			cumprob = if cumprob < 1.0 then addnum else cumprob
			cumprob = cumprob + aide_de_sort_vec
			sorted_vecs = SortVectors({cumprob, vecs2[2], vecs2[3]})			
		end
		desttaz_v[n] = sorted_vecs[2][1]
		desttazseq_v[n] = sorted_vecs[3][1]
		dest_tazseq = desttazseq_v[n]
		odtime[n] = GetMatrixValue(autopkintcur, i2s(thistaz), i2s(desttaz_v[n]))
		dotime[n] = GetMatrixValue(autopkintcur, i2s(desttaz_v[n]), i2s(thistaz))
		remain[1][dest_tazseq] = max(remain[1][dest_tazseq] - 1, 0)	//this removes one attraction from destination zone for each tour
		sumattr[1][dest_tazseq] = sumattr[1][dest_tazseq] + 1
	end
	SetDataVectors(hbwdestii+"|", {{"DEST_TAZ", desttaz_v}, {"DEST_SEQ", desttazseq_v}, {"OD_Time", odtime}, {"DO_Time", dotime}}, {{"Sort Order", {{"tazrandnum","Ascending"},{"ID","Ascending"}}}})
	
	sse = 0
	totattr = 0
	totsumattr = 0
	for i = 1 to hh.length do
		sse = sse + Pow((sumattr[1][i] - hbwattr[i]), 2)
		totattr = totattr + hbwattr[i]
		totsumattr = totsumattr + sumattr[1][i]
	end
	rmse = Sqrt(sse / hh.length)
	SetRecordValues("rmse_results", null, {{"HBW_RMSE", rmse}})
//reportfile = OpenFile(DirOutDC + "\\DC_report.txt","w")
//WriteLine(reportfile, "Tour Destination Choice Results")
//WriteLine(reportfile, "HBW RMSE = " + r2s(rmse))
	
//Remove all post-DC fields from the HBW II DC file.  
	hbw_fields = {"ID", "TAZ", "TAZ_SEQ", "SIZE", "INCOME", "LIFE", "WRKRS", "SCH", "HBU", "HBW", "HBS", "HBO", "ATW", "HHID", "ORIG_TAZ", "ORIG_SEQ", "DEST_TAZ", "DEST_SEQ", "OD_Time", "DO_Time", "PURP"}
	strct = GetTableStructure(hbwdestii)
	for j = 1 to (strct.length) do
 		strct[j] = strct[j] + {strct[j][1]}
 	end
	dim newstrct[hbw_fields.length]
	for j = 1 to hbw_fields.length do
		newstrct[j] = strct[j]
	end
	ModifyTable(hbwdestii, newstrct)
     CloseView("hbwdestii")

//************************************************************************

//We need to update the full ATW model, since the HBW destinations (and thus ATW origins) are changed above. However, since there aren't that many ATW external tours, the proportion
// of IX/XI tours at the external stations shouldn't be much effected.  Therefore, we're only re-doing the IX destination choice for ATW (not for the other purposes).  We do need to 
// redo the XI (both work and non-work) dc however.

//******* AT-WORK TOUR FREQUENCY *********** AT-WORK TOUR FREQUENCY *********** AT-WORK TOUR FREQUENCY *********** AT-WORK TOUR FREQUENCY ***********
atwdc:
  UpdateProgressBar("Destination Choice: At-Work Tour Frequency, Feedback Iter " + i2s(curiter), 10) 

hbwdestii = OpenTable("hbwdestii", "FFB", {DirOutDC + "\\dcHBW.bin",})

//Alternative percentages: 0 tours = 94.1%, 1 tour = 5.3%, 2 tours = 0.6%, 3 tours = ___%, 4 tours = ___%

//Uses the HBW DC I-I output file (hbwdestii) as the input for this step.  Sort the vectors by HHID.
//	SetView("hbwdestii")
	hbwoutfile_v = GetDataVectors(hbwdestii+"|", {"ID", "TAZ", "TAZ_SEQ", "SIZE", "INCOME", "LIFE", "WRKRS", "HHID", "DEST_TAZ", "DEST_SEQ"},{{"Sort Order", {{"HHID","Ascending"}}}})
	idhbwout = hbwoutfile_v[1]
	tazhbwout = hbwoutfile_v[2]
	taz_seqhbwout = hbwoutfile_v[3]
	inchbwout = hbwoutfile_v[5]
	wkrhbwout = hbwoutfile_v[7]
	dest = hbwoutfile_v[9]
	destseq = hbwoutfile_v[10]
	inc4hbwout = if (inchbwout = 4) then 1 else 0

//Get median income of HBW tour origin(home) zone & hh density of HBW destination (work) zone.
	dim medincval[idhbwout.length]
	dim areaval[idhbwout.length]
	dim hhval[idhbwout.length]
	dim accE15cfr_ar[idhbwout.length]
	for n = 1 to idhbwout.length do
		origtaz = taz_seqhbwout[n]
		desttaz = dest[n]			
		if origtaz = prevtaz then do
			medincval[n] = medincval[n-1]
			hhval[n] = hhval[n-1] 
			areaval[n] = areaval[n-1]
			accE15cfr_ar[n] = accE15cfr_ar[n-1]
		end
		else do
			medincval[n] = medinc[taz_seqhbwout[n]]
			hhval[n] = hh[destseq[n]]
			areaval[n] = area[destseq[n]]
			accE15cfr_ar[n] = accE15cfr[taz_seqhbwout[n]]
		end
		prevtaz = origtaz
	end
	medinchbwout = a2v(medincval)
	hhhbwout = a2v(hhval)
	areahbwout = a2v(areaval)
	hhdenshbwout = hhhbwout / (areahbwout * 640)		//SE file has area in SqMiles, needs to be in acres
	accE15cfr_v = a2v(accE15cfr_ar)
	
	U1 = -2.659 - 0.3166 * wkrhbwout + 0.000003801 * medinchbwout + 0.7615 * inc4hbwout + 0.03204 * hhdenshbwout

	E2U0 = Vector(idhbwout.length, "float", {{"Constant", 1}})
	E2U1 = exp(U1)						//Initial alternatives are 0, 1+ HBU tours
	E2U_cum = E2U0 + E2U1

	prob0 = E2U0 / E2U_cum
	prob1 = E2U1 / E2U_cum

	lowprobalt = if (prob0 < prob1) then 0 else 1		//Do the sorting in vectors (simple here because only 2 choices)
	hiprobalt = if (lowprobalt = 0) then 1 else 0
	lowprob = if (lowprobalt = 0) then prob0 else prob1
	hiprob = if (lowprobalt = 0) then prob1 else prob0

	dim choice[idhbwout.length]
SetRandomSeed(67)
	for n = 1 to idhbwout.length do
		rand_val = RandomNumber()
		choice[n] = if (rand_val < lowprob[n]) then lowprobalt[n] else hiprobalt[n]
//The 1+ categories are 1 (89.8% of all 1+ tours) & 2 (10.2%) 
		if (choice[n] > 0) then do
			rand_val = RandomNumber()
			choice[n] = if (rand_val < 0.898) then 1 else 2
		end
	end
	atw_v = a2v(choice)

	SetDataVector(hbwdestii+"|", "ATW", atw_v,{{"Sort Order", {{"HHID","Ascending"}}}})
	
//********************************* ATW DESTINATION CHOICE (Actually, just creating ATW files by internal and external **********************************************
  UpdateProgressBar("Destination Choice: ATW File Setup, Feedback Iter " + i2s(curiter), 10) 

//This is the first run of the ATW DC model.  It does not include the X/I non-resident workers yet.
// 9/16 edit, MK; don't do destination choice at this point since we're going to redo it later in the macro after the HBW-ATWs and XIW-ATWs have been merged

//Create ATW tour II & IX destination tables (copied for previous iteration above)

	strct = GetTableStructure(hbwdestii)
	for j = 1 to strct.length do
 		strct[j] = strct[j] + {strct[j][1]}
 	end
	strct = strct + {{"HBWID", "Integer", 6,,,,,,,,,}}
	atwdestii = CreateTable("atwdestii", DirOutDC + "\\dcATW.bin", "FFB", strct)
	atwdestix = CreateTable("atwdestix", DirOutDC + "\\dcATWext.bin", "FFB", strct)
	
//Calculate probability that tour from this origin, for this purpose, is I/X
	pEXT = min(3.6 * 0.29 * Pow(dist2extsta, -1.33), 0.30)

/*mk: don't need to sort by random number here since all we're doing is dividing into external and internal files
	dim atwrandval[atwsort.length]
	rand_val = RandomNumber()
	atwrandval[1] = rand_val
	for n = 2 to atwsort.length do
		if (atwsort[n] = atwsort[n-1]) then do
			atwrandval[n] = atwrandval[n-1]
		end
		else do
			rand_val = RandomNumber()
			atwrandval[n] = rand_val
		end
	end
	atwrandval_v = a2v(atwrandval)
	SetDataVector(hbwdestii+"|havetours", "tazrandnum", atwrandval_v,{{"Sort Order", {{"DEST_SEQ","Ascending"}}}})
*/
//Pull vectors from HBW-II output file (which now has # of ATW tours)
	qry = "Select * where ATW > 0"
	SetView("hbwdestii")
	havetours = SelectByQuery("havetours", "Several", qry)
	SortSet("havetours", "DEST_SEQ, HHID")					//sort by HBW destination zone (which for ATW is origin zone)
	atwrecordset_v = GetDataVectors(hbwdestii+"|havetours", {"ID", "TAZ", "TAZ_SEQ", "SIZE", "INCOME", "LIFE", "WRKRS", "SCH", "HBU", "HBW", "HBS", "HBO", "ATW", "HHID", "DEST_TAZ", "DEST_SEQ"},) 
	hbwidset = atwrecordset_v[1]		//Here the household ID is found in the HHID field from hbwdestii
	hometazset = atwrecordset_v[2]
	hometazseqset = atwrecordset_v[3]
	sizeset = atwrecordset_v[4]
	incset = atwrecordset_v[5]
	lcset = atwrecordset_v[6]
	wrkrsset = atwrecordset_v[7]
	schtoursset = atwrecordset_v[8]
	hbutoursset = atwrecordset_v[9]
	hbwtoursset = atwrecordset_v[10]
	hbstoursset = atwrecordset_v[11]
	hbotoursset = atwrecordset_v[12]
	atwtoursset = atwrecordset_v[13]
	hhidset = atwrecordset_v[14]		//Here the household ID is found in the HHID field from hbwdestii
	atwtazset = atwrecordset_v[15]
	atwtazseqset = atwrecordset_v[16]

	iitourid = 0
	ixtourid = 0

//Loop all tours
SetRandomSeed(3)
	for n = 1 to hhidset.length do				//hhidset.length	
		if atwtoursset[n] = 0 then do			//go to next record if there are no ATW tours
			goto noatwtours
		end
		for i = 1 to atwtoursset[n] do
			rand_val = RandomNumber()
			if pEXT[atwtazseqset[n]] > rand_val then do	//create a record for this tour if it is IX
				ixtourid = ixtourid + 1
				filltable = AddRecord("atwdestix", {{"ID", ixtourid}, {"HHID", hhidset[n]}, {"TAZ", hometazset[n]}, {"TAZ_SEQ", hometazseqset[n]}, {"SIZE", sizeset[n]}, {"INCOME", incset[n]}, 
							{"LIFE", lcset[n]}, {"WRKRS", wrkrsset[n]}, {"SCH", schtoursset[n]}, {"HBU", hbutoursset[n]}, {"HBW", hbwtoursset[n]}, {"HBS", hbstoursset[n]}, 
							{"HBO", hbotoursset[n]}, {"ATW", atwtoursset[n]}, {"HBWID", hbwidset[n]}, {"ORIG_TAZ", atwtazset[n]}, {"ORIG_SEQ", atwtazseqset[n]}, {"PURP", "ATW"}})
			end
			else do
				iitourid = iitourid + 1
				filltable = AddRecord("atwdestii", {{"ID", iitourid}, {"HHID", hhidset[n]}, {"TAZ", hometazset[n]}, {"TAZ_SEQ", hometazseqset[n]}, {"SIZE", sizeset[n]}, {"INCOME", incset[n]}, 
							{"LIFE", lcset[n]}, {"WRKRS", wrkrsset[n]}, {"SCH", schtoursset[n]}, {"HBU", hbutoursset[n]}, {"HBW", hbwtoursset[n]}, {"HBS", hbstoursset[n]}, 
							{"HBO", hbotoursset[n]}, {"ATW", atwtoursset[n]}, {"HBWID", hbwidset[n]}, {"ORIG_TAZ", atwtazset[n]}, {"ORIG_SEQ", atwtazseqset[n]}, {"PURP", "ATW"}})
			end
		end
		noatwtours:
	end

//********************************* ATW I/X DESTINATION CHOICE ************************************************************************************************************
  UpdateProgressBar("Destination Choice: ATW_IX, Feedback Iter " + i2s(curiter), 10) 

//Not worrying about constraints here, due to the very low number of ATW_IX tours
	extstavoltab = OpenTable("extstavoltab", "FFA", {Dir + "\\Ext\\EXTSTAVOL" + yr_str + ".asc",})
	extstavol_v = GetDataVectors(extstavoltab+"|", {"MODEL_STA", "TOT_AUTO"},{{"Sort Order", {{"MODEL_STA","Ascending"}}}})
	extsta = extstavol_v[1]
	extstavol = extstavol_v[2]
	extstaseq = Vector(extsta.length, "short", {{"Sequence", 1, 1}}) 

//Sort the ATW_IX table by origin TAZ
	qry = "Select * where ID > 0"
	SetView("atwdestix")
	sortedtab = SelectByQuery("sortedtab", "Several", qry)
	SortSet("sortedtab", "ORIG_TAZ, ID")					//sort by HBW destination zone (which for ATW is origin zone)
	ixrecordset_v = GetDataVectors(atwdestix+"|sortedtab", {"ORIG_TAZ", "ORIG_SEQ"},) 
	origtaz = ixrecordset_v[1]		
	origtazseq = ixrecordset_v[2]		
	result_v = Vector(origtaz.length, "long", )

//Create a temp file to do the probability sorting, and choice selection
	temp_ix_prob = CreateTable("temp_ix_prob", DirOutDC + "\\temp_ix_prob.bin", "FFB", {{"ORIG_TAZ", "Integer", 10, null, "No"}, {"ORIG_SEQ", "Integer", 10, null, "No"}, {"cumprob", "Real", 10,8, "No"}})
	rh = AddRecords("temp_ix_prob", null, null, {{"Empty Records", extstavol.length}})

	dim htime_ar[extstavol.length]
	extsta_val = Vector(origtaz.length, "short", )
	extstaseq_val = Vector(origtaz.length, "short", )
	remain_extstavol = Vector(origtaz.length, "short", )
	lasttaz = 0
	odtime_v = Vector(origtaz.length, "float", )
	dotime_v = Vector(origtaz.length, "float", )

SetRandomSeed(6645)
	for n = 1 to origtaz.length do		//origtaz.length			
		if origtaz[n] = lasttaz then do			//skip the probability array creation step if already been done for this TAZ
			goto skipprobix
		end
		htimeplus = GetMatrixVector(autofreecur, {{"Row", origtaz[n]}})	//pull the TT vector for this TAZ from the free speed matrix
		counter = 1
		for i = (hh.length + 1) to htimeplus.length do	
			htime_ar[counter] = htimeplus[i]				//to keep only the external stations
			counter = counter + 1
		end
		htime = a2v(htime_ar)
		U = -0.08577 * htime + log(extstavol)		//calculate probability array (just done for first HH in this TAZ) 
		eU = if (extstavol = 0) then 0 else exp(U)
		sumeU = VectorStatistic(eU, "Sum",)
		prob = eU / sumeU
		vecs = {prob, extsta, extstaseq}
		cumprob1 = CumulativeVector(vecs[1])
		cumprob1[U.length] = 1

//Don't need to loop on the number of tours.  Here, each input record represents one tour.
		skipprobix:
		rand_val = RandomNumber()
		cumprob = cumprob1 / rand_val
		cumprob = if cumprob < 1.0 then 100 else cumprob
		sorted_vecs = SortVectors({cumprob, vecs[2], vecs[3]})				
		extsta_val[n] = sorted_vecs[2][1]
		extstaseq_val[n] = sorted_vecs[3][1]
		odtime_v[n] = GetMatrixValue(autofreecur, i2s(origtaz[n]), i2s(extsta_val[n]))
		dotime_v[n] = GetMatrixValue(autofreecur, i2s(extsta_val[n]), i2s(origtaz[n]))
		remain_extstavol[extstaseq_val[n]] = max(remain_extstavol[extstaseq_val[n]] - 1, 1.0)
		lasttaz = origtaz[n]
	end
	SetDataVectors(atwdestix+"|", {{"DEST_TAZ", extsta_val}, {"DEST_SEQ", extstaseq_val}, {"OD_Time", odtime_v}, {"DO_Time", dotime_v}}, {{"Sort Order", {{"ORIG_TAZ","Ascending"},{"ID","Ascending"}}}})
	
//******************************** APPEND ATW_I/X TOUR FILE to TOTAL I/X Tour File (remove old ATW records first) *************************************************
  UpdateProgressBar("Destination Choice: Append ATW_IX, Feedback Iter " + i2s(curiter), 10) 

//Remove old ATW records from dcEXT file
	mergedix = OpenTable("mergedix", "FFB", {DirOutDC + "\\dcEXT.bin",})
	qry = "Select * where PURP = 'ATW'"
	SetView("mergedix")
	n = SelectByQuery("oldatwrecs", "Several", qry)
	if n > 0 then DeleteRecordsInSet("oldatwrecs")
//merge new ATW_IX table (with destination choice values which were found above) to dcEXT
	fields_ar = GetFields("atwdestix", null)
	num = fields_ar[1].length - 1	//the last field in the atwdestix table is "HBWID", which is not included in the dcEXT.bin table
	dim fieldnames[num] 
	for i = 1 to num do
		fieldnames[i] = fields_ar[1][i]
	end
	rh = GetFirstRecord("atwdestix|", {{"ID", "Ascending"}})
	vals = GetRecordsValues("atwdestix|", rh, null, null, null, "Row", null)
	filltable = AddRecords("mergedix", fieldnames, vals, null)

	id_v = GetDataVector(mergedix+"|", "ID",)
	new_id_v = Vector(id_v.length, "long", {{"Sequence", 1,1}})
	SetDataVector(mergedix+"|", "ID", new_id_v,)
	
//********************************* SUMMARIZE I/X TOURS ***********************************************************************************************

//Sum total I/X round-trip tours by external station
	dim pcix_ar[extsta.length]
	for n =  1 to extsta.length do
		qry = "Select * where DEST_TAZ = " + i2s(extsta[n])
		SetView("mergedix")
		pcix_ar[n] = SelectByQuery("ixsta_count", "Several", qry)
	end
	pcix = a2v(pcix_ar, {{"Type", "Long"}})
		
	
//********************************* REMOVE POST-DC FIELDS FROM I/X TABLE **********************************************************************************************

//Remove all post-DC fields from the I/X table  
	ix_fields = {"ID", "TAZ", "TAZ_SEQ", "SIZE", "INCOME", "LIFE", "WRKRS", "SCH", "HBU", "HBW", "HBS", "HBO", "ATW", "HHID", "ORIG_TAZ", "ORIG_SEQ", "DEST_TAZ", "DEST_SEQ", "OD_Time", "DO_Time", "PURP"}
	strct = GetTableStructure(mergedix)
	for j = 1 to (strct.length) do
 		strct[j] = strct[j] + {strct[j][1]}
 	end
	dim newstrct[ix_fields.length]
	for j = 1 to ix_fields.length do
		newstrct[j] = strct[j]
	end
	ModifyTable(mergedix, newstrct)
     CloseView("mergedix")
	
//********************************* CALCULATE X/I TOURS ***********************************************************************************************
  UpdateProgressBar("Destination Choice: X/I", 10) 

//Open table containing PC X/X trip ends (calculated in Tour_XX.rsc
	xxvoltab = OpenTable("xxvoltab", "FFA", {DirArray + "\\thruvol.asc",})	
	pcxx = GetDataVector(xxvoltab+"|", "auto",{{"Sort Order", {{"MODEL_STA","Ascending"}}}})

//Multiply I/X tour ends by 2 to convert from tours to trips and divide by 1.375 to convert from person travel to vehicle travel.  [WGA] already checked and
// the result of this equation is non-negative for all stations in 2010. Analysis of 2014 external survey data said that 44% of the X/I passenger car
// trips are for work.  Apply that percentage here.  

	pcxi = (extstavol - pcxx - (2*pcix)/1.375)/2
	wrk = r2i(round(0.44 * pcxi,0))
	nwrk = r2i(round(pcxi - wrk,0))
	wrk = max(wrk,0)		//just in case you get a negative -- maybe can update???
	nwrk = max(nwrk,0)	

//Do 2 loops on stations to convert the aggregate X/I totals by station into individual tour records.  Write out 1 record per tour
	totwrk = r2i(VectorStatistic(wrk, "Sum",))
	totnwrk = r2i(VectorStatistic(nwrk, "Sum",))
	xiwrk = Vector(totwrk,"Long",)
	xiwrkid = Vector(totwrk,"Long",{{"Sequence", 1, 1}})
	xinwrk = Vector(totnwrk,"Long",)
	xinwrkid = Vector(totnwrk,"Long",{{"Sequence", 1, 1}})
	extsta_w_seq = Vector(totwrk,"Short",)
	extsta_n_seq = Vector(totnwrk,"Short",)

	xidestwrk = CreateTable("xidestwrk", DirOutDC + "\\dcXIW.bin", "FFB", {{"ID", "Integer", 6, null, "Yes"},{"ORIG_TAZ", "Integer", 5, null,},{"ORIG_SEQ", "Integer", 3, null,},
										{"DEST_TAZ", "Integer", 5, null,},{"DEST_SEQ", "Integer", 5, null,},{"OD_Time", "Real", 8, 2,},{"DO_Time", "Real", 8, 2,},{"ATW", "Integer", 1, null,}})
	rh = AddRecords("xidestwrk", null, null, {{"Empty Records", totwrk}})
	xidestnwrk = CreateTable("xidestnwrk", DirOutDC + "\\dcXIN.bin", "FFB", {{"ID", "Integer", 6, null, "Yes"},{"ORIG_TAZ", "Integer", 5, null,},{"ORIG_SEQ", "Integer", 3, null,},
										{"DEST_TAZ", "Integer", 5, null,},{"DEST_SEQ", "Integer", 5, null,},{"OD_Time", "Real", 8, 2,},{"DO_Time", "Real", 8, 2,}})
	rh = AddRecords("xidestnwrk", null, null, {{"Empty Records", totnwrk}})
	wrkcounter = 1
	nwrkcounter = 1
	for n = 1 to extsta.length do
		if wrk[n] > 0 then do
			for i = 1 to wrk[n] do
				xiwrk[wrkcounter] = extsta[n]
				extsta_w_seq[wrkcounter] = n
				wrkcounter = wrkcounter + 1
			end
		end
		if nwrk[n] > 0 then do
			for i = 1 to nwrk[n] do
				xinwrk[nwrkcounter] = extsta[n]
				extsta_n_seq[nwrkcounter] = n
				nwrkcounter = nwrkcounter + 1
			end
		end
	end
	SetDataVectors(xidestwrk+"|", {{"ID", xiwrkid}, {"ORIG_TAZ", xiwrk}, {"ORIG_SEQ", extsta_w_seq}}, )
	SetDataVectors(xidestnwrk+"|", {{"ID", xinwrkid}, {"ORIG_TAZ", xinwrk}, {"ORIG_SEQ", extsta_n_seq}}, )

//********************************* X/I WORK DESTINATION CHOICE **********************************************************************************************************

	lasttaz = 0

//Loop all tours
SetRandomSeed(5564)
	for n = 1 to totwrk do					
		if xiwrk[n] = lasttaz then do			//skip the probability array creation step if already been done for this TAZ
			goto skipprobxiw
		end
		htime = GetMatrixVector(autopkintcur, {{"Row", xiwrk[n]}})	//pull the TT vector for this TAZ from the free speed matrix

/* 	  Calculate utility & probability.  This is the HBW model, minus the INTRACO term, which cannot be calculated.  Use the high income model 
	  only.  Not trying to match attractions for this purpose.  Tweak HTIME coefficient to match external survey average trip length. (original HBW value: -0.07360)
*/		U = -0.07185*htime + 1.102*cbddum - 0.00000001031*accE15cpk + log(ret + 1.8556*nret) + 0.1*cbddum	//calculate probability array (just done for first HH in this TAZ) 
		eU = exp(U)
		sumeU = VectorStatistic(eU, "Sum",)
		prob = eU / sumeU
		vecs = {prob, taz, tazseq}
		cumprob1 = CumulativeVector(vecs[1])
		cumprob1[U.length] = 1
		lasttaz = xiwrk[n]
		skipprobxiw:
		redo_randval_xiw:
		rand_val = RandomNumber()
		if (rand_val = 0 or rand_val = 1)  then do
			goto redo_randval_xiw
		end
		addnum = max(r2i(1/rand_val), 500)
		cumprob = cumprob1 / rand_val
		cumprob = if cumprob < 1.0 then addnum else cumprob
		cumprob = cumprob + aide_de_sort_vec
		sorted_vecs = SortVectors({cumprob, vecs[2], vecs[3]})				
		dest_taz = sorted_vecs[2][1]
		dest_tazseq = sorted_vecs[3][1]
		odtime = GetMatrixValue(autopkcur, i2s(xiwrk[n]), i2s(dest_taz))
		dotime = GetMatrixValue(autopkcur, i2s(dest_taz), i2s(xiwrk[n]))
		SetRecordValues("xidestwrk", i2s(n), {{"DEST_TAZ", dest_taz}, {"DEST_SEQ", dest_tazseq}, {"OD_Time", odtime}, {"DO_Time", dotime}})		
	end
	
	//fill assigned XIW tours into productions_attractions table
	jointab = JoinViews("jointab", "prod_attr.TAZ", "xidestwrk.DEST_TAZ", {{"A",}})
	attv = GetDataVector(jointab+"|", "[N xidestwrk]", )
	SetDataVector(prod_attr+"|", "DC_XIW", attv, )
	CloseView("jointab")

//********************************* X/I NON-WORK DESTINATION CHOICE ******************************************************************************************************

	lasttaz = 0

//Loop all tours
SetRandomSeed(70)
	for n = 1 to totnwrk do					
		if xinwrk[n] = lasttaz then do			//skip the probability array creation step if already been done for this TAZ
			goto skipprobxinw
		end
		ctime = GetMatrixVector(compfreecur4, {{"Row", xinwrk[n]}})	//pull the TT vector for this TAZ from the offpeak composite speed matrix based on income group 4
/*		Calculate utility & probability.  This is the HBO model, minus the SAMEAT term, which cannot be calculated.  Use the high income 
		model only.  Not trying to match attractions for this purpose.  Tweak CTIME coefficient to match external survey average trip length.(original HBO value: -0.2324)
*/		U = -0.2453*ctime - 0.4178*atype + 0.02397*dist2cbd - 0.000000015*accE15cfr + 1.128*pct4 + log(totemp + 0.109481*pop) + 0.5*cbddum	//calculate probability array (just done for first HH in this TAZ)
		eU = exp(U)
		sumeU = VectorStatistic(eU, "Sum",)
		prob = eU / sumeU
		vecs = {prob, taz, tazseq}
		cumprob1 = CumulativeVector(vecs[1])
		cumprob1[U.length] = 1
		lasttaz = xinwrk[n]
		skipprobxinw:
		redo_randval_xinw:
		rand_val = RandomNumber()
		if (rand_val = 0 or rand_val = 1)  then do
			goto redo_randval_xinw
		end
		addnum = max(r2i(1/rand_val), 500)
		cumprob = cumprob1 / rand_val
		cumprob = if cumprob < 1.0 then addnum else cumprob
		cumprob = cumprob + aide_de_sort_vec
		sorted_vecs = SortVectors({cumprob, vecs[2], vecs[3]})				
		dest_taz = sorted_vecs[2][1]
		dest_tazseq = sorted_vecs[3][1]
		odtime = GetMatrixValue(autofreecur, i2s(xinwrk[n]), i2s(dest_taz))
		dotime = GetMatrixValue(autofreecur, i2s(dest_taz), i2s(xinwrk[n]))
		SetRecordValues("xidestnwrk", i2s(n), {{"DEST_TAZ", dest_taz}, {"DEST_SEQ", dest_tazseq}, {"OD_Time", odtime}, {"DO_Time", dotime}})		//, {"PURP"}})
	end
	
	//fill assigned XIN tours into productions_attractions table
	jointab = JoinViews("jointab", "prod_attr.TAZ", "xidestnwrk.DEST_TAZ", {{"A",}})
	attv = GetDataVector(jointab+"|", "[N xidestnwrk]", )
//	SetDataVector(prod_attr+"|", "DC_XIN", attv, )			//FIX!!
	CloseView("jointab")
	

//************************** APPLY ATW TOUR FREQUENCY TO X/I WORKERS *****************************************************************************************************

//This step tells us how often the non-resident workers make ATW tours while at work.

	inc4dum = 1					//income 4 dummy: let's assume that all of the X/I workers are inc 4
//	hhdens = if (area > 0) then (hh / area) else 0
	med_incdum = 58066		//We don't know the "home zone median income" value for non-residents, so use the 2010 Metrolina mean zonal value of $58,066, calculated from the 2010 S/E file
	wrkdum = 1.56		//We don't know the workers/HH for non-residents, so use the average value for Metrolina in 2010, calculated by the HH synthesis model. Because we 
				//have an X/I work trip, we know there must be at least one worker in the HH, so exclude the zero-worker HHs in this calculation = 976,538 workers / (833,570 - 206,937 HH).
	
	desttazseq_v = GetDataVector(xidestwrk+"|", "DEST_SEQ",) 
	dim areaval[totwrk]
	dim hhval[totwrk]
	dim accE15cfr_ar[totwrk]
	origtaz = 0
	for n = 1 to totwrk do
		hhval[n] = hh[desttazseq_v[n]]
		areaval[n] = area[desttazseq_v[n]]
		accE15cfr_ar[n] = accE15cfr[desttazseq_v[n]]
	end
	hhout = a2v(hhval)
	areaout = a2v(areaval)
	accE15cfr_v = a2v(accE15cfr_ar)
	hhdens = hhout / (areaout * 640)		//SE file has area in SqMiles, needs to be in acres

	U1 = -2.659 - 0.3166*wrkdum + 0.000003801*med_incdum + 0.7615*inc4dum + 0.03204*hhdens	// Use the accessibility of the workplace zone.

	E2U0 = Vector(totwrk, "float", {{"Constant", 1}})
	E2U1 = exp(U1)						//Initial alternatives are 0, 1+ X/I ATW tours
	E2U_cum = E2U0 + E2U1

	prob0 = E2U0 / E2U_cum
	prob1 = E2U1 / E2U_cum

	choice_v = Vector(totwrk, "short", {{"Constant", 0}})	//reset choice vector to 0 tours

//Do a big loop in order to sort each HH's alternatives by ascending probability.  
SetRandomSeed(89)
	for n = 1 to totwrk do
		rand_val = RandomNumber()
		//if probability of 1 HBU tour is less than random number then 0 tours, else use 1+ fractions:
		//The 1+ categories are 1 (89.8% of all 1+ tours) & 2 (10.2%)
		if (rand_val >= prob0[n]) then do
			rand_val = RandomNumber()
			choice_v[n] = if (rand_val < 0.898) then 1 else 2
		end
	end
	atw_v = choice_v

	SetDataVector(xidestwrk+"|", "ATW", atw_v,)

//************************** MERGE RESIDENT & NON-RESIDENT WORKER ATW RECORDS ********************************************************************************************

	recnum = GetDataVector(atwdestii+"|", "ID",) 	//just to get the number of II ATW records

//select only tours from XI-Work table that have ATW tours
	qry = "Select * where ATW > 0"
	SetView("xidestwrk")
	newidnum = recnum.length + 1
	atwtours = SelectByQuery("atwtours", "Several", qry)
	SortSet("atwtours", "DEST_SEQ")
	exsta_recs = GetDataVector(xidestwrk+"|atwtours", "ORIG_TAZ",) 	
	desttaz_recs = GetDataVector(xidestwrk+"|atwtours", "DEST_TAZ",) 	
	destseq_recs = GetDataVector(xidestwrk+"|atwtours", "DEST_SEQ",) 	
	atwnum_recs = GetDataVector(xidestwrk+"|atwtours", "ATW",) 	

//For the X/I non-resident work records, we have no information about the traveller or his HH.  Fortunately, the ATW DC model does not need any data on the
// traveller or his HH. Move the external station to TAZ and the workplace to ORIG, then zero out DEST.

	for n = 1 to atwtours do
		filltable = AddRecord("atwdestii", {{"ID", newidnum}, {"TAZ", exsta_recs[n]}, {"ORIG_TAZ", desttaz_recs[n]}, {"ORIG_SEQ", destseq_recs[n]}})
		if (atwnum_recs[n] = 2) then do
			newidnum = newidnum + 1
			filltable = AddRecord("atwdestii", {{"ID", newidnum}, {"TAZ", exsta_recs[n]}, {"ORIG_TAZ", desttaz_recs[n]}, {"ORIG_SEQ", destseq_recs[n]}})
		end
		newidnum = newidnum + 1
	end
		
	ii = recnum.length
	ix = VectorStatistic(atwnum_recs, "Sum", )
	totatw = r2i(ii + ix)

//********************************* RE-APPLY ATW DESTINATION CHOICE ******************************************************************************************************

//This is the second run of the ATW DC model.  It now includes the X/I non-resident workers.

//Add random number field to merged ATW table, then sort it on the randomized workplace zone.

	strct = GetTableStructure(atwdestii)
	for j = 1 to strct.length do
 		strct[j] = strct[j] + {strct[j][1]}
 	end
	strct = strct + {{"tazrandnum", "Real", 10,8,,,,,,,,}}
	ModifyTable(atwdestii, strct)
	
	atwdestii = OpenTable("atwdestii", "FFB", {DirOutDC + "\\dcATW.bin"}, {{"Shared", "False"}})

	qry = "Select * where ID > 0"
	SetView("atwdestii")
	havetours = SelectByQuery("havetours", "Several", qry)
	SortSet("havetours", "ORIG_SEQ")					
	tazsort_v = GetDataVector(atwdestii+"|havetours", "ORIG_SEQ",{{"Sort Order", {{"ORIG_SEQ","Ascending"}}}}) 
	dim atwrandval[tazsort_v.length]
//	rand_val = RandomNumber()
//	atwrandval[1] = rand_val
SetRandomSeed(527)
	for n = 1 to tazsort_v.length do
/*		if (tazsort_v[n] = tazsort_v[n-1]) then do
			atwrandval[n] = atwrandval[n-1]
		end
		else do
*/			rand_val = RandomNumber()
			atwrandval[n] = rand_val
//		end
	end
	atwrandval_v = a2v(atwrandval)
	SetDataVector(atwdestii+"|havetours", "tazrandnum", atwrandval_v,{{"Sort Order", {{"ORIG_SEQ","Ascending"}}}}) 
//now sort by random number
	SetView("atwdestii")
	sorted = SelectByQuery("sorted", "Several", qry)
	SortSet("sorted", "tazrandnum")					
	tourrecordset_v = GetDataVectors(atwdestii+"|", {"ORIG_TAZ","ORIG_SEQ","tazrandnum"} ,{{"Sort Order", {{"tazrandnum","Ascending"}}}}) 
	tourtazset = tourrecordset_v[1]
	tourtazseqset = tourrecordset_v[2]

	lasttaz = 0
	dim ctime_ar[hh.length]
	dim dest_taz[tourtazset.length]
	dim dest_tazseq[tourtazset.length]
	odtime_v = Vector(tourtazset.length, "float", )
	dotime_v = Vector(tourtazset.length, "float", )

//Must increase the number of ATW trip ends, to account for the non-resident workers. Use the "ii" and "xi" variables computed in the previous step.  
	tend = atwattr * (ii + ix) / ii
	remain_v = tend
//reset sum of ATW attractions for each zone to zero 
	sumattr[2] = Vector(hh.length, "short", {{"Constant", 0}})

//Loop all tours
SetRandomSeed(43)
	for n = 1 to tourtazset.length do				
		thistaz = tourtazset[n]
		if thistaz = lasttaz then do			//skip the probability array creation step if already been done for this TAZ
			goto skipprobatwiiix
		end
		thistazseq = tourtazseqset[n]
		thiscnty = stcnty[thistazseq]
		thisAT = atype[thistazseq]
		intraco = if (stcnty = thiscnty) then 1 else 0
		intrazonal = if (taz <> thistaz) then 0 else if (thisAT < 3) then 0.8 else if (thisAT < 5) then 2.0 else 1.0	//changed for validation
		ctime = GetMatrixVector(compfreecur4, {{"Row", thistaz}})	//pull the TT vector for this TAZ from the free speed matrix
		U = -0.3148*ctime - 0.3274*atype - 0.00000001045*accE15cfr + log(nret + 4.5676*ret + 0.1475*pop) - 0.58*intrazonal  - 0.33*cbddum - 0.80*intraco	
		fac = if (atwattr > 0) then max((remain_v / atwattr), 0.01) else 0	//factor exp. utile by the ratio of remaining attrs to total attrs for this dest zone 
		eU = exp(U) * fac
		sumeU = VectorStatistic(eU, "Sum",)
		prob = eU / sumeU
		vecs = {prob, taz, tazseq}
		cumprob1 = CumulativeVector(vecs[1])
		cumprob1[U.length] = 1
		lasttaz = thistaz
		skipprobatwiiix:
		redo_randval_atwiiix:
		rand_val = RandomNumber()
		if (rand_val = 0 or rand_val = 1)  then do
			goto redo_randval_atwiiix
		end
		addnum = max(r2i(1/rand_val), 500)
		cumprob = cumprob1 / rand_val
		cumprob = if cumprob < 1.0 then addnum else cumprob
		cumprob = cumprob + aide_de_sort_vec
		sorted_vecs = SortVectors({cumprob, vecs1[2], vecs1[3]})				
		dest_taz[n] = sorted_vecs[2][1]
		dest_tazseq[n] = sorted_vecs[3][1]
		odtime_v[n] = GetMatrixValue(autofreeintcur, i2s(thistaz), i2s(dest_taz[n]))
		dotime_v[n] = GetMatrixValue(autofreeintcur, i2s(dest_taz[n]), i2s(thistaz))
		remain_v[dest_tazseq[n]] = max(remain_v[dest_tazseq[n]] - 1, 0)	//this removes one attraction from destination zone for each tour
		sumattr[2][dest_tazseq[n]] = sumattr[2][dest_tazseq[n]] + 1
	end
	dest_taz_v = a2v(dest_taz)
	dest_tazseq_v = a2v(dest_tazseq)
	SetDataVector(atwdestii+"|sorted", "DEST_TAZ", dest_taz_v,{{"Sort Order", {{"tazrandnum","Ascending"}}}}) 
	SetDataVector(atwdestii+"|sorted", "DEST_SEQ", dest_tazseq_v,{{"Sort Order", {{"tazrandnum","Ascending"}}}}) 
	SetDataVector(atwdestii+"|sorted", "OD_Time", odtime_v,{{"Sort Order", {{"tazrandnum","Ascending"}}}}) 
	SetDataVector(atwdestii+"|sorted", "DO_Time", dotime_v,{{"Sort Order", {{"tazrandnum","Ascending"}}}}) 

	sse = 0
	totattr = 0
	for i = 1 to hh.length do
		sse = sse + Pow((sumattr[2][i] - atwattr[i]), 2)
		totattr = totattr + atwattr[i]
	end
	rmse = Sqrt(sse / hh.length)
	SetRecordValues("rmse_results", null, {{"ATW_RMSE", rmse}})
//showmessage("ATW rmse = " + r2s(rmse))

//Remove the random number field from the ATW II DC file.  There are 22 fields to keep (includes HBWID for feedback).  
	strct = GetTableStructure(atwdestii)
	for j = 1 to (strct.length) do
 		strct[j] = strct[j] + {strct[j][1]}
 	end
	dim newstrct[22]
	for j = 1 to 22 do
		newstrct[j] = strct[j]
	end
	ModifyTable(atwdestii, newstrct)

	//remove internal zone indices from skims
	SetMatrixIndex(autopk, "Rows", "Columns")
	DeleteMatrixIndex(autopk, "Internals")
	SetMatrixIndex(autofree, "Rows", "Columns")
	DeleteMatrixIndex(autofree, "Internals")

   DestroyProgressBar()
    RunMacro("G30 File Close All")

    goto quit

	badquit:
		on error, notfound default
		RunMacro("TCB Closing", ret_value, "TRUE" )
		msg = msg + {"Tour DC Feedback Loop " + i2s(curiter) + ": Error somewhere"}
		AppendToLogFile(1, "Tour DC Feedback Loop " + i2s(curiter) + ": Error somewhere")
		datentime = GetDateandTime()
		AppendToLogFile(1, "Tour DC Feedback Loop " + i2s(curiter) + " " + datentime)

       	return({0, msg})

    quit:
		on error, notfound default
   		datentime = GetDateandTime()
		AppendToLogFile(1, "Exit Tour DC Feedback Loop " + i2s(curiter) + " " + datentime)
    	return({1, msg})
skiptoend:		

endmacro