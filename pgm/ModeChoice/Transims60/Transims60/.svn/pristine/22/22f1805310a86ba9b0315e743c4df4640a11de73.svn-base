//*********************************************************
//	Get_Line_Data.cpp - read the transit route file
//*********************************************************

#include "NewFormat.hpp"

//---------------------------------------------------------
//	Get_Line_Data
//---------------------------------------------------------

bool NewFormat::Get_Line_Data (Line_File &file, Line_Data &line_rec)
{
	if (!file.Nested ()) {
		if (select_routes && !route_range.In_Range (file.Route ())) return (false);
		if (line_rec.Mode () >= NO_TRANSIT && line_rec.Mode () < ANY_TRANSIT && !select_transit [file.Mode ()]) return (false);
		if (select_vehicles && !vehicle_range.In_Range (file.Type ())) return (false);
	}
	return ((Data_Service::Get_Line_Data (file, line_rec)));
}
