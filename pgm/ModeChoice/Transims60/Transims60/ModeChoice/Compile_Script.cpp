//*********************************************************
//	Compile_Script.cpp - set data files for the user script
//*********************************************************

#include "ModeChoice.hpp"

//---------------------------------------------------------
//	Compile_Script
//---------------------------------------------------------

void ModeChoice::Compile_Script (void)
{
	int i;
	Db_Base *file;
	Str_Itr mode_itr;
	Int_Itr int_itr;
	String text;
	Db_Mat_Itr matrix_itr;
	Plan_Skim_File_Itr plan_skim_itr;
	Dbls_Array mode_zeros;

	//---- add fields to the trip file ----

	if (plan_flag) {
		trip_file.File_Access (MODIFY);
		trip_file.Create_Fields ();

		model_field = trip_file.Add_Field ("MODEL", DB_INTEGER, sizeof (int), NO_UNITS, true);
		segment_field = trip_file.Add_Field ("SEGMENT", DB_INTEGER, sizeof (int), NO_UNITS, true);

	} else {
		table_file->File_Access (MODIFY);

		period_field = table_file->Add_Field ("PERIOD", DB_INTEGER, sizeof (int), NO_UNITS, true);
		purpose_field = table_file->Add_Field ("PURPOSE", DB_INTEGER, sizeof (int), NO_UNITS, true);
		model_field = table_file->Add_Field ("MODEL", DB_INTEGER, sizeof (int), NO_UNITS, true);
		segment_field = table_file->Add_Field ("SEGMENT", DB_INTEGER, sizeof (int), NO_UNITS, true);

		num_access = (int) access_markets.size ();
		market_field = table_file->Num_Fields ();

		for (i = 1; i <= num_access; i++) {
			text ("ACCESS%d") % i;
			table_file->Add_Field (text, DB_DOUBLE, sizeof (double), NO_UNITS, true);
		}
	}

	//---- create mode files ----

	imp_field = 0;
	time_field = 1;
	walk_field = 2;
	auto_field = 3;
	wait_field = 4;
	lwait_field = 5;
	xwait_field = 6;
	tpen_field = 7;
	term_field = 8;
	dist_field = 9;
	cost_field = 10;
	xfer_field = 11;
	diff_field = 12;
	user_field = 13;
	bias_field = 14;
	pef_field = 15;
	cbd_field = 16;
	const_field = 17;
	plan_field = 18;

	for (mode_itr = mode_names.begin (); mode_itr != mode_names.end (); mode_itr++) {
		file = new Db_Base (MODIFY, BINARY);
		file->File_ID (*mode_itr);

		file->Add_Field ("IMPED", DB_DOUBLE, sizeof (double), NO_UNITS, true);
		file->Add_Field ("TIME", DB_DOUBLE, sizeof (double), NO_UNITS, true);
		file->Add_Field ("WALK", DB_DOUBLE, sizeof (double), NO_UNITS, true);
		file->Add_Field ("AUTO", DB_DOUBLE, sizeof (double), NO_UNITS, true);
		file->Add_Field ("WAIT", DB_DOUBLE, sizeof (double), NO_UNITS, true);
		file->Add_Field ("LWAIT", DB_DOUBLE, sizeof (double), NO_UNITS, true);
		file->Add_Field ("XWAIT", DB_DOUBLE, sizeof (double), NO_UNITS, true);
		file->Add_Field ("TPEN", DB_DOUBLE, sizeof (double), NO_UNITS, true);
		file->Add_Field ("TERM", DB_DOUBLE, sizeof (double), NO_UNITS, true);
		file->Add_Field ("DIST", DB_DOUBLE, sizeof (double), NO_UNITS, true);
		file->Add_Field ("COST", DB_DOUBLE, sizeof (double), NO_UNITS, true);
		file->Add_Field ("XFER", DB_DOUBLE, sizeof (double), NO_UNITS, true);
		file->Add_Field ("DIFF", DB_DOUBLE, sizeof (double), NO_UNITS, true);
		file->Add_Field ("USER", DB_DOUBLE, sizeof (double), NO_UNITS, true);
		file->Add_Field ("BIAS", DB_DOUBLE, sizeof (double), NO_UNITS, true);
		file->Add_Field ("PEF", DB_DOUBLE, sizeof (double), NO_UNITS, true);
		file->Add_Field ("CBD", DB_DOUBLE, sizeof (double), NO_UNITS, true);
		file->Add_Field ("CONSTANT", DB_DOUBLE, sizeof (double), NO_UNITS, true);
		if (plan_flag) {
			file->Add_Field ("PLAN", DB_INTEGER, sizeof (short), NO_UNITS, true);
		}
		data_rec.push_back (file);
	}

	//---- create the program data structure ----

	data_rec.push_back (&org_db);
	data_rec.push_back (&des_db);

	if (plan_flag) {
		data_rec.push_back (&trip_file);

		for (plan_skim_itr = plan_skims.begin (); plan_skim_itr != plan_skims.end (); plan_skim_itr++) {
			data_rec.push_back (*plan_skim_itr);
		}
	} else {
		data_rec.push_back (table_file);

		for (matrix_itr = skim_files.begin (); matrix_itr != skim_files.end (); matrix_itr++) {
			data_rec.push_back (*matrix_itr);
		}
	}
	Write (1, "Compiling Mode Choice Script");

	if (Report_Flag (PRINT_SCRIPT)) {
		Header_Number (PRINT_SCRIPT);

		if (!Break_Check (10)) {
			Print (1);
			Page_Header ();
		}
	}
	program.Initialize (data_rec, random.Seed () + 1);

	if (!program.Compile (script_file, Report_Flag (PRINT_SCRIPT))) {
		Error ("Compiling Mode Choice Script");
	}
	if (Report_Flag (PRINT_STACK)) {
		Header_Number (PRINT_STACK);

		program.Print_Commands (false);
	}
	Header_Number (0);
	Show_Message (1);
}