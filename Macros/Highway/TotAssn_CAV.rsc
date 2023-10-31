macro "TotAssn_CAV" 
//*********************************************************************************************************************

/* 		SCENARIO PLANNING:

tot_assn just for Moderate and Aggressive highway assignments

need to hard-code directory

*/
//********************************************************************************************************************

	Dir = "C:\\1ScenarioPlanning\\Metrolina\\2045"									//
	AssnSubDir = Dir + "\\HwyAssn"

	netview = "RegNet50_AMPeak"
	MaxTTFac = 10.0
	pkhrfac = 0.4
	
	totassnOK = 1
	
	info = GetDBInfo(Dir + "\\"+netview+".dbd")
	scope = info[1]

	// Create a map using this scope
	CreateMap(netview, {{"Scope", scope},{"Auto Project", "True"}})

	file = Dir + "\\"+netview+".dbd"
	layers = GetDBLayers(file)
	addlayer(netview, "Node", file, layers[1])
	addlayer(netview, netview, file, layers[2])
	SetLayerVisibility("Node", "True")
	SetIcon("Node|", "Font Character", "Caliper Cartographic|2", 36)
	SetLayerVisibility(netview, "True")
	solid = LineStyle({{{1, -1, 0}}})
	SetLineStyle(netview+"|", solid)
	SetLineColor(netview+"|", ColorRGB(32000, 32000, 32000))
	SetLineWidth(netview+"|", 0)

	setview(netview)

	cntflag		= CreateExpression(netview, "CNTFLAG", "if CALIB18 > 0 then 1 else 0",)
	fun2		= CreateExpression(netview, "Fun2", "if FUNCL = 1 or FUNCL = 2 or FUNCL = 9 then 1 else if funcl < 6 then 3 else if funcl < 10 then 4 else if (funcl > 20 and funcl < 30 or funcl = 82 or funcl = 83) then 2 else 0",)  
	cntyaf	= CreateExpression(netview, "CntyAF", "COUNTY * 10000 + AREATP * 100 + Fun2",)
	vmtlen	= CreateExpression(netview, "VMTLen", "if FUNCL = 90 then nz(LENGTH) * 2 else nz(LENGTH)",)
	stcnty	= CreateExpression(netview, "STCNTY", "r2i(State * 1000 + County)",)

// drop transit links
	selectset = "select * where FUNCL < 30 or FUNCL = 82 or FUNCL = 83 or FUNCL = 90"
	nlnks = SelectbyQuery("HwyLinks", "Several", selectset,)

	net_bin = AssnSubDir + "\\Tempnet.bin"
	tjoin_bin = AssnSubDir + "\\Tempjoinnet.bin"

	netfields = {"ID", "LENGTH", "DIR", "FUNCL", "FEDFUNC_AQ", "CO_FEDFUNC", "Strname", "A_CrossStr", "B_CrossStr", "AREATP", "CALIB18", "MTK18", "HTK18", "Scrln", 
				"COUNTY", "STCNTY", "Cap1hrAB", "Cap1hrBA", "TTfreeAB", "TTfreeBA", "TTPkAssnAB", "TTPkAssnBA", "lanesAB", "lanesBA", "CNTFLAG", "Fun2", "CntyAF", "VMTLen"}

	ExportView(netview+"|HwyLinks", "FFB", net_bin, netfields ,)

	// temporary fields for joining to assn output tables
	tid 		= CreateExpression(netview, "tid", "ID",)
	tdir		= CreateExpression(netview, "tdir", "DIR",)
	tfun 	= CreateExpression(netview,  "tfun", "FUNCL",)
	ttfrab 	= CreateExpression(netview, "ttfrab", "nz(TTFreeAB)",)
	ttfrba 	= CreateExpression(netview, "ttfrba", "nz(TTFreeBA)",)
	tcapab	= CreateExpression(netview, "tcapab", "nz(Cap1HrAB)",)
	tcapba	= CreateExpression(netview, "tcapba", "nz(Cap1HrBA)",)

	ExportView(netview+"|HwyLinks", "FFB", tjoin_bin, {"tid","tdir","tfun","ttfrab", "ttfrba", "tcapab","tcapba", "VMTLen"},{"Indexed Fields", {"tid"}}) 
	closemap()
	
		am_bin = AssnSubDir + "\\Assn_AMPeakCAV.bin"
		pm_bin = AssnSubDir + "\\Assn_PMPeakCAV.bin"
		mi_bin = AssnSubDir + "\\Assn_MiddayCAV.bin"
		nt_bin = AssnSubDir + "\\Assn_NightCAV.bin"
		out_bin = AssnSubDir + "\\Tot_Assn_CAV.bin"


	tempam_bin = AssnSubDir + "\\TempAM.bin"
	temppm_bin = AssnSubDir + "\\TempPM.bin"
	tempmi_bin = AssnSubDir + "\\TempMI.bin"	
	tempnt_bin = AssnSubDir + "\\TempNT.bin"


