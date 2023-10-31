//*********************************************************
//	Choice_Data.cpp - prepare mode split data
//*********************************************************

#include "ModeChoice.hpp"

//---------------------------------------------------------
//	Choice_Data
//---------------------------------------------------------

int ModeChoice::Choice_Data (Trip_Index trip_index)
{
	int i, num, org, des, o1, d1, org_seg, des_seg, segment, seg;
	bool first;

	Trip_Index_Itr index_itr;
	Plan_Skim_Itr skim_itr;
	Plan_Skim_Data_Itr data_itr;
	Plan_Skim_File_Ptr skim_ptr;
	Location_Data *loc_ptr;
	Zone_Data *zone_ptr;
	Int_Map_Itr map_itr;
	Int2_Map_Itr map2_itr;

	//---- set the plan skim records ----

	first = true;

	for (i = 0, index_itr = index_array.begin (); index_itr != index_array.end (); index_itr++, i++) {
		if (*index_itr == trip_index) {
			plan_skims [i]->Record (index_skims [i]->Record ());
			if (first) {
				first = false;
				trip_file.Copy_Fields (*(plan_skims [i]));
			}
			if (park_demand_flag) {
				skim_ptr = plan_skims [i];

				if (skim_ptr->Parking () > 0) {
					int mode = skim_ptr->Mode ();
					//if (mode == PNR_OUT_MODE || mode == DRIVE_MODE || mode == HOV2_MODE || mode == HOV3_MODE || mode == HOV4_MODE) {
					if (mode == PNR_OUT_MODE) {
						Int_Map_Itr itr = parking_map.find (skim_ptr->Parking ());

						if (itr != parking_map.end ()) {
							Dtime tod = skim_ptr->Transit () + skim_ptr->Wait () + skim_ptr->Walk ();
							if (skim_ptr->Num_Legs () > 1) {
								tod = skim_ptr->Arrive () - tod / 2;
							} else {
								tod = skim_ptr->Arrive () - tod;
							}
							int penalty = park_demand_array.Penalty (itr->second, tod);
							if (penalty >= MAX_PENALTY) {
								skim_ptr->Zero_Data ();
							} else if (penalty > 0) {
								skim_ptr->Impedance (skim_ptr->Impedance () + Resolve (penalty));
							}
						}
					}
				}
			}
		} else {
			plan_skims [i]->Zero_Data ();
		}
	}
	seg = segment = 0;

	//---- get the origin zone data ----

	org = trip_file.Origin ();

	map_itr = location_map.find (org);

	if (map_itr == location_map.end ()) {
		Warning (String ("Origin Location %d was Not Found") % org);
		return (-1);
	}
	loc_ptr = &location_array [map_itr->second];

	if (loc_ptr->Zone () < 0) {
		Warning (String ("Origin Location %d is not in a Zone") % org);
		return (-1);
	}
	o1 = loc_ptr->Zone ();

	zone_ptr = &zone_array [o1];

	org = zone_ptr->Zone ();

	if (select_org_zones && !org_zone_range.In_Range (org)) return (-1);

	org_db.Read_Record (org);

	if (org_map_field >= 0) {
		org_seg = org_db.Get_Integer (org_map_field);
	}

	//---- get the destination zone data ----

	des = trip_file.Destination ();

	map_itr = location_map.find (des);

	if (map_itr == location_map.end ()) {
		Warning (String ("Destination Location %d was Not Found") % des);
		return (-1);
	}
	loc_ptr = &location_array [map_itr->second];

	if (loc_ptr->Zone () < 0) {
		Warning (String ("Destination Location %d is not in a Zone") % des);
		return (-1);
	}
	d1 = loc_ptr->Zone ();
	zone_ptr = &zone_array [d1];

	des = zone_ptr->Zone ();

	if (select_des_zones && !des_zone_range.In_Range (des)) return (-1);

	des_db.Read_Record (des);

	if (segment_flag && des_map_field >= 0) {
		des_seg = des_db.Get_Integer (des_map_field);

		map2_itr = segment_map.find (Int2_Key (org_seg, des_seg));

		if (map2_itr != segment_map.end ()) {
			seg = segment = map2_itr->second;

			if (initial_flag && !calib_seg_flag) {
				seg = 0;
			}
		} else {
			seg = segment = 0;
		}
		trip_file.Put_Field (segment_field, segment);
	}
	trip_file.Put_Field (model_field, 1);

	//---- mode choice ----

	num = Mode_Splits (0, segment, seg, o1, d1, org, des);

	//---- save the plan ----

	if (save_flag && num > 0 && (new_plan_flag || new_skim_flag)) {
		map_itr = plan_num_map.find (num);

		if (map_itr == plan_num_map.end ()) {
			Warning (String ("Plan Number %d was Not Provided") % num);
			return (-1);
		}
		num = map_itr->second;

		if (new_skim_flag) {
			new_plan_skim->Put_Data (*(plan_skims [num]));
			if (!new_plan_skim->Write ()) {
				Error ("Writing New Plan Skim File");
			}
		}
	} else {
		num = -1;
	}
	return (num);
}
