Macro "HwyAssn_RunNight" (Args)

// Macro sets input files and calls hwyassn_MMA
// This version runs hwyassn_gc_mrm - it has the option to switch to bpr   JWM 09/24/16		
// 5/30/19, mk: There are now three distinct networks: AM peak, PM peak, and offpeak; pass correct netview through

	LogFile = Args.[Log File].value
	SetLogFileName(LogFile)
	ReportFile = Args.[Report File].value
	SetReportFileName(ReportFile)

	Dir = Args.[Run Directory].value
	msg = null
	HwyAssnOK = 1

	datentime = GetDateandTime()
	AppendToLogFile(1, "Enter HwyAssn_RunNight: " + datentime)


//Night

	od_matrix = Dir + "\\tod2\\ODHwyVeh_Night.mtx"
	cap_field = "capNight"
	output_bin = Dir + "\\HwyAssn\\Assn_Night.bin"

	timeperiod = "Offpeak"

	HwyAssnNtOK = RunMacro("HwyAssn_MMA", Args, od_matrix, cap_field, output_bin, timeperiod)

//	HwyAssnNtOK = RunMacro("HwyAssn_gc_mrm", Args, od_matrix, cap_field, output_bin)

 	od_matrix = null
	cap_field = null
	output_bin = null
	netview = null

	if HwyAssnNtOK = 0
		then do
			msg = msg + {"HwyAssn OffPeak - Night hwy assn error"}
			HwyAssnOK = 0
		end

	datentime = GetDateandTime()
	AppendToLogFile(2, "HwyAssn Night complete: " + datentime)
	AppendToLogFile(1, "Exit HwyAssn_RunNight: " + datentime)

	return ({HwyAssnOK, msg})
	
endmacro