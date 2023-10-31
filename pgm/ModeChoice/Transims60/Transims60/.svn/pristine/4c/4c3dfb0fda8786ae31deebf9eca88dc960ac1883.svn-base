//*********************************************************
//	Execute.cpp - main execution procedure
//*********************************************************

#include "Reschedule.hpp"

//---------------------------------------------------------
//	Execute
//---------------------------------------------------------

void Reschedule::Execute (void)
{
	//---- read the network ----

	Data_Service::Execute ();

	//---- read detailed schedules ----

	if (run_flag) {
		Read_Runs ();
	}
	
	//---- update schedules based on link travel time changes ----

	if (update_flag) {
		Read_Performance (update_file, update_array);

		if (System_File_Flag (PERFORMANCE)) {
			Update_Schedules ();
		} else {
			Update_Factors ();
		}
	} else if (factor_flag) {
		Factor_Schedules ();
	}

	//---- write the selection file ----

	Write_Schedules ();

	//---- print reports ----

	for (int i = First_Report (); i != 0; i = Next_Report ()) {
		switch (i) {
			case RUN_CHANGE:		//---- Run Time Changes ----
				Run_Change_Report ();
				break;
			default:
				break;
		}
	}
	Exit_Stat (DONE);
}

//---------------------------------------------------------
//	Page_Header
//---------------------------------------------------------

void Reschedule::Page_Header (void)
{
	switch (Header_Number ()) {
		case RUN_CHANGE:		//---- Run Time Changes ----
			Run_Change_Header ();
			break;
		default:
			break;
	}
}

