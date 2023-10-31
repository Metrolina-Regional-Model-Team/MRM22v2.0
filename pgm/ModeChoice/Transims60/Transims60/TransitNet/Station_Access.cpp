//*********************************************************
//	Station_Access.cpp - add access to transit stations
//*********************************************************

#include "TransitNet.hpp"

#include "Shape_Tools.hpp"
#include <math.h>

//---------------------------------------------------------
//	Station_Access
//---------------------------------------------------------

void TransitNet::Station_Access (void)
{
	int i, dir, index, node, max_walk, offset, speed, num, best, best2, min_stop;
	Dtime time;
	double dx, dy, closest, closest2, distance;

	Link_Data *link_ptr, *link2_ptr;
	Dir_Data *dir_ptr;
	Stop_Itr stop_itr;
	Node_Itr node_itr;
	Node_Data *node_ptr;
	Int_Map_Stat map_stat;
	Access_Data access_rec;
	Points points;
	XYZ_Point pt;
	Point_Map_Itr pt_itr;
	Int_Map_Itr map_itr;
	Int_Set acc_nodes;
	Int_Set_Itr int_itr;

	if (station_distance > 0) {
		max_walk = station_distance;
	} else {
		max_walk = Internal_Units (800, FEET);
	}
	speed = Round (Internal_Units (3.0, MPH));

	Show_Message ("Adding Station Access -- Record");
	Set_Progress ();

	if (access_flag) {
		min_stop = new_stop;
	} else {
		min_stop = 0;
	}

	//---- find transit stops on non-walk links ----

	for (nstop = 0, stop_itr = stop_array.begin (); stop_itr != stop_array.end (); stop_itr++, nstop++) {
		if (stop_itr->Stop () <= min_stop) continue;

		link_ptr = &link_array [stop_itr->Link ()];

		if (Use_Permission (link_ptr->Use (), WALK)) continue;

		Show_Progress ();

		if (stop_itr->Offset () < link_ptr->Length () / 2) {
			if (stop_itr->Dir () == 0) {
				node = link_ptr->Anode ();
			} else {
				node = link_ptr->Bnode ();
			}
			offset = stop_itr->Offset ();
		} else {
			if (stop_itr->Dir () == 0) {
				node = link_ptr->Bnode ();
			} else {
				node = link_ptr->Anode ();
			}
			offset = link_ptr->Length () - stop_itr->Offset ();
		}

		if (offset < max_walk) {
			num = 0;
			for (dir = node_list [node]; dir >= 0; dir = dir_list [dir]) {
				dir_ptr = &dir_array [dir];
				if (dir_ptr->Link () == stop_itr->Link ()) continue;

				link2_ptr = &link_array [dir_ptr->Link ()];

				if (!Use_Permission (link2_ptr->Use (), WALK)) continue;
				num++;
				if (dir_stop_array [dir].size () > 0) num++;
			}
			if (num == 0) {
				acc_nodes.insert (node);
			}

			//---- add the connection to the node ----

			time.Seconds (offset / speed);

			access_rec.Link (++max_access);
			access_rec.From_Type (STOP_ID);
			access_rec.From_ID (nstop);
			access_rec.To_Type (NODE_ID);
			access_rec.To_ID (node);
			access_rec.Dir (2);
			access_rec.Time (time);
			access_rec.Cost (0);
			access_rec.Notes ("Station Access");

			access_map.insert (Int_Map_Data (access_rec.Link (), (int) access_array.size ()));
			access_array.push_back (access_rec);
			naccess++;

		} else {

			pt_itr = stop_pt.find (stop_itr->Stop ());

			pt = pt_itr->second;

			closest = closest2 = max_walk + 1;
			best = best2 = -1;

			for (i = 0; i < 2; i++) {

				for (index = 0, node_itr = node_array.begin (); node_itr != node_array.end (); node_itr++, index++) {
					if (index == node) continue;

					dx = UnRound (node_itr->X ()) - pt.x;
					dy = UnRound (node_itr->Y ()) - pt.y;

					distance = sqrt (dx * dx + dy * dy);

					if (distance < closest || distance < closest2) {

						num = 0;
						for (dir = node_list [index]; dir >= 0; dir = dir_list [dir]) {
							dir_ptr = &dir_array [dir];
							if (dir_ptr->Link () == stop_itr->Link ()) continue;

							link2_ptr = &link_array [dir_ptr->Link ()];

							if (!Use_Permission (link2_ptr->Use (), WALK)) continue;

							num++;
							if (dir_stop_array [dir].size () > 0) {
								num++;
							}
						}
						if (num >= (2 - i)) {
							if (distance < closest) {
								closest2 = closest;
								best2 = best;
								closest = distance;
								best = index;
							} else if (distance < closest2) {
								closest2 = distance;
								best2 = index;
							}
						}
					}
				}
				if (best >= 0) break;
			}
			if (best >= 0) {
				time.Seconds (Round (closest) / speed);

				access_rec.Link (++max_access);
				access_rec.From_Type (STOP_ID);
				access_rec.From_ID (nstop);
				access_rec.To_Type (NODE_ID);
				access_rec.To_ID (best);
				access_rec.Dir (2);
				access_rec.Time (time);
				access_rec.Cost (0);
				access_rec.Notes ("Station Access");

				access_map.insert (Int_Map_Data (access_rec.Link (), (int)access_array.size ()));
				access_array.push_back (access_rec);
				naccess++;
			}
			if (best2 >= 0) {
				time.Seconds (Round (closest2) / speed);

				access_rec.Link (++max_access);
				access_rec.From_Type (STOP_ID);
				access_rec.From_ID (nstop);
				access_rec.To_Type (NODE_ID);
				access_rec.To_ID (best2);
				access_rec.Dir (2);
				access_rec.Time (time);
				access_rec.Cost (0);
				access_rec.Notes ("Station Access");

				access_map.insert (Int_Map_Data (access_rec.Link (), (int)access_array.size ()));
				access_array.push_back (access_rec);
				naccess++;
			}

			//----- station to stop access ----

			if (transfer_distance > 0) {
				for (pt_itr = stop_pt.begin (); pt_itr != stop_pt.end (); pt_itr++) {
					dx = pt_itr->second.x - pt.x;
					dy = pt_itr->second.y - pt.y;

					distance = sqrt (dx * dx + dy * dy);

					if (distance <= transfer_distance) {
						map_itr = stop_map.find (pt_itr->first);

						if (map_itr != stop_map.end () && map_itr->second > nstop) {
							time.Seconds (Round (distance) / speed);

							access_rec.Link (++max_access);
							access_rec.From_Type (STOP_ID);
							access_rec.From_ID (nstop);
							access_rec.To_Type (STOP_ID);
							access_rec.To_ID (map_itr->second);
							access_rec.Dir (2);
							access_rec.Time (time);
							access_rec.Cost (0);
							access_rec.Notes ("Transfer");

							access_map.insert (Int_Map_Data (access_rec.Link (), (int)access_array.size ()));
							access_array.push_back (access_rec);
							naccess++;
						}
					}
				}
			}
		}
	}

	//---- find nodes close to the station ----

	for (int_itr = acc_nodes.begin (); int_itr != acc_nodes.end (); int_itr++) {
		node = *int_itr;
		node_ptr = &node_array [node];

		pt.x = UnRound (node_ptr->X ());
		pt.y = UnRound (node_ptr->Y ());
		closest = closest2 = max_walk + 1;
		best = best2 = -1;

		for (i = 0; i < 2; i++) {

			for (index = 0, node_itr = node_array.begin (); node_itr != node_array.end (); node_itr++, index++) {
				if (index == node) continue;

				dx = UnRound (node_itr->X ()) - pt.x;
				dy = UnRound (node_itr->Y ()) - pt.y;

				distance = sqrt (dx * dx + dy * dy);

				if (distance < closest || distance < closest2) {

					num = 0;
					for (dir = node_list [index]; dir >= 0; dir = dir_list [dir]) {
						dir_ptr = &dir_array [dir];

						link2_ptr = &link_array [dir_ptr->Link ()];

						if (link2_ptr->Anode () == node || link2_ptr->Bnode () == node) continue;
						if (!Use_Permission (link2_ptr->Use (), WALK)) continue;

						num++;
						if (dir_stop_array [dir].size () > 0) {
							num++;
						}
					}
					if (num >= (2 - i)) {
						if (distance < closest) {
							closest2 = closest;
							best2 = best;
							closest = distance;
							best = index;
						} else if (distance < closest2) {
							closest2 = distance;
							best2 = index;
						}
					}
				}
			}
			if (best >= 0) break;
		}
		if (best >= 0) {
			time.Seconds (Round (closest) / speed);

			access_rec.Link (++max_access);
			access_rec.From_Type (NODE_ID);
			access_rec.From_ID (node);
			access_rec.To_Type (NODE_ID);
			access_rec.To_ID (best);
			access_rec.Dir (2);
			access_rec.Time (time);
			access_rec.Cost (0);
			access_rec.Notes ("Station Access");

			access_map.insert (Int_Map_Data (access_rec.Link (), (int) access_array.size ()));
			access_array.push_back (access_rec);
			naccess++;
		}
		if (best2 >= 0) {
			time.Seconds (Round (closest2) / speed);

			access_rec.Link (++max_access);
			access_rec.From_Type (NODE_ID);
			access_rec.From_ID (node);
			access_rec.To_Type (NODE_ID);
			access_rec.To_ID (best2);
			access_rec.Dir (2);
			access_rec.Time (time);
			access_rec.Cost (0);
			access_rec.Notes ("Station Access");

			access_map.insert (Int_Map_Data (access_rec.Link (), (int) access_array.size ()));
			access_array.push_back (access_rec);
			naccess++;
		}
	}
	End_Progress ();
}
