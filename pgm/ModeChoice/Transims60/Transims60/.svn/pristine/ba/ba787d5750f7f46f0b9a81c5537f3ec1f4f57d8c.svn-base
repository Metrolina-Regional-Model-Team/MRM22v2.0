//*********************************************************
//	Get_Driver_Data.cpp - read the transit driver file
//*********************************************************

#include "NewFormat.hpp"

//---------------------------------------------------------
//	Get_Driver_Data
//---------------------------------------------------------

bool NewFormat::Get_Driver_Data (Driver_File &file, Driver_Data &driver_rec)
{
	if (!file.Nested ()) {
		if (select_routes && !route_range.In_Range (file.Route ())) return (false);
	}
	return ((Data_Service::Get_Driver_Data (file, driver_rec)));
}
