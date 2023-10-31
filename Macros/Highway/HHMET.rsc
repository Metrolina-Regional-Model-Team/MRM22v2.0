Macro "HHMET" (Args)

//March 2014.  This macro replicates Bill Allen's HHMET Fortran code, dated January 2014 (which is an updated for the 2013/14 trip-based model update).
//Instead of putting input arrays into this code, bin tables were created.  Need to determine where to store (user is prompted for location).  Input arrays:
	//	puma_vw = OpenTable("puma_vw", "FFB", {DirArray + "\\PUMAEQUIV.bin",})
	//	siseed_vw = OpenTable("siseed_vw", "FFB", {DirArray + "\\SISEED.bin",})
	//	sizedist_vw = OpenTable("sizedist_vw", "FFB", {DirArray + "\\SIZEDIST.bin",})
	//	wkrdist_vw = OpenTable("wkrdist_vw", "FFB", {DirArray + "\\WKRDIST.bin",})
	//	lifedist_vw = OpenTable("lifedist_vw", "FFB", {DirArray + "\\LIFEDIST.bin",})
	//	incdist_vw = OpenTable("incdist_vw", "FFB", {DirArray + "\\INCDIST.bin",})
	//	lcfac_vw = OpenTable("lcfac_vw", "FFB", {DirArray + "\\LCFAC.bin",})
	//	wkrmodl_vw = OpenTable("wkrmodl_vw", "FFB", {DirArray + "\\WKRMODL.bin",})


//Updated for new UI - Aug, 2015 - McLelland
// 1/17, mk: changed from .dbf to .bin

//	on error goto badquit
	LogFile = Args.[Log File].value
	ReportFile = Args.[Report File].value
	SetLogFileName(LogFile)
	SetReportFileName(ReportFile)
	
	sedata_file = Args.[LandUse file].value
	Dir = Args.[Run Directory].value
	msg = null
	datentime = GetDateandTime()
	AppendToLogFile(1, "Enter HH Synthesis: " + datentime)
	RunMacro("TCB Init")

	RunMacro("G30 File Close All") 

//shared sefile, pumafile, siseed, wkrdist, lifedist, sizedist, incdist, lcfac, DirArray, avg5per, avg3wkr  //hhfile, zfile, list, avg5per, empfactor

 avg5per = 5.54  //average persons/HH for 5+ persons/HH category
 avg3wkr = 3.255  //average workers/HH for 3+ workers/HH category
 empfactor = 0.8000	//regional ratio of labor force (resident workers) to employees [0.8740]


	DirArray  = Dir + "\\TG"

	se_vw = OpenTable("SEFile", "dBASE", {sedata_file,})

	se_vectors = GetDataVectors(se_vw+"|", {"TAZ", "POP", "HH", "POP_HHS", "MED_INC", "TOTEMP", "SEQ"},{{"Sort Order", {{"TAZ","Ascending"}}}}) //6 vectors
	taz = se_vectors[1]
	pop = se_vectors[2]
	hh = se_vectors[3]
	pophhs = se_vectors[4]
	medinc = se_vectors[5]
	totemp = se_vectors[6]
	tazseq = se_vectors[7]
	cbddum = if (taz = 10001 or taz = 10002 or taz = 10003 or taz = 10004 or taz = 10005 or taz = 10006 or taz = 10007 or taz = 10008 or taz = 10009 or 
		taz = 10010 or taz = 10011 or taz = 10012 or taz = 10013 or taz = 10014 or taz = 10015 or taz = 10016 or taz = 10017 or taz = 10018 or taz = 10019 or 
		taz = 10020 or taz = 10021 or taz = 10022 or taz = 10023 or taz = 10024 or taz = 10025 or taz = 10026 or taz = 10027 or taz = 10028 or taz = 10029 or
		taz = 10030 or taz = 10031 or taz = 10032 or taz = 10033 or taz = 10034 or taz = 10035 or 
		taz = 10052 or taz = 10086 or taz = 10116 or taz = 10117 or taz = 10118 or taz = 10119 or  
		taz = 10144 or taz = 10145 or taz = 10146 or taz = 10160 or taz = 10161 or taz = 10164 or taz = 10165 or taz = 10235) then 1 else 0
	uptown = if (taz = 10001 or taz = 10002 or taz = 10003 or taz = 10004 or taz = 10005 or taz = 10006 or taz = 10007 or taz = 10008 or taz = 10009 or 
		taz = 10010 or taz = 10011 or taz = 10012 or taz = 10013 or taz = 10014 or taz = 10015 or taz = 10016 or taz = 10017 or taz = 10018 or taz = 10019 or 
		taz = 10020 or taz = 10023 or taz = 10024 or taz = 10025 or taz = 10026 or taz = 10027 or taz = 10028 or  
		taz = 10030 or taz = 10031 or taz = 10032 or taz = 10033 or taz = 10034 or taz = 10035 or taz = 10052 or taz = 10116 or taz = 10117 or taz = 10144 or 
		taz = 10165 or taz = 10166 or taz = 10168 or taz = 10173 or taz = 10214 or taz = 10215 or taz = 10216 or taz = 10218 or taz = 10219 or taz = 10220 or 
		taz = 10221 or taz = 10235 or taz = 10236 or taz = 10237 or taz = 10238 or taz = 10239 or taz = 11157 or taz = 11158) then 1 else 0
     