// open temp network join and tod - join

	temp_bin = {tempam_bin, temppm_bin, tempmi_bin, tempnt_bin}
	tod = {"AM", "PM", "MI", "NT"}
	tod_bin = {am_bin, pm_bin, mi_bin, nt_bin}

   for i = 1 to tod.length do // loop on 4 TODs

	tjoin_in = OpenTable("Net", "FFB", {tjoin_bin,})
	tod_in  = OpenTable(tod[i], "FFB", {tod_bin[i],})
    
	jointod = JoinViews("jointod", "Net.tid",tod[i] + ".ID1",)
    
	CloseView(tod_in)
    
// Create TOD fields

	volab		= CreateExpression(jointod, "Vol" + tod[i] + "AB", "nz(AB_Flow)",) 
	volba		= CreateExpression(jointod, "Vol" + tod[i] + "BA", "nz(BA_Flow)",) 
	totvol		= CreateExpression(jointod, "Vol" + tod[i], "r2i(nz(AB_Flow) + nz(BA_Flow))",) 
	minrawab	= CreateExpression(jointod, "MinRaw" + tod[i] + "AB", "if tfun = 90 then nz(AB_Time)* 2 else nz(AB_Time)",)
	minrawba	= CreateExpression(jointod, "MinRaw" + tod[i] + "BA", "if tfun = 90 then nz(BA_Time)* 2 else nz(BA_Time)",)
	minab		= CreateExpression(jointod, "min" + tod[i] + "AB", "min(nz(MinRaw" + tod[i] + "AB), ttfrab * " + i2s(MaxTTFac) + ")",)
	minba		= CreateExpression(jointod, "min" + tod[i] + "BA", "min(nz(MinRaw" + tod[i] + "BA), ttfrba * " + i2s(MaxTTFac) + ")",)
	vmtab		= CreateExpression(jointod, "VMT" + tod[i] + "AB", "Vol" + tod[i] + "AB * VMTlen",)
	vmtba		= CreateExpression(jointod, "VMT" + tod[i] + "BA", "Vol" + tod[i] + "BA * VMTlen",)
	vhtab		= CreateExpression(jointod, "VHT" + tod[i] + "AB", "Vol" + tod[i] + "AB * (min" + tod[i] + "AB / 60.)",)
	vhtba		= CreateExpression(jointod, "VHT" + tod[i] + "BA", "Vol" + tod[i] + "BA * (min" + tod[i] + "BA / 60.)",)
	vmt_tod		= CreateExpression(jointod, "VMT_" + tod[i], "VMT" + tod[i] + "AB + VMT" + tod[i] + "BA",)
	vht_tod		= CreateExpression(jointod, "VHT_" + tod[i], "VHT" + tod[i] + "AB + VHT" + tod[i] + "BA",)

	REGsovab	= CreateExpression(jointod, "REGsov" + tod[i] + "AB", "nz(AB_Flow_SOV)",)
	REGsovba	= CreateExpression(jointod, "REGsov" + tod[i] + "BA", "nz(BA_Flow_SOV)",)
	REGpl2ab	= CreateExpression(jointod, "REGpl2" + tod[i] + "AB", "nz(AB_Flow_Pool2)",)
	REGpl2ba	= CreateExpression(jointod, "REGpl2" + tod[i] + "BA", "nz(BA_Flow_Pool2)",)
	REGpl3ab	= CreateExpression(jointod, "REGpl3" + tod[i] + "AB", "nz(AB_Flow_Pool3)",)
	REGpl3ba	= CreateExpression(jointod, "REGpl3" + tod[i] + "BA", "nz(BA_Flow_Pool3)",)
	REGcomab	= CreateExpression(jointod, "REGcom" + tod[i] + "AB", "nz(AB_Flow_COM)",)
	REGcomba	= CreateExpression(jointod, "REGcom" + tod[i] + "BA", "nz(BA_Flow_COM)",)
	REGmtkab	= CreateExpression(jointod, "REGmtk" + tod[i] + "AB", "nz(AB_Flow_MTK)",)
	REGmtkba	= CreateExpression(jointod, "REGmtk" + tod[i] + "BA", "nz(BA_Flow_MTK)",)
	REGhtkab	= CreateExpression(jointod, "REGhtk" + tod[i] + "AB", "nz(AB_Flow_HTK)",)
	REGhtkba	= CreateExpression(jointod, "REGhtk" + tod[i] + "BA", "nz(BA_Flow_HTK)",)

