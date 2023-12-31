//*********************************************************
//	Inline_Stations.cpp - insert in line station
//*********************************************************

#include "RoutePrep.hpp"

#include "Shape_Tools.hpp"

//---------------------------------------------------------
//	Inline_Station
//---------------------------------------------------------

void RoutePrep::Inline_Station (int node, int link1, int link2)
{
	int i, j, link, dir, node_index, link_index, dir_index, num, new1, new2, from, to;
	double length, offset, factor;
	String name;

	Int_Itr int_itr;
	Node_Data *node_ptr, node_rec;
	Link_Data *link_ptr, link_rec;
	Dir_Data *dir_ptr, dir_rec;
	Points points;
	Points_Itr pt_itr;
	XYZ xyz;
	Shape_Data *shape_ptr;
		
	node_ptr = &node_array [node];
	if (!node_ptr->Notes ().empty ()) {
		name = node_ptr->Notes ();
	} else {
		name = "station";
	}
	from = to = new1 = new2 = link_index = -1;

	for (j=0; j < 2; j++) {
		link = (j == 0) ? link1 : link2;

		link_ptr = &link_array [link];
		
		if (j == 0) {
			link_rec = *link_ptr;

			link_index = (int) link_array.size ();
		}

		//---- adjust the link length and shape ----

		if (link_ptr->Bnode () == node) {
			dir = 0;
			offset = 0.0;
			if (j == 0) {
				from = link_ptr->Anode ();
			} else {
				to = link_ptr->Anode ();
			}
		} else {
			dir = 1;
			offset = station_length / 2.0;
			if (j == 0) {
				from = link_ptr->Bnode ();
			} else {
				to = link_ptr->Bnode ();
			}
		}
		length = UnRound (link_ptr->Length ()) - station_length / 2.0;
		factor = length / UnRound (link_ptr->Length ());

		if (!Link_Shape (link_ptr, 0, points, offset, length)) {
			Warning ("Problem Extracting Station Length from Link ") << link_ptr->Link ();
		}
		num = (int) points.size ();

		if (num <= 2) {
			if (link_ptr->Shape () >= 0) link_ptr->Shape (-1);
		} else {
			shape_ptr = &shape_array [link_ptr->Shape ()];
			shape_ptr->clear ();

			for (i=1, pt_itr = points.begin () + 1; i < num; i++, pt_itr++) {
				xyz.x = Round (pt_itr->x);
				xyz.y = Round (pt_itr->y);
				xyz.z = Round (pt_itr->z);

				shape_ptr->push_back (xyz);
			}
		}
		
		//---- update link data and create station link ----

		node_index = (int) node_array.size ();
		dir_index = (int) dir_array.size ();
			
		if (dir == 0) {
			pt_itr = --points.end ();
			link_ptr->Bnode (node_index);
			if (j == 0) {
				link_rec.Anode (node_index);
				link_rec.Bnode (node_index + 1);
			}
		} else {
			pt_itr = points.begin ();
			link_ptr->Anode (node_index);
			if (j == 0) {
				link_rec.Bnode (node_index);
				link_rec.Anode (node_index + 1);
			}
		}
		link_ptr->Length (length);

		if (link_ptr->AB_Dir () >= 0) {
			dir_ptr = &dir_array [link_ptr->AB_Dir ()];
			dir_ptr->Time0 (DTOI (dir_ptr->Time0 () * factor));

			if (j == 0) {
				dir_rec = *dir_ptr;

				if (platform_time > 0) {
					dir_rec.Time0 (platform_time);
					dir_rec.Speed (platform_speed);
				} else {
					dir_rec.Time0 (2 * (dir_rec.Time0 () - dir_ptr->Time0 ()));
				}
				dir_rec.Link (link_index);

				dir_map.insert (Int_Map_Data (dir_rec.Link_Dir (), dir_index));
				dir_array.push_back (dir_rec);

				link_rec.AB_Dir (dir_index++);
			}
		}

		if (link_ptr->BA_Dir () >= 0) {
			dir_ptr = &dir_array [link_ptr->BA_Dir ()];
			dir_ptr->Time0 (DTOI (dir_ptr->Time0 () * factor));

			if (j == 0) {
				dir_rec = *dir_ptr;

				if (platform_time > 0) {
					dir_rec.Time0 (platform_time);
					dir_rec.Speed (platform_speed);
				} else {
					dir_rec.Time0 (2 * (dir_rec.Time0 () - dir_ptr->Time0 ()));
				}
				dir_rec.Link (link_index);
				dir_map.insert (Int_Map_Data (dir_rec.Link_Dir (), dir_index));
				dir_array.push_back (dir_rec);

				link_rec.BA_Dir (dir_index);
			}
		}
		if (j == 0) {
			link_rec.Link (new_link++);
			link_rec.Name (name);
			link_rec.Length (station_length);
			link_rec.Shape (-1);

			link_map.insert (Int_Map_Data (link_rec.Link (), link_index));
			link_array.push_back (link_rec);
		}

		//---- insert new nodes ----

		if (j == 0) {
			new1 = node_index;
		} else {
			new2 = node_index;
		}
		node_rec.Node (new_node++);
		node_rec.X (pt_itr->x);
		node_rec.Y (pt_itr->y);
		node_rec.Z (0);
		node_rec.Notes (name);

		node_map.insert (Int_Map_Data (node_rec.Node (), node_index));
		node_array.push_back (node_rec);
	}

	//---- update the route nodes ----

	Update_Routes (node, from, to, new1, new2);

	//---- add platform links ----

	if (platform_flag) {
		Platform_Link (link_index);
	} else {
		station_nodes.back ().push_back (new1);
		station_nodes.back ().push_back (new2);
	}
}
