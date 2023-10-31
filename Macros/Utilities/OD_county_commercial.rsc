Macro "OD_county_commercial"

	RunMacro("TCB Init")
	RunMacro("G30 File Close All") 

	Dir = "C:\\MRM1901_PPSL\\Metrolina\\2015"
 	DirOutDC  = Dir + "\\TD"


	counties = {{37025, "Cabarrus"}, {37035, "Catawba"}, {37045, "Cleveland"}, {37071, "Gaston"}, {37097, "Iredell"}, {37109, "Lincoln"}, {37119, "Mecklenburg"}, 
			{37159, "Rowan"}, {37167, "Stanly"}, {37179, "Union"}, {45057, "Lancaster"}, {45091, "York"}, {99999, "External"}}
//	stcnty_tab = OpenTable("stcnty_tab", "DBASE", {MetDir + "\\STCNTY_ID.dbf",})

	purpose = {"COM",  "MTK",  "HTK"}
	purpose_dest = {"COM",  "MTK",  "HTK"}

	ii_ar = {"COM",  "MTK",  "HTK"}
	ix_ar = {"IEC",  "IEM",  "IEH"}
	xi_ar = {"EIC",  "EIM",  "EIH"}
	
	taz_tab = OpenTable("taz_tab", "FFB", {"C:\\MRM1901_PPSL\\TAZ\\taz3578.bin",})


	orig_tab = CreateTable("orig_tab", Dir + "\\Report\\Orig_County_commercial.bin", "FFB", {
				{"PURP", "String", 4, , "No"}, {"Cabarrus", "Real", 12, 2, "No"}, {"Catawba", "Real", 12, 2, "No"}, 
				{"Cleveland", "Real", 12, 2, "No"}, {"Gaston", "Real", 12, 2, "No"}, {"Iredell", "Real", 12, 2, "No"}, {"Lincoln", "Real", 12, 2, "No"}, 
				{"Mecklenburg", "Real", 12, 2, "No"}, {"Rowan", "Real", 12, 2, "No"}, {"Stanly", "Real", 12, 2, "No"}, {"Union", "Real", 12, 2, "No"}, 
				{"Lancaster", "Real", 12, 2, "No"}, {"York", "Real", 12, 2, "No"}, {"External", "Real", 12, 2, "No"}, {"Total", "Real", 12, 2, "No"}}) 

	dest_tab = CreateTable("dest_tab", Dir + "\\Report\\Dest_County_commercial.bin", "FFB", {
				{"PURP", "String", 4, , "No"}, {"Cabarrus", "Real", 12, 2, "No"}, {"Catawba", "Real", 12, 2, "No"}, 
				{"Cleveland", "Real", 12, 2, "No"}, {"Gaston", "Real", 12, 2, "No"}, {"Iredell", "Real", 12, 2, "No"}, {"Lincoln", "Real", 12, 2, "No"}, 
				{"Mecklenburg", "Real", 12, 2, "No"}, {"Rowan", "Real", 12, 2, "No"}, {"Stanly", "Real", 12, 2, "No"}, {"Union", "Real", 12, 2, "No"}, 
				{"Lancaster", "Real", 12, 2, "No"}, {"York", "Real", 12, 2, "No"}, {"External", "Real", 12, 2, "No"}, {"Total", "Real", 12, 2, "No"}}) 


	rh = AddRecords("orig_tab", , ,{{"Empty Records", purpose.length}})
	rh = AddRecords("dest_tab", , ,{{"Empty Records", purpose.length}})

	for p = 1 to purpose.length do

		II_m = OpenMatrix(Dir + "\\TD\\TD" + ii_ar[p] + ".mtx", "True")
		II_mc = CreateMatrixCurrency(II_m, "Trips", "Rows", "Columns",)
	
		IX_m = OpenMatrix(Dir + "\\TD\\TD" + ix_ar[p] + ".mtx", "True")
		IX_mc = CreateMatrixCurrency(IX_m, "Trips", "Rows", "Columns",)

		XI_m = OpenMatrix(Dir + "\\TD\\TD" + xi_ar[p] + ".mtx", "True")
		XI_mc = CreateMatrixCurrency(XI_m, "Trips", "Rows", "Columns",)

		mat_ar = {II_m, IX_m, XI_m}

		for c = 1 to counties.length do //origin counties.length
			for a = 1 to 3 do
				mat_indices = GetMatrixIndexNames(mat_ar[a])	
		
				//this creates County indices if needed
				if c = 1 then do 				
					for c2 = 1 to counties.length do		
						for i = 1 to mat_indices[1].length do
							if counties[c2][2] = mat_indices[1][i] then do
								goto skipcreateindex
							end
						end
						qry = "Select * where STCNTY = " + i2s(counties[c2][1]) 
						SetView("taz_tab")
						countyset = SelectByQuery("countyset", "Several", qry)
						new_index = CreateMatrixIndex(counties[c2][2], mat_ar[a], "Both", "taz_tab|countyset", "TAZ", "TAZ" )
						skipcreateindex:

					end
				end
			end
			//Origins (XIs go in externals; sum of II and IX go in counties)
			if c = counties.length then do
				SetMatrixIndex(XI_m, counties[c][2], "Columns")
				stat_ar = MatrixStatistics(XI_m, )
				valxi = (stat_ar[1][2][2][2])
				SetRecordValues("orig_tab", i2s(p), {{"PURP", purpose[p]}, {counties[c][2], valxi}})
				goto skipinternals
			end
			SetMatrixIndex(II_m, counties[c][2], "Columns")
			stat_ar = MatrixStatistics(II_m, )
			valii = (stat_ar[1][2][2][2])

			SetMatrixIndex(IX_m, counties[c][2], "Columns")
			stat_ar = MatrixStatistics(IX_m, )
			valix = (stat_ar[1][2][2][2])

			valii = valii + valix
			SetRecordValues("orig_tab", i2s(p), {{counties[c][2], valii}})

			skipinternals:

			//Destinations (IXs go in in externals; sum of II and XI go in counties)
			if c = counties.length then do
				SetMatrixIndex(IX_m, "Rows", counties[c][2])
				stat_ar = MatrixStatistics(IX_m, )
				valix = (stat_ar[1][2][2][2])
				SetRecordValues("dest_tab", i2s(p), {{"PURP", purpose[p]}, {counties[c][2], valix}})
				goto skipint
			end
			SetMatrixIndex(II_m, "Rows", counties[c][2])
			stat_ar = MatrixStatistics(II_m, )
			valii = (stat_ar[1][2][2][2])

			SetMatrixIndex(XI_m, "Rows", counties[c][2])
			stat_ar = MatrixStatistics(XI_m, )
			valxi = (stat_ar[1][2][2][2])

			valii = valii + valxi
			SetRecordValues("dest_tab", i2s(p), {{counties[c][2], valii}})
			skipint:

		end
	end

//SetRecordValues("out_tab", i2s(rh), {{"Origin", name_v[f]}, {"Destination", name_v[t]}, {"CoreName", corename}, {"Trips", val}})


    RunMacro("G30 File Close All")
	
endmacro