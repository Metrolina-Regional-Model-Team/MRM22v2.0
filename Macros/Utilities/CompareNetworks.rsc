macro "CompareNetworks" 

//Find differences between two networks
// Network A is assumed to be the base
// Network B is compared to A - all changes are "from" network A
// McLelland - August 2011

//Ecodes
// 1:  record missing from file B
// 2:  record missing from file A
// 3:  main record differences
// 4:  project record differences

	NumVar = 100
	VarName = {"ID",         "Length",     "Dir",        "Anode",      	//   4
	           "Bnode",      "Strname",    "A_CrossStr", "B_CrossStr", 	//   8
		   "funcl",      "fedfuncl",   "fedfunc_AQ", "Lanes",      	//  12 
		   "lanesAB",    "lanesBA",    "factype",    "Spdlimit",   	//  16
		   "SpdLimRun",  "parking",    "Pedactivity","Developden", 	//  20
		   "Drivewayden","landuse",    "A_LeftLns",  "A_ThruLns",       //  24
		   "A_RightLns", "A_Control",  "A_Prohibit", "B_LeftLns",       //  28
		   "B_ThruLns",  "B_RightLns", "B_control",  "B_prohibit", 	//  32    
		   "TMCcode_ab", "TMCcode_ba", "Scrln",      "State",      	//  36
		   "County",     "TAZ",        "locclass1",  "locclass2",  	//  40
		   "reverselane","reversetime","TollAB",     "TollBA",    	//  44 
		   "HOTAB",      "HOTBA",      "datestamp",  "Level",      	//  48
		   "TOLL_PRJID", "HOT_PRJID",  "ITS_Code",   "ITS_Segment",	//  52

		   "projnum1",   "DIR_prj1",   "funcl_prj1", "lnsAB_prj1",	//  56 
 		   "lnsBA_prj1", "factypprj1", "Acntl_prj1", "Aprhb_prj1", 	//  60`	
		   "Aleft_prj1", "Athru_prj1", "Arite_prj1", "Bcntl_prj1", 	//  64
		   "Bprhb_prj1", "Bleft_prj1", "Bthru_prj1", "Brite_prj1", 	//  68	

		   "projnum2",   "DIR_prj2",   "funcl_prj2", "lnsAB_prj2",	//  72 
 		   "lnsBA_prj2", "factypprj2", "Acntl_prj2", "Aprhb_prj2", 	//  76`	
		   "Aleft_prj2", "Athru_prj2", "Arite_prj2", "Bcntl_prj2", 	//  80
		   "Bprhb_prj2", "Bleft_prj2", "Bthru_prj2", "Brite_prj2", 	//  84	

		   "projnum3",   "DIR_prj3",   "funcl_prj3", "lnsAB_prj3",	//  88 
 		   "lnsBA_prj3", "factypprj3", "Acntl_prj3", "Aprhb_prj3", 	//  92`	
		   "Aleft_prj3", "Athru_prj3", "Arite_prj3", "Bcntl_prj3", 	//  96
		   "Bprhb_prj3", "Bleft_prj3", "Bthru_prj3", "Brite_prj3"}	// 100	

	VarType = {"I",          "R",          "I",          "I",		//   4	     
	           "I",          "S",          "S",          "S",        	//   8
	           "I",          "S",          "S",          "I",     		//  12   
	           "I",          "I",          "S",          "I",        	//  16
	           "I",          "S",          "S",          "S",        	//  20
	           "S",          "S",          "I",          "I",		//  24          
		   "I",          "S",          "S",          "I", 		//  28  
	           "I",          "I",          "S",          "S",		//  32
	           "S",          "S",          "I",          "I",		//  36
	           "I",          "I",          "I",          "I",  		//  40 
	           "I",          "S",          "R",          "R",		//  44
	           "R",          "R",          "I",          "I",		//  48
	           "I",          "I",          "I",          "I", 		//  52

       		   "I",          "I",          "I",	     "I",		//  56        
	           "I",          "S",          "S",          "S",        	//  60
	           "I",          "I",          "I",          "S",        	//  64
	           "S",          "I",          "I",          "I",        	//  68

       		   "I",          "I",          "I",	     "I",		//  72        
	           "I",          "S",          "S",          "S",        	//  76
	           "I",          "I",          "I",          "S",        	//  80
	           "S",          "I",          "I",          "I",        	//  84

       		   "I",          "I",          "I",	     "I",               //  88        
	           "I",          "S",          "S",          "S",        	//  92
	           "I",          "I",          "I",          "S",        	//  96
	           "S",          "I",          "I",          "I"}        	// 100


