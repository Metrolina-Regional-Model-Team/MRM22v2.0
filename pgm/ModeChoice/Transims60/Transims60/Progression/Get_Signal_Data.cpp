//*********************************************************
//	Signal_Process.cpp - read the signal file
//*********************************************************

#include "Progression.hpp"

#include "Signal_File.hpp"

//---------------------------------------------------------
//	Signal_Processing
//---------------------------------------------------------

bool Progression::Get_Signal_Data (Signal_File &file, Signal_Data &data)
{
	Signal_Offset offset;

	//---- reserve memory ----

	if (signal_db.Num_Records () == 0) {
		if (!signal_db.Num_Records (file.Num_Records ())) {
			Error ("Insufficient Memory for Signal Database");
		}
	}

	if (Data_Service::Get_Signal_Data (file, data)) {

		//---- save the database record ----

		signal_db.Copy_Fields (file);

		if (!signal_db.Add_Record ()) {
			Error ("Writing Signal Database");
		}

		//---- create the fixed signal data ----

		if (data.Type () == TIMED) {
			offset.input = data.Offset ();

			if (!clear_flag) {
				offset_ptr->Preset (signal_ptr->Offset ());
			}
			if (period_flag) {
				offset_ptr->Period (progress_time.Period (signal_ptr->Start ()));
				if (offset_ptr->Period () == 0) {
					offset_ptr->Preset (signal_ptr->Offset ());
				}
			} else {
				offset_ptr->Period (1);
			}
			if (!signal_offset.Add (offset_ptr)) {
				Error ("Adding Signal Offset Record");
			}
			signal_offset_map.insert (Signal_Offset_Map_Data ((int) signal_array.size (), offset));
		}
		return (true);
	}
	return (false);
}
