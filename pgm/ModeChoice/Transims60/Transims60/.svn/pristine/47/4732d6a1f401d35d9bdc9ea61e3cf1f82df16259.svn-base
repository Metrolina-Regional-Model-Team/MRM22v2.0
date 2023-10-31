//*********************************************************
//	Write_Node.cpp - write the subarea node file
//*********************************************************

#include "SubareaNet.hpp"

//---------------------------------------------------------
//	Write_Node
//---------------------------------------------------------

void SubareaNet::Write_Node (void)
{
	int node, node_field, subarea;
	bool subarea_flag;

	Int_Map_Itr map_itr;
	Node_Data *node_ptr;

	Node_File *node_file = System_Node_File (true);

	char *ext_dir [] = {
		"External Node", "Subarea Node"
	};
	subarea_flag = (node_file->Optional_Field ("SUBAREA", "AREA") < 0);

	if (subarea_flag) {
		node_file->Add_Field ("SUBAREA", DB_INTEGER, 4);
		node_file->Write_Header ();
	}

	//---- process each subarea nodes ----
	
	Show_Message ("Writing Subarea Node Data -- Record");
	Set_Progress ();

	node_field = node_db.Required_Field ("NODE", "ID", "N");

	node_db.Rewind ();

	while (node_db.Read_Record ()) {
		Show_Progress ();

		node = node_db.Get_Integer (node_field);

		map_itr = node_map.find (node);

		if (map_itr == node_map.end ()) continue;

		node_ptr = &node_array [map_itr->second];

		if (node_ptr->Subarea () == 0) continue;
		node_file->Copy_Fields (node_db);

		subarea = node_ptr->Subarea ();
		if (subarea == 2) subarea = 0;

		if (subarea_flag) {
			node_file->Subarea (subarea);
		}
		node_file->Notes (ext_dir [subarea]);

		if (!node_file->Write ()) {
			Error (String ("Writing %s") % node_file->File_Type ());
		}
		nnode++;
	}
	End_Progress ();
}
