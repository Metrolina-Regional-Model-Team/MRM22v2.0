Macro "DBFieldCheck" (dbfile, dblayer, fieldname, isopen)

	// Macro checks a TC db field  

	// 	and optionally, checks if fields are populated
	//	Inputs
	//		dbfile				TC db file (full path), 
	//		dblayer				name of layer
	//		fieldname				name of field, 
	//		isopen				0 = no, 1 = yes  - user input
	
	//	Returns Code
	//		0 - no issue with field check
	//		1 - file not found
	//		2 - not a TC database
	//		3 - layer not found
	//		4 - field name not found
		

	// Used in	\\RunSetup\\AssnonExistingTripTables
	// is file a db file (no, return 2)
	if dbfile = null then return(1)
	info = GetDBInfo(dbfile)
	if info = null then return(2)

	if isopen = 0 	then layers = RunMacro("TCB Add DB Layers", dbfile)
				else layers = GetDBLayers(dbfile)

	for i = 1 to layers.length do
		if upper(layers[i]) = upper(dblayer) then goto gotlayer
	end
	// layer not found  (return 3)
	return(3)

	gotlayer:
	SetLayer(dblayer)
	curview = GetView()
	SetView(curview)

	dbfields_array = GetFields(dblayer, "All")
	dbfield_names = dbfields_array[1]
	//showarray(dbfield_names)

	for i = 1 to dbfield_names.length do
		if upper(dbfield_names[i]) = upper(fieldname) then do
			// field name found (return 0)
			fieldOK = 0
			goto done
		end // if upper(dbfield_name...
		// fell through - field not found
		fieldOK = 4
	end // for i
	done:
	// close views if they were not already open
	if isopen = 0 then do
		for i = 1 to layers.length do
			SetLayer(layers[i])
			curview = GetView()
			CloseView(curview)
		end  // for i
	end	// if isopen	
	return(fieldOK)
endmacro
