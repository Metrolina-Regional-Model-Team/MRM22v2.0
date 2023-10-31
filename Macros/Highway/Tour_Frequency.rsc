Macro "Tour_Frequency" (Args)

//This macro calculates the number of tours, by purpose, for each household.  The number of at-work tours is dependent on the location of the workplace, so ATW tour-frequency
// is determined within the Tour Destination Choice macro.
//The output of this file is TourRecords.bin, located in the TG folder. --1/17 changed from .dbf
// 8/3/17, mk: coefficients changed
// 8/31/17, mk: modified choice methodology to improve speed, removed sorting probabilities, set random seeds before each purpose
// 2/26/18, mk: changes per BA's 2/26/18 email
// 5/29/18, mk: coefficient changes per BA's 5/11/18 email
// 2/25/19, mk: change 2+ breakdown for HBS per Bill's 2/25/19 email

	on error goto badquit
	LogFile = Args.[Log File].value
	ReportFile = Args.[Report File].value
	SetLogFileName(LogFile)
	SetReportFileName(ReportFile)
	
	sedata_file = Args.[LandUse file].value
	Dir = Args.[Run Directory].value
	theyear = Args.[Run Year].value
	msg = null
	datentime = GetDateandTime()
	AppendToLogFile(1, "Tour Frequency: " + datentime)
	RunMacro("TCB Init")

	RunMacro("G30 File Close All") 

	DirArray  = Dir + "\\TG"
 
 	yr_str = Right(theyear,2)
	yr = s2i(yr_str)

//The next line represents a substitutable parameter whose value is used in several places below (edit; 11/21/17)
addBias = 0.8

  CreateProgressBar("Getting Alternative Variables...", "TRUE")

//Open all needed tables, pull out vectors
	hhdetail = OpenTable("hhdetail", "FFB", {DirArray + "\\HHDETAIL.bin",})

	hhdetail_v = GetDataVectors(hhdetail+"|", {"ID", "TAZ_SEQ", "SIZE", "INCOME", "LIFE", "WRKRS"},{{"Sort Order", {{"ID","Ascending"}}}}) 
	hhid = hhdetail_v[1]
	tazseq = hhdetail_v[2]
	size = hhdetail_v[3]					//HBU,HBS,HBO,
	income = hhdetail_v[4]
	lc = hhdetail_v[5]
	wrkr = hhdetail_v[6]					//HBW,HBS,HBO,
	lc1dum = if (lc = 1) then 1 else 0			//SCH,HBU,
	lc2dum = if (lc = 2) then 1 else 0			//SCH,HBS,HBO,
	inc1dum = if (income = 1) then 1 else 0			//SCH,HBU,HBW,HBO,
	inc2dum = if (income = 2) then 1 else 0			//HBU,
	inc4dum = if (income = 4) then 1 else 0			//HBO,
	siz1dum = if (size = 1) then 1 else 0			//HBO,
	siz2dum = if (size = 2) then 1 else 0			//SCH,
	siz3dum = if (size = 3) then 1 else 0			//HBU,
	siz5dum = if (size = 5) then 1 else 0			//SCH,
	siz34dum = if (size = 3 or size = 4) then 1 else 0	//SCH,
	siz345dum = if (size > 2) then 1 else 0			//HBW,
	siz45dum = if (size = 4 or size = 5) then 1 else 0	//SCH,
	wkr0dum = if (wrkr = 0) then 1 else 0			//HBU,
	wkr1dum = if (wrkr = 1) then 1 else 0			//HBW,HBS,
//	wkr2dum = if (wrkr = 2) then 1 else 0			//
	wkr3dum = if (wrkr = 3) then 1 else 0			//SCH,HBU,

	se_vw = OpenTable("SEFile", "dBASE", {sedata_file,})
	se_vectors = GetDataVectors(se_vw+"|", {"TAZ", "HH", "POP", "DORM", "MED_INC"},{{"Sort Order", {{"TAZ","Ascending"}}}})
	taz = se_vectors[1]
	hh = se_vectors[2]
	pop = se_vectors[3]
	medinc = se_vectors[5]
	avgsize = if (hh > 0) then (pop / hh) else 0

	areatype = OpenTable("areatype", "DBASE", {Dir + "\\landuse\\SE" + theyear + "_DENSITY.dbf",})  
	atype = GetDataVector(areatype+"|", "AREATYPE", {{"Sort Order", {{"TAZ","Ascending"}}}}) 