//	goto SkipAround
	picknetworks:
	net_fileA = ChooseFile({{"Standard (*.dbd)","*.dbd"}},"Network AAAAAAAAAAAAAAAAAAAAAAAAAAA:", )
	net_fileB = ChooseFile({{"Standard (*.dbd)","*.dbd"}},"Network BBBBBBBBBBBBBBBBBBBBBBBBBBB:", )

	if net_fileA <> net_fileB then goto LetsGo 
	SameFile = MessageBox("Rechoose files?",
		{{"Caption", "ERROR - networks A & B are same file"}, 
	 	 {"Buttons", "YesNo"}})
	if SameFile = "Yes" then goto picknetworks
			    else return()

	LetsGo:

	SetCursor("Hourglass")

//****
// Network A
// Identify network - extract all relevant fields to dbf for comparison
//****


	info = GetDBInfo(net_fileA)
	scope = info[1]
	layers = GetDBLayers(net_fileA)
	CreateMap(layers[2], {{"Scope", scope},{"Auto Project", "True"}})
	addlayer(layers[2], layers[1], net_fileA, layers[1])
	addlayer(layers[2], layers[2], net_fileA, layers[2])
	SetIcon(layers[1]+"|", "Font Character", "Caliper Cartographic|2", 36)
	SetLineStyle(layers[2]+"|", LineStyle({{{1, -1, 0}}}))
	SetLineColor(layers[2]+"|", ColorRGB(0, 0, 32000))
	SetLineWidth(layers[2]+"|", 0)
	SetLayerVisibility(layers[1], "True")
	SetLayerVisibility(layers[2], "True")

	MapNameA = layers[2]
	FileNameParts = SplitPath(net_fileA)
	DirA = FileNameParts[1] + FileNameParts[2]

// Get line layer

	PickALayer:
	lyr_info = GetLayers()
	LineArrayPos = 0
	for i = 1 to lyr_info[1].length do
		typei = GetLayerType(lyr_info[1][i])
		if typei = "Line" then do
			if LineArrayPos = 0 then do
				LineArray = {lyr_info[1][i]}
				LineArrayPos = LineArrayPos + 1     
			end  //if LineArrayPos
			else do
				LineArray = InsertArrayElements(LineArray, LineArrayPos, {lyr_info[1][i]})			
				LineArrayPos = LineArrayPos + 1     
			end //else do
		end // if typei		
	end //for i

	if LineArrayPos = 1 then do
		SetLayer(LineArray[1])
		LineViewA = GetView()
	end

// Update A and B nodes
	hi = GetFirstRecord(LineViewA + "|",)
	while hi <> null do
		mval = GetRecordValues(LineViewA, hi, {"ID"})
		record = mval[1][2]
		endpts = GetEndpoints(record)
		A_node = endpts[1]
		B_node = endpts[2]
		SetRecordValues(LineViewA,null,{{"Anode", A_node}})
		SetRecordValues(LineViewA,null,{{"Bnode", B_node}})
		hi = GetNextRecord(LineViewA + "|", null,)
	end

