//********************************************************* 
//	Db_Field.cpp - database field
//*********************************************************

#include "Db_Field.hpp"

#include "Execution_Service.hpp"

//-----------------------------------------------------------
//	Db_Field constructor
//-----------------------------------------------------------

Db_Field::Db_Field (void)
{
	offset = 0;
	width = decimal = 0;
	type = DB_INTEGER;
	units = NO_UNITS;
	nest = NO_NEST;
}

//-----------------------------------------------------------
//	Set_Field
//-----------------------------------------------------------

bool Db_Field::Set_Field (const char *name, Field_Type type, int offset, double size, Units_Type units, Nest_Type nest) 
{
	if (*name == '\0') return (false);
	Name (name);
	Type (type);
	Offset (offset);
	Size (size);
	Units (units);
	Nest (nest);
	return (Size () > 0);
}

bool Db_Field::Set_Field (string name, Field_Type type, int offset, double size, Units_Type units, Nest_Type nest) 
{
	if (name.empty ()) return (false);
	Name (name);
	Type (type);
	Offset (offset);
	Size (size);
	Units (units);
	Nest (nest);
	return (Size () > 0);
}

//-----------------------------------------------------------
//	Size
//-----------------------------------------------------------

double Db_Field::Size (void)
{
	if (decimal > 9) {
		return ((double) width + (decimal / 100.0));
	} else {
		return ((double) width + (decimal / 10.0));
	}
}

void  Db_Field::Size (double size)
{
	if (size > 0) {
		width = (short) size;
		decimal = (short) ((size - width) * 100.0 + 0.5);
		if (decimal > 0 && (decimal % 10) == 0) {
			decimal /= 10;
		}
	} else {
		width = decimal = 0;
	}
}

