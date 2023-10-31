//*********************************************************
//	Control.cpp - process the control parameters
//*********************************************************

#include "VissimTrips.hpp"

//---------------------------------------------------------
//	Program_Control
//---------------------------------------------------------

void VissimTrips::Program_Control (void)
{
	int i, num;
	String key;
	File_Group file_data, *file_ptr;

	//---- create the network files ----

	Execution_Service::Program_Control ();

	Print (2, String ("%s Control Keys:") % Program ());

	//---- vissim trip files ----

	num = Highest_Control_Group (VISSIM_TRIP_FILE, 0);

	//---- open each file ----

	for (i = 1; i <= num; i++) {
		key = Get_Control_String (VISSIM_TRIP_FILE, i);

		if (!key.empty ()) {
			Print (1);

			file_data.group = i;
			file_group.push_back (file_data);

			file_ptr = &file_group [(int) file_group.size () - 1];

			file_ptr->file = new Db_File ();

			file_ptr->file->File_Type (String ("VISSIM Trip File #%d") % i);

			file_ptr->file->Open (Project_Filename (key));

			file_ptr->file->Read ();
			key = file_ptr->file->Record_String ();

			if (!key.Equals ("$VR;D3")) {
				Error (String ("VISSIM Trip File Code %s was Not Recognized") % key);
			}
		}
	}
	
	//---- new trip table file ----

	Print (1);
	key = Get_Control_String (NEW_TRIP_TABLE_FILE);
	new_file.File_Type ("New Trip Table File");

	if (Check_Control_Key (NEW_TRIP_TABLE_FORMAT)) {
		new_file.Format_Code (Get_Control_String (NEW_TRIP_TABLE_FORMAT));
	}
	new_file.Data_Type (DATA_TABLE);
	new_file.Range_Flag (true);
	new_file.Create (Project_Filename (key));
}

