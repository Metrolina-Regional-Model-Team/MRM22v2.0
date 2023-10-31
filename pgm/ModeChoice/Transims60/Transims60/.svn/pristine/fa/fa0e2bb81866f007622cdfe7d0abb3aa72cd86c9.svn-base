//*********************************************************
//	Select_Skims.cpp - select plan skim records
//*********************************************************

#include "PlanPrep.hpp"

#include "Shape_Tools.hpp"

//---------------------------------------------------------
//	Select_Skims
//---------------------------------------------------------

void PlanPrep::Select_Skims ()
{
	Int_Map_Itr map_itr;
	Select_Map_Itr sel_itr;
	Location_Data *loc_ptr;
	Link_Data *link_ptr;
	Node_Data *node_ptr;

	Show_Message (String ("Selecting %s -- Record") % skim_file->File_Type ());
	Set_Progress ();

	while (skim_file->Read ()) {
		Show_Progress ();

		//---- check the selection criteria ----

		if (select_households && !hhold_range.In_Range (skim_file->Household ())) continue;
		if (skim_file->Mode () < MAX_MODE && !select_mode [skim_file->Mode ()]) continue;
		if (select_purposes && !purpose_range.In_Range (skim_file->Purpose ())) continue;
		if (select_vehicles && !vehicle_range.In_Range (skim_file->Veh_Type ())) continue;
		if (select_travelers && !traveler_range.In_Range (skim_file->Type ())) continue;
		if (select_start_times && !start_range.In_Range (skim_file->Depart ())) continue;
		if (select_end_times && !end_range.In_Range (skim_file->Arrive ())) continue;
		if (select_origins && !org_range.In_Range (skim_file->Origin ())) continue;
		if (select_destinations && !des_range.In_Range (skim_file->Destination ())) continue;
		if (select_parking && !parking_range.In_Range (skim_file->Parking ())) continue;

		if (select_org_zones || select_subareas || select_polygon) {
			map_itr = location_map.find (skim_file->Origin ());
			if (map_itr == location_map.end ()) continue;
			loc_ptr = &location_array [map_itr->second];

			if (select_org_zones && !org_zone_range.In_Range (loc_ptr->Zone ())) continue;

			if (select_subareas || select_polygon) {
				link_ptr = &link_array [loc_ptr->Link ()];

				if (loc_ptr->Dir () == 0) {
					node_ptr = &node_array [link_ptr->Anode ()];
				} else {
					node_ptr = &node_array [link_ptr->Bnode ()];
				}
				if (select_subareas && !subarea_range.In_Range (node_ptr->Subarea ())) continue;
				if (select_polygon && !In_Polygon (polygon_file, UnRound (node_ptr->X ()), UnRound (node_ptr->Y ()))) continue;
			}
		}

		if (select_des_zones) {
			map_itr = location_map.find (skim_file->Destination ());
			if (map_itr == location_map.end ()) continue;
			loc_ptr = &location_array [map_itr->second];
			if (!des_zone_range.In_Range (loc_ptr->Zone ())) continue;
		}

		//---- check the deletion records ----

		if (delete_flag) {
			sel_itr = delete_map.Best (skim_file->Household (), skim_file->Person (), 
				skim_file->Tour (), skim_file->Trip ());
			if (sel_itr != delete_map.end ()) continue;
		}
		if (delete_households && hhold_delete.In_Range (skim_file->Household ())) continue;
		if (skim_file->Mode () < MAX_MODE && delete_mode [skim_file->Mode ()]) continue;
		if (delete_travelers && traveler_delete.In_Range (skim_file->Type ())) continue;

		//---- check the selection records ----

		if (select_flag) {
			sel_itr = select_map.Best (skim_file->Household (), skim_file->Person (), 
				skim_file->Tour (), skim_file->Trip ());
			if (sel_itr == select_map.end ()) continue;
		}

		if (percent_flag && random.Probability () > select_percent) continue;

		plan_skim_file->Put_Data (*skim_file);
		plan_skim_file->Write ();
		num_new_skims++;
	}
	End_Progress ();
	plan_skim_file->Close ();
}
