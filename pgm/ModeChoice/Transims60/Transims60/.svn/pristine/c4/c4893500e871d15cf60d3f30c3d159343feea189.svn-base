//*********************************************************
//	Read_Constants.cpp - read the mode constants file
//*********************************************************

#include "ModeChoice.hpp"

//---------------------------------------------------------
//	Read_Constants
//---------------------------------------------------------

void ModeChoice::Read_Constants (void)
{
	int i, mode, segment, model, mode_field, segment_field;
	String text;
	Integers model_fields;
	double constant;
	Str_ID_Itr id_itr;

	Show_Message (String ("Reading %s -- Record") % constant_file.File_Type ());
	Set_Progress ();

	//---- identify the data fields ----

	mode_field = constant_file.Optional_Field ("MODE", "M", "MOD", "MODES");

	if (mode_field < 0) {
		Error ("Mode Constant Field Names are Not Defined");
	}
	if (constant_file.Optional_Field ("CONSTANT", "CONST") >= 0) {
		Warning ("Mode Constant Syntax No Longer Supports \"Constant\" Field");
	}
	segment_field = constant_file.Optional_Field ("SEGMENT", "SEG", "MARKET", "S");
	
	model_fields.assign (num_models, -1);

	for (i = first_model; i < num_models; i++) {
		model_fields [i] = constant_file.Field_Number (model_names [i]);
		if (model_fields [i] < 0) {
			Error (String ("Mode Constant Field \"%s\" was Not Found") % model_names [i]);
		}
	}

	//---- initialize the model constants ----

	while (constant_file.Read ()) {
		Show_Progress ();

		text = constant_file.Get_String (mode_field);
		if (text.empty ()) continue;

		id_itr = mode_id.find (text);
		if (id_itr == mode_id.end ()) {
			Warning ("Constant Mode ") << text << " was Not Defined";
			continue;
		}
		mode = id_itr->second;

		segment = constant_file.Get_Integer (segment_field);

		if (!segment_flag && segment != 0) {
			Error ("A Segment Map File is needed for Segment Constants");
		} else if (segment < 0 || segment > num_market) {
			Error (String ("Segment %d is Out of Range (1..%d)") % segment % num_market);
		}

		for (model=first_model; model < num_models; model++) {
			constant = constant_file.Get_Double (model_fields [model]);

			if (segment_flag && segment == 0) {
				for (i = 0; i <= num_market; i++) {
					seg_constant [i] [mode] [model] = constant;
				}
			} else {
				seg_constant [segment] [mode] [model] = constant;
			}
		}
	}
	End_Progress ();
	constant_file.Close ();
}
