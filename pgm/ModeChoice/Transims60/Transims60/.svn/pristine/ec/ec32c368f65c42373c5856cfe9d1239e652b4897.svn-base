//*********************************************************
//	Park_Demand_Data.cpp - parking demand and penalty data
//*********************************************************

#include "Park_Demand_Data.hpp"
#include "Data_Service.hpp"

//---------------------------------------------------------
//	Initialize
//---------------------------------------------------------

void Park_Demand_Array::Initialize (void)
{
	int index;
	Parking_Itr itr;
	Park_Nest_Itr park_itr;

	total_penalty = previous_total = 0;

	if (type < 0) type = CAP_LOTS;

	if (periods == 0) {
		if (dat->Sum_Flow_Flag ()) {
			periods = &dat->sum_periods;
		} else {
			periods = &dat->time_periods;
		}
	}
	for (index=0, itr = dat->parking_array.begin (); itr != dat->parking_array.end (); itr++, index++) {
		if (type == 0 || (type == PNR_LOTS && itr->Type () >= PARKRIDE) || 
			(type == RAIL_LOTS && itr->Type () >= RAIL_PNR) || (type == CAP_LOTS && itr->Capacity () > 0)) {
			Add_Parking (index);
		} else if (type == CAP_LOTS && itr->size () > 0) {
			for (park_itr = itr->begin (); park_itr != itr->end (); park_itr++) {
				if (park_itr->Space () > 0) {
					Add_Parking (index);
					break;
				}
			}
		}
	}
}

//---------------------------------------------------------
//	Check_Parking_Type 
//---------------------------------------------------------

bool Park_Demand_Array::Check_Parking_Type (int parking)
{
	if (lot_map.find (parking) != lot_map.end ()) return (true);
	if (type < 0) return (false);
	if (type > 0) {
		Parking_Data *ptr = &dat->parking_array [parking];

		if (type == PNR_LOTS && ptr->Type () < PARKRIDE) return (false);
		if (type == RAIL_LOTS && ptr->Type () < RAIL_PNR) return (false);
		if (type == CAP_LOTS && ptr->Capacity () == 0) {
			bool flag = false;
			Park_Nest_Itr park_itr;

			for (park_itr = ptr->begin (); park_itr != ptr->end (); park_itr++) {
				if (park_itr->Space () > 0) {
					flag = true;
					break;
				}
			}
			if (!flag) return (false);
		}
	}
	Add_Parking (parking);
	return (true);
}

//---------------------------------------------------------
//	Add_Parking
//---------------------------------------------------------

Park_Demand_Data * Park_Demand_Array::Add_Parking (int parking)
{
	Int_Map_Itr itr = lot_map.find (parking);

	if (itr == lot_map.end ()) {
		int index = (int) lot_map.size ();
		lot_map.insert (Int_Map_Data (parking, index));

		Park_Period_Data period_data;
		Park_Demand_Data demand_data, *demand_ptr;

		demand_data.Parking (parking);

		push_back (demand_data);
		demand_ptr = &at (index);

		demand_ptr->assign (periods->Num_Periods (), period_data);
		return (demand_ptr);
	} else {
		return (&at (itr->second));
	}
}

//---------------------------------------------------------
//	Get_Parking
//---------------------------------------------------------

Park_Demand_Data * Park_Demand_Array::Get_Parking (int parking)
{
	Int_Map_Itr itr = lot_map.find (parking);

	if (itr == lot_map.end ()) {
		return (0);
	} else {
		return (&at (itr->second));
	}
}

//---------------------------------------------------------
//	Penalty
//---------------------------------------------------------

int Park_Demand_Array::Penalty (int parking, Dtime time)
{
	Park_Demand_Ptr ptr = Get_Parking (parking);

	if (ptr == 0) return (0);

	int period = periods->Period (time);

	if (period < 0) return (0);

	return (ptr->at (period).Penalty ());
}

