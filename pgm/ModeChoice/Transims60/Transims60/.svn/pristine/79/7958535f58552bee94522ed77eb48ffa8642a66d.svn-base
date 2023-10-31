//*********************************************************
//	First_Plan.cpp - initialize partitioned file processing
//*********************************************************

#include "Sim_Plan_Step.hpp"
#include "Simulator_Service.hpp"

//---------------------------------------------------------
//	First_Plan
//---------------------------------------------------------

bool Sim_Plan_Step::First_Plan (void)
{
	sim->Show_Message (2, "Positioning Plans -- Time");
	sim->Set_Progress ();

	first = true;
	stat = false;

	if (sim->router_flag) {
		Time_Index time_index;

		for (time_map_itr = sim->plan_time_map.begin (); time_map_itr != sim->plan_time_map.end (); time_map_itr++) {
			time_index = time_map_itr->first;
			sim->Show_Progress (time_index.Start ().Time_String ());

			if (time_index.Start () >= sim->param.end_time_step) break;
			if (time_index.Start () >= sim->time_step) {
				sim->time_step = time_index.Start ();
				stat = true;
				break;
			}
		}
		sim->End_Progress (time_index.Start ().Time_String ());

	} else if (sim->System_File_Flag (PLAN)) {
		Plan_File *plan_file = sim->System_Plan_File ();

		int i, j, num;
		Dtime time;
		Plan_Data *plan_ptr;
		Time_Index *time_ptr;
	
		num_files = plan_file->Num_Parts ();
		first_num = -1;

		file_set.Initialize (plan_file, num_files);
		plan_set.Initialize (num_files);
		time_set.Initialize (num_files);
		next.assign (num_files, -1);

		//---- initialize the first index for each partition -----

		for (num=0; num < num_files; num++) {
			plan_ptr = plan_set [num];
			time_ptr = time_set [num];

			if (file_set [num]->Read_Plan (*plan_ptr)) {
				plan_ptr->Get_Index (*time_ptr);
				stat = true;

				//---- sort the partition numbers by time ----

				if (first_num < 0) {
					first_num = num;
				} else {
					for (i=j=first_num; i >= 0; i = next [j = i]) {
						if (*time_ptr < *time_set [i]) {
							if (i == first_num) {
								next [num] = first_num;
								first_num = num;
							} else {
								next [j] = num;
								next [num] = i;
							}
							break;
						}
						if (next [i] < 0) {
							next [i] = num;
							next [num] = -1;
							break;
						}
					}
				}
			} else {
				time_ptr->Set (MAX_INTEGER, 0, 0);
			}
		}

		//---- check the start time ----

		time = 0;

		while (first_num >= 0) {
			plan_ptr = plan_set [first_num];
			time_ptr = time_set [first_num];

			if (time_ptr->Household () == MAX_INTEGER || plan_ptr->Depart () >= sim->param.end_time_step) break;

			sim->Show_Progress (plan_ptr->Depart ().Time_String ());

			if (plan_ptr->Depart () < time) {
				sim->Error (String ("Plans are Not Time Sorted (%s < %s)") % plan_ptr->Depart ().Time_String () % time.Time_String ());
				return (false);
			}
			if (plan_ptr->Depart () >= sim->time_step) {
				sim->time_step = plan_ptr->Depart ();
				stat = true;
				break;
			}
			time = plan_ptr->Depart ();

			//---- get the next record for the current partition ----

			num = first_num;
			first_num = next [num];

			if (file_set [num]->Read_Plan (*plan_ptr)) {
				plan_ptr->Get_Index (*time_ptr);

				//---- update the record order ---

				if (first_num < 0) {
					first_num = num;
				} else {
					for (i = j = first_num; i >= 0; i = next [j = i]) {
						if (*time_ptr < *time_set [i]) {
							if (i == first_num) {
								next [num] = first_num;
								first_num = num;
							} else {
								next [j] = num;
								next [num] = i;
							}
							break;
						}
						if (next [i] < 0) {
							next [i] = num;
							next [num] = -1;
							break;
						}
					}
				}
			} else {
				time_ptr->Set (MAX_INTEGER, 0, 0);
			}
		}
		sim->End_Progress (time.Time_String ());
	}
	return (stat);
}
