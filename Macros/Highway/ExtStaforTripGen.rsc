Macro "ExtStaforTripGen" (Args)

	// Macro to replace fortran ExtStaCBD
	// Writes 2 .asc files 
	//	Dist_to_closest_ExtSta - Each taz - closest external station and distance (miles)
	//	Dist_to_CBD - Each TAZ - distance to Charlotte CBD - use TAZ 10003 as proxy 

	// Look to get rid of Dist_to_CBD - I can't find it used anywhere
// 5/30/19, mk: There are now three distinct networks, use offpeak 

	Dir = Args.[Run Directory].value
	netview = Args.[Offpeak Hwy Name].value
	SPMATFile = Dir + "\\Skims\\SPMAT_Free.mtx"
	SPMATCoreName = "Length (skim)"
	CBDProxy = 10003
	CBDNdx = 0

	ExtStaOK = 1

	// progress bar variables
	ticks = 1

	// Get the scope of a geographic file
	info = GetDBInfo(Dir + "\\"+netview+".dbd")
	if info = null then do
		msg = msg + {"ExtStaforTripGen: " + netview + ".dbd does not exist in this directory"}
//		AppendToLogFile(1, ""ExtStaforTripGen: " + netview + ".dbd does not exist in this directory")
		goto badnetview
		end
	else scope = info[1]

	// Create a map using this scope
	CreateMap(netview, {{"Scope", scope},{"Auto Project", "True"}})

	file = Dir + "\\"+netview+".dbd"
	layers = GetDBLayers(file)
	addlayer(netview, "Node", file, layers[1])
	addlayer(netview, netview, file, layers[2])
	SetLayerVisibility("Node", "True")
	SetIcon("Node|", "Font Character", "Caliper Cartographic|4", 36)
	SetLayerVisibility(netview, "True")
	solid = LineStyle({{{1, -1, 0}}})
	SetLineStyle(netview+"|", solid)
	SetLineColor(netview+"|", ColorRGB(32000, 32000, 32000))
	SetLineWidth(netview+"|", 0)

	SetView("Node")
	selectquery = "Select * where [External Station] = 1"
	NumExtSta = selectbyquery("ExtSta", "Several", selectquery,)
	if NumExtSta = 0 then goto badextsta
	vExtSta = GetDataVector("Node|ExtSta", "ID",)
	aExtSta = VectorToArray(vExtSta)
