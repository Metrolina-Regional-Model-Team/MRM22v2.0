Macro "Transit_Input" (Args)


	// removed choice set and CR path trips configuration for mode choice output and assignment files
	// Does not assume index names for mode choice output and assignment matrices 
	// Juvva, August, 2015
	// Updated for new UI - McLelland, Jan, 2016
	
	LogFile = Args.[Log File].value
	SetLogFileName(LogFile)

	Dir = Args.[Run Directory].value
	
	TranInputOK = 1
	msg = null

	datentime = GetDateandTime()
	AppendToLogFile(1, "Enter Transit Input: " + datentime)
	
		
	on error do
		msg = msg + {"Transit_Input: Transit Assign Walk Matrix was not found in this Directory"}
		AppendToLogFile(2, "Transit_Input: Transit Assign Walk Matrix was not found in this Directory")
		TranInputOK = 0
	end
	check = openmatrix(Dir + "\\TranAssn\\Transit Assign Walk.mtx", "True")

	on error do
		msg = msg + {"Transit_Input: Transit Assign Drive Matrix was not found in this Directory"}
		AppendToLogFile(2, "Transit_Input: Transit Assign Drive Matrix was not found in this Directory")
		TranInputOK = 0
	end
	check = openmatrix(Dir + "\\TranAssn\\Transit Assign Drive.mtx", "True")

	on error do
		msg = msg + {"Transit_Input: Transit Assign Dropoff Matrix was not found in this Directory"}
		AppendToLogFile(2, "Transit_Input: Transit Assign Dropoff Matrix was not found in this Directory")
		TranInputOK = 0
	end
	check = openmatrix(Dir + "\\TranAssn\\Transit Assign Dropoff.mtx", "True")

	on error default
	
	if TranInputOK = 0 then goto quit

	if (ms_dir = null) then ms_dir = Dir + "\\ModeSplit"

// PprmW -  PEAK PREMIUM WALK TRIPS 
	
	M1  = OpenMatrix(ms_dir + "\\HBW_PEAK_MS.mtx", "True")
	M2  = OpenMatrix(ms_dir + "\\HBO_PEAK_MS.mtx", "True")
	M3  = OpenMatrix(ms_dir + "\\HBU_PEAK_MS.mtx", "True")
	M4  = OpenMatrix(ms_dir + "\\NHB_PEAK_MS.mtx", "True")

	RenameMatrix(M1, "HBW_PEAK_MS")
	RenameMatrix(M2, "HBO_PEAK_MS")
	RenameMatrix(M3, "HBU_PEAK_MS")
	RenameMatrix(M4, "NHB_PEAK_MS")
	
		M5 = OpenMatrix(Dir + "\\TRANASSN\\Transit Assign Walk.mtx", "True")
	
	idx  = Getmatrixindex(M1)
	idxnew = {"Rows", "Columns"}
	idx2  = Getmatrixindex(M5)
	
	for i = 1 to idx.length do
        if idx[i] <> idxnew[i] then do
			SetMatrixIndexName(M1, idx[i], idxnew[i])
			SetMatrixIndexName(M2, idx[i], idxnew[i])
			SetMatrixIndexName(M3, idx[i], idxnew[i])
			SetMatrixIndexName(M4, idx[i], idxnew[i])
		end
	end	

	idx  = Getmatrixindex(M1)
	c1  = CreateMatrixCurrency(M1 , "Wk-Premium", idx[1], idx[2],)
	c2  = CreateMatrixCurrency(M2 , "Wk-Premium", idx[1], idx[2],)
	c3  = CreateMatrixCurrency(M3 , "Wk-Premium", idx[1], idx[2],)
	c4  = CreateMatrixCurrency(M4 , "Wk-Premium", idx[1], idx[2],)
	
		c5 = CreateMatrixCurrency(M5, "PprmW",  idx2[1], idx2[2],)
		MatrixOperations(c5, {c1, c2, c3, c4}, {1, 1, 1, 1}, ,, {{"Operation", "Add"}, {"Force Missing", "No"}})

    c1 = null
    c2 = null
    c3 = null
    c4 = null
    c5 = null
	
