Macro "MS_RunOffPeak" (Args)
// Macro to call batch file \modesplit\MS_<year>_RUNOFFPEAK.bat - batch file calls 4 peak mode choice runs - HBW, HBO, NHB, HBU


	LogFile = Args.[Log File].value
	ReportFile = Args.[Report File].value
	SetLogFileName(LogFile)
	SetReportFileName(ReportFile)

	Dir = Args.[Run Directory].value
	theyear = Args.[Run Year].value
	msg = null
	MSOffPeakOK = 1

	datentime = GetDateandTime()
	AppendToLogFile(1, "Enter MS_RunOffPeak: " + datentime)

// run batch file

	runprogram(Dir + "\\modesplit\\" + theyear + "_RUNOFFPEAK.BAT",)

// post process matrices

	MC_matrices = {"HBW_OFFPEAK_MS", "HBO_OFFPEAK_MS", "HBU_OFFPEAK_MS", "NHB_OFFPEAK_MS"}
		for mat = 1 to MC_matrices.length do
			M  = OpenMatrix(Dir + "\\modesplit\\" + MC_matrices[mat] + ".mtx", "True")
			RenameMatrix(M,  MC_matrices[mat])
			
			idx  = Getmatrixindex(M)
			idxnew = {"Rows", "Columns"}
			
			for index = 1 to idx.length do
				if idx[index] <> idxnew[index] then do
					SetMatrixIndexName(M, idx[index], idxnew[index])
				end
		end
	end

	//check competion
	rtn = RunMacro("GetFieldCore", Dir + "\\ModeSplit\\HBW_OFFPEAK_MS.mtx", "Drive Alone")
	if rtn[1] = 0
		then do 
			AppendToLogFile(2, "ERROR - Drive Alone matrix empty - HBW_OFFPEAK_MS.mtx")
			MSOffPeakOK = 0
		end
	rtn = RunMacro("GetFieldCore", Dir + "\\ModeSplit\\HBO_OFFPEAK_MS.mtx", "Drive Alone")
	if rtn[1] = 0
		then do 
			AppendToLogFile(2, "ERROR - Drive Alone matrix empty - HBO_OFFPEAK_MS.mtx")
			MSOffPeakOK = 0
		end
	rtn = RunMacro("GetFieldCore", Dir + "\\ModeSplit\\NHB_OFFPEAK_MS.mtx", "Drive Alone")
	if rtn[1] = 0
		then do 
			AppendToLogFile(2, "ERROR - Drive Alone matrix empty - NHB_OFFPEAK_MS.mtx")
			MSOffPeakOK = 0
		end
	rtn = RunMacro("GetFieldCore", Dir + "\\ModeSplit\\HBU_OFFPEAK_MS.mtx", "Drive Alone")
	if rtn[1] = 0
		then do 
			AppendToLogFile(2, "ERROR - Drive Alone matrix empty - HBU_OFFPEAK_MS.mtx")
			MSOffPeakOK = 0
		end

	datentime = GetDateandTime()
	AppendToLogFile(1, "Exit MS_RunOffPeak: " + datentime)
	return({MSOffPeakOK, msg})
	
EndMacro