macro "AvgTripLenTrips_tour_miles" (Args)

	Dir = "C:\\MRM1901_PPSL\\Metrolina\\2045"
 	DirOutDC  = Dir + "\\TD"
	
	RunMacro("TCB Init")
   	RunMacro("G30 File Close All")

//Note that IX tours are divided into Work (HBW only) and Non-Work(all the rest), so the dcEXT file is used twice.  Work uses peak travel distance
	purp =     {  "HBW",   "SCH",   "HBU",   "HBS",   "HBO",   "ATW",   "IXW",   "IXN",   "XIW",   "XIN"}
	purp_tab = {"dcHBW", "dcSCH", "dcHBU", "dcHBS", "dcHBO", "dcATW", "dcEXT", "dcEXT", "dcXIW", "dcXIN"}

	pkdist_m = OpenMatrix(Dir + "\\skims\\SPMAT_peak_hov.mtx",)
	pkdist_mc = CreateMatrixCurrency(pkdist_m, "Length (Skim)", "Origin", "Destination",)

	offpkdist_m = OpenMatrix(Dir + "\\skims\\SPMAT_free_hov.mtx",)
	offpkdist_mc = CreateMatrixCurrency(offpkdist_m, "Length (Skim)", "Origin", "Destination",)

	out_tab = CreateTable("out_tab", Dir + "\\Report\\AvgTripLengthMiles.bin", "FFB", {{"PURP", "String", 4,,"No"}, {"Tours", "Integer", 9, , "No"},  
					{"AVG_Dist", "Real", 8, 2, "No"}}) 
	rh = AddRecords("out_tab", , ,{{"Empty Records", purp.length}})
	purp_v = a2v(purp)
	SetDataVector("out_tab|", "PURP", purp_v,)


//	ix_file = OpenTable("ix_file", "FFB", {DirOutDC + "\\dcEXT.bin",})
	for p = 1 to purp.length do	// IXs selected by purpose as part of this loop; XIW and XIN in the next loop
		current_file = OpenTable("current_file", "FFB", {DirOutDC + "\\" + purp_tab[p] + ".bin",})

		//have to split IX (dcEXT) into IXW and IXN
		if purp[p] = "IXW" then do
			qry = "Select * where Purp = 'HBW'"
			SetView(current_file)
			recs = SelectByQuery("recs", "Several", qry)
			O_v = GetDataVector("current_file|recs", "ORIG_TAZ", {{"Sort Order", {{"ID","Ascending"}}}}) 
			D_v = GetDataVector("current_file|recs", "DEST_TAZ", {{"Sort Order", {{"ID","Ascending"}}}}) 
		end
		else if purp[p] = "IXN" then do
			qry = "Select * where Purp <> 'HBW'"
			SetView(current_file)
			recs = SelectByQuery("recs", "Several", qry)
			O_v = GetDataVector("current_file|recs", "ORIG_TAZ", {{"Sort Order", {{"ID","Ascending"}}}}) 
			D_v = GetDataVector("current_file|recs", "DEST_TAZ", {{"Sort Order", {{"ID","Ascending"}}}}) 
		end
		else do			
			O_v = GetDataVector("current_file|", "ORIG_TAZ", {{"Sort Order", {{"ID","Ascending"}}}}) 
			D_v = GetDataVector("current_file|", "DEST_TAZ", {{"Sort Order", {{"ID","Ascending"}}}}) 
		end
		dist_v = Vector(O_v.length, "float", )		

		//peak for HBW or IXW, offpeak for rest
		thismatcur = offpkdist_mc
		if purp[p] = "HBW" or purp[p] = "IXW" or purp[p] = "XIW" then do
			thismatcur = pkdist_mc
		end
		
		for n = 1 to O_v.length do
			dist_v[n] = GetMatrixValue(thismatcur, i2s(O_v[n]), i2s(D_v[n]))
		end
		distavg = VectorStatistic(dist_v, "Mean",)
		SetRecordValues("out_tab", i2s(p), {{"Tours", O_v.length}, {"AVG_Dist", distavg}})

		CloseView(current_file)

	end
		
		
   RunMacro("G30 File Close All")

endmacro