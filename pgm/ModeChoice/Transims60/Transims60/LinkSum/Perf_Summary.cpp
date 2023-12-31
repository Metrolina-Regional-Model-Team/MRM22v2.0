//*********************************************************
//	Perf_Summary.cpp - network performance details
//*********************************************************

#include "LinkSum.hpp"

#define LINKS		0
#define LENGTH		1
#define LANES		2
#define MAX_DEN		3
#define MAX_QUEUE	4
#define VMT			5
#define VHT			6
#define VHD			7
#define TIME_RATIO	8
#define DENSITY		9
#define QUEUE		10
#define FAILURE		11
#define TURNS		12
#define CONG_VMT	13
#define CONG_VHT	14
#define CONG_TIME	15
#define COUNT		16
#define PREV		17

//---------------------------------------------------------
//	Perf_Sum_Report
//---------------------------------------------------------

void LinkSum::Perf_Sum_Report (void)
{
	int i, j, k, k1, index, use_index;
	double length, base, diff, value, percent, factor, time, person_fac, lane_len, inc_per_hour, hours;
	Dtime low, high, tod, period;
	bool connect_flag;
	String units, vmt, lane_mi, label, type;

	Link_Itr link_itr;
	Dir_Data *dir_ptr;
	Perf_Period_Itr period_itr;
	Perf_Period *period_ptr;
	Perf_Data perf_data;
	Turn_Period_Itr turn_itr;
	Turn_Period *compare_ptr;
	Turn_Data *turn_ptr;
	Connect_Data *connect_ptr;
	Doubles_Itr itr;
	Performance_Data data;

	Show_Message ("Creating the Network Performance Details Report -- Record");
	Set_Progress ();

	//---- clear the summary bins -----

	for (j=0, itr = sum_bin.begin (); itr != sum_bin.end (); itr++, j++) {
		itr->assign (NUM_SUM_BINS, 0.0);
	}	
	if (compare_flag) {
		connect_flag = System_Data_Flag (CONNECTION) && (turn_period_array.size () > 0) && (compare_turn_array.size () > 0);
	} else {
		connect_flag = System_Data_Flag (CONNECTION) && (turn_period_array.size () > 0);
	}
	type = (person_flag) ? "Person" : "Vehicle";
	inc_per_hour = 0.0;

	//---- process each link ----

	for (link_itr = link_array.begin (); link_itr != link_array.end (); link_itr++) {
		Show_Progress ();

		if (select_flag && link_itr->Use () == 0) continue;

		length = UnRound (link_itr->Length ());

		for (i=0; i < 2; i++) {
			if (i) {
				if (link_itr->Use () == -1) continue;
				index = link_itr->BA_Dir ();
			} else {
				if (link_itr->Use () == -2) continue;
				index = link_itr->AB_Dir ();
			}
			if (index < 0) continue;
			dir_ptr = &dir_array [index];
			use_index = dir_ptr->Use_Index ();

			//---- process each time period ----

			for (j=0, period_itr = perf_period_array.begin (); period_itr != perf_period_array.end (); period_itr++, j++) {
				perf_period_array.periods->Period_Range (j, low, high);

				data.Start (low);
				data.End (high);

				perf_data = period_itr->Total_Performance (index, use_index);

				if (data.Get_Data (&perf_data, dir_ptr, &(*link_itr), Maximum_Time_Ratio ())) {

					if (person_flag && data.Volume () > 0) {
						person_fac = data.Persons () / data.Volume ();
					} else {
						person_fac = 1.0;
					}
					inc_per_hour = data.Count ();

					//---- check the time ratio ----

					if (select_ratio) {
						if (data.Time_Ratio () < time_ratio) continue;
					}

					//---- check the vc ratio ----

					if (select_vc) {
						if (data.VC_Ratio () < vc_ratio) continue;
					}
					lane_len = data.Lane_Len ();

					sum_bin [j] [LINKS] += 1;
					sum_bin [j] [LENGTH] += length;
					sum_bin [j] [LANES] += lane_len;
					sum_bin [j] [VMT] += data.Veh_Dist () * person_fac;
					sum_bin [j] [VHT] += data.Veh_Time () * person_fac;
					sum_bin [j] [VHD] += data.Veh_Delay () * person_fac;
					sum_bin [j] [TIME_RATIO] += data.Time_Ratio () * lane_len;
					sum_bin [j] [DENSITY] += data.Density () * person_fac;
					sum_bin [j] [MAX_DEN] = MAX (sum_bin [j] [MAX_DEN], data.Max_Density () * person_fac);
					sum_bin [j] [QUEUE] += data.Queue () * person_fac;
					sum_bin [j] [MAX_QUEUE] = MAX (sum_bin [j] [MAX_QUEUE], data.Max_Queue () * person_fac);
					sum_bin [j] [FAILURE] += data.Failure () * person_fac;
					sum_bin [j] [COUNT] += data.Count () * lane_len;

					if (Ratio_Flag ()) {
						sum_bin [j] [CONG_VMT] += data.Ratio_Dist () * person_fac;
						sum_bin [j] [CONG_VHT] += data.Ratio_Time () * person_fac;
						sum_bin [j] [CONG_TIME] += data.Ratios () * lane_len;
					}
				}

				if (compare_flag) {
					period_ptr = &compare_perf_array [j];
					perf_data = period_ptr->Total_Performance (index, use_index);

					if (data.Get_Data (&perf_data, dir_ptr, &(*link_itr), Maximum_Time_Ratio ())) {

						if (person_flag && data.Volume () > 0) {
							person_fac = data.Persons () / data.Volume ();
						} else {
							person_fac = 1.0;
						}
						lane_len = data.Lane_Len ();

						sum_bin [j] [LINKS+PREV] += 1;
						sum_bin [j] [LENGTH+PREV] += length;
						sum_bin [j] [LANES+PREV] += lane_len;
						sum_bin [j] [VMT+PREV] += data.Veh_Dist () * person_fac;
						sum_bin [j] [VHT+PREV] += data.Veh_Time () * person_fac;
						sum_bin [j] [VHD+PREV] += data.Veh_Delay () * person_fac;
						sum_bin [j] [TIME_RATIO+PREV] += data.Time_Ratio () * lane_len;
						sum_bin [j] [DENSITY+PREV] += data.Density () * person_fac;
						sum_bin [j] [MAX_DEN+PREV] = MAX (sum_bin [j] [MAX_DEN+PREV], data.Max_Density () * person_fac);
						sum_bin [j] [QUEUE+PREV] += data.Queue () * person_fac;
						sum_bin [j] [MAX_QUEUE+PREV] = MAX (sum_bin [j] [MAX_QUEUE+PREV], data.Max_Queue () * person_fac);
						sum_bin [j] [FAILURE+PREV] += data.Failure () * person_fac;
						sum_bin [j] [COUNT+PREV] += data.Count () * lane_len;

						if (Ratio_Flag ()) {
							sum_bin [j] [CONG_VMT+PREV] += data.Ratio_Dist () * person_fac;
							sum_bin [j] [CONG_VHT+PREV] += data.Ratio_Time () * person_fac;
							sum_bin [j] [CONG_TIME+PREV] += data.Ratios () * lane_len;
						}
					}
				}
			}

			//---- get the turning movements ----

			if (connect_flag) {
				for (k=dir_ptr->First_Connect (); k >= 0; k = connect_ptr->Next_Index ()) {
					connect_ptr = &connect_array [k];

					if (connect_ptr->Type () != LEFT && connect_ptr->Type () != RIGHT &&
						connect_ptr->Type () != UTURN) continue;

					for (j=0, turn_itr = turn_period_array.begin (); turn_itr != turn_period_array.end (); turn_itr++, j++) {
						turn_ptr = &turn_itr->at (k);

						sum_bin [j] [VHD] += turn_ptr->Time () * turn_ptr->Turn ();
						sum_bin [j] [TURNS] += turn_ptr->Turn ();

						if (compare_flag) {
							compare_ptr = &compare_turn_array [j];
							turn_ptr = &compare_ptr->at (k);

							sum_bin [j] [VHD+PREV] += turn_ptr->Time () * turn_ptr->Turn ();
							sum_bin [j] [TURNS+PREV] += turn_ptr->Turn ();
						}
					}
				}
			}
		}
	}
	End_Progress ();

	//---- print the report ----

	Header_Number (PERF_SUMMARY);

	if (!Break_Check (num_inc * 21)) {
		Print (1);
		Perf_Sum_Header ();
	}
	if (Metric_Flag ()) {
		factor = 1.0 / 1000.0;
		units = "Kilometers";
		vmt = (person_flag) ? "PKT" : "VKT";
		lane_mi = "km)";
	} else {
		factor = 1.0 / MILETOFEET;
		units = "Miles";
		vmt = (person_flag) ? "PMT" : "VMT";
		lane_mi = "mi)";
	}
	tod.Hours (1);

	period = perf_period_array.periods->Increment ();
	hours = (double) period / (double) tod;
	if (inc_per_hour <= 0) inc_per_hour = 1.0;

	for (i=0; i <= num_inc; i++) {
		if (sum_bin [i] [LINKS] == 0.0) continue;

		if (i < num_inc) {
			for (k = 0; k <= COUNT; k++) {
				k1 = k + PREV;
				if (k < VMT) {
					sum_bin [num_inc] [k] = MAX (sum_bin [i] [k], sum_bin [num_inc] [k]);

					if (compare_flag) {
						sum_bin [num_inc] [k1] = MAX (sum_bin [i] [k1], sum_bin [num_inc] [k1]);
					}
				} else {
					sum_bin [num_inc] [k] += sum_bin [i] [k];

					if (compare_flag) {
						sum_bin [num_inc] [k1] += sum_bin [i] [k1];
					}
				}
			}
			lane_len = sum_bin [i] [LANES];
		} else {
			lane_len = 0;

			for (k=0; k < num_inc; k++) {
				lane_len += sum_bin [k] [LANES];
			}
		}
		if (lane_len == 0) lane_len = 1.0;

		if (i < num_inc && sum_bin [i] [VHT] == 0.0 && (!compare_flag || sum_bin [i] [VHT+PREV] == 0.0)) continue;
		if (i) {
			if (!Break_Check ((Ratio_Flag () ? 19 : 16))) {
				Print (1);
			}
		}
		Print (1, String ("Time Period%22c") % BLANK);

		if (i == num_inc) {
			Print (0, "       Total");
		} else {
			Print (0, String ("%12.12s") % sum_periods.Range_Format (i));
		}
		Print (1, String ("Number of Links                 %13.2lf") % sum_bin [i] [LINKS]);
		Print (1, String ("Number of Roadway %-10.10s    %13.2lf") % units % (sum_bin [i] [LENGTH] * factor));
		Print (1, String ("Number of Lane %-10.10s       %13.2lf") % units % (sum_bin [i] [LANES] * factor));

		label = type + " " + units + " of Travel";
		Print (1, String ("%-32.32s%13.2lf") % label % (sum_bin [i] [VMT] * factor));
		if (compare_flag) {
			base = sum_bin [i] [VMT+PREV] * factor;
			diff = sum_bin [i] [VMT] * factor - base;

			Print (0, String (" %13.2lf %13.2lf  (%.2lf%%)") % base % diff % ((base > 0.0) ? (100.0 * diff / base) : 0.0) % FINISH);
		}
		label = type + " Hours of Travel";
		Print (1, String ("%-32.32s%13.2lf") % label % (sum_bin [i] [VHT] / tod));
		if (compare_flag) {
			base = sum_bin [i] [VHT+PREV] / tod;
			diff = sum_bin [i] [VHT] / tod - base;

			Print (0, String (" %13.2lf %13.2lf  (%.2lf%%)") % base % diff % ((base > 0.0) ? (100.0 * diff / base) : 0.0) % FINISH);
		}	
		label = type + " Hours of Delay";
		Print (1, String ("%-32.32s%13.2lf") % label % (sum_bin [i] [VHD] / tod));
		if (compare_flag) {
			base = sum_bin [i] [VHD+PREV] / tod;
			diff = sum_bin [i] [VHD] / tod - base;

			Print (0, String (" %13.2lf %13.2lf  (%.2lf%%)") % base % diff % ((base > 0.0) ? (100.0 * diff / base) : 0.0) % FINISH);
		}
		label = String ("Number of Queued %ss") % type;
		Print (1, String ("%-32.32s%13.2lf") % label % UnRound (sum_bin [i] [QUEUE]));
		if (compare_flag) {
			base = sum_bin [i] [QUEUE+PREV];
			diff = sum_bin [i] [QUEUE] - base;

			Print (0, String (" %13.2lf %13.2lf  (%.2lf%%)") % base % diff % ((base > 0.0) ? (100.0 * diff / base) : 0.0) % FINISH);
		}
		label = String ("Maximum Queued %ss") % type;
		Print (1, String ("%-32.32s%13.2lf") % label % sum_bin [i] [MAX_QUEUE]);
		if (compare_flag) {
			base = sum_bin [i] [MAX_QUEUE+PREV];
			diff = sum_bin [i] [MAX_QUEUE] - base;

			Print (0, String (" %13.2lf %13.2lf  (%.2lf%%)") % base % diff % ((base > 0.0) ? (100.0 * diff / base) : 0.0) % FINISH);
		}
		Print (1, String ("Number of Cycle Failures        %13.2lf") % sum_bin [i] [FAILURE]);
		if (compare_flag) {
			base = sum_bin [i] [FAILURE+PREV];
			diff = sum_bin [i] [FAILURE] - base;

			Print (0, String (" %13.2lf %13.2lf  (%.2lf%%)") % base % diff % ((base > 0.0) ? (100.0 * diff / base) : 0.0) % FINISH);
		}
		Print (1, String ("Number of Turning Movements     %13.2lf") % sum_bin [i] [TURNS]);
		if (compare_flag) {
			base = sum_bin [i] [TURNS+PREV];
			diff = sum_bin [i] [TURNS] - base;

			Print (0, String (" %13.2lf %13.2lf  (%.2lf%%)") % base % diff % ((base > 0.0) ? (100.0 * diff / base) : 0.0) % FINISH);
		}

		Print (1, String ("Average Link Time Ratio         %13.2lf") % (sum_bin [i] [TIME_RATIO] / (lane_len * 100)));
		if (compare_flag) {
			base = sum_bin [i] [TIME_RATIO+PREV] / (sum_bin [i] [COUNT+PREV] * 100.0);
			diff = sum_bin [i] [TIME_RATIO] / (lane_len * 100.0) - base;

			Print (0, String (" %13.2lf %13.2lf  (%.2lf%%)") % base % diff % ((base > 0.0) ? (100.0 * diff / base) : 0.0) % FINISH);
		}

		value = sum_bin [i] [LINKS];
		if (i == num_inc) value *= num_inc;

		Print (1, String ("Average Link Density (/ln-%s   %13.2lf") % lane_mi % UnRound (sum_bin [i] [DENSITY] / value));
		if (compare_flag) {
			base = UnRound (sum_bin [i] [DENSITY+PREV] / value);
			diff = UnRound (sum_bin [i] [DENSITY] / value) - base;

			Print (0, String (" %13.2lf %13.2lf  (%.2lf%%)") % base % diff % ((base > 0.0) ? (100.0 * diff / base) : 0.0) % FINISH);
		}
		Print (1, String ("Maximum Link Density (/ln-%s   %13.2lf") % lane_mi % UnRound (sum_bin [i] [MAX_DEN]));
		if (compare_flag) {
			base = UnRound (sum_bin [i] [MAX_DEN+PREV]);
			diff = UnRound (sum_bin [i] [MAX_DEN]) - base;

			Print (0, String (" %13.2lf %13.2lf  (%.2lf%%)") % base % diff % ((base > 0.0) ? (100.0 * diff / base) : 0.0) % FINISH);
		}
		length = sum_bin [i] [VMT] * factor;
		time = sum_bin [i] [VHT] / tod;
		if (time == 0.0) {
			time = length;
		} else {
			time = length / time;
		}
		Print (1, String ("Average %-19.19s     %13.2lf") % (units + " per Hour") % time);
		if (compare_flag) {
			length = sum_bin [i] [VMT+PREV] * factor;
			base = sum_bin [i] [VHT+PREV] / tod;
			if (base == 0.0) {
				base = length;
			} else {
				base = length / base;
			}
			diff = time - base;

			Print (0, String (" %13.2lf %13.2lf  (%.2lf%%)") % base % diff % ((base > 0.0) ? (100.0 * diff / base) : 0.0) % FINISH);
		}

		if (Ratio_Flag ()) {
			label = "Congested " + type + " " + units;
			Print (1, String ("%-32.32s%13.2lf") % label % (sum_bin [i] [CONG_VMT] * factor));
			if (compare_flag) {
				base = sum_bin [i] [CONG_VMT+PREV] * factor;
				diff = sum_bin [i] [CONG_VMT] * factor - base;

				Print (0, String (" %13.2lf %13.2lf  (%.2lf%%)") % base % diff % ((base > 0.0) ? (100.0 * diff / base) : 0.0) % FINISH);
			}

			value = sum_bin [i] [VMT];
			if (value == 0.0) value = 1.0;
			percent = 100.0 * sum_bin [i] [CONG_VMT] / value;

			Print (1, String ("Percent %s Congested           %13.2lf") % vmt % percent);
			if (compare_flag) {
				value = sum_bin [i] [VMT+PREV];
				if (value == 0.0) value = 1.0;
				base = 100.0 * sum_bin [i] [CONG_VMT+PREV] / value;
				diff = percent - base;

				Print (0, String (" %13.2lf %13.2lf  (%.2lf%%)") % base % diff % ((base > 0.0) ? (100.0 * diff / base) : 0.0) % FINISH);
			}


			label = "Congested " + type + " Hours";
			Print (1, String ("%-32.32s%13.2lf") % label % (sum_bin [i] [CONG_VHT] / tod));
			if (compare_flag) {
				base = sum_bin [i] [CONG_VHT+PREV] / tod;
				diff = sum_bin [i] [CONG_VHT] / tod - base;

				Print (0, String (" %13.2lf %13.2lf  (%.2lf%%)") % base % diff % ((base > 0.0) ? (100.0 * diff / base) : 0.0) % FINISH);
			}

			value = sum_bin [i] [VHT];
			if (value == 0.0) value = 1.0;
			percent = 100.0 * sum_bin [i] [CONG_VHT] / value;

			Print (1, String ("Percent %sHT Congested           %13.2lf") % ((person_flag) ? "P" : "V") % percent);
			if (compare_flag) {
				value = sum_bin [i] [VHT+PREV];
				if (value == 0.0) value = 1.0;
				base = 100.0 * sum_bin [i] [CONG_VHT+PREV] / value;
				diff = percent - base;

				Print (0, String (" %13.2lf %13.2lf  (%.2lf%%)") % base % diff % ((base > 0.0) ? (100.0 * diff / base) : 0.0) % FINISH);
			}

			value = factor * hours / inc_per_hour;

			label = "Congested Duration (hrs*ln-" + lane_mi;
			Print (1, String ("%-32.32s%13.2lf") % label % (sum_bin [i] [CONG_TIME] * value));

			if (compare_flag) {
				base = sum_bin [i] [CONG_TIME+PREV] * value;
				diff = sum_bin [i] [CONG_TIME] * value - base;

				Print (0, String (" %13.2lf %13.2lf  (%.2lf%%)") % base % diff % ((base > 0.0) ? (100.0 * diff / base) : 0.0) % FINISH);
			}
			value = sum_bin [i] [COUNT];
			if (value == 0.0) value = 1.0;

			percent = 100.0 * sum_bin [i] [CONG_TIME] / value;

			Print (1, String ("Percent Time Congested          %13.2lf") % percent);
			if (compare_flag) {
				value = sum_bin [i] [COUNT+PREV];
				if (value == 0.0) value = 1.0;
				base = 100.0 * sum_bin [i] [CONG_TIME+PREV] / value;
				diff = percent - base;

				Print (0, String (" %13.2lf %13.2lf  (%.2lf%%)") % base % diff % ((base > 0.0) ? (100.0 * diff / base) : 0.0) % FINISH);
			}
		}
	}
	Header_Number (0);
}

