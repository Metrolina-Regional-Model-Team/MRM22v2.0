//*********************************************************
//	Park_Demand_Data.hpp - parking demand and penality data
//*********************************************************

#ifndef PARK_DEMAND_DATA_HPP
#define PARK_DEMAND_DATA_HPP

#include "APIDefs.hpp"
#include "Execution_Service.hpp"
#include "Data_Pack.hpp"
#include "Time_Periods.hpp"
#include "Dtime.hpp"

#define MAX_PENALTY  1000000

#include <vector>
using namespace std;

//---------------------------------------------------------
//	Parking_Demand_Data class definition
//---------------------------------------------------------

class SYSLIB_API Parking_Demand_Data
{
public:
	Parking_Demand_Data (void)              { Clear (); }

	int    Parking (void)                   { return (parking); }
	Dtime  Start (void)                     { return (start); }
	Dtime  End (void)                       { return (end); }
	int    Demand (void)                    { return (demand); }
	int    Capacity (void)                  { return (capacity); }
	int    Penalty (void)                   { return (penalty); }
	
	void   Parking (int value)              { parking = value; }
	void   Start (Dtime value)              { start = value; }
	void   End (Dtime value)                { end = value; }
	void   Demand (int value)               { demand = value; }
	void   Capacity (int value)             { capacity = value; }
	void   Penalty (int value)              { penalty = value; }

	void  Clear (void)
	{
		parking = -1; start = end = 0; demand = capacity = penalty = 0; 
	}	
private:
	int    parking;
	Dtime  start;
	Dtime  end;
	int    demand;
	int    capacity;
	int    penalty;
};

typedef vector <Parking_Demand_Data>    Parking_Demand_Array;
typedef Parking_Demand_Array::iterator  Parking_Demand_Itr;
typedef Parking_Demand_Array::pointer   Parking_Demand_Ptr;

//---------------------------------------------------------
//	Park_Period_Data class definition
//---------------------------------------------------------

class SYSLIB_API Park_Period_Data
{
public:
	Park_Period_Data (void)                { Clear (); }

	int    Demand (void)                   { return (demand); }
	int    Penalty (void)                  { return (penalty); }
	
	void   Demand (int value)              { demand = value; }
	void   Penalty (int value)             { penalty = value; }
    
    void   Add_Demand (int value)          { demand += value; }
	void   Add_Penalty (int value)         { penalty += value; }
	
	void   Max_Demand (int value)          { if (value > demand) demand = value; }
	void   Max_Penalty (int value)         { if (value > penalty) penalty = value; }

	void   Clear (void)                    { demand = penalty = 0; }

private:
	int   demand;
	int   penalty;
};

typedef vector <Park_Period_Data>    Park_Period_Array;
typedef Park_Period_Array::iterator  Park_Period_Itr;
typedef Park_Period_Array::pointer   Park_Period_Ptr;

//---------------------------------------------------------
//	Park_Demand_Period_Data class definition
//---------------------------------------------------------

class SYSLIB_API Park_Demand_Data : public Park_Period_Array
{
public:
	Park_Demand_Data (void)    { Clear (); }

	int  Parking (void)        { return (parking); }

	void Parking (int value)   { parking = value; }

	void Clear (void)          { parking = 0; }

private:
	int parking;
};

//---------------------------------------------------------
//	Park_Demand_Array class definition
//---------------------------------------------------------

class SYSLIB_API Park_Demand_Array : public vector <Park_Demand_Data>
{
public:
	Park_Demand_Array (void)  { periods = 0;  pen_function = 0;  type = -1; }
	
	void Initialize (void);

	bool Check_Parking_Type (int parking);

	Park_Demand_Data * Add_Parking (int parking);
	Park_Demand_Data * Get_Parking (int parking);

	int  Penalty (int parking, Dtime time);
	int  Parking_Duration (int parking, Dtime time, Dtime duration);

	int  Demand_Type (void)                    { return (type); }
	void Demand_Type (Park_Demand_Type code)   { type = code; }

	int  Penalty_Function (void)               { return (pen_function);	}
	void Penalty_Function (int number)         { pen_function = number;	}

	double Update_Penalties (bool zero_flag = true);

	void Total_Penalty (double value)          { total_penalty = value; }
	double Total_Penalty (void)                { return (total_penalty); }

	void Zero_Demand (void);
	void Zero_Penalty (void);

	void Replicate (Park_Demand_Array &park_demand_array);

	void Copy_Demand_Data (Park_Demand_Array &park_demand_array, bool zero_flag = false);
	void Copy_Penalty_Data (Park_Demand_Array &park_demand_array, bool zero_flag = true);

	void Add_Demand (Park_Demand_Array &park_demand_array, bool zero_flag = false);
	void Add_Penalty (Park_Demand_Array &park_demand_array, bool zero_flag = false);

	int  Start_Period (Dtime start)             { return (periods->Period (start));	}
	int  End_Period (Dtime end)                 { return (periods->Period (end)); }
	int  Num_Periods (void)                     { return (periods->Num_Periods ());	}

	Time_Periods * periods;

private:
	int pen_function, type;
	Int_Map lot_map;
	double total_penalty, previous_total;
};

typedef Park_Demand_Array::iterator  Park_Demand_Itr;
typedef Park_Demand_Array::pointer   Park_Demand_Ptr;

#endif

