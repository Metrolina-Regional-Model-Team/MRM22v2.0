//*********************************************************
//	Part_Processor.cpp - partition processing thread
//*********************************************************

#include "Converge_Service.hpp"

//---------------------------------------------------------
//	Part_Processor constructor
//---------------------------------------------------------

Converge_Service::Part_Processor::Part_Processor (void)
{
	exe = 0;
	num_processors = num_path_builders = 0;
	plan_process = 0;

#ifdef THREADS
	trip_queue = 0;
	part_thread = 0;
#endif
}

//---------------------------------------------------------
//	Part_Processor destructor
//---------------------------------------------------------

Converge_Service::Part_Processor::~Part_Processor (void)
{
	if (plan_process != 0) {
		delete plan_process;
	}
#ifdef THREADS
	if (trip_queue != 0) {
		for (int i=0; i < num_processors; i++) {
			if (trip_queue [i] != 0) delete trip_queue [i];
		}
		delete [] trip_queue;
	}
	if (part_thread != 0) {
		for (int i=0; i < num_processors; i++) {
			if (part_thread [i] != 0) delete part_thread [i];
		}
		delete part_thread;
	}
#endif
}

//---------------------------------------------------------
//	Initialize
//---------------------------------------------------------

bool Converge_Service::Part_Processor::Initialize (Converge_Service *_exe)
{
	exe = _exe;
	if (exe == 0) return (false);

	num_path_builders = exe->Num_Threads ();

#ifdef THREADS

	//---- allocate threads ----

	if (exe->Num_Threads () > 1) {
		if (exe->Memory_Flag ()) {
			num_processors = 1;
			num_path_builders = exe->Num_Threads ();
		} else if (exe->Num_Partitions () < 2) {
			num_processors = 1;
			if (exe->Num_Threads () > 2) {
				if (exe->Num_Threads () > 4) {
					num_path_builders = exe->Num_Threads () - 1;
				} else {
					num_path_builders = exe->Num_Threads ();
				}
			} else {
				num_path_builders = 2;
			}
		} else if (exe->Num_Threads () >= exe->Num_Partitions ()) {
			num_processors = exe->Num_Partitions ();
			num_path_builders = exe->Num_Threads () / num_processors;
			if (num_path_builders < 2) {
				if ((num_processors % 2) == 0) {
					num_processors /= 2;
					num_path_builders = 2;
				} else {
					num_path_builders = 1;
				}
			}
		} else if (exe->trip_set_flag) {
			num_processors = exe->Num_Threads ();
			num_path_builders = 1;
		} else if (exe->Num_Threads () > 4) {
			num_processors = exe->Num_Threads () / 3;
			if (num_processors < 2) num_processors = 2;
			num_path_builders = exe->Num_Threads () / num_processors;
			if (num_path_builders < 2) num_path_builders = 2;
		} else {
			num_processors = 1;
			num_path_builders = exe->Num_Threads ();
		}
		exe->Write (2, "Number of File Partition Processors = ") << num_processors;
		exe->Write (1, "Number of Path Builders per Process = ") << num_path_builders;
		exe->Write (1);
	} else {
		num_processors = 1;
		num_path_builders = 1;
	}
	exe->Sub_Threads (num_path_builders);

	//---- create processing processors ----

	if (num_processors > 1) {
		int i, j;
		part_thread = new Part_Thread * [num_processors];

		for (i=0; i < num_processors; i++) {
			part_thread [i] = new Part_Thread (i, this);
		}
		if (exe->trip_flag && !exe->trip_set_flag) {
			for (i=j=0; i < exe->Num_Partitions (); i++, j++) {
				if (j == num_processors) j = 0;
				partition_map.push_back (j);
			}
			trip_queue = new Plan_Ptr_Queue * [num_processors];

			for (i=0; i < num_processors; i++) {
				trip_queue [i] = new Plan_Ptr_Queue ();
			}
			return (false);
		}
		return (true);
	} 
#endif
	exe->Sub_Threads (num_path_builders);
	plan_process = new Plan_Processor (exe);
	return (false);
}

