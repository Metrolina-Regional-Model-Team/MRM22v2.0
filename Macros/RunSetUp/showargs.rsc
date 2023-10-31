dbox "showargs"  (Args) left,top ToolBox Title: "Arguments File"
	// Dialog box with current value of arguments - some can be changed here
	
	init do	
		RunMacro("initbox")
	enditem	 
		 
	Text "argsdir" 20, 1.5, 40 Framed Prompt: "Run Directory" Variable: Args.[Run Directory].Value
	Text "argsmrm" 20, after, 40 Framed Prompt: "MRM Directory" Variable: Args.[MRM Directory].Value
	Text "argsmet" 20, after, 40 Framed Prompt: "MET Directory" Variable: Args.[MET Directory].Value
	Text "argsyear" 20, after, 15 Framed Prompt: "Run Year" Variable: Args.[Run Year].Value
	Edit Text "argsscen" 20, after, 40 Prompt: "Scenario Name" Variable: argsscenname
	Text "modeltype" 20, after, 15 Framed Prompt: "Model Type" Variable: Args.[Model Type].Value
	Text "argstaz" 20, after, 60 Framed Prompt: "TAZ File" Variable: Args.[TAZ file].Value
	Text "argslu" 20, after, 60 Framed Prompt: "Land Use File" Variable: Args.[LandUse file].Value
	Edit Text "argsampkhwy" 20, after, 20 Prompt: "AMPeakHwyName" Variable: argsampkhwyname
	Edit Text "argspmpkhwy" 20, after, 20 Prompt: "PMPeakHwyName" Variable: argspmpkhwyname
	Edit Text "argsophwy" 20, after, 20 Prompt: "OffpeakHwyName" Variable: argsophwyname
	Text "argslog" 20, after, 60 Framed Prompt: "Log File" Variable: Args.[Log File].value
	Text "argsrpt" 20, after, 60 Framed Prompt: "Report File" Variable: Args.[Report File].value
	Edit Real "argstw" 20, after, 10 Prompt: "Impedance Time Wgt" Variable: argstimewgt
	Edit Real "argsdw" 50, same, 10 Prompt: "Impedance Dist Wgt" Variable: argsdistwgt
	Edit Integer "argsiter" 20, after, 10 Prompt: "AM feedback skim-assn iter" Variable: argsitertot
	Edit Integer "argscuriter" 50, same, 10 Prompt: "AM feedback cur iter" Variable: argsitercur
	Edit Integer "argshotiter" 20, after, 10 Prompt: "HOT model iter" Variable: argsiterhot
	Edit Real "argsacv" 20, after, 10 Prompt: "Converge-Feedback" Variable: argsbasehwyconverge
	Edit Integer "argsait" 50, same, 10 Prompt: "TC MMA Iter-Feedback" Variable: argsbasehwyiter
	Edit Real "argsacvf" 20, after, 10 Prompt: "Converge-Final" Variable: argsfinalhwyconverge
	Edit Integer "argsaitf" 50, same, 10 Prompt: "TC MMA Iter-Final" Variable: argsfinalhwyiter
	Text "argsver" 20, after, 10 Framed Prompt: "TransCad Version" Variable: r2s(Args.[Version].value)
	Text "argsbld" 50, same, 10 Framed Prompt: "TC Build" Variable: r2s(Args.[Build].value)
	
	Text " " same, after, , 1.0

	Button " Save Args " 23.5, after, 15 do
		Dir = Args.[Run Directory].value
		ArgsInfo = GetFileInfo(Dir + "\\Arguments.args")
		if ArgsInfo = null
			then do
				ShowMessage("You do not have an arguments file to save")
			end
			else do
				Warnbox = null
				if Args.[AM Peak Hwy Name].value <> argsampkhwyname
					then do
						WarnBox = WarnBox + "Replace AM Peak Highway file name with: " + argsampkhwyname + "?" + "\n"
						chgampkhwyname = 1
					end		
				if Args.[PM Peak Hwy Name].value <> argspmpkhwyname
					then do
						WarnBox = WarnBox + "Replace PM Peak Highway file name with: " + argspmpkhwyname + "?" + "\n"
						chgpmpkhwyname = 1
					end		
				if Args.[Offpeak Hwy Name].value <> argsophwyname
					then do
						WarnBox = WarnBox + "Replace Peak Highway file name with: " + argsophwyname + "?" + "\n"
						chgophwyname = 1
					end		
				if Args.[Scenario Name].value <> argsscenname
					then do
						WarnBox = WarnBox + "Replace Scenario Name with: " + argsscenname + "?" + "\n"
						chgscenname = 1
					end
				if Args.[TimeWeight].value <> argstimewgt
					then do 
						WarnBox = WarnBox + "Replace Impedance Time Weight with: " + r2s(argstimewgt) + "?" + "\n"
						chgtimewgt = 1	
					end
				if Args.[DistWeight].value <> argsdistwgt
					then do
						WarnBox = WarnBox + "Replace Impedance Distance Weight with: " + r2s(argsdistwgt) + "?" + "\n"
						chgdistwgt = 1
					end		
				if Args.[Feedback Iterations].value <> argsitertot
					then do
						WarnBox = WarnBox + "Change number of peak feedback speed iterations to: " + i2s(argsitertot) + "?" + "\n"
						chgitertot = 1
					end		
				if Args.[Current Feedback Iter].value <> argsitercur
					then do
						WarnBox = WarnBox + "Change current peak feedback iteration to: " + i2s(argsitercur) + "?" + "\n"
						chgitercur = 1	
					end
				if Args.[HOTAssn Iterations].value <> argsiterhot
					then do
						WarnBox = WarnBox + "Change number of HOT Highway assignment iterations to: " + i2s(argsiterhot) + "?" + "\n"
						chgiterhot = 1
					end	
				if Args.[HwyAssn Converge Feedback].value <> argsbasehwyconverge
					then do
						WarnBox = WarnBox + "Change highway assignment convergence for intermediate steps to: "  
							+ r2s(argsbasehwyconverge) + "?" + "\n"
						chgbasehwyconverge = 1
					end		
				if Args.[HwyAssn Max Iter Feedback].value <> argsbasehwyiter
					then do
						WarnBox = WarnBox + "Change highway assignment max no. iterations for intermediate steps to: "
							 + i2s(argsbasehwyiter) + "?" + "\n"
						chgbasehwyiter = 1	
					end
				if Args.[HwyAssn Converge Final].value <> argsfinalhwyconverge
					then do
						WarnBox = WarnBox + "Change highway assignment convergence for final assignment to: "
							 + r2s(argsfinalhwyconverge) + "?" + "\n"
						chgfinalhwyconverge = 1
					end	
				if Args.[HwyAssn Max Iter Final].value <> argsfinalhwyiter
					then do
						WarnBox = WarnBox + "Change highway assignment max no. iterations for final assignment to: "
							 + r2s(argsfinalhwyiter) + "?" + "\n"
						chgfinalhwyiter = 1
					end		

				button = MessageBox(WarnBox,  
					{{Caption, "Do you want to save these changes?"}, {"Buttons", "YesNo"},
	 				 {"Icon", "Warning"}})
				if button = "Yes"
					then do
						if chgscenname = 1 then do
							msg = msg + {"ShowArgs: Scenario name changed from " + Args.[Scenario Name].Value + " to " + argsscenname}
							Args.[Scenario Name].Value = argsscenname
						end
						if chgampkhwyname = 1 then do 	
							msg = msg + {"ShowArgs: AM Peak highway file name changed from " + Args.[AM Peak Hwy Name].Value + " to " + argsampkhwyname}
							Args.[AM Peak Hwy Name].Value = argsampkhwyname
						end
						if chgpmpkhwyname = 1 then do 	
							msg = msg + {"ShowArgs: PM Peak highway file name changed from " + Args.[PM Peak Hwy Name].Value + " to " + argspmpkhwyname}
							Args.[PM Peak Hwy Name].Value = argspmpkhwyname
						end
						if chgophwyname = 1 then do 	
							msg = msg + {"ShowArgs: Offpeak highway file name changed from " + Args.[Offpeak Hwy Name].Value + " to " + argsophwyname}
							Args.[Offpeak Hwy Name].Value = argsophwyname
						end
						if chgtimewgt = 1 then do
							msg = msg + {"ShowArgs: Impedance time weight changed from " + r2s(Args.[TimeWeight].Value) + " to "
								 + r2s(argstimewgt)}
							Args.[TimeWeight].Value = argstimewgt
						end
						if chgdistwgt = 1 then do
							msg = msg + {"ShowArgs: Impedance distance weight changed from " + r2s(Args.[DistWeight].Value) + " to " 
								+ r2s(argsdistwgt)}
							Args.[DistWeight].Value = argsdistwgt
						end
						if chgitertot = 1 then do
							msg = msg + {"ShowArgs: Total peak speed feedback iterations changed from "
								 + i2s(Args.[Feedback Iterations].Value) + " to " +  i2s(argsitertot)}
							Args.[Feedback Iterations].Value = argsitertot
						end
						if chgitercur = 1 then do
							msg = msg + {"ShowArgs: Current peak speed feedback iteration changed from "
								 + i2s(Args.[Current Feedback Iter].Value) + " to " + i2s(argsitercur)}
							Args.[Current Feedback Iter].Value = argsitercur
						end
						if chgiterhot = 1 then do
							msg = msg + {"ShowArgs: HOT Assignment iterations changed from "
								 + i2s(Args.[HOTAssn Iterations].Value) + " to " + i2s(argsiterhot)}
							Args.[HOTAssn Iterations].Value = argsiterhot
						end
						if chgbasehwyconverge = 1 then do	
							msg = msg + {"ShowArgs: Convergence for intermediate highway assignment changed from " 
								+ r2s(Args.[HwyAssn Converge Feedback].Value) + " to " + r2s(argsbasehwyconverge)}
							Args.[HwyAssn Converge Feedback].value = argsbasehwyconverge
						end
						if chgbasehwyiter = 1 then do	
							msg = msg + {"ShowArgs: Maximum iterations for intermediate highway assignment changed from " 
								+ i2s(Args.[HwyAssn Max Iter Feedback].Value) + " to " + i2s(argsbasehwyiter)}
							Args.[HwyAssn Max Iter Feedback].value = argsbasehwyiter
						end
						if chgfinalhwyconverge = 1 then do	
							msg = msg + {"ShowArgs: Convergence for final highway assignment changed from "
								 + r2s(Args.[HwyAssn Converge Final].Value) + " to " + r2s(argsfinalhwyconverge)}
							Args.[HwyAssn Converge Final].value = argsfinalhwyconverge
						end
						if chgfinalhwyiter = 1 then do	
							msg = msg + {"ShowArgs: Maximum iterations for final highway assignment changed from " 
									+ i2s(Args.[HwyAssn Max Iter Final].Value) + " to " + i2s(argsfinalhwyiter)}
							Args.[HwyAssn Max Iter Final].value = argsfinalhwyiter
						end

						SaveArray(Args, Dir + "\\Arguments.args")
					end	//Button = Yes
				
				// Button = No
				else RunMacro("initbox")
					
			end // else
	enditem

	Text " " same, after, , 1.0

	Button " Return " 23.5, after, 15 Help: "Back to MRM"  Cancel do
		RunMacro("G30 File Close All")
		return(msg)
	enditem

	Text " " same, after, , 0.25

	Macro "initbox" do
		msg = null

		chgscenname = 0
		chghwyname = 0	
		chgtimewgt = 0	
		chgdistwgt = 0	
		chgitertot = 0	
		chgitercur = 0	
		chgiterhot = 0	
		chgbasehwyconverge = 0	
		chgbasehwyiter = 0	
		chgfinalhwyconverge = 0	
		chgfinalhwyiter = 0	

		argsscenname = Args.[Scenario Name].Value
		argsampkhwyname = Args.[AM Peak Hwy Name].Value
		argspmpkhwyname = Args.[PM Peak Hwy Name].Value
		argsophwyname = Args.[Offpeak Hwy Name].Value
		argstimewgt =  Args.[TimeWeight].Value
		argsdistwgt = Args.[DistWeight].Value
		argsitertot = Args.[Feedback Iterations].Value
		argsitercur = Args.[Current Feedback Iter].Value
		argsiterhot =  Args.[HOTAssn Iterations].Value
		argsbasehwyconverge = Args.[HwyAssn Converge Feedback].value
		argsbasehwyiter = Args.[HwyAssn Max Iter Feedback].value
		argsfinalhwyconverge = Args.[HwyAssn Converge Final].value
		argsfinalhwyiter = Args.[HwyAssn Max Iter Final].value
	enditem
	
	close do
		RunMacro("G30 File Close All") 
		return(msg)
	enditem


EndDBox