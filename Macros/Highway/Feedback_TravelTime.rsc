Macro "Feedback_TravelTime" (Args)

//06-03-01 Changed method of recalculating HOV transit speeds - cannot go faster than initially input
//06-12-07 Broke apart first step (ttpkprev*, ttpkassn*, imppk*) into three separate steps (illegal op problem)
//07-07-19 Added funcl 24 and 25
//Changed minspfac to maxTTfac 
//Updated for new UI, McLelland, Nov 2015
// 5/30/19, mk: There are now three distinct networks, use AM Peak

	LogFile = Args.[Log File].value
	SetLogFileName(LogFile)
	ReportFile = Args.[Report File].value
	SetReportFileName(ReportFile)

	Dir = Args.[Run Directory].value
	netview = Args.[AM Peak Hwy Name].value
	timeweight = Args.[TimeWeight].value
	distweight = Args.[DistWeight].value
	maxTTfac = Args.[MaxTravTimeFactor].value

	curiter = Args.[Current Feedback Iter].value
	FeedbackTTOK = 1
	msg = null

	datentime = GetDateandTime()
	AppendToLogFile(1, "Enter Feedback_TravelTime: " + datentime)
	AppendToLogFile(2, "AM Peak feedback iteration: " + i2s(curiter))
	AppendToLogFile(2, "Weight on travel time (minutes) = " + r2s(timeweight))
	AppendToLogFile(2, "Weight on distance (miles) = " + r2s(distweight))
	AppendToLogFile(2, "Maximum travel time factor (* Free speed travel time) = " + r2s(maxTTfac))

	
	fb_tt_file = Dir + "\\HwyAssn\\Assn_AMPeak_pass" + i2s(curiter) + ".bin"
 
   RunMacro("TCB Init")

//Recalculate speeds based on am peak assignment - 

//*************************************************************************************
//Roll TTPkAssn* to TTPkPrev* (AB & BA)
//*************************************************************************************

	Opts = null
     	Opts.Input.[Dataview Set] = {Dir + "\\"+netview+".dbd|"+netview, netview}
     	Opts.Global.Fields = {"TTPkPrevAB","TTPkPrevBA"}
     	Opts.Global.Method = "Formula"
     	Opts.Global.Parameter = {"TTPkAssnAB", "TTPkAssnBA"}
     	ret_value = RunMacro("TCB Run Operation", 1, "Fill Dataview", Opts)
     	if !ret_value then goto badpeakprev

//*************************************************************************************
//New assignment speed is weighted average (50%-50%) of Previous TT and last assigned  
//Minimum assignment speed is currently 10% of free speed (maxTTfac) - all handled in travel time
//*************************************************************************************

     	Opts = null
     	Opts.Input.[Dataview Set] = {{Dir + "\\"+netview+".dbd|"+netview, fb_tt_file, "ID", "ID1"}, netview+"+Assn_AMPeak"}
     	Opts.Global.Fields = {"TTPkAssnAB","TTPkAssnBA"}
     	Opts.Global.Method = "Formula"
     	Opts.Global.Parameter = {"(TTPkPrevAB + min(nz(AB_time), nz(TTfreeAB * "+r2s(maxTTfac)+"))) / 2.0", "(TTPkPrevBA + min(nz(BA_time), nz(TTfreeBA * "+r2s(maxTTfac)+"))) / 2.0"}
     	ret_value = RunMacro("TCB Run Operation", 2, "Fill Dataview", Opts)
     	if !ret_value then goto badpeakassn

//*************************************************************************************
//Calc new peak impedance - time and distance weights are parameters
//   time * timeweight + length * distweight
//*************************************************************************************

//	showmessage(" Time:"+string(timeweight)+" Dist:"+string(distweight))
	Opts = null
     	Opts.Input.[Dataview Set] = {Dir + "\\"+netview+".dbd|"+netview, netview}
     	Opts.Global.Fields = {"ImpPkAB","ImpPkBA"}
     	Opts.Global.Method = "Formula"
     	Opts.Global.Parameter = {"nz(TTPkAssnAB)* " + r2s(timeweight) +" + nz(length)* " + r2s(distweight), "nz(TTPkAssnBA)* " + r2s(timeweight) +" + nz(length)*" + r2s(distweight)}
     	ret_value = RunMacro("TCB Run Operation", 3, "Fill Dataview", Opts)
     	if !ret_value then goto badimpedance