//Accumulate regional totals of employees, HHs, persons in HHs, total persons, HH income.

	regtot_emp = VectorStatistic(totemp, "Sum", )
	regtot_hh = VectorStatistic(hh, "Sum", )
	regtot_pophhs = VectorStatistic(pophhs, "Sum", )
	regtot_pop = VectorStatistic(pop, "Sum", )

	v.income = hh * medinc
	regtot_medinc = VectorStatistic(v.income, "Sum", )
	regavginc = regtot_medinc/regtot_hh			//Calculate the regional median HH income as the HH-weighted average

//*************************************************************************************************
//FIRST LOOP: calculates values for Size+Income categories (S1/I1, S1/I2, S1/I3, S1/I4, S2/I1, etc) *
//*************************************************************************************************

//Determine HH's by Size & Income. Start with size
//SIZEDIST array: regional base HH size model. (Derived from 2000 CTPP Table 1-62, SizeModel.xls). Dimensions: SIZEDIST(size, avg size index)
	sizedist_vw = OpenTable("sizedist_vw", "FFB", {DirArray + "\\SIZEDIST.bin",})
	SetView(sizedist_vw)
	size_v = GetDataVectors(sizedist_vw+"|", {"HHSZ1","HHSZ2","HHSZ3","HHSZ4","[HHSZ5+]"},{{"Sort Order", {{"AVSZINDEX", "Ascending"}}}})
	dim sizedist[5]					//an array of the 5 size vectors
	dim spct[5,hh.length]
	dim spct_av[5]
	dim hhsize[5]
	for s = 1 to 5 do
		sizedist[s] = size_v[s]
	end
	perhh = if (hh = 0) then 1.0 else if (pophhs / hh) > 3.9 then 3.9 else (pophhs / hh)
	lind = r2i(max(floor(perhh * 10 - 9),1))
	hind = r2i(min(lind + 1, 30))
	low = 0.9 + 0.10 * lind
	high = 0.9 + 0.10 * hind
	range = high - low
	ratio = Vector(hh.length, "float", )
	ratio = if (range > 0.001) then ((perhh - low) / range) else 0.0
	for s = 1 to 5 do
		for n = 1 to hh.length do
			spct[s][n] = (sizedist[s][lind[n]] + ratio[n] * (sizedist[s][hind[n]] - sizedist[s][lind[n]])) * 0.01
		end
	end
	spct_av = {a2v(spct[1]), a2v(spct[2]), a2v(spct[3]), a2v(spct[4]), a2v(spct[5])}

//check to see if fractions equal 1.0	
	csum = spct_av[1] + spct_av[2] + spct_av[3] + spct_av[4] + spct_av[5]
	diff = abs(csum - 1.0)
	for s = 1 to 5 do
		spct_av[s] = if (diff > .001) then (spct_av[s] / csum) else spct_av[s]
		hhsize[s] = hh * spct_av[s]
	end
CloseView(sizedist_vw)

//Now do HHs by Income Category
//'INCDIST' array: regional base HH income group model.(Derived from 2000 CTPP Tables 1-66, 1-90, IncomeModel.xls). Dimensions: INCDIST(income, mean income ratio index)
	incdist_vw = OpenTable("incdist_vw", "FFB", {DirArray + "\\INCDIST.bin",})
	SetView(incdist_vw)
	inc_v = GetDataVectors(incdist_vw+"|", {"INC1","INC2","INC3","INC4"},{{"Sort Order", {{"INCRATNDX", "Ascending"}}}})
	dim incdist[4]
	dim ipct[4,hh.length]
	dim hhinc[5]
	for i = 1 to 4 do
		incdist[i] = inc_v[i]
	end
	incrat = if (hh = 0) then 1.0 else if (medinc / regavginc) > 3.7 then 3.7 else if (medinc / regavginc) < 0.1 then 0.1 else (medinc / regavginc)
	lind = r2i(max(floor(incrat *10),1))
	hind = r2i(min(lind + 1, 37))
	low = 0.10 * lind
	high = 0.10 * hind
	range = high - low
	ratio = Vector(hh.length, "float", )
	ratio = if (range > 0.001) then ((incrat - low) / range) else 0.0
	for i = 1 to 4 do
		for n = 1 to hh.length do
			ipct[i][n] = (incdist[i][lind[n]] + ratio[n] * (incdist[i][hind[n]] - incdist[i][lind[n]])) * 0.01
		end
	end
	ipct_av = {a2v(ipct[1]), a2v(ipct[2]), a2v(ipct[3]), a2v(ipct[4])}