// v/c - 2 classes - (2 peaks) - each gets 1/4 capacity lane miles (1/2 of oneway) 
	vcab		= CreateExpression(jointod, "vc" + tod[i] + "AB", "if tdir <> -1 then (nz(AB_Flow) * " + r2s(pkhrfac) + ") / tcapab else 0",)
	vcba		= CreateExpression(jointod, "vc" + tod[i] + "BA", "if tdir <> 1 then (nz(BA_Flow) * " + r2s(pkhrfac) + ") / tcapba else 0",)


		CAVsovab	= CreateExpression(jointod, "CAVsov" + tod[i] + "AB", "nz(AB_Flow_CAVSOV)",)
		CAVsovba	= CreateExpression(jointod, "CAVsov" + tod[i] + "BA", "nz(BA_Flow_CAVSOV)",)
		CAVpl2ab	= CreateExpression(jointod, "CAVpl2" + tod[i] + "AB", "nz(AB_Flow_CAVPOOL2)",)
		CAVpl2ba	= CreateExpression(jointod, "CAVpl2" + tod[i] + "BA", "nz(BA_Flow_CAVPOOL2)",)
		CAVpl3ab	= CreateExpression(jointod, "CAVpl3" + tod[i] + "AB", "nz(AB_Flow_CAVPOOL3)",)
		CAVpl3ba	= CreateExpression(jointod, "CAVpl3" + tod[i] + "BA", "nz(BA_Flow_CAVPOOL3)",)
		CAVcomab	= CreateExpression(jointod, "CAVcom" + tod[i] + "AB", "nz(AB_Flow_CAVCOM)",)
		CAVcomba	= CreateExpression(jointod, "CAVcom" + tod[i] + "BA", "nz(BA_Flow_CAVCOM)",)
		CAVmtkab	= CreateExpression(jointod, "CAVmtk" + tod[i] + "AB", "nz(AB_Flow_CAVMTK)",)
		CAVmtkba	= CreateExpression(jointod, "CAVmtk" + tod[i] + "BA", "nz(BA_Flow_CAVMTK)",)
		CAVhtkab	= CreateExpression(jointod, "CAVhtk" + tod[i] + "AB", "nz(AB_Flow_CAVHTK)",)
		CAVhtkba	= CreateExpression(jointod, "CAVhtk" + tod[i] + "BA", "nz(BA_Flow_CAVHTK)",)
		sov		= CreateExpression(jointod, "sov" + tod[i], "REGsov" + tod[i] + "AB + REGsov" + tod[i] + "BA + CAVsov" + tod[i] + "AB + CAVsov" + tod[i] + "BA",)
		com		= CreateExpression(jointod, "com" + tod[i], "REGcom" + tod[i] + "AB + REGcom" + tod[i] + "BA + CAVcom" + tod[i] + "AB + CAVcom" + tod[i] + "BA",)
		pool2	= CreateExpression(jointod, "pool2" + tod[i], "REGpl2" + tod[i] + "AB + REGpl2" + tod[i] + "BA + CAVpl2" + tod[i] + "AB + CAVpl2" + tod[i] + "BA",)
		pool3	= CreateExpression(jointod, "pool3" + tod[i], "REGpl3" + tod[i] + "AB + REGpl3" + tod[i] + "BA + CAVpl3" + tod[i] + "AB + CAVpl3" + tod[i] + "BA",)
		mtk		= CreateExpression(jointod, "mtk" + tod[i], "REGmtk" + tod[i] + "AB + REGmtk" + tod[i] + "BA + CAVmtk" + tod[i] + "AB + CAVmtk" + tod[i] + "BA",)
		htk		= CreateExpression(jointod, "htk" + tod[i], "REGhtk" + tod[i] + "AB + REGhtk" + tod[i] + "BA + CAVhtk" + tod[i] + "AB + CAVhtk" + tod[i] + "BA",)
		
		MiddleField	= {"REGsov" + tod[i] + "AB", "REGsov" + tod[i] + "BA", "CAVsov" + tod[i] + "AB", "CAVsov" + tod[i] + "BA", 
					"REGpl2" + tod[i] + "AB", "REGpl2" + tod[i] + "BA", "CAVpl2" + tod[i] + "AB", "CAVpl2" + tod[i] + "BA", 
					"REGpl3" + tod[i] + "AB", "REGpl3" + tod[i] + "BA", "CAVpl3" + tod[i] + "AB", "CAVpl3" + tod[i] + "BA", 
					"REGcom" + tod[i] + "AB", "REGcom" + tod[i] + "BA", "CAVcom" + tod[i] + "AB", "CAVcom" + tod[i] + "BA",
					"REGmtk" + tod[i] + "AB", "REGmtk" + tod[i] + "BA", "CAVmtk" + tod[i] + "AB", "CAVmtk" + tod[i] + "BA", 
					"REGhtk" + tod[i] + "AB", "REGhtk" + tod[i] + "BA", "CAVhtk" + tod[i] + "AB", "CAVhtk" + tod[i] + "BA",
					"sov" + tod[i], "pool2" + tod[i], "pool3" + tod[i], "com" + tod[i], "mtk" + tod[i], "htk" + tod[i]}


	BeginField = {"tid", "MinRaw" + tod[i] + "AB", "MinRaw" + tod[i] + "BA", "min" + tod[i] + "AB", "min" + tod[i] + "BA"}

	EndField = {"Vol" + tod[i] + "AB", "Vol" + tod[i] + "BA", "Vol" + tod[i], "VMT" + tod[i] + "AB", "VMT" + tod[i] + "BA", 
			   "VHT" + tod[i] + "AB", "VHT" + tod[i] + "BA", "VMT_" + tod[i], "VHT_" + tod[i], "vc" + tod[i] + "AB", "vc" + tod[i] + "BA"}

	Fields = BeginField + MiddleField + EndField
	ExportView(jointod+"|", "FFB", temp_bin[i], Fields,)

	CloseView(jointod)

   end	// end tod loop
	
	//Reopen the four tod temp files and join
	net2_in = OpenTable("Net2", "FFB", {net_bin})
  	am2_in  = OpenTable("AM2", "FFB", {tempam_bin,})
  	pm2_in  = OpenTable("PM2", "FFB", {temppm_bin,})
  	mi2_in  = OpenTable("MI2", "FFB", {tempmi_bin,})
  	nt2_in  = OpenTable("NT2", "FFB", {tempnt_bin,})

	join1 = JoinViews("join1", "Net2.ID","AM2.tid",)
	join2 = JoinViews("join2", "join1.ID", "PM2.tid",)
	join3 = JoinViews("join3", "join2.ID", "MI2.tid",)
	join4 = JoinViews("join4", "join3.ID", "NT2.tid",)

	CloseView(net2_in)
	CloseView(am2_in)
	CloseView(pm2_in)
	CloseView(mi2_in)
	CloseView(nt2_in)
	CloseView(join1)
	CloseView(join2)
	CloseView(join3)  