//****************************************************************************************
//Recalculate peak transit travel times - lookup value (from capspd) with max of 90% of 
//loaded speed (assigned)
//**************************************************************************************    	Opts = null
     	Opts.Input.[Dataview Set] = {Dir + "\\"+netview+".dbd|"+netview, netview, "Selection", "Select * where (funcl > 0 and funcl < 10)"}
     	Opts.Global.Fields = {"TTPkLocAB", "TTPkLocBA", "TTPkXprAB", "TTPkXprBA"}
     	Opts.Global.Method = "Formula"
     	Opts.Global.Parameter = {"max(PkLocLUAB,TTPkAssnAB / 0.9)", "max(PkLocLUBA,TTPkAssnBA / 0.9)", "max(PkXprLUAB,TTPkAssnAB / 0.9)", "max(PkXprLUBA,TTPkAssnBA / 0.9)"}

     	ret_value = RunMacro("TCB Run Operation", 4, "Fill Dataview", Opts)

     	if !ret_value then goto badtranreg

//*********************************************************************************************************************
//Adjust peak Speed (MPH) to reflect assigned travel time AB 
//*********************************************************************************************************************
     	Opts = null
     	Opts.Input.[Dataview Set] = {Dir + "\\"+netview+".dbd|"+netview, netview, "Selection", "Select * where dir <> -1 and (funcl > 0 and funcl < 10)"}
     	Opts.Global.Fields = {"TTPeakAB", "SPpeakAB"}
     	Opts.Global.Method = "Formula"
     	Opts.Global.Parameter = {"TTPkAssnAB", "Length / (TTPkAssnAB / 60.)"} 

     	ret_value = RunMacro("TCB Run Operation", 5, "Fill Dataview", Opts)

     	if !ret_value then goto badspeedab


//*********************************************************************************************************************
//Adjust peak Speed (MPH) to reflect assigned travel time BA
//*********************************************************************************************************************
     	Opts = null
     	Opts.Input.[Dataview Set] = {Dir + "\\"+netview+".dbd|"+netview, netview, "Selection", "Select * where dir <> 1 and (funcl > 0 and funcl < 10)"}
     	Opts.Global.Fields = {"TTPeakBA", "SPpeakBA"}
     	Opts.Global.Method = "Formula"
     	Opts.Global.Parameter = {"TTPkAssnBA", "Length / (TTPkAssnBA / 60.)"} 

     	ret_value = RunMacro("TCB Run Operation", 6, "Fill Dataview", Opts)

     	if !ret_value then goto badspeedba
//******************************************************************************************************************
//Recalculate peak transit speeds on guideways - increase travel time if background speed decreases 
//******************************************************************************************************************

//      check highway network if hov lanes exist
//      hov2+ are funcl 22 and 82  
//      hov3+ are funcl 23 and 83
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
	selhov = "Select * where funcl = 22 or funcl = 23 or funcl = 24 or funcl = 25 or funcl = 82 or funcl = 83"
	Selectbyquery("check_hov", "Several", selhov,)
	hovcount = getsetcount("check_hov")
//        showmessage("pool2 " + string(pool2count)+"    pool3 "+string(pool3count))
	closemap()


	if hovcount = 0 then do
		goto skipHOVfeedback
		end
	else do
		goto HOVfeedback
		end