//check to see if fractions equal 1.0	
	csum = ipct_av[1] + ipct_av[2] + ipct_av[3] + ipct_av[4]
	diff = abs(csum - 1.0)
	for i = 1 to 4 do
		ipct_av[i] = if (diff > .001) then (ipct_av[i] / csum) else ipct_av[i]
		hhinc[i] = hh * ipct_av[i]
	end
CloseView(incdist_vw)

//******************************
//Next do Size/Income Combo.  Will create S1I1, S1I2,...S5I4 array.  Still in first big loop of Bill's program

//fill PUMA number in SE_calc table

	puma_vw = OpenTable("puma_vw", "FFB", {DirArray + "\\PUMAEQUIV.bin",})
	puma = GetDataVector(puma_vw+"|" ,"PUMANO",{{"Sort Order", {{"TAZ", "Ascending"}}}})

//"SISEED" array: regional base % of HH's by HH size, income group, and PUMA, from the 2005-09<??> ACS PUMS files for Metrolina. (PUMS areas from the 200 census--limited
//  2010-PUMA data is available, but not enough to use yet).  See hhmet.txt for list of PUMAs
	siseed_vw = OpenTable("siseed_vw", "FFB", {DirArray + "\\SISEED.bin",})
	SetView(siseed_vw)
	dim siseedar[15,5,4]

	siseedptr = GetFirstRecord(siseed_vw+"|",)
    	while siseedptr <> null do
		mval = GetRecordValues(siseed_vw, siseedptr, {"PUMA", "Size", "Inc1", "Inc2", "Inc3", "Inc4"})
		PUMA_no = mval[1][2]
		Size = mval[2][2]
		for i= 1 to 4 do
			siseedar[PUMA_no][Size][i] = mval[i+2][2]
		end
	 	siseedptr = GetNextRecord(siseed_vw + "|", null,)
	end
//CloseView(siseed_vw)

//start the big loop joint(s,i) matrix ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	m_jointsi = CreateMatrix({se_vw+"|", "TAZ", "Row Index"}, {siseed_vw+"|", "Size", "Column Index"},
			{{"File Name", DirArray + "\\jointsi.mtx"}, {"Tables", {"Inc1", "Inc2", "Inc3", "Inc4"}}})
	corenames = GetMatrixCoreNames(m_jointsi)
	jointsi_cur = CreateMatrixCurrencies(m_jointsi,,,)
			
//calculate the initial number of HHs per size and income groups.  Fill arrays into matrix (jointsi: rows = TAZSEQ, columns = 5 size cat, cores = 4 income cat)
	dim jointsi[4,5,hh.length]
	for i = 1 to 4 do
		for s = 1 to 5 do
			for n = 1 to hh.length do
				jointsi[i][s][n] = hh[n] * siseedar[puma[n]][s][i]
			end
		end
		mc = jointsi_cur.(corenames[i])
		for s = 1 to 5 do
			SetMatrixVector(mc, a2v(jointsi[i][s]), {{"Column", s}})
		end
	end
//factor matrix to get desired row totals.  (Row is size, though in matrix size is the column value.  Thus, the row (size) total per hh is the quicksum of each income core)
     	Opts = null
     	Opts.Input.[Input Currency] = {DirArray + "\\jointsi.mtx", "Inc1", "Row Index", "Column Index"}
     	ret_value = RunMacro("TCB Run Operation", "Matrix QuickSum", Opts, &Ret)
	mc_rtot = CreateMatrixCurrency(m_jointsi, "QuickSum", "Row Index", "Column Index",)

	for i = 1 to 4 do
		mc = jointsi_cur.(corenames[i])
		for s = 1 to 5 do
			sizeval = GetMatrixVector(mc, {{"Column", s}})
			sizeval.rowbased = True
			values = hhsize[s] * sizeval
			SetMatrixVector(mc, values, {{"Column", s}})
		end
		mc := if (mc <> 0) then mc / mc_rtot else mc
	end
	newtot = hh
	SetMatrixCore(m_jointsi, "Inc1")
	DropMatrixCore(m_jointsi, "QuickSum")

