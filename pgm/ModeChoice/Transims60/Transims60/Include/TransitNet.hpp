//*********************************************************
//	TransitNet.hpp - Transit Conversion Utility
//*********************************************************

//bool select_transit [ANY_TRANSIT], select_transit_modes;
//bool select_stops, select_routes,
//Data_Range vehicle_range, stop_range, route_range;

#ifndef TRANSITNET_HPP
#define TRANSITNET_HPP

#include "Data_Service.hpp"
#include "Select_Service.hpp"
#include "Db_Array.hpp"
#include "Db_Header.hpp"
#include "Time_Periods.hpp"
#include "Best_List.hpp"
#include "TypeDefs.hpp"

#include "Node_Path_Data.hpp"

//#define MIN_LENGTH		37.5
//#define MAX_AREA_TYPE	16

//---------------------------------------------------------
//	TransitNet - execution class definition
//---------------------------------------------------------

class SYSLIB_API TransitNet : public Data_Service, public Select_Service
{
public:
	TransitNet (void);

	virtual void Execute (void);

protected:
	enum TransimsNet_Keys { 
		ROUTE_DATA_FILE = 1, ROUTE_DATA_FORMAT, ROUTE_JOIN_FIELD,
		PARK_AND_RIDE_FILE, PNR_ACCESS_DISTANCE, PNR_STOP_TYPES, 
		STATION_ACCESS_DISTANCE, STATION_TRANSFER_DISTANCE, 
		ZONE_STOP_ACCESS_FILE, ZONE_STOP_ACCESS_FORMAT,
		STOP_FARE_ZONE_FILE, STOP_FARE_ZONE_FORMAT, 
		STOP_SPACING_BY_AREA_TYPE, STOP_FACILITY_TYPE_RANGE,
		TRANSIT_TRAVEL_TIME_FACTORS, MINIMUM_DWELL_TIME,
		INTERSECTION_STOP_TYPE, INTERSECTION_STOP_OFFSET, COORDINATE_SCHEDULES,
		IGNORE_PATH_ERRORS, ADD_TRANSIT_CONNECTIONS, 
		DELETE_TRANSIT_MODES, DELETE_ROUTES, DELETE_STOPS, DELETE_STOP_FILE,
		ADD_ROUTE_STOPS_FILE, ADD_ROUTE_STOPS_FORMAT,
		NEW_ROUTE_CHANGE_FILE, NEW_ROUTE_CHANGE_FORMAT,
	};
	virtual void Program_Control (void);
	virtual int  Put_Line_Data (Line_File &file, Line_Data &data);

	virtual bool Get_Parking_Data (Parking_File &file, Parking_Data &data);
	virtual bool Get_Stop_Data (Stop_File &file, Stop_Data &data);
	virtual bool Get_Line_Data (Line_File &file, Line_Data &data);
	virtual bool Get_Schedule_Data (Schedule_File &file, Schedule_Data &data);
	virtual bool Get_Driver_Data (Driver_File &file, Driver_Data &data);

private:
	enum TransitNet_Reports {ZONE_EQUIV = 1};

	bool route_node_flag, transit_net_flag, new_transit_net_flag, add_connections, stop_zone_flag;
	bool route_data_flag, parkride_flag, equiv_flag, coordinate_flag, ignore_errors_flag;
	bool dwell_flag, time_flag, speed_flag, at_flag, access_flag, new_access_flag, new_link_flag, change_flag;
	bool facility_flag [EXTERNAL + 1], pnr_stop_flag [EXTLOAD + 1], stop_type_flag, zone_stop_flag;
	bool delete_transit_modes, delete_transit [ANY_TRANSIT], delete_route_flag, delete_stop_flag, add_stops_flag;

	int naccess, nlocation, nparking, line_edit, route_edit, schedule_edit, driver_edit;
	int nstop, nroute, nschedule, ndriver, end_warnings, parking_warnings, max_link;
	int max_parking, max_access, max_location, max_stop, nparkride, new_access, new_stop;
	int min_dwell, num_periods, stop_type, left_turn, bus_code, rail_code, stop_offset, add_route_field, add_stop_field, add_fare_field, add_index_field;
	int route_data_field, route_join_field, PNR_distance, station_distance, transfer_distance, stop_field, zone_field, zone_fld, stop_fld;
	int change_route_fld, change_mode_fld, change_name_fld, change_in_len_fld, change_out_len_fld, change_in_stops_fld, change_out_stops_fld;

	Double_List min_stop_spacing, time_factor;
	Data_Range delete_stops, delete_routes;

	Db_Header route_data_file, parkride_file, change_file, stop_zone_file, zone_stop_file, add_stops_file;
	Db_Sort_Array route_data_array;

	Node_Path_Array node_path_array;
	Path_Leg_Array path_leg_array;

	Int2_Set park_loc_set;

	Point_Map stop_pt;
	Integers node_list, dir_list, local_access, fare_zone;

	Int_Map stop_zone_map;
	vector <Int_Map> dir_stop_array;

	Str_ID join_map;

	//---- methods ----

	void Update_Fare_Zones (void);
	void Zone_Access (void);
	void Read_Stop_Zone (void);
	void Read_Route_Data (void);
	void Data_Setup (void);
	void Add_Link (int anode, int bnode);
	void Read_ParkRide (void);
	void Node_Path (int node1, int node2, Use_Type use, int index = -1);
	void Build_Routes (void);
	void Coordinate_Schedules (void);
	void Parking_Access (void);
	void Station_Access (void);
	void Add_Route_Stops (void);
};
#endif