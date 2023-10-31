macro "totassn_speeds"
// macro to pull model speeds by area type and functional class
//	Aggregates travel time (minraw) - calculates cell speed (length / (time / 60)

//  current version pulls only am peak
	Dir = "D:\\MS2018_7\\Metrolina\\2018"
	TotAssnFile = Dir + "\\hwyassn\\hot\\tot_assn_HOT.bin"
	ATFunFile = Dir + "\\Tot_Assn_Speeds_ATFUN.csv"
	
	//ATFun array [x]areatp, [y] funcl (1-9+22), 
	// z, [xy1]=count, [xy2]=length, [xy3]=ttfree, [xy4]=ttampk, [xy5]=ttmddy, [xy6]=ttpmpk, [xy7]=ttnite
	dim ATFun[5,10,7]
	for x = 1 to 5 do
		for y = 1 to 10 do
			for z = 1 to 7 do
				ATFun[x][y][z] = 0
			end
		end
	end
				
	ATFunView = CreateTable("ATFunView", ATFunFile, "CSV",
			{{"AT", "Integer", 2, null, "No"},
			 {"FUN", "Integer", 2, null, "No"},
			 {"Cnt1w",	"Real", 10, 2, "No"},
			 {"Len1w",	"Real", 10, 2, "No"},
			 {"ttfree",	"Real", 10, 2, "No"},
			 {"ttampk",	"Real", 10, 2, "No"},
			 {"ttmddy",	"Real", 10, 2, "No"},
			 {"ttpmpk",	"Real", 10, 2, "No"},
			 {"ttnite",	"Real", 10, 2, "No"},
			 {"spfree",	"Real", 10, 2, "No"},
			 {"spampk",	"Real", 10, 2, "No"},
			 {"spmddy",	"Real", 10, 2, "No"},
			 {"sppmpk",	"Real", 10, 2, "No"},
			 {"spnite",	"Real", 10, 2, "No"}
			 }) 

	TotAssnView = 	OpenTable("TotAssnView", "FFB", {TotAssnFile,})
	rec = GetFirstRecord(TotAssnView + "|", )
	while rec <> null do
		recval = GetRecordValues(TotAssnView, rec, 
							{"Length", "Dir", "funcl", "areatp", 
							 "TTfreeAB", "TTfreeBA", 
							 "MinRawAMAB", "MinRawAMBA", 
							 "MinRawPMAB", "MinRawPMBA", 
							 "MinRawMIAB", "MinRawMIBA", 
							 "MinRawNTAB", "MinRawNTBA" 
					})
		len 		= recval[1][2]
		dir 		= recval[2][2]
		funcl 		= recval[3][2]
		areatp 		= recval[4][2]
		ttfreeab	= recval[5][2]
		ttfreeba	= recval[6][2]
		ttampkab	= recval[7][2]
		ttampkba	= recval[8][2]
		ttpmpkab	= recval[9][2]
		ttpmpkba	= recval[10][2]
		ttmddyab	= recval[11][2]
		ttmddyba	= recval[12][2]
		ttniteab	= recval[13][2]
		ttniteba	= recval[14][2]
		
		if funcl > 0 and funcl < 23 then do
			andx = r2i(areatp)
			fndx = r2i(funcl)
			if fndx = 22 then fndx = 10

			// ab direction - 
			if dir <> -1 then do
				ATFun[andx][fndx][1] = ATFun[andx][fndx][1] + 1
				ATFun[andx][fndx][2] = ATFun[andx][fndx][2] + len
				ATFun[andx][fndx][3] = ATFun[andx][fndx][3] + ttfreeab
				ATFun[andx][fndx][4] = ATFun[andx][fndx][4] + ttampkab
				ATFun[andx][fndx][5] = ATFun[andx][fndx][5] + ttmddyab
				ATFun[andx][fndx][6] = ATFun[andx][fndx][6] + ttpmpkab
				ATFun[andx][fndx][7] = ATFun[andx][fndx][7] + ttniteab
			end // if dir <> -1 - ab direction

			// ba diretion
			if dir <> 1 then do
				ATFun[andx][fndx][1] = ATFun[andx][fndx][1] + 1
				ATFun[andx][fndx][2] = ATFun[andx][fndx][2] + len
				ATFun[andx][fndx][3] = ATFun[andx][fndx][3] + ttfreeba
				ATFun[andx][fndx][4] = ATFun[andx][fndx][4] + ttampkba
				ATFun[andx][fndx][5] = ATFun[andx][fndx][5] + ttmddyba
				ATFun[andx][fndx][6] = ATFun[andx][fndx][6] + ttpmpkba
				ATFun[andx][fndx][7] = ATFun[andx][fndx][7] + ttniteba
			end // if dir <> 1  - ba direction
		end // if funcl 

		rec = GetNextRecord(TotAssnView + "|", null,)
	end // while
	CloseView(TotAssnView)
	
	// Write Array
	SetView(ATFunView)
	for andx = 1 to 5 do
		for fndx = 1 to 10 do 
			if fndx < 10 then funcl = fndx else funcl = 22
			len  = ATFun[andx][fndx][2]
			ttfr = ATFun[andx][fndx][3]
			ttam = ATFun[andx][fndx][4]
			ttmi = ATFun[andx][fndx][5]
			ttpm = ATFun[andx][fndx][6]
			ttnt = ATFun[andx][fndx][7]
			 
			if ttfr > 0 then spfr = len / (ttfr / 60.) else spfr = 0.		
			if ttam > 0 then spam = len / (ttam / 60.) else spam = 0.		
			if ttmi > 0 then spmi = len / (ttmi / 60.) else spmi = 0.		
			if ttpm > 0 then sppm = len / (ttpm / 60.) else sppm = 0.		
			if ttnt > 0 then spnt = len / (ttnt / 60.) else spnt = 0.		
	//ATFun array [x]areatp, [y] funcl (1-9+22), 
	// z, [xy1]=count, [xy2]=length, [xy3]=ttfree, [xy4]=ttampk, [xy5]=ttmddy, [xy6]=ttpmpk, [xy7]=ttnite

			atvals = 
				{{"AT", andx}, {"FUN", funcl},
				 {"Cnt1w",	ATFun[andx][fndx][1]},
				 {"Len1w",	ATFun[andx][fndx][2]},
				 {"ttfree",	ATFun[andx][fndx][3]},
				 {"ttampk",	ATFun[andx][fndx][4]},
				 {"ttmddy",	ATFun[andx][fndx][5]},
				 {"ttpmpk",	ATFun[andx][fndx][6]},
				 {"ttnite",	ATFun[andx][fndx][7]},
				 {"spfree",	spfr},
				 {"spampk",	spam},
				 {"spmddy",	spmi},
				 {"sppmpk",	sppm},
				 {"spnite",	spnt}

				 }
				AddRecord (ATFunView, atvals)
		end // for fndx
	end // for andx
	
	CloseView(ATFunView)	


endmacro
