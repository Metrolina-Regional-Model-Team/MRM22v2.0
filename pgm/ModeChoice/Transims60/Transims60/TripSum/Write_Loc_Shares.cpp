//*********************************************************
//	Write_Location_Shares.cpp - Write a Location Shares File
//*********************************************************

#include "TripSum.hpp"

//---------------------------------------------------------
//	Write_Location_Shares
//---------------------------------------------------------

void TripSum::Write_Location_Shares (void)
{
	int i, zone, total, zone_tot;
	double share;

	Int_Map_Itr map_itr;
	Location_Itr loc_itr;
	Location_Data *loc_ptr;
	Zone_Data *zone_ptr;
	Integers zone_prod, zone_attr;

	Show_Message ("Writing Location Shares -- Location");
	Set_Progress ();

	//---- get the zone sums ----

	zone_prod.assign (zone_array.size (), 0);
	zone_attr.assign (zone_array.size (), 0);

	for (i=0, loc_itr = location_array.begin (); loc_itr != location_array.end (); loc_itr++, i++) {
		zone = loc_itr->Zone ();
		if (zone < 0) continue;

		zone_prod [zone] += productions [i];
		zone_attr [zone] += attractions [i];
	}

	//---- write the location data ----

	for (map_itr = location_map.begin (); map_itr != location_map.end (); map_itr++) {
		Show_Progress ();

		i = map_itr->second;

		loc_ptr = &location_array [i];

		loc_share_file.Put_Field (0, loc_ptr->Location ());

		zone = loc_ptr->Zone ();

		zone_ptr = &zone_array [zone];

		loc_share_file.Put_Field (1, zone_ptr->Zone ());

		loc_share_file.Put_Field (2, productions [i]);
		loc_share_file.Put_Field (3, attractions [i]);

		total = productions [i] + attractions [i];

		loc_share_file.Put_Field (4, total);

		zone_tot = zone_prod [zone];

		if (zone_tot > 0) {
			share = (double) productions [i] * 100.0 / zone_tot;
		} else {
			share = 0;
		}
		loc_share_file.Put_Field (5, share);

		zone_tot = zone_attr [zone];

		if (zone_tot > 0) {
			share = (double) attractions [i] * 100.0 / zone_tot;
		} else {
			share = 0;
		}
		loc_share_file.Put_Field (6, share);

		zone_tot += zone_prod [zone];

		if (zone_tot > 0) {
			share = (double) total * 100.0 / zone_tot;
		} else {
			share = 0;
		}
		loc_share_file.Put_Field (7, share);

		loc_share_file.Write ();
	}
	End_Progress ();

	Print (2, "Number of New Location Shares Records = ") << Progress_Count ();
}
