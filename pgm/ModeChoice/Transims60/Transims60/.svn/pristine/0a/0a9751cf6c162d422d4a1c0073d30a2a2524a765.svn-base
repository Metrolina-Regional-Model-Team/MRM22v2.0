//*********************************************************
//	Reschedule.hpp - reschedule transit routes
//*********************************************************

#ifndef RESCHEDULE_HPP
#define RESCHEDULET_HPP

#include "Data_Service.hpp"
#include "Select_Service.hpp"

//---------------------------------------------------------
//	Reschedule - execution class definition
//---------------------------------------------------------

class SYSLIB_API Reschedule : public Data_Service, public Select_Service
{
public:
	Reschedule (void);

	virtual void Execute (void);

protected:
	enum Reschedule_Keys { RUN_SCHEDULE_FILE = 1, RUN_SCHEDULE_FORMAT, 
		RUN_FILTER_FIELD, RUN_TYPE_FIELD, RUN_SCHEDULE_LINE, RUN_FILTER_RANGE,
		RUN_STOP_FIELD_FILE, PERFORMANCE_UPDATE_FILE, PERFORMANCE_UPDATE_FORMAT,
		TRANSIT_MODE_FACTORS, MINIMUM_MODE_PERCENTS, MAXIMUM_MODE_PERCENTS,
		NEW_TIME_CHANGE_FILE, NEW_TIME_CHANGE_FORMAT,
	};

	virtual void Program_Control (void);

	virtual void Page_Header (void);

private:
	enum Reschedule_Reports { MATCH_DUMP = 1, RUN_CHANGE };

	int mode_field,	line_field, run_field, start_field, old_field, new_field;
	bool run_flag, match_dump, update_flag, factor_flag, min_flag, max_flag, change_flag, file_flag;
	Double_List mode_factor, mode_min, mode_max;
	Db_Header change_file;

	Performance_File update_file;
	Perf_Period_Array update_array;
	
	typedef struct {
		int line;
		int low;
		int high;
		Int_Map stop_field;
	} Line_Filter;

	typedef vector <Line_Filter>   Filter_Array;
	typedef Filter_Array::iterator Filter_Itr;

	typedef struct {
		Db_Header *run_file;
		int filter;
		int type;
		Filter_Array lines;
	} File_Data;

	typedef vector <File_Data>   File_Group;
	typedef File_Group::iterator File_Itr;

	File_Group file_group;

	typedef struct {
		int   mode;
		int   route;
		Dtime old_min;
		Dtime new_min;
		Dtime old_max;
		Dtime new_max;
		int   count;
		double old_run;
		double new_run;
	} Run_Change;

	typedef vector <Run_Change>    Change_Array;
	typedef Change_Array::iterator Change_Itr;

	Run_Change run_change;
	Change_Array change_array;

	//---- methods ----

	void Read_Runs (void);
	void Update_Schedules (void);
	void Update_Factors (void);
	void Factor_Schedules (void);

	void Run_Summary (int mode, int route, int run, Dtime start, Dtime old_tod, Dtime new_tod);

	void Run_Change_Report (void);
	void Run_Change_Header (void);
};
#endif