//---------------------------------------------------------
//	Part_Processor -- Read_Trips
//---------------------------------------------------------

void Converge_Service::Part_Processor::Read_Trips (void)
{
	int p;

#ifdef THREADS
	if (num_processors > 1) {
		if (exe->thread_flag) {
			partition_queue.Reset ();

			for (p=0; p < exe->num_file_sets; p++) {
				partition_queue.Put (p);
			}
			partition_queue.End_of_Queue ();

			for (p=0; p < num_processors; p++) {
				threads.push_back (thread (ref (*(part_thread [p]))));
			}
			threads.Join_All ();
		} else {
			for (p=0; p < num_processors; p++) {
				threads.push_back (thread (ref (*(part_thread [p]))));
			}
			exe->Read_Trips (0);

			for (p=0; p < num_processors; p++) {
				trip_queue [p]->Exit_Queue ();
			}
			threads.Join_All ();
		}
		if (exe->Flow_Updates () || exe->Time_Updates ()) {
			for (p=0; p < num_processors; p++) {
				part_thread [p]->plan_process->Save_Flows ();
			}
		}
		return;
	} else {
		Start_Processing (true, true);
	}
#else
	Start_Processing ();
#endif

	if (exe->Memory_Flag ()) {
		exe->Trip_Loop ((exe->max_iteration == 1));
	} else {
		if (exe->trip_set_flag) {
			for (p=0; p < exe->num_file_sets; p++) {
				exe->Read_Trips (p);
			}
		} else {
			exe->Read_Trips (0);
		}
	}
	Stop_Processing (exe->Flow_Updates () || exe->Time_Updates ());
}

//---------------------------------------------------------
//	Part_Processor -- Copy_Plans
//---------------------------------------------------------

void Converge_Service::Part_Processor::Copy_Plans (void)
{
	int p;

#ifdef THREADS
	if (num_processors > 1) {
		for (p=0; p < exe->num_file_sets; p++) {
			partition_queue.Put (p);
		}
		partition_queue.End_of_Queue ();

		for (p=0; p < num_processors; p++) {
			threads.push_back (thread (ref (*(part_thread [p]))));
		}
		threads.Join_All ();

		if (exe->Flow_Updates () || exe->Time_Updates ()) {
			for (p=0; p < num_processors; p++) {
				part_thread [p]->plan_process->Save_Flows ();
			}
		}
		return;
	}
#endif
	Start_Processing ();

	if (exe->Memory_Flag ()) {
        exe->Copy_Plans (0);
	} else {
	    if (exe->new_set_flag) {
		    for (p=0; p < exe->num_file_sets; p++) {
			    exe->Copy_Plans (p);
		    }
	    } else {
		    for (p=0; ; p++) {
			    if (!exe->plan_file->Open (p)) break;
			    if (exe->new_plan_flag) exe->new_plan_file->Open (p);
			    exe->Copy_Plans (p);
		    }
	    }
	}
	Stop_Processing ((exe->Flow_Updates () || exe->Time_Updates ()) && exe->System_File_Flag (NEW_PERFORMANCE));
}

//---------------------------------------------------------
//	Part_Processor -- Plan_Build
//---------------------------------------------------------

void Converge_Service::Part_Processor::Plan_Build (Plan_Ptr_Array *ptr_array, int partition)
{
#ifdef THREADS
	if (num_processors > 1) {
		partition = partition_map [partition];
		trip_queue [partition]->Put (ptr_array);
		return;
	}
#endif
	plan_process->Plan_Build (ptr_array);
	partition = 0;
}
//---------------------------------------------------------
//	Part_Processor -- Start_Processing
//---------------------------------------------------------

void Converge_Service::Part_Processor::Start_Processing (bool update_times, bool zero_flows)
{
	plan_process->Start_Processing (update_times, zero_flows);
}

//---------------------------------------------------------
//	Part_Processor -- Stop_Processing
//---------------------------------------------------------

