//*********************************************************
//	Read_Trip_Table.cpp - read trip table data
//*********************************************************

#include "ConvertTrips.hpp"

//---------------------------------------------------------
//	Read_Trip_Table
//---------------------------------------------------------

void ConvertTrips::Read_Trip_Table (ConvertTrip_Itr group)
{
	Dtime tod, low, high, start, end;
	int p, p1, p2, num_p, trp, period, current, first_p, last_p;
	int total, stat, errors, org_zone, des_zone, org, des, o, d, trips, num, num_shares, even_bucket, even;
	bool share_flag, factor_flag, time_fac_flag, scale_flag, return_flag, period_flag;
	double trip, factor, added, deleted, bucket;

	Db_Matrix *file;
	Factor_Period *period_fac;
	Dtime_Table_Itr skim_itr;
	Int_Map_Itr map_itr;
	Int_Map *org_map, *des_map;
	Int_Map_Itr org_itr, des_itr;

	static string error_msg = "%d Trip%sbetween Zones %d and %d could not be allocated";

	//---- read the trip table ----

	total = errors = 0;
	added = deleted = 0.0;
	file = group->Trip_File ();

	period_flag = (file->Num_Periods () > 1);

	return_flag = group->Return_Flag ();
	even_bucket = 1;
	bucket = 0.45;

	factor_flag = group->Factor_Flag ();
	time_fac_flag = group->Factor_Periods_Flag ();

	scale_flag = (group->Scaling_Factor () != 1.0);

	num_shares = group->Num_Shares ();
	share_flag = (num_shares > 0);

	first_p = p1 = 0;
	last_p = p2 = num_p = group->Diurnal_Periods () - 1;
	period = -1;

	Show_Message (1, String ("Reading %s -- Record") % file->File_Type ());
	Set_Progress ();

	org_map = file->Org_Map ();
	des_map = file->Des_Map ();

	//---- process each origin zone ----

	for (org_itr = org_map->begin (); org_itr != org_map->end (); org_itr++) {
		Show_Progress ();
		org_zone = org_itr->first;

		if (select_org_zones && !org_zone_range.In_Range (org_zone)) continue;

		//---- read trip matrix ----

		if (!file->Read_Record (org_zone)) continue;

		if (file->Row_Sum (group->Table ()) == 0.0) continue;

		map_itr = zone_map.find (org_zone);
		if (map_itr == zone_map.end ()) {
			Warning (String ("Origin Zone %d is Out of Range") % org_zone);
			continue;
		}
		org = map_itr->second;

		for (des_itr = des_map->begin (); des_itr != des_map->end (); des_itr++) {
			des_zone = des_itr->first;
		
			if (select_des_zones && !des_zone_range.In_Range (des_zone)) continue;

			file->Get_Cell_Index (des_itr->second, group->Table (), trip);

			if (trip == 0.0) continue;
			if (trip < 0) {
				if (trip > -32767) Warning (String ("Number of Trips is Out of Range (%lf < 0)") % trip);
				continue;
			}
			map_itr = zone_map.find (des_zone);
			if (map_itr == zone_map.end ()) {
				Warning (String ("Destination Zone %d is Out of Range") % des_zone);
				continue;
			}
			des = map_itr->second;

			if (period_flag) {
				period = file->Period ();
			}

			//---- check for a factor period ----

			if (time_fac_flag) {
				if (period >= 0) {
					first_p = last_p = -1;

					for (p = 0; p <= num_p; p++) {
						tod = group->Diurnal_Period_Time (p);

						if (group->Factor_Period_Num (tod) == period) {
							if (first_p < 0) first_p = p;
							last_p = p;
						}
					}
					if (last_p < 0) {
						first_p = 0;
						last_p = num_p;
						period = 0;
					}
					} else {
					first_p = 0;
					last_p = num_p;
					period = 0;
				}
			}

			//---- apply the scaling factor ----

			if (scale_flag) {
				trip *= group->Scaling_Factor ();
			}
			trip += bucket;
			trips = (int) trip;
			if (trips < 0) trips = 0;
			bucket = trip - trips;

			if (trips == 0) continue;
			total += trips;

			//---- apply the selection script ----

			if (share_flag) {
				file->Set_Fields (org_zone, des_zone);

				num = group->Execute_Diurnal ();

				if (num < 1 || num > num_shares) {
					Error (String ("Diurnal Selection Value %d is Out of Range (1..%d)") % num % num_shares);
				}
				num--;
				} else {
				num = 0;
			}

			//---- get the travel time ----

			if (skim_flag) {
				o = skim_file->Org_Index (org_zone);
				d = skim_file->Des_Index (des_zone);

				if (o >= 0 && d >= 0) {
					skim_ptr = skim_file->Time_Skim (o, d);
				} else {
					skim_ptr = 0;
				}
			}

			//---- apply adjustment factors ----

			if (factor_flag) {
				o = (equiv_flag) ? zone_equiv.Zone_Group (org_zone) : org_zone;
				d = (equiv_flag) ? zone_equiv.Zone_Group (des_zone) : des_zone;

				if (time_fac_flag) {
					period = -1;
					p1 = p2 = 0;
					trip = 0.0;

					for (p = first_p; p <= last_p; p++) {
						tod = group->Diurnal_Period_Time (p);

						current = group->Factor_Period_Num (tod);

						if (current != period) {
							if (period >= 0) {
								period_fac = group->Period_Factor (o, d, period);

								factor = trip * period_fac->Factor ();
								if (factor > trip) {
									added += factor - trip;
								} else {
									deleted += trip - factor;
								}
								trp = period_fac->Bucket_Factor (trip);

								if (trp > 0 && return_flag) {
									even = (((trp + even_bucket) / 2) * 2);
									even_bucket += trp - even;
									trp = even;
								}
								if (trp > 0) {
									stat = Set_Trips (group, org, des, trp, num, p1, p2, return_flag);

									if (stat > 0) {
										errors += stat;
										Print (1, String (error_msg) % stat % ((stat > 1) ? "s " : " ") % org_zone % des_zone);
									}
								}
							}
							period = current;
							p1 = p;
							trip = 0.0;
						}
						trip += trips * group->Share (p, num);
						p2 = p;
					}

				} else {
					p1 = first_p;
					p2 = last_p;
					trip = trips;
				}
				period_fac = group->Period_Factor (o, d, period);

				factor = trip * period_fac->Factor ();
				if (factor > trip) {
					added += factor - trip;
				} else {
					deleted += trip - factor;
				}
				trp = period_fac->Bucket_Factor (trip);
			} else if (period >= 0) {
				p1 = p2 = -1;
				file->Period_Range (period, start, end);

				for (p = first_p; p <= last_p; p++) {
					group->Diurnal_Time_Range (p, low, high);

					if (low <= start && start <= high) {
						p1 = p;
					}
					if (low <= end && end <= high) {
						p2 = p;
					}
					if (p1 >= 0 && p2 >= 0) break;
				}
				trp = trips;
			} else {
				p1 = first_p;
				p2 = last_p;
				trp = trips;
			}
			if (trp > 0 && return_flag) {
				even = (((trp + even_bucket) / 2) * 2);
				even_bucket += trp - even;
				trp = even;
			}

			//---- process the trips ----

			if (trp > 0) {
				stat = Set_Trips (group, org, des, trp, num, p1, p2, return_flag);

				if (stat > 0) {
					errors += stat;
					Print (1, String (error_msg) % stat % ((stat > 1) ? "s " : " ") % org_zone % des_zone);
				}
			}
		}
	}
	End_Progress ();

	file->Close ();

	Print (1, String ("%s has %d Records and %d Trips") % file->File_Type () % Progress_Count () % total);

	tot_trips += total;

	if (errors > 0) {
		Warning (String ("A Total of %d Trip%scould not be allocated") % errors % ((errors > 1) ? "s " : " "));

		tot_errors += errors;
	}
	if (factor_flag) {
		Print (1, String ("Trip Adjustments: %.0lf trips added, %.0lf trips deleted") % added % deleted);
		tot_add += added;
		tot_del += deleted;
	}
}
