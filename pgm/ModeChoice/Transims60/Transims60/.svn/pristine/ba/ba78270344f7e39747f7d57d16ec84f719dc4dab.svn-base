//*********************************************************
//	Write_Link_Loads - write the link load summary
//*********************************************************

#include "RiderSum.hpp"

//---------------------------------------------------------
//	Write_Link_Loads
//---------------------------------------------------------

void RiderSum::Write_Link_Loads (void)
{
	int i, index, dir, count, last_index;
	int run, num_periods, capacity, board, alight, riders;
	Dtime low, high;

	Stop_Data *stop_ptr;
	Dir_Data *dir_ptr;
	Link_Data *link_ptr;

	Int_Map_Itr itr;
	Line_Itr line_itr;
	Line_Stop_Itr stop_itr, prev_itr;
	Line_Run_Itr run_itr;
	Veh_Type_Data *veh_type_ptr, *run_type_ptr;
	Driver_Itr driver_itr;

	Perf_Period_Itr perf_period_itr;
	Perf_Period *period_ptr;
	Perf_Data *data_ptr;

	Performance_File *file = System_Performance_File (true);

	if (perf_period_array.size () == 0) {
		if (sum_periods.Num_Periods () > 0) {
			perf_period_array.Initialize (&sum_periods);
		} else {
			perf_period_array.Initialize (&time_periods);
		}
	}
	num_periods = perf_period_array.periods->Num_Periods ();

	Show_Message ("Building Link Loads -- Record");
	Set_Progress ();

	//---- process each route ----

	for (line_itr = line_array.begin (); line_itr != line_array.end (); line_itr++) {
		Show_Progress ();

		if (select_routes && !route_range.In_Range (line_itr->Route ())) continue;
		if (select_transit_modes && !select_transit [line_itr->Mode ()]) continue;
		if (select_vehicles && !vehicle_range.In_Range (veh_type_array [line_itr->Type ()].Type ())) continue;
		
		veh_type_ptr = &veh_type_array [line_itr->Type ()];

		driver_itr = line_itr->driver_array.begin ();
		if (driver_itr == line_itr->driver_array.end ()) continue;
		last_index = -1;
		board = alight = riders = 0;
		dir_ptr = 0;

		prev_itr = line_itr->end ();

		for (stop_itr = line_itr->begin (); stop_itr != line_itr->end (); prev_itr = stop_itr++) {
			stop_ptr = &stop_array [stop_itr->Stop ()];

			for (; driver_itr != line_itr->driver_array.end (); driver_itr++) {
				if (*driver_itr != last_index) {
					dir_ptr = &dir_array [*driver_itr];
					last_index = *driver_itr;

					for (run = 0, run_itr = stop_itr->begin (); run_itr != stop_itr->end (); run_itr++, run++) {
						period_ptr = perf_period_array.Period_Ptr (run_itr->Schedule ());
						if (period_ptr == 0) continue;

						data_ptr = period_ptr->Data_Ptr (last_index);

						if (prev_itr == line_itr->end ()) {
							riders = run_itr->Load ();
						} else {
							riders = prev_itr->at (run).Load ();
						}

						if (line_itr->run_types.size () > 0) {
							run_type_ptr = &veh_type_array [line_itr->Run_Type (run)];
							capacity = run_type_ptr->Capacity ();
						} else {
							capacity = veh_type_ptr->Capacity ();
						}
						data_ptr->Add_Persons (riders);
						data_ptr->Add_Volume (capacity);
						data_ptr->Add_Stop_Count (1);

						if (stop_ptr->Link_Dir () == dir_ptr->Link_Dir ()) {
							data_ptr->Add_Enter (run_itr->Board ());
							data_ptr->Add_Exit (run_itr->Alight ());
						}
					}
				} else if (stop_ptr->Link_Dir () == dir_ptr->Link_Dir ()) {
					for (run = 0, run_itr = stop_itr->begin (); run_itr != stop_itr->end (); run_itr++, run++) {
						period_ptr = perf_period_array.Period_Ptr (run_itr->Schedule ());
						if (period_ptr == 0) continue;

						data_ptr = period_ptr->Data_Ptr (last_index);
						data_ptr->Add_Enter (run_itr->Board ());
						data_ptr->Add_Exit (run_itr->Alight ());
					}
				}
				if (stop_ptr->Link_Dir () == dir_ptr->Link_Dir ()) break;
			}
			if (driver_itr == line_itr->driver_array.end ()) {
				Warning (String ("Route %d Stop %d and Driver Links are Incompatible") % line_itr->Route () % stop_ptr->Stop ());
			}
		}
	}
	End_Progress ();

	//---- write the performance data ----

	Show_Message (String ("Writing %s -- Record") % file->File_Type ());
	Set_Progress ();

	//---- process each time period ----

	file->Time (0);
	file->Speed (0);
	file->Delay (0);
	file->Density (0);
	file->Max_Density (0);
	file->Queue (0);
	file->Max_Queue (0);
	file->Failure (0);
	file->Veh_Dist (0);
	file->Veh_Time (0);
	file->Veh_Delay (0);
	count = 0;

	for (i = 0, perf_period_itr = perf_period_array.begin (); perf_period_itr != perf_period_array.end (); perf_period_itr++, i++) {

		perf_period_array.periods->Period_Range (i, low, high);

		file->Start (low);
		file->End (high);

		//---- sort the links ----

		for (itr = link_map.begin (); itr != link_map.end (); itr++) {
			link_ptr = &link_array [itr->second];

			file->Link (link_ptr->Link ());

			for (dir = 0; dir < 2; dir++) {
				index = (dir) ? link_ptr->BA_Dir () : link_ptr->AB_Dir ();
				if (index < 0 || index >= (int) perf_period_itr->size ()) continue;

				Show_Progress ();

				data_ptr = perf_period_itr->Data_Ptr (index);
				if (!data_ptr->Output_Check ()) continue;

				dir_ptr = &dir_array [index];

				if (data_ptr->Volume () < 1.0) continue;

				file->Dir (dir);

				file->Persons (data_ptr->Persons ());
				file->Volume (data_ptr->Volume ());
				file->Enter (data_ptr->Enter ());
				file->Exit (data_ptr->Exit ());
				file->Flow (data_ptr->Stop_Count ());
				file->Time_Ratio (100.0 * data_ptr->Persons () / data_ptr->Volume ());

				if (!file->Write ()) {
					Error (String ("Writing %s") % file->File_Type ());
				}
				count++;
			}
		}
	}
	End_Progress ();
	Print (2, String ("%s Records = %d") % file->File_Type () % count);

	file->Close ();
}