//copy the HHdetail file (ouput from HHMET).  This will be the output file of Tour Frequency
	CopyTableFiles("hhdetail", null, null, null, DirArray + "\\TourRecords.bin", null)

vws = GetViewNames()
for i = 1 to vws.length do
     CloseView(vws[i])
end

//Loop to get alternative variable vectors (the size of these vectors will equal the number of HHs in the region)
	dim avgsize_ar[hhid.length]
	dim medinc_ar[hhid.length]
	dim atype_ar[hhid.length]
	for n = 1 to hhid.length do
		origtazseq = tazseq[n]
		if origtazseq = prevtaz then do
			avgsize_ar[n] = avgsize_ar[n-1]
			medinc_ar[n] = medinc_ar[n-1]
			atype_ar[n] = atype_ar[n-1]
		end
		else do
			avgsize_ar[n] = avgsize[origtazseq]
			medinc_ar[n] = medinc[origtazseq]
			atype_ar[n] = atype[origtazseq]
		end
		prevtaz = origtazseq
	end
	avgsize_v = a2v(avgsize_ar)
	medinc_v = a2v(medinc_ar)				//HBO,
	atype_v = a2v(atype_ar)					//HBO,
	cbddum = if (atype_v = 1) then 1 else 0			//SCH,HBU,HBW,HBS,
	at2dum = if (atype_v = 2) then 1 else 0			//SCH,HBU,
	at5dum = if (atype_v = 5) then 1 else 0			//HBU, HBW, HBO	--Bill sometimes calls this rurdum
	suburb = if (atype_v = 3 or atype_v = 4) then 1 else 0	//HBW, HBS, HBO
	urbdum = if (atype_v = 2 or atype_v = 3) then 1 else 0			//HBW,

//Go ahead and add new tour frequency fields to tourrecords.  
	tourrecords = OpenTable("tourrecords", "FFB", {DirArray + "\\TourRecords.bin",})
	strct = GetTableStructure(tourrecords)					
	for j = 1 to strct.length do
 		strct[j] = strct[j] + {strct[j][1]}
 	end
	strct = strct + {{"SCH", "Integer", 2,,,,,,,,,}}
	strct = strct + {{"HBU", "Integer", 2,,,,,,,,,}}
	strct = strct + {{"HBW", "Integer", 2,,,,,,,,,}}
	strct = strct + {{"HBS", "Integer", 2,,,,,,,,,}}
	strct = strct + {{"HBO", "Integer", 2,,,,,,,,,}}
	strct = strct + {{"ATW", "Integer", 2,,,,,,,,,}}

	ModifyTable(tourrecords, strct)

// ***********SCHOOL***********SCHOOL***********SCHOOL***********SCHOOL***********SCHOOL***********SCHOOL***********SCHOOL***********SCHOOL***********SCHOOL
  UpdateProgressBar("Calculating SCHOOL Tours.....", 10) 
  SetRandomSeed(667653)	

//Alternative percentages: 0 tours = 75.7%, 1 tour = 11.7%, 2 tours = 9.1%, 3 tours = 2.8%, 4 tours = 0.6%, 5 tours = 0.1%
	U1 = -7.417 + 5.345*lc2dum + 0.7053*avgsize_v - 0.5759*wkr3dum + 0.8065*siz34dum + 0.15*inc1dum - 1.9*cbddum + 0.1*at2dum + 2.4*lc1dum - 0.2*siz2dum + 0.50*siz5dum
	U2 = -9.370 + 5.796*lc2dum + 0.7053*avgsize_v - 1.5560*wkr3dum + 2.9150*siz45dum + 0.57*inc1dum - 8.0*cbddum - 0.2*at2dum + 1.1*lc1dum - 3.0*siz2dum + 0.35*siz5dum

	E2U0 = Vector(hhid.length, "float", {{"Constant", 1}})
	E2U1 = if (lc = 3 or size = 1) then 0 else exp(U1)				//LC=3 & Size=1 have no SCH tours
	E2U2 = if (lc = 3 or size = 1) then 0 else exp(U2)				//Initial alternatives are 0, 1 & 2+ SCH tours
	E2U_sum = E2U0 + E2U1+ E2U2

	prob0 = E2U0 / E2U_sum
	prob1 = E2U1 / E2U_sum
	prob2 = E2U2 / E2U_sum
	cumprob01 = prob0 + prob1
	choice_v = Vector(hhid.length, "short", {{"Constant", 0}})

