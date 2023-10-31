//*********************************************************
//	Write_Park_Demand.cpp - write a new parking demand file
//*********************************************************

#include "Data_Service.hpp"

//---------------------------------------------------------
//	Write_Park_Demand
//---------------------------------------------------------

void Data_Service::Write_Park_Demand (void)
{
	int p, count, function;
	Dtime low, high;

	Int_Map_Itr itr;
	Park_Demand_Ptr demand_ptr;
	Park_Period_Itr period_itr;
	Parking_Demand_Data park_rec;
	
	Park_Demand_File *file = System_Park_Demand_File (true);

	Show_Message (String ("Writing %s -- Record") % file->File_Type ());
	Set_Progress ();

	count = 0;
	function = park_demand_array.Penalty_Function ();

	//---- process parking lots in order ----

	for (itr = parking_map.begin (); itr != parking_map.end (); itr++) {
		demand_ptr = park_demand_array.Get_Parking (itr->second);
		if (demand_ptr == 0) continue;

		park_rec.Parking (itr->second);

		for (p=0, period_itr = demand_ptr->begin (); period_itr != demand_ptr->end (); period_itr++, p++) {
			Show_Progress ();
			park_demand_array.periods->Period_Range (p, low, high);

			park_rec.Start (low);
			park_rec.End (high);

			park_rec.Demand (period_itr->Demand ());
			park_rec.Penalty (period_itr->Penalty ());
			count += Put_Park_Demand_Data (*file, park_rec, function);
		}
	}
	Show_Progress (count);
	End_Progress ();
	file->Close ();
	
	Print (2, String ("%s Records = %d") % file->File_Type () % count);
}

//---------------------------------------------------------
//	Put_Park_Demand_Data
//---------------------------------------------------------

int Data_Service::Put_Park_Demand_Data (Park_Demand_File &file, Parking_Demand_Data &data, int function)
{
	int penalty, capacity;
	double ratio, pen;

	Int_Map_Itr map_itr;
	Parking_Data *parking_ptr;
	Park_Nest_Itr park_itr;

	parking_ptr = &parking_array [data.Parking ()];

	file.Parking (parking_ptr->Parking ());
	file.Start (data.Start ());
	file.End (data.End ());

	file.Demand (data.Demand ());

	capacity = parking_ptr->Capacity ();
	penalty = data.Penalty ();

	for (park_itr = parking_ptr->begin (); park_itr != parking_ptr->end (); park_itr++) {
		if (data.Start () >= park_itr->Start () && data.End () <= park_itr->End () && park_itr->Space () > 0) {
			capacity = park_itr->Space ();
			break;
		}
	}

	if (data.Demand () > 0 && capacity > 0) {
		ratio = (double) data.Demand () / capacity;

		if (function > 0) {
			pen = Scale (functions.Apply_Function (function, ratio));
			if (pen > MAX_PENALTY) {
				pen = MAX_PENALTY;
			} else if (pen < 0) {
				pen = 0.0;
			}
			penalty = (int) pen;
		}
	} else {
		ratio = 0.0;
		if (function > 0) penalty = 0;
	}
	file.Ratio (ratio);
	file.Capacity (capacity);
	file.Penalty (Resolve (penalty));

	if (data.Demand () <= 0 && penalty <= 0) return (0);

	if (!file.Write (false)) {
		Error (String ("Writing %s") % file.File_Type ());
	}
	return (1);
}

