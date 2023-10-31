//*********************************************************
//	Get_Parking_Data.cpp - read the parking file
//*********************************************************

#include "TransitNet.hpp"

#include "Link_Dir_Data.hpp"

//---------------------------------------------------------
//	Get_Parking_Data
//---------------------------------------------------------

bool TransitNet::Get_Parking_Data (Parking_File &file, Parking_Data &parking_rec)
{
	Link_Dir_Data link_dir;
	Int2_Key key;
	Int2_Set_Stat set_stat;

	if (!file.Nested ()) {
		if (file.Parking () == 0) return (false);

		link_dir.Link (file.Link ());
		link_dir.Dir (file.Dir ());

		key.first = link_dir.Link_Dir ();
		key.second = Round (file.Offset ());

		set_stat = park_loc_set.insert (key);
		if (!set_stat.second) return (false);
	}
	return (Data_Service::Get_Parking_Data (file, parking_rec));
}