//start big row loop
	for s = 1 to 5 do
		sneg = Vector(hh.length, "float", {{"Constant", 0.0}})
		for i = 1 to 4 do						//calc the column difference
			mc = jointsi_cur.(corenames[i])
			cdiff = hhinc[i]
			for s2 = 1 to 5 do
				sizeval = GetMatrixVector(mc, {{"Column", s2}})			
				sizeval.rowbased = True
				cdiff = cdiff - sizeval
			end
			sizeval = GetMatrixVector(mc, {{"Column", s}})			
			sizeval.rowbased = True
			share = if (newtot > 0.0) then (cdiff * hhsize[s] / newtot) else 0	//Apportion each column's difference along this row
			value1 = sizeval + share
			sneg = if (value1 < 0.0) then (sneg + value1) else sneg			//check to see if resulting value is negative
			values = if (value1 < 0.0) then 0 else value1
			SetMatrixVector(mc, values, {{"Column", s}})
		end
		negfac = Vector(hh.length, "float", {{"Constant", 1.0}})			//end column loop 1.  Calc adjustment for negative values
		negfac = if (sneg < 0.0) then (1.0 + sneg / (hhsize[s] - sneg)) else negfac
		for i = 1 to 4 do								//apply adjustment for negative values (col. loop #2)
			mc = jointsi_cur.(corenames[i])
			sizeval = GetMatrixVector(mc, {{"Column", s}})
			sizeval.rowbased = True
			jointsi = negfac * sizeval
			SetMatrixVector(mc, jointsi, {{"Column", s}})
		end
		newtot = newtot - hhsize[s]
	end

//Do one last factor to get the column totals (by income) to come out more closely to the desired totals. (Since size 
//  is column in matrix, ctot (income) is sum marginal for each core)
	for i =  1 to 4 do
		mc = jointsi_cur.(corenames[i])
		ctot = a2v(GetMatrixMarginals(mc, "Sum", "row"))
		cfac = Vector(hh.length, "float", {{"Constant", 0.0}})
		cfac = if (ctot > 0.0) then (hhinc[i] / ctot) else cfac
		for s = 1 to 5 do
			sizeval = GetMatrixVector(mc, {{"Column", s}})
			sizeval.rowbased = True
			values = cfac * sizeval
			SetMatrixVector(mc, values, {{"Column", s}})
		end
	end
//Sum HHs by income group
	dim tinc[4]
	stat_array = MatrixStatistics(m_jointsi, )
	for i = 1 to 4 do
		tinc[i] = stat_array[i][2][2][2]
	end
//End of first loop
//Calculate the regional percent of HHs by income group.  Need this later.
	dim ripct[4]
	isum = tinc[1] + tinc[2] + tinc[3] + tinc[4]
	for i = 1 to 4 do
		ripct[i] = tinc[i] / isum
	end

//*************************************************************************************************
//SECOND LOOP: Normalize income groups to be 10%/15%/25%/50%					  *
//*************************************************************************************************

	dim igroup[4] 
	igroup[1] = 0.10
	igroup[2] = 0.15
	igroup[3] = 0.25
	igroup[4] = 0.50

	for i = 1 to 4 do
		mc = jointsi_cur.(corenames[i])
		mc := mc * igroup[i] / ripct[i]
	end

//*************************************************************************************************
//THIRD LOOP: The previous loop will have goofed # of HHs by zone. Re-normalize here to correct	  *
//*************************************************************************************************

	newtot = 0.0
	for i = 1 to 4 do
		mc = jointsi_cur.(corenames[i])
		incsum = a2v(GetMatrixMarginals(mc, "Sum", "row"))
		newtot = newtot + incsum
	end
	factor = Vector(hh.length, "float", {{"Constant", 1.0}})
	factor = if (newtot > 0.0001) then (hh / newtot) else factor
	for i = 1 to 4 do
		mc = jointsi_cur.(corenames[i])
		for s = 1 to 5 do
			sizeval = GetMatrixVector(mc, {{"Column", s}})
			sizeval.rowbased = True
			values = factor * sizeval
			SetMatrixVector(mc, values, {{"Column", s}})
		end
	end

//*************************************************************************************************************************
//FOURTH LOOP: For each size & income category, use LIFEDIST array to compute initial dist by Size, Income & Life Cycle	  *
//*************************************************************************************************************************

