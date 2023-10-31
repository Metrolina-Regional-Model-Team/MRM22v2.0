macro "menu"
	on notFound goto next
	RemoveMenuItem("MRM1501")
	RemoveMenuItem("MRM1502")
	RemoveMenuItem("MRM1503")
	RemoveMenuItem("MRM1402")
	RemoveMenuItem("MRM14v1.0")
	RemoveMenuItem("MRM15v1.0")
	RemoveMenuItem("MRM15v1.1")
	RemoveMenuItem("MRM16v1.0")
     	RemoveMenuItem("MRM16v1.1")
     	RemoveMenuItem("MRM17v1.0")
     	RemoveMenuItem("MRM18v1.0")
     	RemoveMenuItem("MRM18v1.1")
     	RemoveMenuItem("MRM1901")
     	RemoveMenuItem("MRM1901_PPSL")
     	RemoveMenuItem("MRM19v1.0")
     	RemoveMenuItem("MRM2001")
	next: on NotFound default
	AddMenuItem("MRM2002_LT", "Before", "Window")
endMacro

Menu "TCMenu"
	MenuItem "MRM2002_LT" text:"MRM2002_LT" key: alt_b
		menu "moose"
endmenu

Menu "Utilities"

      MenuItem "M_Utils" text: "Model Utilities"
		menu "Model_Utils"
EndMenu



Menu "moose"

	MenuItem "MRM2002_LT" text:"MRM2002_LT" key: alt_b
		do
			RunDBox("MasterDBox")
		enditem
     Separator 
	MenuItem "Model Utilities" Text:"Model Utilities"
		menu "Model_Utils"

EndMenu

//Model Utility Menu

Menu "Model_Utils"
	menuitem "Transit ChangeHwy" Text:"Change Transit-Highway File"
		do
			on escape goto endchghwy
			on error goto errchghwy				
			Dir = choosedirectory("Please choose directory with highway & transit netowrks:",)
		
			net_file = ChooseFile({{"Standard (*.dbd)","*.dbd"}},
					"Choose highway file", {{"Initial Directory", Dir}})
			file_parts = SplitPath(net_file)
			netname = file_parts[3]
			route_file = Dir + "\\transys.rts"
			
			ModifyRouteSystem(route_file, {{"Geography", net_file, netname},
				{"Link ID", "ID"}})

			goto endchghwy
			
			errchghwy:
			ShowMessage("Utilities - Transit Change Hwy - ERROR!")
		
			endchghwy:
			on escape default
			on error default
		enditem


	menuitem "Remove Toolbar" Text:"Remove Progress Toolbar"
		do
		   	on error goto endremovetoolbar
		   	on notfound goto endremovetoolbar
		   	DestroyProgressBar()
	   		endremovetoolbar:
		   	on error default
		   	on notfound default
		endItem

	menuitem "TAZNeighbors" Text:"Run TAZ Neighbors (zone_pct)"
		do
		   	on error goto endtazneighbors
		   	on notfound goto endtazneighbors
		   	RunDBox("AreaType_TAZNeighbors")
	   		endtazneighbors:
		   	on error default
		   	on notfound default
		endItem


	menuitem "Close All" Text:"Close All"
		do
 			RunMacro("G30 File Close All")
		endItem


EndMenu
