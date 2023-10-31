Macro "HwyAssn_RunPMPeak" (Args)

// Macro sets input files and calls hwyassn_MMA
// This version runs hwyassn_gc_mrm - it has the option to switch to bpr   JWM 09/24/16		
// 5/30/19, mk: There are now three distinct networks: AM peak, PM peak, and offpeak; pass correct netview through


	LogFile = Args.[Log File].value
	SetLogFileName(LogFile)
	ReportFile = Args.[Report File].value
	SetReportFileName(ReportFile)

	Dir = Args.[Run Directory].value
	msg = null

	datentime = GetDateandTime()
	AppendToLogFile(1, "Enter HwyAssn_RunPMPeak: " + datentime)

	od_matrix = Dir + "\\tod2\\ODHwyVeh_PMPeak.mtx"
	cap_field = "CapPk3hr"
	output_bin = Dir + "\\HwyAssn\\Assn_PMPeak.bin"

	timeperiod = "PMpeak"

	HwyAssnPMOK = RunMacro("HwyAssn_MMA", Args, od_matrix, cap_field, output_bin, timeperiod)

//	HwyAssnPMOK = RunMacro("HwyAssn_gc_mrm", Args, od_matrix, cap_field, output_bin)

 	od_matrix = null
	cap_field = null
	output_bin = null
	netview = null

	datentime = GetDateandTime()
	AppendToLogFile(1, "Exit HwyAssn_RunPMPeak: " + datentime)

	return ({HwyAssnPMOK, msg})
	
endmacro