Macro "IsFileOpen" (file)
	// returns 1 if file is already open (In list of views), 0 if not
	//  uses \MRMFunctions\gettheviews
	// used in \MRMFunctions\TAZ_LandUseCheck
	{viewlist, currentview, currentviewndx, viewsinfo} = RunMacro("gettheviews")
	if viewsinfo = null then return(0)
	for i = 1 to viewsinfo.length do
		if upper(viewsinfo[i][2]) = upper(file) then return(1)
	end // for i
	// fell through - not in views
	return(0)	
endmacro