//---------------------------------------------------------
//	Parking_Duration
//---------------------------------------------------------

int Park_Demand_Array::Parking_Duration (int parking, Dtime time, Dtime duration)
{
	Park_Demand_Ptr ptr = Get_Parking (parking);
	if (ptr == 0) return (0);

	int period = periods->Period (time);
	if (period < 0) period = 0;

	int last_period = periods->Period (time + duration);
	if (last_period < 0) last_period = periods->Num_Periods () - 1;

	int penalty = ptr->at (period).Penalty ();
	total_penalty += penalty;

	for (; period <= last_period; period++) {
		ptr->at (period).Add_Demand (1);
	}
	return (penalty);
}

//---------------------------------------------------------
//	Update_Penalties
//---------------------------------------------------------

double Park_Demand_Array::Update_Penalties (bool zero_flag)
{
	if (pen_function <= 0) return (0);

	int i, p, capacity, demand;
	double ratio, penalty, gap;

	Dtime start_time, end_time, tod;
	Park_Demand_Itr demand_itr;
	Park_Period_Itr period_itr;
	Parking_Data *parking_ptr;
	Park_Nest_Itr park_itr;

	if (previous_total == total_penalty) {
		gap = 0.0;
	} else if (previous_total == 0.0) {
		gap = 1.0;
	} else if (total_penalty > previous_total) {
		gap = (total_penalty - previous_total) / previous_total;
	} else {
		gap = (previous_total - total_penalty) / previous_total;
	}
	previous_total = total_penalty;
	total_penalty = 0;

	for (i=0, demand_itr = begin (); demand_itr != end (); demand_itr++, i++) {
		parking_ptr = &dat->parking_array [demand_itr->Parking ()];

		for (p=0, period_itr = demand_itr->begin (); period_itr != demand_itr->end (); period_itr++, p++) {
			periods->Period_Range (p, start_time, end_time);

			demand = period_itr->Demand ();
			if (zero_flag) period_itr->Demand (0);

			if (demand > 0) {
				capacity = parking_ptr->Capacity ();

				for (park_itr = parking_ptr->begin (); park_itr != parking_ptr->end (); park_itr++) {
					if (start_time >= park_itr->Start () && end_time <= park_itr->End () && park_itr->Space () > 0) {
						capacity = park_itr->Space ();
						break;
					}
				}
				if (capacity > 0) {
					ratio = (double) demand / capacity;

					penalty = exe->functions.Apply_Function (pen_function, ratio);
					if (penalty > MAX_PENALTY) {
						penalty = MAX_PENALTY;
					} else if (penalty < 0) {
						penalty = 0;
					}
					period_itr->Penalty (exe->Round (penalty));
				}
			} else {
				period_itr->Penalty (0);
			}
		}
	}
	return (gap);
}

//---------------------------------------------------------
//	Zero_Demand
//---------------------------------------------------------

void Park_Demand_Array::Zero_Demand (void)
{
	Park_Demand_Itr demand_itr;
	Park_Period_Itr period_itr;

	for (demand_itr = begin (); demand_itr != end (); demand_itr++) {
		for (period_itr = demand_itr->begin (); period_itr != demand_itr->end (); period_itr++) {
			period_itr->Demand (0);
		}
	}
}

//---------------------------------------------------------
//	Zero_Penalty
//---------------------------------------------------------

void Park_Demand_Array::Zero_Penalty (void)
{
	Park_Demand_Itr demand_itr;
	Park_Period_Itr period_itr;

	for (demand_itr = begin (); demand_itr != end (); demand_itr++) {
		for (period_itr = demand_itr->begin (); period_itr != demand_itr->end (); period_itr++) {
			period_itr->Penalty (0);
		}
	}
}

//---------------------------------------------------------
//	Replicate
//---------------------------------------------------------

