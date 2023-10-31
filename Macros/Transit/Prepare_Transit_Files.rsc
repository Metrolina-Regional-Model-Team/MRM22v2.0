macro "Prepare_Transit_Files" (Args)

	// Added NumProcessors check to run 1 or 4+ processors
	// McLelland, Oct, 2011

	// Modified NumProcessors check to run 1 or 8+ processors ; removed choice set and CR path trips configuration for mode choice output and assignment files
	// Modified batch and control file creation process to reflect new ModeChoice program - used Substitute function to simplify creation of batch and control files from the templates
	// Kept the process to create separate skims for rail only and rail+bus
	// Juvva, August, 2015

//Modified for new UI - McLelland - 10/15
//Renamed - Prepare_Transit_Files.rsc
	
	
	RunYear = Args.[Run Year].value
	METDir = Args.[MET Directory].value
	Dir = Args.[Run Directory].value
	msg = null

	LogFile = Args.[Log File].value
	ReportFile = Args.[Report File].value
	SetLogFileName(LogFile)
	SetReportFileName(ReportFile)

	datentime = GetDateandTime()
	AppendToLogFile(1, "Enter Prepare Transit Files " + datentime)

	alt_dir = Dir
	alt_name = RunYear
	ms_dir = METDir + "\\MS_Control_Template"

	
	ok1 = RunMacro ("Mode Split Controls", ms_dir, alt_dir, alt_name, METDir)
	ok2 = RunMacro ("ModeChoice Files", ms_dir, alt_dir, alt_name)
	ok3 = RunMacro ("Create Mode Split Output Matrices", alt_dir, alt_name, METDir)
	ok4 = RunMacro ("Create Transit Skims Output Matrices", alt_dir, alt_name, METDir)
	ok5 = RunMacro ("Create Transit Assignment Matrices", alt_dir, alt_name, METDir)
	
	// copy modes.dbf and modexref.dbf from ms_control_template  (v7 have updated transit fares 4/25/17)
	filename_in  = ms_dir  + "\\modes.dbf"
	filename_out = alt_dir + "\\modes.dbf"
	CopyFile(filename_in, filename_out)

	filename_in  = ms_dir  + "\\modexfer.dbf"
	filename_out = alt_dir + "\\modexfer.dbf"
	CopyFile(filename_in, filename_out)


	if ok1[1] = 0 
		then do
			msg = msg + {"Prepare Transit Files - error return from Mode Split Controls"}
			msg = msg + ok1[2]
			goto badquit
		end	
	if ok2[1] = 0 
		then do
			msg = msg + {"Prepare Transit Files - error return from ModeChoice Files"}
			msg = msg + ok1[2]
			goto badquit
		end	
	if ok3[1] = 0 
		then do
			msg = msg + {"Prepare Transit Files - error return from Mode Split Controls"}
			msg = msg + ok3[2]
			goto badquit
		end	
	if ok4[1] = 0 
		then do
			msg = msg + {"Prepare Transit Files - error return from Transit Skims Output Matrices"}
			msg = msg + ok4[2]
			goto badquit
		end	
	if ok5[1] = 0 
		then do
			msg = msg + {"Prepare Transit Files - error return from Create Mode Split Output Matrices"}
			msg = msg + ok5[2]
			goto badquit
		end	
	
	datentime = GetDateandTime()
	AppendToLogFile(1, "Exit Prepare Transit Files: " + datentime)

	return({1,msg})
	
	badquit:
	RunMacro("G30 File Close All")
	return({0, msg})
	

endmacro


//---------------------------------------------------------------------
// Macro "Mode Split Controls" 
//---------------------------------------------------------------------

