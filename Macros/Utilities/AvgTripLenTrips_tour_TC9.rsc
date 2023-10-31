macro "AvgTripLenTrips_tour" (Args)

// 10/3/23: added {"Memory Only", "True"} to CopyMatrixStructure for TC9
	LogFile = Args.[Log File].value
	SetLogFileName(LogFile)

	Dir = Args.[Run Directory].value
	METDir = Args.[MET Directory].value
	msg = null
	atltripsOK = 1

	datentime = GetDateandTime()
	AppendToLogFile(1, "Enter AvgTripLenTrips: " + datentime)


//This macro just calculates the average trip lengths for each trip purpose.  A text file is created in the run's Report folder, to be input into the RunStats excel spreadsheet.

	purpose = {"hbw1", "HBW2", "HBW3", "HBW4",
		   "HBS1", "HBS2", "HBS3", "HBS4",
		   "HBO1", "HBO2", "HBO3", "HBO4",
		   "SCH",  "HBU",  "JTW",  "ATW",
		   "NWK",  "COM",  "MTK",  "HTK",
		   "EIW",  "EIN",  "EIC",  "EIM",  "EIH",
		   "IEW",  "IEN",  "IEC",  "IEM",  "IEH",
		   "EEA",  "EEC",  "EEM",  "EEH"}

	tod2 = {"AMPeakhot", "PMPeakhot", "MIDDAYhot", "NIGHThot"} 
	tod2_cores = {"SOV", "Pool2", "Pool3", "COM", "MTK", "HTK", "HOTSOV", "HOTPOOL2", "HOTPOOL3", "HOTCOM"} 

	hit = GetFileInfo(Dir + "\\skims\\SPMAT_peak_hov.mtx")
	if hit = null 
		then do 
			badfile = Dir + "\\skims\\SPMAT_peak_hov.mtx"	
			goto badend
		end
	hit = GetFileInfo(Dir + "\\skims\\SPMAT_free_hov.mtx")
	if hit = null 
		then do 
			badfile = Dir + "\\skims\\SPMAT_free_hov.mtx"	
			goto badend
		end
	hit = GetFileInfo(Dir + "\\skims\\TThwy_peak.mtx")
	if hit = null 
		then do 
			badfile = Dir + "\\skims\\TThwy_peak.mtx"	
			goto badend
		end
	hit = GetFileInfo(Dir + "\\skims\\TThwy_free.mtx")
	if hit = null 
		then do 
			badfile = Dir + "\\skims\\TThwy_free.mtx"	
			goto badend
		end

	peak_dist_m = OpenMatrix(Dir + "\\skims\\SPMAT_peak_hov.mtx",)
	free_dist_m = OpenMatrix(Dir + "\\skims\\SPMAT_free_hov.mtx",)
	peak_dist_mc = CreateMatrixCurrency(peak_dist_m, "Length (Skim)", "Origin", "Destination",)
	free_dist_mc = CreateMatrixCurrency(free_dist_m, "Length (Skim)", "Origin", "Destination",)

	peak_tt_m = OpenMatrix(Dir + "\\skims\\TThwy_peak.mtx",)
	free_tt_m = OpenMatrix(Dir + "\\skims\\TThwy_free.mtx",)
	peak_tt_mc = CreateMatrixCurrency(peak_tt_m, "TotalTT", "Rows", "Columns",)
	free_tt_mc = CreateMatrixCurrency(free_tt_m, "TotalTT", "Rows", "Columns",)

	//create a temporary matrix to do all the calculations on
	fill_mat = CopyMatrixStructure({peak_dist_mc}, {{"File Name", "temp_fill_mat.mtx"}, {"Label", "Fill Matrix"}, {"Type", "float"}, {"Memory Only", "True"}, {"Tables", {"AvgTripLen"}}})
	fill_mc = CreateMatrixCurrency(fill_mat, "AvgTripLen", "Rows", "Columns",)


	//work trips use peak travel times (HBW, EIW, IEW)
	imp_mtx = {"peak", "peak", "peak", "peak",
		   "free", "free", "free", "free",
		   "free", "free", "free", "free",
		   "free", "free", "peak", "free",
		   "free", "free", "free", "free",
		   "peak", "free", "free", "free", "free",
		   "peak", "free", "free", "free", "free",
		   "free", "free", "free", "free"}

	tod2_imp_mtx = {"peak", "peak", "free", "free"}
	   
	StatOutName = Dir + "\\Report\\AvgTripLength.csv"
  	exist = GetFileInfo(StatOutName)
  	if (exist <> null) then DeleteFile(StatOutName)
 
  	StatOut = OpenFile(StatOutName, "w")

