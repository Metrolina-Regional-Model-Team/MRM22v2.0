//*********************************************************
//	Control.cpp - process the control parameters
//*********************************************************

#include "ModeChoice.hpp"

#include "TDF_Matrix.hpp"

//---------------------------------------------------------
//	Program_Control
//---------------------------------------------------------

void ModeChoice::Program_Control (void)
{
	int i, num, num2, id, nest, table;
	double size, nesting;
	String key, text, format;
	Strings strings;
	Str_Itr str_itr;
	Str_ID_Itr id_itr;
	Str_ID_Stat id_stat;
	Db_Mat_Ptr matrix_ptr = 0;
	Integers access_modes, nest_modes, zero_tab;
	Double_List value_list;
	String_List str_list;
	Plan_File_Ptr file;
	Plan_Skim_File_Ptr skim_ptr;
	Plan_Skim_Data_Ptr data_ptr;
	Int_Itr int_itr;

	Data_Service::Program_Control ();

	Print (2, String ("%s Control Keys:") % Program ());
	Print (1);

	//---- check for plan files ----

	num = Highest_Control_Group (PLAN_FILE, 0);
	num2 = Highest_Control_Group (PLAN_SKIM_FILE, 0);

	plan_flag = (num > 0 || num2 > 0);

	if (!plan_flag) {

		//---- open trip files ----

		key = Get_Control_String (TRIP_TABLE_FILE);

		if (key.empty ()) {
			Error ("A Trip Table File is Required");
		}
		key = Project_Filename (key);

		format = Db_Header::Def_Format (key);

		if (format.empty ()) {
			if (Check_Control_Key (TRIP_TABLE_FORMAT)) {
				format = Get_Control_String (TRIP_TABLE_FORMAT);
			} else {
				format = Get_Default_Text (TRIP_TABLE_FORMAT);
			}
		}
		table_file = TDF_Matrix (READ, format);

		table_file->File_Type ("Trip Table File");
		table_file->File_ID ("Trip");

		table_file->Open (key);

		zones = table_file->Num_Des ();
		num = table_file->Tables ();

		Print (0, " (Zones=") << zones << " Tables=" << num << ")";

		//---- select trip tables ----

		key = Get_Control_Text (SELECT_TRIP_TABLES);

		if (key.empty () || key.Equals ("ALL")) {
			for (i = 0; i < num; i++) {
				table = table_file->Table_Field_Number (i);
				table_map.push_back (table);
				table_names.push_back (table_file->Field (table)->Name ());
			}
		} else {
			key.Parse (strings);

			for (str_itr = strings.begin (); str_itr != strings.end (); str_itr++) {
				table_map.push_back (table_file->Required_Field (*str_itr));
				table_names.push_back (*str_itr);
			}
		}
		num_models = (int) table_map.size ();

		Print (1);

		//---- create new trip files ----

		key = Get_Control_String (NEW_TRIP_TABLE_FILE);

		if (key.empty ()) {
			Error ("A New Trip Table File is Required");
		}
		if (Check_Control_Key (NEW_TRIP_TABLE_FORMAT)) {
			format = Get_Control_String (NEW_TRIP_TABLE_FORMAT);
		}
		new_table_file = TDF_Matrix (CREATE, format);

		new_table_file->File_Type ("New Trip Table File");
		new_table_file->File_ID ("NewTrip");
		new_table_file->Filename (Project_Filename (key));
		new_table_file->Copy_OD_Map (table_file);

		size = sizeof (double) + (table_file->Table_Field (0)->Decimal () + 2) / 10.0;

		num = Highest_Control_Group (NEW_TABLE_MODES, 0);

		for (i = 1; i <= num; i++) {
			key = Get_Control_String (NEW_TABLE_MODES, i);
			if (key.empty ()) continue;

			text = key;
			text.Split (key, "=");
			if (text.empty ()) text = key;

			new_table_file->Add_Field (text, DB_DOUBLE, size, NO_UNITS, true);
		}
		new_table_file->Add_Field ("ORG", DB_INTEGER, 4, NO_UNITS, true);
		new_table_file->Add_Field ("DES", DB_INTEGER, 4, NO_UNITS, true);

		new_table_file->Create ();

		if (!new_table_file->Allocate_Data ()) {
			Error (String ("Insufficient Memory for Matrix %s") % new_table_file->File_ID ());
		}
		Print (0, " (Zones=") << new_table_file->Num_Des () << " Tables=" << new_table_file->Tables () << ")";
		Print (1);

		//---- open skim files ----

		num = Highest_Control_Group (SKIM_FILE, 0);
		if (num == 0) {
			Error ("No Skim Files were Found");
		}

		skim_files.reserve (num);

		for (i = 1; i <= num; i++) {
			key = Get_Control_String (SKIM_FILE, i);
			if (key.empty ()) continue;

			key = Project_Filename (key);

			format = Db_Header::Def_Format (key);

			if (format.empty ()) {
				if (Check_Control_Key (SKIM_FORMAT, i)) {
					format = Get_Control_String (SKIM_FORMAT, i);
				} else {
					format = Data_Format (table_file->Dbase_Format (), table_file->Model_Format ());
				}
			}
			matrix_ptr = TDF_Matrix (READ, format);

			matrix_ptr->File_Type (String ("Skim File #%d") % i);
			matrix_ptr->File_ID (String ("Skim%d") % i);

			matrix_ptr->Open (key);

			Print (0, " (Zones=") << matrix_ptr->Num_Des () << " Tables=" << matrix_ptr->Tables () << ")";
			Print (1);

			skim_files.push_back (matrix_ptr);
		}

		//---- get the trip purpose label ----

		key = Get_Control_Text (TRIP_PURPOSE_LABEL);

		//---- get the trip purpose number ----

		purpose = Get_Control_Integer (TRIP_PURPOSE_NUMBER);

		//---- get the time period ----

		period = Get_Control_Integer (TRIP_TIME_PERIOD);

		//---- disable keys ----

		System_File_False (NODE);
		System_File_False (LINK);
		System_File_False (LOCATION);
		System_File_False (PARKING);
		System_File_False (TRANSIT_STOP);
		System_File_False (TRANSIT_ROUTE);
		System_File_False (TRANSIT_SCHEDULE);
		System_File_False (VEHICLE_TYPE);
		System_File_False (RIDERSHIP);
		System_File_False (PARK_DEMAND);
		System_File_False (NEW_RIDERSHIP);
		System_File_False (NEW_PARK_DEMAND);
		System_File_False (NEW_PLAN_SKIM);

	} else {

		if (num > 0 && num2 > 0) {
			Error ("Plan Files and Plan Skim Files are Incompatible");
		}
		key = Get_Control_String (TRIP_TABLE_FILE);
		if (!key.empty ()) {
			Error ("Trip Table Files and Plan Files are Incompatible");
		}
		if (num2 > 0) {
			plan_skim_flag = true;

			if (System_File_Flag (NEW_PLAN)) {
				Warning ("Plan Skims cannot create a New Plan File");
				System_File_False (NEW_PLAN);
			}
			num = num2;
		}

		//---- plan file based processing ----

		for (i = 1; i <= num; i++) {
			if (plan_skim_flag) {
				key = Get_Control_String (PLAN_SKIM_FILE, i);
				if (key.empty ()) continue;

				skim_ptr = new Plan_Skim_File ();

				skim_ptr->File_Type (String ("Plan Skim #%d") % i);
				skim_ptr->File_ID (String ("Plan%d") % i);

				if (Check_Control_Key (PLAN_SKIM_FORMAT)) {
					skim_ptr->Dbase_Format (Get_Control_String (PLAN_SKIM_FORMAT));
				}
				skim_ptr->Open (Project_Filename (key));

				plan_skim_files.push_back (skim_ptr);
			} else {
				key = Get_Control_String (PLAN_FILE, i);
				if (key.empty ()) continue;

				file = new Plan_File ();

				file->File_Type (String ("Plan File #%d") % i);
				file->File_ID (String ("Plan%d") % i);

				if (Check_Control_Key (PLAN_FORMAT)) {
					file->Dbase_Format (Get_Control_String (PLAN_FORMAT));
				}
				file->Open (Project_Filename (key));

				plan_files.push_back (file);
			}
			skim_ptr = new Plan_Skim_File (MODIFY, BINARY);

			skim_ptr->File_Type (String ("Plan Skim #%d") % i);
			skim_ptr->File_ID (String ("Plan%d") % i);
			skim_ptr->Create_Fields ();

			plan_skims.push_back (skim_ptr);

			skim_ptr = new Plan_Skim_File (MODIFY, BINARY);
			skim_ptr->Create_Fields ();

			index_skims.push_back (skim_ptr);

			id = (int) plan_num_map.size ();
			plan_num_map.insert (Int_Map_Data (i, id));
		}

		//---- tour mode choice flag ----

		tour_choice_flag = Get_Control_Flag (TOUR_MODE_CHOICE);

		//---- tour mode choice flag ----

		auto_occ_flag = Get_Control_Flag (APPLY_AUTO_OCCUPANCY);

		//---- create the new plan skim file ----

		new_skim_flag = System_File_Flag (NEW_PLAN_SKIM);
		new_plan_skim = System_Plan_Skim_File (true);

		//---- required keys ----

		System_File_True (NODE);
		System_File_True (LINK);
		System_File_True (LOCATION);

		rider_flag = (System_File_Flag (RIDERSHIP) || System_File_Flag (NEW_RIDERSHIP));

		if (rider_flag) {
			System_File_True (TRANSIT_STOP);
			System_File_True (TRANSIT_ROUTE);
			System_File_True (TRANSIT_SCHEDULE);
			System_File_True (VEHICLE_TYPE);
		}

		park_demand_flag = System_File_Flag (PARK_DEMAND);

		if (System_File_Flag (NEW_PARK_DEMAND)) {
			System_File_True (PARKING);
		}
	}

	//---- create the zone database ----

	Zone_File *zone_file = System_Zone_File ();

	org_db.File_ID ("Org");
	org_db.File_Type (zone_file->File_Type ());
	des_db.File_ID ("Des");
	des_db.File_Type (zone_file->File_Type ());
	
	zone_field = zone_file->Required_Field (ZONE_FIELD_NAMES);

	org_db.Replicate_Fields (zone_file, false, false, true);
	des_db.Replicate_Fields (zone_file, false, false, true);

	//---- open mode constant file ----

	Print (1);
	key = Get_Control_String (MODE_CONSTANT_FILE);

	if (!key.empty ()) {
		constant_file.File_Type ("Mode Constant File");

		if (Check_Control_Key (MODE_CONSTANT_FORMAT)) {
			constant_file.Dbase_Format (Get_Control_String (MODE_CONSTANT_FORMAT));
		}
		constant_file.Open (Project_Filename (key));
		constant_flag = true;
	}

	//---- open mode bias file ----

	key = Get_Control_String (MODE_BIAS_FILE);

	if (!key.empty ()) {
		bias_file.File_Type ("Mode Bias File");

		if (Check_Control_Key (MODE_BIAS_FORMAT)) {
			bias_file.Dbase_Format (Get_Control_String (MODE_CONSTANT_FORMAT));
		}
		bias_file.Open (Project_Filename (key));
		bias_flag = true;
	}

	//---- open segment map file ----

	key = Get_Control_String (SEGMENT_MAP_FILE);

	if (!key.empty ()) {
		Print (1);
		segment_file.File_Type ("Segment Map File");

		if (Check_Control_Key (SEGMENT_MAP_FORMAT)) {
			segment_file.Dbase_Format (Get_Control_String (SEGMENT_MAP_FORMAT));
		}
		segment_file.Open (Project_Filename (key));
		segment_flag = true;

		//---- origin map field ----

		key = Get_Control_Text (ORIGIN_MAP_FIELD);

		if (!key.empty ()) {
			org_map_field = zone_file->Required_Field (key);
			Print (0, " (Zone Field = ") << (org_map_field + 1) << ")";
		}

		//---- destination map field ----

		key = Get_Control_Text (DESTINATION_MAP_FIELD);

		if (!key.empty ()) {
			des_map_field = zone_file->Required_Field (key);
			Print (0, " (Zone Field = ") << (des_map_field + 1) << ")";
		}
	}

	//---- open mode choice script ----

	Print (1);
	key = Get_Control_String (MODE_CHOICE_SCRIPT);

	if (!key.empty ()) {
		script_file.File_Type ("Mode Choice Script");

		script_file.Open (Project_Filename (key));
	}

	//---- primary mode choice ----

	Print (1);
	key = Get_Control_Text (PRIMARY_MODE_CHOICE);
	key.Parse (strings);

	nesting = 1.0;

	for (str_itr = strings.begin (); str_itr != strings.end (); str_itr++) {
		id = (int) mode_id.size ();

		id_stat = mode_id.insert (Str_ID_Data (*str_itr, id));

		if (id_stat.second) {
			mode_names.push_back (*str_itr);
			mode_nest.push_back (-1);
			mode_nested.push_back (-1);
			nest_levels.push_back (nesting);
			nest_modes.push_back (id);
		} else {
			Warning ("Duplicate Mode = ") << *str_itr;
		}
	}
	nest_mode.push_back (-1);
	nest_coef.push_back (nesting);
	nested_modes.push_back (nest_modes);

	//---- mode choice nest ----

	num = Highest_Control_Group (MODE_CHOICE_NEST, 0);
	nesting = 0.5;

	for (i=1; i <= num; i++) {
		key = Get_Control_String (NESTING_COEFFICIENT, i);
		if (!key.empty ()) {
			nesting = key.Double ();
		}
		key = Get_Control_Text (MODE_CHOICE_NEST, i);
		if (key.empty ()) continue;

		key.Parse (strings, "=");
		text = strings [0];

		id_itr = mode_id.find (text);

		if (id_itr == mode_id.end ()) {
			Error (String ("Nested Mode %s is not defined") % text);
			nest = 0;
		} else {
			nest = id_itr->second;
		}
		nest_modes.clear ();
		key = strings [1];
		key.Parse (strings);

		for (str_itr = strings.begin (); str_itr != strings.end (); str_itr++) {
			id = (int) mode_id.size ();
			id_stat = mode_id.insert (Str_ID_Data (*str_itr, id));

			if (id_stat.second) {
				mode_names.push_back (*str_itr);
				mode_nest.push_back (nest);
				mode_nested.push_back (-1);
				nest_levels.push_back (nest_levels [nest] * nesting);
				nest_modes.push_back (id);
			} else {
				Warning ("Duplicate Mode = ") << *str_itr;
			}
		}
		mode_nested [nest] = (int) nest_mode.size ();
		nest_mode.push_back (nest);
		nest_coef.push_back (nesting);
		nested_modes.push_back (nest_modes);
	}
	num_nests = (int) nested_modes.size ();
	num_modes = (int) mode_names.size ();

	for (i=0, int_itr = mode_nested.begin (); int_itr != mode_nested.end (); int_itr++, i++) {
		if (*int_itr == -1) {
			key_mode = i;
			break;
		}
	}

	//---- print the nesting coefficient ----

	Print (1);
	for (i=1; i <= num; i++) {
		Get_Control_Text (NESTING_COEFFICIENT, i);
	}

	//---- model names ----

	Print (1);
	num = Highest_Control_Group (MODEL_NAMES, 0);

	if (num > 0) {
		Get_Control_List_Groups (MODEL_NAMES, str_list);

		num = (int) str_list.size () - 1;
	} else {
		num = -1;
	}
	if (plan_flag) {
		if (num < 1) {
			Error ("Model Names are Required");
		}
		first_model = -1;
		for (i = 1; i <= num; i++) {
			model_names.push_back (str_list [i]);
			if (first_model == -1 && !model_names [i-1].empty ()) {
				first_model = i - 1;
			}
		}
	} else {
		if (num > num_models) {
			Warning ("More Model Names than Trip Tables");
		}

		for (i = 0; i < num_models; i++) {
			if (i <= num) {
				model_names.push_back (str_list [i + 1]);
			} else {
				model_names.push_back (table_names [i]);
			}
		}
	}
	num_models = (int) model_names.size ();

	//---- impedance values ----

	imp_values.assign (num_models, 0.0);

	Get_Control_List_Groups (IMPEDANCE_VALUES, value_list);

	for (i = first_model; i < num_models; i++) {
		imp_values [i] = value_list.Best (i + 1);
	}

	//---- vehicle time values ----

	time_values.assign (num_models, 0.0);

	Get_Control_List_Groups (VEHICLE_TIME_VALUES, value_list);

	for (i = first_model; i < num_models; i++) {
		time_values [i] = value_list.Best (i + 1);
	}

	//---- walk time values ----

	walk_values.assign (num_models, 0.0);

	Get_Control_List_Groups (WALK_TIME_VALUES, value_list);

	for (i = first_model; i < num_models; i++) {
		walk_values [i] = value_list.Best (i + 1);
	}

	//---- drive access values ----

	drive_values.assign (num_models, 0.0);

	Get_Control_List_Groups (DRIVE_ACCESS_VALUES, value_list);

	for (i = first_model; i < num_models; i++) {
		drive_values [i] = value_list.Best (i + 1);
	}

	//---- wait time values ----

	wait_values.assign (num_models, 0.0);

	Get_Control_List_Groups (WAIT_TIME_VALUES, value_list);

	for (i = first_model; i < num_models; i++) {
		wait_values [i] = value_list.Best (i + 1);
	}

	//---- long wait time values ----

	lwait_values.assign (num_models, 0.0);

	Get_Control_List_Groups (LONG_WAIT_VALUES, value_list);

	for (i = first_model; i < num_models; i++) {
		lwait_values [i] = value_list.Best (i + 1);
	}

	//---- transfer time values ----

	xwait_values.assign (num_models, 0.0);

	Get_Control_List_Groups (TRANSFER_TIME_VALUES, value_list);

	for (i = first_model; i < num_models; i++) {
		xwait_values [i] = value_list.Best (i + 1);
	}

	//---- penalty time values ----

	tpen_values.assign (num_models, 0.0);

	Get_Control_List_Groups (PENALTY_TIME_VALUES, value_list);

	for (i = first_model; i < num_models; i++) {
		tpen_values [i] = value_list.Best (i + 1);
	}

	//---- terminal time values ----

	term_values.assign (num_models, 0.0);

	Get_Control_List_Groups (TERMINAL_TIME_VALUES, value_list);

	for (i = first_model; i < num_models; i++) {
		term_values [i] = value_list.Best (i + 1);
	}

	//---- distance values ----

	dist_values.assign (num_models, 0.0);

	Get_Control_List_Groups (DISTANCE_VALUES, value_list);

	for (i = first_model; i < num_models; i++) {
		dist_values [i] = value_list.Best (i + 1);
	}

	//---- cost value tables ----

	cost_values.assign (num_models, 0.0);

	Get_Control_List_Groups (COST_VALUES, value_list);

	for (i = first_model; i < num_models; i++) {
		cost_values [i] = value_list.Best (i + 1);
	}

	//---- transfer count values ----

	xfer_values.assign (num_models, 0.0);

	Get_Control_List_Groups (TRANSFER_COUNT_VALUES, value_list);

	for (i = first_model; i < num_models; i++) {
		xfer_values [i] = value_list.Best (i + 1);
	}

	//---- difference values ----

	diff_values.assign (num_models, 0.0);

	Get_Control_List_Groups (DIFFERENCE_VALUES, value_list);

	for (i = first_model; i < num_models; i++) {
		diff_values [i] = value_list.Best (i + 1);
	}

	//---- user values ----

	user_values.assign (num_models, 0.0);

	Get_Control_List_Groups (USER_VALUES, value_list);

	for (i = first_model; i < num_models; i++) {
		user_values [i] = value_list.Best (i + 1);
	}

	if (!plan_flag) {

		//---- mode access market ----

		num = Highest_Control_Group (MODE_ACCESS_MARKET, 0);
		Print (1);

		for (i=1; i <= num; i++) {
			key = Get_Control_Text (MODE_ACCESS_MARKET, i);
			if (key.empty ()) continue;

			key.Parse (strings);
			access_modes.clear ();

			for (str_itr = strings.begin (); str_itr != strings.end (); str_itr++) {
				id_itr = mode_id.find (*str_itr);
				if (id_itr == mode_id.end ()) {
					Warning ("Market Access Mode ") << *str_itr << " was Not Defined";
				}
				access_modes.push_back (id_itr->second);
			}
			access_markets.push_back (access_modes);

			if (i <= 2) {
				nest = 1;
			} else if (i <= 4) {
				nest = 2;
			} else {
				nest = 0;
			}
			market_group.push_back (nest);

			key = Get_Control_Text (ACCESS_MARKET_NAME, i);
			if (key.empty ()) {
				key ("#%d") % i;
			} else {
				Print (1);
			}
			access_names.push_back (key);
		}

		//---- new table modes ----

		num = Highest_Control_Group (NEW_TABLE_MODES, 0);
		Print (1);

		zero_tab.assign (num_models, -1);
		output_table.assign (num_modes, zero_tab);

		for (i = 1; i <= num; i++) {
			key = Get_Control_Text (NEW_TABLE_MODES, i);
			if (key.empty ()) continue;

			key.Split (text, "=");
			text.Parse (strings);

			for (str_itr = strings.begin (); str_itr != strings.end (); str_itr++) {
				key = *str_itr;
				key.Split (text, ".");

				id_itr = mode_id.find (text);
				if (id_itr == mode_id.end ()) {
					Warning ("New Table Mode ") << *str_itr << " was Not Defined";
				}
				if (key.empty ()) {
					for (table = 0; table < num_models; table++) {
						output_table [id_itr->second] [table] = i - 1;
					}
				} else {
					table = key.Integer () - 1;
					if (table < 0 || table >= num_models) {
						Warning ("New Table Mode ") << *str_itr << " was Not Defined";
					} else {
						output_table [id_itr->second] [table] = i - 1;
					}
				}
			}
		}
	} else {
		if (Highest_Control_Group (MODE_ACCESS_MARKET, 0) > 0) {
			Warning ("Mode Access Markets are Not Available for Plan Processing");
		}
		if (Highest_Control_Group (NEW_TABLE_MODES, 0) > 0) {
			Warning ("New Table Modes are Not Available for Plan Processing");
		}
	}

	//---- output trip factor ----

	Print (1);
	trip_factor = Get_Control_Double (OUTPUT_TRIP_FACTOR);

	//---- create the mode summary file ----

	key = Get_Control_String (NEW_MODE_SUMMARY_FILE);

	if (!key.empty ()) {
		Print (1);
		summary_file.File_Type ("New Mode Summary File");

		summary_file.Create (Project_Filename (key));
		summary_flag = true;
	} else {
		summary_flag = Report_Flag (MODE_SUMMARY);
	}

	//---- create the market segment file ----

	key = Get_Control_String (NEW_MARKET_SEGMENT_FILE);

	if (!key.empty ()) {
		Print (1);
		market_file.File_Type ("New Market Segment File");

		market_file.Create (Project_Filename (key));
		market_flag = true;
	} else {
		market_flag = Report_Flag (MARKET_REPORT);
	}
	if (market_flag && !segment_flag) {
		Error ("A Segment Map File is required for Market Segment Processing");
	}

	//---- create the mode segment file ----

	key = Get_Control_String (NEW_MODE_SEGMENT_FILE);

	if (!key.empty ()) {
		Print (1);
		mode_seg_file.File_Type ("New Mode Segment File");

		mode_seg_file.Create (Project_Filename (key));
		mode_seg_flag = true;
	}
	if (mode_seg_flag && !segment_flag) {
		Error ("A Segment Map File is required for Mode Segment Processing");
	}
	
	//---- create the summit file ----

	key = Get_Control_String (NEW_FTA_SUMMIT_FILE);

	if (!key.empty ()) {
		if (plan_flag) {
			Warning ("New FTA Summit File is Not Available for Plan Processing");
		} else {
			Print (1);
			summit_file.File_Type ("New FTA Summit File");
			summit_file.Dbase_Format (BINARY);
			//summit_file.Dbase_Format (TAB_DELIMITED);
			summit_file.Nest (NESTED);
			summit_file.Header_Lines (2);

			summit_file.Add_Field ("ZONES", DB_INTEGER, 4, NO_UNITS, true);
			summit_file.Add_Field ("MARKETS", DB_INTEGER, 4, NO_UNITS, true);
			summit_file.Add_Field ("IVTTT", DB_DOUBLE, 4, NO_UNITS, true);
			summit_file.Add_Field ("IVTTA", DB_DOUBLE, 4, NO_UNITS, true);
			summit_file.Add_Field ("PURPOSE", DB_STRING, 6, NO_UNITS, true);
			summit_file.Add_Field ("TIME", DB_STRING, 6, NO_UNITS, true);
			summit_file.Add_Field ("NAME", DB_STRING, 60, NO_UNITS, true);

			summit_org = summit_file.Add_Field ("ORG", DB_INTEGER, 2, NO_UNITS, true, NESTED);
			summit_des = summit_file.Add_Field ("DES", DB_INTEGER, 2, NO_UNITS, true, NESTED);
			summit_market = summit_file.Add_Field ("MARKET", DB_INTEGER, 2, NO_UNITS, true, NESTED);
			summit_total_trips = summit_file.Add_Field ("TOTAL_TRIPS", DB_DOUBLE, 4, NO_UNITS, true, NESTED);
			summit_motor_trips = summit_file.Add_Field ("MOTOR_TRIPS", DB_DOUBLE, 4, NO_UNITS, true, NESTED);
			summit_auto_exp = summit_file.Add_Field ("AUTO_EXP", DB_DOUBLE, 4.6, NO_UNITS, true, NESTED);
			summit_walk_market = summit_file.Add_Field ("WALK_MARKET", DB_DOUBLE, 4, NO_UNITS, true, NESTED);
			summit_walk_share = summit_file.Add_Field ("WALK_SHARE", DB_DOUBLE, 4, NO_UNITS, true, NESTED);
			summit_drive_market = summit_file.Add_Field ("DRIVE_MARKET", DB_DOUBLE, 4, NO_UNITS, true, NESTED);
			summit_drive_share = summit_file.Add_Field ("DRIVE_SHARE", DB_DOUBLE, 4, NO_UNITS, true, NESTED);

			summit_file.Create (Project_Filename (key));
			summit_flag = true;

			summit_file.Put_Field (0, zones);
			summit_file.Put_Field (1, num_models);
			summit_file.Put_Field (2, time_values [first_model]);
			summit_file.Put_Field (3, time_values [first_model]);
			summit_file.Put_Field (4, purpose);
			summit_file.Put_Field (5, period);
			summit_file.Put_Field (6, key);

			summit_file.Write (false);
		}
	}
		
	//---- create the production file ----

	key = Get_Control_String (NEW_PRODUCTION_FILE);

	if (!key.empty ()) {
		Print (1);
		prod_file.File_Type ("New Production File");

		if (Check_Control_Key (NEW_PRODUCTION_FORMAT)) {
			prod_file.Dbase_Format (Get_Control_String (NEW_PRODUCTION_FORMAT));
		}
		prod_file.Add_Field ("ZONE", DB_INTEGER, 6);

		for (i=0; i <= num_modes; i++) {
			if (i == num_modes) {
				text = "TOTAL";
			} else {
				text = mode_names [i];
			}
			prod_file.Add_Field (text, DB_DOUBLE, 16.2);
		}
		prod_file.Create (Project_Filename (key));
		prod_flag = true;
	}

	//---- create the attraction file ----

	key = Get_Control_String (NEW_ATTRACTION_FILE);

	if (!key.empty ()) {
		Print (1);
		attr_file.File_Type ("New Attraction File");

		if (Check_Control_Key (NEW_ATTRACTION_FORMAT)) {
			attr_file.Dbase_Format (Get_Control_String (NEW_ATTRACTION_FORMAT));
		}
		attr_file.Add_Field ("ZONE", DB_INTEGER, 6);

		for (i=0; i <= num_modes; i++) {
			if (i == num_modes) {
				text = "TOTAL";
			} else {
				text = mode_names [i];
			}
			attr_file.Add_Field (text, DB_DOUBLE, 16.2);
		}
		attr_file.Create (Project_Filename (key));
		attr_flag = true;
	}

	//---- open calibration target file ----

	key = Get_Control_String (CALIBRATION_TARGET_FILE);

	if (!key.empty ()) {
		Print (1);
		target_file.File_Type ("Calibration Target File");

		if (Check_Control_Key (CALIBRATION_TARGET_FORMAT)) {
			target_file.Dbase_Format (Get_Control_String (CALIBRATION_TARGET_FORMAT));
		}
		target_file.Open (Project_Filename (key));
		calib_flag = true;

		//---- calibration scaling factor ----

		scale_fac = Get_Control_Double (CALIBRATION_SCALING_FACTOR);

		//---- max calibration iterations ----

		max_iter = Get_Control_Integer (MAX_CALIBRATION_ITERATIONS);

		//---- adjust first mode constants ----

		first_mode_flag = Get_Control_Flag (ADJUST_FIRST_MODE_CONSTANTS);

		//---- calibration scaling factor ----

		exit_rmse = Get_Control_Double (CALIBRATION_EXIT_RMSE);

		//---- plan skims in memory -----

		if (plan_flag) {
			skim_memory_flag = Get_Control_Flag (PLAN_SKIMS_IN_MEMORY);

			if (skim_memory_flag) {
				Plan_Skim_File_Itr itr;

				for (itr = plan_skims.begin (); itr != plan_skims.end (); itr++) {
					data_ptr = new Plan_Skim_Data_Array;
					data_ptr->Create_Fields ();
					plan_skim_arrays.push_back (data_ptr);
				}
			}
		}

		if (Check_Control_Key (REPORT_AFTER_ITERATIONS)) {
			Print (1);
			key = Get_Control_Text (REPORT_AFTER_ITERATIONS);

			if (!key.empty () && !key.Equals ("NONE")) {
				if (key.Equals ("ALL")) {
					key ("%d..%d") % 1 % max_iter;
				}
				save_iter_flag = true;
				if (!save_iter_range.Add_Ranges (key)) {
					Error ("Adding Iteration Ranges");
				}
			}
		}

		//---- create the new mode constant file ----

		key = Get_Control_String (NEW_MODE_CONSTANT_FILE);

		if (!key.empty ()) {
			calib_file.File_Type ("New Mode Constant File");

			if (Check_Control_Key (NEW_MODE_CONSTANT_FORMAT)) {
				calib_file.Dbase_Format (Get_Control_String (NEW_MODE_CONSTANT_FORMAT));
			}
			calib_file.Create (Project_Filename (key));
			new_calib_flag = true;
		}

		//---- create the new calibration data file ----

		key = Get_Control_String (NEW_CALIBRATION_DATA_FILE);

		if (!key.empty ()) {
			data_file.File_Type ("New Calibration Data File");

			data_file.Create (Project_Filename (key));
			data_flag = true;
		}
	}

	//---- process select service keys ----

	Read_Select_Keys ();

	calib_report = Report_Flag (CALIB_REPORT);

	mode_value_flag = Report_Flag (MODE_VALUES);
	seg_value_flag = Report_Flag (SEGMENT_VALUES);
	access_flag = Report_Flag (ACCESS_MARKET);
	lost_flag = Report_Flag (LOST_TRIPS);

	if (plan_flag) {
		if (access_flag) {
			access_flag = false;
			Warning ("Access Market Reports are Not Available for Plan Processing");
			Show_Message (1);
		}
		if (lost_flag) {
			lost_flag = false;
			Warning ("Lost Trip Reports are Not Available for Plan Processing");
			Show_Message (1);
		}
	}
}
