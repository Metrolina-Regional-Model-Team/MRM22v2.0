//*********************************************************
//	VissimTrips.cpp - convert VISSIM trip tables
//*********************************************************

#include "VissimTrips.hpp"

//---------------------------------------------------------
//	VissimTrips constructor
//---------------------------------------------------------

VissimTrips::VissimTrips (void) : Execution_Service ()
{
	Program ("VissimTrips");
	Version (0);
	Title ("File Format Conversion");

	Control_Key keys [] = { //--- code, key, level, status, type, default, range, help ----
		{ VISSIM_TRIP_FILE, "VISSIM_TRIP_FILE", LEVEL1, REQ_KEY, IN_KEY, "", FILE_RANGE, NO_HELP },
		{ NEW_TRIP_TABLE_FILE, "NEW_TRIP_TABLE_FILE", LEVEL0, REQ_KEY, OUT_KEY, "", FILE_RANGE, NO_HELP },
		{ NEW_TRIP_TABLE_FORMAT, "NEW_TRIP_TABLE_FORMAT", LEVEL0, OPT_KEY, TEXT_KEY, "TAB_DELIMITED", MATRIX_RANGE, FORMAT_HELP },
		END_CONTROL
	};
	Key_List (keys);

	int ignore_keys [] = {
		RANDOM_NUMBER_SEED, MODEL_START_TIME, MODEL_END_TIME, MODEL_TIME_INCREMENT,  
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
	VissimTrips *program = 0;
	try {
		program = new VissimTrips ();
		stat = program->Start_Execution (commands, control);
	}
	catch (exit_exception &e) {
		stat = e.Exit_Code ();
	}
	if (program != 0) delete program;
	return (stat);
}
#endif
