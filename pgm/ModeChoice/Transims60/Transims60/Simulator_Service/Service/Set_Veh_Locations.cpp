//*********************************************************
//	Set_Veh_Locations.cpp - place vehicles on links
//*********************************************************

#include "Simulator_Service.hpp"

//---------------------------------------------------------
//	Set_Vehicle_Locations
//---------------------------------------------------------

void Simulator_Service::Set_Vehicle_Locations (void)
{
	int traveler, vehicle, cells, index, lane, cell;

	Sim_Travel_Itr sim_travel_itr;
	Sim_Plan_Ptr sim_plan_ptr;
	Person_Index person_index;
	Person_Map_Stat person_stat;
	Vehicle_Index veh_index;
	Vehicle_Map_Itr veh_map_itr;
	Veh_Type_Data *veh_type_ptr;
	Sim_Veh_Ptr sim_veh_ptr;
	Sim_Dir_Ptr sim_dir_ptr;
	
	sim->Set_Progress ();

	person_map.clear ();

	for (sim_travel_itr = sim_travel_array.begin (); sim_travel_itr != sim_travel_array.end (); sim_travel_itr++) {
		person_index.Household (sim_travel_itr->Household ());
		person_index.Person (sim_travel_itr->Person ());

		traveler = sim_travel_itr->Traveler ();
		if (traveler < 2) continue;

		person_stat = sim->person_map.insert (Person_Map_Data (person_index, traveler));
		if (!person_stat.second) continue;

		if (sim_travel_itr->Vehicle () == 0 || sim_travel_itr->Plan_Index () < 0) continue;

		sim_plan_ptr = sim_travel_itr->Get_Plan ();
		if (sim_plan_ptr == 0) continue;

		//---- find the vehicle ----

		vehicle = sim_plan_ptr->Vehicle ();

		if (vehicle > 0) {
			veh_index.Household (sim_travel_itr->Household ());
			veh_index.Vehicle (vehicle);

			veh_map_itr = sim_veh_map.find (veh_index);
#ifdef CHECK
			if (veh_map_itr == sim_veh_map.end ()) {
				sim->Error (String ("Simulator_Service::Set_Vehicle_Locations: Sim_Veh_Map %d %d") % veh_index.Household () % vehicle);
			}
#endif
			vehicle = veh_map_itr->second;
#ifdef CHECK
			if (vehicle != sim_travel_itr->Vehicle ()) {
				sim->Error (String ("Simulator_Service::Set_Vehicle_Locations: Vehicle %d vs %d") % vehicle % sim_travel_itr->Vehicle ());
			}
#endif
			if (sim_plan_ptr->Veh_Type () >= 0) {
				veh_type_ptr = &veh_type_array [sim_plan_ptr->Veh_Type ()];
				cells = veh_type_ptr->Cells ();
			} else {
				cells = 1;
			}
			while (cells-- > 0) {
				Show_Progress ();

				sim_veh_ptr = &sim_veh_array [vehicle++];
				if (sim_veh_ptr->Parked ()) continue;
#ifdef CHECK
				if (sim_veh_ptr->link < 0 || sim_veh_ptr->link >= (int) sim_dir_array.size ()) {
					sim->Error (String ("Simulator_Service::Set_Vehicle_Locations: Link %d vs %d") % sim_veh_ptr->link % sim_dir_array.size ());
				}
#endif
				sim_dir_ptr = &sim_dir_array [sim_veh_ptr->link];

				lane = sim_veh_ptr->lane;
				if (lane < 0 || lane >= sim_dir_ptr->Lanes ()) continue;

				cell = Offset_Cell (sim_veh_ptr->offset);
				if (cell < 0 || cell > sim_dir_ptr->Max_Cell ()) continue;

				index = sim_dir_ptr->Index (lane, cell);
				if (cells == 0) {
					sim_dir_ptr->Set (index, traveler);
				} else {
					sim_dir_ptr->Set (index, -traveler);
				}
			}
		}
	}
}
