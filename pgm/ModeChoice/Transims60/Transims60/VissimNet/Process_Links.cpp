//*********************************************************
//	Process_Links.cpp - process link data
//*********************************************************

#include "VissimNet.hpp"

#include "Shape_Tools.hpp"

//---------------------------------------------------------
//	Process_Links
//---------------------------------------------------------

void VissimNet::Process_Links (void)
{
	int min_len, short_len, setback;
	double dx, dy, len;

	Int_Map_Itr map_itr;
	Link_Itr link_itr;
	Shape_Data *shape_ptr;
	Dir_Data *dir_ptr;
	Node_Data *node_ptr;
	XYZ_Itr pt_itr;
	XYZ pt;
	Points points;
	Points_Itr pts_itr;
	XYZ_Point point;

	min_len = Round (1);
	short_len = Round (10);
	setback = short_len / 2;

	for (link_itr = link_array.begin (); link_itr != link_array.end (); link_itr++) {

		if (link_itr->Length () == 0 || link_itr->Anode () < 0 || link_itr->Bnode () < 0) continue;

		//---- smooth the shape ----

		if (link_itr->Shape () >= 0) {
			shape_ptr = &shape_array [link_itr->Shape ()];
			points.clear ();

			node_ptr = &node_array [link_itr->Anode ()];

			point.x = UnRound (node_ptr->X ());
			point.y = UnRound (node_ptr->Y ());
			points.push_back (point);

			pt = shape_ptr->front ();

			dx = pt.x - node_ptr->X ();
			dy = pt.y - node_ptr->Y ();
			len = sqrt (dx * dx + dy * dy);

			link_itr->Aoffset ((int) len);

			for (pt_itr = shape_ptr->begin (); pt_itr != shape_ptr->end (); pt_itr++) {
				point.x = UnRound (pt_itr->x);
				point.y = UnRound (pt_itr->y);
				points.push_back (point);
			}
			node_ptr = &node_array [link_itr->Bnode ()];

			point.x = UnRound (node_ptr->X ());
			point.y = UnRound (node_ptr->Y ());
			points.push_back (point);

			pt = shape_ptr->back ();

			dx = pt.x - node_ptr->X ();
			dy = pt.y - node_ptr->Y ();
			len = sqrt (dx * dx + dy * dy);

			link_itr->Boffset ((int) len);

			if (Smooth_Shape (points, 30, 2)) {
				if (points.size () > 2) {
					shape_ptr->clear ();

					for (pts_itr = points.begin () + 1; (pts_itr + 1) != points.end (); pts_itr++) {
						pt.x = Round (pts_itr->x);
						pt.y = Round (pts_itr->y);
						shape_ptr->push_back (pt);
					}
				} else {
					link_itr->Shape (-1);
					shape_ptr->clear ();
				}
			}
		}

		//---- update the link length ----

		len = 0;
		node_ptr = &node_array [link_itr->Anode ()];

		pt.x = node_ptr->X ();
		pt.y = node_ptr->Y ();

		if (link_itr->Shape () >= 0) {
			shape_ptr = &shape_array [link_itr->Shape ()];
			
			for (pt_itr = shape_ptr->begin (); pt_itr != shape_ptr->end (); pt_itr++) {
				dx = pt_itr->x - pt.x;
				dy = pt_itr->y - pt.y;

				len += sqrt (dx * dx + dy * dy);

				pt = *pt_itr;
			}
		}
		node_ptr = &node_array [link_itr->Bnode ()];

		dx = pt.x - node_ptr->X ();
		dy = pt.y - node_ptr->Y ();

		len += sqrt (dx * dx + dy * dy);

		link_itr->Length (DTOI (len));

		if (link_itr->Length () < min_len) {
			Warning (String ("Link %d is Too Short (%.1lf < %.1lf)") % link_itr->Link () % UnRound (link_itr->Length ()) % UnRound (min_len));

			link_itr->Aoffset (0);
			link_itr->Boffset (0);
		} else {
			if (link_itr->Length () > short_len) {
				if (link_itr->Aoffset () < setback) {
					link_itr->Aoffset (setback);
				}
				if (link_itr->Boffset () < setback) {
					link_itr->Boffset (setback);
				}
			}
			len *= 0.9;

			if (link_itr->Aoffset () + link_itr->Boffset () > len) {
				len /= (link_itr->Aoffset () + link_itr->Boffset ());
				link_itr->Aoffset (DTOI (link_itr->Aoffset () * len));
				link_itr->Boffset (DTOI (link_itr->Boffset () * len));
			}
		}

		//---- facility type ----

		map_itr = type_map.find (link_itr->Area_Type ());
		if (map_itr != type_map.end ()) {
			if (map_itr->second < 0) {
				link_itr->Type (-map_itr->second);
				link_itr->Use (Use_Code ("BUS|HOV2+"));
			} else {
				link_itr->Type (map_itr->second);
				link_itr->Use (Use_Code ("CAR|TRUCK|BUS"));
			}
		} else {
			Warning (String ("Link %d Type %d was Not Defined") % link_itr->Link () % link_itr->Area_Type ());
		}

		//---- speed ----

		dir_ptr = &dir_array [link_itr->AB_Dir ()];

		map_itr = speed_map.find (dir_ptr->Speed ());
		if (map_itr != speed_map.end ()) {
			dir_ptr->Speed (UnRound (map_itr->second) * 1000.0 / 3600.0);
		} else if (dir_ptr->Speed () != 0) {
			Warning (String ("Link %d Speed %d was Not Defined") % link_itr->Link () % dir_ptr->Speed ());
		} else if (link_itr->Type () == FREEWAY) {
			dir_ptr->Speed (28.0);
		} else if (link_itr->Type () == RAMP) {
			dir_ptr->Speed (15.0);
		} else if (link_itr->Type () == MAJOR) {
			dir_ptr->Speed (21.0);
		} else if (link_itr->Type () == MINOR) {
			dir_ptr->Speed (16.0);
		} else if (link_itr->Type () == COLLECTOR) {
			dir_ptr->Speed (13.0);
		} else if (link_itr->Type () == LOCAL) {
			dir_ptr->Speed (11.0);
		}
	}
} 
