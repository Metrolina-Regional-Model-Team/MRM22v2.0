//*********************************************************
//	Get_Schedule_Data.cpp - read the transit schedule file
//*********************************************************

#include "NewFormat.hpp"

//---------------------------------------------------------
//	Get_Schedule_Data
//---------------------------------------------------------

bool NewFormat::Get_Schedule_Data (Schedule_File &file, Schedule_Data &sched_rec)
{
	if (!file.Nested ()) {
		if (select_routes && !route_range.In_Range (file.Route ())) return (false);
	}
	return (Data_Service::Get_Schedule_Data (file, sched_rec));
}
