//********************************************************* 
//	Park_Demand_File.cpp - parking demand and penalty file
//*********************************************************

#include "Park_Demand_File.hpp"

//-----------------------------------------------------------
//	Park_Demand_File constructors
//-----------------------------------------------------------

Park_Demand_File::Park_Demand_File (Access_Type access, string format) : 
	Db_Header (access, format)
{
	Setup ();
}

Park_Demand_File::Park_Demand_File (string filename, Access_Type access, string format) : 
	Db_Header (access, format)
{
	Setup ();

	Open (filename);
}

Park_Demand_File::Park_Demand_File (Access_Type access, Format_Type format) : 
	Db_Header (access, format)
{
	Setup ();
}

Park_Demand_File::Park_Demand_File (string filename, Access_Type access, Format_Type format) : 
	Db_Header (access, format)
{
	Setup ();

	Open (filename);
}

//-----------------------------------------------------------
//	Setup
//-----------------------------------------------------------

void Park_Demand_File::Setup (void)
{
	File_Type ("Parking Demand File");
	File_ID ("Park");

	parking = start = end = demand = capacity = ratio = penalty = -1;
}

//---------------------------------------------------------
//	Create_Fields
//---------------------------------------------------------

bool Park_Demand_File::Create_Fields (void) 
{
	Add_Field ("PARKING", DB_INTEGER, 10);
	Add_Field ("START", DB_TIME, TIME_FIELD_SIZE, Time_Format ());
	Add_Field ("END", DB_TIME, TIME_FIELD_SIZE, Time_Format ());
	Add_Field ("DEMAND", DB_INTEGER, 10, VEHICLES);
	Add_Field ("CAPACITY", DB_INTEGER, 10, VEHICLES);
	Add_Field ("RATIO", DB_DOUBLE, 8.2);
	Add_Field ("PENALTY", DB_INTEGER, 10, IMPEDANCE);

	return (Set_Field_Numbers ());
}

//-----------------------------------------------------------
//	Set_Field_Numbers
//-----------------------------------------------------------

bool Park_Demand_File::Set_Field_Numbers (void)
{
	//---- required fields ----

	parking = Required_Field (PARKING_FIELD_NAMES);

	if (parking < 0) return (false);

	start = Optional_Field (START_FIELD_NAMES);
	end = Optional_Field (END_FIELD_NAMES);
	demand = Optional_Field ("DEMAND", "VEHICLES", "OCCUPANCY");
	capacity = Optional_Field ("CAPACITY", "SPACE", "SPACES", "CAP", "SIZE");
	ratio = Optional_Field ("RATIO", "V/C", "VC_RATIO", "CAP_FAC");
	penalty = Optional_Field ("PENALTY", "DELAY", "PRICE", "IMP", "IMPEDANCE");

	//---- set default units ----

	Set_Units (start, HOUR_CLOCK);
	Set_Units (end, HOUR_CLOCK);
	Set_Units (demand, VEHICLES);
	Set_Units (capacity, VEHICLES);
	Set_Units (penalty, IMPEDANCE);
	return (true);
}
