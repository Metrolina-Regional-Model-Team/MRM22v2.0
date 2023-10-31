//*********************************************************
//	Parking_Fields.cpp - process parking lot records
//*********************************************************

#include "VissimNet.hpp"

//---------------------------------------------------------
//	Parking_Fields
//---------------------------------------------------------

bool VissimNet::Parking_Fields (void)
{
	int lnk, nod, zon, dir;

	XYZ pt;
	Int_Map_Itr map_itr;
	Int_Map_Stat map_stat;
	Link_Data *link_ptr;
	Shape_Data *shape_ptr;
	Zone_Data zone_data, *zone_ptr;
	Parking_Data parking_data;
	Location_Data location_data;

	if (pair_itr->first.Equals ("<parkingLot")) {
		if (lot_flag) Warning ("Parking Lot Block was Not Terminated");
		lot_flag = true;
		zone = parking = link = node = 0;
		value = 0;
	} else if (pair_itr->first.Equals ("</parkingLot")) {
		if (!lot_flag) Warning ("Parking Lot Block was Not Initialized");
		lot_flag = false;
		goto save_data;
	}
	if (lot_flag) {
		lot_flag = !pair_itr->second.Equals ("/>");

		for (++pair_itr; pair_itr != string_pairs.end (); pair_itr++) {
			if (pair_itr->first.Equals ("zone")) {
				zone = pair_itr->second.Integer ();
			} else if (pair_itr->first.Equals ("no")) {
				parking = pair_itr->second.Integer ();
			} else if (pair_itr->first.Equals ("intLink")) {
				link = pair_itr->second.Integer ();
			} else if (pair_itr->first.Equals ("anmConnNodeNo")) {
				node = pair_itr->second.Integer ();
			} else if (pair_itr->first.Equals ("pos")) {
				value = pair_itr->second.Double ();
			}
		}
		if (!lot_flag) {
			goto save_data;
		}
		return (true);
	}
	return (false);

save_data:
	zone_data.Clear ();
	zone_data.Zone (zone);

	map_itr = link_map.find (link);
	if (map_itr != link_map.end ()) {
		lnk = map_itr->second;
		link_ptr = &link_array [lnk];

		shape_ptr = &shape_array [link_ptr->Shape ()];

		map_itr = node_map.find (node);
		if (map_itr != node_map.end ()) {
			nod = map_itr->second;

			//---- get the link direction ----

			if (link_ptr->Anode () == nod) {
				pt = shape_ptr->front ();
				dir = 0;
			} else if (link_ptr->Bnode () == nod) {
				pt = shape_ptr->back ();
				dir = 1;
			} else {
				Warning (String ("Zone Connector Link=%d Node=%d are Not Compatible") % link % node);
				dir = 0;
			}
			//---- create or update the zone record ----

			zone_data.X (pt.x);
			zone_data.Y (pt.y);
			zone_data.Area_Type (1);

			zon = (int) zone_array.size ();

			map_stat = zone_map.insert (Int_Map_Data (zone, zon));

			if (map_stat.second) {
				zone_array.push_back (zone_data);
			} else {
				zon = map_stat.first->second;

				zone_ptr = &zone_array [zon];

				zone_ptr->X (zone_data.X () + zone_ptr->X ());
				zone_ptr->Y (zone_data.Y () + zone_ptr->Y ());
				zone_ptr->Area_Type (zone_ptr->Area_Type () + 1);
			}
			if (value < 2.0) value = 2.0;

			//---- save the parking and location records ----

			parking_data.Parking (parking);
			parking_data.Link (lnk);
			parking_data.Dir (0);
			parking_data.Offset (value);
			parking_data.Type (BOUNDARY);

			if (parking_map.insert (Int_Map_Data (parking, (int) parking_array.size ())).second) {
				parking_array.push_back (parking_data);
			}

			location_data.Location (parking);
			location_data.Link (lnk);
			location_data.Dir (0);
			location_data.Offset (value);
			location_data.Setback (10.0);
			location_data.Zone (zon);

			if (dir == 0) {
				location_data.X (1);
				location_data.Y (0);
			} else {
				location_data.X (0);
				location_data.Y (1);
			}
			if (location_map.insert (Int_Map_Data (parking, (int) location_array.size ())).second) {
				location_array.push_back (location_data);
			}
		} else {
			Warning (String ("Zone Connector Link=%d Node=%d was Not Found") % link % node);
		}
	} else {
		Warning (String ("Zone Connector Link=%d was Not Found") % link);
	}
	return (true);
}
