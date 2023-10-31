Macro"Build_HwyNet" (MRMDir, Dir, RunYear, MasterHwyFile, prj_year, Toll_File, HwyName, timeperiod)
//Macro"Build_HwyNet" (MRMDir, Dir, RunYear, MasterHwyFile, prj_year, Toll_File, AMPkHwyName, PMPkHwyName, OPHwyName, timeperiod)

//Returns netview - Hwy file name
// 5/30/19, mk: This version is set up to create three distinct networks: AM peak, PM peak, and offpeak

CreateProgressBar("Build Highway Network", "False")

on escape do
	DestroyProgressBar()
	DisableProgressBar()
	Return()
end

on error default
	info = GetDBInfo(MasterHwyFile)
	scope = info[1]
	// Create a map using this scope
	CreateMap("MetroRoads", {{"Scope", scope},{"Auto Project", "True"}})

	file = MasterHwyFile
	layers = GetDBLayers(file)
	addlayer("MetroRoads", "Endpoints", file, layers[1])
	addlayer("MetroRoads", "MetroRoads", file, layers[2])
	SetLayerVisibility("Endpoints", "True")
	SetIcon("Endpoints|", "Font Character", "Caliper Cartographic|4", 36)
	SetLayerVisibility("MetroRoads", "True")
	solid = LineStyle({{{1, -1, 0}}})
	SetLineStyle("MetroRoads|", solid)
	SetLineColor("MetroRoads|", ColorRGB(0, 0, 32000))
	SetLineWidth("MetroRoads|", 0)
	
	flds = GetFields("MetroRoads", "All")
	nodes = GetFields("Endpoints", "All")

	stat = UpdateProgressBar("Exporting Netxx to " + Dir,4)
	ExportGeography("MetroRoads", Dir + "\\Netxx.dbd",{{"Field Spec",flds[2]}, {"Node Field Spec", nodes[2]}})

closemap("MetroRoads")

	netview = null
	project = null
	select = null
	base = null

	yearselect = S2I(RunYear) + 1
	yearnet = Substring(RunYear, 3, 2)
	variable = Dir + "\\Variables.dbf"
    base =  Dir + "\\BASE_LINKS_net"+yearnet+".dbf"
	select = "Select*where YEAR < " + I2S(yearselect)

	hwyname_ar = {AMPkHwyName, PMPkHwyName, OPHwyName}
	if timeperiod = "AMpeak" then do	
//		if AMPkHwyName <> null 
		if HwyName <> null 
			then netview = HwyName
			else netview = "RegNet"+yearnet+"_AMPeak"
	end
	else if timeperiod = "PMpeak" then do	
		if HwyName <> null 
			then netview = HwyName
			else netview = "RegNet"+yearnet+"_PMPeak"
	end
	else if timeperiod = "Offpeak" then do	
		if HwyName <> null 
			then netview = HwyName
			else netview = "RegNet"+yearnet+"_Offpeak"
	end
	else do
		goto badtimeperiod
	end
		

	// Get the scope of a geographic file
	info = GetDBInfo(Dir + "\\Netxx.dbd")
	scope = info[1]
	// Create a map using this scope

	CreateMap(netview, {{"Scope", scope},{"Auto Project", "True"}})

	file = Dir + "\\Netxx.dbd"
	layers = GetDBLayers(file)
	addlayer(netview, "Endpoints", file, layers[1])
	addlayer(netview, "MetroRoads", file, layers[2])
	SetLayerVisibility("Endpoints", "False")
	SetIcon("Endpoints|", "Font Character", "Caliper Cartographic|4", 36)
	SetLayerVisibility("MetroRoads", "True")
	solid = LineStyle({{{1, -1, 0}}})
	SetLineStyle("MetroRoads|", solid)
	SetLineColor("MetroRoads|", ColorRGB(0, 0, 32000))
	SetLineWidth("MetroRoads|", 0)
 	RenameLayer("MetroRoads", netview, )
	setview(netview)

	if s2i(RunYear) = 2000 then goto skip2000


//______________________________UPDATE SECTION___________________________________________

	
	//select links with any project ids
	nv = netview // alias
	SetView(nv)
	if timeperiod = "AMpeak" then do
		network_qry = "Select * where projnum1 >0 or projnum2>0 or projnum3>0 or projam>0"
		prj_array = {"projnum1", "projnum2", "projnum3", "projam"} 
		prj_ar = {"prj1", "prj2", "prj3", "prjam"} 
	end
	else if timeperiod = "PMpeak" then do
		network_qry = "Select * where projnum1 >0 or projnum2>0 or projnum3>0 or projpm>0"
		prj_array = {"projnum1", "projnum2", "projnum3", "projpm"} 
		prj_ar = {"prj1", "prj2", "prj3", "prjpm"} 
	end
	else if timeperiod = "Offpeak" then do
		network_qry = "Select * where projnum1 >0 or projnum2>0 or projnum3>0"
		prj_array = {"projnum1", "projnum2", "projnum3"} 
		prj_ar = {"prj1", "prj2", "prj3"} 
	end
	else do
