//*********************************************************
//	Plan_Skim_Data.hpp - travel plan skim classes
//*********************************************************

#ifndef PLAN_SKIM_DATA_HPP
#define PLAN_SKIM_DATA_HPP

#include "APIDefs.hpp"
#include "Trip_Data.hpp"
#include "Plan_Skim_File.hpp"

#include <vector>
using namespace std;

//---------------------------------------------------------
//	Plan_Skim_Data Class definition
//---------------------------------------------------------

class SYSLIB_API Plan_Skim_Data : public Trip_Data 
{
public:
	Plan_Skim_Data ();

	//---- get/put functions ----

	void Get_Data (Plan_Data &plan);
	void Put_Data (Plan_Data &plan);
	void Put_Data (Plan_Skim_Base &file);
	void Add_Leg (Plan_Data &plan);
	void Add_Leg (Plan_Skim_Base &file);

	Dtime    Depart (void)                  { return (depart); }
	Dtime    Arrive (void)                  { return (arrive); }
	Dtime    Activity (void)                { return (activity); }
	Dtime    Walk (void)                    { return (Dtime ((int) walk)); }
	Dtime    Drive (void)                   { return (drive); }
	Dtime    Transit (void)                 { return (transit); }
	Dtime    Wait (void)                    { return (wait); }
	Dtime    Other (void)                   { return (Dtime ((int) other)); }
	int      Length (void)                  { return (length); }
	int      Cost (void)                    { return (cost); }
	unsigned Impedance (void)               { return (impedance); }
	int      Transfers (void)               { return (transfers); }
	Dtime    Xfer_Wait (void)               { return (xwait); }
	int      Parking (void)                 { return (parking); }
	int      Num_Legs (void)                { return (num_legs); }

	void     Depart (Dtime value)           { depart = value; }
	void     Arrive (Dtime value)           { arrive = value; }
	void     Activity (Dtime value)         { activity = value; }
	void     Walk (Dtime value)             { walk = value; }
	void     Drive (Dtime value)            { drive = value; }
	void     Transit (Dtime value)          { transit = value; }
	void     Wait (Dtime value)             { wait = value; }
	void     Other (Dtime value)            { other = value; }
	void     Length (int value)             { length = value; }
	void     Cost (int value)               { cost = value; }
	void     Impedance (unsigned value)     { impedance = value; }
	void     Transfers (int value)          { transfers = (short) value; }
	void     Xfer_Wait (Dtime value)        { xwait = value; }
	void     Parking (int value)            { parking = value; }
	void     Num_Legs (int value)           { num_legs = (short) value; }

	void     Length (double value)          { length = exe->Round (value); }
	void     Cost (double value)            { cost = exe->Round (value); }

	void     Clear (void)
	{
		depart = arrive = activity = walk = drive = transit = wait = other = xwait = 0; 
		length = cost = 0; impedance = 0; transfers = num_legs = 0;  parking = -1; Trip_Data::Clear ();
	}

	void operator = (Trip_Data data)        { *((Trip_Data *) this) = data; }

	Time_Index Get_Time_Index (void)        { return (Time_Index (depart, Household (), Person ())); }

	void Get_Index (Trip_Index &index)      { Trip_Data::Get_Index (index); }
	void Get_Index (Time_Index &index)      { index.Set (depart, Household (), Person ()); }

	bool Internal_IDs (void);
	bool External_IDs (void);

private:
	Dtime     depart;
	Dtime     arrive;
	Dtime     activity;
	Dtime     walk;
	Dtime     wait;
	Dtime     drive;
	Dtime     transit;
	Dtime     other;
	int       cost;
	int       length;
	unsigned  impedance;
	Dtime     xwait;
	int       parking;
	short     transfers;
	short     num_legs;
};

typedef Vector <Plan_Skim_Data>   Plan_Skim_Array;
typedef Plan_Skim_Array::iterator Plan_Skim_Itr;
typedef Plan_Skim_Data *          Plan_Skim_Ptr;

#endif
