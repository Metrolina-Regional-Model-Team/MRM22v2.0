dbox "BufferStats" Toolbox Title: "Buffer Stats - VMT-VHT Statistics for a Project Buffer"
	init do
		sysdir = GetSystemDirectory()

		// run macros to get info on views and maps
		RunMacro("gettheviews")
		RunMacro("getthemaps")
			
		WorkingFolder = null
		
		// Map where projects are located	
		BufBaseMap = null
		BufBaseMapLayer = null
		BufBaseMapFile = null
		BufBaseMapndx = -1
		BufBaseMaplayerndx = 0

		// Project DBF file
		ProjDBFView = null
		ProjDBFFile = null
		projdbfviewndx = -1
		projdbfsetlist = null
		projdbfsetndx = -1
		selProjNum = null
		sProjNum = null
		ProjNum = 0
		MapProjSelectSet = null

		// Buffer section 
		BufWidth = 0
		sBufWidth = null
		BufferDBFile = null
		BufferView = null
		MapBufSelectSet = null
		BufferValue = null

		// no-build section
		NoBldMapLayer = null
		NoBldMapFile = null
		NoBldMaplayerndx = null
		NBTotAssnView = null
		NBTotAssnFile = null

		// Build map layer
		BuildMapLayer = null
		BuildMapFile = null
		BuildMaplayerndx = null
		BUTotAssnView = null
		BUTotAssnFile = null

		
	enditem

	// ****************************************************************************************************
	// Map to create selection sets (projects) to buffer
	// ****************************************************************************************************
	//         1         2         3         4         5         6         7         8         9
	//1234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901
	// projectmap1234567890    projlayer01234    newmapbtn0  addtomap90  filename90  clear

	Frame 1, 1, 86, 5.5 Prompt: " Base Highway Map used to create buffer " 

	// DBD where projects can be buffered
	Text " Map " 2,2
	Text " Layer " 26, same

	Popdown Menu "BufBaseMap" 2, after, 20 List: maplist Variable: BufBaseMapndx do
		if BufBaseMapndx > 0 and BufBaseMapndx <= maplist.length
			then do
				 BufBaseMap = maplist[BufBaseMapndx]
				 maplayers = GetMapLayers(BufBaseMap, "All")
				 BufBaseMaplayerlist = maplayers[1]
			end
			else do
				BufBaseMap = null
				BufBaseMaplayerlist = null
			end
	enditem	 

	Popdown Menu "bufbasemaplayer" 26, same, 14 List: BufBaseMaplayerlist Variable: BufBaseMaplayerndx do
		if BufBaseMaplayerndx > 0 and BufBaseMaplayerndx <= BufBaseMaplayerlist.length
			then do
				BufBaseMapLayer = BufBaseMaplayerlist[BufBaseMaplayerndx]
				info = GetLayerInfo(BufBaseMapLayer)
				BufBaseMapFile = info[10]
				path = SplitPath(BufBaseMapFile)
				if WorkingFolder = null 
					then do
						path = SplitPath(BufBaseMapFile)
						WorkingFolder = path[1] + path[2]
						// the splitpath command leaves the last slash on the path name.  Choose directory does not.  get rid of it
						if right(WorkingFolder, 1) = "\\" or right(WorkingFolder,1) = "\/" 
							then WorkingFolder = left(WorkingFolder, len(WorkingFolder) - 1)
					end
			end	
			else do
				BufBaseMapLayer = null
				BufBaseMapFile = null
			end
	enditem	 

	Button "bufbasemapnewmap" 44, same, 10 Prompt: " new map " Help: "Create a new base highway map to create buffers" do
		on error, escape, notfound goto badnewbufbasemap
		BufBaseMapFile = ChooseFile({{"Standard","*.dbd"}}, "Create a new base highway map to create buffers",	
				{{"Initial Directory", WorkingFolder}})

		path = SplitPath(BufBaseMapFile)
		BufBaseMapLayer = path[3]
		
		// create new map			
		BufBaseMap = "Buffer Base Map"
		info = GetDBInfo(BufBaseMapFile)
		DBDlayers = GetDBLayers(BufBaseMapFile)

		scope = info[1]
		CreateMap(BufBaseMap, {{"Scope", scope},{"Auto Project", "True"}})
		for i = 1 to DBDlayers.length do
			addlayer(BufBaseMap, DBDlayers[i], BufBaseMapFile, DBDlayers[i])
			if upper(DBDlayers[i]) = "NODE"
				then do
					SetLayerVisibility("Node", "False")
					SetIcon("Node|", "Font Character", "Caliper Cartographic|4", 36)
				end
			if upper(DBDlayers[i]) = upper(BufBaseMapLayer)
				then do
					SetLayerVisibility(BufBaseMapLayer, "True")
					solid = LineStyle({{{1, -1, 0}}})
					SetLineStyle(BufBaseMapLayer+"|", solid)
					SetLineColor(BufBaseMapLayer+"|", ColorRGB(0, 0, 0))    //Black
					SetLineWidth(BufBaseMapLayer+"|", 0)
				end
		end // for i	
				
		// all good - update view and map lists		
		message = "Buffer Base Map created, file= " + BufBaseMapFile
		PlaySound(sysdir + "\\media\\Windows Notify.wav", "null")

		RunMacro("gettheviews")
		RunMacro("getthemaps")
		for i = 1 to maplist.length do
			if upper(maplist[i]) = upper(BufBaseMap) 
				then do 
					BufBaseMapndx = i
					maplayers = GetMapLayers(BufBaseMap, "All")
					BufBaseMaplayerlist = maplayers[1]
					BufBaseMaplayerndx = GetLayerPosition(BufBaseMap, BufBaseMapLayer)
					BufBaseMapLayer = BufBaseMaplayerlist[BufBaseMaplayerndx]
				end
		end
		WorkingFolder = path[1] + path[2]
		// the splitpath command leaves the last slash on the path name.  Choose directory does not.  get rid of it
		if right(WorkingFolder, 1) = "\\" or right(WorkingFolder,1) = "\/" 
			then WorkingFolder = left(WorkingFolder, len(WorkingFolder) - 1)
		goto goodnewbufbasemap	 		
 		
 		badnewbufbasemap:
			message = "Error opening new base map"
			PlaySound(sysdir + "\\media\\Windows Critical Stop.wav", "null")
		goodnewbufbasemap:	 
			on error, escape, notfound default
	enditem

	Button "bufbasemapaddtomap" 56, same, 10 Prompt: " add to map " Help: "Add a base highway DBD to existing map " do
		message = null
		on error, escape, notfound goto badaddbufbasemap

		BufBaseMapFile = ChooseFile({{"Standard","*.dbd"}}, "Select DBD to add to map",	
				{{"Initial Directory", WorkingFolder}})

		path = SplitPath(BufBaseMapFile)
		BufBaseMapLayer = path[3]
		
		// add to map
		DBDlayers = GetDBLayers(BufBaseMapFile)

		scope = info[1]
		for i = 1 to DBDlayers.length do
			addlayer(BufBaseMap, DBDlayers[i], BufBaseMapFile, DBDlayers[i])

			if upper(DBDlayers[i]) = "NODE"
				then do
					SetLayerVisibility("Node", "False")
						SetIcon("Node|", "Font Character", "Caliper Cartographic|4", 36)
				end
			if upper(DBDlayers[i]) = upper(BufBaseMapLayer)
				then do
					SetLayerVisibility(BufBaseMapLayer, "True")
					solid = LineStyle({{{1, -1, 0}}})
					SetLineStyle(BufBaseMapLayer+"|", solid)
					SetLineColor(BufBaseMapLayer+"|", ColorRGB(0, 0, 0))    //Black
					SetLineWidth(BufBaseMapLayer+"|", 0)
				end
		end  // for i
				
		// all good - update view and map lists		
		message = "Base Buffer DBD added to map    "
		PlaySound(sysdir + "\\media\\Windows Notify.wav", "null")

		RunMacro("gettheviews")
		RunMacro("getthemaps")
		for i = 1 to maplist.length do
			if upper(maplist[i]) = upper(BufBaseMap) 
				then do 
					BufBaseMapndx = i
					maplayers = GetMapLayers(BufBaseMap,"All")
					BufBaseMaplayerlist = maplayers[1]
					BufBaseMaplayerndx = GetLayerPosition(BufBaseMap, BufBaseMapLayer)
					BufBaseMapLayer = BufBaseMaplayerlist[BufBaseMaplayerndx]
				end
		end
		WorkingFolder = path[1] + path[2]
		// the splitpath command leaves the last slash on the path name.  Choose directory does not.  get rid of it
		if right(WorkingFolder, 1) = "\\" or right(WorkingFolder,1) = "\/" 
			then WorkingFolder = left(WorkingFolder, len(WorkingFolder) - 1)

		goto goodaddbufbasemap
		
		badaddbufbasemap:
			message = message + "Error adding base to existing map"
			PlaySound(sysdir + "\\media\\Windows Critical Stop.wav", "null")

		goodaddbufbasemap:	
			on error, escape, notfound default
	enditem  // button bufbasemapaddtomap			

	Button "showbufbasemapfile" 68, same, 10 Prompt: "file name" do
		message = "Select set dbd: " + BufBaseMapFile
		PlaySound(sysdir + "\\media\\Windows Notify.wav", "null")
	enditem
	
	Button "clearBufBaseMap" 80, same, 5 Prompt: " clear " Help: "Clear all base buffer map entries" do
		// Map where projects are located	
		BufBaseMap = null
		BufBaseMapLayer = null
		BufBaseMapFile = null
		BufBaseMapndx = -1
		BufBaseMaplayerndx = null
		WorkingFolder = null
		
		// run macros to get info on views and maps
		RunMacro("gettheviews")
		RunMacro("getthemaps")

		message = "Cleared Base Buffer Map View!"
	enditem

	// Buffer file working folder - buffer files will be stored here.  Reports in a subfolder 
	Text 22, after, 32 Variable: WorkingFolder Prompt: "Folder for buffer files" Framed
	
	Button "changeworkingfolder" 68, same, 16 Prompt: "change folder" Help: "Folder where buffer files will be written" do
		on error, notfound, escape goto badchangefolder
		WorkingFolder = ChooseDirectory("Folder for buffer files   ",{{"Initial Directory", WorkingFolder}})	
		if WorkingFolder = null
			then do
				path = SplitPath(BufBaseMapFile)
				WorkingFolder = path[1] + path[2]
				// the splitpath command leaves the last slash on the path name.  Choose directory does not.  get rid of it
				if right(WorkingFolder, 1) = "\\" or right(WorkingFolder,1) = "\/" 
					then WorkingFolder = left(WorkingFolder, len(WorkingFolder) - 1)
				message = "Working folder not chosen, base highway folder defaults"
				PlaySound(sysdir + "\\media\\Windows Critical Stop.wav", "null")
				end
		goto goodchangefolder
		badchangefolder:
		message = "Error trying to reset working folder"
		PlaySound(sysdir + "\\media\\Windows Critical Stop.wav", "null")
		goodchangefolder:
		on error, notfound, escape default
	enditem
	
	// ****************************************************************************************************
	//  Project .dbf section
	//*****************************************************************************************************

	Frame 1, 7.0, 86, 6.5 Prompt: " MRM Network Project .dbf file "
	Text " .dbf view " 2, 8.0
	Text " Set Name " 26, same
	
	Popdown Menu "projdbfview" 2, after, 20 List: viewlist Variable: projdbfviewndx Help: "Open projects dbf file" do
		if projdbfviewndx > 0 and projdbfviewndx <= viewlist.length
			then do
				ProjDBFView = viewsinfo[projdbfviewndx][1]
				ProjDBFFile = viewsinfo[projdbfviewndx][2]
				projdbfsetlist = {"none"} + GetSets(ProjDBFView)
				projdbfsetndx = -1
			end	
			else do
				ProjDBFView = null
				ProjDBFFile = null
				projdbfsetlist = null
				projdbfsetndx = -1
				message = "Project DBF view not found!"
				PlaySound(sysdir + "\\media\\Windows Critical Stop.wav", "null")
			end	
	enditem

	// Choose a selection set of the project dbf for list
	Popdown Menu "projdbfset" 26, same, 14 List: projdbfsetlist Variable: projdbfsetndx do
		if projdbfsetndx > 0 and projdbfsetndx <= projdbfsetlist.length
			then ProjDBFSet = projdbfsetlist[projdbfsetndx]
			else do
				ProjDBFSet = null
				projdbfsetlist = {"none"} + GetSets(ProjDBFView)
				projdbfsetndx = -1
				goto retrysets
			end
					
		if ProjDBFSet = "none" 
			then ProjDBFSet = null
			
		projectlist = null 
		rec = GetFirstRecord(ProjDBFView + "|" + ProjDBFSet,)
		while rec <> null do				
			recval = GetRecordValues(ProjDBFView, rec, {"Index", "MTP45_NO","TIP_NO" ,"Project", "Limits", "Type", "County"}) 
			p1 = Format(recval[1][2], "0000")
			p2 = i2s(recval[2][2])
			p3 = recval[3][2]
			if p3 = null
				then p3out = "TIP n/a"
				else p3out = "TIP " + p2 
			p4 = recval[4][2]
			p5 = recval[5][2]
			p6 = recval[6][2]
			p6 = recval[7][2]
			projstring = p1 + ",  " + p2 + ",  " +  p3out + ",  " + p4 + ",  " + p5 + ",  " + p6 + ",  " + p7
			projectlist = projectlist + {left(projstring,140)}
			rec = GetNextRecord(ProjDBFView + "|" + ProjDBFSet, null,)
		end // while
		if projectlist <> null then selProjNum = projectlist[1]
		retrysets:
	enditem

	Button "getprojdbffile" 56, same, 10 Prompt: "open file" Help: "Open projects dbf file" do
		message = null
		on error, escape, notfound goto badprojdbffile
		ProjDBFFile = ChooseFile({{"DBase files","*.dbf"}},"Projects dbf file",	
				{{"Initial Directory", WorkingFolder}})

		// Open table
		ProjDBFView = OpenTable("ProjDBFView", "DBASE", {ProjDBFFile,})
		
		// light gray (49300,49300,49300
		SetView(ProjDBFView)
		viewfields = GetViewStructure(ProjDBFView)
		checkfields = {"Index", "TIP_NO", "Project", "Limits", "Type", "County", "ProjectSet"}
		for i = 1 to checkfields.length do
			hit = 0
			for j = 1 to viewfields.length do
				if upper(checkfields[i]) = upper(viewfields[j][1]) then hit = 1
			end  // for j
			if hit = 0 
				then do
					message = "MRM Project File does not contain field: " + checkfields[i] + "   "
					goto badprojdbffile
				end // hit = 0
		end  // for i

		ProjDBFEditor = CreateEditor("Project DBF", ProjDBFView + "|",
					{"Index", "TIP_NO" ,"Project", "Limits", "Type","County","ProjectSet"}, 
					{{"Position", 0, 10}, 
					 {"Row BackGround Color", ColorRGB(50600,65000,44200)},   //pale green
					 {"Size", 90, 25}, 
					 {"Read Only", "False"}, 
					 {"Title", "ProjDBFView"},
					 {"Show Sets", "True"}}) 

		// all good - update view lists		
		message = "Project DBF opened: " + ProjDBFFile
		PlaySound(sysdir + "\\media\\Windows Notify.wav", "null")

		RunMacro("gettheviews")
		//	viewsinfo (view, file, filetype, viewlayer viewlayertype)
		projdbfviewndx = -1
		for i = 1 to viewsinfo.length do
			if upper(viewsinfo[i][1]) = upper(ProjDBFView) 
				then projdbfviewndx = i
		end
		goto goodprojdbffile
		
		badprojdbffile:
		message = message + "Error opening MRM project DBF"
		PlaySound(sysdir + "\\media\\Windows Critical Stop.wav", "null")

		goodprojdbffile:
		on error, escape, notfound default	
	enditem  // button getprojdbffile			

	Button "showprojdbffile" 68, same, 10 Prompt: "file name" do
		message = "Project dbf file: " + ProjDBFFile
		PlaySound(sysdir + "\\media\\Windows Notify.wav", "null")
	enditem

	Button "clearprojdbf" 80, same, 5 Prompt: " clear " Help: "Clear project dbf entries" do
		// Project .dbf variables
		ProjDBFView = null
		ProjDBFFile = null
		projdbfviewndx = -1
		projdbfsetlist = null
		projdbfsetndx = -1
		selProjNum = null
		sProjNum = null
		ProjNum = 0
		MapProjSelectSet = null
		MapBufSelectSet = null

		// run macros to get info on views and maps
		RunMacro("gettheviews")
		RunMacro("getthemaps")

		message = "Cleared Project dbf section"
	enditem

	//  Select project 
	// Editable popdown - so you can type a number in - returns value rather than index to value
	Text " Choose project or type proj num " 2, after
	Popdown Menu "projpick" 2, after, 82 List: projectlist Variable: selProjNum Editable do
		message = null
		if BufBaseMapLayer = null
			then do
			    message = "Select project - No base highway map to select from!   "
				goto badprojpick
			end

		if selProjNum = null
			then do
				message = "Select project - No Project selected!   "
				goto badprojpick
			end

		// extract project number (4 digits max)
		projnumlen = min(len(selProjNum), 4)
		sProjNum = left(selProjNum, r2i(projnumlen))
		ProjNum = s2i(sProjNum)
		
		if ProjNum = 0
			then do
				message = "Select project - cannot use project index!   "
				goto badprojpick
			end

		// Make sure select set view has the fields 
		SetView(BufBaseMapLayer)
		viewfields = GetViewStructure(BufBaseMapLayer)
		checkfields = {"projnum1", "projnum2", "projnum3"}
		for i = 1 to checkfields.length do
			hit = 0
			for j = 1 to viewfields.length do
				if upper(checkfields[i]) = upper(viewfields[j][1]) then hit = 1
			end  // for j
			if hit = 0 
				then do
					message = "Base Highway Map does not contain field: " + checkfields[i] + "   "
					goto badprojpick
				end // hit = 0
		end  // for i
		
		// query line file for project
		projquery = "select * where projnum1 = " + sProjNum + " or projnum2 = " + sProjNum + " or projnum3 = " + sProjNum
		MapProjSelectSet = "Proj" + sProjNum
		nproj = SelectByQuery(MapProjSelectSet, "Several", projquery)
		if nproj < 1 
			then do
				message = "Select project - Project not found in " + BufBaseMapLayer + "   "
				goto badprojpick
			end

		// zoom to project
		SetLineWidth(BufBaseMapLayer + "|" + MapProjSelectSet, 2.5) 
		SetLineColor(BufBaseMapLayer + "|" + MapProjSelectSet, ColorRGB(32768,0,16384)) 
		SetDisplayStatus(BufBaseMapLayer + "|" + MapProjSelectSet, "Active")
		SetSelectDisplay("True")
		SetMapScope(,GetSetScope(MapProjSelectSet))
		RedrawMap()
		
		message = MapProjSelectSet + " selected, " + i2s(nproj) + " links"
		BufBaseMapselectlist = GetSets(BufBaseMapLayer)
		MapBufSelectSet = MapProjSelectSet

		// project data for report
		curview = GetView()
		SetView(ProjDBFView)
		projptr = LocateRecord(ProjDBFView + "|", "Index", {ProjNum},)						
		ProjInfo = GetRecordValues(ProjView, linkptr, {"Index", "MTP45_NO", "TIP_NO" ,"Project", "Limits", "Type", "County"})
		ProjHeader = {i2s(ProjInfo[1][2]), i2s(ProjInfo[2][2]), ProjInfo[3][2], ProjInfo[4][2], ProjInfo[5][2], ProjInfo[6][2], ProjInfo[7][2]}
		SetView(curview)

		goto goodprojpick
		
		badprojpick:
			PlaySound(sysdir + "\\media\\Windows Critical Stop.wav", "null")

		goodprojpick:
		on error, escape, notfound default	
	enditem  // popdown menu projpick			

	// ****************************************************************************************************
	//  Buffer section
	//*****************************************************************************************************

	Frame 1, 14.0, 86, 6.5 prompt: " Create Buffer "
	Text " Buffer this set " 2, 15.0
	Text " Buffer size (mi) " 26, same
	Text " 123&4 mi. " 44, same
	
	Popdown Menu "bufferset" 2, after, 20 List: BufBaseMapselectlist Variable: MapBufSelectSet Editable do
		message = null
		if BufBaseMapLayer = null
			then do
			    message = "Create Buffer - No base highway map to build buffer!   "
				goto badbufferset
			end
		if MapBufSelectSet = null
			then do
				message = "Create Buffer - No Buffer layer selected!   "
				goto badbufferset
			end
		goto goodbufferset
		
		badbufferset:
			PlaySound(sysdir + "\\media\\Windows Critical Stop.wav", "null")
		goodbufferset:
	enditem  // popdown buffer set			



	Spinner "BufferSpinner" 28, same, 8  List: SpinnerList Variable: sBufWidth do
		BufWidth = s2r(sBufWidth)
		SpinnerList = RunMacro("BuildBufferSpinnerList", BufWidth, 1.0, 1.0, 10.0)
		
		if BufWidth > 0 then buffer1234 = 0
		
		RunMacro("gettheviews")
	endItem

	Checkbox " " 48, same Variable: buffer1234 Help: "Check box to build buffers of 1, 2, 3, & 4 miles" do
		if buffer1234 = 1
			then do
				BufWidth = 0
				sBufWidth = null
			end
		RunMacro("gettheviews")
	enditem

	Button " Create Buffer " 68, same, 16 do
		message = null
		on error, escape, notfound goto badcreatebuffer

		// empty buffer
		if MapBufSelectSet = null
			then do 
				message = {"Create Buffer - No Selection set chosen!  "}
				goto badcreatebuffer
			end
		nsel = GetRecordCount(BufBaseMapLayer,MapBufSelectSet)
		if nsel < 1
			then do
				message = {"Create Buffer - Zero records in selection  "}
				goto badcreatebuffer
			end
		// If buffer1234 is checked - name is buffer_1234mi
		if buffer1234 = 1
			then do
				BufferView = MapBufSelectSet + "_Buf1234mi"
				BufferValue = {1.0, 2.0, 3.0, 4.0}
			end
			else do
				BufferView = MapBufSelectSet + "_Buf" + sBufWidth + "mi"
				BufferValue = {BufWidth}
			end

		BufferDBFile = WorkingFolder + "\\" + BufferView + ".dbd"
		CreateBuffers(BufferDBFile, BufferView, {MapBufSelectSet}, "Value", BufferValue, {{"Exterior", "Merged"}})
		BufferView = AddLayer(,BufferView, BufferDBFile, BufferView, {{"Shared", "False"}, {"ReadOnly", "False"}})
		SetBorderWidth(BufferView + "|", 1.5) 
		SetBorderColor(BufferView + "|", ColorRGB(49152,36864,0))
		SetBorderStyle(BufferView + "|", widedashedline)
		SetMapScope(,GetLayerScope(BufferView))
		redrawmap()