Macro "Mode Split Controls" (template_dir, alt_dir, alt_name, METDir)

	msg = null
	on error, notfound goto badquit

	// -- create Control for HBW_PEAK

	filename_in = template_dir + "\\ALTNAME_HBW_PEAK"+".ctl"
	filename_out =  alt_dir + "\\ModeSplit\\INPUTS\\Controls\\" + alt_name + "_HBW_PEAK"+".ctl"
	ok = RunMacro("Create Mode Split Control Files", filename_in, filename_out, alt_dir, alt_name, "HBW", "PEAK")
	if ok[1] = 0 
		then do
			msg = ok[2]
			msg = msg + {"Error in HBW Peak MS Control"} 
			goto badquit
		end	

	// -- create Control for HBW_OFFPEAK

	filename_in = template_dir + "\\ALTNAME_HBW_OFFPEAK"+".ctl"
	filename_out =  alt_dir + "\\ModeSplit\\INPUTS\\Controls\\" + alt_name + "_HBW_OFFPEAK"+".ctl"
	ok = RunMacro("Create Mode Split Control Files", filename_in, filename_out, alt_dir, alt_name, "HBW", "OFFPEAK")
	if ok[1] = 0 
		then do
			msg = ok[2]
			msg = msg + {"Error in HBW OffPeak MS Control"} 
			goto badquit
		end	

	// -- create Control for HBO_PEAK

	filename_in = template_dir + "\\ALTNAME_HBO_PEAK"+".ctl"
	filename_out =  alt_dir + "\\ModeSplit\\INPUTS\\Controls\\" + alt_name + "_HBO_PEAK"+".ctl"
	ok = RunMacro("Create Mode Split Control Files", filename_in, filename_out, alt_dir, alt_name, "HBO", "PEAK")
	if ok[1] = 0 
		then do
			msg = ok[2]
			msg = msg + {"Error in HBO Peak MS Control"} 
			goto badquit
		end	

	// -- create Control for HBO_OFFPEAK

	filename_in = template_dir + "\\ALTNAME_HBO_OFFPEAK"+".ctl"
	filename_out =  alt_dir + "\\ModeSplit\\INPUTS\\Controls\\" + alt_name + "_HBO_OFFPEAK"+".ctl"
	ok = RunMacro("Create Mode Split Control Files", filename_in, filename_out, alt_dir, alt_name, "HBO", "OFFPEAK")
	if ok[1] = 0 
		then do
			msg = ok[2]
			msg = msg + {"Error in HBO OffPeak MS Control"} 
			goto badquit
		end	
	
	// -- create Control for NHB_PEAK

	filename_in = template_dir + "\\ALTNAME_NHB_PEAK"+".ctl"
	filename_out =  alt_dir + "\\ModeSplit\\INPUTS\\Controls\\" + alt_name + "_NHB_PEAK"+".ctl"
	ok = RunMacro("Create Mode Split Control Files", filename_in, filename_out, alt_dir, alt_name, "NHB", "PEAK")
	if ok[1] = 0 
		then do
			msg = ok[2]
			msg = msg + {"Error in NHB Peak MS Control"} 
			goto badquit
		end	

	// -- create Control for NHB_OFFPEAK

	filename_in = template_dir + "\\ALTNAME_NHB_OFFPEAK"+".ctl"
	filename_out =  alt_dir + "\\ModeSplit\\INPUTS\\Controls\\" + alt_name + "_NHB_OFFPEAK"+".ctl"
	ok = RunMacro("Create Mode Split Control Files", filename_in, filename_out, alt_dir, alt_name, "NHB", "OFFPEAK")
	if ok[1] = 0 
		then do
			msg = ok[2]
			msg = msg + {"Error in NHB OffPeak MS Control"} 
			goto badquit
		end	

	// -- create Control for HBU_PEAK

	filename_in = template_dir + "\\ALTNAME_HBU_PEAK"+".ctl"
	filename_out =  alt_dir + "\\ModeSplit\\INPUTS\\Controls\\" + alt_name + "_HBU_PEAK"+".ctl"
	ok = RunMacro("Create Mode Split Control Files", filename_in, filename_out, alt_dir, alt_name, "HBU", "PEAK")
	if ok[1] = 0 
		then do
			msg = ok[2]
			msg = msg + {"Error in HBU Peak MS Control"} 
			goto badquit
		end	

	// -- create Control for HBU_OFFPEAK

	filename_in = template_dir + "\\ALTNAME_HBU_OFFPEAK"+".ctl"
	filename_out =  alt_dir + "\\ModeSplit\\INPUTS\\Controls\\" + alt_name + "_HBU_OFFPEAK"+".ctl"
	ok = RunMacro("Create Mode Split Control Files", filename_in, filename_out, alt_dir, alt_name, "HBU", "OFFPEAK")
	if ok[1] = 0 
		then do
			msg = ok[2]
			msg = msg + {"Error in HBU OffPeak MS Control"} 
			goto badquit
		end	

	// -- Create ModeSplit Batch Files for HBW_PEAK Model

	filename_in = template_dir + "\\ALTNAME_HBW_PEAK"+".BAT"
	filename_out = alt_dir + "\\ModeSplit\\" + alt_name + "_HBW_PEAK"+".BAT"
	ok = RunMacro("Create Mode Split Batch Files", filename_in, filename_out, alt_dir, alt_name, "HBW", "PEAK", METDir)
	if ok[1] = 0 
		then do
			msg = ok[2]
			msg = msg + {"Error in HBW Peak MS Batch"} 
			goto badquit
		end	

	// -- Create ModeSplit Batch Files for HBW_OFFPEAK Model

	filename_in = template_dir + "\\ALTNAME_HBW_OFFPEAK"+".BAT"
	filename_out = alt_dir + "\\ModeSplit\\" + alt_name + "_HBW_OFFPEAK"+".BAT"
	ok = RunMacro("Create Mode Split Batch Files", filename_in, filename_out, alt_dir, alt_name, "HBW", "OFFPEAK", METDir)
	if ok[1] = 0 
		then do
			msg = ok[2]
			msg = msg + {"Error in HBW OffPeak MS Batch"} 
			goto badquit
		end	

	// -- Create ModeSplit Batch Files for HBO_PEAK Model

	filename_in = template_dir + "\\ALTNAME_HBO_PEAK"+".BAT"
	filename_out = alt_dir + "\\ModeSplit\\" + alt_name + "_HBO_PEAK"+".BAT"
	ok = RunMacro("Create Mode Split Batch Files", filename_in, filename_out, alt_dir, alt_name, "HBO", "PEAK", METDir)
	if ok[1] = 0 
		then do
			msg = ok[2]
			msg = msg + {"Error in HBO Peak MS Batch"} 
			goto badquit
		end	

	// -- Create ModeSplit Batch Files for HBO_OFFPEAK Model

	filename_in = template_dir + "\\ALTNAME_HBO_OFFPEAK"+".BAT"
	filename_out = alt_dir + "\\ModeSplit\\" + alt_name + "_HBO_OFFPEAK"+".BAT"
	ok = RunMacro("Create Mode Split Batch Files", filename_in, filename_out, alt_dir, alt_name, "HBO", "OFFPEAK", METDir)
	if ok[1] = 0 
		then do
			msg = ok[2]
			msg = msg + {"Error in HBO OffPeak MS Batch"} 
			goto badquit
		end	

	// -- Create ModeSplit Batch Files for NHB_PEAK Model

	filename_in = template_dir + "\\ALTNAME_NHB_PEAK"+".BAT"
	filename_out = alt_dir + "\\ModeSplit\\" + alt_name + "_NHB_PEAK"+".BAT"
	ok = RunMacro("Create Mode Split Batch Files", filename_in, filename_out, alt_dir, alt_name, "NHB", "PEAK", METDir)
	if ok[1] = 0 
		then do
			msg = ok[2]
			msg = msg + {"Error in NHB Peak MS Batch"} 
			goto badquit
		end	

	// -- Create ModeSplit Batch Files for NHB_OFFPEAK Model

	filename_in = template_dir + "\\ALTNAME_NHB_OFFPEAK"+".BAT"
	filename_out = alt_dir + "\\ModeSplit\\" + alt_name + "_NHB_OFFPEAK"+".BAT"
	ok = RunMacro("Create Mode Split Batch Files", filename_in, filename_out, alt_dir, alt_name, "NHB", "OFFPEAK", METDir)
	if ok[1] = 0 
		then do
			msg = ok[2]
			msg = msg + {"Error in NHB OffPeak MS Batch"} 
			goto badquit
		end	

	// -- Create ModeSplit Batch Files for HBU_PEAK Model

	filename_in = template_dir + "\\ALTNAME_HBU_PEAK"+".BAT"
	filename_out = alt_dir + "\\ModeSplit\\" + alt_name + "_HBU_PEAK"+".BAT"
	ok = RunMacro("Create Mode Split Batch Files", filename_in, filename_out, alt_dir, alt_name, "HBU", "PEAK", METDir)
	if ok[1] = 0 
		then do
			msg = ok[2]
			msg = msg + {"Error in HBU Peak MS Batch"} 
			goto badquit
		end	

	// -- Create ModeSplit Batch Files for HBU_OFFPEAK Model

	filename_in = template_dir + "\\ALTNAME_HBU_OFFPEAK"+".BAT"
	filename_out = alt_dir + "\\ModeSplit\\" + alt_name + "_HBU_OFFPEAK"+".BAT"
	ok = RunMacro("Create Mode Split Batch Files", filename_in, filename_out, alt_dir, alt_name, "HBU", "OFFPEAK", METDir)
	if ok[1] = 0 
		then do
			msg = ok[2]
			msg = msg + {"Error in HBU OffPeak MS Batch"} 
			goto badquit
		end	


	// -- Create ModeSplit Batch Files to run ALL ModeSplit Model

	// -- Create ModeSplit Batch Files to run ALL ModeSplit Model
	// Add options for number of processors (1, or 4+)  - Create separate runall and runpeak depending on processors
	//   cannot run more than 4 because MS 5-8 use same input files as MS 1-4)
	// McLelland Oct, 2011 
	// Modified options for number of processors (1, or 8+)  - Create separate runall and runpeak depending on processors
	//   8 processors run all 8 models - 4 purposes and 2 time periods. 
	//	At a later stage, can modify script to split HBW and HBO by income and run all 20 models simultaneously if computers running the model have 20+ processors
	// Juvva Aug, 2015 	
	
	// For new interface - created peak and offpeak sets separately running 4 mode choice sets simultaneously instead of 8 (they run at different
	// times in the process - only need four processors for that.  Current conformity run version doesn't use the runall - but I am leaving it,
	// the AECOM model probably uses it.  McLelland - Nov, 2015
	
	SysInfo = GetSystemInfo()
	NumProcessors = SysInfo[2][2]

	if NumProcessors >= 8 then do

		filename_out =  alt_dir + "\\ModeSplit\\"+alt_name + "_RUNALL.BAT"
		exist = GetFileInfo(filename_out)
		if exist then deletefile(filename_out)

      	outctl=Openfile(filename_out,"w")

		writeline(outctl,Left(alt_dir,2))
		writeline(outctl,"CD "+alt_dir+"\\MODESPLIT")
		writeline(outctl,"")
		writeline(outctl,"time /t>start.prn")
		writeline(outctl,"")
		writeline(outctl,"ping -n 6 127.0.0.1>nul")
		writeline(outctl,"for %%A in ("+alt_name+"_HBW_PEAK.BAT) do start %%A")
		writeline(outctl,"ping -n 6 127.0.0.1>nul")
		writeline(outctl,"")
		writeline(outctl,"for %%B in ("+alt_name+"_HBW_OFFPEAK.BAT) do start %%B")
		writeline(outctl,"ping -n 6 127.0.0.1>nul")
		writeline(outctl,"")
		writeline(outctl,"for %%C in ("+alt_name+"_HBO_PEAK.BAT) do start %%C")
		writeline(outctl,"ping -n 6 127.0.0.1>nul")
		writeline(outctl,"")
		writeline(outctl,"for %%D in ("+alt_name+"_HBO_OFFPEAK.BAT) do start %%D")
		writeline(outctl,"ping -n 6 127.0.0.1>nul")
		writeline(outctl,"")
		writeline(outctl,"for %%E in ("+alt_name+"_NHB_PEAK.BAT) do start %%E")
		writeline(outctl,"ping -n 6 127.0.0.1>nul")
		writeline(outctl,"")
		writeline(outctl,"for %%F in ("+alt_name+"_NHB_OFFPEAK.BAT) do start %%F")
		writeline(outctl,"ping -n 6 127.0.0.1>nul")
		writeline(outctl,"")
		writeline(outctl,"for %%G in ("+alt_name+"_HBU_PEAK.BAT) do start %%G")
		writeline(outctl,"ping -n 6 127.0.0.1>nul")
		writeline(outctl,"")
		writeline(outctl,"call " +alt_dir+"\\MODESPLIT\\"+alt_name+"_HBU_OFFPEAK")
		writeline(outctl,"")
		writeline(outctl,":chk1")
		writeline(outctl,"echo Waiting...")
		writeline(outctl,"ping -n 11 127.0.0.1>nul")
		writeline(outctl,"if exist HBW_PEAK.MC if exist HBW_OFFPEAK.MC if exist HBO_PEAK.MC if exist HBO_OFFPEAK.MC if exist HBU_PEAK.MC if exist HBU_OFFPEAK.MC if exist NHB_PEAK.MC if exist NHB_OFFPEAK.MC goto done1")
		writeline(outctl,"goto chk1")
		writeline(outctl,":done1")
		writeline(outctl,"del HBW_PEAK.MC")
		writeline(outctl,"del HBW_OFFPEAK.MC")
		writeline(outctl,"del HBO_PEAK.MC")
		writeline(outctl,"del HBO_OFFPEAK.MC")
		writeline(outctl,"del HBU_PEAK.MC")
		writeline(outctl,"del HBU_OFFPEAK.MC")
		writeline(outctl,"del NHB_PEAK.MC")
		writeline(outctl,"del NHB_OFFPEAK.MC")
		writeline(outctl,"")
		writeline(outctl,"time /t>end.prn")

		CloseFile(outctl)
	end  // 8 processors
	
		// -- Create ModeSplit Batch Files to run Peak ModeSplit Model for feedback iterations
		//            and to create offepeak modesplit model 
	if NumProcessors >= 4 then do

		filename_out =  alt_dir + "\\ModeSplit\\"+alt_name + "_RUNPEAK.BAT"
		exist = GetFileInfo(filename_out)
		if exist then deletefile(filename_out)

		outctl=Openfile(filename_out,"w")

		writeline(outctl,Left(alt_dir,2))
		writeline(outctl,"CD "+alt_dir+"\\MODESPLIT")
		writeline(outctl,"")
		writeline(outctl,"time /t>start.prn")
		writeline(outctl,"")
		writeline(outctl,"ping -n 6 127.0.0.1>nul")
		writeline(outctl,"for %%A in ("+alt_name+"_HBW_PEAK.BAT) do start %%A")
		writeline(outctl,"ping -n 6 127.0.0.1>nul")
		writeline(outctl,"")
		writeline(outctl,"for %%B in ("+alt_name+"_HBO_PEAK.BAT) do start %%B")
		writeline(outctl,"ping -n 6 127.0.0.1>nul")
		writeline(outctl,"")
		writeline(outctl,"for %%C in ("+alt_name+"_NHB_PEAK.BAT) do start %%C")
		writeline(outctl,"ping -n 6 127.0.0.1>nul")
		writeline(outctl,"")
		writeline(outctl,"for %%D in ("+alt_name+"_HBU_PEAK.BAT) do start %%D")
		writeline(outctl,"ping -n 6 127.0.0.1>nul")
		writeline(outctl,"")
		writeline(outctl,":chk1")
		writeline(outctl,"echo Waiting...")
		writeline(outctl,"ping -n 11 127.0.0.1>nul")
		writeline(outctl,"if exist HBW_PEAK.MC if exist HBO_PEAK.MC if exist HBU_PEAK.MC if exist NHB_PEAK.MC goto done1")
		writeline(outctl,"goto chk1")
		writeline(outctl,":done1")
		writeline(outctl,"del HBW_PEAK.MC")
		writeline(outctl,"del HBO_PEAK.MC")
		writeline(outctl,"del HBU_PEAK.MC")
		writeline(outctl,"del NHB_PEAK.MC")
		writeline(outctl,"")
		writeline(outctl,"time /t>end.prn")

		CloseFile(outctl)

		// offpeak controls
		
		filename_out =  alt_dir + "\\ModeSplit\\"+alt_name + "_RUNOFFPEAK.BAT"
		exist = GetFileInfo(filename_out)
		if exist then deletefile(filename_out)

		outctl=Openfile(filename_out,"w")

		writeline(outctl,Left(alt_dir,2))
		writeline(outctl,"CD "+alt_dir+"\\MODESPLIT")
		writeline(outctl,"")
		writeline(outctl,"time /t>start.prn")
		writeline(outctl,"")
		writeline(outctl,"ping -n 6 127.0.0.1>nul")
		writeline(outctl,"for %%A in ("+alt_name+"_HBW_OFFPEAK.BAT) do start %%A")
		writeline(outctl,"ping -n 6 127.0.0.1>nul")
		writeline(outctl,"")
		writeline(outctl,"for %%B in ("+alt_name+"_HBO_OFFPEAK.BAT) do start %%B")
		writeline(outctl,"ping -n 6 127.0.0.1>nul")
		writeline(outctl,"")
		writeline(outctl,"for %%C in ("+alt_name+"_NHB_OFFPEAK.BAT) do start %%C")
		writeline(outctl,"ping -n 6 127.0.0.1>nul")
		writeline(outctl,"")
		writeline(outctl,"for %%D in ("+alt_name+"_HBU_OFFPEAK.BAT) do start %%D")
		writeline(outctl,"ping -n 6 127.0.0.1>nul")
		writeline(outctl,"")
		writeline(outctl,":chk1")
		writeline(outctl,"echo Waiting...")
		writeline(outctl,"ping -n 11 127.0.0.1>nul")
		writeline(outctl,"if exist HBW_OFFPEAK.MC if exist HBO_OFFPEAK.MC if exist HBU_OFFPEAK.MC if exist NHB_OFFPEAK.MC goto done1")
		writeline(outctl,"goto chk1")
		writeline(outctl,":done1")
		writeline(outctl,"del HBW_OFFPEAK.MC")
		writeline(outctl,"del HBO_OFFPEAK.MC")
		writeline(outctl,"del HBU_OFFPEAK.MC")
		writeline(outctl,"del NHB_OFFPEAK.MC")
		writeline(outctl,"")
		writeline(outctl,"time /t>end.prn")

		CloseFile(outctl)

	end // 8+ processors

	// 1 processor 
	else do

		filename_out =  alt_dir + "\\ModeSplit\\"+alt_name + "_RUNALL.BAT"
		exist = GetFileInfo(filename_out)
		if exist then deletefile(filename_out)

  		outctl=Openfile(filename_out,"w")

		writeline(outctl,"call " +alt_dir+"\\MODESPLIT\\"+alt_name+"_HBW_PEAK")
		writeline(outctl,"call " +alt_dir+"\\MODESPLIT\\"+alt_name+"_HBW_OFFPEAK")
		writeline(outctl,"call " +alt_dir+"\\MODESPLIT\\"+alt_name+"_HBO_PEAK")
		writeline(outctl,"call " +alt_dir+"\\MODESPLIT\\"+alt_name+"_HBO_OFFPEAK")
		writeline(outctl,"call " +alt_dir+"\\MODESPLIT\\"+alt_name+"_NHB_PEAK")
		writeline(outctl,"call " +alt_dir+"\\MODESPLIT\\"+alt_name+"_NHB_OFFPEAK")
		writeline(outctl,"call " +alt_dir+"\\MODESPLIT\\"+alt_name+"_HBU_PEAK")
		writeline(outctl,"call " +alt_dir+"\\MODESPLIT\\"+alt_name+"_HBU_OFFPEAK")

		CloseFile(outctl)

		// -- Create ModeSplit Batch Files to run Peak ModeSplit Model for feedback iterations

		filename_out =  alt_dir + "\\ModeSplit\\"+alt_name + "_RUNPEAK.BAT"
		exist = GetFileInfo(filename_out)
		if exist then deletefile(filename_out)

		outctl=Openfile(filename_out,"w")

		writeline(outctl,"call " +alt_dir+"\\MODESPLIT\\"+alt_name+"_HBW_PEAK")
		writeline(outctl,"call " +alt_dir+"\\MODESPLIT\\"+alt_name+"_HBO_PEAK")
		writeline(outctl,"call " +alt_dir+"\\MODESPLIT\\"+alt_name+"_NHB_PEAK")
		writeline(outctl,"call " +alt_dir+"\\MODESPLIT\\"+alt_name+"_HBU_PEAK")

		CloseFile(outctl)

		filename_out =  alt_dir + "\\ModeSplit\\"+alt_name + "_RUNOFFPEAK.BAT"
		exist = GetFileInfo(filename_out)
		if exist then deletefile(filename_out)

		outctl=Openfile(filename_out,"w")

		writeline(outctl,"call " +alt_dir+"\\MODESPLIT\\"+alt_name+"_HBW_OFFPEAK")
		writeline(outctl,"call " +alt_dir+"\\MODESPLIT\\"+alt_name+"_HBO_OFFPEAK")
		writeline(outctl,"call " +alt_dir+"\\MODESPLIT\\"+alt_name+"_NHB_OFFPEAK")
		writeline(outctl,"call " +alt_dir+"\\MODESPLIT\\"+alt_name+"_HBU_OFFPEAK")

		CloseFile(outctl)

	end // 1 processor

	
