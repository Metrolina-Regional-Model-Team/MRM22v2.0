//*********************************************************
//	Read_Plan_Skims.cpp - read the plan skim file
//*********************************************************

#include "ModeChoice.hpp"

//---------------------------------------------------------
//	Read_Plan_Skims
//---------------------------------------------------------

void ModeChoice::Read_Plan_Skims (void)
{
	int i, num;
	bool park_flag;

	Trip_Index trip_index, min_index;
	Trip_Index_Array read_index;
	Trip_Index_Itr index_itr;
	Plan_Skim_File_Itr skim_itr;
	Plan_Skim_Data_Itr data_itr;

	memory_flag = false;
	park_flag = ((System_File_Flag (NEW_PARK_DEMAND) && save_flag) || penalty_update_flag);

	if (calib_flag) {
		if (save_flag && new_skim_flag) {
			Show_Message (String ("Iteration %d Writing Plan Skims -- Record") % iteration);
		} else {
			Show_Message (String ("Iteration %d Reading Plan Skims -- Record") % iteration);
		}
		if (iteration > 1) {
			if (skim_memory_flag) {
				memory_flag = true;
				for (data_itr = plan_skim_arrays.begin (); data_itr != plan_skim_arrays.end (); data_itr++) {
					(*data_itr)->Rewind ();
				}
			} else {
				for (skim_itr = plan_skim_files.begin (); skim_itr != plan_skim_files.end (); skim_itr++) {
					(*skim_itr)->Rewind ();
				}
			}
		}
		//---- clear the parking demand ----

		if (penalty_update_flag) {
			park_demand_array.Zero_Demand ();
		}
	} else {
		Show_Message ("Reading Plan Skim Files -- Record");
	}
	Set_Progress ();

	//---- process each trip ----

	i = (int) plan_skims.size ();
	index_array.assign (i, trip_index);
	read_index.assign (i, trip_index);
	
	while (trip_index.Household () < MAX_INTEGER) {
		Show_Progress ();

		//---- read the next ----

		min_index.Household (MAX_INTEGER);

		for (i = 0, index_itr = index_array.begin (); index_itr != index_array.end (); index_itr++, i++) {
			if (*index_itr <= trip_index) {
				if (memory_flag) {
					if (plan_skim_arrays [i]->Read_Record ()) {
						plan_skim_arrays [i]->Get_Index (*index_itr);
						index_skims [i]->Record (plan_skim_arrays [i]->Record ());
					} else {
						(*index_itr).Household (MAX_INTEGER);
					}
				} else {
					if (read_index [i].Household () == 0) {
						if (plan_skim_files [i]->Read_Record ()) {
							plan_skim_files [i]->Get_Index (read_index [i]);
						} else {
							read_index [i].Household (MAX_INTEGER);
						}
					}
					*index_itr = read_index [i];
					if (read_index [i].Household () == MAX_INTEGER) continue;

					index_skims [i]->Put_Data (*(plan_skim_files [i]));

					if (plan_skim_files [i]->Read_Record ()) {
						plan_skim_files [i]->Get_Index (read_index [i]);

						if (tour_choice_flag) {
							while (read_index [i].Household () < MAX_INTEGER) {
								if (read_index [i].Household () != index_itr->Household () || read_index [i].Person () != index_itr->Person () ||
									read_index [i].Tour () != index_itr->Tour ()) {
									break;
								}
								index_skims [i]->Add_Leg (*(plan_skim_files [i]));

								if (plan_skim_files [i]->Read_Record ()) {
									plan_skim_files [i]->Get_Index (read_index [i]);
								} else {
									read_index [i].Household (MAX_INTEGER);
								}
							}
						}
					} else {
						read_index [i].Household (MAX_INTEGER);
					}
					if (skim_memory_flag) {
						plan_skim_arrays [i]->Record (index_skims [i]->Record ());
						plan_skim_arrays [i]->Add_Record ();
					}
				}
			}
			if (*index_itr < min_index) {
				min_index = *index_itr;
			}
		}
		if (min_index.Household () == MAX_INTEGER) break;

		trip_index = min_index;

		//---- mode choice ----

		num = Choice_Data (trip_index);

		//---- save the parking demand ----

		if (num >= 0 && park_flag) {
			Plan_Skim_File_Ptr skim_ptr = plan_skims [num];

			if (skim_ptr->Parking () > 0) {
				int mode = skim_ptr->Mode ();
				if (mode == PNR_OUT_MODE) {
				//if (mode == PNR_OUT_MODE || mode == DRIVE_MODE || mode == HOV2_MODE || mode == HOV3_MODE || mode == HOV4_MODE) {
					Int_Map_Itr itr = parking_map.find (skim_ptr->Parking ());

					if (itr != parking_map.end ()) {
						Dtime ttime, tod, duration;
						ttime = skim_ptr->Transit () + skim_ptr->Wait () + skim_ptr->Walk ();
						duration = ttime + skim_ptr->Activity ();

						if (skim_ptr->Num_Legs () > 1) {
							tod = skim_ptr->Arrive () - ttime / 2;
						} else {
							tod = skim_ptr->Arrive () - ttime;
						}
						if (park_demand_array.Check_Parking_Type (itr->second)) {
							park_demand_array.Parking_Duration (itr->second, tod, duration);
						}
					}
				}
			}
		}
	}
	if (!calib_flag) End_Progress ();
}
