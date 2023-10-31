//*********************************************************
//	Read_Park_Demand.cpp - read the parking demand file
//*********************************************************

#include "Data_Service.hpp"

//------------------------------------------------------
//	Read_Park_Demand
//---------------------------------------------------------

void Data_Service::Read_Park_Demand (Park_Demand_File &file)
{
	int i, num, start, end, count, function;
	double factor, p1, p2, share;

	Time_Periods *time_ptr;
	Parking_Demand_Data park_rec;
	Park_Demand_Ptr demand_ptr;
	Park_Period_Ptr period_ptr;

	//---- store the park demand data ----

	Show_Message (String ("Reading %s -- Record") % file.File_Type ());
	Set_Progress ();
	
	Initialize_Park_Demand (file);
	count = 0;

	time_ptr = park_demand_array.periods;
	function = park_demand_array.Penalty_Function ();

	while (file.Read ()) {
		Show_Progress ();

		park_rec.Clear ();

		if (!Get_Park_Demand_Data (file, park_rec, function)) continue;

		//---- get the time period ----

		if (time_ptr->Period_Range (park_rec.Start (), park_rec.End (), start, end)) {

			p1 = time_ptr->Period_Offset (start, park_rec.Start ());
			p2 = time_ptr->Period_Offset (end, park_rec.End ());
			if (p1 == p2) continue;

			//---- allocate the data to multiple time periods ----

			num = end - start;
			factor = 1.0 / (end - start + p2 - p1);
			
			demand_ptr = park_demand_array.Add_Parking (park_rec.Parking ());

			for (i = start; i <= end; i++) {
				if (i == start && i == end) {
					share = 1.0;
				} else if (i == start) {
					share = (1.0 - p1) * factor;
				} else if (i == end) {
					share = p2 * factor;
				} else {
					share = factor;
				}
		
				//---- process the parking record ----

				period_ptr = &demand_ptr->at (i);

				period_ptr->Demand (park_rec.Demand ());
				period_ptr->Penalty (park_rec.Penalty ());
				count++;
			}
		}
	}
	End_Progress ();
	file.Close ();

	Break_Check (3);
	Print (2, String ("Number of %s Records = %d") % file.File_Type () % Progress_Count ());

	if (count && count != Progress_Count ()) {
		Print (1, String ("Number of %s Data Records = %d") % file.File_ID () % count);
	}
	if (count > 0) System_Data_True (PARK_DEMAND);
}

//---------------------------------------------------------
//	Initialize_Park_Demand
//---------------------------------------------------------

void Data_Service::Initialize_Park_Demand (Park_Demand_File &file)
{
	Required_File_Check (file, PARKING);
	
	if (System_Data_Reserve (PARK_DEMAND) == 0) return;

	if (park_demand_array.size () == 0) {
		if (Sum_Flow_Flag ()) {
			park_demand_array.periods = &sum_periods;
		} else {
			park_demand_array.periods = &time_periods;
		}
	}
}

//---------------------------------------------------------
//	Get_Park_Demand_Data
//---------------------------------------------------------

bool Data_Service::Get_Park_Demand_Data (Park_Demand_File &file, Parking_Demand_Data &park_rec, int function)
{
	int parking, penalty, index, type;
	double ratio, pen;

	Int_Map_Itr map_itr;
	Parking_Data *parking_ptr;
	Park_Nest_Itr park_itr;

	parking = file.Parking ();
	if (parking <= 0) return (false);

	map_itr = parking_map.find (parking);

	if (map_itr == parking_map.end ()) {
		Warning (String ("Parking Demand Lot %d was Not Found") % parking);
		return (false);
	}
	index = map_itr->second;
	parking_ptr = &parking_array [index];

	penalty = Round (file.Penalty ());

	park_rec.Parking (index);
	park_rec.Start (file.Start ());
	park_rec.End (file.End ());
	park_rec.Demand (file.Demand ());
	park_rec.Capacity (file.Capacity ());
	park_rec.Penalty (penalty);

	for (park_itr = parking_ptr->begin (); park_itr != parking_ptr->end (); park_itr++) {
		if (park_rec.Start () >= park_itr->Start () && park_rec.End () <= park_itr->End () && park_itr->Space () > 0) {
			park_rec.Capacity (park_itr->Space ());
			break;
		}
	}
	if (function > 0) {
		if (park_rec.Demand () > 0 && park_rec.Capacity () > 0) {
			ratio = (double) park_rec.Demand () / park_rec.Capacity ();

			pen = Scale (functions.Apply_Function (function, ratio));
			if (pen > MAX_PENALTY) {
				pen = MAX_PENALTY;
			} else if (pen < 0) {
				pen = 0;
			}
			park_rec.Penalty ((int) pen);
		} else {
			park_rec.Penalty (0);
		}
	}
	type = park_demand_array.Demand_Type ();

	if (type == PNR_LOTS && parking_ptr->Type () < PARKRIDE) return (false);
	if (type == RAIL_LOTS && parking_ptr->Type () < RAIL_PNR) return (false);
	if (type == CAP_LOTS && park_rec.Capacity () <= 0) return (false);

	return (true);
}