quit:
	on error, notfound default
	return({1,msg})

	badquit:
	on error, notfound default
	msg = {"Mode Split Controls - error or notfound"}
	return({0,msg})

endMacro

//------------------------------------------------------------------------
// Macro "Create Mode Split BAtch Files"
//------------------------------------------------------------------------

Macro "Create Mode Split Batch Files" (filename_in, filename_out, alt_dir, alt_name, purp, period, METDir)

	msg = null
	on error, notfound goto badquit

	ModeChoice_Loc = METDir + "\\pgm\\ModeChoice"  

	inctl=Openfile(filename_in,"r")
	outctl=Openfile(filename_out,"w")

	recno=0
	while !FileAtEOF(inctl) do
		line1=ReadLine(inctl)
		recno=recno+1
		line1 = Substitute (line1, "PURPPERIODINC", purp+"_"+period,)
		line1 = Substitute (line1, "ALT_DIR", alt_dir,)
		line1 = Substitute (line1, "ALTNAME", alt_name,)
		line1 = Substitute (line1, "ModeChoice_DIR", ModeChoice_Loc,)
		writeline(outctl,line1)
	end
	CloseFile(outctl)
	CloseFile(inctl)

quit:
	on error, notfound default
	return({1,msg})

	badquit:
	on error, notfound default
	msg = {"Create Mode Split Batch Files - error or notfound"}
	return({0,msg})


