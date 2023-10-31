//*********************************************************
//	Select_Trips.cpp - set the selection criteria
//*********************************************************

#include "Converge_Service.hpp"

//---------------------------------------------------------
//	Select_Trips
//---------------------------------------------------------

bool Converge_Service::Select_Trips (void)
{
	int priority, num_selected, num_rec;
	Plan_Ptr plan_ptr;
	Trip_Data trip_rec;
	Trip_Map_Itr map_itr;

	num_selected = 0;

	for (map_itr = plan_trip_map.begin (); map_itr != plan_trip_map.end (); map_itr++) {
		plan_ptr = &plan_array [map_itr->second];
		trip_rec = *plan_ptr;

		priority = initial_priority;

		if (priority_flag) {
			trip_rec.Priority (priority);
		} else if (trip_rec.Priority () == NO_PRIORITY) {
			trip_rec.Priority (MEDIUM);
		} else if (trip_rec.Priority () == SKIP) {
			trip_rec.Priority (NO_PRIORITY);
		}
		trip_rec.External_IDs ();

		if (!Selection (&trip_rec)) {
			trip_rec.Priority (SKIP);
			priority = SKIP;
		} else {
			num_selected++;
		}
		if (priority_flag || priority == SKIP) {
			plan_ptr->Priority (priority);
		}
		counters.total_records++;
		if (select_priorities && select_priority [plan_ptr->Priority ()]) {
			counters.select_records++;
			counters.select_weight += plan_ptr->Priority ();
		}
	}
	num_rec = (int) plan_trip_map.size ();

	if (num_selected < num_rec) {
		Write (1, "Number of Selected Trips = ") << num_selected;
		if (num_rec > 0) {
			Write (0, String (" (%.1lf%%)") % (100.0 * num_selected / num_rec) % FINISH);
			Show_Message (1);
		}
	}
	return (num_selected > 0);
}
