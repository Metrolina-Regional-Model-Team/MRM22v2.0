//*********************************************************
//	Update_Fare_Zones.cpp - replace fare zones
//*********************************************************

#include "TransitNet.hpp"

//---------------------------------------------------------
//	Update_Fare_Zones
//---------------------------------------------------------

void TransitNet::Update_Fare_Zones (void)
{
	int dir;

	Line_Itr line_itr;
	Line_Stop_Itr stop_itr;
	Stop_Data *stop_ptr;
	Link_Data *link_ptr;

	Show_Message ("Update Fare Zones -- Record");
	Set_Progress ();

	for (line_itr = line_array.begin (); line_itr != line_array.end (); line_itr++) {
		for (stop_itr = line_itr->begin (); stop_itr != line_itr->end (); stop_itr++) {
			Show_Progress ();

			stop_ptr = &stop_array [stop_itr->Stop ()];

			link_ptr = &link_array [stop_ptr->Link ()];
			
			if (stop_ptr->Dir () == 0) {
				dir = link_ptr->AB_Dir ();
			} else {
				dir = link_ptr->BA_Dir ();
			}
			stop_itr->Zone (fare_zone [dir]);
		}
	}
	End_Progress ();
}
