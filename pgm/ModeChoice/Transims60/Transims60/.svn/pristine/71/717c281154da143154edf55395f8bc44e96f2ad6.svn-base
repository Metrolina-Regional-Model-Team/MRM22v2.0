//*********************************************************
//	PlanPrep.hpp - travel plan processing utility
//*********************************************************

#ifndef PLANPREP_HPP
#define PLANPREP_HPP

#include "APIDefs.hpp"
#include "Data_Service.hpp"
#include "Select_Service.hpp"
#include "Data_Queue.hpp"
#include "Data_Range.hpp"

//---------------------------------------------------------
//	PlanPrep - execution class definition
//---------------------------------------------------------

class SYSLIB_API PlanPrep : public Data_Service, public Select_Service
{
public:

	PlanPrep (void);

	virtual void Execute (void);
	virtual void Page_Header (void);

protected:
	enum PlanPrep_Keys { 
		MERGE_PLAN_FILE = 1, MERGE_PLAN_FORMAT, MERGE_MODE_FLAG, MAXIMUM_SORT_SIZE, REPAIR_PLAN_LEGS,
		CONSTRAIN_PARKRIDE_LOTS, MAX_PARKING_DEMAND_RATIO, CONSTRAIN_TRANSIT_LOADS, MAX_ROUTE_LOAD_FACTOR, 
		SHIFT_START_PERCENTAGE, SHIFT_END_PERCENTAGE, SHIFT_FROM_TIME_RANGE, SHIFT_TO_TIME_RANGE,
	};
	virtual void Program_Control (void);

private:
	enum PlanPrep_Reports { FIRST_REPORT = 1, SECOND_REPORT };

	Plan_File *plan_file, *new_plan_file;
	Plan_File merge_file;
	Plan_Skim_File *skim_file, *plan_skim_file;

	int sort_size, new_format, num_repair, repair_plans, num_new_skims;
	bool select_flag, merge_flag, combine_flag, output_flag, new_plan_flag, repair_flag, plan_skim_flag, skim_flag, merge_mode_flag;
	bool park_list_flag, route_list_flag, shift_start_flag, shift_end_flag;
	double max_ratio, max_factor, shift_rate, shift_factor;
	String pathname;
	Dtime low_from, high_from, low_to, high_to;
	Time_Periods shift_from, shift_to;

	Data_Range park_list, route_list;

	void MPI_Setup (void);
	void MPI_Processing (void);
	void Combine_Plans (bool mpi_flag = false);
	void Time_Combine (Plan_File *temp_file, int num_temp);
	void Trip_Combine (Plan_File *temp_file, int num_temp);
	int  Repair_Legs (Plan_Ptr plan_ptr);
	bool Constrain (Plan_Ptr plan_ptr);
	void Select_Skims (void);

	typedef Data_Queue <int> Partition_Queue;

	Partition_Queue partition_queue;

	//---------------------------------------------------------
	//	Plan_Processing - process plan partitions
	//---------------------------------------------------------

	class Plan_Processing
	{
	public:
		Plan_Processing (PlanPrep *_exe);
		~Plan_Processing (void);

		void operator()();

	private:
		PlanPrep *exe;
		int  num_temp, num_repair, repair_plans, num_new_skims;
		bool thread_flag;
		Random      random_part;

		Plan_Ptr_Array  plan_ptr_array;
		Trip_Map        traveler_sort;
		Time_Map        time_sort;
		Plan_File       *plan_file;
		Plan_File       *new_plan_file;
		Plan_File       *merge_file;
		Plan_Skim_File  *plan_skim_file;

		void Read_Plans (int part);
		void Write_Temp (void);
		void Trip_Write (void);
		void Time_Write (void);
		void Temp_Trip_Write (int part);
		void Temp_Time_Write (int part);
	};
};
#endif
