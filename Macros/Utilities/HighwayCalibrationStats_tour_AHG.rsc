Macro "HighwayCalibrationStats_tour" (Args)

	// Part of runstats_hwyassn_hot that deal with calibration
	//	\report\RunStats_HwyAssn.dbf
	//	\report\Screenlinesummary.dbf		\hwyassn\screenlinelinks.bin
	//	\report\runstats_dwnldCOATFUN.dbf
	//  changed tot_assn_hot.dbf to tot_assn_hot.bin (4/25/17)

	//Input Datasets
	//	Dir + "\\HwyAssn\\HOT\\TOT_ASSN_HOT.bin"
	
	//Aggregation datasets
	//	MRMDir + "\\ScreenlineID.bin"
	//	MRMDir + "\\County_ATFun.bin"
	//	MRMDir + "\\County_ATFunID.bin"
	//	MRMDir + "\\ATFUN_ID.dbf"


	LogFile = Args.[Log File].value
	SetLogFileName(LogFile)

	Dir = Args.[Run Directory].value
	METDir = Args.[MET Directory].value
	msg = null
	HwyCalibStatsOK = 1

	datentime = GetDateandTime()
	AppendToLogFile(1, "Enter HighwayCalibrationStats: " + datentime)

	// Add section to check if datasets exist

	//Open files
	TotAssn = OpenTable("TotAssn", "FFB", {Dir + "\\HwyAssn\\HOT\\TOT_ASSN_HOT.bin",})
	CATMatch = OpenTable("CATMatch", "FFB", {METDir + "\\County_ATFun.bin",})
	CATMatch2 = OpenTable("CATMatch2", "FFB", {METDir + "\\County_ATFunID.bin",})
	ScrlnID  = OpenTable("ScrLnID", "FFB", {METDir + "\\ScreenlineID.bin",})
	ATFUNID  = OpenTable("ATFUNID", "DBASE", {METDir + "\\ATFUN_ID.dbf",})
	COATFUNID  = OpenTable("COATFUNID", "DBASE", {METDir + "\\COATFUN_ID.dbf",})

	//Tot_assn variables
	CATFun   = CreateExpression("TotAssn", "CATFun", "if (county = 57 or county = 91) then (45000+county)*1000 + AREATP * 100 + funcl else (37000 + county) * 1000 + areatp * 100 + funcl",)
	Lane_Mi  = CreateExpression("TotAssn", "Lane_Mi", "LENGTH * LANESAB + LENGTH * LANESBA",)
//	comflag  = CreateExpression("TotAssn", "ComFlag", "if Com08 <> null then 1 else 0",)
	mtkflag  = CreateExpression("TotAssn", "MTKFlag", "if MTK18 <> null then 1 else 0",)
	htkflag  = CreateExpression("TotAssn", "HTKFlag", "if HTK18 <> null then 1 else 0",)
	assnvol  = CreateExpression("TotAssn", "AssnVol", "if CALIB18 <> null then TOT_VOL else 0",)
