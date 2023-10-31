//*********************************************************
//	Control.cpp - Program Control
//*********************************************************

#include "VissimNet.hpp"

//---------------------------------------------------------
//	Program_Control
//---------------------------------------------------------

void VissimNet::Program_Control (void)
{
	int link;
	String key;
	Strings strings;
	Str_Itr str_itr;
	Int2_Key map;

	//---- open network and demand files ----

	Data_Service::Program_Control ();

	Print (2, String ("%s Control Keys:") % Program ());
	Print (1);

	//---- open vissim xml file ----

	key = Get_Control_String (VISSIM_XML_FILE);

	if (!key.empty ()) {
		input_flag = true;
		input_file.File_Type ("VISSIM XML File");
		input_file.Open (Project_Filename (key));

		if (!System_File_Flag (NEW_NODE) || !System_File_Flag (NEW_LINK)) {
			Error ("A New Link and Node File are Required");
		}

		//---- keep connector list ----

		key = Get_Control_Text (KEEP_CONNECTOR_LIST);

		if (!key.empty ()) {
			map.first = map.second = -1;
			key.Parse (strings);

			for (str_itr = strings.begin (); str_itr != strings.end (); str_itr++) {
				link = str_itr->Integer ();
				keep_list.insert (Int_Key_Map_Data (link, map));
			}
		}

		//---- new arc link file ----

		key = Get_Control_String (NEW_ARC_LINK_FILE);

		if (!key.empty ()) {
			arc_link_flag = true;
			arc_link_file.File_Type ("New Arc_Link File");
			arc_link_file.File_Access (CREATE);
			arc_link_file.Shape_Type (VECTOR);

			arc_link_file.Add_Field ("LINK", DB_INTEGER, 10);
			arc_link_file.Add_Field ("LANES", DB_INTEGER, 10);

			arc_link_file.Open (Project_Filename (key));
		}

		//---- location weights ----

		if (System_File_Flag (NEW_LOCATION)) {
			Location_File *loc_file = System_Location_File (true);

			org_field = loc_file->Add_Field ("ORIGIN", DB_INTEGER, 2);
			des_field = loc_file->Add_Field ("DESTINATION", DB_INTEGER, 2);

			loc_file->Write_Header ();
		}

	} else {

		key = Get_Control_String (NEW_VISSIM_XML_FILE);

		if (!key.empty ()) {
			input_flag = false;
			output_file.File_Type ("New VISSIM XML File");
			output_file.Create (Project_Filename (key));

			if (!System_File_Flag (NODE) || !System_File_Flag (LINK)) {
				Error ("A Link and Node File are Required");
			}
		} else {
			Error ("An Input or Output VISSIM XML File is Required");
		}
	}
} 