//'LIFEDIST' array: regional base distribution of HHs by HH size, income group, and life cycle, from the 2000 PUMS files for Metrolina. 
	lifedist_vw = OpenTable("lifedist_vw", "FFB", {DirArray + "\\LIFEDIST.bin",})
	SetView(lifedist_vw)
	dim lifedistar[5,4,3]				//life cycle distrubtion array (size, income, lc)

	lifedistptr = GetFirstRecord(lifedist_vw+"|",)
    	while lifedistptr <> null do
		mval = GetRecordValues(lifedist_vw, lifedistptr, {"Size", "Inc", "LC1", "LC2", "LC3"})
		Size = mval[1][2]
		Inc = mval[2][2]
		for l= 1 to 3 do
			lifedistar[Size][Inc][l] = mval[l+2][2]
		end
	 	lifedistptr = GetNextRecord(lifedist_vw + "|", null,)
	end
CloseView(lifedist_vw)
//'LCFAC' array: adjustments to life cycle model, in order to reflect substantial differences in the Charlotte Uptown area. Array is (lifecycle, income).  Adjustments 
//are derived from 2012 survey  ***uptown conversion calc will be commented out until get Uptown zones coded
	lcfac_vw = OpenTable("lcfac_vw", "FFB", {DirArray + "\\LCFAC.bin",})
	SetView(lcfac_vw)
	lcfac_v = GetDataVectors(lcfac_vw+"|", {"LC1","LC2","LC3"},{{"Sort Order", {{"INC", "Ascending"}}}})
	dim lcfac[4]
	for l = 1 to 3 do
		lcfac[l] = lcfac_v[l]
	end

	dim life[3]
	dim ld[5,4,3]
	dim sizinclif_ar[5,4,3,hh.length]
	dim sizinclif[5,4,3]

	life = {0,0,0}
	for n = 1 to hh.length do
		for i = 1 to 4 do
			mc = jointsi_cur.(corenames[i])			
			for s = 1 to 5 do
				sizeinc = GetMatrixVector(mc, {{"Column", s}})
				sizeinc.rowbased = True
				if uptown[n] = 1 then do		//if zone is in Uptown, incorporate special factor; then normalize to ensure the LC fractions sum to 1.
					for l = 1 to 3 do
						ld[s][i][l] = lifedistar[s][i][l] * lcfac[l][i]
					end
					sum = ld[s][i][1] + ld[s][i][2] + ld[s][i][3]
					for l = 1 to 3 do
						ld[s][i][l] = ld[s][i][l] / sum
					end
				end
				else do
					for l = 1 to 3 do
						ld[s][i][l] = lifedistar[s][i][l] 
					end
				end
				for l = 1 to 3 do
					sizinclif_ar[s][i][l][n] = ld[s][i][l] * sizeinc[n]
					life[l] = sizinclif_ar[s][i][l][n] + life[l]
				end
			end
		end
	end
	for s = 1 to 5 do
		for i = 1 to 4 do
			for l = 1 to 3 do
				sizinclif[s][i][l] = a2v(sizinclif_ar[s][i][l])
			end
		end
	end

//Accumulate (Real) HHs by size,income, and life cycle into total table for region. (SizeIncLife.dbf)
	sizinclif_table = CreateTable("sizinclif_table", DirArray + "\\SizeIncLife.dbf", "DBASE", {{"Blank","Integer", 2, null, "No"}})
	rh = AddRecord(sizinclif_table, )
	for s = 1 to 5 do				
		for i =  1 to 4 do
			for l = 1 to 3 do
				sum = VectorStatistic(sizinclif[s][i][l], "Sum",)
				strct = GetTableStructure(sizinclif_table)
				for x = 1 to strct.length do
				    strct[x] = strct[x] + {strct[x][1]}
				end
				strct = strct + {{"S" + i2s(s) + "I" + i2s(i) + "L" + i2s(l), "Real", 12, 2, "False", , , , , , , null}}
				ModifyTable(sizinclif_table, strct)
				SetRecordValues(sizinclif_table, rh, {{"S" + i2s(s) + "I" + i2s(i) + "L" + i2s(l), r2s(sum)}})
			end
		end
	end
CloseView(sizinclif_table)			

//*************************************************************************************************************************
//FIFTH LOOP: For each s/i/lc category, use WKRDIST array to compute initial dist by Size, Income, Life Cycle & Workers	  *
//*************************************************************************************************************************

