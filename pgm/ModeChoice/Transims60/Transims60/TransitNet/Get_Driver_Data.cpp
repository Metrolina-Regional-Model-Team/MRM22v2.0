//*********************************************************
//	Get_Drive_Data.cpp - read the transit driver file
//*********************************************************

#include "TransitNet.hpp"

//---------------------------------------------------------
//	Get_Driver_Data
//---------------------------------------------------------

bool TransitNet::Get_Driver_Data (Driver_File &file, Driver_Data &driver_rec)
{
	if (Data_Service::Get_Driver_Data (file, driver_rec)) {
		int route = file.Route ();
		if (select_routes && !route_range.In_Range (route)) return (false);
		if (delete_route_flag && delete_routes.In_Range (route)) return (false);
		return (true);
	}
	return (false);
}