//Daily fields
	totsov		= CreateExpression(join4, "TOT_SOV", "sovAM + sovPM + sovMI + sovNT",)
	totpl2		= CreateExpression(join4, "TOT_POOL2", "pool2AM + pool2PM + pool2MI + pool2NT",)
	totpl3		= CreateExpression(join4, "TOT_POOL3", "pool3AM + pool3PM + pool3MI + pool3NT",)
	totcom		= CreateExpression(join4, "TOT_COM", "comAM + comPM + comMI + comNT",)
	totmtk		= CreateExpression(join4, "TOT_MTK", "mtkAM + mtkPM + mtkMI + mtkNT",)
	tothtk		= CreateExpression(join4, "TOT_HTK", "htkAM + htkPM + htkMI + htkNT",)
	totvolAB	= CreateExpression(join4, "TotVolAB", "VolAMAB + VolPMAB + VolMIAB + VolNTAB",)
	totvolBA	= CreateExpression(join4, "TotVolBA", "VolAMBA + VolPMBA + VolMIBA + VolNTBA",)
	tot_vol		= CreateExpression(join4, "Tot_Vol", "VolAMAB + VolAMBA + VolPMAB + VolPMBA + VolMIAB + VolMIBA + VolNTAB + VolNTBA",)
	volpost		= CreateExpression(join4, "VOL_POST", "r2i(round(TOT_VOL / 100, 0) * 100)",)

	tot_vmt		= CreateExpression(join4, "TOT_VMT", "VMT_AM + VMT_MI + VMT_PM + VMT_NT",)	//move in front of vol flds
	tot_vht		= CreateExpression(join4, "TOT_VHT", "VHT_AM + VHT_MI + VHT_PM + VHT_NT",)


	cntmcsq		= CreateExpression(join4, "CNTMCSQ", "if CALIB18 > 0 then pow(TOT_VOL - CALIB18,2) else 0",)
