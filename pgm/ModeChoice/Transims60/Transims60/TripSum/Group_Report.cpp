//*********************************************************
//	Group_Report.cpp - Print the Mode Purpose Group Report
//*********************************************************

#include "TripSum.hpp"

//---------------------------------------------------------
//	Mode_Purpose_Group_Report
//---------------------------------------------------------

void TripSum::Mode_Purpose_Group_Report (void)
{
	int g, m, p, org, des;
	int tot_org, tot_des;
	Int4_Itr i4_itr;
	Int3_Itr i3_itr;
	Ints_Itr i2_itr;
	Int_Itr int_itr;

	//---- print the report ----

	Header_Number (TRIP_GROUPS);

	Print (1);
	Mode_Purpose_Group_Header ();

	tot_org = tot_des = 0;

	for (g=0, i4_itr = mode_purp_groups.begin (); i4_itr != mode_purp_groups.end (); i4_itr++, g++) {
		for (m=0, i3_itr = i4_itr->begin (); i3_itr != i4_itr->end (); i3_itr++, m++) {
			for (p=0, i2_itr = i3_itr->begin (); i2_itr != i3_itr->end (); i2_itr++, p++) {
				org = i2_itr->at (0);
				des = i2_itr->at (1);

				if (org == 0 && des == 0) continue;

				tot_org += org;
				tot_des += des;

				Print (1, String ("%5d  %8.8s    %3d   %10d  %10d    %s") % g % Mode_Code ((Mode_Type) m) % p % org % des % zone_equiv.Group_Label (g));
			}
		}
	}
	Print (2, String ("Total                    %10d  %10d") % tot_org % tot_des);
		
	Header_Number (0);
}

//---------------------------------------------------------
//	Mode_Purpose_Group_Header
//---------------------------------------------------------

void TripSum::Mode_Purpose_Group_Header (void)
{
	Print (1, "Mode Purpose Group Report");
	Print (2, "Group      Mode  Purpose    Origins  Destinations");
	Print (1);
}
	 
/*********************************************|***********************************************

	Mode Purpose Group Report

	Group      Mode  Purpose    Origins  Destinations  
	
	ddddd  ssssssss   ddd    dddddddddd  dddddddddd    sssssssssssssssssssssss

	Total                    dddddddddd  dddddddddd

	Total                    dddddddddd  dddddddddd

**********************************************|***********************************************/ 