//	assncom  = CreateExpression("TotAssn", "AssnCOM", "if COM08     <> null then TOT_VOL else 0",)
	assnmtk  = CreateExpression("TotAssn", "AssnMTK", "if MTK18     <> null then TOT_VOL else 0",)
	assnhtk  = CreateExpression("TotAssn", "AssnHTK", "if HTK18     <> null then TOT_VOL else 0",)

	atfun = CreateExpression("TotAssn", "ATFUN", "AREATP * 100 + funcl",)
	coatfun = CreateExpression("TotAssn", "COATFUN", "IF COUNTY = 119 THEN (10000 + (AREATP * 100) + FUNCL) ELSE (20000 + (AREATP * 100) + FUNCL) ",)


	//  RUNSTATS_HWYASSN.CSV ***********************

	//Join CATFUN (STCNTY * 1000 + ATYPE * 100 + Funcl)
	join1 =  JoinViews("AssnMatch1", "TotAssn.CATFun", "CATMatch.CATFun",)

	//Aggregate to CATFun2 - sum AT (1,2,4=comm), Funcl - Freeway, ExprWay, Tfare, Other, HighOcc, Cenconn
	//      all counties except Mecklenburg - use full area type and funcl
	join2 =  JoinViews("AssnCATFun2", "CATMatch2.CATFun2", "AssnMatch1.CATFun2", 
        	           {{"A",}, 
    			    {"Fields",{{"LENGTH",    {{"Sum"}}}, {"Lane_Mi",  {{"Sum"}}},
		        	       {"VMT_AM",    {{"Sum"}}}, {"VHT_AM",   {{"Sum"}}},     		       
		        	       {"VMT_MI",    {{"Sum"}}}, {"VHT_MI",   {{"Sum"}}},     		       
		        	       {"VMT_PM",    {{"Sum"}}}, {"VHT_PM",   {{"Sum"}}},     		       
		      		       {"VMT_NT",    {{"Sum"}}}, {"VHT_NT",   {{"Sum"}}},     		       
			               {"CALIB18",   {{"Sum"}}}, {"AssnVol",  {{"Sum"}}},     		       
			               {"CNTFLAG",   {{"Sum"}}}, {"CNTMCSQ",  {{"Sum"}}},     		       
//			               {"COM08",     {{"Sum"}}}, {"AssnCOM",  {{"Sum"}}},     		       
//			               {"AssnCom",   {{"Sum"}}}, {"TOT_COM",  {{"Sum"}}},     		       
//			               {"COMFLAG",   {{"Sum"}}}, {"COMMCSQ",  {{"Sum"}}},     		       
			               {"MTK18",     {{"Sum"}}}, {"AssnMTK",  {{"Sum"}}},     		       
			               {"MTKFLAG",   {{"Sum"}}}, {"MTKMCSQ",  {{"Sum"}}},     		       
			               {"HTK18",     {{"Sum"}}}, {"AssnHTK",  {{"Sum"}}},     		       
			               {"HTKFLAG",   {{"Sum"}}}, {"HTKMCSQ",  {{"Sum"}}},     		       
   			       }}})

	IDNameArray    = {"CATFun2", "CATMatch2.STCNTY", "CATMatch2.AT2", "CATMatch2.Fun2", 
			  "CATMatch2.CntyName", "AT2Name", "Fun2Name"}
	MileNameArray  = {"LENGTH", "LANE_MI"}
	VMTNameArray   = {"VMT_AM", "VHT_AM", "VMT_MI", "VHT_MI", "VMT_PM", "VHT_PM", "VMT_NT", "VHT_NT"}
        CountNameArray = {"CALIB18","AssnVol", "CNTFLAG", "CNTMCSQ",
//        		  "COM08",    "AssnCOM", "COMFLAG", "COMMCSQ",  
        		  "MTK18",    "AssnMTK", "MTKFLAG", "MTKMCSQ",  
        		  "HTK18",    "AssnHTK", "HTKFLAG", "HTKMCSQ"} 
	OutNameArray   = IDNameArray + MileNameArray + VMTNameArray + CountNameArray
	ExportView(join2 +"|", "CSV", Dir + "\\Report\\RunStats_HwyAssn.csv", OutNameArray,)
	CloseView(CATMatch)
	CloseView(CATMatch2)
	CloseView(join1)
	CloseView(join2)


	// pull screenline records
	SetView("TotAssn")
	ScrLineSelect = "Select * where SCRLN <> null and CNTFLAG = 1"
	nlnks = SelectbyQuery("ScrLineLinks", "Several", ScrLineSelect,)

	//	if nlnks < 1 then goto NoScreen
	ExportView("TotAssn"+"|ScrLineLinks", "FFB", Dir + "\\hwyassn\\ScreenLineLinks.bin", 
		{"SCRLN", "ID", "LENGTH", "DIR", "FUNCL", "AREATP", "COUNTY","Strname", "A_CrossStr", "B_CrossStr", 
		 "CALIB18", "TOT_VOL", "CNTFLAG", "CNTMCSQ"},)
	

	//Reopen file of screenline links - join to screenline id
	ScrLnLinks = OpenTable("ScrLnLinks", "FFB", {Dir + "\\hwyassn\\ScreenLineLinks.bin",})
	 	
	join3 =  JoinViews("ScrLnSum", "ScrLnID.SCRLN", "ScrLnLinks.SCRLN", 
        	           {{"A",}, 
    			    {"Fields",{{"CALIB18", {{"Sum"}}}, {"TOT_VOL",  {{"Sum"}}},     		       
			               {"CNTFLAG",   {{"Sum"}}}, {"CNTMCSQ",  {{"Sum"}}}     		       
   			       }}})

	ExportView("ScrLnSum|", "CSV", Dir + "\\report\\ScreenLineSummary.csv", 
		{"SCRLN", "CALIB18", "TOT_VOL", "CNTFLAG", "CNTMCSQ"}, { {"CSV Header", "True"} } )
	
	CloseView(ScrlnID)
	CloseView(join3)
	CloseView(ScrLnLinks)

	// runstats_dwnldVol.csv
	join_vol =  JoinViews("Counts", "ATFUNID.ATFUN", "TotAssn.ATFUN", 
        	           {{"A",}, 
    			    {"Fields",{{"CNTFLAG", {{"Sum"}}}, {"CALIB18", {{"Sum"}}}, {"AssnVol",  {{"Sum"}}}, {"CNTMCSQ", {{"Sum"}}}   		       
   			       }}})

	ExportView("Counts|", "CSV", Dir + "\\report\\runstats_dwnldVOL.csv", 
		{"ATFUN", "CNTFLAG", "CALIB18", "AssnVol", "CNTMCSQ"}, { {"CSV Header", "True"} } )
	
	CloseView(join_vol)
	CloseView(ATFUNID)

	// runstats_dwnldcoatfun.csv
	join_vol2 =  JoinViews("Counts2", "COATFUNID.COATFUN", "TotAssn.COATFUN", 
        	           {{"A",}, 
    			    {"Fields",{{"CNTFLAG", {{"Sum"}}}, {"CALIB18", {{"Sum"}}}, {"AssnVol",  {{"Sum"}}}, {"CNTMCSQ", {{"Sum"}}}   		       
   			       }}})

	ExportView("Counts2|", "CSV", Dir + "\\report\\runstats_dwnldCOATFUN.csv", 
		{"ORDER", "COATFUN", "CNTFLAG", "CALIB18", "AssnVol", "CNTMCSQ"}, { {"CSV Header", "True"} } )

	CloseView(join_vol2)
	CloseView(COATFUNID)


	//  VolGroupStats.CSV ***********************

	volgroup_tab = CreateTable("volgroup_tab", Dir + "\\report\\volgroup_tab.bin", "FFB", {{"STCNTY", "Integer", 5, , "No"}, {"VolGrpID", "Integer", 2, , "No"},
	{"LinksCount", "Integer", 10, , "No"}, {"Length", "Real", 21, 4, "No"}, {"CALIB18", "Real", 21, 4, "No"}, {"Tot_Vol", "Real", 21, 4, "No"}, {"TOT_VMT", "Real", 21, 4, "No"},
	{"TOT_VHT", "Real", 21, 4, "No"}, {"CNTMCSQ", "Real", 21, 4, "No"}})

		