endMacro


//------------------------------------------------------------------------
// Macro "Create Mode Split Control Files"
//------------------------------------------------------------------------

Macro "Create Mode Split Control Files" (filename_in, filename_out, alt_dir, alt_name, purp, period)

	msg = null
	on error do
		msg = {"Create Mode Split Control Files bad"}
		goto badquit
		end


	inctl=Openfile(filename_in,"r")
	outctl=Openfile(filename_out,"w")
	recno=0
	while !FileAtEOF(inctl) do
		line1=ReadLine(inctl)
		recno=recno+1

		line1 = Substitute (line1, "ALT_DIR", alt_dir,)
		line1 = Substitute (line1, "ALTNAME", alt_name,)
		writeline(outctl,line1)

	end
	CloseFile(outctl)
	CloseFile(inctl)

	on error default
	return({1, msg})

	badquit:
	on error default
	return({0, msg})

endMacro


//---------------------------------------------------------------------
// Macro "Create Mode Split Output Matrices" 
//---------------------------------------------------------------------


Macro "Create Mode Split Output Matrices" (alt_dir, alt_name, METDir)

msg = null
on error do
	msg = {"Create Mode Split Output Matricies - missing \\taz\\matrix_template.mtx"}
	goto badquit
	end

// --- Copy ModeSplit Output Matrices from the Template Directory
	OM = OpenMatrix(METDir + "\\TAZ\\Matrix_template.mtx", "True")
	idxt = GetMatrixIndex(OM)
	mc1 = CreateMatrixCurrency(OM, "Table", idxt[1], idxt[2], )	
	
	purpperiod = {"HBW_PEAK", "HBW_OFFPEAK","HBO_PEAK", "HBO_OFFPEAK", "HBU_PEAK", "HBU_OFFPEAK", "NHB_PEAK", "NHB_OFFPEAK"}
    for pp = 1 to purpperiod.length do

			on error default
			CopyMatrixStructure({mc1}, {{"File Name", alt_dir+"\\MODESPLIT\\"+purpperiod[pp]+"_MS"+".MTX"},
				{"Label", purpperiod[pp]+"_MS"},
				{"File Based", "Yes"},
				{"Tables", {"Drive Alone", "Carpool 2", "Carpool 3", "Wk-Premium", "Wk-Bus", "Dr-Premium", "Dr-Bus", "DropOff-Premium", "DropOff-Bus", "Walk", "Bike"}},
				{"Operation", "Union"}})
	end
	
	on error default
