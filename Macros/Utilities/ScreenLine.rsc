Macro "ScreenLine" (Args)

	LogFile = Args.[Log File].value
	SetLogFileName(LogFile)

	Dir = Args.[Run Directory].value
	msg = null
	MSStatsOK = 1

	datentime = GetDateandTime()
	AppendToLogFile(1, "Enter MSMatrixStats: " + datentime)

// pull screenline records
	SetView("TotAssn")
	ScrLineSelect = "Select * where SCRLN <> null"
	nlnks = SelectbyQuery("ScrLineLinks", "Several", ScrLineSelect,)
//	if nlnks < 1 then goto NoScreen
	ExportView("TotAssn"+"|ScrLineLinks", "FFB", Dir + "\\hwyassn\\ScreenLineLinks.bin", 
		{"SCRLN", "ID", "LENGTH", "DIR", "FUNCL", "AREATP", "COUNTY","Strname", "A_CrossStr", "B_CrossStr", 
		 "CALIB10", "TOT_VOL", "CNTFLAG", "CNTMCSQ"},) 
	
//	CloseView(TotAssn)

//Reopen file of screenline links - join to screenline id
	ScrLnLinks = OpenTable("ScrLnLinks", "FFB", {Dir + "\\hwyassn\\ScreenLineLinks.bin",})
	 	
	join3 =  JoinViews("ScrLnSum", "ScrLnID.SCRLN", "ScrLnLinks.SCRLN", 
        	           {{"A",}, 
    			    {"Fields",{{"CALIB10", {{"Sum"}}}, {"TOT_VOL",  {{"Sum"}}},     		       
			               {"CNTFLAG",   {{"Sum"}}}, {"CNTMCSQ",  {{"Sum"}}}     		       
   			       }}})

	ExportView("ScrLnSum|", "CSV", Dir + "\\report\\ScreenLineSummary.csv", 
		{"SCRLN", "CALIB10", "TOT_VOL", "CNTFLAG", "CNTMCSQ"}, { {"CSV Header", "True"} } )
	
	CloseView(join3)
	CloseView(ScrLnLinks)
end
