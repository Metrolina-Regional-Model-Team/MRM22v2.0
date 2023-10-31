//*********************************************************
//	Put_Location_Data.cpp - write a new location file
//*********************************************************

#include "VissimNet.hpp"

//---------------------------------------------------------
//	Put_Location_Data
//---------------------------------------------------------

int VissimNet::Put_Location_Data (Location_File &file, Location_Data &data)
{
	file.Put_Field (org_field, data.X ());
	file.Put_Field (des_field, data.Y ());

	return (Data_Service::Put_Location_Data (file, data));
}