//	showarray(aExtSta)	
	CloseMap()

	CreateProgressBar("Closest External Station for Trip Gen", "False")
	stat = UpdateProgressBar("Closest External Station for Trip Gen",5)


	// Open SPMAT
	on error, notfound goto badspmat
	SPMATMtx = OpenMatrix(SPMATFile, "True")
	SPMATNdx = GetMatrixIndex(SPMATMtx)
	SPMATCore = CreateMatrixCurrency(SPMATMtx, SPMATCoreName, SPMATNdx[1], SPMATNdx[2],)

	Row_labels = GetMatrixRowLabels(SPMATCore)
	NumTAZ = Row_labels.length

	// Arrays:  Matrix TAZ ID, Closest Ext Sta[TAZ,2] - ExtSta and Distance, Dist to CBD[TAZ]
	dim MtxTAZ[NumTAZ], ClosestExtSta[NumTAZ,2], DistToCBD[NumTAZ]

	// Assume ExtSta are last set of TAZ in row
	FirstExtStaNdx = NumTAZ - NumExtSta + 1

	addtick = r2i(NumTAZ / 32) 


	for i = 1 to NumTAZ do
		if Mod(i2r(i), i2r(addtick)) = 0
			then do
				ticks = ticks + 1
				z = Row_labels[i]
				stat = UpdateProgressBar("Closest External Station for Trip Gen, first pass, TAZ " + z, ticks)
			end

		// Row labels are strings, convert to integer to match AreaType file
		MtxTAZ[i] = s2i(Row_labels[i])
		// get index for CBDProxy while you are going through array 
		if MtxTAZ[i] = CBDProxy then CBDNdx = i
		// check external station IDs
		if i >= FirstExtStaNdx 
			then do
				for j = 1 to aExtSta.length do
					if MtxTAZ[i] = aExtSta[j] then goto gothit
				end
				// no hit
				msg = msg + {"ExtStaforTripGen: ERROR!  TAZ " + MtxTAZ[i] + " should be Ext Sta but not found in TAZ array"}
			//	AppendToLogFile(1, ""ExtStaforTripGen: ERROR!  Could not find TAZ " + CBDProxy + " in SPMAT_Free")
				ExtStaOK = 0
				gothit:
			end				 
	end

	if CBDNdx = 0 
		then do
			msg = msg + {"ExtStaforTripGen: ERROR!  Could not find TAZ " + CBDProxy + " in SPMAT_Free"}
		//	AppendToLogFile(1, ""ExtStaforTripGen: ERROR!  Could not find TAZ " + CBDProxy + " in SPMAT_Free")
			ExtStaOK = 0
		end
	 
	if ExtStaOK = 0 then goto baddone

	// check TAZ match, fill TermMinutes array
	for i = 1 to NumTAZ do

		if Mod(i2r(i), i2r(addtick)) = 0
			then do
				ticks = ticks + 1
				z = Row_labels[i]
				stat = UpdateProgressBar("Closest External Station for Trip Gen, calculating..., TAZ " + z, ticks)
			end

		// Pull vector for each row
		vRowLen = GetMatrixVector(SPMATCore, {{"Row", MtxTAZ[i]}})

		// Distance to CBD 
		if i <> CBDNdx 
			then DistToCBD[i] = vRowLen[CBDNdx]
			else DistToCBD[i] = 0
 
		// Assume external stations are last NumExtSta in row
		closest = 999.
		for j = FirstExtStaNdx to NumTAZ do
			if vRowLen[j] < closest 
				then do
					ClosestExtSta[i][1] = MtxTAZ[j]
					ClosestExtSta[i][2] = vRowLen[j]
					closest = vRowLen[j]
				end
		end
	end

	// Write Arrays
	cbdfilename = 	Dir + "\\LandUse\\Dist_to_CBD.asc"
	exist = GetFileInfo(cbdfilename)
	if (exist <> null) then DeleteFile(cbdfilename)
	cbdptr = OpenFile(cbdfilename, "w")

	extfilename = 	Dir + "\\Ext\\Dist_to_Closest_ExtSta.asc"
	exist = GetFileInfo(extfilename)
	if (exist <> null) then DeleteFile(extfilename)
	extptr = OpenFile(extfilename, "w")

	for i = 1 to NumTAZ do

		if Mod(i2r(i), i2r(addtick)) = 0
			then do
				ticks = ticks + 1
				z = Row_labels[i]
				stat = UpdateProgressBar("Closest External Station for Trip Gen, writing, TAZ " + z, ticks)
			end

		WriteLine(cbdptr, Lpad(Format(MtxTAZ[i],    "*0"),10) 
					 + Lpad(Format(CBDProxy,     "*0"),10)
					 + Lpad(Format(DistToCBD[i], "*0.000000"),10) )

		WriteLine(extptr, Lpad(Format(MtxTAZ[i],    "*0"),10) 
					 + Lpad(Format(ClosestExtSta[i][1], "*0"),10)
					 + Lpad(Format(ClosestExtSta[i][2], "*0.000000"),10) )
	end

	CloseFile(cbdptr)
	CloseFile(extptr)

	// Write asc format (.dct) files
	cbdfilename = 	Dir + "\\LandUse\\Dist_to_CBD.dct"
	exist = GetFileInfo(cbdfilename)
	if (exist <> null) then DeleteFile(cbdfilename)
	cbdptr = OpenFile(cbdfilename, "w")
	WriteLine(cbdptr, " ")
	WriteLine(cbdptr, "30")
	WriteLine(cbdptr, "\"From\",I,1,10,0,10,0,,,\"\",,,")		
	WriteLine(cbdptr, "\"To\",I,11,10,0,10,0,,,\"\",,,")		
	WriteLine(cbdptr, "\"Len\",F,21,10,0,10,6,,,\"\",,,")		
	CloseFile(cbdptr)


	extfilename = 	Dir + "\\Ext\\Dist_to_Closest_ExtSta.dct"
	exist = GetFileInfo(extfilename)
	if (exist <> null) then DeleteFile(extfilename)
	extptr = OpenFile(extfilename, "w")
	WriteLine(extptr, " ")
	WriteLine(extptr, "30")
	WriteLine(extptr, "\"From\",I,1,10,0,10,0,,,\"\",,,")		
	WriteLine(extptr, "\"To\",I,11,10,0,10,0,,,\"\",,,")		
	WriteLine(extptr, "\"Len\",F,21,10,0,10,6,,,\"\",,,")		
	CloseFile(extptr)




	goto done

	badnetview:
	showarray(msg)
	goto done

	badextsta:
	msg = msg + {"ExtStaforTripGen: " + netview + ".dbd has no external stations"}
//	AppendToLogFile(1, ""ExtStaforTripGen: " + netview + ".dbd has no external stations")
	showarray(msg)
	goto done

	badspmat:
	msg = msg + {"ExtStaforTripGen: Error opening \\Skims\\SPMAT_Free.mtx"}
//	AppendToLogFile(1, ""ExtStaforTripGen: Error opening \\Skims\\SPMAT_Free.mtx")
	showarray(msg)
	goto done

	baddone:
	showarray(msg)
	goto done


	done:
	SPMATFile = null
	SPMATMtx = null
	SPMATNdx = null
	SPMATCore = null
	Row_labels = null

	on error default
	datentime = GetDateandTime()

	DestroyProgressBar()

	AppendToLogFile(1, "ExtStaforTripGen" + datentime)
	return({ExtStaforTripGenOK, msg})
endmacro