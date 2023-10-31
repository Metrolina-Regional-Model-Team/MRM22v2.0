//*********************************************************
//	Sim_Dir_Data.cpp - direction link data
//*********************************************************

#include "Sim_Dir_Data.hpp"
#include "Simulator_Service.hpp"

//---------------------------------------------------------
//	Load_Queue
//---------------------------------------------------------

void Sim_Dir_Data::Load_Queue (int traveler)
{
	sim->sim_travel_array [traveler].Next_Load (-1);

	if (first_load < 1) {
		first_load = last_load = traveler;
	} else {
#ifdef CHECK
		if (last_load < 1 || last_load >= (int) sim->sim_travel_array.size ()) {
			sim->Error (String ("Sim_Dir_Data::Load_Queue: Last_Load=%d vs %d") % last_load % sim->sim_travel_array.size ());
		}
#endif
		Sim_Travel_Ptr ptr = &sim->sim_travel_array [last_load];
#ifdef CHECK
		if (ptr->Next_Load () > 0) sim->Error (String ("Sim_Dir_Data::Load_Queue: Next_Load=%d") % ptr->Next_Load ());
#endif
		ptr->Next_Load (traveler);
		last_load = traveler;
	}
}