//Do a big loop in order to sort each HH's alternatives by ascending probability.  If the chosen alternative is 2+ SCH tours, then pick a 2nd random # and select based on percentage of 2+.
	for n = 1 to hhid.length do
		if (lc[n] < 3 and size[n] > 1) then do
			rand_val = RandomNumber()
			if (rand_val < cumprob01[n]) then do
				choice_v[n] = if (rand_val < prob0[n]) then 0 else 1
			end
			//The 2+ categories are 2 (71.0% of all 2+ tours), 3 (21.5%), 4 (5.5%) & 5 (2.0%)
			else do
				rand_val = RandomNumber()
				choice_v[n] = if (rand_val < 0.710) then 2 else if (rand_val < 0.925) then 3 else if (rand_val < 0.980) then 4 else 5
			end
		end
	end
	
	school_v = choice_v
	SetDataVector(tourrecords+"|", "SCH", choice_v,)

dim tbysize[5]
dim tbyincome[4]
dim tbylife[3]
dim tbywkr[4]
dim pctsize[5]
dim pctincome[4]
dim pctlife[3]
dim pctwkr[4]

tottour = VectorStatistic(choice_v, "Sum",)
for s = 1 to 5 do
	stat = if (size = s) then choice_v else 0
	tbysize[s] = VectorStatistic(stat, "Sum",)
	pctsize[s] = tbysize[s] / tottour
end
for i = 1 to 4 do
	stat = if (income = i) then choice_v else 0
	tbyincome[i] = VectorStatistic(stat, "Sum",)
	pctincome[i] = tbyincome[i] / tottour
end
for l = 1 to 3 do
	stat = if (lc = l) then choice_v else 0
	tbylife[l] = VectorStatistic(stat, "Sum",)
	pctlife[l] = tbylife[l] / tottour
end
for w = 1 to 4 do
	stat = if (wrkr = w-1) then choice_v else 0
	tbywkr[w] = VectorStatistic(stat, "Sum",)
	pctwkr[w] = tbywkr[w] / tottour
end
reportfile = OpenFile(DirArray + "\\tf_report.txt","w")
WriteLine(reportfile, "Tour Frequency Results")
WriteLine(reportfile, "Total School Tours:")
WriteLine(reportfile, r2s(tottour))
WriteLine(reportfile, "Total School Tours & Percentage By Size Categories (1-5)")
WriteArray(reportfile, tbysize)
WriteArray(reportfile, pctsize)
WriteLine(reportfile, "Total School Tours & Percentage By Income Categories (1-4)")
WriteArray(reportfile, tbyincome)
WriteArray(reportfile, pctincome)
WriteLine(reportfile, "Total School Tours & Percentage By Life Cycle Categories (1-3)")
WriteArray(reportfile, tbylife)
WriteArray(reportfile, pctlife)
WriteLine(reportfile, "Total School Tours & Percentage By Worker Categories (0-3)")
WriteArray(reportfile, tbywkr)
WriteArray(reportfile, pctwkr)

// ***********HBU***********HBU***********HBU***********HBU***********HBU***********HBU***********HBU***********HBU***********HBU***********HBU***********HBU
   UpdateProgressBar("Calculating HBU Tours.....", 10) 
  SetRandomSeed(67653)	
//Alternative percentages: 0 tours = 96.3%, 1 tour = 3.2%, 2 tours = 0.4%, 3 tours = 0.1%

	U1 = -6.056 + 1.040*size - 0.7481*school_v - 1.0*lc1dum - 0.8*inc1dum + 0.08*inc2dum + 0.3*cbddum + 0.1*at2dum + 0.8*siz3dum - 0.3*at5dum  + 0.25*wkr0dum + 0.25*wkr3dum + 0.26

	E2U0 = Vector(hhid.length, "float", {{"Constant", 1}})
	E2U1 = exp(U1)						//Initial alternatives are 0, 1+ HBU tours
	E2U_sum = E2U0 + E2U1

	prob0 = E2U0 / E2U_sum
	prob1 = E2U1 / E2U_sum
	cumprob01 = prob0 + prob1

	choice_v = Vector(hhid.length, "short", {{"Constant", 0}})	//reset choice vector to 0 tours

