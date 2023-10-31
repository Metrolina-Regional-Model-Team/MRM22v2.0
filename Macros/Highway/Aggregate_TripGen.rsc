macro "Aggregate_TripGen" (Args)

	LogFile = Args.[Log File].value
	ReportFile = Args.[Report File].value
	SetLogFileName(LogFile)
	SetReportFileName(ReportFile)

	datentime = GetDateandTime()
	AppendToLogFile(1, "Enter Aggregate_TripGen: " + datentime)


	METDir = Args.[MET Directory].value
	TAZFile = Args.[TAZ File].value
	Dir = Args.[Run Directory].value
//	netview = Args.[Hwy Name].value
	msg = null


    DateTime = GetDateAndTime()
    Year = Substring(DateTime, 21, 4)
    Month_txt = Substring(DateTime, 5, 3)
    	if Month_txt = "Jan" then Month = "01"
    	else if Month_txt = "Feb" then Month = "02"
    	else if Month_txt = "Mar" then Month = "03"
    	else if Month_txt = "Apr" then Month = "04"
    	else if Month_txt = "May" then Month = "05"
    	else if Month_txt = "Jun" then Month = "06"
    	else if Month_txt = "Jul" then Month = "07"
    	else if Month_txt = "Aug" then Month = "08"
    	else if Month_txt = "Sep" then Month = "09"
    	else if Month_txt = "Oct" then Month = "10"
    	else if Month_txt = "Nov" then Month = "11"
    	else if Month_txt = "Dec" then Month = "12"
    	else Month = "00"
    Day = Substring(DateTime, 9, 2)

    Stamp = Year + "_" + Month + "_" + Day + "_"

    prod = OpenTable("Productions", "FFA", {Dir + "\\tg\\productions.asc",})
    taz_name    = SplitPath(TAZFile)
    taz = OpenTable("TAZ", "FFB", {METDir +"\\TAZ\\"+taz_name[3]+".bin",})
    prodTAZ = JoinViews("Prod+TAZ", taz+".TAZ", prod+".TAZ", )
    CNTY = OpenTable("County", "dBASE", {METDir + "\\STCNTY_ID.dbf",})
    CNTYprodTAZ = JoinViews("CNTY+Prod+TAZ", CNTY+".STCNTY", prodTAZ+".stcnty", {{"A",}, {"Fields", 
	{"[HBW INC 1]", {{"Sum"}}}, {"[HBW INC 2]", {{"Sum"}}}, {"[HBW INC 3]", {{"Sum"}}},
	{"[HBW INC 4]", {{"Sum"}}}, {"SCH", {{"Sum"}}}, {"HBU", {{"Sum"}}}, {"[HBS INC 1]", {{"Sum"}}},
	{"[HBS INC 2]", {{"Sum"}}}, {"[HBS INC 3]", {{"Sum"}}}, {"[HBS INC 4]", {{"Sum"}}},
	{"[HBO INC 1]", {{"Sum"}}}, {"[HBO INC 2]", {{"Sum"}}}, {"[HBO INC 3]", {{"Sum"}}},
	{"[HBO INC 4]", {{"Sum"}}}, {"[NHB JTW]", {{"Sum"}}}, {"[NHB ATW]", {{"Sum"}}},
	{"[NHB NWK]", {{"Sum"}}}, {"COM", {{"Sum"}}}, {"MTK", {{"Sum"}}}, {"HTK", {{"Sum"}}},
	{"[I/E WORK AUTO]", {{"Sum"}}}, {"[I/E NON-WORK AUTO]", {{"Sum"}}}, {"[I/E COM]", {{"Sum"}}},
	{"[I/E MED TRK]", {{"Sum"}}}, {"[I/E HVY TRK]", {{"Sum"}}},
	{"[E/I WORK AUTO]", {{"Sum"}}}, {"[E/I NON-WORK AUTO]", {{"Sum"}}}, {"[E/I COM]", {{"Sum"}}},
	{"[E/I MED TRK]", {{"Sum"}}}, {"[E/I HVY TRK]", {{"Sum"}}}}})

    rh = GetFirstRecord(CNTYprodTAZ+"|", )

    ExportView(CNTYprodTAZ+"|", "dBASE", Dir+"\\report\\"+Stamp+"CNTY_PRO.dbf",
	{"STCNTY", "NAME", "[N PROD+TAZ]", "[HBW INC 1]", "[HBW INC 2]", "[HBW INC 3]", "[HBW INC 4]",
	"SCH", "HBU", "[HBs INC 1]", "[HBS INC 2]", "[HBS INC 3]", "[HBS INC 4]", "[HBO INC 1]", 
	"[HBO INC 2]", "[HBO INC 3]", "[HBO INC 4]", "[NHB JTW]", "[NHB ATW]", "[NHB NWK]", "COM",
	"MTK", "HTK", "[I/E WORK AUTO]", "[I/E NON-WORK AUTO]", "[I/E COM]", "[I/E MED TRK]", "[I/E HVY TRK]",
	"[E/I WORK AUTO]", "[E/I NON-WORK AUTO]", "[E/I COM]", "[E/I MED TRK]", "[E/I HVY TRK]"},)

    attr = OpenTable("Attractions", "FFA", {Dir + "\\tg\\attractions.asc",})
    attrTAZ = JoinViews("Attr+TAZ", taz+".TAZ", attr+".TAZ", )
    CNTYattrTAZ = JoinViews("CNTY+Attr+TAZ", CNTY+".STCNTY", attrTAZ+".stcnty", {{"A",}, {"Fields", 
	{"ID", }, {"Area",}, {taz+".TAZ",}, {"STATE",}, {"COUNTY",}, {"cenTAZ",}, {"TRACT",},
	{"cltsphere",}, {"SubCoDist",}, {"Corr",}, {"Station",}, {"attractions.TAZ",}, {"[SEQ ZONE]",},
	{"[HBW INC 1]", {{"Sum"}}}, {"[HBW INC 2]", {{"Sum"}}}, {"[HBW INC 3]", {{"Sum"}}},
	{"[HBW INC 4]", {{"Sum"}}}, {"SCH", {{"Sum"}}}, {"HBU", {{"Sum"}}}, {"[HBS INC 1]", {{"Sum"}}},
	{"[HBS INC 2]", {{"Sum"}}}, {"[HBS INC 3]", {{"Sum"}}}, {"[HBS INC 4]", {{"Sum"}}},
	{"[HBO INC 1]", {{"Sum"}}}, {"[HBO INC 2]", {{"Sum"}}}, {"[HBO INC 3]", {{"Sum"}}},
	{"[HBO INC 4]", {{"Sum"}}}, {"[NHB JTW]", {{"Sum"}}}, {"[NHB ATW]", {{"Sum"}}},
	{"[NHB NWK]", {{"Sum"}}}, {"COM", {{"Sum"}}}, {"MTK", {{"Sum"}}}, {"HTK", {{"Sum"}}},
	{"[I/E WORK AUTO]", {{"Sum"}}}, {"[I/E NON-WORK AUTO]", {{"Sum"}}}, {"[I/E COM]", {{"Sum"}}},
	{"[I/E MED TRK]", {{"Sum"}}}, {"[I/E HVY TRK]", {{"Sum"}}},
	{"[E/I WORK AUTO]", {{"Sum"}}}, {"[E/I NON-WORK AUTO]", {{"Sum"}}}, {"[E/I COM]", {{"Sum"}}},
	{"[E/I MED TRK]", {{"Sum"}}}, {"[E/I HVY TRK]", {{"Sum"}}}}})

    ExportView(CNTYattrTAZ+"|", "dBASE", Dir+"\\Report\\"+Stamp+"CNTY_ATTR.dbf",
	{"STCNTY", "NAME", "[N ATTR+TAZ]", "[HBW INC 1]", "[HBW INC 2]", "[HBW INC 3]", "[HBW INC 4]",
	"SCH", "HBU", "[HBs INC 1]", "[HBS INC 2]", "[HBS INC 3]", "[HBS INC 4]", "[HBO INC 1]", 
	"[HBO INC 2]", "[HBO INC 3]", "[HBO INC 4]", "[NHB JTW]", "[NHB ATW]", "[NHB NWK]", "COM",
	"MTK", "HTK", "[I/E WORK AUTO]", "[I/E NON-WORK AUTO]", "[I/E COM]", "[I/E MED TRK]", "[I/E HVY TRK]",
	"[E/I WORK AUTO]", "[E/I NON-WORK AUTO]", "[E/I COM]", "[E/I MED TRK]", "[E/I HVY TRK]"},)

    CloseView(taz)
    CloseView(prodTAZ)
    CloseView(CNTY)
    CloseView(CNTYprodTAZ)
    CloseView(attrTAZ)
    CloseView(CNTYattrTAZ)

	datentime = GetDateandTime()
	AppendToLogFile(1, "Exit Aggregate_TripGen: " + datentime)
	AppendToLogFile(1, " ")

    Return({1, null})


endmacro

