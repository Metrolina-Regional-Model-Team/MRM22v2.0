//*********************************************************
//	Write_Load_Summaryt - write the line rider summary
//*********************************************************

#include "RiderSum.hpp"

//---------------------------------------------------------
//	Write_Load_Summary
//---------------------------------------------------------

void RiderSum::Write_Load_Summary (void)
{
	int riders, board, alight, run, runs, num, length, tot_len, period, num_periods, total, capacity;
	double factor, sum_time, tot_time, time, capfac, duration, delay, crowding, hour_fac, len, len_fac;
	double tot_dur [ANY_TRANSIT], tot_delay [ANY_TRANSIT], tot_crowd [ANY_TRANSIT];
	int tot_board [ANY_TRANSIT];
	Dtime low, high;

	Int_Map_Itr map_itr;
	Line_Data *line_ptr;
	Stop_Data *stop_ptr;
	Line_Stop_Itr stop_itr, next_itr;
	Line_Run_Itr run_itr;
	Veh_Type_Data *veh_type_ptr, *run_type_ptr;

	fstream &file = load_summary_file.File ();
	
	num_periods = sum_periods.Num_Periods ();
	if (num_periods == 0) num_periods = 1;

	len_fac = (Metric_Flag ()) ? 1000.0 : 5280.0;

	memset (tot_dur, '\0', sizeof (tot_dur));
	memset (tot_delay, '\0', sizeof (tot_delay));
	memset (tot_crowd, '\0', sizeof (tot_crowd));
	memset (tot_board, '\0', sizeof (tot_board));

	Show_Message (String ("Writing % -- Record") % load_summary_file.File_Type ());
	Set_Progress ();

	file << "Route\tMode\tType\tPeriod\tLength\tTTime\tAlight\tBoard\tRiders\tRuns\tLoadFac\tCapacity\tCapFac\tDuration\tDelay\tCrowding\tRouteName\n";

	//---- process each route ----

	for (map_itr = line_map.begin (); map_itr != line_map.end (); map_itr++) {
		Show_Progress ();

		if (select_routes && !route_range.In_Range (map_itr->first)) continue;

		line_ptr = &line_array [map_itr->second];

		if (select_transit_modes && !select_transit [line_ptr->Mode ()]) continue;
		if (select_vehicles && !vehicle_range.In_Range (veh_type_array [line_ptr->Type ()].Type ())) continue;

		//---- check the link criteria ----

		if (!Link_Selection (line_ptr)) continue;

		//---- set the run flags ----

		if (!Run_Selection (line_ptr)) continue;

		//---- save the route ridership data ----
			
		veh_type_ptr = &veh_type_array [line_ptr->Type ()];

		for (period = 0; period < num_periods; period++) {
			if (period_flag [period] == 0) continue;

			time = tot_time = 0.0;
			total = length = tot_len = 0;

			sum_periods.Period_Range (period, low, high);

			hour_fac = Dtime (high - low).Hours ();

			for (stop_itr = line_ptr->begin (); stop_itr != line_ptr->end (); stop_itr++) {
				riders = board = alight = runs = capacity = 0;

				stop_ptr = &stop_array [stop_itr->Stop ()];

				next_itr = stop_itr + 1;

				if (next_itr != line_ptr->end ()) {
					length = next_itr->Length () - stop_itr->Length ();
				} else {
					length = 0;
				}
				sum_time = 0.0;
				num = 0;

				for (run = 0, run_itr = stop_itr->begin (); run_itr != stop_itr->end (); run_itr++, run++) {
					if (run_flag [run] == 0) continue;
					if (run_period [run] != period) continue;

					board += run_itr->Board ();
					alight += run_itr->Alight ();
					riders += run_itr->Load ();
					runs++;

					if (line_ptr->run_types.size () > 0) {
						run_type_ptr = &veh_type_array [line_ptr->Run_Type (run)];
						capacity += run_type_ptr->Capacity ();
					} else {
						capacity += veh_type_ptr->Capacity ();
					}
					if (next_itr != line_ptr->end ()) {
						time = next_itr->at (run).Schedule ().Seconds () - run_itr->Schedule ().Seconds ();
						sum_time += time;
						num++;
					}
				}
				if (runs == 0) continue;
				if (capacity == 0) capacity = runs;

				factor = DTOI (riders * 10.0 / runs) / 10.0;
				capfac = DTOI (riders * 10.0 / capacity) / 10.0;

				if (next_itr == line_ptr->end ()) runs = 0;

				if (num > 0) {
					time = sum_time / num;
				} else {
					time = 0;
				}
				if (capfac > 1.0) {
					len = UnRound (length) / len_fac;
					duration = len * hour_fac;
					delay = time * riders / 3600.0;
					crowding = len * runs;

					tot_dur [line_ptr->Mode ()] += duration;
					tot_delay [line_ptr->Mode ()] += delay;
					tot_crowd [line_ptr->Mode ()] += crowding;
				} else {
					duration = delay = crowding = 0.0;
				}
				tot_board [line_ptr->Mode ()] += board;

				file << line_ptr->Route () << "\t" << Transit_Code ((Transit_Type) line_ptr->Mode ()) << "\t" <<
					veh_type_ptr->Type () << "\t" << sum_periods.Range_Format (period);

				file << "\t" << UnRound (length) << "\t" << time << "\t" <<
					alight << "\t" << board << "\t" << riders << "\t" << runs << "\t" << factor <<
					"\t" << capacity << "\t" << capfac << "\t" << duration << "\t" << delay << "\t" << crowding << "\t";
				
				if (!line_ptr->Name ().empty ()) {
					file << line_ptr->Name () << "\t";
				}
				file << "\n";
			}
		}
	}
	End_Progress ();
	load_summary_file.Close ();

	Print (2, "Load Summary Results");
	Print (2, "Mode           Boardings     Duration         Delay      Crowding");
	Print (1);

	for (num = 1; num < ANY_TRANSIT; num++) {
		if (tot_board [num] <= 0) continue;

		tot_dur [0] += tot_dur [num];
		tot_delay [0] += tot_delay [num];
		tot_crowd [0] += tot_crowd [num];
		tot_board [0] += tot_board [num];

		Print (1, String ("%14.14s %9d  %12.2lf  %12.2lf  %12.2lf")
			% Transit_Code ((Transit_Type) num) % tot_board [num] % tot_dur [num] % tot_delay [num] % tot_crowd [num]);
	}
	Print (2, String ("%14.14s %9d  %12.2lf  %12.2lf  %12.2lf")
		% "Total" % tot_board [0] % tot_dur [0] % tot_delay [0] % tot_crowd [0]);
}