//Do a big loop in order to sort each HH's alternatives by ascending probability.  
	for n = 1 to hhid.length do
		rand_val = RandomNumber()
		//if probability of 1 HBU tour is less than random number then 0 tours, else use 1+ fractions:
		//The 1+ categories are 1 (88.0% of all 1+ tours), 2 (11.0%) & 3 (1.0%)
		if (rand_val >= prob0[n]) then do
			rand_val = RandomNumber()
			choice_v[n] = if (rand_val < 0.880) then 1 else if (rand_val < 0.990) then 2 else 3
		end
	end
	hbu_v = choice_v

	SetDataVector(tourrecords+"|", "HBU", choice_v,)

tottour = VectorStatistic(choice_v, "Sum",)
for s = 1 to 5 do
	stat = if (size = s) then choice_v else 0
	tbysize[s] = VectorStatistic(stat, "Sum",)
	pctsize[s] = tbysize[s] / tottour
end
for i = 1 to 4 do
	stat = if (income = i) then choice_v else 0
	tbyincome[i] = VectorStatistic(stat, "Sum",)
	pctincome[i] = tbyincome[i] / tottour
end
for l = 1 to 3 do
	stat = if (lc = l) then choice_v else 0
	tbylife[l] = VectorStatistic(stat, "Sum",)
	pctlife[l] = tbylife[l] / tottour
end
for w = 1 to 4 do
	stat = if (wrkr = w-1) then choice_v else 0
	tbywkr[w] = VectorStatistic(stat, "Sum",)
	pctwkr[w] = tbywkr[w] / tottour
end
WriteLine(reportfile, "Total HBU Tours:")
WriteLine(reportfile, r2s(tottour))
WriteLine(reportfile, "Total HBU Tours & Percentage By Size Categories (1-5)")
WriteArray(reportfile, tbysize)
WriteArray(reportfile, pctsize)
WriteLine(reportfile, "Total HBU Tours & Percentage By Income Categories (1-4)")
WriteArray(reportfile, tbyincome)
WriteArray(reportfile, pctincome)
WriteLine(reportfile, "Total HBU Tours & Percentage By Life Cycle Categories (1-3)")
WriteArray(reportfile, tbylife)
WriteArray(reportfile, pctlife)
WriteLine(reportfile, "Total HBU Tours & Percentage By Worker Categories (0-3)")
WriteArray(reportfile, tbywkr)
WriteArray(reportfile, pctwkr)

// ***********HBW***********HBW***********HBW***********HBW***********HBW***********HBW***********HBW***********HBW***********HBW***********HBW***********HBW
    UpdateProgressBar("Calculating HBW Tours.....", 10) 
  SetRandomSeed(7653)	

//Alternative percentages: 0 tours = 51.9%, 1 tour = 29.2%, 2 tours = 15.0%, 3 tours = 3.1%, 4 tours = 0.7%, 5 tours = 0.1%

	U1 = -2.781 + 2.543*wrkr + 0.1779*siz345dum + 0.1346*school_v + 0.5*inc1dum + 1.0*wkr1dum - 1.1*cbddum + 1.0*urbdum - 0.3*at5dum - 0.76 + 0.9*suburb
	U2 = -7.242 + 4.809*wrkr + 0.1779*siz345dum + 0.1346*school_v + 1.0*urbdum - 0.3*at5dum - 0.76 + 0.9*suburb

	E2U0 = Vector(hhid.length, "float", {{"Constant", 1}})
	E2U1 = if (wrkr = 0) then 0 else exp(U1)			//if wrkr = 0, then can be no work tours
	E2U2 = if (wrkr = 0) then 0 else exp(U2)
	E2U_sum = E2U0 + E2U1+ E2U2

	prob0 = E2U0 / E2U_sum
	prob1 = E2U1 / E2U_sum
	prob2 = E2U2 / E2U_sum
	cumprob01 = prob0 + prob1
	choice_v = Vector(hhid.length, "short", {{"Constant", 0}})	//reset choice vector to 0 tours

