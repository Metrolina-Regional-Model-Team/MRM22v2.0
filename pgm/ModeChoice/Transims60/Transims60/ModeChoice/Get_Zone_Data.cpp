//*********************************************************
//	Get_Zone_Data.cpp - read the zone file
//*********************************************************

#include "ModeChoice.hpp"

//---------------------------------------------------------
//	Get_Zone_Data
//---------------------------------------------------------

bool ModeChoice::Get_Zone_Data (Zone_File &file, Zone_Data &zone_rec)
{
	if (Data_Service::Get_Zone_Data (file, zone_rec)) {
		int zone = file.Get_Integer (zone_field);

		org_db.Copy_Fields (file);
		org_db.Write_Record (zone);

		des_db.Copy_Fields (file);
		des_db.Write_Record (zone);
		return (true);
	}
	return (false);
}
