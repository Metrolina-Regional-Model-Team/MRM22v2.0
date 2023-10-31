//*********************************************************
//	Read_Vissim.cpp - read vissim path file
//*********************************************************

#include "VissimPlans.hpp"

//---------------------------------------------------------
//	Read_Table
//---------------------------------------------------------

void VissimPlans::Read_Vissim (void)
{
	int i, count, node, link, path, trips;
	bool edge_flag, path_flag;

	String record;
	Strings fields;
	Str_Itr str_itr;
	Edge_Data edge_data;
	Int_Map_Itr map_itr;
	Path_Data path_data;

	Show_Message (1, String ("Reading %s -- Record") % path_file.File_Type ());
	Set_Progress ();

	path = 0;
	edge_flag = path_flag = false;

	while (path_file.Read ()) {
		Show_Progress ();
		record = path_file.Record_String ();

		if (record.Starts_With ("Linksanzahl")) {
			edge_flag = true;
			continue;
		} else if (record.Starts_With ("Parkplatzwege")) {
			edge_flag = false;
			path_flag = true;
			continue;
		}
		if (edge_flag) {
			record.Parse (fields, " ");
			if (fields.size () < 5) continue;

			edge_data.edge = fields [0].Integer ();

			record = fields [1];
			if (record.length () > 10) {
				record = record.substr (record.length () - 10);
			}
			if (record.length () == 10 && record [0] > '1') record [0] = '1';

			node = record.Integer ();

			map_itr = node_map.find (node);
			if (map_itr == node_map.end ()) {
				Warning (String ("Edge %d Origin Node %d was Not Found") % edge_data.edge % node);
			}
			edge_data.origin = node;

			record = fields [2];
			if (record.length () > 10) {
				record = record.substr (record.length () - 10);
			}
			if (record.length () == 10 && record [0] > '1') record [0] = '1';

			node = record.Integer ();

			map_itr = node_map.find (node);
			if (map_itr == node_map.end ()) {
				Warning (String ("Edge %d Destination Node %d was Not Found") % edge_data.edge % node);
			}
			edge_data.destination = node;

			edge_data.links.clear ();

			for (str_itr = fields.begin () + 4; str_itr != fields.end (); str_itr++) {
				link = str_itr->Integer ();

				map_itr = link_map.find (link);
				if (map_itr != link_map.end ()) {
					edge_data.links.push_back (map_itr->second);
				}
			}
			if (edge_data.links.size () == 0) {
				Warning (String ("No Links were Found for Edge %d") % edge_data.edge);
			}
			if (edge_map.insert (Int_Map_Data (edge_data.edge, (int) edge_array.size ())).second) {
				edge_array.push_back (edge_data);
			} else {
				Warning (String ("Duplicate Edge Number %d") % edge_data.edge);
			}

		} else if (path_flag) {
			record.Parse (fields, " ");
			if (fields.size () < 4) continue;

			path_data.path = ++path;
			node = fields [0].Integer ();

			map_itr = parking_map.find (node);
			if (map_itr == parking_map.end ()) {
				Warning (String ("Path %d Origin Parking %d was Not Found") % path % node);
			}
			path_data.origin = node;

			node = fields [1].Integer ();

			map_itr = parking_map.find (node);
			if (map_itr == parking_map.end ()) {
				Warning (String ("Path %d Destination Parking %d was Not Found") % path % node);
			}
			path_data.destination = node;

			count = fields [2].Integer ();

			path_data.edges.clear ();
			path_data.trips.clear ();

			for (i=0, str_itr = fields.begin () + 3; str_itr != fields.end () && i < count; str_itr++, i++) {
				link = str_itr->Integer ();

				map_itr = edge_map.find (link);
				if (map_itr == edge_map.end ()) {
					Warning (String ("Path %d Edge %d was Not Found") % path % link);
				} else {
					path_data.edges.push_back (map_itr->second);
				}
			}
			count = str_itr->Integer ();

			for (++str_itr; str_itr != fields.end (); str_itr++) {
				trips = str_itr->Integer ();
				path_data.trips.push_back (trips);
			}

			if (path_data.edges.size () == 0) {
				Warning (String ("No Edges were Found for Path %d") % path);
			}
			if (path_data.trips.size () == 0) {
				Warning (String ("No Trips were Found for Path %d") % path);
			}
			path_array.push_back (path_data);
		}
	}
	End_Progress ();

	path_file.Close ();

	Print (2, String ("%s has %d Records") % path_file.File_Type () % Progress_Count ());
	Print (1, "Number of Edge Records=") << edge_array.size ();
	Print (1, "Number of Path Records=") << path_array.size ();
}