hovfeedback:

		// HOV lane feedback - Loc and Xpr travel - same change of speeds as background traffic (TT)
     	Opts = null
     	Opts.Input.[Dataview Set] = {Dir + "\\"+netview+".dbd|"+netview, netview, "Selection", "Select * where funcl = 22 or funcl = 23 or funcl =24 or funcl = 25 or funcl = 82 or funcl = 83"}
     	Opts.Global.Fields = {"TTPkLocAB", "TTPkLocBA", "TTPkXprAB", "TTPkXprBA"}
     	Opts.Global.Method = "Formula"
     	Opts.Global.Parameter = 
		{"if (TTPkAssnAB > TTPkPrevAB) then TTPkLocAB + (TTPkAssnAB - TTPkPrevAB) else TTPkLocAB", 
 		 "if (TTPkAssnBA > TTPkPrevBA) then TTPkLocBA + (TTPkAssnBA - TTPkPrevBA) else TTPkLocBA",  
  		 "if (TTPkAssnAB > TTPkPrevAB) then TTPkXprAB + (TTPkAssnAB - TTPkPrevAB) else TTPkXprAB", 
 		 "if (TTPkAssnBA > TTPkPrevBA) then TTPkXprBA + (TTPkAssnBA - TTPkPrevBA) else TTPkXprBA"}

     	ret_value = RunMacro("TCB Run Operation", 7, "Fill Dataview", Opts)

     	if !ret_value then goto badtrangdwy

//*************************************************************************************************
//Non-stop speed - same as assigned speed, Skip stop speeds - average of local and express 
//******************************	**********************************************************************

skipHOVfeedback:

     	Opts = null
     	Opts.Input.[Dataview Set] = {Dir + "\\"+netview+".dbd|"+netview, netview, "Selection", "Select * where (funcl > 0 and funcl < 10) or funcl = 22 or funcl = 23 or funcl = 24 or funcl = 25 or funcl = 82 or funcl = 83"}
     	Opts.Global.Fields = {"TTPkNStAB", "TTPkNStBA", "TTPkSkSAB", "TTPkSkSBA"}
     	Opts.Global.Method = "Formula"
     	Opts.Global.Parameter = {"TTPkAssnAB", "TTPkAssnBA","(TTPkLocAB + TTPkXprAB) / 2.0", "(TTPkLocBA + TTPkXprBA) / 2.0"}

     	ret_value = RunMacro("TCB Run Operation", 8, "Fill Dataview", Opts)

     	if !ret_value then goto badtrannonskp

goto quit

badpeakprev:
	msg = msg + {"Feedback Travel time - error filling prev peak travel times"}
	AppendToLogFile(2, "Feedback Travel time - error filling prev peak travel times")
	goto badquit

badpeakassn:
	msg = msg + {"Feedback Travel time - error calculating peak assignment travel times"}
	AppendToLogFile(2, "Feedback Travel time - error calculating peak assignment travel times")
	goto badquit

badimpedance:
	msg = msg + {"Feedback Travel time - error calculating highway impedance"}
	AppendToLogFile(2, "Feedback Travel time - error calculating highway impedance")
	goto badquit

badspeedab:
	msg = msg + {"Feedback Travel time - error re-calculating AB peak speed (MPH)"}
	AppendToLogFile(2, "Feedback Travel time - error re-calculating AB peak speed (MPH)")
	goto badquit

badspeedba:
	msg = msg + {"Feedback Travel time - error re-calculating BA peak speed (MPH)"}
	AppendToLogFile(2, "Feedback Travel time - error re-calculating BA peak speed (MPH)")
	goto badquit

badtranreg:
	msg = msg + {"Feedback Travel time - error re-calculating transit travel times on street network"}
	AppendToLogFile(2, "Feedback Travel time - error re-calculating transit travel times on street network")
	goto badquit

badtrangdwy:
	msg = msg + {"Feedback Travel time - error re-calculating transit travel times on guideways"}
	AppendToLogFile(2, "Feedback Travel time - error re-calculating transit travel times on guideways")
	goto badquit

badtrannonskp:
	msg = msg + {"Feedback Travel time - error re-calculating non-stop and skip-stop transit travel times"}
	AppendToLogFile(2, "Feedback Travel time - error re-calculating non-stop and skip-stop transit travel times")
	goto badquit

badquit:
	RunMacro("TCB Closing", ret_value, "TRUE" )
	FeedbackTTOK = 0	

quit:

//  process iterations  
	curiter = curiter + 1
	Args.[Current Feedback Iter].value = curiter

	datentime = GetDateandTime()
	AppendToLogFile(1, "Exit Feedback_TravelTime: " + datentime)

	return({FeedbackTTOK, msg})
endMacro
