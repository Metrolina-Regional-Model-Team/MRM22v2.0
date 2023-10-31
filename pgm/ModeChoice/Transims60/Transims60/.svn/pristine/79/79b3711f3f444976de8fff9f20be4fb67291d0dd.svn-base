//*********************************************************
//	Run_Change_Report.cpp - Print the Trip Start Time Report
//*********************************************************

#include "Reschedule.hpp"

//---------------------------------------------------------
//	Run_Change_Report
//---------------------------------------------------------

void Reschedule::Run_Change_Report (void)
{
	double percent;
	Dtime old_avg, new_avg;
	Change_Itr change_itr;

	//---- print the report ----

	Header_Number (RUN_CHANGE);

	if (!Break_Check ((int) change_array.size () + 5)) {
		Print (1);
		Run_Change_Header ();
	}

	for (change_itr = change_array.begin (); change_itr != change_array.end (); change_itr++) {
		if (change_itr->count > 0) {
			old_avg = (int) (change_itr->old_run / change_itr->count);
			new_avg = (int) (change_itr->new_run / change_itr->count);
			percent = 100.0 * new_avg / old_avg - 100.0;
		} else {
			old_avg = 0;
			new_avg = 0;
			percent = 0;
		}
		Print (1, String ("%-11.11s %6d   %8.8s %8.8s   %8.8s %8.8s   %8.8s %8.8s  %6.1lf%%") % 
			Transit_Code ((Transit_Type) change_itr->mode) % change_itr->route % 
			change_itr->old_min.Time_String () % change_itr->new_min.Time_String () % 
			change_itr->old_max.Time_String () % change_itr->new_max.Time_String () % 
			old_avg.Round_Seconds ().Time_String () % new_avg.Round_Seconds ().Time_String () % 
			percent % FINISH);
	}
	Header_Number (0);
}

//---------------------------------------------------------
//	Run_Change_Header
//---------------------------------------------------------

void Reschedule::Run_Change_Header (void)
{
	Print (1, "Run Time Change Report");
	Print (2, "                     ---- Minimum ----   ---- Maximum ----   ---- Average ---- Percent");
	Print (1, "Mode         Route       Old      New        Old      New        Old      New   Change");
	Print (1);
}
	 
/*********************************************|***********************************************

	Run Time Change Report

	                     ---- Minimum ----   ---- Maximum ----   ---- Average ---- Percent
	Mode         Route       Old      New        Old      New        Old      New   Change

	sssssssssss dddddd   dd:dd:dd dd:dd:dd   dd:dd:dd dd:dd:dd   dd:dd:dd dd:dd:dd  dddd.d%

**********************************************|***********************************************/ 
