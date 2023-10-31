//*********************************************************
//	Run_Summary.cpp - summarized run times
//*********************************************************

#include "Reschedule.hpp"

//---------------------------------------------------------
//	Run_Summary
//---------------------------------------------------------

void Reschedule::Run_Summary (int mode, int route, int run, Dtime start, Dtime old_tod, Dtime new_tod)
{
	old_tod = old_tod - start;
	new_tod = new_tod - start;

	if (change_flag) {
		run_change.mode = mode;
		run_change.route = route;

		if (run == 0) {
			run_change.count = 1;
			run_change.old_min = run_change.old_max = run_change.old_run = old_tod;
			run_change.new_min = run_change.new_max = run_change.new_run = new_tod;
		} else {
			if (run_change.old_min > old_tod) {
				run_change.old_min = old_tod;
			}
			if (run_change.old_max < old_tod) {
				run_change.old_max = old_tod;
			}
			run_change.old_run += old_tod;

			if (run_change.new_min > new_tod) {
				run_change.new_min = new_tod;
			}
			if (run_change.new_max < new_tod) {
				run_change.new_max = new_tod;
			}
			run_change.new_run += new_tod;
			run_change.count++;
		}
	}
	if (file_flag) {
		change_file.Put_Field (mode_field, mode);
		change_file.Put_Field (line_field, route);
		change_file.Put_Field (run_field, (run + 1));
		change_file.Put_Field (start_field, start);
		change_file.Put_Field (old_field, old_tod);
		change_file.Put_Field (new_field, new_tod);
		change_file.Write ();
	}
}
