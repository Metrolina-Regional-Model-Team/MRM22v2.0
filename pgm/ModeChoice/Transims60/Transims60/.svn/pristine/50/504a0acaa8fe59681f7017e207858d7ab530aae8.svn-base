//*********************************************************
//	Execute.cpp - main execution procedure
//*********************************************************

#include "VissimNet.hpp"

//---------------------------------------------------------
//	Execute
//---------------------------------------------------------

void VissimNet::Execute (void)
{
	//---- read the network ----

	Data_Service::Execute ();

	//---- input vissim data ----

	if (input_flag) {
		Read_Vissim ();
	} else {
		Write_Vissim ();
	}

	//---- print reports ----

	//for (int i=First_Report (); i != 0; i=Next_Report ()) {
	//	switch (i) {
	//		default:
	//			break;
	//	}
	//}

	//---- end the program ----

	Exit_Stat (DONE);
}

////---------------------------------------------------------
////	Page_Header
////---------------------------------------------------------
//
//void VissimNet::Page_Header (void)
//{
//	switch (Header_Number ()) {
//		default:
//			break;
//	}
//}