return({1, msg})

badquit:
on error default
return({0, msg})


endMacro

//---------------------------------------------------------------------
// Macro "Create Transit Skims Output Matrices" 
//---------------------------------------------------------------------

Macro "Create Transit Skims Output Matrices" (alt_dir, alt_name, METDir)

msg = null
on error do
	msg = "Create Transit Skims Outut Matrices - missing \\taz\\matrix_template.mtx"
	goto badquit
	end


OM = OpenMatrix(METDir + "\\TAZ\\matrix_template.mtx", "True")
mc1 = CreateMatrixCurrency(OM, "Table", "Rows", "Columns", )
on error default
CopyMatrixStructure({mc1}, {{"File Name", alt_dir+"\\Skims\\PK_WKTRAN_SKIMS.MTX"},
    {"Label", "Peak Walk-to-Transit"},
    {"File Based", "Yes"},
    {"Tables", {"IVTT - Prem Walk", "Approach - Prem Walk", "Cost - Prem Walk", "Transfer Penalty Time - Prem Walk", "Initial Wait - Prem Walk",  "Access Walk Time - Prem Walk", "Egress Walk Time - Prem Walk", "Transfer Walk Time - Prem Walk", "Transfer Wait Time - Prem Walk",
                "IVTT - Bus Walk", "Approach - Bus Walk", "Cost - Bus Walk", "Transfer Penalty Time - Bus Walk", "Initial Wait - Bus Walk", "Access Walk Time - Bus Walk", "Egress Walk Time - Bus Walk", "Transfer Walk Time - Bus Walk", "Transfer Wait Time - Bus Walk",
                "ModeFlag", "Prem IVTT", "SkS Flag", "PrmOnly Flag",
                "IVTT - Prem2 Walk", "Approach - Prem2 Walk", "Cost - Prem2 Walk", "Transfer Penalty Time - Prem2 Walk", "Initial Wait - Prem2 Walk",  "Access Walk Time - Prem2 Walk", "Egress Walk Time - Prem2 Walk", "Transfer Walk Time - Prem2 Walk", "Transfer Wait Time - Prem2 Walk","ModeFlag2", "Prem2 IVTT", "Prm2Only Flag",
                "Total Walk UnWtd - Prem", "Total Walk UnWtd - Prem2", "Total Walk UnWtd - Bus"}},
    {"Operation", "Union"}})

