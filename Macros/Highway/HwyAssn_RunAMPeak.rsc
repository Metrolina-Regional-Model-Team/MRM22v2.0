Macro "HwyAssn_RunAMPeak" (Args)

// Macro sets input files and calls hwyassn_MMA
// This version runs hwyassn_gc_mrm - it has the option to switch to bpr   JWM 09/24/16		

// Allows user to choose gc_mrm assignment - it won't work in TC 7 though
// 5/30/19, mk: There are now three distinct networks: AM peak, PM peak, and offpeak; pass correct netview through

	LogFile = Args.[Log File].value
	SetLogFileName(LogFile)
	ReportFile = Args.[Report File].value
	SetReportFileName(ReportFile)

	Dir = Args.[Run Directory].value
	msg = null

	curiter = Args.[Current Feedback Iter].value
	maxiter = Args.[Feedback Iterations].value
	msg = null

	datentime = GetDateandTime()
	AppendToLogFile(1, "Enter HwyAssn_RunAMPeak: " + datentime)
	AppendToLogFile(2, "AM Peak feedback iteration: " + i2s(curiter))


	od_matrix = Dir + "\\tod2\\ODHwyVeh_AMPeak.mtx"
	cap_field = "CapPk3hr"
	
	if curiter < maxiter 
		then output_bin = Dir + "\\HwyAssn\\Assn_AMPeak_pass" + i2s(curiter) + ".bin"
		else output_bin = Dir + "\\HwyAssn\\Assn_AMPeak.bin"
		
	timeperiod = "AMpeak"

	HwyAssnAMOK = RunMacro("HwyAssn_MMA", Args, od_matrix, cap_field, output_bin, timeperiod)


 	od_matrix = null
	cap_field = null
	output_bin = null
	netview = null

	datentime = GetDateandTime()
	AppendToLogFile(1, "Exit HwyAssn_RunAMPeak: " + datentime)

	return ({HwyAssnAMOK, msg})
	
endmacro	