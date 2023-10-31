dbox "Findbuttons"
init do
	startrange = 210
	
enditem
	Edit Text "runyear" 10, 1, 10  Prompt: "Start Range:" Variable: startrange Help:"Start gittin eye-cons" do
//		EnableItem("no01")
//		EnableItem("no02")
//		EnableItem("no03")
//		EnableItem("no04")
//		EnableItem("no05")
//		EnableItem("no06")
//		EnableItem("no07")
//		EnableItem("no08")
//		EnableItem("no09")
//		EnableItem("no10")
//		EnableItem("no11")
//		EnableItem("no12")
//		EnableItem("no13")
//		EnableItem("no14")
//		EnableItem("no15")
//		EnableItem("no16")
//		EnableItem("no17")
//		EnableItem("no18")
//		EnableItem("no19")
//		EnableItem("no20")
//		EnableItem("no21")
//		EnableItem("no22")
//		EnableItem("no23")
//		EnableItem("no24")
//		EnableItem("no25")
enditem


	Text 3,2.5 Variable: startrange 
    button "no01" 8, 2.5 Icon: "bmp\\buttons|" + i2s(startrange) do
//    button "no01" 8, 2.5 Icon: "bmp\\buttons|" + i2s(startrange) Disabled do
    enditem
    
	Text 3,4.0 Variable: startrange+1 
    button "no02" 8, 4.0 Icon: "bmp\\buttons|" + i2s(startrange+1) do
    enditem
 
 	Text 3,5.5 Variable: startrange+2 
    button "no03" 8, 5.5 Icon: "bmp\\buttons|" + i2s(startrange+2) do
    enditem
 	
	Text 3,7.0 Variable: startrange+3 
    button "no04" 8, 7.0 Icon: "bmp\\buttons|" + i2s(startrange+3) do
    enditem
 
 	Text 3,8.5 Variable: startrange+4 
    button "no05" 8, 8.5 Icon: "bmp\\buttons|" + i2s(startrange+4) do
    enditem
 	
	Text 3,10.0 Variable: startrange+5 
    button "no06" 8, 10.0 Icon: "bmp\\buttons|" + i2s(startrange+5) do
    enditem
 
 	Text 3,11.5 Variable: startrange+6 
    button "no07" 8, 11.5 Icon: "bmp\\buttons|" + i2s(startrange+6) do
    enditem
 	
	Text 3,13.0 Variable: startrange+7 
    button "no08" 8, 13.0 Icon: "bmp\\buttons|" + i2s(startrange+7) do
    enditem
 
 	Text 3,14.5 Variable: startrange+8 
    button "no09" 8, 14.5 Icon: "bmp\\buttons|" + i2s(startrange+8) do
    enditem

	Text 3,16.0 Variable: startrange+9 
    button "no10" 8, 16.0 Icon: "bmp\\buttons|" + i2s(startrange+9) do
    enditem
 
 	Text 3,17.5 Variable: startrange+10 
    button "no11" 8, 17.5 Icon: "bmp\\buttons|" + i2s(startrange+10) do
    enditem
 	
	Text 3,19.0 Variable: startrange+11 
    button "no12" 8, 19.0 Icon: "bmp\\buttons|" + i2s(startrange+11) do
    enditem
 
 	Text 3,20.5 Variable: startrange+12 
    button "no13" 8, 20.5 Icon: "bmp\\2buttons|" + i2s(startrange+12) do
    enditem
 	
	Text 3,22.0 Variable: startrange+13 
    button "no14" 8, 22.0 Icon: "bmp\\buttons|" + i2s(startrange+13) do
    enditem
 
 	Text 3,23.5 Variable: startrange+14 
    button "no15" 8, 23.5 Icon: "bmp\\buttons|" + i2s(startrange+14) do
    enditem
 	
	Text 3,25.0 Variable: startrange+15 
    button "no16" 8, 25.0 Icon: "bmp\\buttons|" + i2s(startrange+15) do
    enditem
 
 	Text 3,26.5 Variable: startrange+16 
    button "no17" 8, 26.5 Icon: "bmp\\buttons|" + i2s(startrange+16) do
    enditem
 	
	Text 3,28.0 Variable: startrange+17 
    button "no18" 8, 28.0 Icon: "bmp\\buttons|" + i2s(startrange+17) do
    enditem
 
 	Text 3,29.5 Variable: startrange+18 
    button "no19" 8, 29.5 Icon: "bmp\\buttons|" + i2s(startrange+18) do
    enditem
 	
	Text 3,31.0 Variable: startrange+19 
    button "no20" 8, 31.0 Icon: "bmp\\buttons|" + i2s(startrange+19) do
    enditem
 
 	Text 3,32.5 Variable: startrange+20 
    button "no21" 8, 32.5 Icon: "bmp\\buttons|" + i2s(startrange+20) do
    enditem
 	
	Text 3,34.0 Variable: startrange+21 
    button "no22" 8, 34.0 Icon: "bmp\\buttons|" + i2s(startrange+21) do
    enditem
 
 	Text 3,35.5 Variable: startrange+22 
    button "no23" 8, 35.5 Icon: "bmp\\buttons|" + i2s(startrange+22) do
    enditem
 	
	Text 3,37.0 Variable: startrange+23 
    button "no24" 8, 37.0 Icon: "bmp\\buttons|" + i2s(startrange+23) do
    enditem
 
 	Text 3,38.5 Variable: startrange+24 
    button "no25" 8, 38.5 Icon: "bmp\\buttons|" + i2s(startrange+24) do
    enditem
 	
	button "dun" 1, 40 do
		return()
	enditem
 	
//	Text "MRM Directory:" 7,1 
//	Text 20, 1 Variable: MRMDir Framed

enddbox