//'WKRDIST' array: regional base distribution of HHs by HH size, income group, lifecycle, and no. of workers, from the 2000 PUMS files for Metrolina. 
	wkrdist_vw = OpenTable("wkrdist_vw", "FFB", {DirArray + "\\WKRDIST.bin",})
	SetView(wkrdist_vw)
	dim wkrdist[5,4,3,4]				//worker cycle distrubtion array (size, income, lc, #workers)

	wkrdistptr = GetFirstRecord(wkrdist_vw+"|",)
    	while wkrdistptr <> null do
		mval = GetRecordValues(wkrdist_vw, wkrdistptr, {"Size", "Inc", "Life", "WKR0", "WKR1", "WKR2", "[WKR3+]"})
		Size = mval[1][2]
		Inc = mval[2][2]
		Life = mval[3][2]
		for w = 1 to 4 do
			wkrdist[Size][Inc][Life][w] = mval[w+3][2]
		end
	 	wkrdistptr = GetNextRecord(wkrdist_vw + "|", null,)
	end
CloseView(wkrdist_vw)

	dim sizinclifwkr[5,4,3,4]
	regtotwkr = 0
	for s = 1 to 5 do				
		for i =  1 to 4 do
			for l = 1 to 3 do
				for w = 1 to 4 do
					sizinclifwkr[s][i][l][w] = sizinclif[s][i][l] * wkrdist[s][i][l][w]
				end
				regtotwkr = regtotwkr + VectorStatistic(sizinclifwkr[s][i][l][2], "Sum",) + 
						2.0 * VectorStatistic(sizinclifwkr[s][i][l][3], "Sum",) + avg3wkr * VectorStatistic(sizinclifwkr[s][i][l][4], "Sum",)
			end
		end
	end
					

//*************************************************************************************************************************
//Adjust the regional total number of workers to match the regional total employment, factored to account for I/E workers,*
//	E/I workers, unemploymnet and multiple job holders. Factor is 'EMPFACTOR' and its value is based on 2010 data.     *
//	Calculate a new adjustment factor called 'EMPADJUST'. 2010 values: REGTOT(1) = regional total Metrolina 	  *
//	employment = 1,220,673, REGTOTWKR = 1,067,600 (program estimate)
//*************************************************************************************************************************

	oldwkrhh =  regtotwkr / regtot_hh
	newtotwkr = regtot_emp * empfactor
	empadjust = newtotwkr / regtotwkr
	newwkrhh = newtotwkr / regtot_hh

//ShowMessage("Regional total employment: " + String(regtot_emp) + "\n" + "Worker/employee ratio: " + String(empfactor)  + "\n" + "New est. regoinal workers: " + String(newtotwkr) + "\n" + "Initial total workers: " + String(regtotwkr) + "\n" + "Workers/HH adjustment factor: " + String(empadjust))

					//   WORKER SUBROUTINE	\\

//Subroutine 'WORKERS' to apply worker submodel to translate an average no. of workers/HH to the percent of HHs with 0, 1, 2, and 3+ workers.
//'WKRMODL' array: regional base workers/HH model. Derived from 2000 CTPP, part 1, table 62. Dimensions: WKRMODL(workers, avg workers/HH index)
	wkrmodl_vw = OpenTable("wkrmodl_vw", "FFB", {DirArray + "\\WKRMODL.bin",})
	SetView(wkrmodl_vw)
	wkrmodl_v = GetDataVectors(wkrmodl_vw+"|", {"WKR0","WKR1","WKR2","WKR3+"},{{"Sort Order", {{"WKR_INDEX", "Ascending"}}}})
	dim wkrmodl[4]
	dim wpctold[4]
	dim wpctnew[4]
	for i = 1 to 4 do
		wkrmodl[i] = wkrmodl_v[i]
	end
CloseView(wkrmodl_vw)

//start with old regional proportion of HHs by number of  workers (OLDWRK)
	oldwkrhh = if (oldwkrhh < 0.4) then 0.4 else if (oldwkrhh > 2.0) then 2.0 else oldwkrhh
	lind = r2i(oldwkrhh * 10 - 3)
	hind = r2i(lind + 1)
	ratio = oldwkrhh * 10 - r2i(oldwkrhh * 10)
	lind = r2i(max(lind, 1))	
	lind = r2i(min(lind, 17))	
	hind = r2i(max(hind, 1))	
	hind = r2i(min(hind, 17))	
	for w = 1 to 4 do
		wpctold[w] = (wkrmodl[w][lind] + ratio * (wkrmodl[w][hind] - wkrmodl[w][lind])) * 0.01
	end

