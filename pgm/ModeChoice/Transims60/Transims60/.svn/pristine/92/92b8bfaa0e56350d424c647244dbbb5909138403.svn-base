//*********************************************************
//	Write_Locations - draw location demands
//*********************************************************

#include "ArcPlan.hpp"

//---------------------------------------------------------
//	Write_Locations
//---------------------------------------------------------

void ArcPlan::Write_Locations (void)
{
	int index, zone, total, zone_tot;
	int loc_field, zone_field, prod_field, attr_field, tot_field, pshare_fld, ashare_fld, tshare_fld;
	double share;

	Int_Map_Itr map_itr;
	Point_Map_Itr pt_itr;
	Location_Data *loc_ptr;
	Location_Itr loc_itr;
	Zone_Data *zone_ptr;
	Integers zone_prod, zone_attr;

	loc_field = arcview_location.Field_Number ("LOCATION");
	zone_field = arcview_location.Field_Number ("ZONE");
	prod_field = arcview_location.Field_Number ("PRODUCTION");
	attr_field = arcview_location.Field_Number ("ATTRACTION");
	tot_field = arcview_location.Field_Number ("TOTAL");
	pshare_fld = arcview_location.Field_Number ("PROD_SHARE");
	ashare_fld = arcview_location.Field_Number ("ATTR_SHARE");
	tshare_fld = arcview_location.Field_Number ("TOT_SHARE");

	arcview_location.clear ();

	Show_Message (String ("Writing %s -- Record") % arcview_location.File_Type ());
	Set_Progress ();

	//---- get the zone sums ----

	zone_prod.assign (zone_array.size (), 0);
	zone_attr.assign (zone_array.size (), 0);

	for (index = 0, loc_itr = location_array.begin (); loc_itr != location_array.end (); loc_itr++, index++) {
		zone = loc_itr->Zone ();
		if (zone < 0) continue;

		zone_prod [zone] += productions [index];
		zone_attr [zone] += attractions [index];
	}

	//---- process each locataion ----

	for (pt_itr = location_pt.begin (); pt_itr != location_pt.end (); pt_itr++) {
		Show_Progress ();

		map_itr = location_map.find (pt_itr->first);
		if (map_itr == location_map.end ()) continue;

		index = map_itr->second;

		loc_ptr = &location_array [index];

		zone = loc_ptr->Zone ();

		zone_ptr = &zone_array [zone];

		total = productions [index] + attractions [index];

		arcview_location.Put_Field (loc_field, loc_ptr->Location ());
		arcview_location.Put_Field (zone_field, zone_ptr->Zone ());
		arcview_location.Put_Field (prod_field, productions [index]);
		arcview_location.Put_Field (attr_field, attractions [index]);
		arcview_location.Put_Field (tot_field, total);

		zone_tot = zone_prod [zone];

		if (zone_tot > 0) {
			share = (double) productions [index] * 100.0 / zone_tot;
		} else {
			share = 0;
		}
		arcview_location.Put_Field (pshare_fld, share);

		zone_tot = zone_attr [zone];

		if (zone_tot > 0) {
			share = (double) attractions [index] * 100.0 / zone_tot;
		} else {
			share = 0;
		}
		arcview_location.Put_Field (ashare_fld, share);

		zone_tot += zone_prod [zone];

		if (zone_tot > 0) {
			share = (double) total * 100.0 / zone_tot;
		} else {
			share = 0;
		}
		arcview_location.Put_Field (tshare_fld, share);

		//---- write the location record ----

		arcview_location.assign (1, pt_itr->second);

		if (!arcview_location.Write_Record ()) {
			Error (String ("Writing %s") % arcview_location.File_Type ());
		}
		num_location++;
	}
	End_Progress ();

	arcview_location.Close ();
}
