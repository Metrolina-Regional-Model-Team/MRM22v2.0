//*********************************************************
//	ArcJoin.cpp - Join Shapefiles
//*********************************************************

#include "ArcJoin.hpp"

//---------------------------------------------------------
//	CountSum constructor
//---------------------------------------------------------

ArcJoin::ArcJoin (void) : Data_Service ()
{
	Program ("ArcJoin");
	Version (4);
	Title ("Join Shapefiles");

	Control_Key keys [] = { //--- code, key, level, status, type, default, range, help ----
		{ ARC_DATA_FILE, "ARC_DATA_FILE", LEVEL1, REQ_KEY, IN_KEY, "", FILE_RANGE, NO_HELP },
		{ DATA_INDEX_FIELD, "DATA_INDEX_FIELD", LEVEL1, REQ_KEY, TEXT_KEY, "", "", NO_HELP },
		{ DIRECTION_FIELD, "DIRECTION_FIELD", LEVEL1, OPT_KEY, TEXT_KEY, "", "", NO_HELP },
		{ SPLIT_DIRECTIONS, "SPLIT_DIRECTIONS", LEVEL1, OPT_KEY, BOOL_KEY, "FALSE", BOOL_RANGE, NO_HELP },
		{ DIRECTION_OFFSET, "DIRECTION_OFFSET", LEVEL1, OPT_KEY, FLOAT_KEY, "0.0", "0.0..1000.0", NO_HELP },
		{ SELECT_DATA_FIELDS, "SELECT_DATA_FIELDS", LEVEL1, OPT_KEY, LIST_KEY, "", "", NO_HELP },
		{ LIKE_MATCH_FIELD, "LIKE_MATCH_FIELD", LEVEL1, OPT_KEY, LIST_KEY, "", "FIELD, LENGTH", NO_HELP },
		{ NEW_ARC_DATA_FILE, "NEW_ARC_DATA_FILE", LEVEL1, OPT_KEY, OUT_KEY, "", FILE_RANGE, NO_HELP },
		{ COORDINATE_BUFFER, "COORDINATE_BUFFER", LEVEL0, OPT_KEY, FLOAT_KEY, "0.0", "0.0..5000.0", NO_HELP },
		{ NEW_ARC_JOIN_FILE, "NEW_ARC_JOIN_FILE", LEVEL0, OPT_KEY, OUT_KEY, "", FILE_RANGE, NO_HELP },
		{ INCLUDE_DATA_FIELDS, "INCLUDE_DATA_FIELDS", LEVEL0, OPT_KEY, BOOL_KEY, "FALSE", BOOL_RANGE, NO_HELP },
		END_CONTROL
	};
	const char *reports [] = {
		""
	};

	Key_List (keys);
	Report_List (reports);
	
	projection.Add_Keys ();
	buffer = 0.0;

	compass.Set_Points (16);

	new_arc_flag = field_flag = like_flag = false;
}

#ifdef _CONSOLE
//---------------------------------------------------------
//	main program
//---------------------------------------------------------

int main (int commands, char *control [])
{
	int stat = 0;
	ArcJoin *program = 0;
	try {
		program = new ArcJoin ();
		stat = program->Start_Execution (commands, control);
	}
	catch (exit_exception &e) {
		stat = e.Exit_Code ();
	}
	if (program != 0) delete program;
	return (stat);
}
#endif
