dbox "ChooseAB" (ChooseMsg, Aopt, Bopt) , , 40, 7 Title: "Choose A or B"
	init do
		A_text = SampleText("A", "Calibri|bold|16", {{"Size", x,y}, {"Color", ColorRGB(0, 32768, 0)}})
		B_text = SampleText("B", "Calibri|bold|16", {{"Size", x,y}, {"Color", ColorRGB(10000, 10000, 65535)}})
		PlaySound(sysdir + "\\media\\Windows Notify.wav", "null")
	enditem

	text 1,1 Variable:ChooseMsg Framed
	sample button "bA" 1,3,3,1.2 contents: A_text do
		return("A")
	enditem
	text 5, same variable: Aopt

	text " " same, after
	sample button "bB" 1,after,3,1.2 contents: B_text do
		return("B")
	enditem
	text 5, same variable: Bopt
enddbox	