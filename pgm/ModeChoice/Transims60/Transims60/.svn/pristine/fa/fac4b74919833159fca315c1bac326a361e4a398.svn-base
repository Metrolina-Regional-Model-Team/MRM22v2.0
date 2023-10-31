//*********************************************************
//	Execute.cpp - main execution procedure
//*********************************************************

#include "VissimPlans.hpp"

//---------------------------------------------------------
//	Execute
//---------------------------------------------------------

void VissimPlans::Execute (void)
{
	//---- read the network data ----

	Data_Service::Execute ();

	//---- read the vissim trip data ----

	Read_Vissim ();

	//---- build plan templates ----

	Build_Plans ();

	//--- path plan summary ----

	if (path_flag) {
		path_plan.Print_Summary ();
	}

	//---- plan summary ----

	new_file->Print_Summary ();

	Exit_Stat (DONE);
}