//Do a big loop in order to sort each HH's alternatives by ascending probability.  If the chosen alternative is 2+ HBW tours, then pick a 2nd random # and select based on percentage of 2+.
	for n = 1 to hhid.length do
		if wrkr[n] > 0 then do
			rand_val = RandomNumber()
			if (rand_val < cumprob01[n]) then do
				choice_v[n] = if (rand_val < prob0[n]) then 0 else 1
			end
			//The 2+ categories are 2 (78.0% of all 2+ tours), 3 (17.8%), 4 (3.7%) & 5 (0.5%)
			else do
				rand_val = RandomNumber()
				choice_v[n] = if (rand_val < 0.780) then 2 else if (rand_val < 0.958) then 3 else if (rand_val < 0.995) then 4 else 5
			end
		end
	end
	
	hbw_v = choice_v
	SetDataVector(tourrecords+"|", "HBW", choice_v,)

tottour = VectorStatistic(choice_v, "Sum",)
for s = 1 to 5 do
	stat = if (size = s) then choice_v else 0
	tbysize[s] = VectorStatistic(stat, "Sum",)
	pctsize[s] = tbysize[s] / tottour
end
for i = 1 to 4 do
	stat = if (income = i) then choice_v else 0
	tbyincome[i] = VectorStatistic(stat, "Sum",)
	pctincome[i] = tbyincome[i] / tottour
end
for l = 1 to 3 do
	stat = if (lc = l) then choice_v else 0
	tbylife[l] = VectorStatistic(stat, "Sum",)
	pctlife[l] = tbylife[l] / tottour
end
for w = 1 to 4 do
	stat = if (wrkr = w-1) then choice_v else 0
	tbywkr[w] = VectorStatistic(stat, "Sum",)
	pctwkr[w] = tbywkr[w] / tottour
end
WriteLine(reportfile, "Total HBW Tours:")
WriteLine(reportfile, r2s(tottour))
WriteLine(reportfile, "Total HBW Tours & Percentage By Size Categories (1-5)")
WriteArray(reportfile, tbysize)
WriteArray(reportfile, pctsize)
WriteLine(reportfile, "Total HBW Tours & Percentage By Income Categories (1-4)")
WriteArray(reportfile, tbyincome)
WriteArray(reportfile, pctincome)
WriteLine(reportfile, "Total HBW Tours & Percentage By Life Cycle Categories (1-3)")
WriteArray(reportfile, tbylife)
WriteArray(reportfile, pctlife)
WriteLine(reportfile, "Total HBW Tours & Percentage By Worker Categories (0-3)")
WriteArray(reportfile, tbywkr)
WriteArray(reportfile, pctwkr)

// ***********HBS***********HBS***********HBS***********HBS***********HBS***********HBS***********HBS***********HBS***********HBS***********HBS***********HBS
    UpdateProgressBar("Calculating HBS Tours.....", 10) 
  SetRandomSeed(653)	

//Alternative percentages: 0 tours = 67.7%, 1 tour = 22.0%, 2 tours = 7.7%, 3 tours = 1.9%, 4 tours = 0.5%, 5 tours = 0.1%, 6 tours = 0.1%

	U1 = -1.606 + 0.3866*size - 0.5960*lc2dum + 1.05*suburb - 0.2518*(school_v + hbu_v) - 0.5492*hbw_v - 0.25*cbddum + 0.2*wkr1dum + 0.48
	U2 = -3.464 + 0.9283*size - 0.5960*lc2dum + 1.05*suburb - 0.2518*(school_v + hbu_v) - 0.5492*hbw_v - 0.1883*wrkr - 0.9*cbddum - 0.3*wkr1dum + 0.48

	E2U0 = Vector(hhid.length, "float", {{"Constant", 1}})
	E2U1 = exp(U1)
	E2U2 = exp(U2)					
	E2U_sum = E2U0 + E2U1+ E2U2

	prob0 = E2U0 / E2U_sum
	prob1 = E2U1 / E2U_sum
	prob2 = E2U2 / E2U_sum
	cumprob01 = prob0 + prob1
	choice_v = Vector(hhid.length, "short", {{"Constant", 0}})	//reset choice vector to 0 tours

