//*********************************************************
//	Sign_Fields.cpp - process stop sign records
//*********************************************************

#include "VissimNet.hpp"

//---------------------------------------------------------
//	Sign_Fields
//---------------------------------------------------------

bool VissimNet::Sign_Fields (void)
{
	String data, lane;
	Int_Map_Itr map_itr;
	Link_Data *link_ptr;
	Dir_Data *dir_ptr;

	if (pair_itr->first.Equals ("<stopSign")) {
		if (sign_flag) Warning ("Stop Sign Block was Not Terminated");
		sign_flag = true;
		link = 0;
	} else if (pair_itr->first.Equals ("</stopSign")) {
		if (!sign_flag) Warning ("Stop Sign Block was Not Initialized");
		sign_flag = false;
		goto save_data;
	}
	if (sign_flag) {
		sign_flag = !pair_itr->second.Equals ("/>");

		for (++pair_itr; pair_itr != string_pairs.end (); pair_itr++) {
			if (pair_itr->first.Equals ("lane")) {
				lane = pair_itr->second;
				lane.Split (data, " ");
				link = data.Integer ();
				break;
			}
		}
		if (!sign_flag) {
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
		dir_ptr->Sign (STOP_SIGN);
	}
	return (true);
}
