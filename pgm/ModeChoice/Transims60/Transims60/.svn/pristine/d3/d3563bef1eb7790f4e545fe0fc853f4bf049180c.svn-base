//*********************************************************
//	VissimPlans.cpp - convert VISSIM path files
//*********************************************************

#include "VissimPlans.hpp"

//---------------------------------------------------------
//	VissimPlans constructor
//---------------------------------------------------------

VissimPlans::VissimPlans (void) : Data_Service ()
{
	Program ("VissimPlans");
	Version (4);
	Title ("VISSIM Path Conversion");

	System_File_Type required_files [] = {
		NODE, LINK, ZONE, CONNECTION, LOCATION, PARKING, NEW_PLAN, END_FILE
	};

	Control_Key keys [] = { //--- code, key, level, status, type, default, range, help ----
		{ VISSIM_PATH_FILE, "VISSIM_PATH_FILE", LEVEL0, REQ_KEY, IN_KEY, "", FILE_RANGE, NO_HELP },
		{ NEW_TRANSIMS_PATH_FILE, "NEW_TRANSIMS_PATH_FILE", LEVEL0, OPT_KEY, OUT_KEY, "", FILE_RANGE, NO_HELP },
		{ NEW_TRANSIMS_PATH_FORMAT, "NEW_TRANSIMS_PATH_FORMAT", LEVEL0, OPT_KEY, TEXT_KEY, "TAB_DELIMITED", FORMAT_RANGE, NO_HELP },
		END_CONTROL
	};
	Required_System_Files (required_files);
	Key_List (keys);

	path_flag = false;

	int ignore_keys [] = {
		MAX_WARNING_MESSAGES, MAX_WARNING_EXIT_FLAG, MAX_PROBLEM_COUNT, NUMBER_OF_THREADS, 0
	};
	Ignore_Keys (ignore_keys);
}

#ifdef _CONSOLE
//---------------------------------------------------------
//	main program
//---------------------------------------------------------

int main (int commands, char *control [])
{
	int stat = 0;
	VissimPlans *program = 0;
	try {
		program = new VissimPlans ();
		stat = program->Start_Execution (commands, control);
	}
	catch (exit_exception &e) {
		stat = e.Exit_Code ();
	}
	if (program != 0) delete program;
	return (stat);
}
#endif
