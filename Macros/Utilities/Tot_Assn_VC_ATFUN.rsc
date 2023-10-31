macro "totassn_vc"
// macro to pull model links (length) (by area type and functional class and v/c increment
//  current version pulls only am peak
	Dir = "D:\\MS2018_7\\Metrolina\\2018"
	TotAssnFile = Dir + "\\hwyassn\\hot\\tot_assn_HOT.bin"
	ATFunFile = Dir + "\\Tot_Assn_VC_ATFUN.csv"
	
	//ATFun array [x]areatp, [y] funcl (1-9+22), 
	// z, vc < 0.5 [xy1] vc < 0.6 [xy2] vc < 0.7, [xy3] ... vc < 1.9 [xy15] vc >= 2.0 [xy16]
	// zz - length, count  
	dim ATFun[5,10,16,2]
	for x = 1 to 5 do
		for y = 1 to 10 do
			for z = 1 to 16 do
				for zz = 1 to 2 do
					ATFun[x][y][z][zz] = 0
				end
			end
		end
	end
				
	ATFunView = CreateTable("ATFunView", ATFunFile, "CSV",
			{{"AT", "Integer", 2, null, "No"},
			 {"FUN", "Integer", 2, null, "No"},
			 {"VC05Len",	"Real", 10, 2, "No"},
			 {"VC0Len6",	"Real", 10, 2, "No"},
			 {"VC07Len",	"Real", 10, 2, "No"},
			 {"VC08Len",	"Real", 10, 2, "No"},
			 {"VC09Len",	"Real", 10, 2, "No"},
			 {"VC10Len",	"Real", 10, 2, "No"},
			 {"VC11Len",	"Real", 10, 2, "No"},
			 {"VC12Len",	"Real", 10, 2, "No"},
			 {"VC13Len",	"Real", 10, 2, "No"},
			 {"VC14Len",	"Real", 10, 2, "No"},
			 {"VC15Len",	"Real", 10, 2, "No"},
			 {"VC16Len",	"Real", 10, 2, "No"},
			 {"VC17Len",	"Real", 10, 2, "No"},
			 {"VC18Len",	"Real", 10, 2, "No"},
			 {"VC19Len",	"Real", 10, 2, "No"},
			 {"VC20Len",	"Real", 10, 2, "No"},
			 {"VC05Cnt",	"Real", 10, 2, "No"},
			 {"VC0LCnt",	"Real", 10, 2, "No"},
			 {"VC07Cnt",	"Real", 10, 2, "No"},
			 {"VC08Cnt",	"Real", 10, 2, "No"},
			 {"VC09Cnt",	"Real", 10, 2, "No"},
			 {"VC10Cnt",	"Real", 10, 2, "No"},
			 {"VC11Cnt",	"Real", 10, 2, "No"},
			 {"VC12Cnt",	"Real", 10, 2, "No"},
			 {"VC13Cnt",	"Real", 10, 2, "No"},
			 {"VC14Cnt",	"Real", 10, 2, "No"},
			 {"VC15Cnt",	"Real", 10, 2, "No"},
			 {"VC16Cnt",	"Real", 10, 2, "No"},
			 {"VC17Cnt",	"Real", 10, 2, "No"},
			 {"VC18Cnt",	"Real", 10, 2, "No"},
			 {"VC19Cnt",	"Real", 10, 2, "No"},
			 {"VC20Cnt",	"Real", 10, 2, "No"}
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

				for tod = 1 to 4 do
					if tod = 1 then vctod = vcamab
					else if tod = 2 then vctod = vcpmab
					else if tod = 3 then vctod = vcmiab
					else if tod = 4 then vctod = vcntab

					if vctod < 0.5 then do	ATFun[andx][fndx][1][1] = ATFun[andx][fndx][1][1] + len
											ATFun[andx][fndx][1][2] = ATFun[andx][fndx][1][2] + 1.0 end // vctod < 0.5
					else if vctod < 0.6 then do	ATFun[andx][fndx][2][1] = ATFun[andx][fndx][2][1] + len
												ATFun[andx][fndx][2][2] = ATFun[andx][fndx][2][2] + 1.0 end // vctod < 0.6
					else if vctod < 0.7 then do	ATFun[andx][fndx][3][1] = ATFun[andx][fndx][3][1] + len
												ATFun[andx][fndx][3][2] = ATFun[andx][fndx][3][2] + 1.0 end // vctod < 0.7
					else if vctod < 0.8 then do	ATFun[andx][fndx][4][1] = ATFun[andx][fndx][4][1] + len
												ATFun[andx][fndx][4][2] = ATFun[andx][fndx][4][2] + 1.0 end // vctod < 0.8
					else if vctod < 0.9 then do	ATFun[andx][fndx][5][1] = ATFun[andx][fndx][5][1] + len
												ATFun[andx][fndx][5][2] = ATFun[andx][fndx][5][2] + 1.0 end // vctod < 0.9
					else if vctod < 1.0 then do	ATFun[andx][fndx][6][1] = ATFun[andx][fndx][6][1] + len
												ATFun[andx][fndx][6][2] = ATFun[andx][fndx][6][2] + 1.0 end // vctod < 1.0
					else if vctod < 1.1 then do	ATFun[andx][fndx][7][1] = ATFun[andx][fndx][7][1] + len
												ATFun[andx][fndx][7][2] = ATFun[andx][fndx][7][2] + 1.0 end // vctod < 1.1
					else if vctod < 1.2 then do	ATFun[andx][fndx][8][1] = ATFun[andx][fndx][8][1] + len
												ATFun[andx][fndx][8][2] = ATFun[andx][fndx][8][2] + 1.0 end // vctod < 1.2
					else if vctod < 1.3 then do	ATFun[andx][fndx][9][1] = ATFun[andx][fndx][9][1] + len
												ATFun[andx][fndx][9][2] = ATFun[andx][fndx][9][2] + 1.0 end // vctod < 1.3
					else if vctod < 1.4 then do	ATFun[andx][fndx][10][1] = ATFun[andx][fndx][10][1] + len
												ATFun[andx][fndx][10][2] = ATFun[andx][fndx][10][2] + 1.0 end // vctod < 1.4
					else if vctod < 1.5 then do	ATFun[andx][fndx][11][1] = ATFun[andx][fndx][11][1] + len
												ATFun[andx][fndx][11][2] = ATFun[andx][fndx][11][2] + 1.0 end // vctod < 1.5
					else if vctod < 1.6 then do	ATFun[andx][fndx][12][1] = ATFun[andx][fndx][12][1] + len
												ATFun[andx][fndx][12][2] = ATFun[andx][fndx][12][2] + 1.0 end // vctod < 1.6
					else if vctod < 1.7 then do	ATFun[andx][fndx][13][1] = ATFun[andx][fndx][13][1] + len
												ATFun[andx][fndx][13][2] = ATFun[andx][fndx][13][2] + 1.0 end // vctod < 1.7
					else if vctod < 1.8 then do	ATFun[andx][fndx][14][1] = ATFun[andx][fndx][14][1] + len
												ATFun[andx][fndx][14][2] = ATFun[andx][fndx][14][2] + 1.0 end // vctod < 1.8
					else if vctod < 1.9 then do	ATFun[andx][fndx][15][1] = ATFun[andx][fndx][15][1] + len
												ATFun[andx][fndx][15][2] = ATFun[andx][fndx][15][2] + 1.0 end // vctod < 1.9
					else do						ATFun[andx][fndx][16][1] = ATFun[andx][fndx][16][1] + len
												ATFun[andx][fndx][16][2] = ATFun[andx][fndx][16][2] + 1.0 end // vctod > 1.9
				end // for tod
			end // if dir <> -1 - ab direction

			// ba diretion
			if dir <> 1 then do

				for tod = 1 to 4 do
					if tod = 1 then vctod = vcamba
					else if tod = 2 then vctod = vcpmba
					else if tod = 3 then vctod = vcmiba
					else if tod = 4 then vctod = vcntba
	
					if vctod < 0.5 then do	ATFun[andx][fndx][1][1] = ATFun[andx][fndx][1][1] + len
											ATFun[andx][fndx][1][2] = ATFun[andx][fndx][1][2] + 1.0 end // vctod < 0.5
					else if vctod < 0.6 then do	ATFun[andx][fndx][2][1] = ATFun[andx][fndx][2][1] + len
												ATFun[andx][fndx][2][2] = ATFun[andx][fndx][2][2] + 1.0 end // vctod < 0.6
					else if vctod < 0.7 then do	ATFun[andx][fndx][3][1] = ATFun[andx][fndx][3][1] + len
												ATFun[andx][fndx][3][2] = ATFun[andx][fndx][3][2] + 1.0 end // vctod < 0.7
					else if vctod < 0.8 then do	ATFun[andx][fndx][4][1] = ATFun[andx][fndx][4][1] + len
												ATFun[andx][fndx][4][2] = ATFun[andx][fndx][4][2] + 1.0 end // vctod < 0.8
					else if vctod < 0.9 then do	ATFun[andx][fndx][5][1] = ATFun[andx][fndx][5][1] + len
												ATFun[andx][fndx][5][2] = ATFun[andx][fndx][5][2] + 1.0 end // vctod < 0.9
					else if vctod < 1.0 then do	ATFun[andx][fndx][6][1] = ATFun[andx][fndx][6][1] + len
												ATFun[andx][fndx][6][2] = ATFun[andx][fndx][6][2] + 1.0 end // vctod < 1.0
					else if vctod < 1.1 then do	ATFun[andx][fndx][7][1] = ATFun[andx][fndx][7][1] + len
												ATFun[andx][fndx][7][2] = ATFun[andx][fndx][7][2] + 1.0 end // vctod < 1.1
					else if vctod < 1.2 then do	ATFun[andx][fndx][8][1] = ATFun[andx][fndx][8][1] + len
												ATFun[andx][fndx][8][2] = ATFun[andx][fndx][8][2] + 1.0 end // vctod < 1.2
					else if vctod < 1.3 then do	ATFun[andx][fndx][9][1] = ATFun[andx][fndx][9][1] + len
												ATFun[andx][fndx][9][2] = ATFun[andx][fndx][9][2] + 1.0 end // vctod < 1.3
					else if vctod < 1.4 then do	ATFun[andx][fndx][10][1] = ATFun[andx][fndx][10][1] + len
												ATFun[andx][fndx][10][2] = ATFun[andx][fndx][10][2] + 1.0 end // vctod < 1.4
					else if vctod < 1.5 then do	ATFun[andx][fndx][11][1] = ATFun[andx][fndx][11][1] + len
												ATFun[andx][fndx][11][2] = ATFun[andx][fndx][11][2] + 1.0 end // vctod < 1.5
					else if vctod < 1.6 then do	ATFun[andx][fndx][12][1] = ATFun[andx][fndx][12][1] + len
												ATFun[andx][fndx][12][2] = ATFun[andx][fndx][12][2] + 1.0 end // vctod < 1.6
					else if vctod < 1.7 then do	ATFun[andx][fndx][13][1] = ATFun[andx][fndx][13][1] + len
												ATFun[andx][fndx][13][2] = ATFun[andx][fndx][13][2] + 1.0 end // vctod < 1.7
					else if vctod < 1.8 then do	ATFun[andx][fndx][14][1] = ATFun[andx][fndx][14][1] + len
												ATFun[andx][fndx][14][2] = ATFun[andx][fndx][14][2] + 1.0 end // vctod < 1.8
					else if vctod < 1.9 then do	ATFun[andx][fndx][15][1] = ATFun[andx][fndx][15][1] + len
												ATFun[andx][fndx][15][2] = ATFun[andx][fndx][15][2] + 1.0 end // vctod < 1.9
					else do						ATFun[andx][fndx][16][1] = ATFun[andx][fndx][16][1] + len
												ATFun[andx][fndx][16][2] = ATFun[andx][fndx][16][2] + 1.0 end // vctod > 1.9
				end // for tod
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
		
	//ATFun array [x]areatp, [y] funcl (1-9+22), 
	// z, vc < 0.5 [xy1] vc < 0.6 [xy2] vc < 0.7, [xy3] ... vc < 1.9 [xy15] vc >= 2.0 [xy16]
	// zz - length, count  

			atvals = 
				{{"AT", andx}, {"FUN", funcl},
			 	 {"VC05Len",	ATFun[andx][fndx][1][1]},
				 {"VC0Len6",	ATFun[andx][fndx][2][1]},
				 {"VC07Len",	ATFun[andx][fndx][3][1]},
				 {"VC08Len",	ATFun[andx][fndx][4][1]},
				 {"VC09Len",	ATFun[andx][fndx][5][1]},
				 {"VC10Len",	ATFun[andx][fndx][6][1]},
				 {"VC11Len",	ATFun[andx][fndx][7][1]},
				 {"VC12Len",	ATFun[andx][fndx][8][1]},
				 {"VC13Len",	ATFun[andx][fndx][9][1]},
				 {"VC14Len",	ATFun[andx][fndx][10][1]},
				 {"VC15Len",	ATFun[andx][fndx][11][1]},
				 {"VC16Len",	ATFun[andx][fndx][12][1]},
				 {"VC17Len",	ATFun[andx][fndx][13][1]},
				 {"VC18Len",	ATFun[andx][fndx][14][1]},
				 {"VC19Len",	ATFun[andx][fndx][15][1]},
				 {"VC20Len",	ATFun[andx][fndx][16][1]},
				 {"VC05Cnt",	ATFun[andx][fndx][1][2]},
				 {"VC0LCnt",	ATFun[andx][fndx][2][2]},
				 {"VC07Cnt",	ATFun[andx][fndx][3][2]},
				 {"VC08Cnt",	ATFun[andx][fndx][4][2]},
				 {"VC09Cnt",	ATFun[andx][fndx][5][2]},
				 {"VC10Cnt",	ATFun[andx][fndx][6][2]},
				 {"VC11Cnt",	ATFun[andx][fndx][7][2]},
				 {"VC12Cnt",	ATFun[andx][fndx][8][2]},
				 {"VC13Cnt",	ATFun[andx][fndx][9][2]},
				 {"VC14Cnt",	ATFun[andx][fndx][10][2]},
				 {"VC15Cnt",	ATFun[andx][fndx][11][2]},
				 {"VC16Cnt",	ATFun[andx][fndx][12][2]},
				 {"VC17Cnt",	ATFun[andx][fndx][13][2]},
				 {"VC18Cnt",	ATFun[andx][fndx][14][2]},
				 {"VC19Cnt",	ATFun[andx][fndx][15][2]},
				 {"VC20Cnt",	ATFun[andx][fndx][16][2]}
				 }
				AddRecord (ATFunView, atvals)
		end // for fndx
	end // for andx
	
	CloseView(ATFunView)	


endmacro