OM = OpenMatrix(METDir + "\\TAZ\\matrix_template.mtx", "True")
mc1 = CreateMatrixCurrency(OM, "Table", "Rows", "Columns", )
on error default
CopyMatrixStructure({mc1}, {{"File Name", alt_dir+"\\Skims\\OFFPK_WKTRAN_SKIMS.MTX"},
    {"Label", "OffPeak Walk-to-Transit"},
    {"File Based", "Yes"},
    {"Tables", {"IVTT - Prem Walk", "Approach - Prem Walk", "Cost - Prem Walk", "Transfer Penalty Time - Prem Walk", "Initial Wait - Prem Walk",  "Access Walk Time - Prem Walk", "Egress Walk Time - Prem Walk", "Transfer Walk Time - Prem Walk", "Transfer Wait Time - Prem Walk",
                "IVTT - Bus Walk", "Approach - Bus Walk", "Cost - Bus Walk", "Transfer Penalty Time - Bus Walk", "Initial Wait - Bus Walk", "Access Walk Time - Bus Walk", "Egress Walk Time - Bus Walk", "Transfer Walk Time - Bus Walk", "Transfer Wait Time - Bus Walk",
                "ModeFlag", "Prem IVTT", "SkS Flag", "PrmOnly Flag",
                "IVTT - Prem2 Walk", "Approach - Prem2 Walk", "Cost - Prem2 Walk", "Transfer Penalty Time - Prem2 Walk", "Initial Wait - Prem2 Walk",  "Access Walk Time - Prem2 Walk", "Egress Walk Time - Prem2 Walk", "Transfer Walk Time - Prem2 Walk", "Transfer Wait Time - Prem2 Walk","ModeFlag2", "Prem2 IVTT", "Prm2Only Flag",
                "Total Walk UnWtd - Prem", "Total Walk UnWtd - Prem2", "Total Walk UnWtd - Bus"}},
    {"Operation", "Union"}})