//v1=Vector(5,"short",)
//ShowArray(v1)
		goto badtimeperiod
	end
		
	n_recs = SelectByQuery ("project_links", "Several", network_qry,)

	if n_recs> 0 then do
		prj_fields = {"DIR_", "funcl_", "fedfuncl_", "fedfunc_AQ_", "lnsAB_", "lnsBA_", "factyp", "SpdLmt", "SpLRun", "Park_", "Ped_","Devden_", "Drwyden_", "Acntl_", "Aprhb_", "Aleft_", "Athru_", "Arite_", "Bcntl_", "Bprhb_", "Bleft_", "Bthru_", "Brite_"}
		net_fields = {"Dir", "funcl", "fedfuncl", "fedfunc_AQ", "lanesAB","lanesBA","factype","Spdlimit", "SpdLimRun", "parking", "Pedactivity", "Developden", "Drivewayden","A_Control", "A_prohibit","A_LeftLns","A_ThruLns","A_RightLns","B_Control","B_prohibit","B_LeftLns","B_ThruLns","B_RightLns"}    
		dim fn[prj_array.length]//link attribute field names for each project
		for i =1 to prj_array.length do
			fn[i] = CopyArray(prj_fields)
			for j = 1 to prj_fields.length do
				fn[i][j] = fn[i][j] + prj_ar[i]
			end
		end
		//for each link with project ids

		rec = GetFirstRecord(netview+"|project_links",)

		linkcounter = 0
		updatepct = round(n_recs/94,0)
		pbpct = 6

		while rec <> null do

			linkcounter = linkcounter + 1
			if mod(linkcounter, updatepct) = 0 then pbpct = pbpct + 1
			stat = UpdateProgressBar("Processing link " + i2s(linkcounter) + " of " + i2s(n_recs),pbpct)

			my_projects = null //active project list
			for i = 1 to prj_array.length do //for each project section
				my_id_name = prj_array[i]
				my_id = nv.(my_id_name)
				my_year = 0
				if my_id > 0 then do
					my_id = i2s(my_id)
					my_year = prj_year.(my_id)
					if (my_year < yearselect) then do //active project
						mval = GetRecordValues(netview, rec, fn[i])
						temp_prj = {my_year, mval}
						if my_projects = null then my_projects = {temp_prj}
						else my_projects = my_projects + {temp_prj}
					end
				end
			end

			//now we have a set of active projects
			if my_projects.length > 1 then my_projects = SortArray(my_projects) //sort projects by year order
			//else no active or only one active project
			//applying projects by year order
			for i = 1 to my_projects.length do
				my_attr = my_projects[i][2] //atrributes array
				pairs = null //field name/value pairs to be updated
				for j = 1 to prj_fields.length do
					if my_attr[j][2] <> null then do
						if pairs = null then pairs = {{net_fields[j], my_attr[j][2]}}
						else pairs = pairs + {{net_fields[j], my_attr[j][2]}}
					end
				end
				if pairs.length > 0 then SetRecordValues(nv,rec,pairs)
			end

			rec = GetNextRecord(netview+"|project_links", null,)
		end
	end

	