//		// Queries for multi buffers
		SetView(BufferView)
		bquery = "select * where Width = 1"
		nband1 = SelectByQuery("BBand1", "Several", bquery,)
		bquery = "select * where Width = 2"
		nband2 = SelectByQuery("BBand2", "Several", bquery,)
		bquery = "select * where Width = 3"
		nband3 = SelectByQuery("BBand3", "Several", bquery,)
		bquery = "select * where Width = 4"
		nband4 = SelectByQuery("BBand4", "Several", bquery,)
		SetView(BufBaseMap)




		goto goodcreatebuffer

		badcreatebuffer:
			PlaySound(sysdir + "\\media\\Windows Critical Stop.wav", "null")
		goodcreatebuffer:
		on error, escape, notfound default
	EndItem


	// add buffer to map - this is different than creating one
	Text " Buffer View " 2,after
	Text 2, after, 50 Variable: BufferView Framed 

	Button "bufferaddtomap" 56, same, 10 Prompt: " add to map " Help: "Add buffer DBD to base map " do
		on error, notfound, escape goto badaddbuffer
		message = null
		// No map selected to add DBD
		BufferDBFile = ChooseFile({{"Standard","*.dbd"}}, "Choose buffer file to add to map",	
				{{"Initial Directory", WorkingFolder}})
		path = SplitPath(BufferDBFile)
		BufferView = path[3]
			
		// add to map
		info = GetDBInfo(BufferDBFile)
		DBDlayers = GetDBLayers(BufferDBFile)
		scope = info[1]
		for i = 1 to DBDlayers.length do
			addlayer(BufBaseMap, DBDlayers[i], BufferDBFile, DBDlayers[i])

			if upper(DBDlayers[i]) = upper(BufferView)
				then do
					SetLayerVisibility(BufferView, "True")
					SetBorderWidth(BufferView + "|", 1.5) 
					SetBorderColor(BufferView + "|", ColorRGB(49152,36864,0))
					SetBorderStyle(BufferView + "|", widedashedline)
					SetMapScope(,GetLayerScope(BufferView))
					redrawmap()
				end
		end  // for i
				
		// all good -  clear the create buffeupdate view and map lists		
		MapBufSelectSet = null
		sBufWidth = null
		BufWidth = 0
		buffer1234 = 0
		
		message = "Buffer DBD added to map "
		PlaySound(sysdir + "\\media\\Windows Notify.wav", "null")

		RunMacro("gettheviews")
		RunMacro("getthemaps")
