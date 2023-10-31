macro "project_toolbox" 

//TO DO:   
//Add DisableItem in the delete button to kill itself
//Add selection set to project file - 
//Show Legend seems to burp a bit before working

//If not master network - warn that edits will not mean schitte, you can work the project file though

//Attributes only set - remove these from new / widen / delete / changedir

//Change shape of main box - move three secondary buttons down a row

//Add a project?
//	will need to add to project file
//	bring up window with editable fields - not a bad thing to bring up anyway

//Threaten editing for master network and project file - offer (and implement) backup and open new file
//Add EvaWeight - 10 more fields on project file - default them to 1.0

//+++++++++++++   START SARA NEW MACRO   +++++++++++++++

	global Dir, Location, startyear, endyear, horizon1, horizon2, horizon3, altname, netview 




		LineView = null
		lyr_info = null
		lyr_check = getview()
		if lyr_check = null then goto OpenMap
				    else goto PickALayer

		OpenMap:
		on escape do
			return()
		end
    		geo_file = ChooseFile({{"Standard (*.dbd)","*.dbd"}},"Choose a Network File", )
		info = GetDBInfo(geo_file)
		scope = info[1]
		layers = GetDBLayers(geo_file)
		CreateMap(layers[2], {{"Scope", scope},{"Auto Project", "True"}})
		//addlayer(layers[2], layers[1], geo_file, layers[1])
		addlayer(layers[2], layers[2], geo_file, layers[2])
		//SetIcon(layers[1]+"|", "Font Character", "Caliper Cartographic|2", 36)
		SetLineStyle(layers[2]+"|", LineStyle({{{1, -1, 0}}}))
		SetLineColor(layers[2]+"|", ColorRGB(0, 0, 32000))
		SetLineWidth(layers[2]+"|", 0)
		//SetLayerVisibility(layers[1], "True")
		SetLayerVisibility(layers[2], "True")

		PickALayer:
		lyr_info = GetLayers()
		if lyr_info = null then goto OpenMap
		LineArrayPos = 0
		for i = 1 to lyr_info[1].length do
			typei = GetLayerType(lyr_info[1][i])
			if typei = "Line" then do
				if LineArrayPos = 0 then do
					LineArray = {lyr_info[1][i]}
					LineArrayPos = LineArrayPos + 1     
				end  //if LineArrayPos
				else do
					LineArray = InsertArrayElements(LineArray, LineArrayPos, {lyr_info[1][i]})			
					LineArrayPos = LineArrayPos + 1     
				end //else do
			end // if typei		
		end //for i

		if LineArrayPos = 1 then do
			SetLayer(LineArray[1])
			LineView = GetView()
		end
		else runDBox("LinePicker", LineArray, &LineView)
		if LineView = null then goto OpenMap




//get year
	redo:
	rundbox("yeargetter")
	

//goto skiptoend

	Proj_File = ChooseFile({{"DBASE (*.dbf)", "*.dbf"}},"Choose the Project list file",)
	Proj_View = OpenTable("Proj_View", "DBASE", {Proj_File}, {{"Read Only", "False"},{"Shared", "False"}})
	SetView("Proj_View")

	SetView("Proj_View")
               qry1 = "select * where Year>= "+startyear+ " and year<="+horizon1
               n1= SelectByQuery("HORIZON_1","Several",qry1,)
               qry2 = "select * where Year> "+horizon1+ " and year<="+horizon2
               n2= SelectByQuery("HORIZON_2","Several",qry2,)
               qry3 = "select * where Year> "+horizon2+ " and year<="+horizon3
               n3= SelectByQuery("HORIZON_3","Several",qry3,)
               Project_set1 = GetDataVector("Proj_View|HORIZON_1","Index",)
               Project_set2 = GetDataVector("Proj_View|HORIZON_2","Index",)
               Project_set3 = GetDataVector("Proj_View|HORIZON_3","Index",)
                
               ProjLines1=startyear+"_"+horizon1 
               ProjLines2=horizon1+"_"+horizon2 
               ProjLines3=horizon2+"_"+horizon3   
          
