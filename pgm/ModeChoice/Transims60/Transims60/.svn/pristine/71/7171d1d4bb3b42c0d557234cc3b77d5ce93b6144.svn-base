//*********************************************************
//	Veh_Type_Fields.cpp - process vehicle type records
//*********************************************************

#include "VissimNet.hpp"

//---------------------------------------------------------
//	Veh_Type_Fields
//---------------------------------------------------------

bool VissimNet::Veh_Type_Fields (void)
{
	String data;

	if (pair_itr->first.Equals ("<vehicleType")) {
		if (veh_type_flag) Warning ("Vehicle Type Block was Not Terminated");
		veh_type_flag = true;
		code = type = 0;
	} else if (pair_itr->first.Equals ("</vehicleType")) {
		if (!veh_type_flag) Warning ("Vehicle Type Block was Not Initialized");
		veh_type_flag = false;
		vehtype_map.insert (Int_Map_Data (code, type));
	}
	if (veh_type_flag) {
		if (pair_itr->first.Equals ("<vehicleType")) {
			veh_type_flag = !pair_itr->second.Equals ("/>");

			for (++pair_itr; pair_itr != string_pairs.end (); pair_itr++) {
				if (pair_itr->first.Equals ("category")) {
					data = pair_itr->second;
				} else if (pair_itr->first.Equals ("name")) {
					if (!pair_itr->second.empty ()) {
						data = pair_itr->second;
					}
				} else if (pair_itr->first.Equals ("no")) {
					code = pair_itr->second.Integer ();
				}
			}
			if (data.Starts_With ("SOV") || data.Starts_With ("CAR")) {
				type = CAR;
			} else if (data.Starts_With ("HOV")) {
				type = HOV2P;
			} else if (data.Starts_With ("BIKE")) {
				type = BIKE;
			} else if (data.Starts_With ("BUS")) {
				type = LOCAL_BUS;
			} else {
				type = CAR;
			}
			if (!veh_type_flag) {
				vehtype_map.insert (Int_Map_Data (code, type));
			}
		}
		return (true);
	}
	return (false);
}
