Macro "DidItRun" (chkfile)
// returns date of file and elapsed time since file was written

	info = GetFileInfo(chkfile)
	if info = null then return({,})
	chkdate = ParseString(info[7], " ,")
	chktime = ParseString(info[8],":")
	chkYear = s2i(chkdate[3])
	MoReturn = RunMacro("Mo", Substring(chkdate[1], 1, 3))
	chkMonth = MoReturn[1]
	addchkMin = MoReturn[2]
	chkDay = s2i(chkdate[2])
	chkHour = s2i(chktime[1])
	chkMin = s2i(chktime[2])
	chkTime = addchkMin + ((chkDay - 1) * 1440) + (chkHour * 60) + chkMin
	// Leap day
	
	if (Mod(chkYear,4.) = 0. and chkMonth > 2) then chkTime = chkTime + 1440

//GetDateAndTime return (str 24 long)
//123456789012345678901234
//Wed Oct 19 10:48:42 1994.

	curDateTime = GetDateAndTime()
	curYear = s2i(Substring(curDateTime, 21, 4))
	MoReturn = RunMacro("Mo", Substring(curDateTime, 5, 3))
	curMonth = MoReturn[1]
	addcurMin = MoReturn[2]
	curDay = s2i(Substring(curDateTime, 9, 2))
	curHour = s2i(Substring(curDateTime, 12, 2))
	curMin = s2i(SubString(curDateTime, 15, 2))

	curTime = addcurMin + ((curDay - 1) * 1440) + (curHour * 60) + curMin
	//Leap day
	if (Mod(curYear,4.) = 0. and curMonth > 2) then curTime = curTime + 1440

	elapseMin = curTime - chkTime
	elapseYear = curYear - chkYear
	if elapseYear > 0 then elapseMin = elapseMin + 525600

	fdate = info[7] + " " + info[8]
	return({fdate, elapseMin})
endmacro

Macro "Mo" (Month_txt)
// returns month int and minutes of previous months
   	if Month_txt = "Jan"
		then do 
			Month = 1 
			AddMin = 0 
		end
    	else if Month_txt = "Feb" 
		then do 
			Month = 2
			AddMin = 44640
		end
	else if Month_txt = "Mar" 
		then do 
			Month = 3
			AddMin = 84960
		end
	else if Month_txt = "Apr" 
		then do 
			Month = 4
			AddMin = 129600
		end
	else if Month_txt = "May" 
		then do 
			Month = 5
			AddMin = 172800
		end
	else if Month_txt = "Jun" 
		then do 
			Month = 6
			AddMin = 217440
		end
	else if Month_txt = "Jul" 
		then do 
			Month = 7
			AddMin = 260640
		end
	else if Month_txt = "Aug" 
		then do 
			Month = 8
			AddMin = 305280
		end
	else if Month_txt = "Sep" 
		then do 
			Month = 9
			AddMin = 349920
		end
	else if Month_txt = "Oct" 
		then do 
			Month = 10
			AddMin = 393120
		end
	else if Month_txt = "Nov" 
		then do 
			Month = 11
			AddMin = 437760
		end
	else if Month_txt = "Dec" 
		then do 
			Month = 12
			AddMin = 480960
		end
	else do
			Month = 0
			AddMin = 0
		end
	return({Month,AddMin})
EndMacro


