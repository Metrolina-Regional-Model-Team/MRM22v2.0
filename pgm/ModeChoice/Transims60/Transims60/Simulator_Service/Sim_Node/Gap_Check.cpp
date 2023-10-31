//*********************************************************
//	Gap_Check.cpp - check the speed of the vehicle ahead
//*********************************************************

#include "Sim_Node_Process.hpp"
#include "Simulator_Service.hpp"

//---------------------------------------------------------
//	Gap_Check
//---------------------------------------------------------

int Sim_Node_Process::Gap_Check (Sim_Dir_Ptr sim_dir_ptr, int move, int lane, int cell)
{
	int m, c, max_m, traveler, speed;
	Int_Itr int_itr;

	max_m = move + (int) sim->gap_speed.size ();

	for (m = 0, c = cell + 1; m <= max_m; m++, c++) {
		if (c > sim_dir_ptr->Max_Cell ()) break;
		traveler = sim_dir_ptr->Get (lane, c);
		if (traveler == 0) continue;

		if (traveler > 0) {
			speed = sim->sim_travel_array [traveler].Speed ();
			for (int_itr = sim->gap_speed.begin (); int_itr != sim->gap_speed.end (); int_itr++, m--) {
				if (speed < *int_itr) break;
			}
			if (m < move) move = m;
		}
		break;
	}
	return (move);
}