//		BufferViewndx = -1		
//		for i = 1 to BufBaseMaplayerlist.length do
//			if upper(BufferView) = upper(BufBaseMaplayerlist[i])
//				then BufferViewndx = i
//		end		
		goto goodaddbuffer
		
		badaddbuffer:
			message = message + "Error adding buffer view to existing map"
			PlaySound(sysdir + "\\media\\Windows Critical Stop.wav", "null")

		goodaddbuffer:	
			on error, escape, notfound default
	enditem  // button bufferaddtomap			

	Button "showbufferfile" 68, same, 10 Prompt: "file name" do
		message = "Buffer dbd: " + BufferDBFile
		PlaySound(sysdir + "\\media\\Windows Notify.wav", "null")
	enditem

	Button "clearbuff" 80, same, 5 Prompt: " clear " Help: "Clear buffer entries" do
		
		BufWidth = 0
		sBufWidth = null
		BufferDBFile = null
		BufferView = null
		MapBufSelectSet = null
		BufferValue = null
		
		// run macros to get info on views and maps
		RunMacro("gettheviews")
		RunMacro("getthemaps")
		message = "Cleared buffer section"
	enditem

	// ****************************************************************************************************
	// VMT - VHT  Report	
	// ****************************************************************************************************
	//  NOBUILD network and tot_assn
	//*****************************************************************************************************

	Frame 1, 21.0, 86, 6.0 Prompt: " NO BUILD network "

	// NoBuild DBD - for buffer - Must be on base map to apply buffer

	Popdown Menu "nobldmaplayer" 2, 22.5, 14 List: BufBaseMaplayerlist Variable: NoBldMaplayerndx do
		if NoBldMaplayerndx > 0 and NoBldMaplayerndx <= BufBaseMaplayerlist.length
			then do
				NoBldMapLayer = BufBaseMaplayerlist[NoBldMaplayerndx]
				info = GetLayerInfo(NoBldMapLayer)
				NoBldMapFile = info[10]
			end	
			else do
				NoBldMapLayer = null
				NoBldMapFile = null
			end	
	enditem	 

	Button "nobldaddtomap" 56, same, 10 Prompt: " add to map " Help: "Add no build highway DBD to base map " do
		on error, notfound, escape goto badaddnobld
		message = null
		// No map selected to add DBD
		NoBldMapFile = ChooseFile({{"Standard","*.dbd"}}, "Select DBD to add to map",	
				{{"Initial Directory", WorkingFolder}})
		path = SplitPath(NoBldMapFile)
		NoBldMapLayer = path[3]
			
		// add to map
		info = GetDBInfo(NoBldMapFile)
		DBDlayers = GetDBLayers(NoBldMapFile)
		scope = info[1]
		for i = 1 to DBDlayers.length do
			addlayer(BufBaseMap, DBDlayers[i], NoBldMapFile, DBDlayers[i])

			if upper(DBDlayers[i]) = "NODE"
				then do
					SetLayerVisibility("Node", "False")
						SetIcon("Node|", "Font Character", "Caliper Cartographic|4", 36)
				end
			if upper(DBDlayers[i]) = upper(NoBldMapLayer)
				then do
					SetLayerVisibility(NoBldMapLayer, "True")
					solid = LineStyle({{{1, -1, 0}}})
					SetLineStyle(NoBldMapLayer+"|", solid)
					SetLineColor(NoBldMapLayer+"|", ColorRGB(39320, 26215, 13100))    //Brown
					SetLineWidth(NoBldMapLayer+"|", 0)
				end
		end  // for i
				
		// all good - update view and map lists		
		message = "No Build DBD added to map "
		PlaySound(sysdir + "\\media\\Windows Notify.wav", "null")

		RunMacro("gettheviews")
		RunMacro("getthemaps")
		NoBldMaplayerndx = -1
		for i = 1 to BufBaseMaplayerlist.length do
			if upper(BufBaseMaplayerlist[i]) = upper(NoBldMapLayer) 
				then NoBldMaplayerndx = i
		end		
		goto goodaddnobld
		
		badaddnobld:
			message = message + "Error adding no build network to existing map"
			PlaySound(sysdir + "\\media\\Windows Critical Stop.wav", "null")

		goodaddnobld:	
			on error, escape, notfound default
	enditem  // button nobldaddtomap			

	Button "shownobldmapfile" 68, same, 10 Prompt: "file name" do
		message = "No Build dbd: " + NoBldMapFile
		PlaySound(sysdir + "\\media\\Windows Notify.wav", "null")
	enditem
	
	Button "clearNoBld" 80, same, 5 Prompt: " clear " Help: "Clear all no build file entries" do
		// No build map layer
		NoBldMapLayer = null
		NoBldMapFile = null
		NoBldMaplayerndx = null
				
		// run macros to get info on views and maps
		RunMacro("gettheviews")
		RunMacro("getthemaps")

		// need to close tot_assn if open
		for i = 1 to viewlist.length do
			if upper(viewlist[i] = NBTotAssnView)
				then do
					CloseView(NBTotAssnView)
					goto closednbview
				end
		end
		closednbview:
		NBTotAssnView = null
		NBTotAssnFile = null

		message = "Cleared No Build Map View!"
	enditem

	//  No Build TotAssn - Open file, but not editor
	Text " No Build Tot_Assn File " 2, after
	Text "nbtotassn" 2, after, 52 variable: NBTotAssnFile Help: "NO BUILD HOT highway assn tot_assn.bin" Framed

	Button "getnbtotassn" 56, same, 10 Prompt: "open file" Help: "Select NO BUILD HOT highway assignment tot_assn file" do
		on error, escape, notfound goto badnbtotassn
		NBTotAssnFile = ChooseFile({{"Fixed format binary (.bin)","*.bin"}},
								 "Select NO BUILD HOT highway assignment tot_assn file",	
								 {{"Initial Directory", WorkingFolder}})

		// Open table
		NBTotAssnView = OpenTable("NBTotAssnView", "FFB", {NBTotAssnFile,})
		goto goodnbtotassn

		badnbtotassn:
			message = "No Build Tot_Assn - Error Opening File"
			PlaySound(sysdir + "\\media\\Windows Critical Stop.wav", "null")
		goodnbtotassn:
		on error, notfound, escape default	
		RunMacro("gettheviews")
	enditem  // button getnbtotassn			

//	Button " Buffer NoBuild " 68, same, 16 do
//		message = null
//		on error, escape, notfound goto badbuffernobld
//		
//		goto goodbuffernobld
//		badbuffernobld:
//		goodbuffernobld:
//	enditem

	// ****************************************************************************************************
	//  BUILD network and tot_assn
	//*****************************************************************************************************

	Frame 1, 27.5, 86, 6.0 Prompt: " BUILD network "

	// Build DBD - for buffer - Must be on base map to apply buffer

	Popdown Menu "buildmaplayer" 2, 29.0, 14 List: BufBaseMaplayerlist Variable: BuildMaplayerndx do
		if BuildMaplayerndx > 0 and BuildMaplayerndx <= BufBaseMaplayerlist.length
			then do
				BuildMapLayer = BufBaseMaplayerlist[BuildMaplayerndx]
				info = GetLayerInfo(BuildMapLayer)
				BuildMapFile = info[10]
			end	
			else do
				BuildMapLayer = null
				BuildMapFile = null
			end
	enditem	 

	Button "buildaddtomap" 56, same, 10 Prompt: " add to map " Help: "Add Build highway DBD to base map " do
		on error, notfound, escape goto badaddbuild
		message = null
		// No map selected to add DBD
		BuildMapFile = ChooseFile({{"Standard","*.dbd"}}, "Select DBD to add to map",	
				{{"Initial Directory", WorkingFolder}})
		path = SplitPath(BuildMapFile)
		BuildMapLayer = path[3]
			
		// add to map
		info = GetDBInfo(BuildMapFile)
		DBDlayers = GetDBLayers(BuildMapFile)
		scope = info[1]
		for i = 1 to DBDlayers.length do
			addlayer(BufBaseMap, DBDlayers[i], BuildMapFile, DBDlayers[i])

			if upper(DBDlayers[i]) = "NODE"
				then do
					SetLayerVisibility("Node", "False")
						SetIcon("Node|", "Font Character", "Caliper Cartographic|4", 36)
				end
			if upper(DBDlayers[i]) = upper(BuildMapLayer)
				then do
					SetLayerVisibility(BuildMapLayer, "True")
					solid = LineStyle({{{1, -1, 0}}})
					SetLineStyle(BuildMapLayer+"|", solid)
					SetLineColor(BuildMapLayer+"|", ColorRGB(10000, 10000, 65535))    //Blue
					SetLineWidth(BuildMapLayer+"|", 0)
				end
		end  // for i
				
		// all good - update view and map lists		
		message = "Build DBD added to map "
		PlaySound(sysdir + "\\media\\Windows Notify.wav", "null")

		RunMacro("gettheviews")
		RunMacro("getthemaps")
		BuildMaplayerndx = -1
		for i = 1 to BufBaseMaplayerlist.length do
			if upper(BuildMapLayer) = upper(BufBaseMaplayerlist[i])
				then BuildMaplayerndx = i
		end		
		goto goodaddbuild
		
		badaddbuild:
			message = message + "Error adding Build network to existing map"
			PlaySound(sysdir + "\\media\\Windows Critical Stop.wav", "null")

		goodaddbuild:	
			on error, escape, notfound default
	enditem  // button buildaddtomap			

	Button "showbuildmapfile" 68, same, 10 Prompt: "file name" do
		message = "Build dbd: " + BuildMapFile
		PlaySound(sysdir + "\\media\\Windows Notify.wav", "null")
	enditem
	
	Button "clearBuild" 80, same, 5 Prompt: " clear " Help: "Clear all build file entries" do
		// Build map layer
		BuildMapLayer = null
		BuildMapFile = null
		BuildMaplayerndx = null
				
		// run macros to get info on views and maps
		RunMacro("gettheviews")
		RunMacro("getthemaps")

		// need to close tot_assn if open
		for i = 1 to viewlist.length do
			if upper(viewlist[i] = BUTotAssnView)
				then do
					CloseView(BUTotAssnView)
					goto closedbuview
				end
		end
		closedbuview:
		BUTotAssnView = null
		BUTotAssnFile = null

		message = "Cleared Build Map View!"
	enditem

	//  Build TotAssn - Open file, but not editor
	Text " Build Tot_Assn File " 2, after
	Text "butotassn" 2, after, 52 variable: BUTotAssnFile Help: "BUILD HOT highway assn tot_assn.bin" Framed

	Button "getbutotassn" 56, same, 10 Prompt: "open file" Help: "Select BUILD HOT highway assignment tot_assn file" do
		on error, escape, notfound goto badbutotassn
		BUTotAssnFile = ChooseFile({{"Fixed format binary (.bin)","*.bin"}},
								 "Select BUILD HOT highway assignment tot_assn file",	
								 {{"Initial Directory", WorkingFolder}})

		// Open table
		BUTotAssnView = OpenTable("BUTotAssnView", "FFB", {BUTotAssnFile,})
		goto goodbutotassn

		badbutotassn:
			message = "Build Tot_Assn - Error Opening File"
			PlaySound(sysdir + "\\media\\Windows Critical Stop.wav", "null")
		goodbutotassn:
		on error, notfound, escape default	
		RunMacro("gettheviews")
	enditem  // button getbutotassn			


	//****************************************************************************************************************
	// Create Buffer statistic VMT/VHT report 
	//****************************************************************************************************************
	// select links from NoBuild and Build networks using buffer (selectbyvicinity) - export file of link IDs  
	// vmt_vht_report creates data files of buffered links and a report

	Text " " same, after, , 0.5
	Edit Text "syear" 16, after, 20 variable: rptyear prompt: "Base year for No Build" Help: "Year of analysis for report file" 
	
	Button " Buffer Stats" 40, same, 15 do

		// Links files
		NBLinksFile = WorkingFolder + "\\" + BufferView + "_NBLinks.asc"
		BULinksFile = WorkingFolder + "\\" + BufferView + "_BULinks.asc"

		// temp files with linkID - all links and selection sets from other bandwidths
		templinksfile = WorkingFolder + "\\templinks.asc"
		tempfile4 = WorkingFolder + "\\templinks4.asc"
		tempfile3 = WorkingFolder + "\\templinks3.asc"
		tempfile2 = WorkingFolder + "\\templinks2.asc"
		tempfile1 = WorkingFolder + "\\templinks1.asc"

		// Header Info
		
		
		info = GetFileInfo(NoBldMapFile)
		nbdate = info[7]
		info = GetFileInfo(BuildMapFile)
		budate = info[7]
		HeaderInfo = ProjHeader + {rptyear, NoBldMapLayer, NoBldMapFile, nbdate, BuildMapLayer, BuildMapFile, budate} 

