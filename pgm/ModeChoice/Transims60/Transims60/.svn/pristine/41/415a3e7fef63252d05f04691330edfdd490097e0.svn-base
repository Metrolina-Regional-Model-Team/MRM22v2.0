//*********************************************************
//	Control.cpp - Program Control
//*********************************************************

#include "TransitNet.hpp"

//---------------------------------------------------------
//	Program_Control
//---------------------------------------------------------

void TransitNet::Program_Control (void)
{
	int i, low, high;
	String key, low_str, high_str;
	Strings parts;
	Str_Itr str_itr;

	//---- open network files ----

	add_connections = Set_Control_Flag (ADD_TRANSIT_CONNECTIONS);
	Transit_Connections (add_connections);

	if (!Get_Control_String (ZONE_STOP_ACCESS_FILE).empty ()) {
		System_File_True (LOCATION);
		Location_XY_Flag (true);
	}

	Data_Service::Program_Control ();

	Read_Select_Keys ();

	//---- check the file configuration ----

	route_node_flag = System_File_Flag (ROUTE_NODES);
	transit_net_flag = System_File_Flag (TRANSIT_STOP) && System_File_Flag (TRANSIT_ROUTE) &&
		System_File_Flag (TRANSIT_SCHEDULE) && System_File_Flag (TRANSIT_DRIVER);

	if (!route_node_flag && !transit_net_flag) {
		Error ("A Route Nodes or Transit Network is Required");
	}
	new_transit_net_flag = System_File_Flag (NEW_TRANSIT_STOP) && System_File_Flag (NEW_TRANSIT_ROUTE) && 
		System_File_Flag (NEW_TRANSIT_SCHEDULE) && System_File_Flag (NEW_TRANSIT_DRIVER);

	if (route_node_flag && !new_transit_net_flag) {
		Error ("A New Transit Network is Required for Route Nodes");
	}
	access_flag = System_File_Flag (ACCESS_LINK);
	new_access_flag = System_File_Flag (NEW_ACCESS_LINK);

	if (!access_flag && new_access_flag && !transit_net_flag) {
		Error ("A Transit Network is Required for Access Links");
	}

	if ((access_flag || (!access_flag && new_access_flag)) && !System_File_Flag (PARKING)) {
		Error ("A Parking File is Required for Access Links");
	}
	parkride_flag = Check_Control_Key (PARK_AND_RIDE_FILE);	

	if (parkride_flag && (!System_File_Flag (PARKING) || !System_File_Flag (NEW_PARKING))) {
		Error ("Parking Files are Required for Park and Ride Processing");
	}
	new_link_flag = System_File_Flag (NEW_LINK);

	//---- set processing flags ----

	Link_File *link_file = System_Link_File ();

	at_flag = !link_file->Area_Type_Flag () && System_File_Flag (ZONE);

	if (route_node_flag) {
		Route_Nodes_File *nodes_file = System_Route_Nodes_File ();

		dwell_flag = nodes_file->Dwell_Flag ();
		time_flag = nodes_file->Time_Flag ();
		speed_flag = nodes_file->Speed_Flag ();

		//---- get the time periods ----

		num_periods = transit_time_periods.Num_Periods ();

		if (nodes_file->Num_Periods () != num_periods) {
			Error (String ("Transit Time Periods = %d do not match Route Nodes Periods = %d") % num_periods % nodes_file->Num_Periods ());
		}
	}
	
	Print (2, String ("%s Control Keys:") % Program ());

	//---- route data file ----

	key = Get_Control_String (ROUTE_DATA_FILE);

	if (!key.empty ()) {
		route_data_file.File_Type ("Route Data File");
		route_data_flag = true;

		//---- get the file format ----

		if (Check_Control_Key (ROUTE_DATA_FORMAT)) {
			route_data_file.Dbase_Format (Get_Control_String (ROUTE_DATA_FORMAT));
		}
		route_data_file.Open (Project_Filename (key));

		//---- route join field ----

		if (Check_Control_Key (ROUTE_JOIN_FIELD)) {
			key = Get_Control_Text (ROUTE_JOIN_FIELD);

			route_join_field = route_data_file.Required_Field (key);

			Print (0, String (" (Number = %d)") % (route_join_field + 1));
		} else {
			route_data_field = route_data_file.Required_Field (ROUTE_FIELD_NAMES);
		}

		Line_File *file = System_Line_File (true);
		Field_Ptr fld;

		for (i=0; i < route_data_file.Num_Fields (); i++) {
			if (i == route_data_field) continue;

			fld = route_data_file.Field (i);
			if (file->Field_Number (fld->Name ()) >= 0) continue;

			file->Add_Field (fld->Name (), fld->Type (), fld->Size (), fld->Units ());
			route_data_array.Add_Field (fld->Name (), fld->Type (), fld->Size (), fld->Units ());
		}
		file->Write_Header ();
	}

	//---- open the park and ride file ----

	if (parkride_flag) {
		key = Get_Control_String (PARK_AND_RIDE_FILE);

		parkride_file.File_Type ("Park and Ride File");

		parkride_file.Open (Project_Filename (key));
	}

	if (parkride_flag || (!access_flag && new_access_flag)) {

		//---- PNR access distance ----

		PNR_distance = Get_Control_Integer (PNR_ACCESS_DISTANCE);

		//---- get the stop type range ----

		key = Get_Control_Text (PNR_STOP_TYPES);

		if (!key.empty ()) {
			stop_type_flag = true;
			key.Parse (parts, COMMA_DELIMITERS);

			for (str_itr = parts.begin (); str_itr != parts.end (); str_itr++) {
				key = *str_itr;
				key.Range (low_str, high_str);
				low = Stop_Code (low_str);
				high = Stop_Code (high_str);

				for (i = low; i <= high; i++) {
					pnr_stop_flag [i] = true;
				}
			}
		}
		Print (1);
	}

	//---- station access distance ----

	station_distance = Get_Control_Integer (STATION_ACCESS_DISTANCE);

	//---- station transfer distance ----

	transfer_distance = Get_Control_Integer (STATION_TRANSFER_DISTANCE);

	//---- zone stop access file ----

	key = Get_Control_String (ZONE_STOP_ACCESS_FILE);

	if (!key.empty ()) {
		zone_stop_file.File_Type ("Zone Stop Access File");
		zone_stop_flag = true;

		//---- get the file format ----

		if (Check_Control_Key (ZONE_STOP_ACCESS_FORMAT)) {
			zone_stop_file.Dbase_Format (Get_Control_String (ZONE_STOP_ACCESS_FORMAT));
		}
		zone_stop_file.Open (Project_Filename (key));

		zone_fld = zone_stop_file.Required_Field ("ZONE", "TAZ", "ID", "ZONE_NUM");
		stop_fld = zone_stop_file.Required_Field ("STATION", "STOP", "NODE");
	}

	//---- stop fare zone file ----

	key = Get_Control_String (STOP_FARE_ZONE_FILE);

	if (!key.empty ()) {
		stop_zone_file.File_Type ("Stop Fare Zone File");
		stop_zone_flag = true;

		//---- get the file format ----

		if (Check_Control_Key (STOP_FARE_ZONE_FORMAT)) {
			stop_zone_file.Dbase_Format (Get_Control_String (STOP_FARE_ZONE_FORMAT));
		}
		stop_zone_file.Open (Project_Filename (key));

		stop_field = stop_zone_file.Required_Field ("STOP", "STATION", "ID", "TRANSIT");
		zone_field = stop_zone_file.Required_Field ("ZONE", "FARE", "FAREZONE", "FARE_ZONE");
	}

	//---- get the min spacing length ----
	
	Get_Control_List_Groups (STOP_SPACING_BY_AREA_TYPE, min_stop_spacing);

	//---- get the stop facility type range ----

	key = Get_Control_Text (STOP_FACILITY_TYPE_RANGE);

	if (key.empty ()) {
		key = "PRINCIPAL..FRONTAGE";
	}
	key.Parse (parts, COMMA_DELIMITERS);

	for (str_itr = parts.begin (); str_itr != parts.end (); str_itr++) {

		if (!Type_Range (*str_itr, FACILITY_CODE, low, high)) {
			Error (String ("Facility Type Range %s is Illegal") % *str_itr);
		}
		for (i=low; i <= high; i++) {
			facility_flag [i] = true;
		}
	}

	//---- set the time factors ----

	Get_Control_List_Groups (TRANSIT_TRAVEL_TIME_FACTORS, time_factor);

	//---- minimum dwell time ----

	min_dwell = Get_Control_Time (MINIMUM_DWELL_TIME);

	//---- intersection stop type ----

	stop_type = Stop_Code (Get_Control_Text (INTERSECTION_STOP_TYPE));

	//---- intersection stop offset ----

	stop_offset = Round (Get_Control_Double (INTERSECTION_STOP_OFFSET));

	if (stop_type == FARSIDE && stop_offset < Round (Internal_Units (10, METERS))) {
		Warning ("Farside Stops and Stop Offset are Incompatible");
	}

	//---- coordinate schedules -----

	coordinate_flag = Get_Control_Flag (COORDINATE_SCHEDULES);

	//---- ignore path errors -----

	ignore_errors_flag = Get_Control_Flag (IGNORE_PATH_ERRORS);

	//---- add transit connections -----

	add_connections = Get_Control_Flag (ADD_TRANSIT_CONNECTIONS);

	if (add_connections && !System_File_Flag (NEW_CONNECTION)) {
		Error ("A New Connection File is Required for Transit Connections");
	}

	//---- select transit modes ----

	delete_transit_modes = Transit_Range_Key (DELETE_TRANSIT_MODES, delete_transit);

	//---- delete routes ----

	if (Control_Key_Status (DELETE_ROUTES)) {
		key = Get_Control_Text (DELETE_ROUTES);

		if (!key.empty () && !key.Equals ("NONE")) {
			delete_route_flag = true;
			if (!delete_routes.Add_Ranges (key)) {
				Error ("Adding Transit Route Ranges");
			}
		}
	}

	//---- delete stops ----

	if (Control_Key_Status (DELETE_STOPS)) {
		key = Get_Control_Text (DELETE_STOPS);

		if (!key.empty () && !key.Equals ("NONE")) {
			delete_stop_flag = true;
			if (!delete_stops.Add_Ranges (key)) {
				Error ("Adding Transit Stop Ranges");
			}
		}
	}

	//---- delete stop file ----

	if (Control_Key_Status (DELETE_STOP_FILE)) {
		key = Get_Control_Text (DELETE_STOP_FILE);	

		if (!key.empty ()) {
			Db_File file;
			file.File_Type ("Delete Stop File");

			file.Open (Project_Filename (key));

			while (file.Read ()) {
				key = file.Record_String ();
				if (key.empty ()) continue;
				if (key [0] < '0' || key [0] > '9') continue;
				delete_stop_flag = true;
				if (!delete_stops.Add_Ranges (key)) {
					exe->Error ("Adding Transit Stop Ranges");
				}
			}
		}
	}

	//---- add route stops file ----

	key = Get_Control_String (ADD_ROUTE_STOPS_FILE);

	if (!key.empty ()) {
		add_stops_file.File_Type ("Add Route Stops File");
		add_stops_flag = true;

		//---- get the file format ----

		if (Check_Control_Key (ADD_ROUTE_STOPS_FORMAT)) {
			add_stops_file.Dbase_Format (Get_Control_String (ADD_ROUTE_STOPS_FORMAT));
		}
		add_stops_file.Open (Project_Filename (key));

		add_route_field = add_stops_file.Required_Field (ROUTE_FIELD_NAMES);
		add_stop_field = add_stops_file.Required_Field ("STOP", "STOP_ID", "ID");
		add_fare_field = add_stops_file.Optional_Field ("ZONE", "FARE_ZONE", "DISTRICT");
		add_index_field = add_stops_file.Optional_Field ("POSITION", "INDEX", "END");
	}

	//---- new route change file ----

	key = Get_Control_String (NEW_ROUTE_CHANGE_FILE);

	if (!key.empty ()) {
		change_file.File_Type ("New Route Change File");
		change_flag = true;

		//---- get the file format ----

		if (Check_Control_Key (NEW_ROUTE_CHANGE_FORMAT)) {
			change_file.Dbase_Format (Get_Control_String (NEW_ROUTE_CHANGE_FORMAT));
		}
		change_route_fld = change_file.Add_Field ("ROUTE", DB_INTEGER, 10);
		change_mode_fld = change_file.Add_Field ("MODE", DB_STRING, 16, TRANSIT_CODE);
		change_name_fld = change_file.Add_Field ("NAME", DB_STRING, 20);
		change_in_len_fld = change_file.Add_Field ("IN_LENGTH", DB_INTEGER, 10, FEET);
		change_out_len_fld = change_file.Add_Field ("OUT_LENGTH", DB_INTEGER, 10, FEET);
		change_in_stops_fld = change_file.Add_Field ("IN_STOPS", DB_INTEGER, 10);
		change_out_stops_fld = change_file.Add_Field ("OUT_STOPS", DB_INTEGER, 10);

		change_file.Create (Project_Filename (key));
	}

	//---- write the report names ----

	List_Reports ();

	//---- read the zone equiv ----

	equiv_flag = Zone_Equiv_Flag ();

	if (equiv_flag) {
		zone_equiv.Read (Report_Flag (ZONE_EQUIV));
	}
} 

