Macro "MS_HBWOffPeak" (Args)

// Macro to call HBW_OffPeak Modechoice ONLY - Not a part of standard conformity run (Conformity run uses MS_OffRunPeak)

	LogFile = Args.[Log File].value
	SetLogFileName(LogFile)
	ReportFile = Args.[Report File].value
	SetReportFileName(ReportFile)

	Dir = Args.[Run Directory].value
	theyear = Args.[Run Year].value
	
	msg = null
	MSOffPeakOK = 1

	datentime = GetDateandTime()
	AppendToLogFile(1, "Enter MS_HBWOffPeak, HBW OffPeak ONLY: " + datentime)

// run batch file

	runprogram(Dir + "\\modesplit\\" + theyear + "_HBW_OFFPEAK.BAT",)

// post process matrices

	M  = OpenMatrix(Dir + "\\modesplit\\HBW_OFFPEAK_MS.mtx", "True")
	RenameMatrix(M,  "HBW_OFFPEAK_MS")
			
	idx  = Getmatrixindex(M)
	idxnew = {"Rows", "Columns"}
			
	for index = 1 to idx.length do
		if idx[index] <> idxnew[index] then do
			SetMatrixIndexName(M, idx[index], idxnew[index])
		end
	end

	//check competion
	rtn = RunMacro("GetFieldCore", Dir + "\\ModeSplit\\HBW_OFFPEAK_MS.mtx", "Drive Alone")
	if rtn[1] = 0
		then do 
			AppendToLogFile(2, "ERROR - Drive Alone matrix empty - HBW_OFFPEAK_MS.mtx")
			MSOffPeakOK = 0
		end

	datentime = GetDateandTime()
	AppendToLogFile(1, "Exit MS_HBWOffPeak: " + datentime)
	return({MSOffPeakOK, msg})
	
EndMacro