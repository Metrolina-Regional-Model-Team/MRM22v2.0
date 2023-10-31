//*********************************************************
//	Control.cpp - process the control parameters
//*********************************************************

#include "ArcJoin.hpp"

//---------------------------------------------------------
//	Program_Control
//---------------------------------------------------------

void ArcJoin::Program_Control (void)
{
	int i, num, fld;

	String key;
	Strings strings;
	Str_Itr str_itr;

	Arc_Data_Group arc_data;
	Arc_Data_Itr arc_itr;
	Field_Ptr fld_ptr;
	Int_Itr int_itr;

	//---- create the network files ----

	Data_Service::Program_Control ();
		
	projection.Read_Control ();

	Print (2, String ("%s Control Keys:") % Program ());

	//--- get the arc data files ----

	num = Highest_Control_Group (ARC_DATA_FILE);

	if (num < 1) {
		Error ("Arc Data Files are Required");
	}
	for (i = 1; i <= num; i++) {
		key = Get_Control_String (ARC_DATA_FILE, i);

		if (key.empty ()) continue;

		arc_data_array.push_back (arc_data);

		arc_itr = --arc_data_array.end ();

		arc_itr->group = i;
		arc_itr->file = new Arcview_File ();
		arc_itr->data_db = new Db_Data_Array ();
		arc_itr->file->Set_Projection (projection);

		Print (1);
		arc_itr->file->File_Type (String ("Arc Data File #%d") % i);
		arc_itr->file->File_ID (String ("ArcData%d") % i);

		arc_itr->file->Open (Project_Filename (key));

		arc_itr->type = arc_itr->file->Shape_Type ();

		arc_itr->data_db->Replicate_Fields (arc_itr->file);

		arc_itr->new_field = -1;
		arc_itr->new_flag = false;

		//---- data index field ----

		key = Get_Control_Text (DATA_INDEX_FIELD, i);

		if (key.empty ()) {
			Error (String ("Data Index Field %d is Missing") % i);
		}
		arc_itr->id_name (key);
		arc_itr->id_field = arc_itr->file->Field_Number (key);

		if (arc_itr->id_field < 0) {
			Error (String ("Data Index Field %s was Not Found") % key);
		}
		Print (0, String (" (Number=%d)") % (arc_itr->id_field + 1));

		//---- direction field ----

		key = Get_Control_Text (DIRECTION_FIELD, i);

		arc_itr->dir_field = arc_itr->file->Field_Number (key);

		if (arc_itr->dir_field >= 0) {
			Print (0, String (" (Number=%d)") % (arc_itr->dir_field + 1));
		}

		//---- split directions ----

		arc_itr->split = Get_Control_Flag (SPLIT_DIRECTIONS, i);

		if (arc_itr->split) {

			//---- direction offset ----

			arc_itr->offset = (float) Get_Control_Double (DIRECTION_OFFSET, i);
		}

		//---- select fields ----

		key = Get_Control_Text (SELECT_DATA_FIELDS, i);

		if (!key.empty ()) {
			key.Parse (strings);

			for (str_itr = strings.begin (); str_itr != strings.end (); str_itr++) {
				fld = arc_itr->file->Field_Number (*str_itr);

				if (fld < 0) {
					Error (String ("Select Data Field %s was Not Found") % *str_itr);
				}
				arc_itr->select.push_back (fld);
			}
		}

		//---- like match field ----

		key = Get_Control_Text (LIKE_MATCH_FIELD, i);

		if (!key.empty ()) {
			key.Parse (strings);
			if (strings.size () != 2) {
				Error ("Like Match Field = FIELD_NAME, MATCH_LENGTH");
			}
			arc_itr->like_len = strings [1].Integer ();
			if (arc_itr->like_len <= 0) {
				Error (String ("Like Match Field Length %d is Out of Range (>0)") % arc_itr->like_len);
			}
			arc_itr->like_name (strings [0]);

			arc_itr->like_fld = arc_itr->file->Field_Number (arc_itr->like_name);

			if (arc_itr->like_fld < 0) {
				Error (String ("Like Match Field %s was Not Found in Data File #%d") % arc_itr->like_name % i);
			}
			Print (0, String (" (Number=%d)") % (arc_itr->like_fld + 1));
			like_flag = true;
		} else {
			arc_itr->like_fld = arc_itr->like_len = arc_itr->like_group = -1;
		}

		//---- new arc data file ----
		
		key = Get_Control_String (NEW_ARC_DATA_FILE, i);

		if (!key.empty ()) {
			arc_itr->new_file = new Arcview_File ();
			arc_itr->new_file->File_Type (String ("New Arc Data File #%d") % i);;
			arc_itr->new_file->File_ID (String ("NewData%d") % i);
			arc_itr->new_file->File_Access (CREATE);
			arc_itr->new_file->Shape_Type (arc_itr->file->Shape_Type ());
			arc_itr->new_file->Set_Projection (projection);

			if (!arc_itr->new_file->Open (Project_Filename (key))) {
				File_Error ("Opening New Arc Data File", new_arc_file.Shape_Filename ());
			}
			arc_itr->new_flag = true;

			if (arc_itr->select.size () > 0) {
				fld_ptr = arc_itr->file->Field (arc_itr->id_field);

				arc_itr->new_file->Add_Field (fld_ptr->Name (), fld_ptr->Type (), fld_ptr->Size ());

				if (arc_itr->dir_field >= 0) {
					fld_ptr = arc_itr->file->Field (arc_itr->dir_field);

					arc_itr->new_file->Add_Field (fld_ptr->Name (), fld_ptr->Type (), fld_ptr->Size ());
				}

				for (int_itr = arc_itr->select.begin (); int_itr != arc_itr->select.end (); int_itr++) {
					fld_ptr = arc_itr->file->Field (*int_itr);

					arc_itr->new_file->Add_Field (fld_ptr->Name (), fld_ptr->Type (), fld_ptr->Size ());
				}
			} else {
				arc_itr->new_file->Replicate_Fields (arc_itr->file);
			}
			arc_itr->new_file->Write_Header ();
		}
	}

	//---- map the like match fields ----

	if (like_flag) {
		Arc_Data_Itr itr;

		for (arc_itr = arc_data_array.begin (); arc_itr != arc_data_array.end (); arc_itr++) {
			if (!arc_itr->like_name.empty ()) {
				for (i = 0, itr = arc_data_array.begin (); itr != arc_data_array.end (); itr++, i++) {
					if (itr != arc_itr && itr->id_name.Equals (arc_itr->like_name)) {
						arc_itr->like_group = i;
						break;
					}
				}
				if (arc_itr->like_group < 0) {
					Error (String ("Like Match Field %s was not an Index for another Group"));
				}
			}
		}
	}

	//---- coordinate buffer ----

	Print (1);
	buffer = Get_Control_Double (COORDINATE_BUFFER);

	//---- open the new arc data file ----

	key = Get_Control_String (NEW_ARC_JOIN_FILE);

	if (!key.empty ()) {
		new_arc_flag = true;

		new_arc_file.File_Type ("New Arc Join File");
		new_arc_file.File_ID ("NewArcJoin");
		new_arc_file.File_Access (CREATE);
		new_arc_file.Shape_Type (VECTOR);
		new_arc_file.Set_Projection (projection);

		if (!new_arc_file.Open (Project_Filename (key))) {
			File_Error ("Opening New Arc Join File", new_arc_file.Shape_Filename ());
		}

		//---- include data fields ----

		field_flag = Get_Control_Flag (INCLUDE_DATA_FIELDS);

		new_arc_file.Add_Field ("RECORD", DB_INTEGER, 10);
		new_arc_file.Add_Field ("SOURCE", DB_INTEGER, 3);

		for (arc_itr = arc_data_array.begin (); arc_itr != arc_data_array.end (); arc_itr++) {
			fld_ptr = arc_itr->file->Field (arc_itr->id_field);

			num = new_arc_file.Field_Number (fld_ptr->Name ());
			if (num < 0) {
				num = new_arc_file.Add_Field (fld_ptr->Name (), fld_ptr->Type (), fld_ptr->Size ());
			}
			arc_itr->new_field = num;
		}
		if (field_flag) {
			for (arc_itr = arc_data_array.begin (); arc_itr != arc_data_array.end (); arc_itr++) {
				if (arc_itr->select.size () > 0) {
					for (int_itr = arc_itr->select.begin (); int_itr != arc_itr->select.end (); int_itr++) {
						fld_ptr = arc_itr->file->Field (*int_itr);

						num = new_arc_file.Field_Number (fld_ptr->Name ());

						if (num < 0) {
							new_arc_file.Add_Field (fld_ptr->Name (), fld_ptr->Type (), fld_ptr->Size ());
						}
					}
				} else {
					for (i=0; i < arc_itr->file->Num_Fields (); i++) {
						fld_ptr = arc_itr->file->Field (i);
						if (fld_ptr->Name ().Equals ("OBJECTID") || fld_ptr->Name ().Equals ("Shape_Leng")) continue;

						num = new_arc_file.Field_Number (fld_ptr->Name ());

						if (num < 0) {
							new_arc_file.Add_Field (fld_ptr->Name (), fld_ptr->Type (), fld_ptr->Size ());
						}
					}
				}
			}
		}
		new_arc_file.Write_Header ();
	}
}