//	totassn_tab = OpenTable("totassn_tab", "FFB", {Dir + "\\HwyAssn\\HOT\\Tot_Assn_HOT.bin",}) 
	
	//Define Variables - Arrays for STCNTY and VolGroup

	stcnty_ar = { "37025", "37035", "37045", "37071", "37097", "37109", "37119", "37159", "37167", "37179", "45057", "45091"}

	volgroup_ar = { 0, 1000, 2500, 5000, 10000, 25000, 50000, 1000000 }


		for c = 1 to stcnty_ar.length do 
			counter = 0
			for vg = 1 to (volgroup_ar.length - 1) do	
					counter = counter + 1
					
					SetView("TotAssn")
					qry1 = "Select * where STCNTY = " + stcnty_ar[c] + " and CALIB18 between " + i2s(volgroup_ar[vg]+1) + " and " + i2s(volgroup_ar[vg+1]) // 1-1000, 1001 - 2500
					numlinks = SelectByQuery("numlinks", "Several", qry1, )

					stats_tab = ComputeStatistics("TotAssn|numlinks", "stats_tab", Dir +"\\stats_tab.bin", "FFB",) 
					
					SetView("stats_tab")
					qry2 = 'Select * where Field = "Length" or Field= "CALIB18" or Field = "Tot_Vol" or Field = "CNTMCSQ" or Field = "TOT_VMT" or Field = "TOT_VHT" '
					sumfields = SelectByQuery("sumfields", "Several", qry2, )

					stats_v = GetDataVector(stats_tab +"|sumfields", "Sum",)
					lengthval = stats_v[1]
					CALIB18val = stats_v[2]
					tot_volval = stats_v[3]
					TOT_VMTval = stats_v[4]
					TOT_VHTval = stats_v[5]	
					CNTMCSQval = stats_v[6]			
	
					rh = AddRecord("volgroup_tab", {{"STCNTY", s2i(stcnty_ar[c])}, {"VolGrpID", counter}, {"LinksCount", numlinks}, {"Length", lengthval}, {"CALIB18", CALIB18val},
						{"Tot_Vol", tot_volval}, {"TOT_VMT", TOT_VMTval}, {"TOT_VHT", TOT_VHTval}, {"CNTMCSQ", CNTMCSQval}})      
					CloseView(stats_tab)
				end
			end
		

		volgroup_tab2 = ExportView("volgroup_tab|", "CSV", Dir + "\\report\\VolGroupStats.csv",{"STCNTY", "VolGrpID", "LinksCount", "Length", "CALIB18", "Tot_Vol", "CNTMCSQ", "TOT_VMT", "TOT_VHT"}, { {"CSV Header", "True"} } )		
	
    

   
	CloseView(TotAssn)

	goto quit
		
//	badmat: 
//	msg = msg + {"HighwwayCalibrationStats:  Error - matrix " + MatArray[mcnt] + " not found"}
//	AppendToLogFile(1, "HighwayCalibrationStats:  Error - matrix " + MatArray[mcnt] + " not found")
//	HwyCalibStatsOK = 0
//	goto quit 
	
	quit: 

	datentime = GetDateandTime()
	AppendToLogFile(1, "Exit HighwayCalibrationStats: " + datentime)
	return({HwyCalibStatsOK, msg})



EndMacro
