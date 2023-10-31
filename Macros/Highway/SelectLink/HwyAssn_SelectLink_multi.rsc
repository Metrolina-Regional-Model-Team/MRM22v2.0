Macro "HwyAssn_SelectLink_multi" 

        shared net_file
//*********************************************************************************************************************
//Hwy Assn
// This version runs straight bpr delay.		

//   Added funcls 24 and 25: JWM, July 19, 2007
//   Update to TC 5.0 - change to bpr delay, Feb, 2008
//*********************************************************************************************************************
Dir = "D:\\Metrolina\\2015"
	timeweight = 2.0
	distweight = 0.1 
        minspfac = 10
	od_matrix = Dir + "\\tod2\\ODHwyVeh_AMPeakhot.mtx"
	cap_field = "CapPk3hr"
	output_bin = Dir + "\\hwyassn\\HOT\\AMPeakhot_University.bin"
	netview = "RegNet15"
	netname = netview
	Location = splitpath(Dir)

//capacity fields
	cap_fields = "[" + cap_field + "AB / " + cap_field + "BA]"

//      check highway network if hov lanes exist
//      hov2+ are funcl 22, 24, and 82  
//      hov3+ are funcl 23, 25, and 83
	net_file = Dir + "\\"+netview+".DBD"

	info = GetDBInfo(net_file)
	scope = info[1]
	CreateMap(netname, {{"Scope", scope},{"Auto Project", "True"}})
	layers = GetDBLayers(net_file)
	node_lyr = addlayer(netname, layers[1], net_file, layers[1])
	link_lyr = addlayer(netname, layers[2], net_file, layers[2])
	SetLayerVisibility(node_lyr, "False")
	SetIcon(node_lyr + "|", "Font Character", "Caliper Cartographic|4", 36)
	SetLayerVisibility(link_lyr, "True")
	solid = LineStyle({{{1, -1, 0}}})
	SetLineStyle(link_lyr+"|", solid)
	SetLineColor(link_lyr+"|", ColorRGB(0, 0, 32000))
	SetLineWidth(link_lyr+"|", 0)

	setview(netview)
	selpool2 = "Select * where funcl = 22 or funcl = 23 or funcl = 24 or funcl = 25 or funcl = 82 or funcl = 83"
	selpool3 = "Select * where funcl = 23 or funcl = 25 or funcl = 83"
	Selectbyquery("check_pool2", "Several", selpool2,)
	Selectbyquery("check_pool3", "Several", selpool3,)
	pool2count = getsetcount("check_pool2")
	pool3count = getsetcount("check_pool3")
//        showmessage("pool2 " + string(pool2count)+"    pool3 "+string(pool3count))
	closemap()


	if pool2count = 0 and pool3count = 0 then do
		goto assnnoHOV
		end
	else if pool2count > 0 and pool3count = 0 then do
		goto assnHOV2only
		end
	else do
		goto assnHOV2andHOV3
		end



assnnoHOV:

//Network has no HOV facilities - don't worry about exclusion sets
    RunMacro("TCB Init")

// Build Highway Network
     	Opts = null
     	Opts.Input.[Link Set] = {Dir + "\\"+netview+".DBD|"+netview, netview, "hwynet", "Select * where (funcl > 0 and funcl < 10) or funcl =90"}
	Opts.Global.[Network Options].[Link Type] = {"funcl", netview+".funcl", netview+".funcl"}
	Opts.Global.[Network Options].[Time Unit] = "Minutes"
     	Opts.Global.[Network Options].[Node ID] = "Node.ID"
     	Opts.Global.[Network Options].[Link ID] = netview+".ID"
     	Opts.Global.[Network Options].[Turn Penalties] = "No"
     	Opts.Global.[Network Options].[Keep Duplicate Links] = "FALSE"
     	Opts.Global.[Network Options].[Ignore Link Direction] = "FALSE"
	Opts.Global.[Link Options] = 
		{{"Length", {netview+".Length", netview+".Length", , , "False"}}, 
		 {"alpha", {netview+".alpha", netview+".alpha", , , "False"}},
		 {"beta", {netview+".beta", netview+".beta", , , "False"}}, 
		 {"[TTFreeAB / TTFreeBA]", {netview+".TTFreeAB", netview+".TTFreeBA", , , "True"}},
		 {"[CapPk3hrAB / CapPk3hrBA]", {netview+".CapPk3hrAB", netview+".CapPk3hrBA", , , "False"}},
		 {"[capMidAB / capMidBA]", {netview+".capMidAB", netview+".capMidBA", , , "False"}},
		 {"[capNightAB / capNightBA]", {netview+".capNightAB", netview+".capNightBA", , , "False"}},
		 {"[TollAB / TollBA]", {netview+".TollAB", netview+".TollBA", , , "False"}}}
	Opts.Global.[Length Unit] = "Miles"
	Opts.Global.[Time Unit] = "Minutes"
     	Opts.Output.[Network File] = Dir + "\\net_highway.net"

	ret_value = RunMacro("TCB Run Operation", "Build Highway Network", Opts, &Ret)
     	if !ret_value then goto badnetbuild


