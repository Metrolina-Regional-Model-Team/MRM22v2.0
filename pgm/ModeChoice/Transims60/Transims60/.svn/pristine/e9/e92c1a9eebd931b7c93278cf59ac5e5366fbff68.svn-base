//*********************************************************
//	Restart_Setup.cpp - initialize the restart process
//*********************************************************

#include "Simulator.hpp"

//---------------------------------------------------------
//	Restart_Setup
//---------------------------------------------------------

void Simulator::Restart_Setup (void)
{
	Show_Message (2, "Reading Backup Data");

	Show_Progress ("-- Travelers");
	sim_travel_array.UnPack (restart_file);

	Show_Progress ("-- Plans");
	sim_plan_array.UnPack (restart_file);
	sim_leg_array.UnPack (restart_file);

	Show_Progress ("-- Vehicles");
	sim_veh_array.UnPack (restart_file);
	sim_veh_map.UnPack (restart_file);

	restart_file.Close ();

	Show_Message (0, " -- Locations");

	Set_Vehicle_Locations ();

	time_step = restart_time;
	End_Progress ();
}

