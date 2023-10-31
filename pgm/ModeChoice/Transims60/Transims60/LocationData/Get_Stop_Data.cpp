//*********************************************************
//	Get_Stop_Data.cpp - additional transit stop processing
//*********************************************************

#include "LocationData.hpp"

#include "Shape_Tools.hpp"

//---------------------------------------------------------
//	Get_Stop_Data
//---------------------------------------------------------

bool LocationData::Get_Stop_Data (Stop_File &file, Stop_Data &stop_rec)
{
	Point_Map_Stat map_stat;

	if (Data_Service::Get_Stop_Data (file, stop_rec)) {
		Link_Data *link_ptr;
		Points points;
		XY xy;

		link_ptr = &link_array [stop_rec.Link ()];

		Link_Shape (link_ptr, stop_rec.Dir (), points, UnRound (stop_rec.Offset ()), 0.0, 0.0);

		if (points.size () > 0) {
			xy.x = Round (points [0].x);
			xy.y = Round (points [0].y);
		} else {
			Node_Data *node_ptr = &node_array [link_ptr->Anode ()];

			xy.x = node_ptr->X ();
			xy.y = node_ptr->Y ();
		}
		stop_xy.insert (XY_Map_Data ((int) stop_array.size (), xy));
		return (true);
	}
	return (false);
}