//---------------------------------------------------------
//	Perf_Sum_Header
//---------------------------------------------------------

void LinkSum::Perf_Sum_Header (void)
{
	Print (1, "Network Performance Details");
	Print (2, String ("%36cCurrent") % BLANK);
	if (compare_flag) {
		Print (0, "      Previous      Difference  Percent");
	}
	Print (1);
}

/*********************************************|***********************************************

	Network Performance Details
	
	                                    Current      Previous      Difference  Percent

	Time Period                      xx:xx..xx:xx
	Number of Links                  fffffffff.ff
	Number of Roadway Miles          fffffffff.ff
	Number of Lane Miles             fffffffff.ff
	Vehicle Miles of Travel          fffffffff.ff  fffffffff.ff  fffffffff.ff  (f.ff%)
	Vehicle Hours of Travel          fffffffff.ff  fffffffff.ff  fffffffff.ff  (f.ff%)
	Vehicle Hours of Delay           fffffffff.ff  fffffffff.ff  fffffffff.ff  (f.ff%)
	Average Queued Vehicles          fffffffff.ff  fffffffff.ff  fffffffff.ff  (f.ff%)
	Maximum Queued Vehicles          fffffffff.ff  fffffffff.ff  fffffffff.ff  (f.ff%)
	Number of Cycle Failures         fffffffff.ff  fffffffff.ff  fffffffff.ff  (f.ff%)
	Number of Turning Movements      fffffffff.ff  fffffffff.ff  fffffffff.ff  (f.ff%)
	Average Link Time Ratio          fffffffff.ff  fffffffff.ff  fffffffff.ff  (f.ff%)
	Average Link Density             fffffffff.ff  fffffffff.ff  fffffffff.ff  (f.ff%)
	Average Link Max Density         fffffffff.ff  fffffffff.ff  fffffffff.ff  (f.ff%)
	Average Miles Per Hour           fffffffff.ff  fffffffff.ff  fffffffff.ff  (f.ff%)
	Congested Vehicle Miles          fffffffff.ff  fffffffff.ff  fffffffff.ff  (f.ff%)
	Percent of VMT Congested         fffffffff.ff  fffffffff.ff  fffffffff.ff  (f.ff%)
	Congested Vehicle Hours          fffffffff.ff  fffffffff.ff  fffffffff.ff  (f.ff%)
	Percent of VHT Congested         fffffffff.ff  fffffffff.ff  fffffffff.ff  (f.ff%)
	Congestion Duration (Hours)      fffffffff.ff  fffffffff.ff  fffffffff.ff  (f.ff%)
	Percent of Time Congested        fffffffff.ff  fffffffff.ff  fffffffff.ff  (f.ff%)

**********************************************|***********************************************/ 
