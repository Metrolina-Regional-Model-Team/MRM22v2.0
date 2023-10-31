//*********************************************************
//	Get_Turn_Delay_Data.cpp - read the turn volume file
//*********************************************************

#include "Relocate.hpp"

//---------------------------------------------------------
//	Get_Turn_Delay_Data
//---------------------------------------------------------

bool Relocate::Get_Turn_Delay_Data (Turn_Delay_File &file, Turn_Delay_Data &data)
{
	Int_Map_Itr itr;
	Link_Data *link_ptr;

	data.Dir_Index (0);

	itr = link_map.find (file.Link ());

	if (itr == link_map.end ()) return (false);

	link_ptr = &link_array [itr->second];
	if (link_ptr->Divided () != 1) return (false);

	itr = link_map.find (file.To_Link ());
	if (itr == link_map.end ()) return (false);

	link_ptr = &link_array [itr->second];
	if (link_ptr->Divided () != 1) return (false);

	//---- copy the fields to the subarea file ----

	Db_Header *new_file = System_File_Header (NEW_TURN_DELAY);

	new_file->Copy_Fields (file);

	if (!new_file->Write ()) {
		Error (String ("Writing %s") % new_file->File_Type ());
	}
	num_turn++;
	
	//---- don't save the record ----

	return (false);
}
