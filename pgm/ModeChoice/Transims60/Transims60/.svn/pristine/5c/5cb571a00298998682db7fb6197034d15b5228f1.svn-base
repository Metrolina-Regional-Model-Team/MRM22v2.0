//*********************************************************
//	ModeChoice.cpp - mode choice processing
//*********************************************************

#include "ModeChoice.hpp"

//---------------------------------------------------------
//	ModeChoice constructor
//---------------------------------------------------------

ModeChoice::ModeChoice (void) : Data_Service (), Select_Service ()
{
	Program ("ModeChoice");
	Version (31);
	Title ("Mode Choice Processing");

	System_File_Type required_files[] = {
		ZONE, END_FILE
	};
	System_File_Type optional_files[] = {
		NODE, LINK, LOCATION, PARKING, TRANSIT_STOP, TRANSIT_ROUTE, TRANSIT_SCHEDULE, VEHICLE_TYPE, 
		RIDERSHIP, PARK_DEMAND, NEW_PLAN, NEW_RIDERSHIP, NEW_PARK_DEMAND, NEW_PLAN_SKIM, END_FILE
	};
	int file_service_keys[] = {
		ZONE_EQUIVALENCE_FILE, 0
	};
	int data_service_keys [] = {
		PARKING_DEMAND_TYPE, PARKING_PENALTY_FUNCTION, 0
	};
	int select_service_keys [] = {
		SELECT_ORIGIN_ZONES, SELECT_DESTINATION_ZONES, 0
	};
	Control_Key keys [] = { //--- code, key, level, status, type, default, range, help ----
		{ PLAN_FILE, "PLAN_FILE", LEVEL1, OPT_KEY, IN_KEY, "", FILE_RANGE, NO_HELP},
		{ PLAN_FORMAT, "PLAN_FORMAT", LEVEL1, OPT_KEY, TEXT_KEY, "TAB_DELIMITED", FORMAT_RANGE, FORMAT_HELP},
		{ PLAN_SKIM_FILE, "PLAN_SKIM_FILE", LEVEL1, OPT_KEY, IN_KEY, "", FILE_RANGE, NO_HELP },
		{ PLAN_SKIM_FORMAT, "PLAN_SKIM_FORMAT", LEVEL1, OPT_KEY, TEXT_KEY, "TAB_DELIMITED", FORMAT_RANGE, FORMAT_HELP },
		{ TOUR_MODE_CHOICE, "TOUR_MODE_CHOICE", LEVEL0, OPT_KEY, BOOL_KEY, "FALSE", BOOL_RANGE, NO_HELP },
		{ APPLY_AUTO_OCCUPANCY, "APPLY_AUTO_OCCUPANCY", LEVEL0, OPT_KEY, BOOL_KEY, "FALSE", BOOL_RANGE, NO_HELP },

		{ TRIP_TABLE_FILE, "TRIP_TABLE_FILE", LEVEL0, OPT_KEY, IN_KEY, "", FILE_RANGE, NO_HELP },
		{ TRIP_TABLE_FORMAT, "TRIP_TABLE_FORMAT", LEVEL0, OPT_KEY, TEXT_KEY, "CUBE", MATRIX_RANGE, FORMAT_HELP },
		{ NEW_TRIP_TABLE_FILE, "NEW_TRIP_TABLE_FILE", LEVEL0, OPT_KEY, OUT_KEY, "", FILE_RANGE, NO_HELP },
		{ NEW_TRIP_TABLE_FORMAT, "NEW_TRIP_TABLE_FORMAT", LEVEL0, OPT_KEY, TEXT_KEY, "CUBE", MATRIX_RANGE, FORMAT_HELP },
		{ SELECT_TRIP_TABLES, "SELECT_TRIP_TABLES", LEVEL0, OPT_KEY, TEXT_KEY, "ALL", "", NO_HELP },
		{ SKIM_FILE, "SKIM_FILE", LEVEL1, OPT_KEY, IN_KEY, "", FILE_RANGE, NO_HELP },
		{ SKIM_FORMAT, "SKIM_FORMAT", LEVEL0, OPT_KEY, TEXT_KEY, "CUBE", MATRIX_RANGE, FORMAT_HELP },

		{ MODE_CONSTANT_FILE, "MODE_CONSTANT_FILE", LEVEL0, OPT_KEY, IN_KEY, "", FILE_RANGE, NO_HELP },
		{ MODE_CONSTANT_FORMAT, "MODE_CONSTANT_FORMAT", LEVEL0, OPT_KEY, TEXT_KEY, "TAB_DELIMITED", FORMAT_RANGE, FORMAT_HELP },
		{ MODE_BIAS_FILE, "MODE_BIAS_FILE", LEVEL0, OPT_KEY, IN_KEY, "", FILE_RANGE, NO_HELP },
		{ MODE_BIAS_FORMAT, "MODE_BIAS_FORMAT", LEVEL0, OPT_KEY, TEXT_KEY, "TAB_DELIMITED", FORMAT_RANGE, FORMAT_HELP },
		{ SEGMENT_MAP_FILE, "SEGMENT_MAP_FILE", LEVEL0, OPT_KEY, IN_KEY, "", FILE_RANGE, NO_HELP },
		{ SEGMENT_MAP_FORMAT, "SEGMENT_MAP_FORMAT", LEVEL0, OPT_KEY, TEXT_KEY, "TAB_DELIMITED", FORMAT_RANGE, FORMAT_HELP },
		{ ORIGIN_MAP_FIELD, "ORIGIN_MAP_FIELD", LEVEL0, OPT_KEY, TEXT_KEY, "SEGMENT", "", NO_HELP },
		{ DESTINATION_MAP_FIELD, "DESTINATION_MAP_FIELD", LEVEL0, OPT_KEY, TEXT_KEY, "SEGMENT", "", NO_HELP },

		{ MODE_CHOICE_SCRIPT, "MODE_CHOICE_SCRIPT", LEVEL0, REQ_KEY, IN_KEY, "", FILE_RANGE, NO_HELP },
		{ PRIMARY_MODE_CHOICE, "PRIMARY_MODE_CHOICE", LEVEL0, REQ_KEY, TEXT_KEY, "", "", NO_HELP },
		{ MODE_CHOICE_NEST, "MODE_CHOICE_NEST", LEVEL1, OPT_KEY, TEXT_KEY, "", "", NO_HELP },
		{ NESTING_COEFFICIENT, "NESTING_COEFFICIENT", LEVEL1, OPT_KEY, FLOAT_KEY, "0.5", "0.0..1.0", NO_HELP },

		{ MODEL_NAMES, "MODEL_NAMES", LEVEL1, OPT_KEY, LIST_KEY, "", "", NO_HELP},
		{ IMPEDANCE_VALUES, "IMPEDANCE_VALUES", LEVEL1, OPT_KEY, LIST_KEY, "0.0", "0, -5.0..0.00", NO_HELP },
		{ VEHICLE_TIME_VALUES, "VEHICLE_TIME_VALUES", LEVEL1, OPT_KEY, LIST_KEY, "-0.02", "0, -0.04..-0.01", NO_HELP },
		{ WALK_TIME_VALUES, "WALK_TIME_VALUES", LEVEL1, OPT_KEY, LIST_KEY, "0.0", "0, -1.0..-0.01", NO_HELP },
		{ DRIVE_ACCESS_VALUES, "DRIVE_ACCESS_VALUES", LEVEL1, OPT_KEY, LIST_KEY, "0.0", "0, -1.0..-0.01", NO_HELP },
		{ WAIT_TIME_VALUES, "WAIT_TIME_VALUES", LEVEL1, OPT_KEY, LIST_KEY, "0.0", "0, -1.0..-0.01", NO_HELP },
		{ LONG_WAIT_VALUES, "LONG_WAIT_VALUES", LEVEL1, OPT_KEY, LIST_KEY, "0.0", "0, -1.0..-0.01", NO_HELP },
		{ TRANSFER_TIME_VALUES, "TRANSFER_TIME_VALUES", LEVEL1, OPT_KEY, LIST_KEY, "0.0", "0, -1.0..-0.01", NO_HELP }, 
		{ PENALTY_TIME_VALUES, "PENALTY_TIME_VALUES", LEVEL1, OPT_KEY, LIST_KEY, "0.0", "0, -1.0..-0.01", NO_HELP },
		{ TERMINAL_TIME_VALUES, "TERMINAL_TIME_VALUES", LEVEL1, OPT_KEY, LIST_KEY, "0.0", "0, -1.0..-0.01", NO_HELP },
		{ DISTANCE_VALUES, "DISTANCE_VALUES", LEVEL1, OPT_KEY, LIST_KEY, "0.0", "0, -1.0..-0.01", NO_HELP },
		{ COST_VALUES, "COST_VALUES", LEVEL1, OPT_KEY, LIST_KEY, "0.0", "0, -5.0..0.0", NO_HELP },
		{ TRANSFER_COUNT_VALUES, "TRANSFER_COUNT_VALUES", LEVEL1, OPT_KEY, LIST_KEY, "0.0", "0, -1.0..-0.01", NO_HELP },
		{ DIFFERENCE_VALUES, "DIFFERENCE_VALUES", LEVEL1, OPT_KEY, LIST_KEY, "0.0", "0, -5.0..5.0", NO_HELP },
		{ USER_VALUES, "USER_VALUES", LEVEL1, OPT_KEY, LIST_KEY, "0.0", "0, -5.0..5.0", NO_HELP },

		{ MODE_ACCESS_MARKET, "MODE_ACCESS_MARKET", LEVEL1, OPT_KEY, TEXT_KEY, "", "SOV, SR2, SR3...", NO_HELP },
		{ ACCESS_MARKET_NAME, "ACCESS_MARKET_NAME", LEVEL1, OPT_KEY, TEXT_KEY, "", "", NO_HELP },
		{ NEW_TABLE_MODES, "NEW_TABLE_MODES", LEVEL1, OPT_KEY, TEXT_KEY, "", "", NO_HELP },
		{ OUTPUT_TRIP_FACTOR, "OUTPUT_TRIP_FACTOR", LEVEL0, OPT_KEY, FLOAT_KEY, "1.0", "1.0..1000.0", NO_HELP },
		{ NEW_MODE_SUMMARY_FILE, "NEW_MODE_SUMMARY_FILE", LEVEL0, OPT_KEY, OUT_KEY, "", FILE_RANGE, NO_HELP },
		{ NEW_MARKET_SEGMENT_FILE, "NEW_MARKET_SEGMENT_FILE", LEVEL0, OPT_KEY, OUT_KEY, "", FILE_RANGE, NO_HELP },
		{ NEW_MODE_SEGMENT_FILE, "NEW_MODE_SEGMENT_FILE", LEVEL0, OPT_KEY, OUT_KEY, "", FILE_RANGE, NO_HELP },

		{ NEW_FTA_SUMMIT_FILE, "NEW_FTA_SUMMIT_FILE", LEVEL0, OPT_KEY, OUT_KEY, "", FILE_RANGE, NO_HELP },
		{ TRIP_PURPOSE_LABEL, "TRIP_PURPOSE_LABEL", LEVEL0, OPT_KEY, TEXT_KEY, "Peak Home-Based Work", "", NO_HELP },
		{ TRIP_PURPOSE_NUMBER, "TRIP_PURPOSE_NUMBER", LEVEL0, OPT_KEY, INT_KEY, "1", "1..100", NO_HELP },
		{ TRIP_TIME_PERIOD, "TRIP_TIME_PERIOD", LEVEL0, OPT_KEY, INT_KEY, "1", "1..100", NO_HELP },
		
		{ NEW_PRODUCTION_FILE, "NEW_PRODUCTION_FILE", LEVEL0, OPT_KEY, OUT_KEY, "", FILE_RANGE, NO_HELP },
		{ NEW_PRODUCTION_FORMAT, "NEW_PRODUCTION_FORMAT", LEVEL0, OPT_KEY, TEXT_KEY, "TAB_DELIMITED", FORMAT_RANGE, FORMAT_HELP },
		{ NEW_ATTRACTION_FILE, "NEW_ATTRACTION_FILE", LEVEL0, OPT_KEY, OUT_KEY, "", FILE_RANGE, NO_HELP },
		{ NEW_ATTRACTION_FORMAT, "NEW_ATTRACTION_FORMAT", LEVEL0, OPT_KEY, TEXT_KEY, "TAB_DELIMITED", FORMAT_RANGE, FORMAT_HELP },
		{ CALIBRATION_TARGET_FILE, "CALIBRATION_TARGET_FILE", LEVEL0, OPT_KEY, IN_KEY, "", FILE_RANGE, NO_HELP },
		{ CALIBRATION_TARGET_FORMAT, "CALIBRATION_TARGET_FORMAT", LEVEL0, OPT_KEY, TEXT_KEY, "TAB_DELIMITED", FORMAT_RANGE, FORMAT_HELP },
		{ CALIBRATION_SCALING_FACTOR, "CALIBRATION_SCALING_FACTOR", LEVEL0, OPT_KEY, FLOAT_KEY, "1.0", "1.0..5.0", NO_HELP },
		{ MAX_CALIBRATION_ITERATIONS, "MAX_CALIBRATION_ITERATIONS", LEVEL0, OPT_KEY, INT_KEY, "20", "1..1000", NO_HELP },
		{ ADJUST_FIRST_MODE_CONSTANTS, "ADJUST_FIRST_MODE_CONSTANTS", LEVEL0, OPT_KEY, BOOL_KEY, "FALSE", BOOL_RANGE, NO_HELP },
		{ CALIBRATION_EXIT_RMSE, "CALIBRATION_EXIT_RMSE", LEVEL0, OPT_KEY, FLOAT_KEY, "5.0", "0.01..50.0", NO_HELP },
		{ PLAN_SKIMS_IN_MEMORY, "PLAN_SKIMS_IN_MEMORY", LEVEL0, OPT_KEY, BOOL_KEY, "FALSE", BOOL_RANGE, NO_HELP },
		{ REPORT_AFTER_ITERATIONS, "REPORT_AFTER_ITERATIONS", LEVEL0, OPT_KEY, LIST_KEY, "NONE", RANGE_RANGE, NO_HELP },
		{ NEW_MODE_CONSTANT_FILE, "NEW_MODE_CONSTANT_FILE", LEVEL0, OPT_KEY, OUT_KEY, "", FILE_RANGE, NO_HELP },
		{ NEW_MODE_CONSTANT_FORMAT, "NEW_MODE_CONSTANT_FORMAT", LEVEL0, OPT_KEY, TEXT_KEY, "TAB_DELIMITED", FORMAT_RANGE, FORMAT_HELP },
		{ NEW_CALIBRATION_DATA_FILE, "NEW_CALIBRATION_DATA_FILE", LEVEL0, OPT_KEY, OUT_KEY, "", FILE_RANGE, NO_HELP },
		END_CONTROL
	};
	const char *reports [] = {
		"MODE_CHOICE_SCRIPT",
		"MODE_CHOICE_STACK",
		"MODE_SUMMARY_REPORT",
		"MARKET_SEGMENT_REPORT",
		"CALIBRATION_REPORT",
		"TARGET_DATA_REPORT",
		"MODE_VALUE_SUMMARY",
		"SEGMENT_VALUE_SUMMARY",
		"ACCESS_MARKET_SUMMARY",
		"LOST_TRIPS_REPORT",
		""
	};
	Required_System_Files (required_files);
	Optional_System_Files (optional_files);
	File_Service_Keys (file_service_keys);
	Data_Service_Keys (data_service_keys);
	Select_Service_Keys (select_service_keys);

	Key_List (keys);
	Report_List (reports);

	org_map_field = des_map_field = segment_field = zone_field = market_field = model_field = -1;
	iteration, model_num = num_modes = num_models = num_access = num_market = header_value = zones = first_model = 0;
	period = purpose = 0;
	max_iter = 1;
	imp_field = time_field = walk_field = auto_field = wait_field = lwait_field = xwait_field = tpen_field = term_field = diff_field = -1;
	dist_field = cost_field = xfer_field = bias_field = pef_field = cbd_field = const_field = user_field = plan_field = -1;
	scale_fac = 0.0;
	trip_factor = 1.0;
	key_mode = -1;
	summary_flag = market_flag = segment_flag = constant_flag = mode_value_flag = seg_value_flag = false;
	plan_flag = plan_skim_flag = new_skim_flag = skim_memory_flag = bias_flag = tour_choice_flag = false;
	calib_flag = calib_seg_flag = calib_model_flag = calib_report = new_calib_flag = data_flag = mode_seg_flag = false;
	prod_flag = attr_flag = memory_flag = new_plan_flag = rider_flag = park_demand_flag = penalty_update_flag = false;
	org_flag = initial_flag = sum_flag = prod_sum_flag = attr_sum_flag = save_summit_flag = save_flag = save_iter_flag = iter_save_flag = false;

	table_file = new_table_file = 0;
}

//---------------------------------------------------------
//	ModeChoice destructor
//---------------------------------------------------------

ModeChoice::~ModeChoice (void)
{
	if (table_file != 0) {
		delete table_file;
	}
	if (new_table_file != 0) {
		delete new_table_file;
	}
}
#ifdef _CONSOLE
//---------------------------------------------------------
//	main program
//---------------------------------------------------------

int main (int commands, char *control [])
{
	int stat = 0;
	ModeChoice *program = 0;
	try {
		program = new ModeChoice ();
		stat = program->Start_Execution (commands, control);
	}
	catch (exit_exception &e) {
		stat = e.Exit_Code ();
	}
	if (program != 0) delete program;
	return (stat);
}
#endif