Macro "HwyAssn_RunHOTTotAssn" (Args)

// Macro sets assignment directory and sets input files and calls hwyassn_gc_mrm
// AssnSubDir currently set to \\HwyAssn and \\HwyAssn\\HOT
// assntype = "base", "HOT2+", or "HOT3+"

	LogFile = Args.[Log File].value
	SetLogFileName(LogFile)
	ReportFile = Args.[Report File].value
	SetReportFileName(ReportFile)

	msg = null

	datentime = GetDateandTime()
	AppendToLogFile(1, "Enter HwyAssnRunHOTTotAssn: " + datentime)
	AppendToLogFile(2, "Aggregate highway assignments for : " + assntype)

	Dir = Args.[Run Directory].value
	AssnSubDir = Dir + "\\hwyassn\\HOT"
	assntype = "HOT3+"
	
	TotAssnOK = RunMacro("TotAssn", Args, AssnSubDir, assntype)
 	AssnSubDir = null
	assntype = null
	
	datentime = GetDateandTime()
	AppendToLogFile(1, "Exit HwyAssnRunHOTTotAssn: " + datentime)

	return ({TotAssnOK, msg})
	
endmacro	