//Do a big loop in order to sort each HH's alternatives by ascending probability.  If the chosen alternative is 2+ HBW tours, then pick a 2nd random # and select based on percentage of 2+.
	for n = 1 to hhid.length do
		rand_val = RandomNumber()
		if (rand_val < cumprob01[n]) then do
			choice_v[n] = if (rand_val < prob0[n]) then 0 else 1
		end
		//The 2+ categories are 2 (74.8% of all 2+ tours), 3 (18.4%), 4 (4.9%), 5 (1.0%) & 6 (1.0%)
		else do
			rand_val = RandomNumber()
			choice_v[n] = if (rand_val < 0.750) then 2 else if (rand_val < 0.925) then 3 else if (rand_val < 0.975) then 4 else if (rand_val < 0.978) then 5 else if (rand_val < 0.986) then 6 else 7
		end
	end
	
	hbs_v = choice_v
	SetDataVector(tourrecords+"|", "HBS", choice_v,)

tottour = VectorStatistic(choice_v, "Sum",)
for s = 1 to 5 do
	stat = if (size = s) then choice_v else 0
	tbysize[s] = VectorStatistic(stat, "Sum",)
	pctsize[s] = tbysize[s] / tottour
end
for i = 1 to 4 do
	stat = if (income = i) then choice_v else 0
	tbyincome[i] = VectorStatistic(stat, "Sum",)
	pctincome[i] = tbyincome[i] / tottour
end
for l = 1 to 3 do
	stat = if (lc = l) then choice_v else 0
	tbylife[l] = VectorStatistic(stat, "Sum",)
	pctlife[l] = tbylife[l] / tottour
end
for w = 1 to 4 do
	stat = if (wrkr = w-1) then choice_v else 0
	tbywkr[w] = VectorStatistic(stat, "Sum",)
	pctwkr[w] = tbywkr[w] / tottour
end
WriteLine(reportfile, "Total HBS Tours:")
WriteLine(reportfile, r2s(tottour))
WriteLine(reportfile, "Total HBS Tours & Percentage By Size Categories (1-5)")
WriteArray(reportfile, tbysize)
WriteArray(reportfile, pctsize)
WriteLine(reportfile, "Total HBS Tours & Percentage By Income Categories (1-4)")
WriteArray(reportfile, tbyincome)
WriteArray(reportfile, pctincome)
WriteLine(reportfile, "Total HBS Tours & Percentage By Life Cycle Categories (1-3)")
WriteArray(reportfile, tbylife)
WriteArray(reportfile, pctlife)
WriteLine(reportfile, "Total HBS Tours & Percentage By Worker Categories (0-3)")
WriteArray(reportfile, tbywkr)
WriteArray(reportfile, pctwkr)

// ***********HBO***********HBO***********HBO***********HBO***********HBO***********HBO***********HBO***********HBO***********HBO***********HBO***********HBO
    UpdateProgressBar("Calculating HBO Tours.....", 10) 
  SetRandomSeed(53)	

