//*********************************************************
//	Input_Trips.cpp - Read the Trips into Memory
//*********************************************************

#include "Converge_Service.hpp"

//---------------------------------------------------------
//	Input_Trips
//---------------------------------------------------------

bool Converge_Service::Input_Trips (void)
{
	int part, num_rec, part_num, first, num_selected, priority, mode;
	Dtime shift, new_time, duration;

	Trip_File *file = System_Trip_File ();

	Trip_Data trip_rec;
	Trip_Index trip_index;
	Trip_Map_Stat map_stat;
	Plan_Data *plan_ptr, plan_rec;
	Trip_Map_Itr map_itr;

	num_rec = first = num_selected = 0;

	//---- check the partition number ----

	if (file->Part_Flag () && First_Partition () != file->Part_Number ()) {
		file->Open (0);
	} else if (First_Partition () >= 0) {
		first = First_Partition ();
	}

	//---- process each partition ----

	for (part=0; ; part++) {
		if (part > 0) {
			if (!file->Open (part)) break;
		}

		//---- store the trip data ----

		if (file->Part_Flag ()) {
			part_num = file->Part_Number ();
			Show_Message (String ("Reading %s %d -- Record") % file->File_Type () % part_num);
		} else {
			part_num = part + first;
			Show_Message (String ("Reading %s -- Record") % file->File_Type ());
		}
		Set_Progress ();

		while (file->Read ()) {
			Show_Progress ();

			file->Get_Data (trip_rec);

			if (trip_rec.Household () < 1) continue;

			if (trip_rec.Partition () < part_num) trip_rec.Partition (part_num);

			priority = initial_priority;

			if (set_mode_flag) {
				mode = set_mode;
				if (trip_rec.Trip () == 2) {
					if (mode == PNR_OUT_MODE) mode = PNR_IN_MODE;
					if (mode == KNR_OUT_MODE) mode = KNR_IN_MODE;
				}
				trip_rec.Mode (mode);

				if (set_veh_type > 0) {
					trip_rec.Veh_Type (set_veh_type);
					if (trip_rec.Vehicle () == 0) {
						trip_rec.Vehicle (1);
					}
				}
			}
			if (priority_flag) {
				trip_rec.Priority (priority);
			} else if (trip_rec.Priority () == NO_PRIORITY) {
				trip_rec.Priority (MEDIUM);
			} else if (trip_rec.Priority () == SKIP) {
				trip_rec.Priority (NO_PRIORITY);
			}
			if (!Selection (&trip_rec)) {
				if (!plan_flag) continue;

				trip_rec.Priority (SKIP);
				priority = SKIP;
			} else {
				num_selected++;
			}
			if (!trip_rec.Internal_IDs ()) continue;

			trip_rec.Get_Index (trip_index);
			file->Add_Trip (trip_index.Household (), trip_index.Person (), trip_index.Tour ());

		    map_itr = plan_trip_map.find (trip_index);

		    if (map_itr == plan_trip_map.end ()) {
			    plan_rec = trip_rec;

			    plan_rec.Index ((int) plan_array.size ());
				plan_rec.Priority (CRITICAL);
				plan_rec.Depart (trip_rec.Start ());
				plan_rec.Arrive (trip_rec.End ());

			    map_stat = plan_trip_map.insert (Trip_Map_Data (trip_index, plan_rec.Index ()));
				if (!map_stat.second) {
					Warning (String ("Problem Inserting Plan %d-%d-%d-%d") % plan_rec.Household () %
						plan_rec.Person () % plan_rec.Tour () % plan_rec.Trip ());
					continue;
				}
				if (time_order_flag) {
					if (!plan_time_map.insert (Time_Map_Data (plan_rec.Get_Time_Index (), plan_rec.Index ())).second) {
						Error (String ("Time Index Problem Plan %d-%d-%d-%d") % plan_rec.Household () %
							plan_rec.Person () % plan_rec.Tour () % plan_rec.Trip ());
					}
				}
			    plan_array.push_back (plan_rec);
			    plan_array.Max_Partition (plan_rec);
				plan_ptr = &plan_rec;
		    } else {
				plan_ptr = &plan_array [map_itr->second];
				if (plan_ptr->Priority () == NO_PRIORITY) {
					plan_ptr->Priority (MEDIUM);
				}
				if (priority_flag || priority == SKIP) {
					plan_ptr->Priority (priority);
				}
				if (plan_ptr->Constraint () == END_TIME) {
					if (plan_ptr->End () != trip_rec.End ()) {
						shift = plan_ptr->End () - trip_rec.End ();

						plan_ptr->Start (trip_rec.Start ());
						plan_ptr->End (trip_rec.End ());

						duration = plan_ptr->Arrive () - plan_ptr->Depart ();

						new_time = plan_ptr->Arrive () - shift - duration;
						if (new_time < 0) new_time = 0;
						plan_ptr->Depart (new_time);

						new_time = plan_ptr->Arrive () - shift;
						if (new_time < 1) new_time = 1;
						plan_ptr->Arrive (new_time);
					}
				} else {
					if (plan_ptr->Start () != trip_rec.Start ()) {
						shift = plan_ptr->Start () - trip_rec.Start ();

						plan_ptr->Start (trip_rec.Start ());
						plan_ptr->End (trip_rec.End ());

						duration = plan_ptr->Arrive () - plan_ptr->Depart ();

						new_time = plan_ptr->Depart () - shift;
						if (new_time < 0) new_time = 0;

						plan_ptr->Depart (new_time);
						plan_ptr->Arrive (new_time + duration);
					}
				}
			}
			counters.total_records++;
			if (select_priorities && select_priority [plan_ptr->Priority ()]) {
				counters.select_records++;
				counters.select_weight += plan_ptr->Priority ();
			}
		}
		End_Progress ();
		num_rec += Progress_Count ();
	}
	file->Close ();

	Print (2, String ("Number of %s Records = %d") % file->File_Type () % num_rec);
	if (part > 1) Print (0, String (" (%d files)") % part);

	if (num_selected < num_rec) {
		Write (1, "Number of Selected Trips = ") << num_selected;
		if (num_rec > 0) {
			Write (0, String (" (%.1lf%%)") % (100.0 * num_selected / num_rec) % FINISH);
			Show_Message (1);
		}
	}
	return (num_selected > 0);
}