//	commcsq		= CreateExpression(join4, "COMMCSQ", "if COM08 > 0 then pow(TOT_COM - COM08,2) else 0",)
	mtkmcsq		= CreateExpression(join4, "MTKMCSQ", "if MTK18 > 0 then pow(TOT_MTK - MTK18,2) else 0",) 
	htkmcsq		= CreateExpression(join4, "HTKMCSQ", "if HTK18 > 0 then pow(TOT_HTK - HTK18,2) else 0",)


		OutFields = 
		{"ID", "LENGTH", "DIR", "FUNCL", "FEDFUNC_AQ", "CO_FEDFUNC", "Strname", "A_CrossStr", "B_CrossStr", 
	  	 "AREATP", "CALIB18", "MTK18", "HTK18", "Scrln", "COUNTY", "STCNTY", "Cap1hrAB", "Cap1hrBA", 
	 	 "TTfreeAB", "TTfreeBA", "TTPkAssnAB", "TTPkAssnBA", "lanesAB", "lanesBA",
	 	 "Fun2", "CntyAF", "VMTLen", 
	 	 "TotVolAB", "TotVolBA", "VOL_POST", "Tot_Vol",   
	 	 "TOT_VMT", "VMT_AM", "VMT_MI", "VMT_PM", "VMT_NT", 
		 "TOT_VHT", "VHT_AM", "VHT_MI", "VHT_PM", "VHT_NT",  
 	 	 "TOT_SOV", "sovAM", "sovMI", "sovPM", "sovNT", 
 	 	 "TOT_POOL2", "pool2AM", "pool2MI", "pool2PM", "pool2NT", 
 	 	 "TOT_POOL3", "pool3AM", "pool3MI", "pool3PM","pool3NT",  
 	 	 "TOT_COM", "comAM", "comMI", "comPM", "comNT", 
 	 	 "TOT_MTK", "mtkAM", "mtkMI", "mtkPM", "mtkNT", 
 	 	 "TOT_HTK", "htkAM", "htkMI", "htkPM", "htkNT", 
	 	 "VolAMAB", "VolAMBA", "VolMIAB", "VolMIBA", "VolPMAB", "VolPMBA", "VolNTAB", "VolNTBA", 
	 	 "REGsovAMAB", "REGsovAMBA",  "REGsovMIAB", "REGsovMIBA", "REGsovPMAB", "REGsovPMBA", "REGsovNTAB", "REGsovNTBA",  
	 	 "CAVsovAMAB", "CAVsovAMBA", "CAVsovMIAB", "CAVsovMIBA", "CAVsovPMAB", "CAVsovPMBA", "CAVsovNTAB", "CAVsovNTBA",  
	 	 "REGpl2AMAB", "REGpl2AMBA", "REGpl2MIAB", "REGpl2MIBA", "REGpl2PMAB", "REGpl2PMBA", "REGpl2NTAB", "REGpl2NTBA",  
	 	 "CAVpl2AMAB", "CAVpl2AMBA", "CAVpl2MIAB", "CAVpl2MIBA", "CAVpl2PMAB", "CAVpl2PMBA", "CAVpl2NTAB", "CAVpl2NTBA",   
	 	 "REGpl3AMAB", "REGpl3AMBA", "REGpl3MIAB", "REGpl3MIBA", "REGpl3PMAB", "REGpl3PMBA", "REGpl3NTAB", "REGpl3NTBA",   
	 	 "CAVpl3AMAB", "CAVpl3AMBA", "CAVpl3MIAB", "CAVpl3MIBA", "CAVpl3PMAB", "CAVpl3PMBA", "CAVpl3NTAB", "CAVpl3NTBA",   
	 	 "REGcomAMAB", "REGcomAMBA", "REGcomMIAB", "REGcomMIBA", "REGcomPMAB", "REGcomPMBA", "REGcomNTAB", "REGcomNTBA",
	 	 "CAVcomAMAB", "CAVcomAMBA", "CAVcomMIAB", "CAVcomMIBA", "CAVcomPMAB", "CAVcomPMBA", "CAVcomNTAB", "CAVcomNTBA",    
	 	 "REGmtkAMAB", "REGmtkAMBA", "REGmtkMIAB", "REGmtkMIBA", "REGmtkPMAB", "REGmtkPMBA", "REGmtkNTAB", "REGmtkNTBA",   
	 	 "CAVmtkAMAB", "CAVmtkAMBA", "CAVmtkMIAB", "CAVmtkMIBA", "CAVmtkPMAB", "CAVmtkPMBA", "CAVmtkNTAB", "CAVmtkNTBA",   
	 	 "REGhtkAMAB", "REGhtkAMBA", "REGhtkMIAB", "REGhtkMIBA", "REGhtkPMAB", "REGhtkPMBA", "REGhtkNTAB", "REGhtkNTBA",   
	 	 "CAVhtkAMAB", "CAVhtkAMBA", "CAVhtkMIAB", "CAVhtkMIBA", "CAVhtkPMAB", "CAVhtkPMBA", "CAVhtkNTAB", "CAVhtkNTBA",   
	 	 "minAMAB", "minAMBA", "minMIAB", "minMIBA", "minPMAB", "minPMBA", "minNTAB", "minNTBA", 
	 	 "MinRawAMAB", "MinRawAMBA", "MinRawMIAB", "MinRawMIBA", "MinRawPMAB", "MinRawPMBA", "MinRawNTAB", "MinRawNTBA", 
	 	 "VMTAMAB", "VMTAMBA", "VMTMIAB", "VMTMIBA", "VMTPMAB", "VMTPMBA", "VMTNTAB", "VMTNTBA",   
	 	 "VHTAMAB", "VHTAMBA", "VHTMIAB", "VHTMIBA", "VHTPMAB", "VHTPMBA", "VHTNTAB", "VHTNTBA",  
	 	 "vcAMAB", "vcAMBA", "vcPMAB", "vcPMBA", 
	 	 "CNTFLAG", "CNTMCSQ", "MTKMCSQ", "HTKMCSQ"}


	ExportView(join4+"|", "FFB", out_bin, OutFields,)

	CloseView(join4)


	return(totassnOK)

endmacro