//  Export relevant fields

	Exportview(LineViewA+"|", "FFB", DirA + "\\LineFileA.bin", 
	          {"ID",         "Length",     "Dir",        "Anode",      	//   4
	           "Bnode",      "Strname",    "A_CrossStr", "B_CrossStr", 	//   8
		   "funcl",      "fedfuncl",   "fedfunc_AQ", "Lanes",      	//  12 
		   "lanesAB",    "lanesBA",    "factype",    "Spdlimit",   	//  16
		   "SpdLimRun",  "parking",    "Pedactivity","Developden", 	//  20
		   "Drivewayden","landuse",    "A_LeftLns",  "A_ThruLns",       //  24
		   "A_RightLns", "A_Control",  "A_Prohibit", "B_LeftLns",       //  28
		   "B_ThruLns",  "B_RightLns", "B_control",  "B_prohibit", 	//  32    
		   "TMCcode_ab", "TMCcode_ba", "Scrln",      "State",      	//  36
		   "County",     "TAZ",        "locclass1",  "locclass2",  	//  40
		   "reverselane","reversetime","TollAB",     "TollBA",    	//  44 
		   "HOTAB",      "HOTBA",      "datestamp",  "Level",      	//  48
		   "TOLL_PRJID", "HOT_PRJID",  "ITS_Code",   "ITS_Segment",	//  52

		   "projnum1",   "DIR_prj1",   "funcl_prj1", "lnsAB_prj1",	//  56 
 		   "lnsBA_prj1", "factypprj1", "Acntl_prj1", "Aprhb_prj1", 	//  60`	
		   "Aleft_prj1", "Athru_prj1", "Arite_prj1", "Bcntl_prj1", 	//  64
		   "Bprhb_prj1", "Bleft_prj1", "Bthru_prj1", "Brite_prj1", 	//  68	

		   "projnum2",   "DIR_prj2",   "funcl_prj2", "lnsAB_prj2",	//  72 
 		   "lnsBA_prj2", "factypprj2", "Acntl_prj2", "Aprhb_prj2", 	//  76`	
		   "Aleft_prj2", "Athru_prj2", "Arite_prj2", "Bcntl_prj2", 	//  80
		   "Bprhb_prj2", "Bleft_prj2", "Bthru_prj2", "Brite_prj2", 	//  84	

		   "projnum3",   "DIR_prj3",   "funcl_prj3", "lnsAB_prj3",	//  88 
 		   "lnsBA_prj3", "factypprj3", "Acntl_prj3", "Aprhb_prj3", 	//  92`	
		   "Aleft_prj3", "Athru_prj3", "Arite_prj3", "Bcntl_prj3", 	//  96
		   "Bprhb_prj3", "Bleft_prj3", "Bthru_prj3", "Brite_prj3"},)	// 100	

	CloseMap(MapNameA)
//****
// Network B
// Identify network - extract all relevant fields to dbf for comparison
//****

	info = GetDBInfo(net_fileB)
	scope = info[1]
	layers = GetDBLayers(net_fileB)
	CreateMap(layers[2], {{"Scope", scope},{"Auto Project", "True"}})
	addlayer(layers[2], layers[1], net_fileB, layers[1])
	addlayer(layers[2], layers[2], net_fileB, layers[2])
	SetIcon(layers[1]+"|", "Font Character", "Caliper Cartographic|2", 36)
	SetLineStyle(layers[2]+"|", LineStyle({{{1, -1, 0}}}))
	SetLineColor(layers[2]+"|", ColorRGB(0, 0, 32000))
	SetLineWidth(layers[2]+"|", 0)
	SetLayerVisibility(layers[1], "True")
	SetLayerVisibility(layers[2], "True")

	MapNameB = layers[2]
	FileNameParts = SplitPath(net_fileB)
	DirB = FileNameParts[1] + FileNameParts[2]

// Get line layer

	PickALayerB:
	lyr_info = GetLayers()
	LineArrayPos = 0
	for i = 1 to lyr_info[1].length do
		typei = GetLayerType(lyr_info[1][i])
		if typei = "Line" then do
			if LineArrayPos = 0 then do
				LineArray = {lyr_info[1][i]}
				LineArrayPos = LineArrayPos + 1     
			end  //if LineArrayPos
			else do
				LineArray = InsertArrayElements(LineArray, LineArrayPos, {lyr_info[1][i]})			
				LineArrayPos = LineArrayPos + 1     
			end //else do
		end // if typei		
	end //for i

	if LineArrayPos = 1 then do
		SetLayer(LineArray[1])
		LineViewB = GetView()
	end

// Update A and B nodes
	hi = GetFirstRecord(LineViewB + "|",)
	while hi <> null do
		mval = GetRecordValues(LineViewB, hi, {"ID"})
		record = mval[1][2]
		endpts = GetEndpoints(record)
		A_node = endpts[1]
		B_node = endpts[2]
		SetRecordValues(LineViewB,null,{{"Anode", A_node}})
		SetRecordValues(LineViewB,null,{{"Bnode", B_node}})
		hi = GetNextRecord(LineViewB + "|", null,)
	end