//zg--------------: update toll and hot values based on Toll_File definition
		
    //toll values
	tb_toll = OpenTable("toll_val", "FFB", {Toll_File},)
	order = {"Sort Order",{{"PROJNUM", "Ascending"}, {"YEAR", "Descending"}}} //sort by project then by year (from high to low)
	v_prj = GetDataVector(tb_toll+"|","PROJNUM",{order})
	v_year = GetDataVector(tb_toll+"|","YEAR",{order})
	v_toll_mile = GetDataVector(tb_toll+"|","TOLL_MILE",{order})
	v_toll_gate = GetDataVector(tb_toll+"|","TOLL_GATE",{order})
	v_hot_mile = GetDataVector(tb_toll+"|","HOT_MILE",{order})
	v_hot_gate = GetDataVector(tb_toll+"|","HOT_GATE",{order})
	CloseView(tb_toll)
	
	prev_prj = null
	toll_prj_list= null //list of vaid projects
	for i = 1 to v_prj.length do
		//check if the project is active and valid (toll >0 or hot toll>0)
		if v_year[i]> s2i(RunYear) or (v_toll_mile[i] <=0 and v_toll_gate[i]<=0 and v_hot_mile[i] <=0 and v_hot_gate[i]<=0) then goto next_toll_record
		//if project already found, should skip all other years because records are sorted by year from high to low, first qualified record is the most recent to use 
		if prev_prj = v_prj[i] then goto next_toll_record
		//for a valid project (most recent active year)
		temp_prj = {v_prj[i], v_year[i], v_toll_mile[i], v_toll_gate[i], v_hot_mile[i], v_hot_gate[i]}
		if toll_prj_list = null then toll_prj_list = {temp_prj}
		else toll_prj_list = toll_prj_list + {temp_prj}

		prev_prj = v_prj[i]  
		next_toll_record:
	end

	//clear the toll and HOT fields
	setview(netview)
	v_zero = GetDataVector(netview+"|", "TollAB",)
	for i = 1 to v_zero.length do
		v_zero[i]=0.0
	end
	SetDataVector(netview+"|", "TollAB",v_zero,)
	SetDataVector(netview+"|", "TollBA",v_zero,)

	//clear the HOT fields
	setview(netview)
	v_zero = GetDataVector(netview+"|", "HOTAB",)
	for i = 1 to v_zero.length do
		v_zero[i]=0.0
	end
	SetDataVector(netview+"|", "HOTAB",v_zero,)
	SetDataVector(netview+"|", "HOTBA",v_zero,)

	//now we have a list of projects that are active and unique for most recent year	
	for i = 1 to toll_prj_list.length do
		my_prj = toll_prj_list[i][1]
		my_year = toll_prj_list[i][2]
		my_toll_mile = toll_prj_list[i][3]
		my_toll_gate = toll_prj_list[i][4]
		my_hot_mile = toll_prj_list[i][5]
		my_hot_gate = toll_prj_list[i][6]

		query = "Select * where TOLL_PRJID = " + i2s(my_prj)
		nlinks = SelectByQuery("Toll_Prj_links", "Several", query)
		if (nlinks > 0) then do
   			v_dir = GetDataVector("Toll_Prj_links", "DIR",)
   			v_len = GetDataVector("Toll_Prj_links", "Length",)
   			v_ab_toll = GetDataVector("Toll_Prj_links", "TollAB",)
   			v_ba_toll = GetDataVector("Toll_Prj_links", "TollBA",)
   			
			for k = 1 to v_dir.length do //for each link
				if my_toll_gate>0 then do //gate toll, apply directly
					if (v_dir[k]>-1) then v_ab_toll[k] = my_toll_gate
					if (v_dir[k]<1) then v_ba_toll[k] = my_toll_gate
				end
				else if my_toll_mile > 0 then do //per mile toll
					if (v_dir[k]>-1) then v_ab_toll[k] = my_toll_mile*v_len[k]
					if (v_dir[k]<1) then v_ba_toll[k] = my_toll_mile*v_len[k]
				end 

			end
			//write back toll values
			SetDataVector("Toll_Prj_links", "TollAB",v_ab_toll,)
			SetDataVector("Toll_Prj_links", "TollBA",v_ba_toll,)

		end

		queryHOT = "Select * where HOT_PRJID = " + i2s(my_prj)
		nlinksHOT = SelectByQuery("HOT_Prj_links", "Several", queryHOT)
		if (nlinksHOT > 0) then do
   			vH_dir = GetDataVector("HOT_Prj_links", "DIR",)
   			vH_len = GetDataVector("HOT_Prj_links", "Length",)
   			v_ab_hot = GetDataVector("HOT_Prj_links", "HOTAB",)
   			v_ba_hot = GetDataVector("HOT_Prj_links", "HOTBA",)
   			
			for k = 1 to vH_dir.length do //for each link
				if my_hot_gate>0 then do //gate toll, apply directly
					if (vH_dir[k]>-1) then v_ab_hot[k] = my_hot_gate
					if (vH_dir[k]<1) then v_ba_hot[k] = my_hot_gate
				end
				else if my_hot_mile > 0 then do //per mile toll
					if (vH_dir[k]>-1) then v_ab_hot[k] = my_hot_mile*vH_len[k]
					if (vH_dir[k]<1) then v_ba_hot[k] = my_hot_mile*vH_len[k]
				end 

			end
			//write back toll values
			SetDataVector("HOT_Prj_links", "HOTAB",v_ab_hot,)
			SetDataVector("HOT_Prj_links", "HOTBA",v_ba_hot,)

		end

	end	
