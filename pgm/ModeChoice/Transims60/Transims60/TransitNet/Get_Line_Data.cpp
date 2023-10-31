//*********************************************************
//	Get_Line_Data.cpp - read the transit route file
//*********************************************************

#include "TransitNet.hpp"

//---------------------------------------------------------
//	Get_Line_Data
//---------------------------------------------------------

bool TransitNet::Get_Line_Data (Line_File &file, Line_Data &line_rec)
{
	if (delete_stop_flag && file.Nested ()) {
		if (delete_stops.In_Range (file.Stop ())) return (false);
	}
	if (Data_Service::Get_Line_Data (file, line_rec)) {
		if (select_routes && !route_range.In_Range (line_rec.Route ())) return (false);
		if (delete_route_flag && delete_routes.In_Range (line_rec.Route ())) return (false);
		return (true);
	}
	return (false);
}
