//*********************************************************
//	Update_Schedules.cpp - update transit schedules
//*********************************************************

#include "Reschedule.hpp"

//---------------------------------------------------------
//	Update_Schedules
//---------------------------------------------------------

void Reschedule::Update_Schedules (void)
{
	int run, runs, offset, num_stops, index;
	double len_fac, diff;
	Dtime time, time0, time1, sum0, sum1, start, old_tod, new_tod, last_tod, min_time;
	bool first;
	
	Line_Itr line_itr;
	Line_Stop_Itr stop_itr, first_itr;
	Line_Run *run_ptr;
	Driver_Itr driver_itr;
	Stop_Data *stop_ptr;
	Dir_Data *dir_ptr;
	Link_Data *link_ptr;
	Perf_Period *perf0_ptr, *perf1_ptr;

	//---- process each transit route ----

	for (line_itr = line_array.begin (); line_itr != line_array.end (); line_itr++) {
		Show_Progress ();
		
		if (select_transit_modes && !select_transit [line_itr->Mode ()]) continue;
		if (select_routes && !route_range.In_Range (line_itr->Route ())) continue;

		first_itr = line_itr->begin ();
		if (first_itr == line_itr->end ()) continue;

		runs = (int) first_itr->size ();

		//---- update the schedules for each run ----

		for (run=0; run < runs; run++) {
			start = old_tod = new_tod = last_tod = first_itr->at (run).Schedule ();

			sum0 = sum1 = 0;
			first = true;
			offset = 0;
			num_stops = 0;
			stop_itr = line_itr->begin ();

			//---- find travel time changes for links along the route ----

			for (driver_itr = line_itr->driver_array.begin (); driver_itr != line_itr->driver_array.end (); driver_itr++) {
				dir_ptr = &dir_array [*driver_itr];
				link_ptr = &link_array [dir_ptr->Link ()];

				offset = 0;
				index = *driver_itr;

				if (dir_ptr->Use_Index () >= 0) {
					index = dir_ptr->Use_Index ();
				}
				time0 = time1 = min_time = dir_ptr->Time0 ();

				perf0_ptr = perf_period_array.Period_Ptr (old_tod);
				if (perf0_ptr != 0) {
					time0 = perf0_ptr->Time (index);
					if (time0 < min_time) time0 = min_time;
				}
				perf1_ptr = update_array.Period_Ptr (new_tod);
				if (perf1_ptr != 0) {
					time1 = perf1_ptr->Time (index);
					if (time1 < min_time) time1 = min_time;
				}

				for (; stop_itr != line_itr->end (); stop_itr++) {
					stop_ptr = &stop_array [stop_itr->Stop ()];

					if (stop_ptr->Link_Dir () != dir_ptr->Link_Dir ()) break;

					if (!first) {
						len_fac = (double) (stop_ptr->Offset () - offset) / link_ptr->Length ();

						sum0 += (int) (time0 * len_fac);
						sum1 += (int) (time1 * len_fac);

						run_ptr = &stop_itr->at (run);

						old_tod = run_ptr->Schedule ();

						diff = old_tod - last_tod;
						last_tod = old_tod;

						if (sum0 > 0) {
							if (sum1 > sum0 * 4) {
								diff *= 4.0;
							} else {
								diff = diff * sum1 / sum0;
							}
						}
						new_tod = (int) (new_tod + diff);
						if (new_tod >= Model_End_Time ()) {
							new_tod = Model_End_Time () - 1;
						}
						run_ptr->Schedule (new_tod.Round_Seconds ());
						sum0 = sum1 = 0;
					} else {
						first = false;
					}
					offset = stop_ptr->Offset ();
					num_stops++;
				}
				if (stop_itr == line_itr->end ()) break;
				if (first) continue;

				len_fac = (double) (link_ptr->Length () - offset) / link_ptr->Length ();
						
				sum0 += (int) (time0 * len_fac);
				sum1 += (int) (time1 * len_fac);
			}
			Run_Summary (line_itr->Mode (), line_itr->Route (), run, start, old_tod, new_tod);
		}
		if (change_flag) {
			change_array.push_back (run_change);
		}
	}
	if (file_flag) {
		change_file.Close ();
	}
}
