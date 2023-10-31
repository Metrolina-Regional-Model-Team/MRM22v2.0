//*************************************************** 
//	Projection.hpp - Coordinate Projection Class
//***************************************************

#ifndef PROJECTION_HPP
#define PROJECTION_HPP

#include "APIDefs.hpp"
#include "System_Defines.hpp"
#include "Static_Service.hpp"
#include "Projection_Service.hpp"
#include "String.hpp"
#include "TypeDefs.hpp"

//-------------------------------------
//	Projection Class definition
//-------------------------------------

class  SYSLIB_API Projection : public Static_Service
{
public:
	Projection (void);
	Projection (Projection_Service &service);

	bool Set_Projection (Projection_Service &service);

	bool Convert_In (double *x, double *y);
	bool Convert_Out (double *x, double *y);

	bool Convert_In (XYZ_Point *pt)    { return (Convert_In (&(pt->x), &(pt->y))); }
	bool Convert_In (XY_Point *pt)     { return (Convert_In (&(pt->x), &(pt->y))); }
	
	bool Convert_Out (XYZ_Point *pt)   { return (Convert_Out (&(pt->x), &(pt->y))); }
	bool Convert_Out (XY_Point *pt)    { return (Convert_Out (&(pt->x), &(pt->y))); }

	double Length_In_Factor (void);
	double Speed_In_Factor (void);

	double Length_Out_Factor (void);
	double Speed_Out_Factor (void);

	string& Get_Projection_String (void);

private:

	typedef struct {
		Projection_Data projection;
		double long_origin;
		double false_easting;
		double false_northing;
		double scale_factor;
		double a;
		double b;
		double e;
		double ef;
		double e_square;
		double e_prime_sq;
		double a1;
		double a2;
		double a3;
		double a4;
		double mo;
		double e1;
		double m1;
		double m2;
		double t1;
		double t2;
		double tf;
		double n;
		double sf;
		double rf;
		int  index;
		bool adjust;
	} Factor_Data;

	typedef struct {
		int code;
		double lat_origin;
		double long_origin;
		double first_parallel;
		double second_parallel;
		double false_easting;
		double false_northing;
		double scale_factor;
		char name [32];
	} SP_Data;

	typedef struct {
		int code;
		double lat_origin;
		double long_origin;
		double scale_factor;
		double false_easting;
		double false_northing;
		char name [4];
	} UTM_Data;
	
	bool Initialize (Factor_Data *data);

	void LatLongToUtm (Factor_Data *data, double *x, double *y);
	void UtmToLatLong (Factor_Data *data, double *x, double *y);
	void LatLongToSP (Factor_Data *data, double *x, double *y);
	void SPToLatLong (Factor_Data *data, double *x, double *y);

	Factor_Data input, data, output;
	bool status, convert_in_flag, convert_out_flag;

	static String projection;

	static SP_Data  sp_data [];
	static UTM_Data utm_data [];
};
#endif
