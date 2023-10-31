//*********************************************************
//	Wrtie_Group_File.cpp - Write the Mode Purpose Group File
//*********************************************************

#include "TripSum.hpp"

//---------------------------------------------------------
//	Write_Group_File
//---------------------------------------------------------

void TripSum::Write_Mode_Purpose_Groups (void)
{
	int g, m, p, org, des;

	Int4_Itr i4_itr;
	Int3_Itr i3_itr;
	Ints_Itr i2_itr;
	Int_Itr int_itr;

	Show_Message ("Writing Mode Purpose Groups -- Record");
	Set_Progress ();

	for (g=0, i4_itr = mode_purp_groups.begin (); i4_itr != mode_purp_groups.end (); i4_itr++, g++) {
		for (m=0, i3_itr = i4_itr->begin (); i3_itr != i4_itr->end (); i3_itr++, m++) {
			for (p=0, i2_itr = i3_itr->begin (); i2_itr != i3_itr->end (); i2_itr++, p++) {
				Show_Progress ();

				org = i2_itr->at (0);
				des = i2_itr->at (1);

				if (org == 0 && des == 0) continue;

				group_file.Put_Field (0, g);
				group_file.Put_Field (1, Mode_Code ((Mode_Type) m));
				group_file.Put_Field (2, p);
				group_file.Put_Field (3, org);
				group_file.Put_Field (4, des);
				group_file.Put_Field (5, zone_equiv.Group_Label (g));

				group_file.Write ();
			}
		}
	}
	End_Progress ();
}

