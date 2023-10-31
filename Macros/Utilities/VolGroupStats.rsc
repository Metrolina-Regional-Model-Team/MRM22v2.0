Macro "VolGroupStats" (Args)

/*
	SetLogFileName(LogFile)

	Dir = Args.[Run Directory].value
	METDir = Args.[MET Directory].value
	msg = null
	atltripsOK = 1

	datentime = GetDateandTime()
	AppendToLogFile(1, "Enter VolGroupStats: " + datentime)
*/

    Dir = "D:\\1901_AQ_update\\Metrolina\\2015\\HwyAssn\\HOT"

//Create Table & Open Tot_Assn_HOT Table

volgroup_tab = CreateTable("volgroup_tab", Dir + "\\volgroup_tab.bin", "FFB", {{"STCNTY", "Integer", 5, , "No"}, {"VolGrpID", "Integer", 2, , "No"},
{"LinksCount", "Integer", 10, , "No"}, {"CALIB18", "Real", 10, 2, "No"}, {"TOT_VOL", "Real", 12, 2, "No"}, {"CNTMCSQ", "Real", 8, 2, "No"}, {"TOT_VMT", "Real", 8, 2, "No"},
{"TOT_VHT", "Real", 12, 2, "No"}, {"LENGTH", "Real", 8, 2, "No"}})

	
TotAssn_tab = OpenTable("TotAssn_tab", "DBASE", {Dir + "\\Tot_Assn_HOTX.dbf",}) // hardcoded D:\1901_AQ_update\Metrolina\2015\HwyAssn\HOT
//	STCNTY = GetDataVector(TotAssn_tab + "|", "STCNTY",)
   
//Define Variables - Arrays for STCNTY and VolGroup

volgroup_tab = CreateTable("volgroup_tab", Dir + "\\volgroup_tab.bin", "FFB", {{"STCNTY", "Integer", 5, , "No"}, {"VolGrpID", "Integer", 2, , "No"},
	{"LinksCount", "Integer", 10, , "No"}, {"Length", "Real", 21, 4, "No"}, {"CALIB18", "Real", 21, 4, "No"}, {"Tot_Vol", "Real", 21, 4, "No"}, {"CNTMCSQ", "Real", 21, 4, "No"}, {"TOT_VMT", "Real", 21, 4, "No"},
	{"TOT_VHT", "Real", 21, 4, "No"}})

		
	totassn_tab = OpenTable("totassn_tab", "FFB", {Dir + "\\HwyAssn\\HOT\\Tot_Assn_HOT.bin",}) 
	
	
	//Define Variables - Arrays for STCNTY and VolGroup

	stcnty_ar = { "37025", "37035", "37045", "37071", "37097", "37109", "37119", "37159", "37167", "37179", "45057", "45091"}

	volgroup_ar = { 0, 1000, 2500, 5000, 10000, 25000, 50000, 1000000 }


		for c = 1 to stcnty_ar.length do 
			counter = 0
			for vg = 1 to (volgroup_ar.length - 1) do	
					counter = counter + 1
					
					SetView("totassn_tab")
					qry1 = "Select * where STCNTY = " + stcnty_ar[c] + " and CALIB18 between " + i2s(volgroup_ar[vg]+1) + " and " + i2s(volgroup_ar[vg+1]) // 1-1000, 1001 - 2500
					numlinks = SelectByQuery("numlinks", "Several", qry1, )

					stats_tab = ComputeStatistics("totassn_tab|numlinks", "stats_tab", Dir +"\\stats_tab.bin", "FFB",) 
					
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
						{"Tot_Vol", tot_volval}, {"CNTMCSQ", CNTMCSQval}, {"TOT_VMT", TOT_VMTval}, {"TOT_VHT", TOT_VHTval}})      
					CloseView(stats_tab)
				end
			end
		

		volgroup_tab2 = ExportView("volgroup_tab|", "CSV", Dir + "\\VolGroupStats.csv",{"STCNTY", "VolGrpID", "LinksCount", "Length", "CALIB18", "Tot_Vol", "CNTMCSQ", "TOT_VMT", "TOT_VHT"}, { {"CSV Header", "True"} } )		
	
    
    
	goto quit
		
	badend: 
	msg = msg + {"VolGroupStats:  Error - file " + badfile + " not found"}
	AppendToLogFile(1, "VolGroupStats:  Error - file " + badfile + " not found")
	atltripsOK = 0
	goto quit 
	
	quit: 
	datentime = GetDateandTime()
	AppendToLogFile(1, "Exit VolGroupStats: " + datentime)
	return({atltripsOK, msg})

endmacro