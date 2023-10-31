//*********************************************************
//	Parking_Penalty.cpp - parking penalty methods
//*********************************************************

#include "Router_Service.hpp"


//---------------------------------------------------------
//	Set_Park_Penalty 
//---------------------------------------------------------

void Router_Service::Set_Park_Penalty (void)
{
	//---- initialize the penalty field ----

	if (Sum_Flow_Flag ()) {
		park_period_array.Initialize (&sum_periods);
	} else {
		park_period_array.Initialize (&time_periods);
	}
	if (!park_pen_file.Is_Open ()) return;

	//---- process each parking penalty file record ----
	
	int parking, demand, penalty, num_penalty, period, num_period, index;
	double ratio, pen;

	Int_Map_Itr map_itr;
	Park_Period *period_ptr;
	Park_Penalty *pen_ptr;
	Parking_Data *parking_ptr;
	Park_Nest_Itr park_itr;

	num_penalty = 0;

	while (park_pen_file.Read ()) {
		Show_Progress ();

		parking = park_pen_file.Parking ();
		if (parking <= 0) continue;

		demand = park_pen_file.Demand ();
		penalty = Round (park_pen_file.Penalty ());
		if (demand <= 0 && penalty <= 0) continue;

		map_itr = parking_map.find (parking);

		if (map_itr == parking_map.end ()) {
			Warning (String ("Parking Penalty Lot %d was Not Found") % parking);
			continue;
		}
		index = map_itr->second;

		period = park_period_array.Start_Period (park_pen_file.Start ());
		num_period = park_period_array.End_Period (park_pen_file.End ());

		if (period < 0) period = 0;
		if (num_period < 0) num_period = park_period_array.periods->Num_Periods () - 1;

		if (park_pen_function > 0 && demand > 0) {
			parking_ptr = &parking_array [index];

			for (park_itr = parking_ptr->begin (); park_itr != parking_ptr->end (); park_itr++) {
				if (park_pen_file.Start () >= park_itr->Start () && park_pen_file.End () <= park_itr->End () && park_itr->Space () > 0) {
					ratio = (double) demand / park_itr->Space ();
					pen = Scale (functions.Apply_Function (park_pen_function, ratio));
					if (pen > MAX_PENALTY) {
						pen = MAX_PENALTY;
					}
					if (pen > 0 && pen > penalty) {
						penalty = (int) pen;
					}
					break;
				}
			}
		}
		for (; period <= num_period; period++) {
			period_ptr = park_period_array.Period_Ptr (period);

			pen_ptr = period_ptr->Data_Ptr (index);

			pen_ptr->Max_Penalty (penalty);
		}
		num_penalty++;
	}
	Print (2, "Number of Parking Penalty Records = ") << num_penalty;
	park_pen_file.Close ();
}

//---------------------------------------------------------
//	Update_Park_Penalty 
//---------------------------------------------------------

void Router_Service::Update_Park_Penalty (void)
{
	if (park_pen_function <= 0) return;

	int index, period, num_penalty;
	double ratio, penalty;
	Dtime start, end, tod;
	Park_Period_Itr period_itr;
	Penalty_Itr pen_itr;
	Parking_Data *parking_ptr;
	Park_Nest_Itr park_itr;

	num_penalty = 0;

	for (period = 0, period_itr = park_period_array.begin (); period_itr != park_period_array.end (); period_itr++, period++) {
		park_period_array.periods->Period_Range (period, start, end);

		for (index = 0, pen_itr = period_itr->begin (); pen_itr != period_itr->end (); pen_itr++, index++) {
			if (pen_itr->Demand () > 0) {
				parking_ptr = &parking_array [index];

				for (park_itr = parking_ptr->begin (); park_itr != parking_ptr->end (); park_itr++) {
					if (start >= park_itr->Start () && end <= park_itr->End () && park_itr->Space () > 0) {
						ratio = (double) pen_itr->Demand () / park_itr->Space ();
						penalty = functions.Apply_Function (park_pen_function, ratio);
						if (penalty > MAX_PENALTY) {
							penalty = MAX_PENALTY;
						}
						if (penalty > 0) {
							pen_itr->Penalty (Round (penalty));
							num_penalty++;
						}
						break;
					}
				}
			}
		}
	}
	Print (2, "Number of Parking Penalty Updates = ") << num_penalty;
}

//---------------------------------------------------------
//	Write_Park_Penalty 
//---------------------------------------------------------

void Router_Service::Write_Park_Penalty (void)
{
	if (!new_park_pen_file.Is_Open ()) return;

	int index, period, num_penalty;
	Dtime start, end;
	Park_Period_Itr period_itr;
	Penalty_Itr park_itr;
	Parking_Data *parking_ptr;

	Show_Message (String ("Writing %s -- Record") % new_park_pen_file.File_Type ());
	Set_Progress ();

	num_penalty = 0;

	for (period = 0, period_itr = park_period_array.begin (); period_itr != park_period_array.end (); period_itr++, period++) {
		park_period_array.periods->Period_Range (period, start, end);

		for (index = 0, park_itr = period_itr->begin (); park_itr != period_itr->end (); park_itr++, index++) {
			Show_Progress ();

			if (park_itr->Demand () > 0 || park_itr->Penalty () > 0) {
				parking_ptr = &parking_array [index];

				new_park_pen_file.Parking (parking_ptr->Parking ());
				new_park_pen_file.Start (start);
				new_park_pen_file.End (end);
				new_park_pen_file.Demand (park_itr->Demand ());
				new_park_pen_file.Penalty (Resolve (park_itr->Penalty ()));

				new_park_pen_file.Write ();
				num_penalty++;
			}
		}
	}
	End_Progress ();

	Print (2, "Number of New Parking Penalty Records = ") << num_penalty;
	new_park_pen_file.Close ();
}