// Highway Network Setting

     	Opts = null
     	Opts.Input.Database = Dir + "\\"+netview+".DBD"
     	Opts.Input.Network = Dir + "\\net_highway.net"
     	Opts.Input.[Centroids Set] = {Dir + "\\"+netview+".DBD|Node", "Node", "centroid", "Select * where centroid = 1 or centroid = 2"}
	Opts.Input.[Spc Turn Pen Table]= {Location[1] + Location[2] + "trnpnlty.bin"}
      	Opts.Input.[Toll Set]= {Dir + "\\"+netview+".DBD|"+netview, netview, "tollset", "Select * where TollAB > 0 or TollBA > 0"}
     	Opts.Global.[Global Turn Penalties] = {0, 0, 0, -1}

	ret_value = RunMacro("TCB Run Operation", "Highway Network Setting", Opts, &Ret)
     	if !ret_value then goto notolls1
	goto skipnotolls1

	notolls1:

	Opts = null
     	Opts.Input.Database = Dir + "\\"+netview+".DBD"
     	Opts.Input.Network = Dir + "\\net_highway.net"
     	Opts.Input.[Centroids Set] = {Dir + "\\"+netview+".DBD|Node", "Node", "centroid", "Select * where centroid = 1 or centroid = 2"}
	Opts.Input.[Spc Turn Pen Table]= {Location[1] + Location[2] + "trnpnlty.bin"}
	Opts.Global.[Global Turn Penalties] = {0, 0, 0, -1}

	ret_value = RunMacro("TCB Run Operation", "Highway Network Setting", Opts, &Ret)
     	if !ret_value then goto badnetsettings
	
	skipnotolls1:

//MMA Assignment - No HOV

     	Opts = null
     	Opts.Input.Database = Dir + "\\"+netview+".DBD"
     	Opts.Input.Network = Dir + "\\net_highway.net"
     	Opts.Input.[OD Matrix Currency] = {od_matrix, "SOV", "Rows", "Columns"}
     	Opts.Input.[Exclusion Link Sets] = {, , , , ,}
     	Opts.Field.[Vehicle Classes] = {1, 2, 3, 4, 5, 6}
	Opts.Field.[Fixed Toll Fields] = {"[TollAB / TollBA]", "[TollAB / TollBA]", "[TollAB / TollBA]", "[TollAB / TollBA]", "[TollAB / TollBA]", "[TollAB / TollBA]"}
	Opts.Field.[PCE Fields] = {"None", "None", "None", "None", "None", "None"}
	Opts.Field.[VDF Fld Names] = {"[TTfreeAB / TTfreeBA]", cap_fields, "alpha", "beta", "None", "[TollAB / TollBA]", "None", "Length", "None"}
     	Opts.Global.[Number of Classes] = 6
	Opts.Global.[Load Method] = "UE"
	Opts.Global.[Loading Multiplier] = 1
	Opts.Global.Convergence = 0.01
	Opts.Global.[Time Minimum] = 0.01
    	Opts.Global.[Class PCEs] = {1, 1, 1, 1, 1.5, 2.5}
     	Opts.Global.[Class VOIs] = {1, 1, 1, 1, 1, 1}
     	Opts.Global.[Cost Function File] = "gc_mrm.vdf"
	Opts.Global.[VDF Defaults] = {, , 0.15, 4, 0, distweight, timeweight, , 0}
     	Opts.Global.Iterations = 50

     	Opts.Flag.[Do Critical] = 0
     	Opts.Flag.[Do Share Report] = 1   
     	Opts.Output.[Flow Table] = output_bin

	ret_value = RunMacro("TCB Run Procedure", "MMA", Opts, &Ret)
     	if !ret_value then goto badassign