//check to see if fractions equal 1.0	
	csum = wpctold[1] + wpctold[2] + wpctold[3] + wpctold[4]
	diff = abs(csum - 1.0)
	for w = 1 to 4 do
		wpctold[w] = if (diff > .001) then (wpctold[w] / csum) else wpctold[w]
	end

//now do new regional proportion of HHs by number of  workers (NEWWRK)
	newwkrhh = if (newwkrhh < 0.4) then 0.4 else if (newwkrhh > 2.0) then 2.0 else newwkrhh
	lind = r2i(newwkrhh * 10 - 3)
	hind = r2i(lind + 1)
	ratio = newwkrhh * 10 - r2i(newwkrhh * 10)
	lind = r2i(max(lind, 1))	
	lind = r2i(min(lind, 17))	
	hind = r2i(max(hind, 1))	
	hind = r2i(min(hind, 17))	
	for w = 1 to 4 do
		wpctnew[w] = (wkrmodl[w][lind] + ratio * (wkrmodl[w][hind] - wkrmodl[w][lind])) * 0.01
	end

//Ensure that total percentages sum to 1.0
	csum = wpctnew[1] + wpctnew[2] + wpctnew[3] + wpctnew[4]
	diff = abs(csum - 1.0)
	for w = 1 to 4 do
		wpctnew[w] = if (diff > .001) then (wpctnew[w] / csum) else wpctnew[w]
	end

					// END OF WORKER SUBROUTINE \\

//Calculate ratio of NEWWRK to OLDWRK, by no. of workers
	dim wratio[4]
	for w = 1 to 4 do
		wratio[w] = 1.0
		wratio[w] = if (wpctold[w] > 0.001) then (wpctnew[w] / wpctold[w]) else wratio[w]
	end

//*************************************************************************************************************************
//SIXTH LOOP: Just as above -- For each s/i/lc category, use WKRDIST array to compute initial dist by Size, Income, Life  * 
//	Cycle & Workers.												  *
//Except this time, modify the worker distribution using WRATIO, as calculated above					  *
//*************************************************************************************************************************

	dim wkrinclif[4,4,3]
	dim szinlfwk[5,4,3,4]
	
	tothh = Vector(hh.length, "float", {{"Constant", 0.0}})
	wsum = Vector(hh.length, "float", {{"Constant", 0.0}})
	for s = 1 to 5 do
		for i = 1 to 4 do
			for l = 1 to 3 do
				wsum = 0.0
				for w = 1 to 4 do
					sizinclifwkr[s][i][l][w] = sizinclif[s][i][l] * wkrdist[s][i][l][w] * wratio[w]
					wsum = wsum + sizinclifwkr[s][i][l][w]
				end
//Normalize to get correct total for each size/income/lc group.
				wfac = 1.0
				wfac = if (wsum > 0.001) then (sizinclif[s][i][l] / wsum) else wfac
				for w = 1 to 4 do
					sizinclifwkr[s][i][l][w] = wfac * sizinclifwkr[s][i][l][w]
					tothh = tothh + sizinclifwkr[s][i][l][w]
				end
			end
		end
	end
//Check resulting total. If they don't match the input total, warn the user (show message)
	for n = 1 to hh.length do
		if abs(tothh[n] - hh[n]) > 1.0 then do
			zone = i2s(n)
			ShowMessage("Check workers/HH calculation. Zone " + zone + " incorrect")
		end
	end
//Now collapse the size diminsion, leaving HHs by workers/income/life cycle
	wkrinclif_v = Vector(hh.length, "float", {{"Constant", 0.0}})
	for w = 1 to 4 do
		for i = 1 to 4 do
			for l = 1 to 3 do
				wkrinclif[w][i][l] = wkrinclif_v
			end
		end
	end
	for w = 1 to 4 do
		for i = 1 to 4 do
			for l = 1 to 3 do
				for s = 1 to 5 do
					wkrinclif[w][i][l] = wkrinclif[w][i][l] + sizinclifwkr[s][i][l][w]
				end
			end
		end
	end

//Following steps create individual HH records for each zone, showing the size, income, lifecycle, and workers
//Create the hhdetail table
	hhdetail = CreateTable("hhdetail", DirArray + "\\hhdetail.bin", "FFB", {{"ID","Integer", 7, null, "No"}, {"TAZ","Integer", 5, null, "No"}, {"TAZ_SEQ","Integer", 5, null, "No"}, {"SIZE","Integer", 2, null, "No"}, {"INCOME","Integer", 2, null, "No"}, {"LIFE","Integer", 2, null, "No"}, {"WRKRS","Integer", 2, null, "No"}})

