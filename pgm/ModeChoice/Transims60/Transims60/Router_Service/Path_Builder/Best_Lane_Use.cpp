//*********************************************************
//	Best_Lane_Use.cpp - calculate lane use impedance
//*********************************************************

#include "Path_Builder.hpp"

//---------------------------------------------------------
//	Best_Lane_Use
//---------------------------------------------------------

bool Path_Builder::Best_Lane_Use (int index, Dtime time, double len_factor, Dtime &ttime, Dtime &delay, int &cost, int &group)
{
	int i, num, tt, cst, imp, lanes, type, grp, use_type [2], costs [2], best [2];
	Dtime ttimes [2], delays [2], min_time;
	double factor;

	Dir_Data *dir_ptr;
	Lane_Use_Data *use_ptr;
	Int_Map_Stat map_stat;
	Lane_Use_Period *period_ptr;
	Link_Dir_Data *use_index;

	dir_ptr = &exe->dir_array [index];

	if (path_param.delay_flag) {
		ttimes [0] = exe->perf_period_array.Travel_Time (index, time, len_factor, forward_flag);
		if (dir_ptr->Use_Index () >= 0) {
			ttimes [1] = exe->perf_period_array.Travel_Time (dir_ptr->Use_Index (), time, len_factor, forward_flag);
		}
	}
	if (ttimes [0] < 0 && ttimes [1] <= 0) return (false);

	min_time = dir_ptr->Time0 () * len_factor;

	if (ttimes [0] < min_time) ttimes [0] = min_time;
	if (ttimes [1] < min_time) ttimes [1] = min_time;

	ttime = ttimes [0];
	delay = 0;
	cost = group = 0;

	//---- find the time period ----

	index = dir_ptr->First_Lane_Use ();
	if (index < 0) return (true);

	for (period_ptr = &exe->use_period_array [index]; ; period_ptr = &exe->use_period_array [++index]) {
		if (period_ptr->Start () <= time && time < period_ptr->End ()) break;
		if (period_ptr->Periods () == 0) return (true);
	}

	//---- set the lane group data ----

	best [0] = best [1] = 0;
	delays [0] = delays [1] = 0;
	costs [0] = costs [1] = 0;

	use_type [0] = (period_ptr->Lanes (0) == 0) ? PROHIBIT : APPLY;
	use_type [1] = (period_ptr->Lanes (1) == 0) ? PROHIBIT : APPLY;

	type = path_param.traveler_type;

	num = period_ptr->Records ();
	index = period_ptr->Index ();

	for (i=0; i < num; i++, index++) {
		use_index = &exe->use_period_index [index];
		use_ptr = &exe->lane_use_array [use_index->Link ()];

		grp = use_index->Dir ();
		if (use_type [grp] == PROHIBIT) continue;

		lanes = use_ptr->High_Lane () - use_ptr->Low_Lane () + 1;

		if (lanes >= period_ptr->Lanes (grp)) {
			if (path_param.veh_type < 0 || use_ptr->Min_Veh_Type () < 0 || 
				(use_ptr->Min_Veh_Type () <= path_param.veh_type && path_param.veh_type <= use_ptr->Max_Veh_Type ())) {

				if (type == 0 || use_ptr->Min_Traveler () < 0 || 
					(use_ptr->Min_Traveler () <= type && type <= use_ptr->Max_Traveler ())) {

					if (Use_Permission (use_ptr->Use (), path_param.use)) {
						if (use_ptr->Type () == APPLY) {
							cst = use_ptr->Toll ();
							tt = use_ptr->Min_Delay ();
							if (use_ptr->Max_Delay () > use_ptr->Min_Delay ()) {
								map_stat = lane_use_delay.insert (Int_Map_Data (use_index->Link_Dir (), 0));
								if (map_stat.second) {
									map_stat.first->second = DTOI ((use_ptr->Max_Delay () - use_ptr->Min_Delay ()) * path_param.random.Probability ());
								}
								tt += map_stat.first->second;
							}
							imp = Resolve (tt * path_param.value_time + cst * path_param.value_cost / path_param.occupancy);
							if (imp < best [grp] || best [grp] == 0) {
								delays [grp] = tt;
								costs [grp] = cst;
								best [grp] = imp;
							}
							use_type [grp] = APPLY;
						} else if (use_ptr->Type () == PROHIBIT) {
							use_type [grp] = PROHIBIT;
						} else if (use_ptr->Type () == REQUIRE) {
							use_type [1-grp] = PROHIBIT;
						}
						continue;
					}
				}
			}
			if (use_ptr->Type () == LIMIT) {
				use_type [grp] = PROHIBIT;
			}
		}
	}

	//---- select the best lane group ----

	if (use_type [0] == PROHIBIT && use_type [1] == PROHIBIT) return (false);

	if (use_type [0] == APPLY && use_type [1] == APPLY) {
		best [0] += Resolve (ttimes [0] * path_param.value_time);
		best [1] += Resolve (ttimes [1] * path_param.value_time);

		if (random_flag) {
			factor = 1.0 + path_param.random_imped * (path_param.random.Probability () - 0.5) / 100.0;
			best [1] = DTOI (best [1] * factor);
		}
		if (best [1] > 0 && best [0] > 0) {
			group = (best [1] < best [0]) ? 1 : 0;
		} else {
			group = 0;
		}
	} else if (use_type [0] == APPLY) {
		group = 0;
	} else {
		group = 1;
	}
	delay = delays [group];
	cost = costs [group];
	ttime = ttimes [group];
	return ((ttime > 0));
}