// PbusW -  PEAK Bus WALK TRIPS 
	
	c1  = CreateMatrixCurrency(M1 , "Wk-Bus", idx[1], idx[2],)
	c2  = CreateMatrixCurrency(M2 , "Wk-Bus", idx[1], idx[2],)
	c3  = CreateMatrixCurrency(M3 , "Wk-Bus", idx[1], idx[2],)
	c4  = CreateMatrixCurrency(M4 , "Wk-Bus", idx[1], idx[2],)

		c5 = CreateMatrixCurrency(M5, "PBusW",  idx2[1], idx2[2],)
		MatrixOperations(c5, {c1, c2, c3, c4}, {1, 1, 1, 1}, ,, {{"Operation", "Add"}, {"Force Missing", "No"}})

    c1 = null
    c2 = null
    c3 = null
    c4 = null
    c5 = null

// PprmD -  PEAK Premium Drive TRIPS 
	
    M5 = OpenMatrix(Dir + "\\TRANASSN\\Transit Assign Drive.mtx", "True")
	idx2 = GetMatrixIndex(M5)

	c1  = CreateMatrixCurrency(M1 , "Dr-Premium", idx[1], idx[2],)
	c2  = CreateMatrixCurrency(M2 , "Dr-Premium", idx[1], idx[2],)
	c3  = CreateMatrixCurrency(M3 , "Dr-Premium", idx[1], idx[2],)
	c4  = CreateMatrixCurrency(M4 , "Dr-Premium", idx[1], idx[2],)

		c5 = CreateMatrixCurrency(M5, "PprmD", idx2[1], idx2[2],)
		MatrixOperations(c5, {c1, c2, c3, c4}, {1, 1, 1, 1}, ,, {{"Operation", "Add"}, {"Force Missing", "No"}})
	
    c1 = null
    c2 = null
    c3 = null
    c4 = null
    c5 = nulL

// PBusD -  PEAK Bus Drive TRIPS 
	
	c1  = CreateMatrixCurrency(M1 , "Dr-Bus", idx[1], idx[2],)
	c2  = CreateMatrixCurrency(M2 , "Dr-Bus", idx[1], idx[2],)
	c3  = CreateMatrixCurrency(M3 , "Dr-Bus", idx[1], idx[2],)
	c4  = CreateMatrixCurrency(M4 , "Dr-Bus", idx[1], idx[2],)

		c5 = CreateMatrixCurrency(M5, "PBusD", idx2[1], idx2[2],)
		MatrixOperations(c5, {c1, c2, c3, c4}, {1, 1, 1, 1}, ,, {{"Operation", "Add"}, {"Force Missing", "No"}})
	
    c1 = null
    c2 = null
    c3 = null
    c4 = null
    c5 = null

// PprmDropOff -  PEAK Premium DropOff TRIPS 

    M5 = OpenMatrix(Dir + "\\TRANASSN\\Transit Assign DropOff.mtx", "True")
	idx2 = GetMatrixIndex(M5)
	
	c1  = CreateMatrixCurrency(M1 , "Dropoff-Premium", idx[1], idx[2],)
	c2  = CreateMatrixCurrency(M2 , "Dropoff-Premium", idx[1], idx[2],)
	c3  = CreateMatrixCurrency(M3 , "Dropoff-Premium", idx[1], idx[2],)
	c4  = CreateMatrixCurrency(M4 , "Dropoff-Premium", idx[1], idx[2],)

		c5 = CreateMatrixCurrency(M5, "PprmDropoff", idx2[1], idx2[2],)
		MatrixOperations(c5, {c1, c2, c3, c4}, {1, 1, 1, 1}, ,, {{"Operation", "Add"}, {"Force Missing", "No"}})
	
    c1 = null
    c2 = null
    c3 = null
    c4 = null
    c5 = null

// PbusDropOff -  PEAK Bus DropOff TRIPS 
	
	c1  = CreateMatrixCurrency(M1 , "Dropoff-Bus", idx[1], idx[2],)
	c2  = CreateMatrixCurrency(M2 , "Dropoff-Bus", idx[1], idx[2],)
	c3  = CreateMatrixCurrency(M3 , "Dropoff-Bus", idx[1], idx[2],)
	c4  = CreateMatrixCurrency(M4 , "Dropoff-Bus", idx[1], idx[2],)

		c5 = CreateMatrixCurrency(M5, "PBusDropoff", idx2[1], idx2[2],)
		MatrixOperations(c5, {c1, c2, c3, c4}, {1, 1, 1, 1}, ,, {{"Operation", "Add"}, {"Force Missing", "No"}})
	
    c1 = null
    c2 = null
    c3 = null
    c4 = null
    c5 = null


