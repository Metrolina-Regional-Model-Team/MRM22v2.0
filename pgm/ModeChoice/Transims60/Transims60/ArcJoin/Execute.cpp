//*********************************************************
//	Execute.cpp - main execution procedure
//*********************************************************

#include "ArcJoin.hpp"

//---------------------------------------------------------
//	Execute
//---------------------------------------------------------

void ArcJoin::Execute (void)
{
	Data_Service::Execute ();	

	Read_Arc_Data ();

	if (new_arc_flag) {
		Write_Arc_Data ();
	}
	Exit_Stat (DONE);
}
