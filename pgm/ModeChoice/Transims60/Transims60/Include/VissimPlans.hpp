//*********************************************************
//	VissimPlans.hpp - convert VISSIM path files
//*********************************************************

#ifndef VISSIMPLANS_HPP
#define VISSIMPLANS_HPP

#include "Data_Service.hpp"
#include "Db_File.hpp"
#include "Matrix_File.hpp"
#include "TypeDefs.hpp"

//---------------------------------------------------------
//	VissimPlans - execution class definition
//---------------------------------------------------------

class SYSLIB_API VissimPlans : public Data_Service
{
public:
	VissimPlans (void);

	virtual void Execute (void);

protected:
	enum VissimPlans_Keys { 
		VISSIM_PATH_FILE = 1, NEW_TRANSIMS_PATH_FILE, NEW_TRANSIMS_PATH_FORMAT,
	};
	virtual void Program_Control (void);

private:
	bool path_flag;
	Db_File path_file;
	Plan_File *new_file;
	Plan_File path_plan;

	//---- edge data ----

	typedef struct {
		int edge;
		int origin;
		int destination;
		Integers links;
	} Edge_Data;

	typedef vector <Edge_Data>     Edge_Array;
	typedef Edge_Array::iterator   Edge_Itr;

	Edge_Array edge_array;
	Int_Map edge_map;

	//---- path data ----

	typedef struct {
		int path;
		int origin;
		int destination;
		Integers edges;
		Integers trips;
	} Path_Data;

	typedef vector <Path_Data>     Path_Array;
	typedef Path_Array::iterator   Path_Itr;

	Path_Array path_array;

	void Read_Vissim (void);
	void Build_Plans (void);
};
#endif