//		HeaderInfo = {"Index", "TIP_NO" ,"Project", "Limits", "Type", "County"
//                     rptyear, NoBldMapLayer, NoBldMapFile, nbdate, BuildMapLayer, BuildMapFile, budate}


		// NOBUILD network
		
		SetView(NoBldMapLayer)
			
		// clear sets
		set_list = GetSets(NoBldMapLayer)
		for i = 1 to set_list.length do
			if upper(set_list[i]) <> "SELECTION" then deleteset(set_list[i])
		end
		
		// Conditions for culling out non-highway links 
		cullvar = NoBldMapLayer + ".funcl"
		cullset = "select * where (" + cullvar + " > 0 and " + cullvar + " < 30) or " + cullvar + " = 82 or " + cullvar + " = 83"


		// export all links to temp file - ID only, add field BandID
		ExportView(NoBldMapLayer + "|", "FFA", templinksfile , {"ID"},)

		// Add BandID to temp file
		templinks = OpenTable("templinks", "FFA", {templinksfile,})
		strct = GetTableStructure("templinks")
		for i = 1 to strct.length do
	   		strct[i] = strct[i] + {strct[i][1]}
		end
		new_struct = strct + {{"BandID", "INTEGER", 10, 0, "False",,,,null}}
		ModifyTable("templinks", new_struct)

		if nband4 > 0 
			then do
				nNBBuff4 = SelectByVicinity("NBBuff4", "Several", BufferView + "|BBand4", , {{"Inclusion", "Intersecting"}})
				SetLineColor(NoBldMapLayer +  "|NBBuff4", ColorRGB(65535, 32896, 0))	
				SetDisplayStatus(NoBldMapLayer +  "|NBBuff4", "Active")
				if nNBBuff4 > 0 
					then do
						nNBBuff4a = SelectByQuery("NBBuff4a", "Several", cullset, {{"Source And", "NBBuff4"}})
						if nNBBuff4a > 0
							then ExportView(NoBldMapLayer + "|NBBuff4a", "FFA", tempfile4, {"ID"},)
					end // nNBBuff4 > 0
			end 

		if nband3 > 0 
			then do
				nNBBuff3 = SelectByVicinity("NBBuff3", "Several", BufferView + "|BBand3", , {{"Inclusion", "Intersecting"}})
				SetLineColor(NoBldMapLayer +  "|NBBuff3", ColorRGB(0, 0, 65535))	
				SetDisplayStatus(NoBldMapLayer +  "|NBBuff3", "Active")
				if nNBBuff3 > 0 
					then do
						nNBBuff3a = SelectByQuery("NBBuff3a", "Several", cullset, {{"Source And", "NBBuff3"}})
						if nNBBuff3a > 0
							then ExportView(NoBldMapLayer + "|NBBuff3a", "FFA", tempfile3, {"ID"},)
					end // nNBBuff3 > 0
		end 

		if nband2 > 0 
			then do
				nNBBuff2 = SelectByVicinity("NBBuff2", "Several", BufferView + "|BBand2", , {{"Inclusion", "Intersecting"}})
				SetLineColor(NoBldMapLayer +  "|NBBuff2", ColorRGB(0, 65535, 0))	
				SetDisplayStatus(NoBldMapLayer +  "|NBBuff2", "Active")
				if nNBBuff2 > 0 
					then do
						nNBBuff2a = SelectByQuery("NBBuff2a", "Several", cullset, {{"Source And", "NBBuff2"}})
						if nNBBuff2a > 0
							then ExportView(NoBldMapLayer + "|NBBuff2a", "FFA", tempfile2, {"ID"},)
					end // nNBBuff2 > 0
			end 

		if nband1 > 0 
			then do
				nNBBuff1 = SelectByVicinity("NBBuff1", "Several", BufferView + "|BBand1", , {{"Inclusion", "Intersecting"}})
				SetLineColor(NoBldMapLayer +  "|NBBuff1", ColorRGB(32896, 0, 65535))	
				SetDisplayStatus(NoBldMapLayer +  "|NBBuff1", "Active")
				if nNBBuff1 > 0 
					then do
						nNBBuff1a = SelectByQuery("NBBuff1a", "Several", cullset, {{"Source And", "NBBuff1"}})
						if nNBBuff1a > 0
							then ExportView(NoBldMapLayer + "|NBBuff1a", "FFA", tempfile1, {"ID"},)
					end // nNBBuff1 > 0
		end 

		RedrawMap()
	
		// reopen temp files and join 1 at a time to temp file with all links
		//  join from outer band to inner - if link is in both, it will be assigned to inner band
		temp4 = OpenTable("temp4", "FFA", {tempfile4,})
		Join4 = JoinViews("Join4", templinks + ".ID", temp4 + ".ID",)
		SetView(Join4)
		query = "Select * where temp4.ID <> null"
		nsel = SelectByQuery("b4", "Several", query,)
		if nsel > 0	
			then do
				ptr = GetFirstRecord(Join4 + "|b4",)
				while ptr <> null do
					SetRecordValues(Join4, ptr, {{"BandID", 4}})
					ptr = GetNextRecord(Join4+ "|b4",ptr,)
				end
			end	
		CloseView(temp4)
		CloseView(Join4)
	
		temp3 = OpenTable("temp3", "FFA", {tempfile3,})
		Join3 = JoinViews("Join3", templinks + ".ID", temp3 + ".ID",)
		SetView(Join3)
		query = "Select * where temp3.ID <> null"
		nsel = SelectByQuery("b3", "Several", query,)
		if nsel > 0	
			then do
				ptr = GetFirstRecord(Join3 + "|b3",)
				while ptr <> null do
					SetRecordValues(Join3, ptr, {{"BandID", 3}})
					ptr = GetNextRecord(Join3+ "|b3",ptr,)
				end
			end	
		CloseView(temp3)
		CloseView(Join3)
	
		temp2 = OpenTable("temp2", "FFA", {tempfile2,})
		Join2 = JoinViews("Join2", templinks + ".ID", temp2 + ".ID",)
		SetView(Join2)
		query = "Select * where temp2.ID <> null"
		nsel = SelectByQuery("b2", "Several", query,)
		if nsel > 0	
			then do
				ptr = GetFirstRecord(Join2 + "|b2",)
				while ptr <> null do
					SetRecordValues(Join2, ptr, {{"BandID", 2}})
					ptr = GetNextRecord(Join2+ "|b2",ptr,)
				end
			end	
		CloseView(temp2)
		CloseView(Join2)
	
		temp1 = OpenTable("temp1", "FFA", {tempfile1,})
		Join1 = JoinViews("Join1", templinks + ".ID", temp1 + ".ID",)
		SetView(Join1)
		query = "Select * where temp1.ID <> null"
		nsel = SelectByQuery("b1", "Several", query,)
		if nsel > 0	
			then do
				ptr = GetFirstRecord(Join1 + "|b1",)
				while ptr <> null do
					SetRecordValues (Join1, ptr, {{"BandID", 1}})
					ptr = GetNextRecord(Join1+ "|b1",ptr,)
				end
			end	
		CloseView(temp1)
		CloseView(Join1)
	
		// From all links - select only those with BandID
		SetView(templinks)
		query = "Select * where BandID <> null"
		nsel = SelectByQuery("blinks", "Several", query,)
		if nsel > 0	
			then ExportView(templinks + "|blinks", "FFA", NBLinksFile , {"ID", "BandID"},)
		CloseView(templinks)	

		//*********************************************************************************************************************
		// BUILD network
		SetView(BuildMapLayer)
		
			
		// clear sets
		set_list = GetSets(BuildMapLayer)
		for i = 1 to set_list.length do
			if upper(set_list[i]) <> "SELECTION" then deleteset(set_list[i])
		end
		
		// Conditions for culling out non-highway links 
		cullvar = BuildMapLayer + ".funcl"
		cullset = "select * where (" + cullvar + " > 0 and " + cullvar + " < 30) or " + cullvar + " = 82 or " + cullvar + " = 83"


		// export all links to temp file - ID only, add field BandID
		ExportView(BuildMapLayer + "|", "FFA", templinksfile , {"ID"},)

		// Add BandID to temp file
		templinks = OpenTable("templinks", "FFA", {templinksfile,})
		strct = GetTableStructure("templinks")
		for i = 1 to strct.length do
	   		strct[i] = strct[i] + {strct[i][1]}
		end
		new_struct = strct + {{"BandID", "INTEGER", 10, 0, "False",,,,null}}
		ModifyTable("templinks", new_struct)

		if nband4 > 0 
			then do
				nBUBuff4 = SelectByVicinity("BUBuff4", "Several", BufferView + "|BBand4", , {{"Inclusion", "Intersecting"}})
				SetLineColor(BuildMapLayer +  "|BUBuff4", ColorRGB(65535, 32896, 0))	
				SetDisplayStatus(BuildMapLayer +  "|BUBuff4", "Active")
				if nBUBuff4 > 0 
					then do
						nBUBuff4a = SelectByQuery("BUBuff4a", "Several", cullset, {{"Source And", "BUBuff4"}})
						if nBUBuff4a > 0
							then ExportView(BuildMapLayer + "|BUBuff4a", "FFA", tempfile4, {"ID"},)
					end // nBUBuff4 > 0
			end 

		if nband3 > 0 
			then do
				nBUBuff3 = SelectByVicinity("BUBuff3", "Several", BufferView + "|BBand3", , {{"Inclusion", "Intersecting"}})
				SetLineColor(BuildMapLayer +  "|BUBuff3", ColorRGB(0, 0, 65535))	
				SetDisplayStatus(BuildMapLayer +  "|BUBuff3", "Active")
				if nBUBuff3 > 0 
					then do
						nBUBuff3a = SelectByQuery("BUBuff3a", "Several", cullset, {{"Source And", "BUBuff3"}})
						if nBUBuff3a > 0
							then ExportView(BuildMapLayer + "|BUBuff3a", "FFA", tempfile3, {"ID"},)
					end // nBUBuff3 > 0
		end 

		if nband2 > 0 
			then do
				nBUBuff2 = SelectByVicinity("BUBuff2", "Several", BufferView + "|BBand2", , {{"Inclusion", "Intersecting"}})
				SetLineColor(BuildMapLayer +  "|BUBuff2", ColorRGB(0, 65535, 0))	
				SetDisplayStatus(BuildMapLayer +  "|BUBuff2", "Active")
				if nBUBuff2 > 0 
					then do
						nBUBuff2a = SelectByQuery("BUBuff2a", "Several", cullset, {{"Source And", "BUBuff2"}})
						if nBUBuff2a > 0
							then ExportView(BuildMapLayer + "|BUBuff2a", "FFA", tempfile2, {"ID"},)
					end // nBUBuff2 > 0
			end 

		if nband1 > 0 
			then do
				nBUBuff1 = SelectByVicinity("BUBuff1", "Several", BufferView + "|BBand1", , {{"Inclusion", "Intersecting"}})
				SetLineColor(BuildMapLayer +  "|BUBuff1", ColorRGB(32896, 0, 65535))	
				SetDisplayStatus(BuildMapLayer +  "|BUBuff1", "Active")
				if nBUBuff1 > 0 
					then do
						nBUBuff1a = SelectByQuery("BUBuff1a", "Several", cullset, {{"Source And", "BUBuff1"}})
						if nBUBuff1a > 0
							then ExportView(BuildMapLayer + "|BUBuff1a", "FFA", tempfile1, {"ID"},)
					end // nBUBuff1 > 0
		end 

		RedrawMap()
	
		// reopen temp files and join 1 at a time to temp file with all links
		//  join from outer band to inner - if link is in both, it will be assigned to inner band
		temp4 = OpenTable("temp4", "FFA", {tempfile4,})
		Join4 = JoinViews("Join4", templinks + ".ID", temp4 + ".ID",)
		SetView(Join4)
		query = "Select * where temp4.ID <> null"
		nsel = SelectByQuery("b4", "Several", query,)
		if nsel > 0	
			then do
				ptr = GetFirstRecord(Join4 + "|b4",)
				while ptr <> null do
					SetRecordValues(Join4, ptr, {{"BandID", 4}})
					ptr = GetNextRecord(Join4+ "|b4",ptr,)
				end
			end	
		CloseView(temp4)
		CloseView(Join4)
	
		temp3 = OpenTable("temp3", "FFA", {tempfile3,})
		Join3 = JoinViews("Join3", templinks + ".ID", temp3 + ".ID",)
		SetView(Join3)
		query = "Select * where temp3.ID <> null"
		nsel = SelectByQuery("b3", "Several", query,)
		if nsel > 0	
			then do
				ptr = GetFirstRecord(Join3 + "|b3",)
				while ptr <> null do
					SetRecordValues(Join3, ptr, {{"BandID", 3}})
					ptr = GetNextRecord(Join3+ "|b3",ptr,)
				end
			end	
		CloseView(temp3)
		CloseView(Join3)
	
		temp2 = OpenTable("temp2", "FFA", {tempfile2,})
		Join2 = JoinViews("Join2", templinks + ".ID", temp2 + ".ID",)
		SetView(Join2)
		query = "Select * where temp2.ID <> null"
		nsel = SelectByQuery("b2", "Several", query,)
		if nsel > 0	
			then do
				ptr = GetFirstRecord(Join2 + "|b2",)
				while ptr <> null do
					SetRecordValues(Join2, ptr, {{"BandID", 2}})
					ptr = GetNextRecord(Join2+ "|b2",ptr,)
				end
			end	
		CloseView(temp2)
		CloseView(Join2)
	
		temp1 = OpenTable("temp1", "FFA", {tempfile1,})
		Join1 = JoinViews("Join1", templinks + ".ID", temp1 + ".ID",)
		SetView(Join1)
		query = "Select * where temp1.ID <> null"
		nsel = SelectByQuery("b1", "Several", query,)
		if nsel > 0	
			then do
				ptr = GetFirstRecord(Join1 + "|b1",)
				while ptr <> null do
					SetRecordValues(Join1, ptr, {{"BandID", 1}})
					ptr = GetNextRecord(Join1+ "|b1",ptr,)
				end
			end	
		CloseView(temp1)
		CloseView(Join1)
	
		// From all links - select only those with BandID
		SetView(templinks)
		query = "Select * where BandID <> null"
		nsel = SelectByQuery("blinks", "Several", query,)
		if nsel > 0	then
			ExportView(templinks + "|blinks", "FFA", BULinksFile , {"ID", "BandID"},)
		CloseView(templinks)	

		info = GetDirectoryInfo(WorkingFolder + "\\Report", "Folder")
		if info = null then CreateDirectory(WorkingFolder + "\\Report")
		ReportDir = WorkingFolder + "\\Report"

		RunMacro("VMT_VHT_Report", NBTotAssnFile, BUTotAssnFile, NBLinksFile, BULinksFile, ReportDir, BufferView, HeaderInfo)
		
	enditem		
//*********************************************************************************************************************



	// ****************************************************************************************************
	//  Message block
	// ****************************************************************************************************
	Text " " same, after, , 0.5
	Text " Message" 2, after
	Text 2, after, 60, 3 Variable: message Framed

	// ****************************************************************************************************
	// bottom row of buttons
	// ****************************************************************************************************
//	Text " " 65, same
	Button " Close " 65, same Cancel do
		on error, notfound, escape default	
		return()
	enditem

	//******************************************************************************************************
	//  Internal macros
	//******************************************************************************************************
	Macro "gettheviews" do

		// Macro to fill viewlist, currentview, currentviewndx, and 
		//	viewsinfo (view, file, filetype, viewlayer viewlayertype)
		theviews = GetViews()
		if theviews <> null
			then do
				viewlist = theviews[1]
				currentviewndx = theviews[2]
				currentview = theviews[3]

				dim viewsinfo[viewlist.length,5]

				for i = 1 to viewlist.length do
					theview = viewlist[i]
	 				tableinfo = GetViewTableInfo(theview)
					theviewfiletype = tableinfo[1]
					theviewfilename = tableinfo[2][1]
					if theviewfiletype = "RDM"
						then do 
							layerinfo = GetLayerInfo(theview)
							theviewlayer = layerinfo[11]
							theviewlayertype = GetLayerType(theviewlayer)
						end
						else do
							theviewlayer = null
							theviewlayertype = null
						end
					viewsinfo[i] = {theview, theviewfilename,theviewfiletype, theviewlayer, theviewlayertype}
				end  // for i
			end // theviews <> null	
			else do
				currentview = null
				curentviewndx = -1
				viewlist = null
			end // else (theviews = null) 
	enditem  // macro gettheviews

	Macro "getthemaps" do
		// Get map info 
		themaps = GetMaps()
		if themaps <> null
			then do
				maplist = themaps[1]
				currentmapndx = themaps[2]
				currentmap = themaps[3]

				if BufBaseMapndx > 0 and BufBaseMapndx <= maplist.length
					then do
						maplayers = GetMapLayers(BufBaseMap, "All")
						BufBaseMaplayerlist = maplayers[1]
					end	
					else BufBaseMaplayerlist = null
			end // themaps <> null	 
		if themaps = null
			then do
				BufBaseMap = null
				BufBaseMaplayerlist = null
			end
	enditem	 

endDBox  // Buffer_Stats

//**********************************************************************************************************
//  External macros
//**********************************************************************************************************

Macro "BuildBufferSpinnerList" (val, step, low, high)
	val = MAX(low, MIN(val, high))
	SpinnerList = {r2s(val)}
	if val - step >= low then SpinnerList = {r2s(val - step)} + SpinnerList
	if val + step <= high then SpinnerList = SpinnerList + {r2s(val + step)}
	return(SpinnerList)
endmacro

