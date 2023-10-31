macro "VMTAQ" (Args)

	// Write files \report\runstats_VMTAQ.scv 
	//			\report\runstats_
	//  changed tot_assn_hot.dbf to tot_assn_hot.bin (4/25/17)


	LogFile = Args.[Log File].value
	SetLogFileName(LogFile)

	Dir = Args.[Run Directory].value
	METDir = Args.[MET Directory].value
	msg = null
	VMTAQOK = 1

	datentime = GetDateandTime()
	AppendToLogFile(1, "Enter VMTAQ: " + datentime)

//Open files

	TotAssnFile = Dir + "\\HwyAssn\\HOT\\TOT_ASSN_HOT.bin"
	FunAQIDFile = METDir + "\\FUNAQ_ID.dbf"

	hit = GetFileInfo(TotAssnFile)
	if hit = null 
		then do 
			badfile = TotAssnFile	
			goto badend
		end

	hit = GetFileInfo(FunAQIDFile)
	if hit = null 
		then do 
			badfile = FunAQIDFile	
			goto badend
		end



	TotAssn = OpenTable("TotAssn", "FFB", {TotAssnFile,})
	FUNAQID  = OpenTable("FUNAQID", "DBASE", {FunAQIDFile,})


	//  RUNSTATS_VMTAQ ****************************

	VMTAQ =  JoinViews("VMTAQ", "FUNAQID.FUNAQ", "TotAssn.FEDFUNC_AQ", 
        	           {{"A",}, 
    			    {"Fields",{{"CNTFLAG", {{"Sum"}}}, {"CALIB18", {{"Sum"}}}, {"VMT_AM",  {{"Sum"}}}, {"VHT_AM", {{"Sum"}}}, {"VMT_PM", {{"Sum"}}}, {"VHT_PM", {{"Sum"}}},  		       
			            {"VMT_MI", {{"Sum"}}}, {"VHT_MI", {{"Sum"}}}, {"VMT_NT", {{"Sum"}}}, {"VHT_NT", {{"Sum"}}}, {"TOT_VMT", {{"Sum"}}}, {"TOT_VHT", {{"Sum"}}}   		       
   			       }}})

	runstats_VMTAQ = ExportView("VMTAQ|", "CSV", Dir + "\\report\\runstats_VMTAQ.csv", 
		{"ORDER", "FUNAQ", "FUNAQID.COUNTY", "[N TotAssn]", "LENGTH", "CNTFLAG", "CALIB18", "VMT_AM", "VHT_AM", "VMT_PM", "VHT_PM", "VMT_MI", "VHT_MI", "VMT_NT", "VHT_NT", "TOT_VMT", "TOT_VHT"}, { {"CSV Header", "True"} } )

	
	//  RUNSTATS_VMTCnty ****************************

	VMTAQ2 =  JoinViews("VMTAQ2", "FUNAQID.FUNAQ", "TotAssn.CO_FEDFUNC", 
        	           {{"A",}, 
    			    {"Fields",{{"CNTFLAG", {{"Sum"}}}, {"CALIB18", {{"Sum"}}}, {"VMT_AM",  {{"Sum"}}}, {"VHT_AM", {{"Sum"}}}, {"VMT_PM", {{"Sum"}}}, {"VHT_PM", {{"Sum"}}},  		       
			            {"VMT_MI", {{"Sum"}}}, {"VHT_MI", {{"Sum"}}}, {"VMT_NT", {{"Sum"}}}, {"VHT_NT", {{"Sum"}}}, {"TOT_VMT", {{"Sum"}}}, {"TOT_VHT", {{"Sum"}}}   		       
   			       }}})

	runstats_VMTCnty = ExportView("VMTAQ2|", "CSV", Dir + "\\report\\runstats_VMTCnty.csv", 
		{"ORDER", "FUNAQ", "FUNAQID.COUNTY", "[N TotAssn]", "LENGTH", "CNTFLAG", "CALIB18", "VMT_AM", "VHT_AM", "VMT_PM", "VHT_PM", "VMT_MI", "VHT_MI", "VMT_NT", "VHT_NT", "TOT_VMT", "TOT_VHT"}, { {"CSV Header", "True"} } )

	CloseView(VMTAQ)
	CloseView(VMTAQ2)
	CloseView(FUNAQID)
	CloseView(TotAssn)

	goto quit
		
	badend: 
	msg = msg + {"VMTAQ:  Error - file " + badfile + " not found"}
	AppendToLogFile(1, "VMTAQ:  Error - file " + badfile + " not found")
	VMTAQOK = 0
	goto quit 
	
	quit: 
	datentime = GetDateandTime()
	AppendToLogFile(1, "Exit VMTAQ: " + datentime)
	return({VMTAQOK, msg})

endmacro