void Converge_Service::Part_Processor::Stop_Processing (bool save_flows)
{
#ifdef THREADS
	if (num_processors > 1) {
		for (int p=0; p < num_processors; p++) {
			exe->counters.num_reskim += part_thread [p]->counters.num_reskim;
			exe->counters.total_records += part_thread [p]->counters.total_records;
			exe->counters.num_reroute += part_thread [p]->counters.num_reroute;
			exe->counters.num_update += part_thread [p]->counters.num_update;
			exe->counters.num_copied += part_thread [p]->counters.num_copied;
			exe->counters.num_build += part_thread [p]->counters.num_build;
			exe->counters.select_records += part_thread [p]->counters.select_records;
			exe->counters.select_weight += part_thread [p]->counters.select_weight;
		}
	}
#endif
	plan_process->Stop_Processing (save_flows);
}

//---------------------------------------------------------
//	Part_Processor -- Counter_Ptr
//---------------------------------------------------------

Counters * Converge_Service::Part_Processor::Counter_Ptr (int part)
{
	if (part < 0) part = 0;
#ifdef THREADS
	if (Thread_Flag () && part < num_processors) {
		return (&part_thread [part]->counters);
	} else {
		return (&exe->counters);
	}
#else
	return (&exe->counters);
#endif
}

//---------------------------------------------------------
//	Part_Processor -- Save_Flows
//---------------------------------------------------------

void Converge_Service::Part_Processor::Save_Flows (void)
{
#ifdef THREADS
	if (num_processors > 1) {
MAIN_LOCK
		for (int p=0; p < num_processors; p++) {
			part_thread [p]->plan_process->Save_Flows ();
		}
END_LOCK
		return;
	}
#endif
	plan_process->Save_Flows ();
}

//
////---------------------------------------------------------
////	Part_Processor -- Save_Park_Demand
////---------------------------------------------------------
//
//void Converge_Service::Part_Processor::Save_Park_Demand (void)
//{
//#ifdef THREADS
//	if (Thread_Flag () && exe->Park_Demand_Flag ()) {
//		for (int p = 0; p < num_processors; p++) {
//			part_thread [p]->plan_process->Save_Park_Demand ();
//			exe->park_demand_array.Add_Demand (part_thread [p]->park_demand_array);
//		}
//	}
//#endif
//}

//---------------------------------------------------------
//	Part_Processor -- Update_Penalties
//---------------------------------------------------------

double Converge_Service::Part_Processor::Update_Penalties (bool zero_flag)
{
	//Save_Park_Demand ();

	double gap = exe->park_demand_array.Update_Penalties (zero_flag);

//#ifdef THREADS
//	if (Thread_Flag () && exe->Park_Demand_Flag ()) {
//		for (int p = 0; p < num_processors; p++) {
//			part_thread [p]->park_demand_array.Copy_Penalty_Data (exe->park_demand_array, zero_flag);
//		}
//	}
//#endif
	return (gap);
}

#ifdef THREADS
//---------------------------------------------------------
//	Part_Thread constructor
//---------------------------------------------------------

Converge_Service::Part_Processor::Part_Thread::Part_Thread (int num, Part_Processor *_ptr)
{
	ptr = _ptr;
	number = num;
	plan_process = 0;

	if (ptr) {
		plan_process = new Plan_Processor (ptr->exe);
	}
}

//---------------------------------------------------------
//	Part_Thread operator
//---------------------------------------------------------

void Converge_Service::Part_Processor::Part_Thread::operator()()
{
	int partition;
	plan_process->Start_Processing ();

	if (ptr->exe->thread_flag) {
		while (ptr->partition_queue.Get (partition)) {
			if (ptr->exe->trip_flag) {
				ptr->exe->Read_Trips (partition);
			} else {
				ptr->exe->Copy_Plans (partition);
			}		
		}
	} else {
		Plan_Ptr_Array *plan_ptr_array;
		Plan_Ptr_Queue *queue = ptr->trip_queue [number];
		queue->Start_Work ();

		while (queue->Get (plan_ptr_array)) {
			plan_process->Plan_Build (plan_ptr_array);
		}
	}
	plan_process->Stop_Processing ();
}
#endif
