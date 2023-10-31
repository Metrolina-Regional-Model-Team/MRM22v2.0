macro "CapSpd" (Args)

//Modified for 2015 User Interface - Aug, 2015
// 5/30/19, mk: Loops to fill capacity fields for three distinct networks: AM peak, PM peak, and offpeak

	Dir = Args.[Run Directory].value
	METDir = Args.[MET Directory].value
	theyear = Args.[Run Year].value

	timeweight = Args.[TimeWeight].value
	distweight = Args.[DistWeight].value

	LogFile = Args.[Log File].value
	ReportFile = Args.[Report File].value
	SetLogFileName(LogFile)
	SetReportFileName(ReportFile)
	datentime = GetDateandTime()
	AppendToLogFile(1, "Enter CapSpd: " + datentime)

	msg = null

	hwyname_ar = {Args.[AM Peak Hwy Name].value, Args.[PM Peak Hwy Name].value, Args.[Offpeak Hwy Name].value}
	timeperiod_ar = {"AM Peak", "PM Peak", "Offpeak"}
	
	for tp = 1 to 3 do
		HwyName = hwyname_ar[tp]
		netview = HwyName
		altname = netview
		
		CreateProgressBar("Capacity and Speed Calculations "+timeperiod_ar[tp], "False")
		stat = UpdateProgressBar("Capacity and Speed Calculations "+timeperiod_ar[tp],1)
	
		// Get the scope of a geographic file
		info = GetDBInfo(Dir + "\\"+netview+".dbd")
		if info = null then do
			msg = msg + {"CapSpd: " + netview + ".dbd does not exist in this directory"}
			AppendToLogFile(1, "CapSpd: " + netview + ".dbd does not exist in this directory")
			goto badquit
			end
		else scope = info[1]
	
		// Create a map using this scope
		CreateMap(netview, {{"Scope", scope},{"Auto Project", "True"}})
	
		file = Dir + "\\"+netview+".dbd"
		layers = GetDBLayers(file)
		addlayer(netview, "Node", file, layers[1])
		addlayer(netview, netview, file, layers[2])
		SetLayerVisibility("Node", "True")
		SetIcon("Node|", "Font Character", "Caliper Cartographic|4", 36)
		SetLayerVisibility(netview, "True")
		solid = LineStyle({{{1, -1, 0}}})
		SetLineStyle(netview+"|", solid)
		SetLineColor(netview+"|", ColorRGB(32000, 32000, 32000))
		SetLineWidth(netview+"|", 0)
	
	     stat = UpdateProgressBar("Reestimating future densities",13)
	
	     Runmacro("ped_drive_den_update", Args, HwyName)
	
	     stat = UpdateProgressBar("Getting A and B Node information",16)
		j = GetRecordCount(netview,)
		i = j/16
		k = 13
		t = 1
		y = i
		hi = GetFirstRecord(netview + "|",)
		while hi <> null do
		if t < i then do
			goto nextrecord
			end
		if t > i then do
			stat = UpdateProgressBar("Getting A and B Node information",k)
			i = i + y
			k = k + 1
			goto nextrecord
			end
		nextrecord:
		mval = GetRecordValues(netview, hi, {"ID"})
			record = mval[1][2]
			setlayer(netview)
			endpts = GetEndpoints(record)
			A_node = endpts[1]
			B_node = endpts[2]
			SetRecordValues(netview,null,{{"Anode", A_node}})
			SetRecordValues(netview,null,{{"Bnode", B_node}})
		hi = GetNextRecord(netview + "|", null,)
		t = t + 1
		end
	
		setlayer(netview)
	
			k = k + 3
			stat = UpdateProgressBar("Exporting "+Dir + "\\"+netview+"_capspeedIN.asc",k)
	
		Exportview(netview+"|", "FFA", Dir + "\\"+netview+"_capspeedIN.asc", {"ID", "Length", "Dir", "Anode", "Bnode", "funcl", "fedfuncl", "fedfunc_AQ","lanesAB", "lanesBA", "factype", "Spdlimit", "parking", "Pedactivity", "Developden", "Drivewayden", "landuse", "A_LeftLns", "A_ThruLns", "A_RightLns", "A_Control", "A_Prohibit", "B_LeftLns", "B_ThruLns", "B_RightLns", "B_Control", "B_Prohibit", "State", "County", "locclass1", "locclass2", "reverselane", "reversetime","taz", "cap1hrAB", "cap1hrBA", "TTPkEstAB", "TTPkEstBA", "TTPkPrevAB", "TTPkPrevBA", "TTPkAssnAB", "TTPkAssnBA", "TTPkLocAB", "TTPkLocBA", "TTPkXprAB", "TTPkXprBA", "TTPkNStAB", "TTPkNStBA", "TTPkSkSAB", "TTPkSkSBA", "PkLocLUAB", "PkLocLUBA", "PkXprLUAB", "PkXprLUBA"},)
	
	//080124:  Default fortran return 24 if job doesn't run, Jan 24, 2008 McLelland
	
		rtnfptr = null
		rtnfptr=openfile(Dir + "\\Report\\return_code_CapSpd.txt","w")
		writeline(rtnfptr,"      24")
		closefile(rtnfptr)		
	
	
		FortInfo = GetFileInfo(METDir + "\\Pgm\\capspd.exe")
		TimeStamp = FortInfo[7] + " " + FortInfo[8]
		AppendToLogFile(2, "CapSpd call to fortran: pgm=capspd.exe, timestamp: " + TimeStamp)
	
		ctlname = METDir + "\\Pgm\\Param\\capspd.ctl"
	  	exist = GetFileInfo(ctlname)
	  	if (exist <> null) then DeleteFile(ctlname)
	 
	  	mac = OpenFile(ctlname, "w")
	
		WriteLine(mac, "&INFILES  IN09='"+ Dir+ "\\LandUse\\TAZ_AREATYPE.asc',")
		WriteLine(mac, "          IN10='"+ Dir+ "\\" + netview +"_capspeedIN.asc',")
		WriteLine(mac, "          IN11='"+ METDir +  "\\Pgm\\CapSpdFactors\\capspd_factors.prn',")
	    WriteLine(mac, "          IN12='"+ METDir + "\\Pgm\\CapSpdFactors\\capspd_nodeerrors.asc'")
	    WriteLine(mac, "          IN13='"+ METDir + "\\Pgm\\CapSpdFactors\\guideway20.prn'")
		WriteLine(mac, "/")
		WriteLine(mac, "&OUTFILES OUT06='"+ Dir+ "\\Report\\CapSpd_log_" + netview + ".prn',")
	    WriteLine(mac, "          OUT07='"+ Dir+ "\\Report\\CapSpd_warnlog_" + netview + ".asc',")
		WriteLine(mac, "          OUT08='"+ Dir+ "\\Report\\CapSpd_errorlog_" + netview + ".asc',")
		WriteLine(mac, "          OUT14='"+ Dir+ "\\" + netview + "_CapSpeedOUT.asc',")
		WriteLine(mac, "          OUT15='"+ Dir+ "\\" + netview + "_CapSpeedOUT.dct',")
		WriteLine(mac, "          OUT16='"+ Dir+ "\\nodecontrol_CapSpd_" + netview + ".asc'")
		WriteLine(mac, "          OUT18='"+ Dir +"\\Report\\return_code_CapSpd.txt'")
		WriteLine(mac, "/")
		WriteLine(mac, "&PARAM RUNYEAR="+theyear+", SPDCAP=70, CAPYEAR=2050, RTNSPD=F")
		WriteLine(mac, "/")
		WriteLine(mac, "&OPTION TRACE=T,F,F,F,F,F,F,F, LIST=T,F,F")
		WriteLine(mac, "/")
		CloseFile(mac)
	
	        runprogram(METDir + "\\Pgm\\capspd.exe \""+ METDir + "\\Pgm\\Param\\capspd.ctl\"", )
	
	//080124:  Return code check,  McLelland, Jan 24, 2008 (dropped call to badfortrtn - didn't work)
	
		rtnfptr = null
		rtnfptr=openfile(Dir + "\\Report\\return_code_CapSpd.txt","r")
		fortrtn=readline(rtnfptr)
		severe = '       8'
		fatal =  '      24'
		if fortrtn = severe then do 
			msg = msg + {"Severe error in fortran capspd program, see \\Report\\CapSpd_errorlog_.txt"}
			AppendToLogFile(1, "Severe error in fortran capspd program, see \\Report\\CapSpd_errorlog_.txt")
			goto badquit
			end
		if fortrtn = fatal then do 
			msg = msg + {"Fortran Fatal error - CapSpd did not run"}
			AppendToLogFile(1, "Fortran Fatal error - CapSpd did not run")
			goto badquit
			end
		closefile(rtnfptr)
		
	//089124:  end of Jan 24 08 edit,
	
	    base =  Dir + "\\" + netview + "_CapSpeedOUT.asc"
	    opentable("Copy", "FFA", {base,})
	    JoinViews(netview+"+ Copy", netview+".ID", "Copy.ID", )
	    setview(netview+"+ Copy")
	
			k = k + 6
			stat = UpdateProgressBar("Updating " + netview + " with " + netview + "_CapSpeedOUT.asc",k)
			j = GetRecordCount(netview,)
			i = j/16
			t = 1
			y = i
	
	    hi = GetFirstRecord(netview+"+ Copy|",)
	    while hi <> null do
		mval = GetRecordValues(netview+"+ Copy", hi, {"Copy.SPfreeAB", "Copy.SPfreeBA", "Copy.SPpeakAB", "Copy.SPpeakBA", "Copy.TTfreeAB", "Copy.TTfreeBA", "Copy.TTpeakAB", "Copy.TTpeakBA", "Copy.TTLinkFrAB", "Copy.TTLinkFrBA", "Copy.TTlinkPkAB", "Copy.TTlinkPkBA", "Copy.IntDelFr_A", "Copy.IntDelFr_B", "Copy.IntDelPk_A", "Copy.IntDelPk_B", "Copy.CapPk3hrAB", "Copy.CapPk3hrBA", "Copy.CapMidAB", "Copy.CapMidBA",  "Copy.CapNightAB", "Copy.CapNightBA",  "Copy.Cap1hrAB", "Copy.Cap1hrBA", "Copy.TTPkEstAB", "Copy.TTPkEstBA", "Copy.TTPkPrevAB", "Copy.TTPkPrevBA", "Copy.TTPkAssnAB", "Copy.TTPkAssnBA", "Copy.TTPkLocAB", "Copy.TTPkLocBA", "Copy.TTPkXprAB", "Copy.TTPkXprBA", "Copy.TTFrLocAB", "Copy.TTFrLocBA", "Copy.TTFrXprAB", "Copy.TTFrXprBA", "Copy.TTwalkAB", "Copy.TTwalkBA", "lanesAB", "lanesBA", "Copy.alpha", "Copy.beta", "Strname", "Length", "Copy.areatp","Copy.TTbikeAB", "Copy.TTbikeBA", "Copy.walkmode", "Copy.PkLocLUAB", "Copy.PkLocLUBA", "Copy.PkXprLUAB", "Copy.PkXprLUBA", "Copy.TTPkNStAB", "Copy.TTPkNStBA", "Copy.TTFrNStAB", "Copy.TTFrNStBA", "Copy.TTPkSkSAB", "Copy.TTPkSkSBA", "Copy.TTFrSkSAB", "Copy.TTFrSkSBA", "Copy.SpdLimRun"})
		SPfreeAB = mval[1][2]
		SPfreeBA = mval[2][2]
		SPpeakAB = mval[3][2]
		SPpeakBA = mval[4][2] 
		TTfreeAB = mval[5][2]
		TTfreeBA = mval[6][2]
		TTpeakAB = mval[7][2]
		TTpeakBA = mval[8][2]
		TTLinkFrAB = mval[9][2]
		TTLinkFrBA = mval[10][2]
		TTlinkPkAB = mval[11][2]
		TTlinkPkBA = mval[12][2]
		IntDelFr_A = mval[13][2]
		IntDelFr_B = mval[14][2]
		IntDelPk_A = mval[15][2]
		IntDelPk_B = mval[16][2]
		capPk3hrAB = mval[17][2]
		capPk3hrBA = mval[18][2]
		capMidAB = mval[19][2]
		capMidBA = mval[20][2]
		capNightAB = mval[21][2]
		capNightBA = mval[22][2]
		cap1hrAB = mval[23][2]
		cap1hrBA = mval[24][2]
		TTPkEstAB = mval[25][2]
		TTPkEstBA = mval[26][2]
		TTPkPrevAB = mval[27][2]
		TTPkPrevBA = mval[28][2]
		TTPkAssnAB = mval[29][2]
		TTPkAssnBA = mval[30][2]
		TTPkLocAB = mval[31][2]
		TTPkLocBA = mval[32][2]
		TTPkXprAB = mval[33][2]
		TTPkXprBA = mval[34][2]
		TTFrLocAB = mval[35][2]
		TTFrLocBA = mval[36][2]
		TTFrXprAB = mval[37][2]
		TTFrXprBA = mval[38][2]
		TTwalkAB = mval[39][2]
		TTwalkBA = mval[40][2]
		lanesAB = mval[41][2]
		lanesBA = mval[42][2]
		alpha = mval[43][2]
		beta = mval[44][2]
		strname = mval[45][2]
		length = mval[46][2]
		areatp = mval[47][2]
		TTbikeAB = mval[48][2]
		TTbikeBA = mval[49][2]
		walkmode = mval[50][2]
	        PkLocLUAB = mval[51][2]
	        PkLocLUBA = mval[52][2]
	        PkXprLUAB = mval[53][2]
	        PkXprLUBA = mval[54][2]
		TTPkNStAB = mval[55][2]	
		TTPkNStBA = mval[56][2]	
		TTFrNStAB = mval[57][2]	
		TTFrNStBA = mval[58][2]	
		TTPkSkSAB = mval[59][2]	
		TTPkSkSBA = mval[60][2]	
		TTFrSkSAB = mval[61][2]	
		TTFrSkSBA = mval[62][2]	
	        SpdLimRun = mval[63][2]        
	
	
		if strname = null then
			do strname = "NULL"
			end
		if t < i then do
			goto recordnext
			end
		if t > i then do
			i = i + y
			k = k + 1
			goto recordnext
			end
		recordnext:
		stat = UpdateProgressBar(strname,k)
		SetRecordValues(netview,null,{{netview+".SPfreeAB", SPfreeAB}}) 
		SetRecordValues(netview,null,{{netview+".SPfreeBA", SPfreeBA}}) 
		SetRecordValues(netview,null,{{netview+".SPpeakAB", SPpeakAB}}) 
		SetRecordValues(netview,null,{{netview+".SPpeakBA",  SPpeakBA}})  
		SetRecordValues(netview,null,{{netview+".TTfreeAB", TTfreeAB}})
		SetRecordValues(netview,null,{{netview+".TTfreeBA", TTfreeBA}}) 
		SetRecordValues(netview,null,{{netview+".TTpeakAB", TTpeakAB}}) 
		SetRecordValues(netview,null,{{netview+".TTpeakBA", TTpeakBA}}) 
		SetRecordValues(netview,null,{{netview+".TTLinkFrAB", TTLinkFrAB}}) 
		SetRecordValues(netview,null,{{netview+".TTLinkFrBA", TTLinkFrBA}}) 
		SetRecordValues(netview,null,{{netview+".TTlinkPkAB", TTlinkPkAB}}) 
		SetRecordValues(netview,null,{{netview+".TTlinkPkBA", TTlinkPkBA}}) 
		SetRecordValues(netview,null,{{netview+".IntDelFr_A", IntDelFr_A}}) 
		SetRecordValues(netview,null,{{netview+".IntDelFr_B", IntDelFr_B}}) 
		SetRecordValues(netview,null,{{netview+".IntDelPk_A", IntDelPk_A}}) 
		SetRecordValues(netview,null,{{netview+".IntDelPk_B", IntDelPk_B}}) 
		SetRecordValues(netview,null,{{netview+".capPk3hrAB", capPk3hrAB}}) 
		SetRecordValues(netview,null,{{netview+".capPk3hrBA", capPk3hrBA}})
		SetRecordValues(netview,null,{{netview+".capMidAB", capMidAB}}) 
		SetRecordValues(netview,null,{{netview+".capMidBA", capMidBA}}) 
		SetRecordValues(netview,null,{{netview+".capNightAB", capNightAB}}) 
		SetRecordValues(netview,null,{{netview+".capNightBA", capNightBA}})  
		SetRecordValues(netview,null,{{netview+".cap1hrAB", cap1hrAB}})
		SetRecordValues(netview,null,{{netview+".cap1hrBA", cap1hrBA}}) 
		SetRecordValues(netview,null,{{netview+".TTPkEstAB", TTPkEstAB}})
		SetRecordValues(netview,null,{{netview+".TTPkEstBA", TTPkEstBA}}) 
		SetRecordValues(netview,null,{{netview+".TTPkPrevAB", TTPkPrevAB}}) 
		SetRecordValues(netview,null,{{netview+".TTPkPrevBA", TTPkPrevBA}}) 
		SetRecordValues(netview,null,{{netview+".TTPkAssnAB", TTPkAssnAB}}) 
		SetRecordValues(netview,null,{{netview+".TTPkAssnBA", TTPkAssnBA}}) 
		SetRecordValues(netview,null,{{netview+".TTPkLocAB", TTPkLocAB}}) 
		SetRecordValues(netview,null,{{netview+".TTPkLocBA", TTPkLocBA}}) 
		SetRecordValues(netview,null,{{netview+".TTPkXprAB", TTPkXprAB}}) 
		SetRecordValues(netview,null,{{netview+".TTPkXprBA", TTPkXprBA}}) 
		SetRecordValues(netview,null,{{netview+".TTFrLocAB", TTFrLocAB}}) 
		SetRecordValues(netview,null,{{netview+".TTFrLocBA", TTFrLocBA}}) 
		SetRecordValues(netview,null,{{netview+".TTFrXprAB", TTFrXprAB}}) 
		SetRecordValues(netview,null,{{netview+".TTFrXprBA", TTFrXprBA}})  
		SetRecordValues(netview,null,{{netview+".TTwalkAB", TTwalkAB}})
		SetRecordValues(netview,null,{{netview+".TTwalkBA", TTwalkBA}})
		SetRecordValues(netview,null,{{netview+".alpha", alpha}})
		SetRecordValues(netview,null,{{netview+".beta", beta}})
		SetRecordValues(netview,null,{{"Lanes", nz(lanesAB)+nz(lanesBA)}})
		SetRecordValues(netview,null,{{"ImpPkAB", ((nz(TTpeakAB))* timeweight)+((nz(length))* distweight)}})
		SetRecordValues(netview,null,{{"ImpPkBA", ((nz(TTpeakBA))* timeweight)+((nz(length))* distweight)}})
		SetRecordValues(netview,null,{{"ImpFreeAB", ((nz(TTfreeAB))* timeweight)+((nz(length))* distweight)}})
		SetRecordValues(netview,null,{{"ImpFreeBA", ((nz(TTfreeBA))* timeweight)+((nz(length))* distweight)}})
		SetRecordValues(netview,null,{{netview+".areatp", areatp}})
		SetRecordValues(netview,null,{{netview+".TTbikeAB", TTbikeAB}})
		SetRecordValues(netview,null,{{netview+".TTbikeBA", TTbikeBA}})
		SetRecordValues(netview,null,{{netview+".mode", walkmode}})
		SetRecordValues(netview,null,{{"PkLocLUAB", PkLocLUAB}})
		SetRecordValues(netview,null,{{"PkLocLUBA", PkLocLUBA}})
		SetRecordValues(netview,null,{{"PkXprLUAB", PkXprLUAB}})
		SetRecordValues(netview,null,{{"PkXprLUBA", PkXprLUBA}})
		SetRecordValues(netview,null,{{"TTPkNStAB", TTPkNStAB}}) 
		SetRecordValues(netview,null,{{"TTPkNStBA", TTPkNStBA}})  
		SetRecordValues(netview,null,{{"TTFrNStAB", TTFrNStAB}}) 
		SetRecordValues(netview,null,{{"TTFrNStBA", TTFrNStBA}})  
		SetRecordValues(netview,null,{{"TTPkSkSAB", TTPkSkSAB}}) 
		SetRecordValues(netview,null,{{"TTPkSkSBA", TTPkSkSBA}})  
		SetRecordValues(netview,null,{{"TTFrSkSAB", TTFrSkSAB}}) 
		SetRecordValues(netview,null,{{"TTFrSkSBA", TTFrSkSBA}})  
		SetRecordValues(netview,null,{{"SpdLimRun", SpdLimRun}})  
		
		lanesAB = null
		lanesBA = null
	 	hi = GetNextRecord(netview+"+ Copy|", null, )
		t = t + 1
	    end
	
		closeview("Copy")
		closeview(netview+"+ Copy")
		
		closemap()
		DestroyProgressBar()
		
	end //end loop of time periods


	RunMacro("G30 File Close All")

	AppendToLogFile(1, "Exit CapSpd: " + datentime)
	return({1, msg})

	userquit:
	msg = {"CapSpd - User Quit"}
	AppendToLogFile(1, "CapSpd - User Quit")
	goto done
	badquit:
	msg = {"CapSpd - Error End"}
	AppendToLogFile(1, "CapSpd - Error End")
	goto done
	nodirquit:
	msg = {"CapSpd, No Dir quit"}
	AppendToLogFile(1, "CapSpd, No Dir quit")
	done:
	AppendToLogFile(1, "Exit CapSpd: " + datentime)

	return({0, msg})
endmacro