//Alternative percentages: 0 tours = 35.4%, 1 tour = 26.6%, 2 tours = 19.7%, 3 tours = 8.1%, 4 tours = 4.9%, 5 tours = 2.2%, 6 tours = 1.7%, 7 tours = 0.6%, 8 tours = 0.5%, 9 tours = 0.2%, 10 tours = 0.1%

	U1 = -0.1911 + 0.8086*size + 0.3765*lc2dum - 0.2502*wrkr - 0.12369*atype_v + 0.000005842*medinc_v - 0.6965*(school_v + hbu_v) - 1.035*hbw_v - 0.8163*hbs_v + 0.3254*inc4dum - 0.5*siz1dum + 1.5*urbdum - 0.3*at5dum + 0.94 + 0.9*suburb
	U2 = -0.5274 + 0.8086*size + 0.3765*lc2dum - 0.2502*wrkr - 0.12369*atype_v + 0.000005842*medinc_v - 0.6965*(school_v + hbu_v) - 1.035*hbw_v - 0.8163*hbs_v + 0.3254*inc4dum - 1.4*siz1dum + 1.5*urbdum - 0.3*at5dum + 0.94 + 0.9*suburb
	U3 = -2.880 + 1.421*size + 0.3765*lc2dum - 0.5127*wrkr - 0.12369*atype_v + 0.000005842*medinc_v - 0.6965*(school_v + hbu_v) - 1.035*hbw_v - 0.8163*hbs_v + 0.6236*inc4dum - 0.6706*inc1dum - 1.6*siz1dum + 1.5*urbdum - 0.3*at5dum + 0.94 + 0.9*suburb
	U4 = -4.202 + 1.859*size + 0.3765*lc2dum - 0.5127*wrkr - 0.12369*atype_v + 0.000005842*medinc_v - 0.6965*(school_v + hbu_v) - 1.035*hbw_v - 0.8163*hbs_v + 0.6085*inc4dum - 0.7486*inc1dum - 2.0*siz1dum + 1.5*urbdum - 0.3*at5dum + 0.94 + 0.9*suburb

	E2U0 = Vector(hhid.length, "float", {{"Constant", 1}})
	E2U1 = exp(U1)
	E2U2 = exp(U2)
	E2U3 = exp(U3)
	E2U4 = exp(U4)
	E2U_sum = E2U0 + E2U1+ E2U2 + E2U3+ E2U4

	prob0 = E2U0 / E2U_sum
	prob1 = E2U1 / E2U_sum
	prob2 = E2U2 / E2U_sum
	prob3 = E2U3 / E2U_sum
	prob4 = E2U4 / E2U_sum

	cumprob01 = prob0 + prob1
	cumprob02 = prob0 + prob1 + prob2
	cumprob03 = prob0 + prob1 + prob2 + prob3
	choice_v = Vector(hhid.length, "short", {{"Constant", 0}})

//Do a big loop in order to sort each HH's alternatives by ascending probability.  If the chosen alternative is 4+ HBO tours, then pick a 2nd random # and select based on percentage of 4+.
	for n = 1 to hhid.length do
		rand_val = RandomNumber()
		if (rand_val < cumprob03[n]) then do
			choice_v[n] = if (rand_val < prob0[n]) then 0 else if (rand_val < cumprob01[n]) then 1 else if (rand_val < cumprob02[n]) then 2 else 3
		end
		//The 4+ categories are 4 (47.0% of all 4+ tours), 5 (23.0%), 6 (15.0%), 7 (7.0%), 8 (3.5%), 9 (1.5%) & 10 (3.0%)
		else do
			rand_val = RandomNumber()
			choice_v[n] = if (rand_val < 0.470) then 4 else if (rand_val < 0.700) then 5 else if (rand_val < 0.850) then 6 else if (rand_val < 0.920) then 7 else if (rand_val < 0.955) then 8 else if (rand_val < 0.970) then 9 else 10
		end
	end
	
	hbo_v = choice_v
	SetDataVector(tourrecords+"|", "HBO", choice_v,)


tottour = VectorStatistic(choice_v, "Sum",)
for s = 1 to 5 do
	stat = if (size = s) then choice_v else 0
	tbysize[s] = VectorStatistic(stat, "Sum",)
	pctsize[s] = tbysize[s] / tottour
end
for i = 1 to 4 do
	stat = if (income = i) then choice_v else 0
	tbyincome[i] = VectorStatistic(stat, "Sum",)
	pctincome[i] = tbyincome[i] / tottour
end
for l = 1 to 3 do
	stat = if (lc = l) then choice_v else 0
	tbylife[l] = VectorStatistic(stat, "Sum",)
	pctlife[l] = tbylife[l] / tottour
end
for w = 1 to 4 do
	stat = if (wrkr = w-1) then choice_v else 0
	tbywkr[w] = VectorStatistic(stat, "Sum",)
	pctwkr[w] = tbywkr[w] / tottour
end
WriteLine(reportfile, "Total HBO Tours:")
WriteLine(reportfile, r2s(tottour))
WriteLine(reportfile, "Total HBO Tours & Percentage By Size Categories (1-5)")
WriteArray(reportfile, tbysize)
WriteArray(reportfile, pctsize)
WriteLine(reportfile, "Total HBO Tours & Percentage By Income Categories (1-4)")
WriteArray(reportfile, tbyincome)
WriteArray(reportfile, pctincome)
WriteLine(reportfile, "Total HBO Tours & Percentage By Life Cycle Categories (1-3)")
WriteArray(reportfile, tbylife)
WriteArray(reportfile, pctlife)
WriteLine(reportfile, "Total HBO Tours & Percentage By Worker Categories (0-3)")
WriteArray(reportfile, tbywkr)
WriteArray(reportfile, pctwkr)

