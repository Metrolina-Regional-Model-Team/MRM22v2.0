//*********************************************************
//	VissimTrips.hpp - convert VISSIM trip tables
//*********************************************************

#ifndef VISSIMTRIPS_HPP
#define VISSIMTRIPS_HPP

#include "Execution_Service.hpp"
#include "Db_File.hpp"
#include "Matrix_File.hpp"
#include "TypeDefs.hpp"

//---------------------------------------------------------
//	VissimTrips - execution class definition
//---------------------------------------------------------

class SYSLIB_API VissimTrips : public Execution_Service
{
public:
	VissimTrips (void);

	virtual void Execute (void);

protected:
	enum VissimTrips_Keys { 
		VISSIM_TRIP_FILE = 1, NEW_TRIP_TABLE_FILE, NEW_TRIP_TABLE_FORMAT, 
	};
	virtual void Program_Control (void);

private:
	Matrix_File new_file;

	//---- file groups ----

	typedef struct {
		int group;
		Db_File *file;
	} File_Group;

	typedef vector <File_Group>     File_Array;
	typedef File_Array::iterator    File_Itr;

	File_Array file_group;

	void Read_Vissim (void);
};
#endif
