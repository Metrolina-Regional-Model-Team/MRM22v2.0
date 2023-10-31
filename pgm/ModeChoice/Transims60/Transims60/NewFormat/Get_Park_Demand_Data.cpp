//*********************************************************
//	Get_Park_Demand_Data.cpp - read the parking demand file
//*********************************************************

#include "NewFormat.hpp"

//---------------------------------------------------------
//	Get_Park_Demand_Data
//---------------------------------------------------------

bool NewFormat::Get_Park_Demand_Data (Park_Demand_File &file, Parking_Demand_Data &park_rec, int function)
{
	if (select_start_times && !start_range.In_Range (file.Start ())) return (false);
	if (select_end_times && !end_range.In_Range (file.End ())) return (false);
	if (select_parking && !parking_range.In_Range (file.Parking ())) return (false);

	return (Data_Service::Get_Park_Demand_Data (file, park_rec, function));
}