// OPprmW -  OFFPEAK PREMIUM WALK TRIPS 
	
	M1  = OpenMatrix(ms_dir + "\\HBW_OFFPEAK_MS.mtx", "True")
	M2  = OpenMatrix(ms_dir + "\\HBO_OFFPEAK_MS.mtx", "True")
	M3  = OpenMatrix(ms_dir + "\\HBU_OFFPEAK_MS.mtx", "True")
	M4  = OpenMatrix(ms_dir + "\\NHB_OFFPEAK_MS.mtx", "True")

	RenameMatrix(M1, "HBW_OFFPEAK_MS")
	RenameMatrix(M2, "HBO_OFFPEAK_MS")
	RenameMatrix(M3, "HBU_OFFPEAK_MS")
	RenameMatrix(M4, "NHB_OFFPEAK_MS")

		M5 = OpenMatrix(Dir + "\\TRANASSN\\Transit Assign Walk.mtx", "True")
	
	idx  = Getmatrixindex(M1)
	idxnew = {"Rows", "Columns"}
	idx2  = Getmatrixindex(M5)
	
	for i = 1 to idx.length do
        if idx[i] <> idxnew[i] then do
			SetMatrixIndexName(M1, idx[i], idxnew[i])
			SetMatrixIndexName(M2, idx[i], idxnew[i])
			SetMatrixIndexName(M3, idx[i], idxnew[i])
			SetMatrixIndexName(M4, idx[i], idxnew[i])
		end
	end	

	idx  = Getmatrixindex(M1)
	c1  = CreateMatrixCurrency(M1 , "Wk-Premium", idx[1], idx[2],)
	c2  = CreateMatrixCurrency(M2 , "Wk-Premium", idx[1], idx[2],)
	c3  = CreateMatrixCurrency(M3 , "Wk-Premium", idx[1], idx[2],)
	c4  = CreateMatrixCurrency(M4 , "Wk-Premium", idx[1], idx[2],)

	
		c5 = CreateMatrixCurrency(M5, "OPprmW",  idx2[1], idx2[2],)
		MatrixOperations(c5, {c1, c2, c3, c4}, {1, 1, 1, 1}, ,, {{"Operation", "Add"}, {"Force Missing", "No"}})

    c1 = null
    c2 = null
    c3 = null
    c4 = null
    c5 = null

	
// OPbusW -  OFFPEAK bus WALK TRIPS 

	c1  = CreateMatrixCurrency(M1 , "Wk-Bus", idx[1], idx[2],)
	c2  = CreateMatrixCurrency(M2 , "Wk-Bus", idx[1], idx[2],)
	c3  = CreateMatrixCurrency(M3 , "Wk-Bus", idx[1], idx[2],)
	c4  = CreateMatrixCurrency(M4 , "Wk-Bus", idx[1], idx[2],)
	
		c5 = CreateMatrixCurrency(M5, "OPbusW",  idx2[1], idx2[2],)
		MatrixOperations(c5, {c1, c2, c3, c4}, {1, 1, 1, 1}, ,, {{"Operation", "Add"}, {"Force Missing", "No"}})

    c1 = null
    c2 = null
    c3 = null
    c4 = null
    c5 = null

// OPprmD -  OFFPEAK PREMIUM DRIVE TRIPS

	M5 = OpenMatrix(Dir + "\\TRANASSN\\Transit Assign Drive.mtx", "True")
	idx2 = GetMatrixIndex(M5)
 
	c1  = CreateMatrixCurrency(M1 , "Dr-Premium", idx[1], idx[2],)
	c2  = CreateMatrixCurrency(M2 , "Dr-Premium", idx[1], idx[2],)
	c3  = CreateMatrixCurrency(M3 , "Dr-Premium", idx[1], idx[2],)
	c4  = CreateMatrixCurrency(M4 , "Dr-Premium", idx[1], idx[2],)
	
		c5 = CreateMatrixCurrency(M5, "OPprmD",  idx2[1], idx2[2],)
		MatrixOperations(c5, {c1, c2, c3, c4}, {1, 1, 1, 1}, ,, {{"Operation", "Add"}, {"Force Missing", "No"}})

    c1 = null
    c2 = null
    c3 = null
    c4 = null
    c5 = null
	
