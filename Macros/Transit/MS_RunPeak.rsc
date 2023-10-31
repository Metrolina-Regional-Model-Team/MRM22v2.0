Macro "MS_RunPeak" (Args)
// Macro to call batch file \modesplit\MS_<year>_RUNPEAK.bat - batch file calls 4 peak mode choice runs - HBW, HBO, NHB, HBU

	LogFile = Args.[Log File].value
	SetLogFileName(LogFile)
	ReportFile = Args.[Report File].value
	SetReportFileName(ReportFile)

	Dir = Args.[Run Directory].value
	theyear = Args.[Run Year].value
	
	curiter = Args.[Current Feedback Iter].value
	MSPeakOK = 1
	msg = null

	datentime = GetDateandTime()
	AppendToLogFile(1, "Enter MS_RunPeak: " + datentime)
	AppendToLogFile(2, "AM Peak feedback iteration: " + i2s(curiter))

// run batch file

	runprogram(Dir + "\\modesplit\\" + theyear + "_RUNPEAK.BAT",)

// post process matrices

	MC_matrices = {"HBW_PEAK_MS", "HBO_PEAK_MS", "HBU_PEAK_MS", "NHB_PEAK_MS"}
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

// check completion
	rtn = RunMacro("GetFieldCore", Dir + "\\ModeSplit\\HBW_PEAK_MS.mtx", "Drive Alone")
	if rtn[1] = 0
		then do 
			AppendToLogFile(2, "ERROR - Drive Alone matrix empty - HBW_PEAK_MS.mtx")
			MSPeakOK = 0
		end
	rtn = RunMacro("GetFieldCore", Dir + "\\ModeSplit\\HBO_PEAK_MS.mtx", "Drive Alone")
	if rtn[1] = 0
		then do 
			AppendToLogFile(2, "ERROR - Drive Alone matrix empty - HBO_PEAK_MS.mtx")
			MSPeakOK = 0
		end
	rtn = RunMacro("GetFieldCore", Dir + "\\ModeSplit\\NHB_PEAK_MS.mtx", "Drive Alone")
	if rtn[1] = 0
		then do 
			AppendToLogFile(2, "ERROR - Drive Alone matrix empty - NHB_PEAK_MS.mtx")
			MSPeakOK = 0
		end
	rtn = RunMacro("GetFieldCore", Dir + "\\ModeSplit\\HBU_PEAK_MS.mtx", "Drive Alone")
	if rtn[1] = 0
		then do 
			AppendToLogFile(2, "ERROR - Drive Alone matrix empty - HBU_PEAK_MS.mtx")
			MSPeakOK = 0
		end
		

	datentime = GetDateandTime()
	AppendToLogFile(1, "Exit MS_RunPeak: " + datentime)
	return({MSPeakOK, msg})
	
EndMacro