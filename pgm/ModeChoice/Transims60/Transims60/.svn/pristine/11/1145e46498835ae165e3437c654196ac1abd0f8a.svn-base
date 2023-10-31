//*********************************************************
//	Write_Transfers.cpp - Line to Line Transfers
//*********************************************************

#include "PlanSum.hpp"

//---------------------------------------------------------
//	Write_Transfers
//---------------------------------------------------------

void PlanSum::Write_Transfers (void)
{
    String label;

	Line_Data *line_ptr;
	Stop_Data *stop_ptr;
	Int_Map_Itr int_itr;
	Xfer_IO_Map_Itr map_itr;
	Xfer_IO xfer_io;

	Show_Message ("Writing Stop Transfers -- Record");
	Set_Progress ();

	for (map_itr = xfer_map.begin (); map_itr != xfer_map.end (); map_itr++) {
		Show_Progress ();
		xfer_io = map_itr->first;

		transfer_file.Put_Field (0, xfer_io.from_stop);
		transfer_file.Put_Field (1, xfer_io.from_line);
		transfer_file.Put_Field (2, xfer_io.to_stop);
		transfer_file.Put_Field (3, xfer_io.to_line);
		transfer_file.Put_Field (4, map_itr->second);

		if (Notes_Name_Flag ()) {
			label.clear ();

			int_itr = line_map.find (xfer_io.from_line);
			if (int_itr != line_map.end ()) {
				line_ptr = &line_array [int_itr->second];
				if (!line_ptr->Name ().empty ()) {
					label += line_ptr->Name ();
				}
			}
			int_itr = stop_map.find (xfer_io.from_stop);
			if (int_itr != stop_map.end ()) {
				stop_ptr = &stop_array [int_itr->second];
				if (!stop_ptr->Name ().empty ()) {
					if (label.size () > 0) {
						label += " at ";
					}
					label += stop_ptr->Name ();
				}
			}
			if (label.size () > 0) {
				label += " --> ";
			}
			int_itr = line_map.find (xfer_io.to_line);
			if (int_itr != line_map.end ()) {
				line_ptr = &line_array [int_itr->second];
				if (!line_ptr->Name ().empty ()) {
					label += line_ptr->Name ();
				}
			}
			int_itr = stop_map.find (xfer_io.to_stop);
			if (int_itr != stop_map.end ()) {
				stop_ptr = &stop_array [int_itr->second];
				if (!stop_ptr->Name ().empty ()) {
					if (label.size () > 0) {
						label += " at ";
					}
					label += stop_ptr->Name ();
				}
			}
			transfer_file.Put_Field (5, label);
		}
		transfer_file.Write ();
	}
	End_Progress ();
	transfer_file.Close ();
}
