//*********************************************************
//	Read_Stop_Zone.cpp - Read the Stop Fare Zone Map
//*********************************************************

#include "TransitNet.hpp"

//---------------------------------------------------------
//	Read_Stop_Zone
//---------------------------------------------------------

void TransitNet::Read_Stop_Zone (void)
{
	int stop, zone;

	Int_Map_Itr map_itr;
	Int_Map_Stat map_stat;
	Line_Itr line_itr;
	Line_Stop_Itr stop_itr;

	Show_Message (String ("Reading %s -- Record") % stop_zone_file.File_Type ());
	Set_Progress ();

	while (stop_zone_file.Read ()) {
		Show_Progress ();

		stop = stop_zone_file.Get_Integer (stop_field);
		zone = stop_zone_file.Get_Integer (zone_field);

		if (stop <= 0) continue;

		map_itr = stop_map.find (stop);

		if (map_itr == stop_map.end ()) {
			Warning (String ("Stop %d was Not Found in the Stop File") % stop);
			continue;
		}

		map_stat = stop_zone_map.insert (Int_Map_Data (map_itr->second, zone));

		if (!map_stat.second) {
			Warning (String ("Duplicate Fare Zone for Stop %d") % stop);
		}
	}
	End_Progress ();

	Print (2, "Number of Stop Fare Zone Records = ") << stop_zone_map.size ();
		
	stop_zone_file.Close ();

	//---- set the fare zone ----

	for (line_itr = line_array.begin (); line_itr != line_array.end (); line_itr++) {
		for (stop_itr = line_itr->begin (); stop_itr != line_itr->end (); stop_itr++) {
			map_itr = stop_zone_map.find (stop_itr->Stop ());

			if (map_itr != stop_zone_map.end ()) {
				stop_itr->Zone (map_itr->second);
			}
		}
	}
}