goto quit

assnHOV2only:
    RunMacro("TCB Init")
//Network has HOV2+ facilities - and no HOV3+ facilities
//exclude link sets for 6 vol classes
// 1 = sov - exclude from hov2+ and hov3+  (funcl 22,24,82 & 23,25,83=sovexclude)
// 2 = pool2 - no exclusion 
// 3 = pool3 - no exclusion
// 4 = COM - exclude from all hov (sovexclude)
// 5 = MTK - exclude from all hov (sovexclude)
// 6 = HTK - exclude from all hov (sovexclude)


// Build Highway Network
    RunMacro("TCB Init")
     	Opts = null
     	Opts.Input.[Link Set] = {Dir + "\\"+netview+".DBD|"+netview, netview, "hwynet", "Select * where (funcl > 0 and funcl < 10) or funcl = 22 or funcl = 23 or funcl = 24 or funcl = 25 or funcl = 82 or funcl = 83 or funcl = 90"}
	Opts.Global.[Network Options].[Link Type] = {"funcl", netview+".funcl", netview+".funcl"}
	Opts.Global.[Network Options].[Time Unit] = "Minutes"
     	Opts.Global.[Network Options].[Node ID] = "Node.ID"
     	Opts.Global.[Network Options].[Link ID] = netview+".ID"
     	Opts.Global.[Network Options].[Turn Penalties] = "Yes"
     	Opts.Global.[Network Options].[Keep Duplicate Links] = "FALSE"
     	Opts.Global.[Network Options].[Ignore Link Direction] = "FALSE"
	Opts.Global.[Link Options] = 
		{{"Length", {netview+".Length", netview+".Length", , , "False"}}, 
		 {"alpha", {netview+".alpha", netview+".alpha", , , "False"}},
		 {"beta", {netview+".beta", netview+".beta", , , "False"}}, 
		 {"[TTFreeAB / TTFreeBA]", {netview+".TTFreeAB", netview+".TTFreeBA", , , "True"}},
		 {"[CapPk3hrAB / CapPk3hrBA]", {netview+".CapPk3hrAB", netview+".CapPk3hrBA", , , "False"}},
		 {"[capMidAB / capMidBA]", {netview+".capMidAB", netview+".capMidBA", , , "False"}},
		 {"[capNightAB / capNightBA]", {netview+".capNightAB", netview+".capNightBA", , , "False"}},
		 {"[TollAB / TollBA]", {netview+".TollAB", netview+".TollBA", , , "False"}}}
	Opts.Global.[Length Unit] = "Miles"
	Opts.Global.[Time Unit] = "Minutes"
     	Opts.Output.[Network File] = Dir + "\\net_highway.net"

	ret_value = RunMacro("TCB Run Operation", "Build Highway Network", Opts, &Ret)
     	if !ret_value then goto badnetbuild

// Highway Network Setting

     	Opts = null
     	Opts.Input.Database = Dir + "\\"+netview+".DBD"
     	Opts.Input.Network = Dir + "\\net_highway.net"
     	Opts.Input.[Centroids Set] = {Dir + "\\"+netview+".DBD|Node", "Node", "centroid", "Select * where centroid = 1 or centroid = 2"}
	Opts.Input.[Spc Turn Pen Table]= {Location[1] + Location[2] + "trnpnlty.bin"}
      	Opts.Input.[Toll Set]= {Dir + "\\"+netview+".DBD|"+netview, netview, "tollset", "Select * where TollAB > 0 or TollBA > 0"}
    	Opts.Global.[Global Turn Penalties] = {0, 0, 0, -1}

	ret_value = RunMacro("TCB Run Operation", "Highway Network Setting", Opts, &Ret)
     	if !ret_value then goto notolls2
	goto skipnotolls2

	notolls2:
	Opts = null
     	Opts.Input.Database = Dir + "\\"+netview+".DBD"
     	Opts.Input.Network = Dir + "\\net_highway.net"
     	Opts.Input.[Centroids Set] = {Dir + "\\"+netview+".DBD|Node", "Node", "centroid", "Select * where centroid = 1 or centroid = 2"}
	Opts.Input.[Spc Turn Pen Table]= {Location[1] + Location[2] + "trnpnlty.bin"}
	Opts.Global.[Global Turn Penalties] = {0, 0, 0, -1}

	ret_value = RunMacro("TCB Run Operation", "Highway Network Setting", Opts, &Ret)
     	if !ret_value then goto badnetsettings

	skipnotolls2:

// MMA Assignment 

//showmessage(od_matrix+" "+cap_field+" "+output_bin+" "+netview+" "+Dir+" "+Location[1]+Location[2])
     	Opts = null
     	Opts.Input.Database = Dir + "\\"+netview+".DBD"
     	Opts.Input.Network = Dir + "\\net_highway.net"
     	Opts.Input.[OD Matrix Currency] = {od_matrix, "SOV", "Rows", "Columns"}
     	Opts.Input.[Exclusion Link Sets] = 
{{Dir + "\\"+netview+".DBD|"+netview, netview, "sovexclude", "Select * where funcl = 22 or funcl = 23 or funcl = 24 or funcl = 25 or funcl = 82 or funcl = 83"}, , , {Dir + "\\"+netview+".DBD|"+netview, netview, "sovexclude"}, {Dir + "\\"+netview+".DBD|"+netview, netview, "sovexclude"}, {Dir + "\\"+netview+".DBD|"+netview, netview, "sovexclude"}}
     	Opts.Field.[Vehicle Classes] = {1, 2, 3, 4, 5, 6}
	Opts.Field.[Fixed Toll Fields] = {"[TollAB / TollBA]", "[TollAB / TollBA]", "[TollAB / TollBA]", "[TollAB / TollBA]", "[TollAB / TollBA]", "[TollAB / TollBA]"}
	Opts.Field.[PCE Fields] = {"None", "None", "None", "None", "None", "None"}
	Opts.Field.[VDF Fld Names] = {"[TTfreeAB / TTfreeBA]", cap_fields, "alpha", "beta", "None", "[TollAB / TollBA]", "None", "Length", "None"}
     	Opts.Global.[Number of Classes] = 6
	Opts.Global.[Load Method] = "UE"
	Opts.Global.[Loading Multiplier] = 1
	Opts.Global.Convergence = 0.01
	Opts.Global.[Time Minimum] = 0.01
     	Opts.Global.[Class PCEs] = {1, 1, 1, 1, 1.5, 2.5}
     	Opts.Global.[Class VOIs] = {1, 1, 1, 1, 1, 1}
     	Opts.Global.[Cost Function File] = "gc_mrm.vdf"
     	Opts.Global.[VDF Defaults] = {, , 0.15, 4, 0, distweight, timeweight,,0}
    	Opts.Global.Iterations = 50
	Opts.Global.[Critical Queries] = {"LinkAB(207161)&|LinkAB(207239) or LinkAB(220533) or LinkAB(210427) or LinkAB(207121) or LinkAB(205216) or LinkAB(205219) or LinkAB(224563) or LinkAB(224591)"}
    	Opts.Global.[Critical Set Names] = {"University"}
        Opts.Flag.[Do Critical] = 0
     	Opts.Flag.[Do Share Report] = 1   
     	Opts.Output.[Flow Table] = output_bin
 	Opts.Output.[Critical Matrix].Label = "Critical Matrix"
    	Opts.Output.[Critical Matrix].[File Name] = Dir + "\\MMA_AMPeakhot.mtx"
     	
	ret_value = RunMacro("TCB Run Procedure", "MMA", Opts, &Ret)
     	if !ret_value then goto badassign
goto quit


assnHOV2andHOV3:
    RunMacro("TCB Init")
//Network has both HOV2 and HOV3 lanes 
//exclude link sets for 6 vol classes
// 1 = sov - exclude from hov2+ and hov3+  (funcl 22,24,82 & 23,25,83=sovexclude)
// 2 = pool2 - exclude from hov3+ (funcl 23,25,83=pool2exclude)
// 3 = pool3 - no exclusion
// 4 = COM - exclude from all hov (sovexclude)
// 5 = MTK - exclude from all hov (sovexclude)
// 6 = HTK - exclude from all hov (sovexclude)

