//*********************************************************
//	Read_Arc_Data.cpp - read the arc data files
//*********************************************************

#include "ArcJoin.hpp"

//---------------------------------------------------------
//	Read_Arc_Data
//---------------------------------------------------------

void ArcJoin::Read_Arc_Data (void)
{
	Arc_Data_Itr arc_itr;
	Shape_Record shape_rec;
	Points shape;
	XY_Range box;
	XYZ_Point pt1, pt2;
	bool point_flag, flip;
	int size, num_match;
	String direction;
	Strings strings;
	Str_Itr str_itr;

	//---- read the arcview data files ----

	num_match = (int) arc_data_array.size ();

	for (arc_itr = arc_data_array.begin (); arc_itr != arc_data_array.end (); arc_itr++) {
		Show_Message (String ("Reading %s -- Record") % arc_itr->file->File_Type ());
		Set_Progress ();

		point_flag = (arc_itr->type == DOT);

		//---- read each record ----

		while (arc_itr->file->Read_Record ()) {
			Show_Progress ();

			if (!arc_itr->data_db->Copy_Fields (*arc_itr->file)) {
				Error ("Copying Fields");
			}
			if (!arc_itr->data_db->Add_Record ()) {
				Error ("Adding Record");
			}
			shape_rec.shape = (*arc_itr->file);

			size = (int) shape_rec.shape.size ();

			if ((int) arc_itr->file->size () != size) {
				Error ("Size problem");
			}
			shape_rec.box = Buffer_Box (arc_itr->file->Coordinate_Range (), buffer);

			shape_rec.index = arc_itr->data_db->Get_String (arc_itr->id_field);

			if (point_flag) {
				shape_rec.direction = 0;
			} else {
				pt1 = shape_rec.shape [0];
				pt2 = shape_rec.shape [size - 1];

				shape_rec.direction = compass.Direction (pt2.x - pt1.x, pt2.y - pt1.y);

				//---- check the shape direction ----

				if (arc_itr->dir_field >= 0) {
					direction = arc_itr->data_db->Get_String (arc_itr->dir_field);
retry:
					if (!direction.empty ()) {
						flip = false;
						if (direction.Starts_With ("N")) {
							flip = (pt1.y > pt2.y);
						} else if (direction.Starts_With ("S")) {
							flip = (pt2.y > pt1.y);
						} else if (direction.Starts_With ("E")) {
							flip = (pt1.x > pt2.x);
						} else if (direction.Starts_With ("W")) {
							flip = (pt2.x > pt1.x);
						} else {
							direction.Parse (strings);

							for (str_itr = strings.begin (); str_itr != strings.end (); str_itr++) {
								if (str_itr->Starts_With ("North") ||
									str_itr->Starts_With ("South") ||
									str_itr->Starts_With ("East") ||
									str_itr->Starts_With ("West")) {
									direction = *str_itr;
									arc_itr->data_db->Put_Field (arc_itr->dir_field, direction);
									goto retry;
								}
								if (str_itr->Starts_With ("N") ||
									str_itr->Starts_With ("S") ||
									str_itr->Starts_With ("E") ||
									str_itr->Starts_With ("W")) {
									direction = *str_itr;
									arc_itr->data_db->Put_Field (arc_itr->dir_field, direction);
									goto retry;
								}
							}
						}
						if (flip) {
							shape_rec.direction = compass.Flip (shape_rec.direction);
							shape_rec.shape.assign (arc_itr->file->rbegin (), arc_itr->file->rend ());
						}
					}
				}
			}
			shape_rec.best.assign (num_match, MAX_INTEGER);
			shape_rec.match.assign (num_match, -1);

			if (arc_itr->like_fld >= 0) {
				shape_rec.like (arc_itr->file->Get_String (arc_itr->like_fld));
				shape_rec.like.erase (arc_itr->like_len);
			} else {
				shape_rec.like.clear ();
			}
			 
			//---- save the shape record ----

			arc_itr->shapes.push_back (shape_rec);

			if (arc_itr->new_flag) {
				arc_itr->new_file->Copy_Fields (*arc_itr->data_db);
				arc_itr->new_file->assign (shape_rec.shape.begin (), shape_rec.shape.end ());

				if (arc_itr->new_file->size () > 0) {
					if (!arc_itr->new_file->Write_Record ()) {
						Error (String ("Writing %s") % arc_itr->new_file->File_Type ());
					}
				}
			}

			//----- create a shape in the opposite direction ----

			if (arc_itr->split) {
				Shift_Shape (shape_rec.shape, arc_itr->offset, 1);
				shape_rec.direction = compass.Flip (shape_rec.direction);

				arc_itr->shapes.push_back (shape_rec);

				if (!point_flag && arc_itr->dir_field && !direction.empty ()) {
					if (direction.Starts_With ("N")) {
						if (direction.Equals ("Northbound")) {
							arc_itr->data_db->Put_Field (arc_itr->dir_field, "Southbound");
						} else {
							arc_itr->data_db->Put_Field (arc_itr->dir_field, "S");
						}
					} else if (direction.Starts_With ("S")) {
						if (direction.Equals ("Sorthbound")) {
							arc_itr->data_db->Put_Field (arc_itr->dir_field, "Nouthbound");
						} else {
							arc_itr->data_db->Put_Field (arc_itr->dir_field, "N");
						}
					} else if (direction.Starts_With ("E")) {
						if (direction.Equals ("Eastbound")) {
							arc_itr->data_db->Put_Field (arc_itr->dir_field, "Westbound");
						} else {
							arc_itr->data_db->Put_Field (arc_itr->dir_field, "W");
						}
					} else if (direction.Starts_With ("W")) {
						if (direction.Equals ("Westbound")) {
							arc_itr->data_db->Put_Field (arc_itr->dir_field, "Eastbound");
						} else {
							arc_itr->data_db->Put_Field (arc_itr->dir_field, "E");
						}
					}
				}
				if (!arc_itr->data_db->Add_Record ()) {
					Error ("Adding Record");
				}
				if (arc_itr->new_flag) {
					arc_itr->new_file->Copy_Fields (*arc_itr->data_db);
					arc_itr->new_file->assign (shape_rec.shape.begin (), shape_rec.shape.end ());
					
					if (arc_itr->new_file->size () > 0) {
						if (!arc_itr->new_file->Write_Record ()) {
							Error (String ("Writing %s") % arc_itr->new_file->File_Type ());
						}
					}
				}
			}
		}
		End_Progress ();

		Print (2, String ("Number of %s Records = %d") % arc_itr->file->File_Type () % Progress_Count ());
		
		arc_itr->file->Close ();
		if (arc_itr->new_flag) {
			arc_itr->new_file->Close ();
		}
	}
}