//*******************************************************************************************************
Macro "VMT_VHT_Report" (NBTotAssnFile, BUTotAssnFile, NBLinksFile, BULinksFile, ReportDir, BufferName, HeaderInfo)
//			NB - NoBuild
//			BU - Build
//			(savings is NoBuild - Build)

		NBExportFile = ReportDir + "\\NOBUILD_LINKS_VMT_VHT_" + BufferName + ".asc"
		BUExportFile = ReportDir + "\\BUILD_LINKS_VMT_VHT_" + BufferName + ".asc"
		VMTVHTReportFile = ReportDir + "\\VMT_VHT_Report_" + BufferName + ".txt"
		VMTVHTReportExport = ReportDir + "\\VMT_VHT_Export_" + BufferName + ".csv"



//  	NEED TO PREPARE COMMA DELIMTED FILE FOR EXPORT TO EXCEL
//  	NEED BUFFER WIDTH (1-4) BEFORE AND AFTER


		NoBldExportVar =
			{
			"nbID", "nbLength", "nbDir", "nbFuncl", "nbStrName", "nbACrossStr", "nbBCrossStr", "nbBandID",
			
			"nbVolTotal24", "nbVolAuto24",  "nbVolTruck24",
			"nbVMTTotal24", "nbVMTAuto24",  "nbVMTTruck24",
			"nbVHTTotal24", "nbVHTAuto24",  "nbVHTTruck24",
			
			"nbVolTotalAM", "nbVolTotalMI", "nbVolTotalPM", "nbVolTotalNT",
			"nbVolAutoAM",  "nbVolAutoMI",  "nbVolAutoPM",  "nbVolAutoNT",
			"nbVolTruckAM", "nbVolTruckMI", "nbVolTruckPM", "nbVolTruckNT",

			"nbVMTTotalAM", "nbVMTTotalMI", "nbVMTTotalPM", "nbVMTTotalNT",
			"nbVMTAutoAM",  "nbVMTAutoMI",  "nbVMTAutoPM",  "nbVMTAutoNT",
			"nbVMTTruckAM", "nbVMTTrucKMI", "nbVMTTruckPM", "nbVMTTruckNT",

			"nbVHTTotalAM", "nbVHTTotalMI", "nbVHTTotalPM", "nbVHTTotalNT",
			"nbVHTAutoAM",  "nbVHTAutoMI",  "nbVHTAutoPM",  "nbVHTAutoNT",
			"nbVHTTruckAM", "nbVHTTrucKMI", "nbVHTTruckPM", "nbVHTTruckNT"
			}

		BuildExportVar =
			{
			"buID", "buLength", "buDir", "buFuncl", "buStrName", "buACrossStr", "buBCrossStr", "buBandID",
			
			"buVolTotal24", "buVolAuto24",  "buVolTruck24",
			"buVMTTotal24", "buVMTAuto24",  "buVMTTruck24",
			"buVHTTotal24", "buVHTAuto24",  "buVHTTruck24",
			
			"buVolTotalAM", "buVolTotalMI", "buVolTotalPM", "buVolTotalNT",
			"buVolAutoAM",  "buVolAutoMI",  "buVolAutoPM",  "buVolAutoNT",
			"buVolTruckAM", "buVolTruckMI", "buVolTruckPM", "buVolTruckNT",

			"buVMTTotalAM", "buVMTTotalMI", "buVMTTotalPM", "buVMTTotalNT",
			"buVMTAutoAM",  "buVMTAutoMI",  "buVMTAutoPM",  "buVMTAutoNT",
			"buVMTTruckAM", "buVMTTrucKMI", "buVMTTruckPM", "buVMTTruckNT",

			"buVHTTotalAM", "buVHTTotalMI", "buVHTTotalPM", "buVHTTotalNT",
			"buVHTAutoAM",  "buVHTAutoMI",  "buVHTAutoPM",  "buVHTAutoNT",
			"buVHTTruckAM", "buVHTTrucKMI", "buVHTTruckPM", "buVHTTruckNT"
			}


