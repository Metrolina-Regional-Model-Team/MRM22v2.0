//*********************************************************
//	Add_Route_Stops.cpp - add stops to specified routes
//*********************************************************

#include "TransitNet.hpp"

//---------------------------------------------------------
//	Add_Route_Stops
//---------------------------------------------------------

void TransitNet::Add_Route_Stops (void)
{
	int route, stop, index, fare, count, dir_index, node0, node, run;
	bool rail_flag, flag;
	Dtime old_time, new_time, ttime;
	double factor;

	Int_Map_Itr map_itr;
	Line_Data *line_ptr;
	Stop_Data *stop_ptr;
	Line_Stop line_stop, *line_stop_ptr, *stop0_ptr;
	Line_Run line_run;
	Line_Run_Itr run_itr;
	Dir_Data *dir_ptr;
	Link_Data *link_ptr;
	Path_Leg_RItr path_ritr;
	Int_RItr int_ritr;

	Show_Message (String ("Reading %s -- Record") % add_stops_file.File_Type ());
	Set_Progress ();

	count = 0;

	while (add_stops_file.Read ()) {
		Show_Progress ();

		route = add_stops_file.Get_Integer (add_route_field);
		if (route == 0) continue;

		map_itr = line_map.find (route);
		if (map_itr == line_map.end ()) {
			Warning (String ("Add Route Stop Route=%d was Not Found") % route);
			continue;
		}
		line_ptr = &line_array [map_itr->second];

		stop = add_stops_file.Get_Integer (add_stop_field);

		map_itr = stop_map.find (stop);
		if (map_itr == stop_map.end ()) {
			Warning (String ("Add Route Stop Stop=%d was Not Found") % stop);
			continue;
		}
		stop = map_itr->second;
		stop_ptr = &stop_array [stop];

		if (add_index_field >= 0) {
			index = add_stops_file.Get_Integer (add_index_field);
		} else {
			index = -1;
		}

		if (add_fare_field >= 0) {
			fare = add_stops_file.Get_Integer (add_fare_field);
		} else {
			fare = 1;
		}
		if (index < 0 || index >= (int) line_ptr->size ()) {
			line_stop.Clear ();
			line_stop.Stop (stop);
			line_stop.Zone (fare);

			dir_index = line_ptr->driver_array.back ();
			dir_ptr = &dir_array [dir_index];

			rail_flag = false;

			if (dir_ptr->Link_Dir () != stop_ptr->Link_Dir ()) {

				link_ptr = &link_array [dir_ptr->Link ()];
				if (dir_ptr->Dir () == 0) {
					node0 = link_ptr->Bnode ();
				} else {
					node0 = link_ptr->Anode ();
				}

				link_ptr = &link_array [stop_ptr->Link ()];
				if (stop_ptr->Dir () == 0) {
					node = link_ptr->Anode ();
					index = link_ptr->AB_Dir ();
				} else {
					node = link_ptr->Bnode ();
					index = link_ptr->BA_Dir ();
				}

				//---- attempt to build a minimum distance path ----

				Node_Path (node0, node, BUS, dir_index);

				if ((int) path_leg_array.size () == 0) {

					//---- try to build a rail path ----

					Node_Path (node0, node, RAIL, dir_index);

					if ((int) path_leg_array.size () == 0) {
						Warning (String ("Path from %d and %d on Route %d includes Use Restrictions") % node_array [node0].Node () % node_array [node].Node () % line_ptr->Route ());
						continue;
					}
					rail_flag = true;
				}

				//---- add links to the driver array ----

				for (path_ritr = path_leg_array.rbegin (); path_ritr != path_leg_array.rend (); path_ritr++) {
					line_ptr->driver_array.push_back (path_ritr->Dir_Index ());
				}

				line_ptr->driver_array.push_back (index);
			}

			//---- calculate the network travel time for the path ----

			link_ptr = &link_array [stop_ptr->Link ()];
			new_time = dir_ptr->Time0 () * (stop_ptr->Offset () - link_ptr->Length ()) / link_ptr->Length ();

			index = (int) line_ptr->size () - 1;

			line_stop_ptr = &line_ptr->at (index);
			stop_ptr = &stop_array [line_stop_ptr->Stop ()];
			link_ptr = &link_array [stop_ptr->Link ()];

			if (stop_ptr->Dir () == 0) {
				dir_index = link_ptr->AB_Dir ();
			} else {
				dir_index = link_ptr->BA_Dir ();
			}

			old_time = 0;
			flag = true;

			for (int_ritr = line_ptr->driver_array.rbegin (); int_ritr != line_ptr->driver_array.rend (); int_ritr++) {
				dir_ptr = &dir_array [*int_ritr];

				if (*int_ritr == dir_index) {
					new_time += old_time = dir_ptr->Time0 () * (link_ptr->Length () - stop_ptr->Offset ()) / link_ptr->Length ();
					old_time = dir_ptr->Time0 () - old_time;
					flag = false;
				} else if (flag) {
					new_time += dir_ptr->Time0 ();
				} else {
					old_time += dir_ptr->Time0 ();
				}
			}

			//---- add schedule records ----

			stop0_ptr = &line_ptr->at (0);
			factor = new_time.Seconds () / old_time.Seconds ();

			line_stop.clear ();
			line_run.Clear ();

			for (run=0, run_itr = line_stop_ptr->begin (); run_itr != line_stop_ptr->end (); run_itr++, run++) {
				ttime = run_itr->Schedule () - stop0_ptr->at (run).Schedule ();
				ttime.Seconds (ttime.Seconds () * factor);
				line_run.Schedule (run_itr->Schedule () + ttime.Round_Seconds ());
				line_stop.push_back (line_run);
			}
			line_ptr->push_back (line_stop);
		}
		count++;
	}
	End_Progress ();

	Print (2, "Number of Route Stops Added = ") << count;
		
	add_stops_file.Close ();
}
