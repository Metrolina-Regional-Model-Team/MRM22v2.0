//*********************************************************
//	Link_Behavior.cpp - process link behavior records
//*********************************************************

#include "VissimNet.hpp"

//---------------------------------------------------------
//	Link_Behavior
//---------------------------------------------------------

bool VissimNet::Link_Behavior (void)
{
	int code, type;
	String data, junk;

	if (pair_itr->first.Equals ("<linkBehaviorType")) {
		if (type_flag) Warning ("Link Type Block was Not Terminated");
		type_flag = true;
	} else if (pair_itr->first.Equals ("</linkBehaviorType")) {
		if (!type_flag) Warning ("Link Type Block was Not Initialized");
		type_flag = false;
	}
	if (type_flag) {
		type_flag = !pair_itr->second.Equals ("/>");

		for (++pair_itr; pair_itr != string_pairs.end (); pair_itr++) {
			if (pair_itr->first.Equals ("name")) {
				data = pair_itr->second;
			} else if (pair_itr->first.Equals ("no")) {
				code = pair_itr->second.Integer ();
			}
		}
		if (!type_flag) {
			if (data.Starts_With ("Freeway") || data.Starts_With ("Fwy")) {
				type = FREEWAY;
			} else if (data.Starts_With ("Ramp") || data.Starts_With ("Off-Ramp")) {
				type = RAMP;
			} else if (data.Starts_With ("Major")) {
				type = MAJOR;
			} else if (data.Starts_With ("Minor")) {
				type = MINOR;
			} else if (data.Starts_With ("Collector")) {
				type = COLLECTOR;
			} else if (data.Starts_With ("Local")) {
				type = LOCAL;
			} else if (data.Starts_With ("HOV")) {
				if (data.Starts_With ("HOV_Merge")) {
					type = FREEWAY;
				} else {
					type = -FREEWAY;
				}
			} else if (data.Starts_With ("Stub")) {
				type = LOCAL;
			} else {
				data.Split (junk);

				if (data.Starts_With ("Freeway")) {
					type = FREEWAY;
				} else if (data.Starts_With ("Ramp")) {
					type = RAMP;
				} else {
					type = MINOR;
				}
			}
			type_map.insert (Int_Map_Data (code, type));
		}
		return (true);
	}
	return (false);
}