OM = OpenMatrix(METDir+ "\\TAZ\\matrix_template.mtx", "True")
mc1 = CreateMatrixCurrency(OM, "Table", "Rows", "Columns", )
on error default
CopyMatrixStructure({mc1}, {{"File Name", alt_dir+"\\Skims\\PK_DRVTRAN_SKIMS.MTX"},
    {"Label", "Peak Drive-to-Transit"},
    {"File Based", "Yes"},
    {"Tables", {"IVTT - Prem Drive", "Approach - Prem Drive", "Cost - Prem Drive", "Transfer Penalty Time - Prem Drive", "Initial Wait - Prem Drive", "Drive Access Time - Prem Drive", "Drive Access Distance - Prem Drive", "Transfer Wait Time - Prem Drive", "Highway OP Time - Prem Drive",
                "IVTT - Bus Drive", "Approach - Bus Drive", "Cost - Bus Drive", "Transfer Penalty Time - Bus Drive", "Initial Wait - Bus Drive", "Drive Access Time - Bus Drive", "Drive Access Distance - Bus Drive", "Transfer Wait Time - Bus Drive", "Highway OP Time - Bus Drive",
                "ModeFlag", "Prem IVTT", "SkS Flag", "PrmOnly Flag",
                "IVTT - Prem2 Drive", "Approach - Prem2 Drive", "Cost - Prem2 Drive", "Transfer Penalty Time - Prem2 Drive", "Initial Wait - Prem2 Drive", "Drive Access Time - Prem2 Drive", "Drive Access Distance - Prem2 Drive", "Transfer Wait Time - Prem2 Drive", "Highway OP Time - Prem2 Drive","ModeFlag2", "Prem2 IVTT", "Prm2Only Flag",
                "Total Walk UnWtd - Prem", "Total Walk UnWtd - Prem2", "Total Walk UnWtd - Bus"}},
    {"Operation", "Union"}})

OM = OpenMatrix(METDir + "\\TAZ\\matrix_template.mtx", "True")
mc1 = CreateMatrixCurrency(OM, "Table", "Rows", "Columns", )
on error default
CopyMatrixStructure({mc1}, {{"File Name", alt_dir+"\\Skims\\OFFPK_DRVTRAN_SKIMS.MTX"},
    {"Label", "OffPeak Drive-to-Transit"},
    {"File Based", "Yes"},
    {"Tables", {"IVTT - Prem Drive", "Approach - Prem Drive", "Cost - Prem Drive", "Transfer Penalty Time - Prem Drive", "Initial Wait - Prem Drive", "Drive Access Time - Prem Drive", "Drive Access Distance - Prem Drive", "Transfer Wait Time - Prem Drive", "Highway OP Time - Prem Drive",
                "IVTT - Bus Drive", "Approach - Bus Drive", "Cost - Bus Drive", "Transfer Penalty Time - Bus Drive", "Initial Wait - Bus Drive", "Drive Access Time - Bus Drive", "Drive Access Distance - Bus Drive", "Transfer Wait Time - Bus Drive", "Highway OP Time - Bus Drive",
                "ModeFlag", "Prem IVTT", "SkS Flag", "PrmOnly Flag",
                "IVTT - Prem2 Drive", "Approach - Prem2 Drive", "Cost - Prem2 Drive", "Transfer Penalty Time - Prem2 Drive", "Initial Wait - Prem2 Drive", "Drive Access Time - Prem2 Drive", "Drive Access Distance - Prem2 Drive", "Transfer Wait Time - Prem2 Drive", "Highway OP Time - Prem2 Drive","ModeFlag2", "Prem2 IVTT", "Prm2Only Flag",
                "Total Walk UnWtd - Prem", "Total Walk UnWtd - Prem2", "Total Walk UnWtd - Bus"}},
    {"Operation", "Union"}})

OM = OpenMatrix(METDir  + "\\TAZ\\matrix_template.mtx", "True")
mc1 = CreateMatrixCurrency(OM, "Table", "Rows", "Columns", )
on error default
CopyMatrixStructure({mc1}, {{"File Name", alt_dir+"\\Skims\\PK_DROPTRAN_SKIMS.MTX"},
    {"Label", "Peak Drop-Off-to-Transit"},
    {"File Based", "Yes"},
    {"Tables", {"IVTT - Prem DropOff", "Approach - Prem DropOff", "Cost - Prem DropOff", "Transfer Penalty Time - Prem DropOff", "Initial Wait - Prem DropOff", "Drive Access Time - Prem DropOff", "Drive Access Distance - Prem DropOff", "Transfer Wait Time - Prem DropOff", "Highway SkimLength - Prem DropOff", "ParkFlag - Prem DropOff",
                "IVTT - Bus DropOff", "Approach - Bus DropOff", "Cost - Bus DropOff", "Transfer Penalty Time - Bus DropOff" , "Initial Wait - Bus DropOff", "Drive Access Time - Bus DropOff", "Drive Access Distance - Bus DropOff", "Transfer Wait Time - Bus DropOff", "Highway SkimLength - Bus DropOff", "ParkFlag - Bus DropOff",
                "ModeFlag", "Prem IVTT", "SkS Flag", "PrmOnly Flag",
                "IVTT - Prem2 DropOff", "Approach - Prem2 DropOff", "Cost - Prem2 DropOff", "Transfer Penalty Time - Prem2 DropOff", "Initial Wait - Prem2 DropOff", "Drive Access Time - Prem2 DropOff", "Drive Access Distance - Prem2 DropOff", "Transfer Wait Time - Prem2 DropOff", "Highway SkimLength - Prem2 DropOff", "ParkFlag - Prem2 DropOff", "ModeFlag2", "Prem2 IVTT", "Prm2Only Flag",
                "Total Walk UnWtd - Prem", "Total Walk UnWtd - Prem2", "Total Walk UnWtd - Bus"}},
    {"Operation", "Union"}})

