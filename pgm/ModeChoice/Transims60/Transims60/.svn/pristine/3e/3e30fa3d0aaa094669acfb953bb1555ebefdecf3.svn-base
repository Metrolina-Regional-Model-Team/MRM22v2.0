//*********************************************************
//	Read_Vissim.cpp - read vissim trip tables
//*********************************************************

#include "VissimTrips.hpp"

//---------------------------------------------------------
//	Read_Table
//---------------------------------------------------------

void VissimTrips::Read_Vissim (void)
{
	int org, des, ext_org, ext_des, period, zon, zone, num_zones;
	double total, trips;
	bool zone_flag;
	String record, field;
	Strings fields;
	Str_Itr str_itr;
	Dtime low, high;
	Integers zones;
	Int_Set zone_set;

	File_Itr file_itr;
	num_zones = 0;

	//---- establish input structure ----
	
	for (file_itr = file_group.begin (); file_itr != file_group.end (); file_itr++) {

		while (file_itr->file->Read ()) {
			record = file_itr->file->Record_String ();

			if (record.Equals ("* From To")) {
				file_itr->file->Read ();
				record = file_itr->file->Record_String ();
				record.Trim ();
				record.Split (field, " ");
				low.Hours (field.Double ());
				high.Hours (record.Double ());

				new_file.Add_Range (low, (high - 1), 0);
			}
			if (record.Equals ("* Number of Zones")) {
				file_itr->file->Read ();
				record = file_itr->file->Record_String ();
				record.Trim ();
				num_zones = record.Integer ();

				new_file.Num_Zones (num_zones);
				zon = 0;

				//---- set zone numbers ----

				while (file_itr->file->Read ()) {
					record = file_itr->file->Record_String ();
					record.Trim ();
					record.Parse (fields, " ");

					for (str_itr = fields.begin (); str_itr != fields.end (); str_itr++, zon++) {
						zone = str_itr->Integer ();

						new_file.Add_Org (zone);
						new_file.Add_Des (zone);

						if (zone_set.insert (zone).second) {
							zones.push_back (zone);
						}
					}
					if (zon >= num_zones) break;
				}
				break;
			}
		}
	}
	new_file.Write_Header ();
	new_file.Allocate_Data ();

	//----- process the trip data by origin zone ----

	for (period = 0, file_itr = file_group.begin (); file_itr != file_group.end (); file_itr++, period++) {
		Show_Message (1, String ("Reading %s -- Record") % file_itr->file->File_Type ());
		Set_Progress ();

		total = trips = 0;
		ext_org = ext_des = 0;

		zone_flag = false;

		while (file_itr->file->Read ()) {
			Show_Progress ();
			record = file_itr->file->Record_String ();

			if (record.Starts_With ("* Zone ")) {
				record.Parse (fields, " ");
				ext_org = fields [2].Integer ();
				total += fields [4].Double ();

				org = new_file.Org_Index (ext_org);
				if (org < 0) continue;

				//----- read the destination records ----

				zon = 0;

				while (file_itr->file->Read ()) {
					Show_Progress ();

					record = file_itr->file->Record_String ();
					record.Trim ();
					record.Parse (fields, " ");

					for (str_itr = fields.begin (); str_itr != fields.end (); str_itr++, zon++) {
						ext_des = zones [zon];
						trips = str_itr->Double ();

						des = new_file.Des_Index (ext_des);

						new_file.Set_Cell_Index (des, 0, trips);
					}
					if (zon >= num_zones) break;
				}
				new_file.Write_Row (ext_org, period);
			}
		}
		End_Progress ();

		file_itr->file->Close ();

		Print (2, String ("%s has %d Records and %.3lf Trips") % file_itr->file->File_Type () % Progress_Count () % total);
	}
	new_file.Close ();
}
