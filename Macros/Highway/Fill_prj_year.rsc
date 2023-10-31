Macro "Fill_prj_year" (ProjectFile)

	//zg: rewrite future year project processing logic 
	//get project year and store in a hash table
	prj_vw = opentable("projects", "DBASE", {ProjectFile,})
	order = {"Sort Order",{{"INDEX", "Ascending"}}}
	v_id = GetDataVector(prj_vw+"|", "INDEX", {order})
	v_yr = GetDataVector(prj_vw+"|", "YEAR", {order})
	prj_year={}
	for i = 1 to v_id.length do
		if v_yr[i]>0 and v_id[i]>0 then prj_year.(i2s(v_id[i])) = v_yr[i]
	end
	CloseView(prj_vw)
	return(prj_year)
endmacro

