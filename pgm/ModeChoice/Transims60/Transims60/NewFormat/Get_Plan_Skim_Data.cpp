//*********************************************************
//	Get_Plan_Skim_Data - Read the Plan Skim File
//*********************************************************

#include "NewFormat.hpp"

//---------------------------------------------------------
//	Get_Plan_Skim_Data
//---------------------------------------------------------

bool NewFormat::Get_Plan_Skim_Data (Plan_Skim_File &file, Plan_Skim_Data &data)
{
	if (select_households && !hhold_range.In_Range (file.Household ())) return (false);
	int mode = file.Mode ();
	if (mode >= 0 && mode < MAX_MODE && !select_mode [mode]) return (false);
	if (select_purposes && !purpose_range.In_Range (file.Purpose ())) return (false);
	if (select_vehicles && !vehicle_range.In_Range (file.Veh_Type ())) return (false);
	if (select_travelers && !traveler_range.In_Range (file.Type ())) return (false);
	if (select_priorities || !select_priority [file.Priority ()]) return (false);
	if (select_start_times && !start_range.In_Range (file.Depart ())) return (false);
	if (select_end_times && !end_range.In_Range (file.Arrive ())) return (false);
	if (select_origins && !org_range.In_Range (file.Origin ())) return (false);
	if (select_destinations && !des_range.In_Range (file.Destination ())) return (false);
	if (select_parking && !parking_range.In_Range (file.Parking ())) return (false);

	if (select_org_zones) {
		Int_Map_Itr map_itr = location_map.find (file.Origin ());
		if (map_itr != location_map.end ()) {
			Location_Data *loc_ptr = &location_array [map_itr->second];
			if (!org_zone_range.In_Range (loc_ptr->Zone ())) return (false);
		}
	}
	if (select_des_zones) {
		Int_Map_Itr map_itr = location_map.find (file.Destination ());
		if (map_itr != location_map.end ()) {
			Location_Data *loc_ptr = &location_array [map_itr->second];
			if (!des_zone_range.In_Range (loc_ptr->Zone ())) return (false);
		}
	}
	return (Data_Service::Get_Plan_Skim_Data (file, data));
}
