Macro "HwyAssn_RunHOTAMPeak" (Args)

// 5/30/19, mk: There are now three distinct networks: AM peak, PM peak, and offpeak; pass correct netview through

	//  hwyassnarguments and old arguments array and new hwyassnarguments 
	//  hwyassnarguments	variable in hot_assn	old arguments	
	//		Args				Dir					arguments[1] = "Directory Location"
	//		Args				timeweight			arguments[2] = 2.0
	//		Args				distweight			arguments[3] = 0.1
	//		Args				netview				arguments[4] = 
	//	  not used				---					arguments[5] ="What Year?"
	//		[1]					PERIOD				arguments[6] = "AM"
	//		[3]					od_matrix			arguments[7] = arguments[1] + "\\tod2\\ODHwyVeh_AMPeak.mtx"
	//		[2]					cap_field	        arguments[8] = "CapPk3hr"
	//	    [10]    			output_bin			arguments[9] = arguments[1] + "\\hwyassn\\HOT\\Assn_AMPEAKhot.bin"
	//		[4]					od_hot_matrix		arguments[10] = arguments[1] + "\\tod2\\ODHwyVeh_AMPeakhot.mtx"
	//	    [9]    				input_bin			arguments[11] = arguments[1] + "\\hwyassn\\Assn_AMPEAK.bin"
	//		[5]					od_hotonly_matrix	arguments[12] = arguments[1] + "\\tod2\\ODHwyVeh_AMPEAKhotonly.mtx"
	//							output_dcb			arguments[13] = arguments[1] + "\\hwyassn\\HOT\\Assn_AMPEAKhot.dcb"
	//												arguments[14] = "Create HOT Directory & copy HOT assign dcb files"
	//	        									arguments[15] = "HOT Resource File Location"
	//												arguments[16] = "Assignment dcb file location"
	//		[8]					HOTin & assndir		arguments[17] = arguments[1] + "\\hwyassn\\HOT"
	//		[7]										arguments[18] = arguments[1] + "\\hwyassn"
	//		[6]					ODDir				arguments[19] = arguments[1] + "\\tod2"
	//      [11]										"HOT2", "HOT3", "TollOnly"
	//**************************************************************************************************************

	//	Highway Assign specific arguments for HwyAssn_HOT macro
	dim hwyassnarguments[11]
	hwyassnarguments[1]  = "AM"
	hwyassnarguments[2]  = "CapPk3hr"
	hwyassnarguments[3]  = "\\TOD2\\ODHwyVeh_AMPeak.mtx"
	hwyassnarguments[4]  = "\\TOD2\\ODHwyVeh_AMPeakhot.mtx"
	hwyassnarguments[5]  = "\\TOD2\\ODHwyVeh_AMPEAKhotonly.mtx"
	hwyassnarguments[6]  = "\\TOD2"
	hwyassnarguments[7]  = "\\HwyAssn"
	hwyassnarguments[8]  = "\\HwyAssn\\HOT"
	hwyassnarguments[9]  = "\\HwyAssn\\Assn_AMPEAK.bin"
	hwyassnarguments[10] = "\\HwyAssn\\HOT\\Assn_AMPEAKhot.bin"
	hwyassnarguments[11] = "HOT3"
	
	msg = null
	
	timeperiod = "AMpeak"

	HOTAssnOK = runmacro("HwyAssn_HOT", Args, hwyassnarguments, timeperiod)

	hwyassnarguments = null
	netview = null
	
//		DeleteFile("HOT_Table.dbf")

	Return({HOTAssnOK, msg})

EndMacro