//  Export relevant fields

	Exportview(LineViewB+"|", "FFB", DirB + "\\LineFileB.bin", 
	          {"ID",         "Length",     "Dir",        "Anode",      	//   4
	           "Bnode",      "Strname",    "A_CrossStr", "B_CrossStr", 	//   8
		   "funcl",      "fedfuncl",   "fedfunc_AQ", "Lanes",      	//  12 
		   "lanesAB",    "lanesBA",    "factype",    "Spdlimit",   	//  16
		   "SpdLimRun",  "parking",    "Pedactivity","Developden", 	//  20
		   "Drivewayden","landuse",    "A_LeftLns",  "A_ThruLns",       //  24
		   "A_RightLns", "A_Control",  "A_Prohibit", "B_LeftLns",       //  28
		   "B_ThruLns",  "B_RightLns", "B_control",  "B_prohibit", 	//  32    
		   "TMCcode_ab", "TMCcode_ba", "Scrln",      "State",      	//  36
		   "County",     "TAZ",        "locclass1",  "locclass2",  	//  40
		   "reverselane","reversetime","TollAB",     "TollBA",    	//  44 
		   "HOTAB",      "HOTBA",      "datestamp",  "Level",      	//  48
		   "TOLL_PRJID", "HOT_PRJID",  "ITS_Code",   "ITS_Segment",	//  52

		   "projnum1",   "DIR_prj1",   "funcl_prj1", "lnsAB_prj1",	//  56 
 		   "lnsBA_prj1", "factypprj1", "Acntl_prj1", "Aprhb_prj1", 	//  60`	
		   "Aleft_prj1", "Athru_prj1", "Arite_prj1", "Bcntl_prj1", 	//  64
		   "Bprhb_prj1", "Bleft_prj1", "Bthru_prj1", "Brite_prj1", 	//  68	

		   "projnum2",   "DIR_prj2",   "funcl_prj2", "lnsAB_prj2",	//  72 
 		   "lnsBA_prj2", "factypprj2", "Acntl_prj2", "Aprhb_prj2", 	//  76`	
		   "Aleft_prj2", "Athru_prj2", "Arite_prj2", "Bcntl_prj2", 	//  80
		   "Bprhb_prj2", "Bleft_prj2", "Bthru_prj2", "Brite_prj2", 	//  84	

		   "projnum3",   "DIR_prj3",   "funcl_prj3", "lnsAB_prj3",	//  88 
 		   "lnsBA_prj3", "factypprj3", "Acntl_prj3", "Aprhb_prj3", 	//  92`	
		   "Aleft_prj3", "Athru_prj3", "Arite_prj3", "Bcntl_prj3", 	//  96
		   "Bprhb_prj3", "Bleft_prj3", "Bthru_prj3", "Brite_prj3"},)	// 100	

	CloseMap(MapNameB)

skiparound:


//output file to store comparison stats 
	LineD = CreateTable("LineD", DirA + "\\LineFileDiff.bin", "FFB",
		    {{"ID", "Integer", 8,,"No"},
		     {"DMessage", "String", 40,,"No"},
		     {"VarA", "String", 20,,"No"},
		     {"VarB", "String", 20,,"No"},
	             {"Ecode", "Integer", 4,, "No"}})

	LineD = OpenTable("LineD", "FFB", {DirA + "\\LineFileDiff.bin"},{{"Read Only", "False"},{"Shared", "False"}})
	Dptr = GetFirstRecord(LineD + "|",)

	Dptr = AddRecord(LineD, {{"Ecode", 0}, {"DMessage", net_fileA}})
	Dptr = GetNextRecord(LineD + "|", null,)
	Dptr = AddRecord(LineD, {{"Ecode", 0}, {"DMessage", net_fileB}})
	Dptr = GetNextRecord(LineD + "|", null,)

	LineA = OpenTable("LineA", "FFB", {DirA + "\\LineFileA.bin"},{{"Read Only", "False"},{"Shared", "False"}})
	LineB = OpenTable("LineB", "FFB", {DirB + "\\LineFileB.bin"},{{"Read Only", "False"},{"Shared", "False"}})


