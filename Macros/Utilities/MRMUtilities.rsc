DBox "MRMUtilities" (Args) , top Title: "MRM Utilities"
//  DBox for model utilities

//	Add open transit system
//			modify route sys
//			reload / verify
//			open routes.dbf
		
//	Add RunMatrixTemplate
//	Add CheckTAZ

//  Modify transit routes = search for dir / regnet - offer chance to enter

	Init do
		UtilitiesOK = 1
		msg = null
	enditem

	Frame 1,1,28,25 Prompt: "MRM Utilities"

	Button " TAZ Neighbors pct " 2.0, 3.5, 25 Help: "Create \\TAZ\\TAZNeighbors_pct file (formerly zone_pct) " do
   		RunDBox("AreaType_TAZNeighbors")
	endItem


	Text " " same, after, , 0.5
	Button "Transit Change Hwy" same, after, 25 Help:"Set directory and highway system for transys.rts" 	do
		Dir = Args.[Run Directory].value
		HwyName = Args.[Hwy Name].value
		on error goto tranchhwyerr				

		route_file = Dir + "\\transys.rts"
		net_file = Dir + "\\" + HwyName + ".dbd"

		ModifyRouteSystem(route_file, {{"Geography", net_file, netname},{"Link ID", "ID"}})

		goto quittranchhwy
		tranchhwyerr:
		on error default
		msg = msg + {"MRM Utilities - Transit Change Hwy - ERROR!"}
		UtilitiesOK = 3
		return({UtilitiesOK, msg})
		quittranchhwy:
	endItem


	Text " " same, after, , 0.5
	Button " Run Matrix_Template " 2.0, after, 25 Help: "Create Matrix Template and TAZID files" do
		TAZFile = Args.[TAZ File].value
		exist = GetFileInfo(TAZFile)
		if exist = null
			then do
				msg = msg + {"MRM Utilities ERROR! - TAZ file not found (create matrix template)"}
				UtilitiesOK = 3
				return({UtilitiesOK, msg})
			end
  		RunMacro("Matrix_Template" , TAZFile)
	endItem


	Text " " same, after, , 0.5
	Button " Check Land Use / TAZ " 2.0, after, 25 Help: "Check that TAZ matches land use file" do
		TAZFile = Args.[TAZ File].value
		LUFile = Args.[LandUse File].value
		exist = GetFileInfo(TAZFile)
		if exist = null
			then do
				msg = msg + {"MRM Utilities ERROR! - TAZ file not found"}
				UtilitiesOK = 3
				return({UtilitiesOK, msg})
			end
		exist = GetFileInfo(LUFile)
		if exist = null
			then do
				msg = msg + {"MRM Utilities ERROR! - Land Use file not found"}
				UtilitiesOK = 3
				return({UtilitiesOK, msg})
			end
  		RunMacro("checkLU", LUFile, TAZFile)
	endItem


	Text " " same, after, , 0.5
	Button " Destroy Progress Bar " 2.0, after, 25 Help: "Get rid of lingering progress bar" do
	    	on error, notfound goto quitkillpbar
	    	DestroyProgressBar()
		quitkillpbar:
		on error, notfound default
	endItem


	Text " " same, after, , 0.5
	Button " Clear All " 2.0, after, 25 Help: "TransCad Close All Utility" do
   		RunMacro("G30 File Close All")
	endItem


	Text " " same, after, , 0.5
	Text " Exit   " 2, after
	Button " " after, same Icon: "bmp\\buttons|440" Help: "Exit to main menu" Cancel do	
		return({UtilitiesOK, msg})
	enditem

enddbox