//zg---------------end applying toll and HOT values to the network

//___________________________________UPDATE SECTION ENDEDED___________________________________________
	skip2000:

	setview(netview)
	select = "Select*where funcl > 0 and funcl < 10"
	Selectbyquery("funcl", "Several", select,)

	j = GetRecordCount(netview,"funcl")
	i = j/16
	t = 1
	y = i
	k = 58

	hi = GetFirstRecord(netview+"|funcl",)
	while hi <> null do

	if t < i then do
		goto thirdrecordB
		end
	if t > i then do
		i = i + y
		k = k + 1
		goto thirdrecordB
		end
	thirdrecordB:
		stat = UpdateProgressBar("Clearing.....",k)
		if stat = "True" then do
			ShowMessage("You Quit!")
			goto badquit
			end
		mval = GetRecordValues(netview, hi,{"SPpeakAB", "SPpeakBA", "SPfreeAB", "SPfreeBA", "cap1hrAB", "cap1hrBA", "TTfreeAB", "TTfreeBA", "TTpeakAB", "TTpeakBA", "capNightAB", "capNightBA", "IntDelFr_A", "IntDelFr_B", "IntDelPk_A", "IntDelPk_B", "capMidAB", "capMidBA", "capPk3hrAB", "capPk3hrBA", "TTlinkPkAB", "TTlinkPkBA", "TTlinkFrAB", "TTlinkFrBA", "TTPkLocAB", "TTPkLocBA", "TTPkXprAB", "TTPkXprBA", "TTFrXprAB", "TTFrXprBA", "TTFrLocAB", "TTFrLocBA", "TTwalkAB", "TTwalkBA","TTPkPrevAB", "TTPkPrevBA", "TTPkAssnAB", "TTPkAssnBA"})

		clear = null

	SetRecordValues(netview,null,{{"SPpeakAB", clear},{"SPpeakBA", clear},{"SPfreeAB", clear},
		{"SPfreeBA", clear},{"cap1hrAB", clear},{"cap1hrBA", clear},{"TTfreeAB", clear},
		{"TTfreeBA", clear},{"TTpeakAB", clear},{"TTpeakBA", clear},{"capNightAB", clear},
		{"capNightBA", clear},{"capMidAB", clear},{"capMidBA", clear},{"capPk3hrAB", clear},
		{"capPk3hrBA", clear},{"TTlinkpkAB", clear},{"TTlinkpkBA", clear},{"TTlinkfrAB", clear},
		{"TTlinkfrBA", clear},{"TTpkLocAB", clear},{"TTpkLocBA", clear},{"TTpkXprAB", clear},
		{"TTpkXprBA", clear},{"TTFrXprAB", clear},{"TTFrXprBA", clear},{"TTFrLocAB", clear},
		{"TTFrLocBA", clear},{"TTwalkAB", clear},{"TTwalkBA", clear},{"IntDelFr_A", clear},
		{"IntDelFr_B", clear},{"IntDelPk_A", clear},{"IntDelPk_B", clear},{"TTPkPrevAB", clear},
		{"TTPkPrevBA", clear},{"TTPkAssnAB", clear},{"TTPkAssnBA", clear}})
	hi = GetNextRecord(netview+"|funcl", null, )
	t = t + 1
	end


	SetLayer(netview)
	qry = "Select*where funcl > 0 and funcl < 900 and Level <> 3"
	k = k + 5
	SelectByQuery("Selection", "Several", qry,)

	flds = GetFields(netview, "All")
	nodes = GetFields("Endpoints", "All")

	k = k + 6
	stat = UpdateProgressBar("Exporting "+netview+".dbd to " + Dir,k)
	ExportGeography(netview+"|Selection", Dir + "\\"+netview+".dbd",{{"Field Spec",flds[2]}, {"Node Field Spec", nodes[2]}})

closemap()

RunMacro("G30 File Close All")

goto quit

badtimeperiod:
		msg = msg + {"Highway Network Time period error"}
		AppendToLogFile(1, "Build_HwyNet: Error: - Time period error")
		ShowItem(" Error/Warning messages ")
		ShowItem("netmessageslist")
		goto quit


badquit:
	DestroyProgressBar()
	DisableProgressBar()
	return()

quit:
	DestroyProgressBar()
	DisableProgressBar()
//	showmessage("hwy name = " + netview)	
//	on error, notfound goto quit2
	DeleteDataBase(Dir + "\\Netxx.dbd")

	return(netview)

quit2:
//	AppendToLogFile(1, "Error Deleting netxx.dbd")
	on error, notfound default
	return(netview)

endmacro