// Build Highway Network
     	Opts = null
     	Opts.Input.[Link Set] = {Dir + "\\"+netview+".DBD|"+netview, netview, "hwynet", "Select * where (funcl > 0 and funcl < 10) or funcl = 22 or funcl = 23 or funcl = 24 or funcl = 25 or funcl = 82 or funcl = 83 or funcl = 90"}
       Opts.Global.[Network Options].[Link Type] = {"funcl", netview+".funcl", netview+".funcl"}

     	Opts.Global.[Network Options].[Node ID] = "Node.ID"
     	Opts.Global.[Network Options].[Link ID] = netview+".ID"
     	Opts.Global.[Network Options].[Turn Penalties] = "Yes"
     	Opts.Global.[Network Options].[Keep Duplicate Links] = "FALSE"
     	Opts.Global.[Network Options].[Ignore Link Direction] = "FALSE"
	Opts.Global.[Network Options].[Time Unit] = "Minutes"
     	Opts.Global.[Link Options] = 
		{{"Length", {netview+".Length", netview+".Length", , , "False"}}, 
		 {"alpha", {netview+".alpha", netview+".alpha", , , "False"}},
		 {"beta", {netview+".beta", netview+".beta", , , "False"}}, 
		 {"[TTFreeAB / TTFreeBA]", {netview+".TTFreeAB", netview+".TTFreeBA", , , "True"}},
		 {"[CapPk3hrAB / CapPk3hrBA]", {netview+".CapPk3hrAB", netview+".CapPk3hrBA", , , "False"}},
		 {"[capMidAB / capMidBA]", {netview+".capMidAB", netview+".capMidBA", , , "False"}},
		 {"[capNightAB / capNightBA]", {netview+".capNightAB", netview+".capNightBA", , , "False"}},
		 {"[TollAB / TollBA]", {netview+".TollAB", netview+".TollBA", , , "False"}}}
	Opts.Global.[Length Unit] = "Miles"
	Opts.Global.[Time Unit] = "Minutes"
     	Opts.Output.[Network File] = Dir + "\\net_highway.net"

	ret_value = RunMacro("TCB Run Operation", "Build Highway Network", Opts, &Ret)
    	if !ret_value then goto badnetbuild

// Highway Network Setting

     	Opts = null
     	Opts.Input.Database = Dir + "\\"+netview+".DBD"
     	Opts.Input.Network = Dir + "\\net_highway.net"
     	Opts.Input.[Centroids Set] = {Dir + "\\"+netview+".DBD|Node", "Node", "centroid", "Select * where centroid = 1 or centroid = 2"}
	Opts.Input.[Spc Turn Pen Table]= {Location[1] + Location[2] + "trnpnlty.bin"}
      	Opts.Input.[Toll Set]= {Dir + "\\"+netview+".DBD|"+netview, netview, "tollset", "Select * where TollAB > 0 or TollBA > 0"}
     	Opts.Global.[Global Turn Penalties] = {0, 0, 0, -1}

	ret_value = RunMacro("TCB Run Operation", "Highway Network Setting", Opts, &Ret)
     	if !ret_value then goto notolls3

	goto skipnotolls3
	notolls3:

	Opts = null
     	Opts.Input.Database = Dir + "\\"+netview+".DBD"
     	Opts.Input.Network = Dir + "\\net_highway.net"
     	Opts.Input.[Centroids Set] = {Dir + "\\"+netview+".DBD|Node", "Node", "centroid", "Select * where centroid = 1 or centroid = 2"}
	Opts.Input.[Spc Turn Pen Table]= {Location[1] + Location[2] + "trnpnlty.bin"}
	Opts.Global.[Global Turn Penalties] = {0, 0, 0, -1}

	ret_value = RunMacro("TCB Run Operation", "Highway Network Setting", Opts, &Ret)
     	if !ret_value then goto badnetsettings
	
	skipnotolls3:

// MMA Assignment 
//exclude link sets for 6 vol classes
// 1 = sov - exclude from hov2+ and hov3+  (funcl 22,24,82 & 23,25,83=sovexclude)
// 2 = pool2 - exclude from hov3+ (funcl 23,25,83=pool2exclude)
// 3 = pool3 - no exclusion
// 4 = COM - exclude from all hov (sovexclude)
// 5 = MTK - exclude from all hov (sovexclude)
// 6 = HTK - exclude from all hov (sovexclude)

