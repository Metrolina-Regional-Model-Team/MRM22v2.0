//*********************************************************
//	PlanPrep.cpp - travel plan processing utility
//*********************************************************

#include "PlanPrep.hpp"

//---------------------------------------------------------
//	PlanPrep constructor
//---------------------------------------------------------

PlanPrep::PlanPrep (void) : Data_Service (), Select_Service ()
{
	Program ("PlanPrep");
	Version (11);
	Title ("Travel Plan Processing Utility");

	System_File_Type optional_files [] = {
		NODE, LINK, LOCATION, PARKING, ACCESS_LINK, TRANSIT_STOP, TRANSIT_ROUTE, TRANSIT_SCHEDULE, TRANSIT_DRIVER,
		VEHICLE_TYPE, SELECTION, PLAN, PLAN_SKIM, PARK_DEMAND, RIDERSHIP, NEW_PLAN, NEW_PLAN_SKIM, NEW_SELECTION, END_FILE
	};
	int file_service_keys [] = {
		TRIP_SORT_TYPE, PLAN_SORT_TYPE, 0
	};
	int select_service_keys [] = {
		SELECT_HOUSEHOLDS, SELECT_MODES, SELECT_PURPOSES, SELECT_START_TIMES, SELECT_END_TIMES, 
		SELECT_ORIGINS, SELECT_DESTINATIONS, SELECT_VEHICLE_TYPES, SELECT_TRAVELER_TYPES, 
		SELECT_ORIGIN_ZONES, SELECT_DESTINATION_ZONES, SELECT_PARKING_LOTS,
		SELECT_LINKS, SELECT_NODES, SELECT_SUBAREAS, SELECTION_POLYGON, SELECTION_PERCENTAGE, 
		DELETION_FILE, DELETION_FORMAT, DELETE_HOUSEHOLDS, DELETE_MODES, DELETE_TRAVELER_TYPES, 0
	};
	Control_Key keys [] = { //--- code, key, level, status, type, default, range, help ----
		{ MERGE_PLAN_FILE, "MERGE_PLAN_FILE", LEVEL0, OPT_KEY, IN_KEY, "", PARTITION_RANGE, NO_HELP },
		{ MERGE_PLAN_FORMAT, "MERGE_PLAN_FORMAT", LEVEL0, OPT_KEY, TEXT_KEY, "TAB_DELIMITED", FORMAT_RANGE, FORMAT_HELP },
		{ MERGE_MODE_FLAG, "MERGE_MODE_FLAG", LEVEL0, OPT_KEY, BOOL_KEY, "FALSE", BOOL_RANGE, NO_HELP },
		{ MAXIMUM_SORT_SIZE, "MAXIMUM_SORT_SIZE", LEVEL0, OPT_KEY, INT_KEY, "0", "0, >=100000 trips", NO_HELP },
		{ REPAIR_PLAN_LEGS, "REPAIR_PLAN_LEGS", LEVEL0, OPT_KEY, BOOL_KEY, "FALSE", BOOL_RANGE, NO_HELP },
		{ CONSTRAIN_PARKRIDE_LOTS, "CONSTRAIN_PARKRIDE_LOTS", LEVEL0, OPT_KEY, LIST_KEY, "NONE", RANGE_RANGE, NO_HELP },
		{ MAX_PARKING_DEMAND_RATIO, "MAX_PARKING_DEMAND_RATIO", LEVEL0, OPT_KEY, FLOAT_KEY, "1.2", "1.0..100.0", NO_HELP },
		{ CONSTRAIN_TRANSIT_LOADS, "CONSTRAIN_TRANSIT_LOADS", LEVEL0, OPT_KEY, LIST_KEY, "NONE", RANGE_RANGE, NO_HELP },
		{ MAX_ROUTE_LOAD_FACTOR, "MAX_ROUTE_LOAD_FACTOR", LEVEL0, OPT_KEY, FLOAT_KEY, "1.2", "1.0..100.0", NO_HELP },
		{ SHIFT_START_PERCENTAGE, "SHIFT_START_PERCENTAGE", LEVEL0, OPT_KEY, FLOAT_KEY, "0.0", "0.0..100.0", NO_HELP },
		{ SHIFT_END_PERCENTAGE, "SHIFT_END_PERCENTAGE", LEVEL0, OPT_KEY, FLOAT_KEY, "0.0", "0.0..100.0", NO_HELP },
		{ SHIFT_FROM_TIME_RANGE, "SHIFT_FROM_TIME_RANGE", LEVEL0, OPT_KEY, TEXT_KEY, "", TIME_RANGE, NO_HELP },
		{ SHIFT_TO_TIME_RANGE, "SHIFT_TO_TIME_RANGE", LEVEL0, OPT_KEY, TEXT_KEY, "", TIME_RANGE, NO_HELP },
		END_CONTROL
	};
	const char *reports [] = {
		//"FIRST_REPORT",
		//"SECOND_REPORT",
		""
	};
	Optional_System_Files (optional_files);
	File_Service_Keys (file_service_keys);
	Select_Service_Keys (select_service_keys);

	Key_List (keys);
	Report_List (reports);
	Enable_Partitions (true);

#ifdef THREADS
	Enable_Threads (true);
#endif
#ifdef MPI_EXE
	Enable_MPI (true);
#endif

	sort_size = num_repair = repair_plans = num_new_skims = 0;
	select_flag = merge_flag = combine_flag = output_flag = new_plan_flag = repair_flag = skim_flag = plan_skim_flag = merge_mode_flag = false;
	shift_start_flag = shift_end_flag = false;
	shift_rate = 0.0;
	shift_factor = 1.0;

	max_ratio = max_factor = 1.2;

	System_Read_False (PLAN);
	System_Data_Reserve (PLAN, 0);

	System_Read_False (PLAN_SKIM);
	System_Data_Reserve (PLAN_SKIM, 0);
}

#ifdef _CONSOLE
//---------------------------------------------------------
//	main program
//---------------------------------------------------------

int main (int commands, char *control [])
{
	int stat = 0;
	PlanPrep *program = 0;
	try {
		program = new PlanPrep ();
		stat = program->Start_Execution (commands, control);
	}
	catch (exit_exception &e) {
		stat = e.Exit_Code ();
	}
	if (program != 0) delete program;
	return (stat);
}
#endif

