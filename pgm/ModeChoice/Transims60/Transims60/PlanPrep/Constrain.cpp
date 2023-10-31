//*********************************************************
//	Constrain.cpp - constrain plans
//*********************************************************

#include "PlanPrep.hpp"

//---------------------------------------------------------
//	Constrain
//---------------------------------------------------------

bool PlanPrep::Constrain (Plan_Ptr plan_ptr)
{
	int board, route, run, run1, run2, index;
	double load;
	Dtime time, time2;
	bool park_flag, transit_flag, flag;

	Line_Data *line_ptr;
	Line_Stop_Itr stop_itr, board_itr, alight_itr;
	Line_Run_Itr run_itr;
	Line_Run *run_ptr;
	Plan_Leg_Itr leg_itr;
	Int_Map_Itr map_itr;

	park_flag = (plan_ptr->Mode () == PNR_OUT_MODE && park_list_flag);
	transit_flag = (plan_ptr->Transit_Mode_Flag () && route_list_flag);

	if (!park_flag && !transit_flag) return (true);

	board = route = -1;
	time = plan_ptr->Depart ();
	time2 = 0;
	flag = false;

	for (leg_itr = plan_ptr->begin (); leg_itr != plan_ptr->end (); leg_itr++, time += time2) {
		time2 = leg_itr->Time ();

		if (leg_itr->Type () == STOP_ID) {
			if (leg_itr->Mode () != TRANSIT_MODE) {
				board = leg_itr->ID ();
			}
		} else if (leg_itr->Type () == ROUTE_ID) {
			route = leg_itr->ID ();

			if (route_list_flag && route_list.In_Range (route)) {
				map_itr = dat->stop_map.find (board);
				if (map_itr == dat->stop_map.end ()) continue;

				board = map_itr->second;

				map_itr = dat->line_map.find (route);
				if (map_itr == dat->line_map.end ()) continue;

				line_ptr = &line_array [map_itr->second];

				//---- find the boarding and alighting locations ----

				for (board_itr = line_ptr->begin (); board_itr != line_ptr->end (); board_itr++) {
					if (board_itr->Stop () == board) break;
				}
				if (board_itr == line_ptr->end ()) continue;

				//---- find the run number ----

				for (run = 0, run_itr = board_itr->begin (); run_itr != board_itr->end (); run_itr++, run++) {
					if (time <= run_itr->Schedule ()) break;
				}
				if (run_itr == board_itr->end ()) continue;

				//---- load the trip ----

				load = 0;
				run1 = run - 2;
				if (run1 < 0) run1 = 0;
				run2 = run + 2;
				if (run2 >= (int) board_itr->size ()) run2 = (int) board_itr->size () - 1;

				for (run = run1; run <= run2; run++) {
					run_ptr = &board_itr->at (run);

					load += run_ptr->Factor ();
				}
				run = run2 - run1 + 1;
				load /= run;

				if (load > max_factor) return (false);
			}
			board = -1;
		
		} else if (park_flag && leg_itr->Type () == PARKING_ID) {
			if (flag) {
				index = leg_itr->ID ();

				Park_Demand_Data *demand_ptr;
				Park_Period_Data *period_ptr;
				Parking_Data *parking_ptr;

				Int_Map_Itr itr = parking_map.find (index);
				if (itr != parking_map.end ()) {
					demand_ptr = park_demand_array.Get_Parking (itr->second);

					if (demand_ptr != 0) {
						int period = park_demand_array.periods->Period (time);
						if (period < 0) period = 0;
						
						period_ptr = &demand_ptr->at (period);
						double demand = period_ptr->Demand ();

						parking_ptr = &parking_array [itr->second];

						if (parking_ptr->Capacity () > 0) {
							double ratio = (double) demand / parking_ptr->Capacity ();
							if (ratio >= max_ratio) return (false);
						}
					}
				}
			} else {
				flag = true;
			}
		}
	}
	return (true);
}