// *********** Create & fill total productions table

	se_vw = OpenTable("SEFile", "dBASE", {sedata_file,})
	
	prod_attr = CreateTable("prod_attr", DirArray + "\\Productions_Attractions.bin", "FFB", {
		{"TAZ", "Short", 5, null, "Yes"},
		{"P_SCH", "Short", 5, null, "No"}, {"P_HBU", "Short", 5, null, "No"}, {"P_HBW", "Short", 5, null, "No"},
		{"P_HBS", "Short", 5, null, "No"}, {"P_HBO", "Short", 5, null, "No"}, {"P_ATW", "Short", 5, null, "No"},
		{"A_TOT_SCH", "Short", 5, null, "No"}, {"A_TOT_HBU", "Short", 5, null, "No"}, {"A_TOT_HBW", "Short", 5, null, "No"},
		{"A_TOT_HBS", "Short", 5, null, "No"}, {"A_TOT_HBO", "Short", 5, null, "No"}, {"A_TOT_ATW", "Short", 5, null, "No"},
		{"DC_II_SCH", "Short", 5, null, "No"}, {"DC_II_HBU", "Short", 5, null, "No"}, {"DC_II_HBW", "Short", 5, null, "No"},
		{"DC_II_HBS", "Short", 5, null, "No"}, {"DC_II_HBO", "Short", 5, null, "No"}, {"DC_II_ATW", "Short", 5, null, "No"},
		{"DC_IX", "Short", 5, null, "No"}, {"DC_XIN", "Short", 5, null, "No"}, {"DC_XIW", "Short", 5, null, "No"},
		{"DC_IS_SCH", "Short", 5, null, "No"}, {"DC_IS_HBU", "Short", 5, null, "No"}, {"DC_IS_HBW", "Short", 5, null, "No"},
		{"DC_IS_HBS", "Short", 5, null, "No"}, {"DC_IS_HBO", "Short", 5, null, "No"}, {"DC_IS_ATW", "Short", 5, null, "No"},
		{"DC_IS_IX", "Short", 5, null, "No"}, {"DC_IS_XIN", "Short", 5, null, "No"}, {"DC_IS_XIW", "Short", 5, null, "No"}
		})
	
	rh = AddRecords("prod_attr", null, null, {{"Empty Records", taz.length}})
	SetDataVector(prod_attr+"|", "TAZ", taz,)
		
	jointab = JoinViews("jointab", "SEFile.TAZ", "tourrecords.TAZ", {{"A", }, 
			{"Fields", {{"SCH", {{"Sum"}}}, {"HBU", {{"Sum"}}}, {"HBW", {{"Sum"}}}, {"HBS", {{"Sum"}}}, {"HBO", {{"Sum"}}}}}})
	flds = {"SCH", "HBU", "HBW", "HBS", "HBO"}
	flds2 = {"P_SCH", "P_HBU", "P_HBW", "P_HBS", "P_HBO"}
	for i = 1 to flds.length do
		p_tot = GetDataVector(jointab+"|", flds[i], )
		SetDataVector(prod_attr+"|", flds2[i], p_tot, )
	end

    DestroyProgressBar()
    RunMacro("G30 File Close All")


//ATW tour program will need to follow HBW destination choice model, since it includes Work Zone density as a variable
// ***********ATW***********ATW***********ATW***********ATW***********ATW***********ATW***********ATW***********ATW***********ATW***********ATW***********ATW

    goto quit
skiptoend:
	badquit:
		on error, notfound default
		RunMacro("TCB Closing", ret_value, "TRUE" )
		msg = msg + {"Tour Frequency: Error somewhere"}
		AppendToLogFile(1, "Tour Frequency: Error somewhere")
		datentime = GetDateandTime()
		AppendToLogFile(1, "Tour Frequency " + datentime)

       	return({0, msg})

    quit:
		on error, notfound default
   		datentime = GetDateandTime()
		AppendToLogFile(1, "Exit Tour Frequency " + datentime)
    	return({1, msg})
		
 
endmacro