//showmessage(od_matrix+" "+cap_field+" "+output_bin+" "+netview+" "+Dir+" "+Location[1]+Location[2])
     	Opts = null
     	Opts.Input.Database = Dir + "\\"+netview+".DBD"
     	Opts.Input.Network = Dir + "\\net_highway.net"
     	Opts.Input.[OD Matrix Currency] = {od_matrix, "SOV", "Rows", "Columns"}
     	Opts.Input.[Exclusion Link Sets] = 
{{Dir + "\\"+netview+".DBD|"+netview, netview, "sovexclude", "Select * where funcl = 22 or funcl = 23 or funcl = 24 or funcl = 25 or funcl = 82 or funcl = 83"}, {Dir + "\\"+netview+".DBD|"+netview, netview, "pool2exclude", "Select * where funcl = 23 or funcl = 25 or funcl = 83"}, , {Dir + "\\"+netview+".DBD|"+netview, netview, "sovexclude"}, {Dir + "\\"+netview+".DBD|"+netview, netview, "sovexclude"}, {Dir + "\\"+netview+".DBD|"+netview, netview, "sovexclude"}}
     	Opts.Field.[Vehicle Classes] = {1, 2, 3, 4, 5, 6}
	Opts.Field.[Fixed Toll Fields] = {"[TollAB / TollBA]", "[TollAB / TollBA]", "[TollAB / TollBA]", "[TollAB / TollBA]", "[TollAB / TollBA]", "[TollAB / TollBA]"}
	Opts.Field.[PCE Fields] = {"None", "None", "None", "None", "None", "None"}
	Opts.Field.[VDF Fld Names] = {"[TTfreeAB / TTfreeBA]", cap_fields, "alpha", "beta", "None", "[TollAB / TollBA]", "None", "Length", "None"}
     	Opts.Global.[Number of Classes] = 6
	Opts.Global.[Load Method] = "UE"
	Opts.Global.[Loading Multiplier] = 1
	Opts.Global.Convergence = 0.01
	Opts.Global.[Time Minimum] = 0.01
     	Opts.Global.[Class PCEs] = {1, 1, 1, 1, 1.5, 2.5}
     	Opts.Global.[Class VOIs] = {1, 1, 1, 1, 1, 1}
     	Opts.Global.[Cost Function File] = "gc_mrm.vdf"
     	Opts.Global.[VDF Defaults] = {, , 0.15, 4, 0, distweight, timeweight,,0}
     	Opts.Global.Iterations = 50
	Opts.Global.[Critical Queries] = {"LinkAB(207161) or LinkAB(207239) or LinkAB(220533) or LinkAB(210427) or LinkAB(207121) or LinkAB(205216) or LinkAB(205219) or LinkAB(224563) or LinkAB(224591)"}
    	Opts.Global.[Critical Set Names] = {"University"}	
    	Opts.Global.[Critical Set Names] = {"University"}
        Opts.Flag.[Do Critical] = 0
     	Opts.Flag.[Do Share Report] = 1   
     	Opts.Output.[Flow Table] = output_bin
 	Opts.Output.[Critical Matrix].Label = "Critical Matrix"
    	Opts.Output.[Critical Matrix].[File Name] = Dir + "\\MMA_AMPeakhot.mtx"
	ret_value = RunMacro("TCB Run Procedure", "MMA", Opts, &Ret)
     	if !ret_value then goto badassign
goto quit

badnetbuild:
	btn = MessageBox("Highway Assignment - cannot build highway network, kill job?",
         {{"Caption", "ERROR"},
         {"Buttons", "YesNo"}})
	if btn = "Yes" then killjob = 1
        goto badquit

badnetsettings:
	btn = MessageBox("Highway Assignment - highway network settings error, kill job?",
         {{"Caption", "ERROR"},
         {"Buttons", "YesNo"}})
	if btn = "Yes" then killjob = 1
        goto badquit

badassign:
	btn = MessageBox("Highway Assignment - highway assignment error, kill job?",
         {{"Caption", "ERROR"},
         {"Buttons", "YesNo"}})
	if btn = "Yes" then killjob = 1
        goto badquit

badquit:
	RunMacro("TCB Closing", ret_value, "TRUE" )
quit:

endMacro