OM = OpenMatrix(METDir + "\\TAZ\\matrix_template.mtx", "True")
mc1 = CreateMatrixCurrency(OM, "Table", "Rows", "Columns", )
on error default
CopyMatrixStructure({mc1}, {{"File Name", alt_dir+"\\Skims\\OFFPK_DROPTRAN_SKIMS.MTX"},
    {"Label", "OffPeak Drop-Off-to-Transit"},
    {"File Based", "Yes"},
    {"Tables", {"IVTT - Prem DropOff", "Approach - Prem DropOff", "Cost - Prem DropOff", "Transfer Penalty Time - Prem DropOff", "Initial Wait - Prem DropOff", "Drive Access Time - Prem DropOff", "Drive Access Distance - Prem DropOff", "Transfer Wait Time - Prem DropOff", "Highway SkimLength - Prem DropOff", "ParkFlag - Prem DropOff",
                "IVTT - Bus DropOff", "Approach - Bus DropOff", "Cost - Bus DropOff", "Transfer Penalty Time - Bus DropOff" , "Initial Wait - Bus DropOff", "Drive Access Time - Bus DropOff", "Drive Access Distance - Bus DropOff", "Transfer Wait Time - Bus DropOff", "Highway SkimLength - Bus DropOff", "ParkFlag - Bus DropOff",
                "ModeFlag", "Prem IVTT", "SkS Flag", "PrmOnly Flag",
                "IVTT - Prem2 DropOff", "Approach - Prem2 DropOff", "Cost - Prem2 DropOff", "Transfer Penalty Time - Prem2 DropOff", "Initial Wait - Prem2 DropOff", "Drive Access Time - Prem2 DropOff", "Drive Access Distance - Prem2 DropOff", "Transfer Wait Time - Prem2 DropOff", "Highway SkimLength - Prem2 DropOff", "ParkFlag - Prem2 DropOff", "ModeFlag2", "Prem2 IVTT", "Prm2Only Flag",
                "Total Walk UnWtd - Prem", "Total Walk UnWtd - Prem2", "Total Walk UnWtd - Bus"}},
    {"Operation", "Union"}})

on error default
return({1, msg})

badquit:
on error default
return({0, msg})

endMacro


//---------------------------------------------------------------------
// Macro "Create Transit Assignment Matrices" 
//---------------------------------------------------------------------

Macro "Create Transit Assignment Matrices" (alt_dir, alt_name, METDir)

msg = null
on error do
	msg = "Create Transit Assignment Matrices - missing \\taz\\matrix_template.mtx"
	goto badquit
	end


// --- Create From Template Matrix, Output Matrices to store Transit Skims


OM = OpenMatrix(METDir + "\\TAZ\\matrix_template.mtx", "True")
mc1 = CreateMatrixCurrency(OM, "Table", "Rows", "Columns", )
on error default
CopyMatrixStructure({mc1}, {{"File Name", alt_dir+"\\tranassn\\Transit Assign Walk.MTX"},
    {"Label", "Walk-to-Transit Assignment"},
    {"File Based", "Yes"},
    {"Tables", {"PprmW", "PbusW", "OPprmW", "OPbusW"}},
    {"Operation", "Union"}})

OM = OpenMatrix(METDir + "\\TAZ\\matrix_template.mtx", "True")
mc1 = CreateMatrixCurrency(OM, "Table", "Rows", "Columns", )
on error default
CopyMatrixStructure({mc1}, {{"File Name", alt_dir+"\\tranassn\\Transit Assign Drive.MTX"},
    {"Label", "Drive-to-Transit Assignment"},
    {"File Based", "Yes"},
    {"Tables", {"PprmD", "PbusD", "OPprmD", "OPbusD"}},
    {"Operation", "Union"}})

OM = OpenMatrix(METDir + "\\TAZ\\matrix_template.mtx", "True")
mc1 = CreateMatrixCurrency(OM, "Table", "Rows", "Columns", )
on error default
CopyMatrixStructure({mc1}, {{"File Name", alt_dir+"\\tranassn\\Transit Assign DropOff.MTX"},
    {"Label", "DriveOff-to-Transit Assignment"},
    {"File Based", "Yes"},
    {"Tables", {"PprmDropOff", "PbusDropOff", "OPprmDropOff", "OPbusDropOff"}},
    {"Operation", "Union"}})

	on error default
	return({1, msg})

	badquit:
	on error default
	return({0, msg})

endMacro

Macro "ModeChoice Files" (template_dir, alt_dir)

	msg = null
//	on error, notfound goto badquit

	//TAZ_ATYPE.asc.def - def file needed by TransSims modechoice - copy from ms_control template to dir
	filename_in  = template_dir + "\\TAZ_ATYPE.asc.def"
	filename_out = alt_dir 		+ "\\TAZ_ATYPE.asc.def"
	CopyFile(filename_in, filename_out)


	filename_in  = template_dir + "\\Mode_Choice_Script"+".txt"
	filename_out = alt_dir 		+ "\\ModeSplit\\INPUTS\\" + "Mode_Choice_Script"+".txt"
	CopyFile(filename_in, filename_out)
	
	filename_in  = template_dir + "\\Segment_Map"+".txt"
	filename_out = alt_dir 		+ "\\ModeSplit\\INPUTS\\Controls\\" + "Segment_Map"+".txt"
	CopyFile(filename_in, filename_out)
	
	filename_in  = template_dir + "\\Segment_Map"+".txt.def"
	filename_out = alt_dir 		+ "\\ModeSplit\\INPUTS\\Controls\\" + "Segment_Map"+".txt.def"
	CopyFile(filename_in, filename_out)
	
	purpperiod = {"HBW_PEAK", "HBW_OFFPEAK","HBO_PEAK", "HBO_OFFPEAK", "HBU_PEAK", "HBU_OFFPEAK", "NHB_PEAK", "NHB_OFFPEAK"}
	const_bias = {"Constant.txt", "Constant.txt.def", "Bias.txt", "Bias.txt.def"}
    
	for pp = 1 to purpperiod.length do
		for cb = 1 to const_bias.length do
		
		filename_in  = template_dir + "\\" + purpperiod[pp] + "_" + const_bias[cb]
		filename_out = alt_dir 		+ "\\ModeSplit\\INPUTS\\" + purpperiod[pp] + "_" + const_bias[cb]
		CopyFile(filename_in, filename_out)
		
		end
	end
	
	on error default
	return({1, msg})

	badquit:
	on error default
	return({0, msg})

	
endMacro