// All but

	LineJ = JoinViews("LineJ", "LineA.ID", "LineB.ID",)

	Jptr = GetFirstRecord(LineJ + "|",)
	while Jptr <> null do

		jval = GetRecordValues(LineJ, Jptr, 
		{"LineA.ID",         "LineA.Length",     "LineA.Dir",        "LineA.Anode",         //   4
	         "LineA.Bnode",      "LineA.Strname",    "LineA.A_CrossStr", "LineA.B_CrossStr",    //   8
		 "LineA.funcl",      "LineA.fedfuncl",   "LineA.fedfunc_AQ", "LineA.Lanes",         //  12
		 "LineA.lanesAB",    "LineA.lanesBA",    "LineA.factype",    "LineA.Spdlimit",      //  16
		 "LineA.SpdLimRun",  "LineA.parking",    "LineA.Pedactivity","LineA.Developden",    //  20
		 "LineA.Drivewayden","LineA.landuse",	 "LineA.A_LeftLns",  "LineA.A_ThruLns",     //  24 
		 "LineA.A_RightLns", "LineA.A_Control",  "LineA.A_Prohibit", "LineA.B_LeftLns",     //  28 
		 "LineA.B_ThruLns",  "LineA.B_RightLns", "LineA.B_control",  "LineA.B_prohibit",    //  32
		 "LineA.TMCcode_ab", "LineA.TMCcode_ba", "LineA.Scrln",      "LineA.State",         //  36
		 "LineA.County",     "LineA.TAZ",        "LineA.locclass1",  "LineA.locclass2",     //  40
		 "LineA.reverselane","LineA.reversetime","LineA.TollAB",     "LineA.TollBA",        //  44  
		 "LineA.HOTAB",      "LineA.HOTBA",      "LineA.datestamp",  "LineA.Level",         //  48  
		 "LineA.TOLL_PRJID", "LineA.HOT_PRJID",  "LineA.ITS_Code",   "LineA.ITS_Segment",   //  52

		 "LineA.projnum1",   "LineA.DIR_prj1",   "LineA.funcl_prj1", "LineA.lnsAB_prj1",    //  56
		 "LineA.lnsBA_prj1", "LineA.factypprj1", "LineA.Acntl_prj1", "LineA.Aprhb_prj1",    //  60
		 "LineA.Aleft_prj1", "LineA.Athru_prj1", "LineA.Arite_prj1", "LineA.Bcntl_prj1",    //  64
		 "LineA.Bprhb_prj1", "LineA.Bleft_prj1", "LineA.Bthru_prj1", "LineA.Brite_prj2",    //  68

	 	 "LineA.projnum2",   "LineA.dir_prj2",   "LineA.funcl_prj2", "LineA.lnsAB_prj2",    //  72
		 "LineA.lnsBA_prj2", "LineA.factypprj2", "LineA.Acntl_prj2", "LineA.Aprhb_prj2",    //  76
		 "LineA.Aleft_prj2", "LineA.Athru_prj2", "LineA.Arite_prj2", "LineA.Bcntl_prj2",    //  80 
		 "LineA.Bprhb_prj2", "LineA.Bleft_prj2", "LineA.Bthru_prj2", "LineA.Brite_prj2",    //  84 

		 "LineA.projnum3",   "LineA.dir_prj3",   "LineA.funcl_prj3", "LineA.lnsAB_prj3",    //  88
	 	 "LineA.lnsBA_prj3", "LineA.factypprj3", "LineA.Acntl_prj3", "LineA.Aprhb_prj3",    //  92
		 "LineA.Aleft_prj3", "LineA.Athru_prj3", "LineA.Arite_prj3", "LineA.Bcntl_prj3",    //  96
		 "LineA.Bprhb_prj3", "LineA.Bleft_prj3", "LineA.Bthru_prj3", "LineA.Brite_prj3",    // 100

		 "LineB.ID",         "LineB.Length",     "LineB.Dir",        "LineB.Anode",         // 104
	         "LineB.Bnode",      "LineB.Strname",    "LineB.A_CrossStr", "LineB.B_CrossStr",    // 108
		 "LineB.funcl",      "LineB.fedfuncl",   "LineB.fedfunc_AQ", "LineB.Lanes",         // 112
		 "LineB.lanesAB",    "LineB.lanesBA",    "LineB.factype",    "LineB.Spdlimit",      // 116
		 "LineB.SpdLimRun",  "LineB.parking",    "LineB.Pedactivity","LineB.Developden",    // 120
		 "LineB.Drivewayden","LineB.landuse",	 "LineB.A_LeftLns",  "LineB.A_ThruLns",     // 124 
		 "LineB.A_RightLns", "LineB.A_Control",  "LineB.A_Prohibit", "LineB.B_LeftLns",     // 128 
		 "LineB.B_ThruLns",  "LineB.B_RightLns", "LineB.B_control",  "LineB.B_prohibit",    // 132
		 "LineB.TMCcode_ab", "LineB.TMCcode_ba", "LineB.Scrln",      "LineB.State",         // 136
		 "LineB.County",     "LineB.TAZ",        "LineB.locclass1",  "LineB.locclass2",     // 140
		 "LineB.reverselane","LineB.reversetime","LineB.TollAB",     "LineB.TollBA",        // 144  
		 "LineB.HOTAB",      "LineB.HOTBA",      "LineB.datestamp",  "LineB.Level",         // 148  
		 "LineB.TOLL_PRJID", "LineB.HOT_PRJID",  "LineB.ITS_Code",   "LineB.ITS_Segment",   // 152

		 "LineB.projnum1",   "LineB.DIR_prj1",   "LineB.funcl_prj1", "LineB.lnsAB_prj1",    // 156
		 "LineB.lnsBA_prj1", "LineB.factypprj1", "LineB.Acntl_prj1", "LineB.Aprhb_prj1",    // 160
		 "LineB.Aleft_prj1", "LineB.Athru_prj1", "LineB.Arite_prj1", "LineB.Bcntl_prj1",    // 164
		 "LineB.Bprhb_prj1", "LineB.Bleft_prj1", "LineB.Bthru_prj1", "LineB.Brite_prj2",    // 168

	 	 "LineB.projnum2",   "LineB.dir_prj2",   "LineB.funcl_prj2", "LineB.lnsAB_prj2",    // 172
		 "LineB.lnsBA_prj2", "LineB.factypprj2", "LineB.Acntl_prj2", "LineB.Aprhb_prj2",    // 176
		 "LineB.Aleft_prj2", "LineB.Athru_prj2", "LineB.Arite_prj2", "LineB.Bcntl_prj2",    // 180 
		 "LineB.Bprhb_prj2", "LineB.Bleft_prj2", "LineB.Bthru_prj2", "LineB.Brite_prj2",    // 184 

		 "LineB.projnum3",   "LineB.dir_prj3",   "LineB.funcl_prj3", "LineB.lnsAB_prj3",    // 188
	 	 "LineB.lnsBA_prj3", "LineB.factypprj3", "LineB.Acntl_prj3", "LineB.Aprhb_prj3",    // 192
		 "LineB.Aleft_prj3", "LineB.Athru_prj3", "LineB.Arite_prj3", "LineB.Bcntl_prj3",    // 196
		 "LineB.Bprhb_prj3", "LineB.Bleft_prj3", "LineB.Bthru_prj3", "LineB.Brite_prj3"})   // 200

 

		if jval[NumVar + 1][2] = null then do 
			Dptr = AddRecord(LineD, {{"ID", jval[1][2]},
				{"Ecode", 1}, {"DMessage", "No Record in line file B"}})
			Dptr = GetNextRecord(LineD + "|", null,)
			goto skiprest
		end // if j[2][2] = null

		for j = 2 to NumVar do
			if jval[j][2] <> jval[j+NumVar][2] then do 
				if j < 53 then Evalue = 3
					  else Evalue = 4
				if VarType[j] = "I" then 
					Dptr = AddRecord(LineD, {{"ID", jval[1][2]}, 
				 		{"VarA", i2s(jval[j][2])},{"VarB", i2s(jval[j+NumVar][2])},
						{"Ecode", Evalue},{"DMessage", VarName[j]}})
				else if VarType[j] + "R" then
					Dptr = AddRecord(LineD, {{"ID", jval[1][2]}, 
				 		{"VarA", r2s(jval[j][2])},{"VarB", r2s(jval[j+NumVar][2])},
						{"Ecode", Evalue},{"DMessage", VarName[j]}})
				else	Dptr = AddRecord(LineD, {{"ID", jval[1][2]}, 
				 		{"VarA", jval[j][2]},{"VarB", jval[j+NumVar][2]},
						{"Ecode", Evalue},{"DMessage", VarName[j]}})
				Dptr = GetNextRecord(LineD + "|", null,)
			end // if jval
		end // for j 

		skiprest:
		Jptr = GetNextRecord(LineJ + "|", null,)
	end //while


	CloseView(LineJ)

//Records missing in file A

	LineJ = JoinViews("LineJ", "LineB.ID", "LineA.ID",)

	Jptr = GetFirstRecord(LineJ + "|",)
	while Jptr <> null do
		jval = GetRecordValues(LineJ, Jptr, {"LineB.ID", "LineA.ID"})
		if jval[2][2] = null then do 
			Dptr = AddRecord(LineD, {{"ID", jval[1][2]},
				{"Ecode", 2}, {"DMessage", "No Record in line file AAAA"}})
			Dptr = GetNextRecord(LineD + "|", null,)
		end // 
		Jptr = GetNextRecord(LineJ + "|", null,)
	end //while
	CloseView(LineJ)

//Compare variables

	ResetCursor()
	CloseView(LineA)
	CloseView(LineB)
	CloseView(LineD)

quit:
endmacro