//*******************************************************************************************************

	NBTotAssn = OpenTable("NBTotAssn", "FFB", {NBTotAssnFile,})
	BUTotAssn = OpenTable("BUTotAssn", "FFB", {BUTotAssnFile,})

	NBLinks = OpenTable("NBLinks", "FFA", {NBLinksFile,})
	BULinks = OpenTable("BULinks", "FFA", {BULinksFile,})

	NBJoin = JoinViews("NBJoin", NBLinks+".ID", NBTotAssn + ".ID",)
	BUJoin = JoinViews("BUJoin", BULinks+".ID", BUTotAssn + ".ID",)
  


	//******************************************************************************************
	// No Build network

	SetView(NBJoin)
	nbid        = CreateExpression(NBJoin, "nbID",        NBTotAssn+".id",)
	nbdir       = CreateExpression(NBJoin, "nbDir",       "dir",)
	nblength    = CreateExpression(NBJoin, "nbLength",    "length",)
	nbfuncl     = CreateExpression(NBJoin, "nbFuncl",     "funcl",)
	nbstrname   = CreateExpression(NBJoin, "nbStrName",   "Strname",)
	nbacrossstr = CreateExpression(NBJoin, "nbACrossStr", "A_CrossStr",)
	nbbcrossstr = CreateExpression(NBJoin, "nbBCrossStr", "B_CrossStr",)
	nbbandid 	= CreateExpression(NBJoin, "nbBandID", 	  "BandID",)

	// total volume
	nbvoltotalam = CreateExpression(NBJoin, "nbVolTotalAM", "VolAMAB + VolAMBA",)
	nbvoltotalmi = CreateExpression(NBJoin, "nbVolTotalMI", "VolMIAB + VolMIBA",)
	nbvoltotalpm = CreateExpression(NBJoin, "nbVolTotalPM", "VolPMAB + VolPMBA",)
	nbvoltotalnt = CreateExpression(NBJoin, "nbVolTotalNT", "VolNTAB + VolNTBA",)
	nbvoltotal24 = CreateExpression(NBJoin, "nbVolTotal24", "TOT_VOL",)

	// total VMT
	nbvmttotalam = CreateExpression(NBJoin, "nbVMTTotalAM", "VMT_AM",)
	nbvmttotalmi = CreateExpression(NBJoin, "nbVMTTotalMI", "VMT_MI",)
	nbvmttotalpm = CreateExpression(NBJoin, "nbVMTTotalPM", "VMT_PM",)
	nbvmttotalnt = CreateExpression(NBJoin, "nbVMTTotalNT", "VMT_NT",)
	nbvmttotal24 = CreateExpression(NBJoin, "nbVMTTotal24", "TOT_VMT",)

	// total VHT
	nbvhttotalam = CreateExpression(NBJoin, "nbVHTTotalAM", "VHT_AM",)
	nbvhttotalmi = CreateExpression(NBJoin, "nbVHTTotalMI", "VHT_MI",)
	nbvhttotalpm = CreateExpression(NBJoin, "nbVHTTotalPM", "VHT_PM",)
	nbvhttotalnt = CreateExpression(NBJoin, "nbVHTTotalNT", "VHT_NT",)
	nbvhttotal24 = CreateExpression(NBJoin, "nbVHTTotal24", "TOT_VHT",)

	// Truck volume
	nbvoltruckamab = CreateExpression(NBJoin, "nbVolTruckAMAB", "mtkAMAB + htkAMAB",)
	nbvoltruckamba = CreateExpression(NBJoin, "nbVolTruckAMBA", "mtkAMBA + htkAMBA",)

	nbvoltruckmiab = CreateExpression(NBJoin, "nbVolTruckMIAB", "mtkMIAB + htkMIAB",)
	nbvoltruckmiba = CreateExpression(NBJoin, "nbVolTruckMIBA", "mtkMIBA + htkMIBA",)

	nbvoltruckpmab = CreateExpression(NBJoin, "nbVolTruckPMAB", "mtkPMAB + htkPMAB",)
	nbvoltruckpmba = CreateExpression(NBJoin, "nbVolTruckPMBA", "mtkPMBA + htkPMBA",)

	nbvoltruckntab = CreateExpression(NBJoin, "nbVolTruckNTAB", "mtkNTAB + htkNTAB",)
	nbvoltruckntba = CreateExpression(NBJoin, "nbVolTruckNTBA", "mtkNTBA + htkNTBA",)

	nbvoltruckam   = CreateExpression(NBJoin, "nbVolTruckAM",   "nbVolTruckAMBA + nbVolTruckAMBA",)
	nbvoltruckmi   = CreateExpression(NBJoin, "nbVolTruckMI",   "nbVolTruckMIBA + nbVolTruckMIBA",)
	nbvoltruckpm   = CreateExpression(NBJoin, "nbVolTruckPM",   "nbVolTruckPMBA + nbVolTruckPMBA",)
	nbvoltrucknt   = CreateExpression(NBJoin, "nbVolTruckNT",   "nbVolTruckNTBA + nbVolTruckNTBA",)
	nbvoltruck24   = CreateExpression(NBJoin, "nbVolTruck24",   "nbVolTruckAM + nbVolTruckMI + nbVolTruckPM + nbVolTruckNT",)

	// auto volume (total minus trucks)
	nbvolautoam    = CreateExpression(NBJoin, "nbVolAutoAM", "nbVolTotalAM - nbVolTruckAM",)
	nbvolautomi    = CreateExpression(NBJoin, "nbVolAutoMI", "nbVolTotalMI - nbVolTruckMI",)
	nbvolautopm    = CreateExpression(NBJoin, "nbVolAutoPM", "nbVolTotalPM - nbVolTruckPM",)
	nbvolautont    = CreateExpression(NBJoin, "nbVolAutoNT", "nbVolTotalNT - nbVolTruckNT",)
	nbvolauto24    = CreateExpression(NBJoin, "nbVolAuto24", "nbVolAutoAM + nbVolAutoMI + nbVolAutoPM + nbVolAutoNT",)

	// truck & auto (tot-truck) vmt
	nbvmttruckamab = CreateExpression(NBJoin, "nbVMTTruckAMAB", "VMTLen * nbVolTruckAMAB",)
	nbvmttruckamba = CreateExpression(NBJoin, "nbVMTTruckAMBA", "VMTLen * nbVolTruckAMBA",)
	nbvmttruckam   = CreateExpression(NBJoin, "nbVMTTruckAM",   "nbVMTTruckAMBA + nbVMTTruckAMBA",)
	nbvmtautoam    = CreateExpression(NBJoin, "nbVMTAutoAM",    "nbVMTTotalAM - nbVMTTruckAM",)

	nbvmttruckmiab = CreateExpression(NBJoin, "nbVMTTruckMIAB", "VMTLen * nbVolTruckMIAB",)
	nbvmttruckmiba = CreateExpression(NBJoin, "nbVMTTruckMIBA", "VMTLen * nbVolTruckMIBA",)
	nbvmttruckmi   = CreateExpression(NBJoin, "nbVMTTruckMI",   "nbVMTTruckMIBA + nbVMTTruckMIBA",)
	nbvmtautomi    = CreateExpression(NBJoin, "nbVMTAutoMI",    "nbVMTTotalMI - nbVMTTruckMI",)

	nbvmttruckpmab = CreateExpression(NBJoin, "nbVMTTruckPMAB", "VMTLen * nbVolTruckPMAB",)
	nbvmttruckpmba = CreateExpression(NBJoin, "nbVMTTruckPMBA", "VMTLen * nbVolTruckPMBA",)
	nbvmttruckpm   = CreateExpression(NBJoin, "nbVMTTruckPM",   "nbVMTTruckPMBA + nbVMTTruckPMBA",)
	nbvmtautopm    = CreateExpression(NBJoin, "nbVMTAutoPM",    "nbVMTTotalPM - nbVMTTruckPM",)

	nbvmttruckntab = CreateExpression(NBJoin, "nbVMTTruckNTAB", "VMTLen * nbVolTruckNTAB",)
	nbvmttruckntba = CreateExpression(NBJoin, "nbVMTTruckNTBA", "VMTLen * nbVolTruckNTBA",)
	nbvmttrucknt   = CreateExpression(NBJoin, "nbVMTTruckNT",   "nbVMTTruckNTBA + nbVMTTruckNTBA",)
	nbvmtautont    = CreateExpression(NBJoin, "nbVMTAutoNT",    "nbVMTTotalNT - nbVMTTruckNT",)

	// total VMT, truck and auto
	nbvmtauto24    = CreateExpression(NBJoin, "nbVMTAuto24",  "nbVMTAutoAM +  nbVMTAutoMI +  nbVMTAutoPM +  nbVMTAutoNT",)
	nbvmttruck24   = CreateExpression(NBJoin, "nbVMTTruck24", "nbVMTTruckAM + nbVMTTruckMI + nbVMTTruckPM + nbVMTTruckNT",)

	// truck & auto (tot-truck) VHT
	nbvhttruckamab = CreateExpression(NBJoin, "nbVHTTruckAMAB", "(minAMAB / 60.) * nbVolTruckAMAB",)
	nbvhttruckamba = CreateExpression(NBJoin, "nbVHTTruckAMBA", "(minAMBA / 60.) * nbVolTruckAMBA",)
	nbvhttruckam   = CreateExpression(NBJoin, "nbVHTTruckAM",   "nbVHTTruckAMBA + nbVHTTruckAMBA",)
	nbvhtautoam    = CreateExpression(NBJoin, "nbVHTAutoAM",    "nbVHTTotalAM - nbVHTTruckAM",)

	nbvhttruckmiab = CreateExpression(NBJoin, "nbVHTTruckMIAB", "(minMIAB / 60.) * nbVolTruckMIAB",)
	nbvhttruckmiba = CreateExpression(NBJoin, "nbVHTTruckMIBA", "(minMIBA / 60.) * nbVolTruckMIBA",)
	nbvhttruckmi   = CreateExpression(NBJoin, "nbVHTTruckMI",   "nbVHTTruckMIBA + nbVHTTruckMIBA",)
	nbvhtautomi    = CreateExpression(NBJoin, "nbVHTAutoMI",    "nbVHTTotalMI - nbVHTTruckMI",)

	nbvhttruckpmab = CreateExpression(NBJoin, "nbVHTTruckPMAB", "(minPMAB / 60.) * nbVolTruckPMAB",)
	nbvhttruckpmba = CreateExpression(NBJoin, "nbVHTTruckPMBA", "(minPMBA / 60.) * nbVolTruckPMBA",)
	nbvhttruckpm   = CreateExpression(NBJoin, "nbVHTTruckPM",   "nbVHTTruckPMBA + nbVHTTruckPMBA",)
	nbvhtautopm    = CreateExpression(NBJoin, "nbVHTAutoPM",    "nbVHTTotalPM - nbVHTTruckPM",)

	nbvhttruckntab = CreateExpression(NBJoin, "nbVHTTruckNTAB", "(minNTAB / 60.) * nbVolTruckNTAB",)
	nbvhttruckntba = CreateExpression(NBJoin, "nbVHTTruckNTBA", "(minNTBA / 60.) * nbVolTruckNTBA",)
	nbvhttrucknt   = CreateExpression(NBJoin, "nbVHTTruckNT",   "nbVHTTruckNTBA + nbVHTTruckNTBA",)
	nbvhtautont    = CreateExpression(NBJoin, "nbVHTAutoNT",    "nbVHTTotalNT - nbVHTTruckNT",)

	// total VHT, truck and auto
	nbvhtauto24    = CreateExpression(NBJoin, "nbVHTAuto24",  "nbVHTAutoAM +  nbVHTAutoMI +  nbVHTAutoPM +  nbVHTAutoNT",)
	nbvhttruck24   = CreateExpression(NBJoin, "nbVHTTruck24", "nbVHTTruckAM + nbVHTTruckMI + nbVHTTruckPM + nbVHTTruckNT",)

	//*****************************************************************
	// EXPORT should be set in buffer_stats
	ExportView(NBJoin + "|", "FFA", NBExportFile, NoBldExportVar,)
	//*****************************************************************


	// AGGREGATE VMT 
	// Selection sets for bandwidths 1-3 - all links are in band4
	nbquery1 = "select * where NBBandID = 1"
	nbquery2 = "select * where NBBandID <= 2"
	nbquery3 = "select * where NBBandID <= 3"
	nbnsel1 = SelectByQuery("nblinks1", "Several", nbquery1,)
	nbnsel2 = SelectByQuery("nblinks2", "Several", nbquery2,)
	nbnsel3 = SelectByQuery("nblinks3", "Several", nbquery3,)
	
	// vmt - auto truck and total for 4 band widths
	vnbvmtauto241  = GetDataVector(NBJoin + "|nblinks1", "nbVMTAuto24",)
	vnbvmttruck241 = GetDataVector(NBJoin + "|nblinks1", "nbVMTTruck24",)
	vnbvmttotal241 = GetDataVector(NBJoin + "|nblinks1", "nbVMTTotal24",)

	vnbvmtauto242  = GetDataVector(NBJoin + "|nblinks2", "nbVMTAuto24",)
	vnbvmttruck242 = GetDataVector(NBJoin + "|nblinks2", "nbVMTTruck24",)
	vnbvmttotal242 = GetDataVector(NBJoin + "|nblinks2", "nbVMTTotal24",)

	vnbvmtauto243  = GetDataVector(NBJoin + "|nblinks3", "nbVMTAuto24",)
	vnbvmttruck243 = GetDataVector(NBJoin + "|nblinks3", "nbVMTTruck24",)
	vnbvmttotal243 = GetDataVector(NBJoin + "|nblinks3", "nbVMTTotal24",)

	vnbvmtauto244  = GetDataVector(NBJoin + "|", "nbVMTAuto24",)
	vnbvmttruck244 = GetDataVector(NBJoin + "|", "nbVMTTruck24",)
	vnbvmttotal244 = GetDataVector(NBJoin + "|", "nbVMTTotal24",)

	nbvmtauto241sum  = VectorStatistic(vnbvmtauto241,"Sum",)
	nbvmttruck241sum = VectorStatistic(vnbvmttruck241,"Sum",)
	nbvmttotal241sum = VectorStatistic(vnbvmttotal241,"Sum",)

	nbvmtauto242sum  = VectorStatistic(vnbvmtauto242,"Sum",)
	nbvmttruck242sum = VectorStatistic(vnbvmttruck242,"Sum",)
	nbvmttotal242sum = VectorStatistic(vnbvmttotal242,"Sum",)

	nbvmtauto243sum  = VectorStatistic(vnbvmtauto243,"Sum",)
	nbvmttruck243sum = VectorStatistic(vnbvmttruck243,"Sum",)
	nbvmttotal243sum = VectorStatistic(vnbvmttotal243,"Sum",)

	nbvmtauto244sum  = VectorStatistic(vnbvmtauto244,"Sum",)
	nbvmttruck244sum = VectorStatistic(vnbvmttruck244,"Sum",)
	nbvmttotal244sum = VectorStatistic(vnbvmttotal244,"Sum",)

	// Aggregate VHT
	// vht - auto truck and total for 4 band widths
	vnbvhtauto241  = GetDataVector(NBJoin + "|nblinks1", "nbVHTAuto24",)
	vnbvhttruck241 = GetDataVector(NBJoin + "|nblinks1", "nbVHTTruck24",)
	vnbvhttotal241 = GetDataVector(NBJoin + "|nblinks1", "nbVHTTotal24",)

	vnbvhtauto242  = GetDataVector(NBJoin + "|nblinks2", "nbVHTAuto24",)
	vnbvhttruck242 = GetDataVector(NBJoin + "|nblinks2", "nbVHTTruck24",)
	vnbvhttotal242 = GetDataVector(NBJoin + "|nblinks2", "nbVHTTotal24",)

	vnbvhtauto243  = GetDataVector(NBJoin + "|nblinks3", "nbVHTAuto24",)
	vnbvhttruck243 = GetDataVector(NBJoin + "|nblinks3", "nbVHTTruck24",)
	vnbvhttotal243 = GetDataVector(NBJoin + "|nblinks3", "nbVHTTotal24",)

	vnbvhtauto244  = GetDataVector(NBJoin + "|", "nbVHTAuto24",)
	vnbvhttruck244 = GetDataVector(NBJoin + "|", "nbVHTTruck24",)
	vnbvhttotal244 = GetDataVector(NBJoin + "|", "nbVHTTotal24",)

	nbvhtauto241sum  = VectorStatistic(vnbvhtauto241,"Sum",)
	nbvhttruck241sum = VectorStatistic(vnbvhttruck241,"Sum",)
	nbvhttotal241sum = VectorStatistic(vnbvhttotal241,"Sum",)

	nbvhtauto242sum  = VectorStatistic(vnbvhtauto242,"Sum",)
	nbvhttruck242sum = VectorStatistic(vnbvhttruck242,"Sum",)
	nbvhttotal242sum = VectorStatistic(vnbvhttotal242,"Sum",)

	nbvhtauto243sum  = VectorStatistic(vnbvhtauto243,"Sum",)
	nbvhttruck243sum = VectorStatistic(vnbvhttruck243,"Sum",)
	nbvhttotal243sum = VectorStatistic(vnbvhttotal243,"Sum",)

	nbvhtauto244sum  = VectorStatistic(vnbvhtauto244,"Sum",)
	nbvhttruck244sum = VectorStatistic(vnbvhttruck244,"Sum",)
	nbvhttotal244sum = VectorStatistic(vnbvhttotal244,"Sum",)


	CloseView(NBTotAssn)
	CloseView(NBLinks)
	CloseView(NBJoin)

	// Build network

	SetView(BUJoin)

	buid        = CreateExpression(BUJoin, "buID",        BUTotAssn+".id",)
	budir       = CreateExpression(BUJoin, "buDir",       BUTotAssn+".dir",)
	bulength    = CreateExpression(BUJoin, "buLength",    BUTotAssn+".length",)
	bufuncl     = CreateExpression(BUJoin, "buFuncl",     BUTotAssn+".funcl",)
	bustrname   = CreateExpression(BUJoin, "buStrName",   BUTotAssn+".Strname",)
	buacrossstr = CreateExpression(BUJoin, "buACrossStr", BUTotAssn+".A_CrossStr",)
	bubcrossstr = CreateExpression(BUJoin, "buBCrossStr", BUTotAssn+".B_CrossStr",)
	bubandid 	= CreateExpression(BUJoin, "buBandID", 	  "BandID",)

	// total volume
	buvoltotalam = CreateExpression(BUJoin, "buVolTotalAM", "VolAMAB + VolAMBA",)
	buvoltotalmi = CreateExpression(BUJoin, "buVolTotalMI", "VolMIAB + VolMIBA",)
	buvoltotalpm = CreateExpression(BUJoin, "buVolTotalPM", "VolPMAB + VolPMBA",)
	buvoltotalnt = CreateExpression(BUJoin, "buVolTotalNT", "VolNTAB + VolNTBA",)
	buvoltotal24 = CreateExpression(BUJoin, "buVolTotal24", "TOT_VOL",)

	// total VMT
	buvmttotalam = CreateExpression(BUJoin, "buVMTTotalAM", "VMT_AM",)
	buvmttotalmi = CreateExpression(BUJoin, "buVMTTotalMI", "VMT_MI",)
	buvmttotalpm = CreateExpression(BUJoin, "buVMTTotalPM", "VMT_PM",)
	buvmttotalnt = CreateExpression(BUJoin, "buVMTTotalNT", "VMT_NT",)
	buvmttotal24 = CreateExpression(BUJoin, "buVMTTotal24", "TOT_VMT",)

	// total VHT
	buvhttotalam = CreateExpression(BUJoin, "buVHTTotalAM", "VHT_AM",)
	buvhttotalmi = CreateExpression(BUJoin, "buVHTTotalMI", "VHT_MI",)
	buvhttotalpm = CreateExpression(BUJoin, "buVHTTotalPM", "VHT_PM",)
	buvhttotalnt = CreateExpression(BUJoin, "buVHTTotalNT", "VHT_NT",)
	buvhttotal24 = CreateExpression(BUJoin, "buVHTTotal24", "TOT_VHT",)

	// Truck volume
	buvoltruckamab = CreateExpression(BUJoin, "buVolTruckAMAB", "mtkAMAB + htkAMAB",)
	buvoltruckamba = CreateExpression(BUJoin, "buVolTruckAMBA", "mtkAMBA + htkAMBA",)

	buvoltruckmiab = CreateExpression(BUJoin, "buVolTruckMIAB", "mtkMIAB + htkMIAB",)
	buvoltruckmiba = CreateExpression(BUJoin, "buVolTruckMIBA", "mtkMIBA + htkMIBA",)

	buvoltruckpmab = CreateExpression(BUJoin, "buVolTruckPMAB", "mtkPMAB + htkPMAB",)
	buvoltruckpmba = CreateExpression(BUJoin, "buVolTruckPMBA", "mtkPMBA + htkPMBA",)

	buvoltruckntab = CreateExpression(BUJoin, "buVolTruckNTAB", "mtkNTAB + htkNTAB",)
	buvoltruckntba = CreateExpression(BUJoin, "buVolTruckNTBA", "mtkNTBA + htkNTBA",)

	buvoltruckam   = CreateExpression(BUJoin, "buVolTruckAM",   "buVolTruckAMBA + buVolTruckAMBA",)
	buvoltruckmi   = CreateExpression(BUJoin, "buVolTruckMI",   "buVolTruckMIBA + buVolTruckMIBA",)
	buvoltruckpm   = CreateExpression(BUJoin, "buVolTruckPM",   "buVolTruckPMBA + buVolTruckPMBA",)
	buvoltrucknt   = CreateExpression(BUJoin, "buVolTruckNT",   "buVolTruckNTBA + buVolTruckNTBA",)
	buvoltruck24   = CreateExpression(BUJoin, "buVolTruck24",   "buVolTruckAM + buVolTruckMI + buVolTruckPM + buVolTruckNT",)

	// auto volume (total minus trucks)
	buvolautoam    = CreateExpression(BUJoin, "buVolAutoAM", "buVolTotalAM - buVolTruckAM",)
	buvolautomi    = CreateExpression(BUJoin, "buVolAutoMI", "buVolTotalMI - buVolTruckMI",)
	buvolautopm    = CreateExpression(BUJoin, "buVolAutoPM", "buVolTotalPM - buVolTruckPM",)
	buvolautont    = CreateExpression(BUJoin, "buVolAutoNT", "buVolTotalNT - buVolTruckNT",)
	buvolauto24    = CreateExpression(BUJoin, "buVolAuto24", "buVolAutoAM + buVolAutoMI + buVolAutoPM + buVolAutoNT",)

	// truck & auto (tot-truck) vmt
	buvmttruckamab = CreateExpression(BUJoin, "buVMTTruckAMAB", "VMTLen * buVolTruckAMAB",)
	buvmttruckamba = CreateExpression(BUJoin, "buVMTTruckAMBA", "VMTLen * buVolTruckAMBA",)
	buvmttruckam   = CreateExpression(BUJoin, "buVMTTruckAM",   "buVMTTruckAMBA + buVMTTruckAMBA",)
	buvmtautoam    = CreateExpression(BUJoin, "buVMTAutoAM",    "buVMTTotalAM - buVMTTruckAM",)

	buvmttruckmiab = CreateExpression(BUJoin, "buVMTTruckMIAB", "VMTLen * buVolTruckMIAB",)
	buvmttruckmiba = CreateExpression(BUJoin, "buVMTTruckMIBA", "VMTLen * buVolTruckMIBA",)
	buvmttruckmi   = CreateExpression(BUJoin, "buVMTTruckMI",   "buVMTTruckMIBA + buVMTTruckMIBA",)
	buvmtautomi    = CreateExpression(BUJoin, "buVMTAutoMI",    "buVMTTotalMI - buVMTTruckMI",)

	buvmttruckpmab = CreateExpression(BUJoin, "buVMTTruckPMAB", "VMTLen * buVolTruckPMAB",)
	buvmttruckpmba = CreateExpression(BUJoin, "buVMTTruckPMBA", "VMTLen * buVolTruckPMBA",)
	buvmttruckpm   = CreateExpression(BUJoin, "buVMTTruckPM",   "buVMTTruckPMBA + buVMTTruckPMBA",)
	buvmtautopm    = CreateExpression(BUJoin, "buVMTAutoPM",    "buVMTTotalPM - buVMTTruckPM",)

	buvmttruckntab = CreateExpression(BUJoin, "buVMTTruckNTAB", "VMTLen * buVolTruckNTAB",)
	buvmttruckntba = CreateExpression(BUJoin, "buVMTTruckNTBA", "VMTLen * buVolTruckNTBA",)
	buvmttrucknt   = CreateExpression(BUJoin, "buVMTTruckNT",   "buVMTTruckNTBA + buVMTTruckNTBA",)
	buvmtautont    = CreateExpression(BUJoin, "buVMTAutoNT",    "buVMTTotalNT - buVMTTruckNT",)

	// total VMT, truck and auto
	buvmtauto24    = CreateExpression(BUJoin, "buVMTAuto24",  "buVMTAutoAM +  buVMTAutoMI +  buVMTAutoPM +  buVMTAutoNT",)
	buvmttruck24   = CreateExpression(BUJoin, "buVMTTruck24", "buVMTTruckAM + buVMTTruckMI + buVMTTruckPM + buVMTTruckNT",)

	// truck & auto (tot-truck) VHT
	buvhttruckamab = CreateExpression(BUJoin, "buVHTTruckAMAB", "(minAMAB / 60.) * buVolTruckAMAB",)
	buvhttruckamba = CreateExpression(BUJoin, "buVHTTruckAMBA", "(minAMBA / 60.) * buVolTruckAMBA",)
	buvhttruckam   = CreateExpression(BUJoin, "buVHTTruckAM",   "buVHTTruckAMBA + buVHTTruckAMBA",)
	buvhtautoam    = CreateExpression(BUJoin, "buVHTAutoAM",    "buVHTTotalAM - buVHTTruckAM",)

	buvhttruckmiab = CreateExpression(BUJoin, "buVHTTruckMIAB", "(minMIAB / 60.) * buVolTruckMIAB",)
	buvhttruckmiba = CreateExpression(BUJoin, "buVHTTruckMIBA", "(minMIBA / 60.) * buVolTruckMIBA",)
	buvhttruckmi   = CreateExpression(BUJoin, "buVHTTruckMI",   "buVHTTruckMIBA + buVHTTruckMIBA",)
	buvhtautomi    = CreateExpression(BUJoin, "buVHTAutoMI",    "buVHTTotalMI - buVHTTruckMI",)

	buvhttruckpmab = CreateExpression(BUJoin, "buVHTTruckPMAB", "(minPMAB / 60.) * buVolTruckPMAB",)
	buvhttruckpmba = CreateExpression(BUJoin, "buVHTTruckPMBA", "(minPMBA / 60.) * buVolTruckPMBA",)
	buvhttruckpm   = CreateExpression(BUJoin, "buVHTTruckPM",   "buVHTTruckPMBA + buVHTTruckPMBA",)
	buvhtautopm    = CreateExpression(BUJoin, "buVHTAutoPM",    "buVHTTotalPM - buVHTTruckPM",)

	buvhttruckntab = CreateExpression(BUJoin, "buVHTTruckNTAB", "(minNTAB / 60.) * buVolTruckNTAB",)
	buvhttruckntba = CreateExpression(BUJoin, "buVHTTruckNTBA", "(minNTBA / 60.) * buVolTruckNTBA",)
	buvhttrucknt   = CreateExpression(BUJoin, "buVHTTruckNT",   "buVHTTruckNTBA + buVHTTruckNTBA",)
	buvhtautont    = CreateExpression(BUJoin, "buVHTAutoNT",    "buVHTTotalNT - buVHTTruckNT",)

	// total VHT, truck and auto
	buvhtauto24    = CreateExpression(BUJoin, "buVHTAuto24",  "buVHTAutoAM +  buVHTAutoMI +  buVHTAutoPM +  buVHTAutoNT",)
	buvhttruck24   = CreateExpression(BUJoin, "buVHTTruck24", "buVHTTruckAM + buVHTTruckMI + buVHTTruckPM + buVHTTruckNT",)

	//*****************************************************************
	// EXPORT should be set in buffer_stats
	ExportView(BUJoin + "|", "FFA", BUExportFile, BuildExportVar,)
	//*****************************************************************


	// AGGREGATE VMT 
	// Selection sets for bandwidths 1-3 - all links are in band4
	buquery1 = "select * where BUBandID = 1"
	buquery2 = "select * where BUBandID <= 2"
	buquery3 = "select * where BUBandID <= 3"
	bunsel1 = SelectByQuery("bulinks1", "Several", buquery1,)
	bunsel2 = SelectByQuery("bulinks2", "Several", buquery2,)
	bunsel3 = SelectByQuery("bulinks3", "Several", buquery3,)
	
	// vmt - auto truck and total for 4 band widths
	vbuvmtauto241  = GetDataVector(BUJoin + "|bulinks1", "buVMTAuto24",)
	vbuvmttruck241 = GetDataVector(BUJoin + "|bulinks1", "buVMTTruck24",)
	vbuvmttotal241 = GetDataVector(BUJoin + "|bulinks1", "buVMTTotal24",)

	vbuvmtauto242  = GetDataVector(BUJoin + "|bulinks2", "buVMTAuto24",)
	vbuvmttruck242 = GetDataVector(BUJoin + "|bulinks2", "buVMTTruck24",)
	vbuvmttotal242 = GetDataVector(BUJoin + "|bulinks2", "buVMTTotal24",)

	vbuvmtauto243  = GetDataVector(BUJoin + "|bulinks3", "buVMTAuto24",)
	vbuvmttruck243 = GetDataVector(BUJoin + "|bulinks3", "buVMTTruck24",)
	vbuvmttotal243 = GetDataVector(BUJoin + "|bulinks3", "buVMTTotal24",)

	vbuvmtauto244  = GetDataVector(BUJoin + "|", "buVMTAuto24",)
	vbuvmttruck244 = GetDataVector(BUJoin + "|", "buVMTTruck24",)
	vbuvmttotal244 = GetDataVector(BUJoin + "|", "buVMTTotal24",)

	buvmtauto241sum  = VectorStatistic(vbuvmtauto241,"Sum",)
	buvmttruck241sum = VectorStatistic(vbuvmttruck241,"Sum",)
	buvmttotal241sum = VectorStatistic(vbuvmttotal241,"Sum",)

	buvmtauto242sum  = VectorStatistic(vbuvmtauto242,"Sum",)
	buvmttruck242sum = VectorStatistic(vbuvmttruck242,"Sum",)
	buvmttotal242sum = VectorStatistic(vbuvmttotal242,"Sum",)

	buvmtauto243sum  = VectorStatistic(vbuvmtauto243,"Sum",)
	buvmttruck243sum = VectorStatistic(vbuvmttruck243,"Sum",)
	buvmttotal243sum = VectorStatistic(vbuvmttotal243,"Sum",)

	buvmtauto244sum  = VectorStatistic(vbuvmtauto244,"Sum",)
	buvmttruck244sum = VectorStatistic(vbuvmttruck244,"Sum",)
	buvmttotal244sum = VectorStatistic(vbuvmttotal244,"Sum",)

	// Aggregate VHT
	// vht - auto truck and total for 4 band widths
	vbuvhtauto241  = GetDataVector(BUJoin + "|bulinks1", "buVHTAuto24",)
	vbuvhttruck241 = GetDataVector(BUJoin + "|bulinks1", "buVHTTruck24",)
	vbuvhttotal241 = GetDataVector(BUJoin + "|bulinks1", "buVHTTotal24",)

	vbuvhtauto242  = GetDataVector(BUJoin + "|bulinks2", "buVHTAuto24",)
	vbuvhttruck242 = GetDataVector(BUJoin + "|bulinks2", "buVHTTruck24",)
	vbuvhttotal242 = GetDataVector(BUJoin + "|bulinks2", "buVHTTotal24",)

	vbuvhtauto243  = GetDataVector(BUJoin + "|bulinks3", "buVHTAuto24",)
	vbuvhttruck243 = GetDataVector(BUJoin + "|bulinks3", "buVHTTruck24",)
	vbuvhttotal243 = GetDataVector(BUJoin + "|bulinks3", "buVHTTotal24",)

	vbuvhtauto244  = GetDataVector(BUJoin + "|", "buVHTAuto24",)
	vbuvhttruck244 = GetDataVector(BUJoin + "|", "buVHTTruck24",)
	vbuvhttotal244 = GetDataVector(BUJoin + "|", "buVHTTotal24",)

	buvhtauto241sum  = VectorStatistic(vbuvhtauto241,"Sum",)
	buvhttruck241sum = VectorStatistic(vbuvhttruck241,"Sum",)
	buvhttotal241sum = VectorStatistic(vbuvhttotal241,"Sum",)

	buvhtauto242sum  = VectorStatistic(vbuvhtauto242,"Sum",)
	buvhttruck242sum = VectorStatistic(vbuvhttruck242,"Sum",)
	buvhttotal242sum = VectorStatistic(vbuvhttotal242,"Sum",)

	buvhtauto243sum  = VectorStatistic(vbuvhtauto243,"Sum",)
	buvhttruck243sum = VectorStatistic(vbuvhttruck243,"Sum",)
	buvhttotal243sum = VectorStatistic(vbuvhttotal243,"Sum",)

	buvhtauto244sum  = VectorStatistic(vbuvhtauto244,"Sum",)
	buvhttruck244sum = VectorStatistic(vbuvhttruck244,"Sum",)
	buvhttotal244sum = VectorStatistic(vbuvhttotal244,"Sum",)

	// Calc Savings VMT 
	savvmtauto241sum  = nbvmtauto241sum -  buvmtauto241sum
	savvmttruck241sum = nbvmttruck241sum - buvmttruck241sum
	savvmttotal241sum = nbvmttotal241sum - buvmttotal241sum

	savvmtauto242sum  = nbvmtauto242sum -  buvmtauto242sum
	savvmttruck242sum = nbvmttruck242sum - buvmttruck242sum
	savvmttotal242sum = nbvmttotal242sum - buvmttotal242sum

	savvmtauto243sum  = nbvmtauto243sum -  buvmtauto243sum
	savvmttruck243sum = nbvmttruck243sum - buvmttruck243sum
	savvmttotal243sum = nbvmttotal243sum - buvmttotal243sum

	savvmtauto244sum  = nbvmtauto244sum -  buvmtauto244sum
	savvmttruck244sum = nbvmttruck244sum - buvmttruck244sum
	savvmttotal244sum = nbvmttotal244sum - buvmttotal244sum

	// Calc Savings VHT 
	savvhtauto241sum  = nbvhtauto241sum -  buvhtauto241sum
	savvhttruck241sum = nbvhttruck241sum - buvhttruck241sum
	savvhttotal241sum = nbvhttotal241sum - buvhttotal241sum

	savvhtauto242sum  = nbvhtauto242sum -  buvhtauto242sum
	savvhttruck242sum = nbvhttruck242sum - buvhttruck242sum
	savvhttotal242sum = nbvhttotal242sum - buvhttotal242sum

	savvhtauto243sum  = nbvhtauto243sum -  buvhtauto243sum
	savvhttruck243sum = nbvhttruck243sum - buvhttruck243sum
	savvhttotal243sum = nbvhttotal243sum - buvhttotal243sum

	savvhtauto244sum  = nbvhtauto244sum -  buvhtauto244sum
	savvhttruck244sum = nbvhttruck244sum - buvhttruck244sum
	savvhttotal244sum = nbvhttotal244sum - buvhttotal244sum

	
	CloseView(BUTotAssn)
	CloseView(BULinks)
	CloseView(BUJoin)

	rptname = VMTVHTReportFile
  	exist = GetFileInfo(rptname)
  	if (exist <> null) then DeleteFile(rptname)


  	txtrpt = OpenFile(rptname, "w")