//Bucket round the SIZINCLIFWKR array
	for n = 1 to hh.length do
		SetView(se_vw)
		thistaz = LocateRecord(se_vw+"|", "SEQ", {n}, {{"Exact", "True"}})
		tazval = GetRecordValues(se_vw, thistaz, {"TAZ"})		
		tazid = tazval[1][2]
		thh = 0
		buck = 0.5
		for s = 1 to 5 do
			for i = 1 to 4 do
				for l = 1 to 3 do
					for w = 1 to 4 do
						number = 0
						szinlfwk[s][i][l][w] = nz(Floor(sizinclifwkr[s][i][l][w][n] + buck))
						buck = sizinclifwkr[s][i][l][w][n] - szinlfwk[s][i][l][w] + buck
						thh = thh + szinlfwk[s][i][l][w]
						number = szinlfwk[s][i][l][w]
						if number > 0 then do
							for x = 1 to number do
								filltable = AddRecord("hhdetail", {{"TAZ", tazid}, {"TAZ_SEQ", n}, {"SIZE", s}, {"INCOME", i}, {"LIFE", l}, {"WRKRS", w-1}})
							end
						end
					end
				end
			end
		end
//Check HH totals to make sure we didn't lose/gain any.  If we did, repeatedly add/subtract 1 from a random non-zero cell until difference if zero.
//		hdiff[n] = hh[n] - thh[n]
//		while hdiff[n] <> 0 do
			
	end
	SetView("hhdetail")
	SetRecordsValues(null, {{"ID"}, null}, "Sequence", {1,1},)
CloseView(hhdetail)

//*************************************************************************************************************************
//SEVENTH LOOP: Calculate and output final total integer HHs by income							  *
//*************************************************************************************************************************

	hh_by_income = CreateTable("hh_by_income", DirArray + "\\hh_income.bin", "FFB", {{"TAZ","Integer", 5, null, "No"}, {"INC1","Integer", 5, null, "No"}, {"INC2","Integer", 5, null, "No"}, {"INC3","Integer", 5, null, "No"}, {"INC4","Integer", 5, null, "No"}})	

	dim rinc[4]
	dim garb[4]
	dim intinc[4]
	dim tjointWIL[4,4,3]
	dim twkr[4]
	dim tlife[3]

//Calculate total workers
	ztotwkr = 0.0
	for n = 1 to hh.length do
		for i = 1 to 4 do
			for l = 1 to 3 do 
				ztotwkr = ztotwkr + wkrinclif[2][i][l][n] + 2.0 * wkrinclif[3][i][l][n] + avg3wkr * wkrinclif[4][i][l][n]
			end
		end
//Bucket round across income categories within each zone
		for i = 1 to 4 do
			rinc[i] = 0.0
			for w = 1 to 4 do
				for l = 1 to 3 do
					rinc[i] = rinc[i] + wkrinclif[w][i][l][n]
				end
			end
			garb[i] = 0.5
			intinc[i] = Floor(rinc[i] + garb[i])
			garb[i] = rinc[i] - intinc[i] + garb[i]
		end
		filltable = AddRecord("hh_by_income", {{"TAZ", }, {"INC1", rinc[1]}, {"INC2", rinc[2]}, {"INC3", rinc[3]}, {"INC4", rinc[4]}})

//Accumulate (Real) HHs by workers, income, and life cycle into a total table for the region.
		for w = 1 to 4 do
			for i = 1 to 4 do
				for l = 1 to 3 do
					tlife[l] = 0
					tjointWIL[w][i][l] = nz(tjointWIL[w][i][l]) + wkrinclif[w][i][l][n]
					tinc[i] = tinc[i] + wkrinclif[w][i][l][n]
					twkr[w] = nz(twkr[w]) + wkrinclif[w][i][l][n]
					tlife[l] = nz(tlife[l]) + wkrinclif[w][i][l][n]
				end
			end
		end
	end
	SetDataVector(hh_by_income+"|", "TAZ", taz,)

    goto quit

	badquit:
		on error, notfound default
		RunMacro("TCB Closing", ret_value, "TRUE" )
		msg = msg + {"HHMET: Error somewhere"}
		AppendToLogFile(1, "HHMET: Error somewhere")
		datentime = GetDateandTime()
		AppendToLogFile(1, "Exit HHMET " + datentime)

       	return({0, msg})


    quit:
		on error, notfound default
   		datentime = GetDateandTime()
		AppendToLogFile(1, "Exit HH Synthesis " + datentime)
    	return({1, msg})

endmacro