// OPbusD -  OFFPEAK Bus Drive TRIPS 
	
	c1  = CreateMatrixCurrency(M1 , "Dr-Bus", idx[1], idx[2],)
	c2  = CreateMatrixCurrency(M2 , "Dr-Bus", idx[1], idx[2],)
	c3  = CreateMatrixCurrency(M3 , "Dr-Bus", idx[1], idx[2],)
	c4  = CreateMatrixCurrency(M4 , "Dr-Bus", idx[1], idx[2],)
	
		c5 = CreateMatrixCurrency(M5, "OPbusD",  idx2[1], idx2[2],)
		MatrixOperations(c5, {c1, c2, c3, c4}, {1, 1, 1, 1}, ,, {{"Operation", "Add"}, {"Force Missing", "No"}})

    c1 = null
    c2 = null
    c3 = null
    c4 = null
    c5 = null

// OPprmDropOff -  OFFPEAK Premium DropOff TRIPS 
	
	M5 = OpenMatrix(Dir + "\\TRANASSN\\Transit Assign Dropoff.mtx", "True")
	idx2 = GetMatrixIndex(M5)

	c1  = CreateMatrixCurrency(M1 , "Dropoff-Premium", idx[1], idx[2],)
	c2  = CreateMatrixCurrency(M2 , "Dropoff-Premium", idx[1], idx[2],)
	c3  = CreateMatrixCurrency(M3 , "Dropoff-Premium", idx[1], idx[2],)
	c4  = CreateMatrixCurrency(M4 , "Dropoff-Premium", idx[1], idx[2],)
	
		c5 = CreateMatrixCurrency(M5, "OPprmDropoff",  idx2[1], idx2[2],)
		MatrixOperations(c5, {c1, c2, c3, c4}, {1, 1, 1, 1}, ,, {{"Operation", "Add"}, {"Force Missing", "No"}})

    c1 = null
    c2 = null
    c3 = null
    c4 = null
    c5 = null

// OPbusDropOff -  OFFPEAK Bus DropOff TRIPS 
	
	c1  = CreateMatrixCurrency(M1 , "Dropoff-Bus", idx[1], idx[2],)
	c2  = CreateMatrixCurrency(M2 , "Dropoff-Bus", idx[1], idx[2],)
	c3  = CreateMatrixCurrency(M3 , "Dropoff-Bus", idx[1], idx[2],)
	c4  = CreateMatrixCurrency(M4 , "Dropoff-Bus", idx[1], idx[2],)
	
		c5 = CreateMatrixCurrency(M5, "OPbusDropoff",  idx2[1], idx2[2],)
		MatrixOperations(c5, {c1, c2, c3, c4}, {1, 1, 1, 1}, ,, {{"Operation", "Add"}, {"Force Missing", "No"}})

    c1 = null
    c2 = null
    c3 = null
    c4 = null
    c5 = null

// -- export the transit drive assign matrix in ascii format
	
//   OM = OpenMatrix(Dir + "\\TRANASSN\\Transit Assign Drive.mtx", "True")
//   CreateTableFromMatrix(OM, Dir + "\\TRANASSN\\transit assign drive.asc", "FFA", {{"Complete", "Yes"}})

// -- export the transit drop-off assign matrix in ascii format
	
//   OM = OpenMatrix(Dir + "\\TRANASSN\\Transit Assign DropOff.mtx", "True")
//   CreateTableFromMatrix(OM, Dir + "\\TRANASSN\\transit assign dropoff.asc", "FFA", {{"Complete", "Yes"}})

	quit:

	datentime = GetDateandTime()
	AppendToLogFile(1, "Exit Transit_Input: " + datentime)
	return({TranInputOK, msg})

endmacro