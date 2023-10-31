//*********************************************************
//	Heap_Queue.hpp - expanding circular queue
//*********************************************************

#ifndef HEAP_QUEUE_HPP
#define HEAP_QUEUE_HPP

#include "APIDefs.hpp"

#include <vector>
using namespace std;

//---------------------------------------------------------
//	Heap_Queue -- template class definition
//---------------------------------------------------------
//	Heap_Queue <Type> (int max_records = 200);
//
//	void Put_Back (Type &data);
//  void Put_First (Type &data);
//  bool Get_First (Type &data);
//
//  void Reset (void);
//	bool Max_Records (int max_records);
//  int  Max_Records (void);
//  bool Expand_Queue (void);
//  int  Number_Records (void);
//---------------------------------------------------------

template <typename Type>
class SYSLIB_API Heap_Queue
{
	typedef vector <Type> Type_Array;

public:

	//---------------------------------------------------------
	//	Heap_Queue constructor
	//---------------------------------------------------------

	Heap_Queue (int max_records = 200)
	{
		Max_Records (max_records);
		Reset ();
	}

	//---------------------------------------------------------
	//	Put_Back
	//---------------------------------------------------------

	void Put_Back (Type data)
	{
		if (num_records == max_records) {
			Expand_Queue ();
		}
		num_records++;
		type_array [last++] = data;

		if (last >= max_records) last = 0;
	}

	//---------------------------------------------------------
	//	Put_First
	//---------------------------------------------------------

	void Put_First (Type data)
	{
		if (num_records == max_records) {
			Expand_Queue ();
		}
		if (num_records == 0) {
			type_array [last++] = data;

			if (last >= max_records) last = 0;
		} else {
			first--;
			if (first < 0) first = max_records - 1;

			type_array [first] = data;
		}
		num_records++;		
	}

	//---------------------------------------------------------
	//	Get_First
	//---------------------------------------------------------

	bool Get_First (Type &data)
	{
		if (num_records <= 0) return (false);
		num_records--;

		data = type_array [first++];

		if (first >= max_records) first = 0;
		if (num_records == 0) {
			first = last = 0;
		}
		return (true);
	}

	//---------------------------------------------------------
	//	Reset
	//---------------------------------------------------------

	void Reset (void)
	{
		first = last = num_records = 0;
	}

	//---------------------------------------------------------
	//	Max_Records
	//---------------------------------------------------------

	bool Max_Records (int max_size)
	{
		type_array.resize (max_size);
		max_records = (int) type_array.size ();
		return (max_records > 0);
	}
	int Max_Records (void)
	{
		return (max_records);
	}

	//---------------------------------------------------------
	//	Expand_Queue
	//---------------------------------------------------------

	bool Expand_Queue (void)
	{
		int i, j;
		int size = MAX (max_records + 1000, (int) (max_records * 1.1));
		Type_Array temp;
		Type data;
		temp.assign (size, data);

		for (i = 0, j = first; i < num_records; i++, j++) {
			if (j == max_records) j = 0;
			temp [i] = type_array [j];
			last = i;
		}
		first = 0;
		type_array.swap (temp);
		max_records = (int) type_array.size ();
		return (max_records > 0);
	}

	//---------------------------------------------------------
	//	Number_Records
	//---------------------------------------------------------

	int Number_Records (void)
	{
		return (num_records);
	}

private:

	//---- data ----

	int num_records, max_records, first, last;

	Type_Array type_array;
};

#endif

