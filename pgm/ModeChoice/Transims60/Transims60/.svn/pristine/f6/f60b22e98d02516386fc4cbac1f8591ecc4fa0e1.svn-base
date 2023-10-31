//*********************************************************
//	Read_Plan_Skims.cpp - Read the Plan Skim File
//*********************************************************

#include "ArcPlan.hpp"

//---------------------------------------------------------
//	Get_Plan_Skim_Data
//---------------------------------------------------------

bool ArcPlan::Get_Plan_Skim_Data (Plan_Skim_File &file, Plan_Skim_Data &data)
{
	int index;
	Location_Data *loc_ptr;
	XYZ_Point point;
	Point_Map_Itr pt_itr;

	if (Data_Service::Get_Plan_Skim_Data (file, data)) {

		if (select_households && !hhold_range.In_Range (data.Household ())) return (false);
		if (data.Mode () < MAX_MODE && !select_mode [data.Mode ()]) return (false);
		if (select_purposes && !purpose_range.In_Range (data.Purpose ())) return (false);
		if (select_start_times && !start_range.In_Range (data.Start ())) return (false);
		if (select_end_times && !end_range.In_Range (data.End ())) return (false);
		if (select_origins && !org_range.In_Range (file.Origin ())) return (false);
		if (select_destinations && !des_range.In_Range (file.Destination ())) return (false);
		if (select_parking && !parking_range.In_Range (file.Parking ())) return (false);

		if (select_org_zones) {
			loc_ptr = &location_array [data.Origin ()];
			if (!org_zone_range.In_Range (loc_ptr->Zone ())) return (false);
		}
		if (select_des_zones) {
			loc_ptr = &location_array [data.Destination ()];
			if (!des_zone_range.In_Range (loc_ptr->Zone ())) return (false);
		}
		if (select_travelers && !traveler_range.In_Range (data.Type ())) return (false);

		//---- check the selection records ----

		if (System_File_Flag (SELECTION)) {
			Select_Map_Itr sel_itr;

			sel_itr = select_map.Best (data.Household (), data.Person (), data.Tour (), data.Trip ());
			if (sel_itr == select_map.end ()) return (false);
		}

		//---- draw the drive access record ----

		if (drive_access_flag) {
			arcview_drive_access.clear ();
			arcview_drive_access.Copy_Fields (file);

			loc_ptr = &location_array [data.Origin ()];
			point.x = UnRound (loc_ptr->X ());
			point.y = UnRound (loc_ptr->Y ());

			arcview_drive_access.push_back (point);

			pt_itr = parking_pt.find (file.Parking ());
			if (pt_itr == parking_pt.end ()) return (false);

			arcview_drive_access.assign (1, pt_itr->second);

			loc_ptr = &location_array [data.Destination ()];
			point.x = UnRound (loc_ptr->X ());
			point.y = UnRound (loc_ptr->Y ());

			arcview_drive_access.push_back (point);

			if (!arcview_drive_access.Write_Record ()) {
				Error (String ("Writing %s") % arcview_drive_access.File_Type ());
			}
			num_drive_access++;
		}

		//---- summarize location productions and attractions ----

		if (location_flag) {
			index = data.Origin ();
			loc_ptr = &location_array [index];

			if (data.Trip () > 1) {
				attractions [index]++;
			} else {
				productions [index]++;
			}
			index = data.Destination ();
			loc_ptr = &location_array [index];

			if (data.Trip () > 1) {
				productions [index]++;
			} else {
				attractions [index]++;
			}
		}

		//---- summarize parking demand data ----

		if (parking_flag && data.Parking () >= 0) {
			index = data.Parking ();

			if (data.Mode () == PNR_IN_MODE || data.Mode () == KNR_IN_MODE) {
				parking_out [index]++;
			} else {
				parking_in [index]++;
			}
		}
	}
	return (false);
}
