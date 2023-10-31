//*********************************************************
//	Link_Spd_Fields.cpp - process speed decision records
//*********************************************************

#include "VissimNet.hpp"

//---------------------------------------------------------
//	Link_Speed_Fields
//---------------------------------------------------------

bool VissimNet::Link_Speed_Fields (void)
{
	String data, lane;
	Int_Map_Itr map_itr;
	Link_Data *link_ptr;
	Dir_Data *dir_ptr;

	if (pair_itr->first.Equals ("<desSpeedDecision")) {
		if (speed_flag) Warning ("Speed Decision Block was Not Terminated");
		link_spd_flag = true;
		code = link = 0;
	} else if (pair_itr->first.Equals ("</desSpeedDecision")) {
		if (!link_spd_flag) Warning ("Speed Decision Block was Not Initialized");
		link_spd_flag = false;
	}
	if (link_spd_flag) {
		if (pair_itr->first.Equals ("<vehClassDesSpeedDistr")) {
			if (veh_spds_flag) Warning ("Vehicle Speeds Block was Not Terminated");
			veh_spds_flag = true;
		} else if (pair_itr->first.Equals ("</vehClassDesSpeedDistr")) {
			if (!veh_spds_flag) Warning ("Vehicle Speeds Block was Not Initialized");
			veh_spds_flag = false;

			map_itr = link_map.find (link);
			if (map_itr != link_map.end ()) {
				link_ptr = &link_array [map_itr->second];
				dir_ptr = &dir_array [link_ptr->AB_Dir ()];
				dir_ptr->Speed (code);
			}
			return (true);
		}
		if (veh_spds_flag) {
			if (pair_itr->first.Equals ("<vehClassDesSpeedDistribution")) {
				if (veh_spd_flag) Warning ("Vehicle Speed Block was Not Terminated");
				veh_spd_flag = true;
			} else if (pair_itr->first.Equals ("</vehClassDesSpeedDistribution")) {
				if (!veh_spd_flag) Warning ("Vehicle Speed was Not Initialized");
				veh_spd_flag = false;
			}
			if (veh_spd_flag) {
				if (pair_itr->first.Equals ("<vehClassDesSpeedDistribution")) {
					veh_spd_flag = !pair_itr->second.Equals ("/>");

					for (++pair_itr; pair_itr != string_pairs.end (); pair_itr++) {
						if (pair_itr->first.Equals ("desSpeedDistr")) {
							code = pair_itr->second.Integer ();
							break;
						}
					}
				}
			}
			return (true);
		}
		if (pair_itr->first.Equals ("<desSpeedDecision")) {
			link_spd_flag = !pair_itr->second.Equals ("/>");

			for (++pair_itr; pair_itr != string_pairs.end (); pair_itr++) {
				if (pair_itr->first.Equals ("lane")) {
					lane = pair_itr->second;
					lane.Split (data, " ");
					link = data.Integer ();
					break;
				}
			}
		}
		return (true);
	}
	return (false);
}
