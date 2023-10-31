//*********************************************************
//	Detector_Fields.cpp - process detector records
//*********************************************************

#include "VissimNet.hpp"

//---------------------------------------------------------
//	Detector_Fields
//---------------------------------------------------------

bool VissimNet::Detector_Fields (void)
{
	String data, string;
	Int_Map_Itr map_itr;
	Int_Map_Stat map_stat;
	Link_Data *link_ptr;
	Dir_Data *dir_ptr;
	Detector_Data detector_data, *detect_ptr;

	if (pair_itr->first.Equals ("<detector")) {
		if (detector_flag) Warning ("Detector Block was Not Terminated");
		detector_flag = true;
		detector = link = lane = 0;
		length = offset = 0;
	} else if (pair_itr->first.Equals ("</detector")) {
		if (!detector_flag) Warning ("Detector Block was Not Initialized");
		detector_flag = false;
		goto save_data;
	}
	if (detector_flag) {
		if (pair_itr->first.Equals ("<vehClasses")) {
			if (veh_class_flag) Warning ("Vehicle Classes Block was Not Terminated");
			veh_class_flag = true;
		} else if (pair_itr->first.Equals ("</vehClasses")) {
			if (!veh_class_flag) Warning ("Vehicle Classes Block was Not Initialized");
			veh_class_flag = false;
			return (true);
		}
		if (veh_class_flag) {
			if (pair_itr->first.Equals ("<intObjectRef")) {
				for (++pair_itr; pair_itr != string_pairs.end (); pair_itr++) {
					if (pair_itr->first.Equals ("key")) {
						code = pair_itr->second.Integer ();
					}
				}
			}
			return (true);
		}
		detector_flag = !pair_itr->second.Equals ("/>");

		for (++pair_itr; pair_itr != string_pairs.end (); pair_itr++) {
			if (pair_itr->first.Equals ("lane")) {
				string = pair_itr->second;
				string.Split (data, " ");
				link = data.Integer ();
				lane = string.Integer ();
			} else if (pair_itr->first.Equals ("no")) {
				detector = pair_itr->second.Integer ();
			} else if (pair_itr->first.Equals ("length")) {
				length = pair_itr->second.Double ();
			} else if (pair_itr->first.Equals ("pos")) {
				offset = pair_itr->second.Double ();
			}
		}
		if (!detector_flag) {
			goto save_data;
		}
		return (true);
	}
	return (false);

save_data:
	map_itr = link_map.find (link);
	if (map_itr != link_map.end ()) {
		link_ptr = &link_array [map_itr->second];
		dir_ptr = &dir_array [link_ptr->AB_Dir ()];

		lane = dir_ptr->Lanes () - lane;

		detector_data.Detector (detector);
		detector_data.Dir_Index (link_ptr->AB_Dir ());
		detector_data.Offset (offset);
		detector_data.Length (length);
		detector_data.Low_Lane (lane);
		detector_data.High_Lane (lane);
		detector_data.Type (PRESENCE);
		detector_data.Use (ANY);

		map_stat = detector_map.insert (Int_Map_Data (detector, (int) detector_array.size ()));

		if (map_stat.second) {
			detector_array.push_back (detector_data);
		} else {
			detect_ptr = &detector_array [map_stat.first->second];
			if (detect_ptr->Low_Lane () > lane) detect_ptr->Low_Lane (lane);
			if (detect_ptr->High_Lane () < lane) detect_ptr->High_Lane (lane);
		}
	}
	return (true);
}
