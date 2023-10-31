//*********************************************************
//	Write_Arc_Data.cpp - write the arc data files
//*********************************************************

#include "ArcJoin.hpp"

//---------------------------------------------------------
//	Write_Arc_Data
//---------------------------------------------------------

void ArcJoin::Write_Arc_Data (void)
{
	int i, j, k, l, m, n, count, num, record, num_match;
	double dx, dy, diff, sum_diff, length, length2;
	bool keep;
	String match_str;
	Arc_Data_Group *arc_ptr;
	Arc_Data_Itr arc_itr, arc2_itr;
	Shape_Record *shape_ptr;
	Shape_Itr shape_itr, shape2_itr;
	Points_Itr pt_itr;
	XYZ_Point pt;
	XY_Range box;
	Int_Itr int_itr;

	//---- write the arc data file ----

	num_match = (int) arc_data_array.size ();

	Show_Message ("Merging Shapefiles -- Record");
	Set_Progress ();

	//---- match shapes ----

	for (i = 0, arc_itr = arc_data_array.begin (); arc_itr != arc_data_array.end (); arc_itr++, i++) {
		for (j = 0, arc2_itr = arc_data_array.begin (); arc2_itr != arc_data_array.end (); arc2_itr++, j++) {

			if (i == j) continue;

			for (k = 0, shape_itr = arc_itr->shapes.begin (); shape_itr != arc_itr->shapes.end (); shape_itr++, k++) {
				for (l = 0, shape2_itr = arc2_itr->shapes.begin (); shape2_itr != arc2_itr->shapes.end (); shape2_itr++, l++) {
					Show_Progress ();

					if (!In_Extents (shape_itr->box, shape2_itr->box)) continue;

					count = 0;
					sum_diff = 0;

					if (arc2_itr->type == DOT) {
						pt = shape2_itr->shape [0];
						sum_diff += Point_Shape_Distance (pt, shape_itr->shape);
						count++;
					} else {
						if (arc_itr->type != DOT) {
							if (compass.Difference (shape_itr->direction, shape2_itr->direction) > 1) continue;
						}
						pt.x = pt.y = dx = dy = 0;

						for (m = 0, pt_itr = shape_itr->shape.begin (); pt_itr != shape_itr->shape.end (); pt_itr++, m++) {
							if (m == 0 || buffer <= 0.0) {
								num = 0;
							} else {
								dx = pt_itr->x - pt.x;
								dy = pt_itr->y - pt.y;

								num = MAX (DTOI (abs (dx) / buffer), DTOI (abs (dy) / buffer));

								if (num > 1) {
									dx /= num;
									dy /= num;
									num--;
								} else {
									num = 0;
								}
							}
							for (n = 0; n <= num; n++) {
								if (n == num) {
									pt = *pt_itr;
								} else {
									pt.x += dx;
									pt.y += dy;
								}
								if (!In_Extents (pt, shape2_itr->box)) continue;

								diff = Point_Shape_Distance (pt, shape2_itr->shape);

								if (count > 10) {
									if (diff > buffer && (sum_diff / count) < buffer) continue;
									if (diff < buffer && (sum_diff / count) > buffer) {
										sum_diff = 0;
										count = 0;
									}
								}
								sum_diff += diff;
								count++;
							}
						}
					}
					if (count > 0) {
						diff = sum_diff / count;

						if (diff <= buffer && diff < shape_itr->best [j]) {
							shape_itr->best [j] = diff;
							shape_itr->match [j] = l;
						}
					}
				}
			}
		}
	}
	End_Progress ();

	//---- apply like match logic ----

	if (like_flag) {
		for (i = 0, arc_itr = arc_data_array.begin (); arc_itr != arc_data_array.end (); arc_itr++, i++) {
			if (arc_itr->like_fld < 0) continue;
			arc_ptr = &arc_data_array [arc_itr->like_group];

			for (j = 0, shape2_itr = arc_ptr->shapes.begin (); shape2_itr != arc_ptr->shapes.end (); shape2_itr++, j++) {
				if (shape2_itr->match [i] >= 0 || shape2_itr->index.empty ()) continue;

				for (k = 0, shape_itr = arc_itr->shapes.begin (); shape_itr != arc_itr->shapes.end (); shape_itr++, k++) {
					if (shape_itr->like.empty ()) continue;

					if (shape2_itr->index.Starts_With (shape_itr->like)) {
						shape2_itr->match [i] = k;
						break;
					}
				}
			}
		}
	}

	//---- output the shorter shape records ----

	Show_Message (String ("Writing %s -- Record") % new_arc_file.File_Type ());
	Set_Progress ();

	record = 1;
	count = 0;

	for (i = 0, arc_itr = arc_data_array.begin (); arc_itr != arc_data_array.end (); arc_itr++, i++) {
		if (arc_itr->type == DOT) continue;

		for (k = 0, shape_itr = arc_itr->shapes.begin (); shape_itr != arc_itr->shapes.end (); shape_itr++, k++) {
			Show_Progress ();

			length = Shape_Length (shape_itr->shape);
			keep = false;

			for (j=0; j < num_match; j++) {
				if (i != j && shape_itr->match [j] >= 0) {
					arc_ptr = &arc_data_array [j];
					if (arc_ptr->type != DOT) {
						shape_ptr = &(arc_ptr->shapes [shape_itr->match [j]]);

						length2 = Shape_Length (shape_ptr->shape);

						if (length < length2 || (length == length2 && i < j)) {
							keep = true;
						}
					}
				}
			}
			if (keep) {
				new_arc_file.assign (shape_itr->shape.begin (), shape_itr->shape.end ());
				new_arc_file.Reset_Record ();

				//---- copy data fields ----

				if (field_flag) {
					arc_itr->data_db->Read_Record (k);
					new_arc_file.Copy_Fields (*(arc_itr->data_db));
					n = m = -1;

					for (j = 0; j < num_match; j++) {
						if (i != j) {
							arc_ptr = &arc_data_array [j];

							if (shape_itr->match [j] >= 0) {
								arc_ptr->data_db->Read_Record (shape_itr->match [j]);
								new_arc_file.Copy_Fields (*(arc_ptr->data_db));
								n = j;
								m = shape_itr->match [j];
							} else if (arc_ptr->type == DOT) {
								if (m >= 0) {
									arc_ptr = &arc_data_array [n];
									shape_ptr = &(arc_ptr->shapes [m]);
									
									if (shape_ptr->match [j] >= 0) {
										arc_ptr->data_db->Read_Record (shape_ptr->match [j]);
										new_arc_file.Copy_Fields (*(arc_ptr->data_db));
									}
								}
							}
						}
					}
				}

				//---- write the index fields ----

				new_arc_file.Put_Field (0, record++);
				new_arc_file.Put_Field (1, arc_itr->group);
				new_arc_file.Put_Field (arc_itr->new_field, shape_itr->index);
				n = m = -1;

				for (j = 0; j < num_match; j++) {
					if (i != j) {
						arc_ptr = &arc_data_array [j];

						if (shape_itr->match [j] >= 0) {
							shape_ptr = &(arc_ptr->shapes [shape_itr->match [j]]);
							new_arc_file.Put_Field (arc_ptr->new_field, shape_ptr->index);
							n = j;
							m = shape_itr->match [j];
						} else if (arc_ptr->type == DOT) {
							if (m >= 0) {
								arc_ptr = &arc_data_array [n];
								shape_ptr = &(arc_ptr->shapes [m]);

								if (shape_ptr->match [j] >= 0) {
									shape_ptr = &(arc_ptr->shapes [shape_ptr->match [j]]);
									new_arc_file.Put_Field (arc_ptr->new_field, shape_ptr->index);
								}
							}
						}
					}
				}
				if (new_arc_file.size () > 0) {
					if (!new_arc_file.Write_Record ()) {
						Error (String ("Writing %s") % new_arc_file.File_Type ());
					}
				}
				count++;
			}
		}
	}
	
	End_Progress ();

	Print (2, String ("Number of %s Records = %d") % new_arc_file.File_Type () % count);
		
	new_arc_file.Close ();
}
