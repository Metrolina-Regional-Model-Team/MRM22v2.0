//*********************************************************
//	Get_Stop_Data.cpp - read the transit stop file
//*********************************************************

#include "TransitNet.hpp"

//---------------------------------------------------------
//	Get_Stop_Data
//---------------------------------------------------------

bool TransitNet::Get_Stop_Data (Stop_File &file, Stop_Data &stop_rec)
{
	if (Data_Service::Get_Stop_Data (file, stop_rec)) {
		if (select_stops && !stop_range.In_Range (stop_rec.Stop ())) return (false);
		if (delete_stop_flag && delete_stops.In_Range (stop_rec.Stop ())) return (false);
		return (true);
	}
	return (false);
}
