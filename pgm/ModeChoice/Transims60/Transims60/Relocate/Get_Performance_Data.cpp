//*********************************************************
//	Get_Performance_Data - read the performance file
//*********************************************************

#include "Relocate.hpp"

//---------------------------------------------------------
//	Get_Performance_Data
//---------------------------------------------------------

bool Relocate::Get_Performance_Data (Performance_File &file, Performance_Data &data)
{
	Int_Map_Itr itr;
	Link_Data *link_ptr;

	itr = link_map.find (file.Link ());

	if (itr != link_map.end ()) {
		link_ptr = &link_array [itr->second];

		if (link_ptr->Divided () == 1) {

			//---- copy the fields to the subarea file ----

			Db_Header *new_file = System_File_Header (NEW_PERFORMANCE);

			new_file->Copy_Fields (file);

			if (!new_file->Write ()) {
				Error (String ("Writing %s") % new_file->File_Type ());
			}
			num_perf++;
		} else if (link_ptr->Divided () == 1 || link_ptr->Divided () == 3) {
			int link, length;
			double factor;
			Int_Map_Itr map_itr;

			link = file.Link ();

			map_itr = link_map.find (link);

			if (map_itr != link_map.end ()) {
				link_ptr = &link_array [map_itr->second];
				length = link_ptr->Length ();
			} else {
				length = 1;
			}
			map_itr = target_link_map.find (link);

			if (map_itr != target_link_map.end ()) {
				link_ptr = &link_array [map_itr->second];
				factor = link_ptr->Length () / length;
			} else {
				factor = 1.0;
			}

			//---- copy the fields to the subarea file ----

			Performance_File *new_file = System_Performance_File (true);

			new_file->Copy_Fields (file);

			if (factor < 1.0) {
				new_file->Time ((int) (new_file->Time () * factor));
				new_file->Veh_Dist (new_file->Veh_Dist () * factor);
				new_file->Veh_Time (new_file->Veh_Time () * factor);
				new_file->Veh_Delay (new_file->Veh_Delay () * factor);
			}
			if (!new_file->Write ()) {
				Error (String ("Writing %s") % new_file->File_Type ());
			}
			num_perf++;
		}
	}
	data.Count (0);
	
	//---- don't save the record ----

	return (false);
}
