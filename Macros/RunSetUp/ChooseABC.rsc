dbox "ChooseABC" (ChooseMsg, Aopt, Bopt, Copt) , , 40, 9 Title: "Choose A B or C"
	init do
		A_text = SampleText("A", "Calibri|bold|16", {{"Size", x,y}, {"Color", ColorRGB(0, 32768, 0)}})
		B_text = SampleText("B", "Calibri|bold|16", {{"Size", x,y}, {"Color", ColorRGB(10000, 10000, 65535)}})
		C_text = SampleText("C", "Calibri|bold|16", {{"Size", x,y}, {"Color", ColorRGB(65525, 0, 0)}})
		PlaySound(sysdir + "\\media\\Windows Notify.wav", "null")
	enditem

	text 1,1 Variable:ChooseMsg Framed
	sample button "bA" 1,3,3.0,1.2 contents: A_text do
		return("A")
	enditem
	text 5, same variable: Aopt

	text " " same, after
	sample button "bB" 1,after,3.0,1.2 contents: B_text do
		return("B")
	enditem
	text 5, same variable: Bopt

	text " " same, after
	sample button "bC" 1,after, 3.0,1.2 contents: C_text do
		return("C")
	enditem
	text 5, same variable: Copt
enddbox	