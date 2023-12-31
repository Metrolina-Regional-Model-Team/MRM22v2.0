//*********************************************************
//	Reschedule.cpp - reschedule transit routes
//*********************************************************

#include "Reschedule.hpp"

//---------------------------------------------------------
//	Reschedule constructor
//---------------------------------------------------------

Reschedule::Reschedule (void) : Data_Service (), Select_Service ()
{
	Program ("Reschedule");
	Version (6);
	Title ("Reschedule Transit Routes");

	System_File_Type required_files [] = {
		NODE, LINK, TRANSIT_STOP, TRANSIT_ROUTE, TRANSIT_SCHEDULE, VEHICLE_TYPE, NEW_TRANSIT_SCHEDULE, END_FILE
	};
	System_File_Type optional_files [] = {
		LANE_USE, TRANSIT_DRIVER, PERFORMANCE, END_FILE
	};
	int select_service_keys [] = {
		SELECT_TRANSIT_MODES, SELECT_ROUTES, 0
	};
	int file_service_keys [] = {
		NOTES_AND_NAME_FIELDS, 	SAVE_LANE_USE_FLOWS, 0
	};
	Control_Key keys [] = { //--- code, key, level, status, type, default, range, help ----
		{ RUN_SCHEDULE_FILE, "RUN_SCHEDULE_FILE", LEVEL1, OPT_KEY, IN_KEY, "", FILE_RANGE, NO_HELP },
		{ RUN_SCHEDULE_FORMAT, "RUN_SCHEDULE_FORMAT", LEVEL1, OPT_KEY, TEXT_KEY, "TAB_DELIMITED", FORMAT_RANGE, FORMAT_HELP },
		{ RUN_FILTER_FIELD, "RUN_FILTER_FIELD", LEVEL1, OPT_KEY, TEXT_KEY, "", "", NO_HELP },
		{ RUN_TYPE_FIELD, "RUN_TYPE_FIELD", LEVEL1, OPT_KEY, TEXT_KEY, "", "", NO_HELP },
		{ RUN_SCHEDULE_LINE, "RUN_SCHEDULE_LINE", LEVEL2, OPT_KEY, INT_KEY, "0", ">0", NO_HELP },
		{ RUN_FILTER_RANGE, "RUN_FILTER_RANGE", LEVEL2, OPT_KEY, TEXT_KEY, "ALL", "0..10000000", NO_HELP },
		{ RUN_STOP_FIELD_FILE, "RUN_STOP_FIELD_FILE", LEVEL2, OPT_KEY, IN_KEY, "", FILE_RANGE, NO_HELP },
		{ PERFORMANCE_UPDATE_FILE, "PERFORMANCE_UPDATE_FILE", LEVEL0, OPT_KEY, IN_KEY, "", FILE_RANGE, NO_HELP },
		{ PERFORMANCE_UPDATE_FORMAT, "PERFORMANCE_UPDATE_FORMAT", LEVEL0, OPT_KEY, TEXT_KEY, "TAB_DELIMITED", FORMAT_RANGE, FORMAT_HELP },
		{ TRANSIT_MODE_FACTORS, "TRANSIT_MODE_FACTORS", LEVEL0, OPT_KEY, LIST_KEY, "1.0", "0.5..3.0", NO_HELP },
		{ MINIMUM_MODE_PERCENTS, "MINIMUM_MODE_PERCENTS", LEVEL0, OPT_KEY, LIST_KEY, "0.0", "-100.0..100.0", NO_HELP },
		{ MAXIMUM_MODE_PERCENTS, "MAXIMUM_MODE_PERCENTS", LEVEL0, OPT_KEY, LIST_KEY, "0.0", "0.0..1000.0", NO_HELP },
		{ NEW_TIME_CHANGE_FILE, "NEW_TIME_CHANGE_FILE", LEVEL0, OPT_KEY, OUT_KEY, "", FILE_RANGE, NO_HELP },
		{ NEW_TIME_CHANGE_FORMAT, "NEW_TIME_CHANGE_FORMAT", LEVEL0, OPT_KEY, TEXT_KEY, "TAB_DELIMITED", FORMAT_RANGE, FORMAT_HELP },
		END_CONTROL
	};
	const char *reports [] = {
		"DUMP_MATCH_PROBLEMS",
		"RUN_TIME_CHANGES",
		""
	};
	Required_System_Files (required_files);
	Optional_System_Files (optional_files);
	Select_Service_Keys (select_service_keys);
	File_Service_Keys (file_service_keys);

	Key_List (keys);
	Report_List (reports);

	run_flag = match_dump = update_flag = factor_flag = min_flag = max_flag = change_flag = file_flag = false;
	mode_field = line_field = run_field = start_field = old_field = new_field = -1;
}
#ifdef _CONSOLE
//---------------------------------------------------------
//	main program
//---------------------------------------------------------

int main (int commands, char *control [])
{
	int stat = 0;
	Reschedule *program = 0;
	try {
		program = new Reschedule ();
		stat = program->Start_Execution (commands, control);
	}
	catch (exit_exception &e) {
		stat = e.Exit_Code ();
	}
	if (program != 0) delete program;
	return (stat);
}
#endif
