//*********************************************************
//	Shape_Tools.hpp - network shape functions
//*********************************************************

#ifndef SHAPE_TOOLS_HPP
#define SHAPE_TOOLS_HPP

#include "APIDefs.hpp"
#include "TypeDefs.hpp"

bool SYSLIB_API Sub_Shape (Points &points, double offset, double length, double max_len = 0.0);
bool SYSLIB_API Connection_Curve (Points &in_pts, Points &out_pts, double turn_shape_setback);
bool SYSLIB_API Smooth_Shape (Points &points, int max_angle = 90, int min_length = 10);
int  SYSLIB_API X_Sort_Function (const void *rec1, const void *rec2);
bool SYSLIB_API In_Polygon (Points &points, double x, double y);
bool SYSLIB_API In_Extents (Points &points, Points &extents);
bool SYSLIB_API In_Extents (Points &points, XY_Range &range);
bool SYSLIB_API In_Extents (XY_Range &box, XY_Range &range);
bool SYSLIB_API In_Extents (XYZ_Point &pt, XY_Range &range);
bool SYSLIB_API Vehicle_Shape (XYZ_Point p1, XYZ_Point p2, double width, Points &points, bool front_flag = true);
bool SYSLIB_API Vehicle_Shape (Points &pts, double width, Points &points, bool front_flag = true);
bool SYSLIB_API Shift_Shape (Points &points, double side = 0.0, int dir = 0);

XY_Range SYSLIB_API Buffer_Box (XY_Range box, double buffer);
XY_Range SYSLIB_API Buffer_Box (XYZ_Point pt, double buffer);

double SYSLIB_API Point_Shape_Distance (XYZ_Point pt, Points &points);
double SYSLIB_API Shape_Length (Points &points);

#endif