//                         1      2          3        4        5      6           7             8   
//		HeaderInfo = {"Index", "MTP45_NO" "TIP_NO" ,"Project", "Limits", "Type", "County", rptyear,  
//					    9            10      11             12          13              14
//					NoBldMapLayer, NoBldMapFile, nbdate, BuildMapLayer, BuildMapFile, budate}



	WriteLine(txtrpt, " 2021 PROJECT RANKINGS ")
	WriteLine(txtrpt, " VEHICLE MILES TRAVELED, VEHICLE HOURS TRAVELED REPORT ")
	WriteLine(txtrpt, " ")
	WriteLine(txtrpt, " Analysis Year:     " + HeaderInfo[8])
	WriteLine(txtrpt, " ")
	WriteLine(txtrpt, " MTP 2050_No:       " + HeaderInfo[2])
	WriteLine(txtrpt, " Project Index:     " + HeaderInfo[1])
	WriteLine(txtrpt, " Project NC TIP:    " + HeaderInfo[3])
	WriteLine(txtrpt, " Project name:      " + HeaderInfo[4])
	WriteLine(txtrpt, " Project limits:    " + HeaderInfo[5])
	WriteLine(txtrpt, " Project type:      " + HeaderInfo[6])
	WriteLine(txtrpt, " County:            " + HeaderInfo[7])
	WriteLine(txtrpt, " ")
	WriteLine(txtrpt, " ")
	WriteLine(txtrpt, " NoBuild network:      " + HeaderInfo[9])
	WriteLine(txtrpt, " NoBuild network file: " + HeaderInfo[10])
	WriteLine(txtrpt, " NoBuild network date: " + HeaderInfo[11])
	WriteLine(txtrpt, " NoBuild HOT Assign file")
	WriteLine(txtrpt, "            " + NBTotAssnFile)
	WriteLine(txtrpt, " ")
	WriteLine(txtrpt, " Build network:        " + HeaderInfo[12])
	WriteLine(txtrpt, " Build network file:   " + HeaderInfo[13])
	WriteLine(txtrpt, " Build network date:   " + HeaderInfo[14])
	WriteLine(txtrpt, " Build HOT Assign file")
	WriteLine(txtrpt, "            " + BUTotAssnFile)
	WriteLine(txtrpt, " ")
	WriteLine(txtrpt, " ")
	WriteLine(txtrpt, "************************************************************")
	WriteLine(txtrpt, " ")
	WriteLine(txtrpt, " VMT - Vehicle Miles Traveled")
	WriteLine(txtrpt, " ")
	WriteLine(txtrpt, "                           Buffer width")	
	WriteLine(txtrpt, "                    1 mi.       2 mi       3 mi.       4 mi.")
	WriteLine(txtrpt, "************************************************************")
	WriteLine(txtrpt, " Auto (not truck)")
	WriteLine(txtrpt, "------------------------------------------------------------")
	WriteLine(txtrpt, " NoBuild    " 	+ Lpad(Format(nbvmtauto241sum,  ",*0"),12) 
										+ Lpad(Format(nbvmtauto242sum,  ",*0"),12)
										+ Lpad(Format(nbvmtauto243sum,  ",*0"),12)
										+ Lpad(Format(nbvmtauto244sum,  ",*0"),12) )  
	WriteLine(txtrpt, " Build      " 	+ Lpad(Format(buvmtauto241sum,  ",*0"),12)   
										+ Lpad(Format(buvmtauto242sum,  ",*0"),12)
										+ Lpad(Format(buvmtauto243sum,  ",*0"),12)
										+ Lpad(Format(buvmtauto244sum,  ",*0"),12) )
	WriteLine(txtrpt, "               ---------  ----------  ----------  ----------")
	WriteLine(txtrpt, " Savings    " 	+ Lpad(Format(savvmtauto241sum, ",*0"),12) 
										+ Lpad(Format(savvmtauto242sum, ",*0"),12)
										+ Lpad(Format(savvmtauto243sum, ",*0"),12)
										+ Lpad(Format(savvmtauto244sum, ",*0"),12) ) 
	WriteLine(txtrpt, " ")
	WriteLine(txtrpt, " Truck")
	WriteLine(txtrpt, "------------------------------------------------------------")
	WriteLine(txtrpt, " NoBuild    " 	+ Lpad(Format(nbvmttruck241sum,  ",*0"),12)
										+ Lpad(Format(nbvmttruck242sum,  ",*0"),12)
										+ Lpad(Format(nbvmttruck243sum,  ",*0"),12)
										+ Lpad(Format(nbvmttruck244sum,  ",*0"),12)  )
	WriteLine(txtrpt, " Build      " 	+ Lpad(Format(buvmttruck241sum,  ",*0"),12)
										+ Lpad(Format(buvmttruck242sum,  ",*0"),12)
										+ Lpad(Format(buvmttruck243sum,  ",*0"),12)
										+ Lpad(Format(buvmttruck244sum,  ",*0"),12) )
	WriteLine(txtrpt, "               ---------  ----------  ----------  ----------")
	WriteLine(txtrpt, " Savings    " 	+ Lpad(Format(savvmttruck241sum, ",*0"),12) 
										+ Lpad(Format(savvmttruck242sum, ",*0"),12)
										+ Lpad(Format(savvmttruck243sum, ",*0"),12)
										+ Lpad(Format(savvmttruck244sum, ",*0"),12) )
	WriteLine(txtrpt, " ")
	WriteLine(txtrpt, " ")
	WriteLine(txtrpt, " ")
	WriteLine(txtrpt, "************************************************************")
	WriteLine(txtrpt, " ")
	WriteLine(txtrpt, " VHT - Vehicle Hours Traveled")
	WriteLine(txtrpt, " ")
	WriteLine(txtrpt, "                           Buffer width")	
	WriteLine(txtrpt, "                    1 mi.       2 mi       3 mi.       4 mi.")
	WriteLine(txtrpt, "************************************************************")
	WriteLine(txtrpt, " Auto (not truck)")
	WriteLine(txtrpt, "------------------------------------------------------------")
	WriteLine(txtrpt, " NoBuild    " 	+ Lpad(Format(nbvhtauto241sum,  ",*0"),12)
										+ Lpad(Format(nbvhtauto242sum,  ",*0"),12)
										+ Lpad(Format(nbvhtauto243sum,  ",*0"),12)
										+ Lpad(Format(nbvhtauto244sum,  ",*0"),12)  )  
	WriteLine(txtrpt, " Build      " 	+ Lpad(Format(buvhtauto241sum,  ",*0"),12) 
										+ Lpad(Format(buvhtauto242sum,  ",*0"),12)
										+ Lpad(Format(buvhtauto243sum,  ",*0"),12)
										+ Lpad(Format(buvhtauto244sum,  ",*0"),12) ) 
	WriteLine(txtrpt, "               ---------  ----------  ----------  ----------")
	WriteLine(txtrpt, " Savings    " 	+ Lpad(Format(savvhtauto241sum, ",*0"),12)
										+ Lpad(Format(savvhtauto242sum, ",*0"),12) 
										+ Lpad(Format(savvhtauto243sum, ",*0"),12)
										+ Lpad(Format(savvhtauto244sum, ",*0"),12) ) 
	WriteLine(txtrpt, " ")
	WriteLine(txtrpt, " Truck")
	WriteLine(txtrpt, "------------------------------------------------------------")
	WriteLine(txtrpt, " NoBuild    " 	+ Lpad(Format(nbvhttruck241sum,  ",*0"),12)
										+ Lpad(Format(nbvhttruck242sum,  ",*0"),12) 
										+ Lpad(Format(nbvhttruck243sum,  ",*0"),12) 
										+ Lpad(Format(nbvhttruck244sum,  ",*0"),12)  )
	WriteLine(txtrpt, " Build      " 	+ Lpad(Format(buvhttruck241sum,  ",*0"),12) 
										+ Lpad(Format(buvhttruck242sum,  ",*0"),12)
										+ Lpad(Format(buvhttruck243sum,  ",*0"),12) 
										+ Lpad(Format(buvhttruck244sum,  ",*0"),12)  )
	WriteLine(txtrpt, "               ---------  ----------  ----------  ----------")
	WriteLine(txtrpt, " Savings    " 	+ Lpad(Format(savvhttruck241sum, ",*0"),12) 
										+ Lpad(Format(savvhttruck242sum, ",*0"),12) 
										+ Lpad(Format(savvhttruck243sum, ",*0"),12)
										+ Lpad(Format(savvhttruck244sum, ",*0"),12))
	CloseFile(txtrpt)



	rptname = VMTVHTReportExport
  	exist = GetFileInfo(rptname)
  	if (exist <> null) then DeleteFile(rptname)


  	txtrpt = OpenFile(rptname, "w")

	WriteLine(txtrpt, " 2021 PROJECT RANKINGS ")
	WriteLine(txtrpt, " VEHICLE MILES TRAVELED - VEHICLE HOURS TRAVELED REPORT ")
	WriteLine(txtrpt, " ")
	WriteLine(txtrpt, " Analysis Year:     ," + HeaderInfo[8])
	WriteLine(txtrpt, " ")
	WriteLine(txtrpt, " MTP 2045_No:       ," + HeaderInfo[2])
	WriteLine(txtrpt, " Project Index:     ," + HeaderInfo[1])
	WriteLine(txtrpt, " Project NC TIP:    ," + HeaderInfo[3])
	WriteLine(txtrpt, " Project name:      ," + HeaderInfo[4])
	WriteLine(txtrpt, " Project limits:    ," + HeaderInfo[5])
	WriteLine(txtrpt, " Project type:      ," + HeaderInfo[6])
	WriteLine(txtrpt, " County:            ," + HeaderInfo[7])
	WriteLine(txtrpt, " ")
	WriteLine(txtrpt, " ")
	WriteLine(txtrpt, " NoBuild network:      ," + HeaderInfo[9])
	WriteLine(txtrpt, " NoBuild network file: ," + HeaderInfo[10])
	WriteLine(txtrpt, " NoBuild network date: ," + HeaderInfo[11])
	WriteLine(txtrpt, " NoBuild HOT Assign file: ," + NBTotAssnFile)
	WriteLine(txtrpt, " ")
	WriteLine(txtrpt, " Build network:        ," + HeaderInfo[12])
	WriteLine(txtrpt, " Build network file:   ," + HeaderInfo[13])
	WriteLine(txtrpt, " Build network date:   ," + HeaderInfo[14])
	WriteLine(txtrpt, " Build HOT Assign file: ," + BUTotAssnFile)
	WriteLine(txtrpt, " ")
	WriteLine(txtrpt, " VMT - Vehicle Miles Traveled")
	WriteLine(txtrpt, "  Buffer width")	
	WriteLine(txtrpt, "                   ,    1 mi.,       2 mi.,       3 mi.,       4 mi.")
	WriteLine(txtrpt, " Auto (not truck)")
	WriteLine(txtrpt, " NoBuild    ," 	+ Lpad(Format(nbvmtauto241sum,  "*0"),12) 
								+ ","	+ Lpad(Format(nbvmtauto242sum,  "*0"),12)
								+ ","		+ Lpad(Format(nbvmtauto243sum,  "*0"),12)
								+ ","		+ Lpad(Format(nbvmtauto244sum,  "*0"),12) )  
	WriteLine(txtrpt, " Build      ," 	+ Lpad(Format(buvmtauto241sum,  "*0"),12)   
								+ ","		+ Lpad(Format(buvmtauto242sum,  "*0"),12)
								+ ","		+ Lpad(Format(buvmtauto243sum,  "*0"),12)
								+ ","		+ Lpad(Format(buvmtauto244sum,  "*0"),12) )
	WriteLine(txtrpt, " Savings    ," 	+ Lpad(Format(savvmtauto241sum, "*0"),12) 
								+ ","		+ Lpad(Format(savvmtauto242sum, "*0"),12)
								+ ","		+ Lpad(Format(savvmtauto243sum, "*0"),12)
								+ ","		+ Lpad(Format(savvmtauto244sum, "*0"),12) ) 
	WriteLine(txtrpt, " ")
	WriteLine(txtrpt, " Truck")
	WriteLine(txtrpt, " NoBuild    ," 	+ Lpad(Format(nbvmttruck241sum,  "*0"),12)
								+ ","		+ Lpad(Format(nbvmttruck242sum,  "*0"),12)
								+ ","		+ Lpad(Format(nbvmttruck243sum,  "*0"),12)
								+ ","		+ Lpad(Format(nbvmttruck244sum,  "*0"),12)  )
	WriteLine(txtrpt, " Build      ," 	+ Lpad(Format(buvmttruck241sum,  "*0"),12)
								+ ","		+ Lpad(Format(buvmttruck242sum,  "*0"),12)
								+ ","		+ Lpad(Format(buvmttruck243sum,  "*0"),12)
								+ ","		+ Lpad(Format(buvmttruck244sum,  "*0"),12) )
	WriteLine(txtrpt, " Savings    ," 	+ Lpad(Format(savvmttruck241sum, "*0"),12) 
								+ ","		+ Lpad(Format(savvmttruck242sum, "*0"),12)
								+ ","		+ Lpad(Format(savvmttruck243sum, "*0"),12)
								+ ","		+ Lpad(Format(savvmttruck244sum, "*0"),12) )
	WriteLine(txtrpt, " ")
	WriteLine(txtrpt, " ")
	WriteLine(txtrpt, " VHT - Vehicle Hours Traveled")
	WriteLine(txtrpt, "   Buffer width")	
	WriteLine(txtrpt, "             ,       1 mi.,       2 mi.,       3 mi.,       4 mi.")
	WriteLine(txtrpt, " Auto (not truck)")
	WriteLine(txtrpt, " NoBuild   , " 	+ Lpad(Format(nbvhtauto241sum,  "*0.0"),12)
								+ ","	+ Lpad(Format(nbvhtauto242sum,  "*0.0"),12)
								+ ","		+ Lpad(Format(nbvhtauto243sum,  "*0.0"),12)
								+ ","		+ Lpad(Format(nbvhtauto244sum,  "*0.0"),12)  )  
	WriteLine(txtrpt, " Build      ," 	+ Lpad(Format(buvhtauto241sum,  "*0.0"),12) 
								+ ","		+ Lpad(Format(buvhtauto242sum,  "*0.0"),12)
								+ ","		+ Lpad(Format(buvhtauto243sum,  "*0.0"),12)
								+ ","		+ Lpad(Format(buvhtauto244sum,  "*0.0"),12) ) 
	WriteLine(txtrpt, " Savings    ," 	+ Lpad(Format(savvhtauto241sum, "*0.0"),12)
								+ ","		+ Lpad(Format(savvhtauto242sum, "*0.0"),12) 
								+ ","		+ Lpad(Format(savvhtauto243sum, "*0.0"),12)
								+ ","		+ Lpad(Format(savvhtauto244sum, "*0.0"),12) ) 
	WriteLine(txtrpt, " ")
	WriteLine(txtrpt, " Truck")
	WriteLine(txtrpt, " NoBuild    ," 	+ Lpad(Format(nbvhttruck241sum,  "*0.0"),12)
								+ ","		+ Lpad(Format(nbvhttruck242sum,  "*0.0"),12) 
								+ ","		+ Lpad(Format(nbvhttruck243sum,  "*0.0"),12) 
								+ ","		+ Lpad(Format(nbvhttruck244sum,  "*0.0"),12)  )
	WriteLine(txtrpt, " Build      ," 	+ Lpad(Format(buvhttruck241sum,  "*0.0"),12) 
								+ ","		+ Lpad(Format(buvhttruck242sum,  "*0.0"),12)
								+ ","		+ Lpad(Format(buvhttruck243sum,  "*0.0"),12) 
								+ ","		+ Lpad(Format(buvhttruck244sum,  "*0.0"),12)  )
	WriteLine(txtrpt, " Savings    ," 	+ Lpad(Format(savvhttruck241sum, "*0.0"),12) 
								+ ","		+ Lpad(Format(savvhttruck242sum, "*0.0"),12) 
								+ ","		+ Lpad(Format(savvhttruck243sum, "*0.0"),12)
								+ ","		+ Lpad(Format(savvhttruck244sum, "*0.0"),12))
	CloseFile(txtrpt)


endmacro  // VMT_VHT_Report