void Park_Demand_Array::Replicate (Park_Demand_Array &demand_array)
{
	Park_Demand_Itr demand_itr;
	Park_Period_Itr period_itr;

	periods = demand_array.periods;
	lot_map = demand_array.lot_map;
	pen_function = demand_array.pen_function;

	for (demand_itr = demand_array.begin (); demand_itr != demand_array.end (); demand_itr++) {
		push_back (*demand_itr);
	}
}

//---------------------------------------------------------
//	Copy_Demand_Data
//---------------------------------------------------------

void Park_Demand_Array::Copy_Demand_Data (Park_Demand_Array &demand_array, bool zero_flag)
{
	int i, p;

	Park_Demand_Itr demand_itr;
	Park_Demand_Ptr demand_ptr;
	Park_Period_Itr period_itr;
	Park_Period_Ptr period_ptr;

	total_penalty += demand_array.total_penalty;

	for (i=0, demand_itr = begin (); demand_itr != end (); demand_itr++, i++) {
		demand_ptr = &demand_array [i];
		for (p=0, period_itr = demand_itr->begin (); period_itr != demand_itr->end (); period_itr++, p++) {
			period_ptr = &demand_ptr->at (p);
			period_itr->Demand (period_ptr->Demand ());
			period_itr->Penalty (period_ptr->Penalty ());
			if (zero_flag) period_ptr->Demand (0);
		}
	}
}

//---------------------------------------------------------
//	Copy_Penalty_Data
//---------------------------------------------------------

void Park_Demand_Array::Copy_Penalty_Data (Park_Demand_Array &demand_array, bool zero_flag)
{
	int i, p;

	Park_Demand_Itr demand_itr;
	Park_Demand_Ptr demand_ptr;
	Park_Period_Itr period_itr;
	Park_Period_Ptr period_ptr;

	for (i = 0, demand_itr = begin (); demand_itr != end (); demand_itr++, i++) {
		demand_ptr = &demand_array [i];
		for (p = 0, period_itr = demand_itr->begin (); period_itr != demand_itr->end (); period_itr++, p++) {
			period_ptr = &demand_ptr->at (p);
			period_itr->Penalty (period_ptr->Penalty ());
			if (zero_flag) period_ptr->Demand (0);
		}
	}
}

//---------------------------------------------------------
//	Add_Demand
//---------------------------------------------------------

void Park_Demand_Array::Add_Demand (Park_Demand_Array &demand_array, bool zero_flag)
{
	int i, p;

	Park_Demand_Itr demand_itr;
	Park_Demand_Ptr demand_ptr;
	Park_Period_Itr period_itr;
	Park_Period_Ptr period_ptr;
	
	total_penalty += demand_array.total_penalty;

	for (i = 0, demand_itr = begin (); demand_itr != end (); demand_itr++, i++) {
		demand_ptr = &demand_array [i];
		for (p = 0, period_itr = demand_itr->begin (); period_itr != demand_itr->end (); period_itr++, p++) {
			period_ptr = &demand_ptr->at (p);
			period_itr->Add_Demand (period_ptr->Demand ());
			if (zero_flag) period_ptr->Demand (0);
		}
	}
}

//---------------------------------------------------------
//	Merge_Penalty
//---------------------------------------------------------

void Park_Demand_Array::Add_Penalty (Park_Demand_Array &demand_array, bool zero_flag)
{
	int i, p;

	Park_Demand_Itr demand_itr;
	Park_Demand_Ptr demand_ptr;
	Park_Period_Itr period_itr;
	Park_Period_Ptr period_ptr;

	for (i = 0, demand_itr = begin (); demand_itr != end (); demand_itr++, i++) {
		demand_ptr = &demand_array [i];
		for (p = 0, period_itr = demand_itr->begin (); period_itr != demand_itr->end (); period_itr++, p++) {
			period_ptr = &demand_ptr->at (p);
			period_itr->Add_Penalty (period_ptr->Penalty ());
			if (zero_flag) period_ptr->Demand (0);
		}
	}
}