//create selection sets
		SetView(LineView)
		sets_array = GetSets(LineView)

		
                CreateSet("future_lines")
                widedashedline = Linestyle({{{1,-1,0,1,4}}})
                SetLineStyle(LineView + "|future_lines", widedashedline) 
		SetLineWidth(LineView + "|future_lines", 1.5) 
		SetLineColor(LineView + "|future_lines", ColorRGB(65535,65535,65535)) 
		SetDisplayStatus(LineView + "|future_lines", "Invisible")
		CreateSet(ProjLines1)
		SetLineWidth(LineView + "|"+ProjLines1, 3) 
		SetLineColor(LineView + "|"+ProjLines1, ColorRGB(65535,0,0)) 
		SetDisplayStatus(LineView + "|"+ProjLines1, "Active")
                CreateSet(ProjLines2)
		SetLineWidth(LineView + "|"+ProjLines2, 3) 
		SetLineColor(LineView + "|"+ProjLines2, ColorRGB(0,32896,65535)) 
		SetDisplayStatus(LineView + "|"+ProjLines2, "Active")
                CreateSet(ProjLines3)
		SetLineWidth(LineView + "|"+ProjLines3, 3) 
		SetLineColor(LineView + "|"+ProjLines3, ColorRGB(0,32896,0)) 
		SetDisplayStatus(LineView + "|"+ProjLines3, "Active")
                CreateSet("Cc")
		SetLineWidth(LineView + "|Cc", 1.5) 
		SetLineColor(LineView + "|Cc", ColorRGB(24576,0,49152)) 
		SetDisplayStatus(LineView + "|Cc", "Invisible")
                
               		
//Define Selections 
		//whole project	

		SetView(LineView)
                Cc = "Select * where funcl = 90"
	        c1= SelectByQuery("Cc","more",Cc,)

                future_lines = "Select * where funcl > 900"
	        f1= SelectByQuery("future_lines","more",future_lines,)

                for i = 1 to n1 do
		projlines1 = "Select * where projnum1 = " + i2s(Project_set1[i]) + " or projnum2 = " + i2s(Project_set1[i]) + " or projnum3 = " + i2s(Project_set1[i])
	        m1= SelectByQuery(ProjLines1,"more",projlines1,)
                end

                for i = 1 to n2 do
		projlines2 = "Select * where projnum1 = " + i2s(Project_set2[i]) + " or projnum2 = " + i2s(Project_set2[i]) + " or projnum3 = " + i2s(Project_set2[i])
	        m2= SelectByQuery(ProjLines2,"more",projlines2,)
                end

                for i = 1 to n3 do
		projlines3 = "Select * where projnum1 = " + i2s(Project_set3[i]) + " or projnum2 = " + i2s(Project_set3[i]) + " or projnum3 = " + i2s(Project_set3[i])
	        m3= SelectByQuery(ProjLines3,"more",projlines3,)
                end



 //ShowArray(Project_set)
endmacro

//goto skiptoend



//skiptoend:

dbox "yeargetter" Title: "Year Range?"

     


	Edit Text "base year" 12, 1, 10 prompt:"base Year" variable: startyear
        Edit Text "horizon 1" 12, 2.5, 10  prompt:"horizon 1" variable: horizon1
        Edit Text "horizon 2" 12, 4, 10  prompt:"horizon 2" variable: horizon2
        Edit Text "horizon 3" 12, 5.5, 10  prompt:"horizon 3" variable: horizon3
	




	Button "Continue" 2, 8, 8, 1 default do
	istartyear=s2i(startyear)
        ihorizon1=s2i(horizon1)
        ihorizon2=s2i(horizon2)
        ihorizon3=s2i(horizon3)
         
	Return(1)
        	endItem

enddbox










