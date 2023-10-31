Macro "GetFieldCore" (filename, fieldname)
// returns array {0/1 if ok, message for error)


	if fieldname = null then return({1, })
//	showmessage("GefFieldCore: " + filename + ", field:" + fieldname)
	pathparts = SplitPath(filename)
	
	//open file based on suffix (pathparts[4])
	// .dcb - coverave - use primary .bin file - NOTE - ONLY USER stats avaialable
	if upper(pathparts[4]) = ".DCB"
		then do
			filename = pathparts[1] + pathparts[2] + pathparts[3] + ".bin"
			table_type = "FFB"
			goto checktable
		end
	else if upper(pathparts[4]) = ".DBF"
		then do
			table_type = "DBASE"
			goto checktable
		end
	else if upper(pathparts[4]) = ".ASC"		
		then do
			table_type = "FFA"
			goto checktable
		end
	else if upper(pathparts[4]) = ".BIN"		
		then do
			table_type = "FFB"
			goto checktable
		end
	else if upper(pathparts[4]) = ".MTX"		
		then goto checkmtx
	else do
		return({0,"GetFieldCore, file type not handled: " + filename})
	end
	checktable:
		InFile = OpenTable("InFile", table_type, {filename})
		v = GetDataVector("InFile|", fieldname,)
		vstat = VectorStatistic(v, "Count",)
		CloseView("Infile")
		InFile = null
		v = null
		return({vstat, })
		
	checkmtx:
		mat = OpenMatrix(filename,)
		ndx = GetMatrixIndex(mat)
		matcore = CreateMatrixCurrency(mat, fieldname, ndx[1], ndx[2],)
		mattot = GetMatrixMarginals(matcore, "count", "row")
		mstat = r2i(Sum(mattot))
		mat = null
		matcore = null
		ndx = null
//		showarray(mattot)
		mattot = null
		return({mstat, })
			
endmacro