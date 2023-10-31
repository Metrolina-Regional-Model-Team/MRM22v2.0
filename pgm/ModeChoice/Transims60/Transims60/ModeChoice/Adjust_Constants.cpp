//*********************************************************
//	Adjust_Constants - perform mode choice calibration
//*********************************************************

#include "ModeChoice.hpp"

#include <math.h>

//---------------------------------------------------------
//	Adjust_Constatns
//---------------------------------------------------------

bool ModeChoice::Adjust_Constants (void)
{
	int n, seg, s1, s2, s, count, model, mode, m;
	double target, trips, total_target, total_trips, constant, total;
	double target_sq, trip_sq, target_trip, error, error_sq, per_error, factor, nest_fac, diff, rmse, max_rmse;
	bool distribute_flag;

	Market_Seg current_const;
	Integers *nest_ptr;
	Int_Itr mode_itr;
	String text;

	max_rmse = 0;

	if (calib_seg_flag) {
		s1 = 1;
		s2 = num_market;
		distribute_flag = false;
	} else {
		s1 = s2 = 0;
		distribute_flag = segment_flag;
	}
	current_const = seg_constant;

	//---- process each model ----

	for (model = first_model; model < num_models; model++) {
		count = 0;
		rmse = error_sq = total = error = per_error = 0;

		//---- process each segment ----

		for (seg = s1; seg <= s2; seg++) {

			//---- normalize to the calibration targets ----

			nest_ptr = &nested_modes [0];
			target = trips = 0;

			for (mode_itr = nest_ptr->begin (); mode_itr != nest_ptr->end (); mode_itr++) {
				mode = *mode_itr;
				target += calib_target [seg] [mode] [model];
				trips += market_seg [seg] [mode] [model];
			}
			if (target > 0.0 && trips != target) {
				factor = trips / target;

				for (mode = 0; mode < num_modes; mode++) {
					calib_target [seg] [mode] [model] *= factor;
				}
			}

			//---- calculate adjustment factors ----

			for (n = 0; n < num_nests; n++) {
				nest_ptr = &nested_modes [n];
				target = trips = 0;

				for (mode_itr = nest_ptr->begin (); mode_itr != nest_ptr->end (); mode_itr++) {
					mode = *mode_itr;
					target += calib_target [seg] [mode] [model];
					trips += market_seg [seg] [mode] [model];
				}
				if (target > 0.0) {
					nest_fac = trips / target;
				} else {
					nest_fac = 1.0;
				}
				for (m=0, mode_itr = nest_ptr->begin (); mode_itr != nest_ptr->end (); mode_itr++, m++) {
					mode = *mode_itr;
					target = calib_target [seg] [mode] [model];
					trips = market_seg [seg] [mode] [model];
					diff = target - trips;

					//---- write the calibration data ----
					
					if (data_flag) {
						if (target > 0) {
							per_error = 100.0 * diff / target;
						} else {
							per_error = 0.0;
						}
						data_file.File () << iteration << "\t";
					
						if (seg > 0) {
							data_file.File () << seg << "\t";
						}
						if (calib_model_flag) {
							data_file.File () << model_names [model] << "\t";
						}
						text ("%s\t%.0lf\t%.0lf\t%.0lf\t%.1lf%%") % mode_names [mode] % target % trips % diff % per_error % FINISH;
					
						data_file.File () << text << (String ("\t%.6lf") % current_const [seg] [mode] [model]) << endl;
					}
					if (mode_nested [mode] < 0) {
						count++;
						error_sq += diff * diff;
						total += target;
					}

					if (m == 0 && !first_mode_flag) continue;

					if (trips > 0) {
						factor = target * nest_fac / trips;
						constant = seg_constant [seg] [mode] [model] + log (factor);

						if (constant < min_const [seg] [mode]) {
							constant = min_const [seg] [mode];
						} else if (constant > max_const [seg] [mode]) {
							constant = max_const [seg] [mode];
						}
					} else if (target > 0) {
						constant = max_const [seg] [mode];
					} else {
						constant = 0;
					}
					seg_constant [seg] [mode] [model] = constant;

					if (distribute_flag) {
						for (s = 1; s <= num_market; s++) {
							seg_constant [s] [mode] [model] = constant;
						}
					}
				}
			}
		}

		//---- calculate the rmse ----

		factor = (double) count;
		if (factor > 0 && total > 0) {
			rmse = 100.0 * sqrt (error_sq / factor) * factor / total;
			if (rmse > max_rmse) max_rmse = rmse;
		}

		//---- write the calibration report ----

		if (calib_report) {
			header_value = iteration;
			model_num = model;
			Header_Number (CALIB_REPORT);

			if (!Break_Check (num_modes + 8)) {
				Print (1);
				Calib_Header ();
			}
			total_target = total_trips = target_sq = trip_sq = target_trip = error = per_error = 0.0;

			for (seg = s1; seg <= s2; seg++) {
				for (mode = 0; mode < num_modes; mode++) {
					trips = market_seg [seg] [mode] [model];
					target = calib_target [seg] [mode] [model];

					diff = trips - target;
					if (target > 0) {
						factor = diff * 100.0 / target;
					} else {
						factor = 0.0;
					}
					Print (1, "");
					if (calib_seg_flag) {
						Print (0, String ("%4d    ") % seg);
					}
					Print (0, String ("%-20s  %8.0lf  %8.0lf    %8.0lf  %6.1lf%%") %
						mode_names [mode] % target % trips % diff % factor % FINISH);

					constant = current_const [seg] [mode] [model];

					Print (0, String ("  %10.6lf") % constant);

					if (mode_nested [mode] < 0) {
						for (m = mode_nest [mode]; m >= 0; m = mode_nest [m]) {
							constant = constant * nest_coef [mode_nested [m]] + current_const [seg] [m] [model];
							constant = log (exp (constant));
						}
						constant /= -time_values [first_model];
						Print (0, String ("  %6.1lf") % constant);
					}

					//---- bottom line statistics ----

					if (mode_nested [mode] < 0) {
						total_trips += trips;
						trip_sq += trips * trips;
						total_target += target;
						target_sq += target * target;
						target_trip += target * trips;
						diff = fabs (diff);
						error += diff;
						if (target > 0) {
							per_error += diff / target;
						}
					}
				}
			}

			//---- write statistics ----

			if (total_target > 0) {
				diff = error * 100.0 / total_target;
			} else {
				diff = 0;
			}
			text ("%.1lf%%") % diff % FINISH;

			Print (2, String ("Abs.Error = %-6s") % text);

			factor = (double) count;

			if (count > 0) {
				diff = per_error * 100.0 / factor;
			} else {
				diff = 0;
			}
			text ("%.1lf%%") % diff % FINISH;

			Print (0, String ("  Avg.Error = %-7s") % text);

			text ("%.1lf%%") % rmse % FINISH;
			Print (0, String ("  RMSE = %-6s") % text);

			if (factor > 0) {
				diff = (trip_sq - total_trips * total_trips / factor) * (target_sq - total_target * total_target / factor);
			} else {
				diff = 0;
			}
			if (diff != 0.0) {
				diff = (target_trip - total_target * total_trips / factor) / sqrt (diff);
				diff *= diff;
			} else {
				diff = 0.0;
			}
			Print (0, String ("  R-Squared = %5.3lf") % diff);

			Header_Number (0);
		}
	}
	calib_trips = market_seg;
	calib_const = current_const;

	//---- write the calibration data file ----

	if (new_calib_flag && (save_flag || iter_save_flag)) {
		for (seg = s1; seg <= s2; seg++) {
			for (mode = 0; mode < num_modes; mode++) {
				n = 0;
				if (calib_seg_flag) {
					calib_file.Put_Field (n++, seg);
				}
				calib_file.Put_Field (n++, mode_names [mode]);

				for (model = first_model; model < num_models; model++) {
					calib_file.Put_Field (n++, calib_const [seg] [mode] [model]);
				}
				calib_file.Write ();
			}
		}
	}
	if (plan_flag) {
		text ("RMSE=%.1lf%%") % max_rmse % FINISH;
	} else {
		text ("%d  RMSE=%.1lf%%") % zones % max_rmse % FINISH;
	}
	End_Progress (text);

	return (max_rmse <= exit_rmse);
}

//---------------------------------------------------------
//	Calib_Header
//---------------------------------------------------------

void ModeChoice::Calib_Header (void)
{
	Print (1, "Calibration Report for Iteration #") << header_value << " -- " << model_names [model_num];
	Print (2, "");
	if (calib_seg_flag) {
		Print (0, "Segment ");
	}
	Print (0, "Trips by Mode           Target     Trips  Difference  Percent    Constant  Minutes");
	Print (1);
}

/*********************************************|***********************************************

	Calibration Report for Iteration #dd -- sssssssssssss

	Trips by Mode           Target     Trips  Difference  Percent    Constant  Minutes

	ssssssss20ssssssssss  ffffffff  ffffffff    ffffffff  ffff.f%  fff.ffffff  ffff.f

or
	Segment  Trips by Mode           Target     Trips  Difference  Percent    Constant  Minutes

	 dddd    ssssssss20ssssssssss  ffffffff  ffffffff    ffffffff  ffff.f%  fff.ffffff  ffff.f

	Abs.Error = fff.f%  Avg.Error = ffff.f%  RMSE = fff.f%  R-Squared = f.fff

**********************************************|***********************************************/ 
