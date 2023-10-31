Macro "Update_Drive_PNR_Skims" (m1File, m2File, m3File)

//	Takes about 9 minutes to run

// Replaces fortran routine UPD_DA_Dist_Time_Costv2.for
//	Three Matricies of different sizes called
//	/skims/peakpremium_DADist.mtx	or offpeak or bus etc.
//	/skims/skim_pnr_peak_prm.mtx
//	/skims/skim_pnr2dest_peak_prm.mtx

//	Dir = "D:\\1901AQ_2045\\Metrolina\\2045"

	//m1 - DADist matrix (taz x taz)
//	m1File = Dir + "\\skims\\peakpremium_DADist.mtx"
	m1 = OpenMatrix(m1File,)
	m1Info = GetMatrixInfo(m1)
	m1RowName = m1Info[1][1]
	m1ColName = m1Info[2][1]
	m1NumRows = m1Info[5][1]
	m1NumCols = m1Info[5][2]
//	showmessage("m1 Row Name = " + m1RowName + ", num rows = " + i2s(m1NumRows) + "\n" + 
//				"m1 Col Name = " + m1ColName + ", num cols = " + i2s(m1NumCols))
	m1Cores = GetMatrixCoreNames(m1)
//	ShowArray(m1Cores) 
	m1cost		= CreateMatrixCurrency(m1, m1Cores[1], m1RowName, m1ColName,)
	m1drivelen	= CreateMatrixCurrency(m1, m1Cores[2], m1RowName, m1ColName,)
	m1parknode	= CreateMatrixCurrency(m1, m1Cores[3], m1RowName, m1ColName,)
	m1drivetime	= CreateMatrixCurrency(m1, m1Cores[4], m1RowName, m1ColName,)
	m1pnr2dest	= CreateMatrixCurrency(m1, m1Cores[5], m1RowName, m1ColName,)
	m1pnrcost	= CreateMatrixCurrency(m1, m1Cores[8], m1RowName, m1ColName,)

	//m2 - skim_pnr_<tod>_<prm/bus> (taz x pnr)
//	m2File = Dir + "\\skims\\skim_pnr_peak_prm.mtx"
	m2 = OpenMatrix(m2File,)
	m2Info = GetMatrixInfo(m2)
	m2RowName = m2Info[1][1]
	m2ColName = m2Info[2][1]
	m2NumRows = m2Info[5][1]
	m2NumCols = m2Info[5][2]
//	showmessage("m2 Row Name = " + m2RowName + ", num rows = " + i2s(m2NumRows) + "\n" + 
//				"m2 Col Name = " + m2ColName + ", num cols = " + i2s(m2NumCols)) 
	m2Cores = GetMatrixCoreNames(m2)
//	ShowArray(m2Cores) 
	m2drivelen	= CreateMatrixCurrency(m2, m2Cores[2], m2RowName, m2ColName,)
	m2drivetime	= CreateMatrixCurrency(m2, m2Cores[3], m2RowName, m2ColName,)
	m2pnrcost	= CreateMatrixCurrency(m2, m2Cores[5], m2RowName, m2ColName,)

	//m3 - skim_pnr2dest_<tod>_<prm/bus> (pnr x taz)
//	m3File = Dir + "\\skims\\skim_pnr2dest_peak_prm.mtx"
	m3 = OpenMatrix(m3File,)
	m3Info = GetMatrixInfo(m3)
	m3RowName = m3Info[1][1]
	m3ColName = m3Info[2][1]
	m3NumRows = m3Info[5][1]
	m3NumCols = m3Info[5][2]
//	showmessage("m3 Row Name = " + m3RowName + ", num rows = " + i2s(m3NumRows) + "\n" + 
//				"m3 Col Name = " + m3ColName + ", num cols = " + i2s(m3NumCols)) 
	m3Cores = GetMatrixCoreNames(m3)
//	ShowArray(m3Cores) 
	m3pnr2dest	= CreateMatrixCurrency(m3, m2Cores[2], m3RowName, m3ColName,)


	// loop thru taz x taz
	for i = 1 to m1NumRows do
		for j = 1 to m1NumCols do
			si = i2s(i)
			sj = i2s(j)
			cost = GetMatrixValue(m1cost, si, sj)   
			parknode = GetMatrixValue(m1parknode, si, sj)
			if parknode > 0 then do
	      			prkindex	= r2s(parknode)
					drivelen	= GetMatrixValue(m2drivelen, si, prkindex)
					drivetime	= GetMatrixValue(m2drivetime, si, prkindex)
					pnrcost		= GetMatrixValue(m2pnrcost, si, prkindex)
					pnr2dest	= GetMatrixValue(m3pnr2dest, prkindex, sj)
					if cost > 0 and drivelen > 0 then do
						cost2 = (100 * cost) + (10 * drivelen) + (0.5 * pnrcost)
						SetMatrixValue(m1cost, si, sj, cost2)
	 					SetMatrixValue(m1drivelen, si, sj, drivelen)
						SetMatrixValue(m1drivetime, si, sj, drivetime)
						SetMatrixValue(m1pnr2dest, si, sj, pnr2dest)
						SetMatrixValue(m1pnrcost, si, sj, pnrcost)
					end // if cost
			end // if parknode
		end // for j
	end // for i

	m1 = null
	m2 = null
	m2 = null
endmacro