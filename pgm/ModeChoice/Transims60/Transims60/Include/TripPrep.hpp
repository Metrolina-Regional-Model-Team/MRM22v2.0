//*********************************************************
//	TripPrep.hpp - travel trip processing utility
//*********************************************************

#ifndef TRIPPREP_HPP
#define TRIPPREP_HPP

#include "APIDefs.hpp"
#include "Data_Service.hpp"
#include "Select_Service.hpp"
#include "Data_Queue.hpp"
#include "Partition_Files.hpp"
#include "User_Program.hpp"
#include "Factor_File.hpp"

//---------------------------------------------------------
//	TripPrep - execution class definitionfshift
//---------------------------------------------------------

class SYSLIB_API TripPrep : public Data_Service, public Select_Service
{
public:

	TripPrep (void);

	virtual void Execute (void);

protected:
	enum TripPrep_Keys { 
		MERGE_TRIP_FILE = 1, MERGE_TRIP_FORMAT, MERGE_VEHICLE_FILE, MERGE_VEHICLE_FORMAT,
		MAXIMUM_SORT_SIZE, UPDATE_TRIP_PARTITIONS, UPDATE_TRAVELER_TYPE, TRIP_PROCESSING_SCRIPT,
		NUMBER_OF_PARTITIONS, SORT_HOUSEHOLD_TOURS, SYNTHESIZE_VEHICLES, CHECK_ACTIVITY_PATTERNS,
		SHIFT_START_PERCENTAGE, SHIFT_END_PERCENTAGE, SHIFT_FROM_TIME_RANGE, SHIFT_TO_TIME_RANGE, 
		ZONE_FACTOR_FILE, ZONE_FACTOR_FORMAT, NEW_DESTINATION_FLAG, NEW_HOUSEHOLD_NUMBER, 
	};
	virtual void Program_Control (void);
	virtual void Page_Header (void);

private:
	enum TripPrep_Reports { PRINT_SCRIPT = 1, PRINT_STACK };

	Trip_File *trip_file, *new_trip_file, merge_file, *script_file;
	Factor_File *factor_file;
	
	Db_File program_file;
	User_Program program;

	int sort_size, new_format, num_out, num_parts, check_count, error_count, new_hhold, org_fld, des_fld;
	bool select_flag, merge_flag, combine_flag, output_flag, new_trip_flag, new_select_flag;
	bool update_flag, type_flag, script_flag, merge_veh_flag, veh_part_flag, factor_flag, move_flag;
	bool sort_tours, make_veh_flag, check_flag, shift_start_flag, shift_end_flag;
	Dtime low_from, high_from, low_to, high_to;
	double shift_rate, shift_factor;
	String pathname;
	Integers part_count;
	Int_Map location_parking;
	Time_Periods shift_from, shift_to;
	Dbls_Array row_factor;
	Integers zone_location;
	Integers next_location;

	void Check_Trips (void);
	void Person_Trips (Trip_Array &trip_array);
	void MPI_Setup (void);
	void MPI_Processing (void);
	void Combine_Trips (bool mpi_flag = false);
	void Time_Combine (Trip_File *temp_file, int num_temp);
	void Trip_Combine (Trip_File *temp_file, int num_temp);
	void Read_Factors (void);

	typedef Data_Queue <int> Partition_Queue;

	Partition_Files <Trip_File> new_file_set;
	Partition_Queue partition_queue;

	//---------------------------------------------------------
	//	Trip_Processing - process trip partitions
	//---------------------------------------------------------

	class Trip_Processing
	{
	public:
		Trip_Processing (TripPrep *_exe, int num);
		~Trip_Processing (void);

		void operator()();

	private:
		TripPrep *exe;
		int  num, num_temp;
		bool thread_flag;

		Random      random_part, random_fac, random_move;
		Integers    part_count;
		Select_Map  select_map;
		Vehicle_Map vehicle_map;

		Trip_Ptr_Array  trip_ptr_array;
		Trip_Map        traveler_sort;
		Time_Map        time_sort;
		Trip_File       *trip_file;
		Trip_File       *script_file;
		Trip_File       *new_trip_file;
		Trip_File       *merge_file;
		User_Program    program;

		void Read_Trips (int part);
		void Write_Temp (void);
		void Trip_Write (void);
		void Time_Write (void);
		void Temp_Trip_Write (int part);
		void Temp_Time_Write (int part);
		void Sort_Tours (void);
	};
};
#endif
