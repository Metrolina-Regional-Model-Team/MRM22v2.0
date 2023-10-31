Macro "HwyAssn_RunHOTAMPeak" (Args)

/* 		SCENARIO PLANNING:

similar to HOT assign, this sets up assignment for CAV-only use on managed lanes

*/
	//**************************************************************************************************************

	//	Highway Assign specific arguments for HwyAssn_CAV macro
	dim hwyassnarguments[11]
	hwyassnarguments[1]  = "AM"
	hwyassnarguments[2]  = "CapPk3hr"
	hwyassnarguments[3]  = "\\TOD2\\ODHwyVeh_AMPeak.mtx"
	hwyassnarguments[4]  = "\\TOD2\\ODHwyVeh_AMPeakcav.mtx"
	hwyassnarguments[5]  = "\\TOD2\\ODHwyVeh_AMPEAKcavonly.mtx"
	hwyassnarguments[6]  = "\\TOD2"
	hwyassnarguments[7]  = "\\HwyAssn"
	hwyassnarguments[8]  = "\\HwyAssn\\CAV"
	hwyassnarguments[9]  = "\\HwyAssn\\Assn_AMPEAK.bin"
	hwyassnarguments[10] = "\\HwyAssn\\CAV\\Assn_AMPEAKcav.bin"
//	hwyassnarguments[11] = "HOT3"
	
	msg = null
	
	timeperiod = "AMpeak"

	CAVAssnOK = runmacro("HwyAssn_CAV", Args, hwyassnarguments, timeperiod)

	hwyassnarguments = null
	netview = null
	
	Return({CAVAssnOK, msg})

EndMacro