//	AvgTripLengthTrips = CreateTable("AvgTripLengthTrips", DirReport + "\\AvgTripLengthTrips.bin", "FFB", {{"TOD", "String", 19, , "No"}, {"Measure", "String", 12, , "No"}, {"Result", "Real", 15, 4, "No"}}) 

	//do time of day calculations
	for i = 1 to tod2.length do
		if tod2_imp_mtx[i] = peak then do
			imp_dist_mc = peak_dist_mc
			imp_tt_mc = peak_tt_mc
		end
		else do
			imp_dist_mc = free_dist_mc
			imp_tt_mc = free_tt_mc
		end

		hit = GetFileInfo(Dir + "\\tod2\\ODHwyVeh_" + tod2[i] + ".mtx")
		if hit = null 
			then do 
				badfile = Dir + "\\tod2\\ODHwyVeh_" + tod2[i] + ".mtx"	
				goto badend
			end


		tod2_M = OpenMatrix(Dir + "\\tod2\\ODHwyVeh_" + tod2[i] + ".mtx",)

		//do average travel distance (miles) first
		for j = 1 to tod2_cores.length do
			tod2_mc = CreateMatrixCurrency(tod2_M, tod2_cores[j], "Rows", "Columns",)
			fill_mc := tod2_mc * imp_dist_mc
			tod2_M_stat_array = MatrixStatistics(tod2_M, {{"Tables", {tod2_cores[j]}}})
			tod2_M_sum = tod2_M_stat_array[1][2][2][2]		//Sum is the second statistic
			fill_mat_stat_array = MatrixStatistics(fill_mat, )
			fill_mat_sum = fill_mat_stat_array.AvgTripLen.Sum
			if tod2_M_sum > 0 then avg_trip_length = fill_mat_sum / tod2_M_sum
							  else avg_trip_length = 0
			WriteLine(StatOut, tod2[i] + tod2_cores[j] + ", ATL Miles, " + r2s(avg_trip_length))

			//now do average travel time (minutes)
			fill_mc := tod2_mc * imp_tt_mc
			fill_mat_stat_array = MatrixStatistics(fill_mat, )
			fill_mat_sum = fill_mat_stat_array.AvgTripLen.Sum
			if tod2_M_sum > 0 then avg_trip_length = fill_mat_sum / tod2_M_sum
							  else avg_trip_length = 0
			WriteLine(StatOut, tod2[i] + tod2_cores[j] + ", ATL Min, " + r2s(avg_trip_length))
		end
	end

	// AvgTripLengthTrips_tab1 = ExportView("AvgTripLengthTrips|", "CSV", DirReport + "\\AvgTripLengthTrips.csv",{"TOD", "Measure", "Result"}, { {"CSV Header", "True"} } )

	Closefile(StatOut)
	goto quit
		
	badend: 
	msg = msg + {"AvgTripLenTrips:  Error - file " + badfile + " not found"}
	AppendToLogFile(1, "AvgTripLenTrips:  Error - file " + badfile + " not found")
	atltripsOK = 0
	goto quit 
	
	quit: 
	datentime = GetDateandTime()
	AppendToLogFile(1, "Exit AvgTripLenTrips: " + datentime)
	return({atltripsOK, msg})

endmacro