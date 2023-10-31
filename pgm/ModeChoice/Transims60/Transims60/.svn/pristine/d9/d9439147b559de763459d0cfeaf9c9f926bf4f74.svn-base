//*********************************************************
//	ArcJoin.hpp - Traffic Count Processing
//*********************************************************

#ifndef ARCJOIN_HPP
#define ARCJOIN_HPP

#include "Data_Service.hpp"
#include "Arcview_File.hpp"
#include "Projection_Service.hpp"
#include "Db_Header.hpp"
#include "Db_Array.hpp"
#include "TypeDefs.hpp"
#include "Compass.hpp"
#include "Shape_Tools.hpp"

//---------------------------------------------------------
//	ArcJoin - execution class definition
//---------------------------------------------------------

class SYSLIB_API ArcJoin : public Data_Service
{
public:
	ArcJoin (void);

	virtual void Execute (void);

protected:
	enum CountSum_Keys { 
		ARC_DATA_FILE = 1, DATA_INDEX_FIELD, DIRECTION_FIELD, SPLIT_DIRECTIONS, DIRECTION_OFFSET, SELECT_DATA_FIELDS, NEW_ARC_DATA_FILE, 
		LIKE_MATCH_FIELD, COORDINATE_BUFFER, NEW_ARC_JOIN_FILE, INCLUDE_DATA_FIELDS
	};
	virtual void Program_Control (void);

private:

	typedef struct {
		Points shape;
		XY_Range box;
		int direction;
		Integers  match;
		Doubles best;
		String index;
		String like;
	} Shape_Record;

	typedef vector <Shape_Record>    Shape_Array;
	typedef Shape_Array::iterator    Shape_Itr;

	//---- arc data groups ----

	typedef struct {
		int group;
		Arcview_File *file;
		Arcview_File *new_file;
		Db_Data_Array *data_db;
		Shape_Array shapes;
		String id_name;
		int id_field;
		int dir_field;
		int new_field;
		int type;
		bool split;
		bool new_flag;
		float offset;
		Integers select;
		String like_name;
		int like_fld;
		int like_len;
		int like_group;
	} Arc_Data_Group;

	typedef vector <Arc_Data_Group>     Arc_Data_Array;
	typedef Arc_Data_Array::iterator    Arc_Data_Itr;

	Arc_Data_Array arc_data_array;
	Arcview_File new_arc_file;

	Projection_Service projection;
	Compass_Points compass;

	bool new_arc_flag, field_flag, like_flag;
	double buffer;

	void Read_Arc_Data (void);
	void Write_Arc_Data (void);
};
#endif
