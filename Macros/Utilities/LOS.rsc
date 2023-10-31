Macro "LOS" 

// Created by Si, May 2019
// This macro calculates the LOS of each roadway segment based on NCDOT's generic LOS table.
// Only LOS D, E, F are recorded (D is best it can be -- need to check on this)

// Currently you need to hard code in fields on your network to run macro -- need to update so that it checks if they are there and, if not, to add them
// Currenty you also need to have the VOL_POST field added to the network -- this needs to be added to macro as a join/fill
// Can possibly use another volume field (ie FORECASTVOL), which you could select (would need to make macro a dialog box)

// Currently file location is hard-coded

// Needs to be thoroughly checked


// Input file
	HwyFile = "C:\\Si\\Martin\\Matthews\\Model\\2045\\RegNet45.dbd"
	LOSLookUpFile = "C:\\Si\\Martin\\Matthews\\LOS_Lookup.csv"	

// Open highway file
	layers = RunMacro("TCB Add DB Layers", HwyFile)
	HwyLayer = layers[2]

	SetLayer(HwyLayer)
	HwyView =GetView()
	SetView(HwyView)

	//////Add new columes funcl_lu,areatp_lu,spdlimit_lu, factype
	CreateProgressBar("Calculate Roadway LOS", "False")
	stat = UpdateProgressBar("Reads Hihgway Network",0)
	
	ptr = GetFirstRecord(HwyView+"|",)
	while ptr <> null do
		hwyrec = GetRecordValues(HwyView,ptr, {"DIR", "funcl", "Lanes", "factype", "areatp", "SpdLimit"})
		dir = hwyrec[1][2]
		funcl = hwyrec[2][2]
		lanes = hwyrec[3][2]
		factype = hwyrec[4][2]
		areatype = hwyrec[5][2]
		spdlimit = hwyrec[6][2]


	// funcl
		if funcl = 1 or funcl = 8 or funcl = 9 or funcl = 22 or funcl = 23 or funcl = 24 or funcl = 25 or funcl = 82 or funcl = 83 then funcl_lu = "Freeway"	
		else if funcl = 2 then funcl_lu = "Expressway"
		else if funcl = 3 or funcl = 4 then do
			if factype = "M" then funcl_lu = "Boulevard"
			else funcl_lu ="Major"
			end
		else if funcl >= 5 and funcl <8 then funcl_lu ="Minor"	

	// area type
		if areatype<=3 then areatp_lu ="Urban"
		else if areatype = 4 then areatp_lu = "Suburban"
		else if areatype = 5 then areatp_lu = "Rural"	

	// lanes + multiplyer
		if dir = 0 then do
			if Mod(lanes,2) = 0 then do 
				lanes_lu = lanes/2
				multiplyer = 1.0
				end
			else do
				lanes_lu = 1.0
				multiplyer = lanes/2
				end
			end
		else do
			lanes_lu = lanes
			multiplyer = 1.0
			end
			
		if funcl_lu = "Freeway"	or funcl_lu = "Expressway" then do
			if lanes_lu > 4 then do
				multiplyer = lanes_lu/2
				lanes_lu = 2
				end
			end
		else if funcl_lu = "Major" and lanes_lu >3 or funcl_lu = "Boulevard" and lanes_lu >3 then do
			multiplyer = lanes_lu
			lanes_lu = 1
			end
		else if funcl_lu = "Minor" and lanes_lu >1 then do
			multiplyer = lanes_lu
			lanes_lu = 1
			end
					
	// speedlimit
		if funcl>2 and funcl <=8 then do
			if spdlimit =< 25 then spdlimit_lu = 25
			else if spdlimit =< 35 then spdlimit_lu = 35
			else if spdlimit =< 45 then spdlimit_lu = 45
			else spdlimit_lu = 55
			end
		else spdlimit_lu = 0
		


	// factype
		if funcl_lu = "Major" or funcl_lu = "Minor" then do
			if factype = "U" then factype_lu = "NO"
			else factype_lu = "YES"
			end
		else  factype_lu = "NA"
			
		SetRecordValues(HwyView, ptr,{{"funcl_lu", funcl_lu}})
		SetRecordValues(HwyView, ptr,{{"areatp_lu", areatp_lu}})
		SetRecordValues(HwyView, ptr,{{"lanes_lu", lanes_lu}})
		SetRecordValues(HwyView, ptr,{{"multiplyer", multiplyer}}) 
		SetRecordValues(HwyView, ptr,{{"spdlimit_lu", spdlimit_lu}})
		SetRecordValues(HwyView, ptr,{{"factype_lu", factype_lu}})
		
		funcl_lu = null
		areatp_lu = null
		lanes_lu = null
		multiplyer = null
		spdlimit_lu = null
		factype_lu = null
		
		ptr = GetNextRecord(HwyView + "|", null,)

	end
CloseView(HwyView)

// LOS Lookup table
stat = UpdateProgressBar("Reads LOS Lookup Table",40)
LOSView = OpenTable("LOSView", "CSV", {LOSLookUpFile,})

stat = UpdateProgressBar("Reads Highway DBD and join",45)
layers = RunMacro("TCB Add DB Layers", HwyFile)
HwyLayer = layers[2]
SetLayer(HwyLayer)
HwyView =GetView()
SetView(HwyView)
	

stat = UpdateProgressBar("Join",50)
joinVW = JoinViewsMulti("joinVW", {HwyView+".funcl_lu", HwyView+".lanes_lu", HwyView+".areatp_lu", HwyView+".factype_lu", HwyView+".spdlimit_lu"}, {"LOSView.funcl", "LOSView.lanes", "LOSView.areatype", "LOSView.factype", "LOSView.speedlimit"},{{"L",}})

SetView(joinVW)
ptr = GetFirstRecord(joinVW+"|",)
	while ptr <> null do
		joinrec = GetRecordValues(joinVW,ptr, {"Vol_Post", "LOS_D", "LOS_E", "multiplyer"})
		vol = joinrec[1][2]
		los_D = joinrec[2][2]
		los_E = joinrec[3][2]
		multiplyer = joinrec[4][2]
		
		if vol < los_D * multiplyer then SetRecordValues(joinView, ptr,{{"LOS_lu", "D"}})
		else if vol < los_E * multiplyer then SetRecordValues(joinView, ptr,{{"LOS_lu", "E"}})
		else SetRecordValues(joinView, ptr,{{"LOS_lu", "F"}})

		ptr = GetNextRecord(joinVW + "|", null,)

	end

stat = UpdateProgressBar("Close views",95)
CloseView(joinVW)
CloseView(HwyView)
CloseView(LOSView)
DestroyProgressBar()

endMacro