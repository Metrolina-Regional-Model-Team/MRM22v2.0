macro "totassn_vc2"
// macro to pull model links (length) (by area type and functional class and v/c increment
//  current version pulls only am peak
	Dir = "D:\\MS2018_7\\Metrolina\\2018"
	TotAssnFile = Dir + "\\hwyassn\\hot\\tot_assn_HOT.bin"
	ATFunFile = Dir + "\\Tot_Assn_VC_test.csv"
	
				
	ATFunView = CreateTable("ATFunView", ATFunFile, "CSV",
			{{"AT", "Integer", 2, null, "No"},
			 {"FUN", "Integer", 2, null, "No"},
			 {"VCCount",	"Real", 10, 2, "No"},
			 {"VCLen",	"Real", 10, 2, "No"},
			 {"VCAM",	"Real", 10, 2, "No"},
			 {"VCMI",	"Real", 10, 2, "No"},
			 {"VCPM",	"Real", 10, 2, "No"},
			 {"VCNT",	"Real", 10, 2, "No"}
			 }) 

	TotAssnView = 	OpenTable("TotAssnView", "FFB", {TotAssnFile,})
	rec = GetFirstRecord(TotAssnView + "|", )
	while rec <> null do
		recval = GetRecordValues(TotAssnView, rec, 
							{"Length", "Dir", "funcl", "areatp", 
							 "vcAMAB", "vcAMBA", 
							 "vcPMAB", "vcPMBA", 
							 "vcMIAB", "vcMIBA", 
							 "vcNTAB", "vcNTBA" 
					})
		len 	= recval[1][2]
		dir 	= recval[2][2]
		funcl 	= recval[3][2]
		areatp 	= recval[4][2]
		vcamab  = recval[5][2]
		vcamba	= recval[6][2]
		vcpmab	= recval[7][2]
		vcpmba	= recval[8][2]
		vcmiab	= recval[9][2]
		vcmiba	= recval[10][2]
		vcntab	= recval[11][2]
		vcntba	= recval[12][2]
		
		if funcl > 0 and funcl < 23 then do
			andx = r2i(areatp)
			fndx = r2i(funcl)
			if fndx = 22 then fndx = 10

			// ab direction - 
			if dir <> -1 then do

			SetView(ATFunView)
			atvals = 
				{{"AT", andx}, {"FUN", funcl},
				 {"VCLen",	len},
				 {"VCAM",	vcamab},
				 {"VCMI",	vcmiab},
				 {"VCPM",	vcpmab},
				 {"VCNT",	vcntab}
				 }
				AddRecord (ATFunView, atvals)
			end // if dir
			// ba diretion
			if dir <> 1 then do

			SetView(ATFunView)
			atvals = 
				{{"AT", andx}, {"FUN", funcl},
				 {"VCLen",	len},
				 {"VCAM",	vcamba},
				 {"VCMI",	vcmiba},
				 {"VCPM",	vcpmba},
				 {"VCNT",	vcntba}
				 }
				AddRecord (ATFunView, atvals)
			end // if dir
			SetView(TotAssnView)
		end // if funcl
		rec = GetNextRecord(TotAssnView + "|", null,)
	end // while
	CloseView(TotAssnView)
	CloseView(ATFunView)	


endmacro
