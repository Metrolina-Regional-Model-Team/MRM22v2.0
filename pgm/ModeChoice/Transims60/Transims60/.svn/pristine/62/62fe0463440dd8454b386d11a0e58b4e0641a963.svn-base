//*********************************************************
//	Read_Vissim.cpp - input VISSIM data
//*********************************************************

#include "VissimNet.hpp"

//---------------------------------------------------------
//	Read_Vissim
//---------------------------------------------------------

void VissimNet::Read_Vissim (void)
{
	bool header, end_flag, network_flag;
	String line;

	Show_Message (1, String ("Reading %s -- Record") % input_file.File_Type ());
	Set_Progress ();

	network_flag = false;
	header = true;

	while (input_file.Read ()) {
		Show_Progress ();

		line = input_file.Record_String ();

		if (line.Parse_XML (string_pairs) == 0) continue;

		for (pair_itr = string_pairs.begin (); pair_itr != string_pairs.end (); pair_itr++) {
			if (header) {
				if (!pair_itr->first.Equals ("<?xml") || !pair_itr->second.Equals ("?>")) {
					Error ("Input File is Not in XML Format");
				}
				header = false;
				break;
			}
			end_flag = true;

			if (pair_itr->first.Equals ("<network")) {
				if (network_flag) Warning ("Network Block was Not Terminated");
				network_flag = true;
				end_flag = !pair_itr->second.Equals ("/>");
			} else if (pair_itr->first.Equals ("</network")) {
				if (!network_flag) Warning ("Network Block was Not Initialized");
				network_flag = false;
			}
			if (network_flag) {

				//---- set block flags ----

				if (pair_itr->first.Equals ("<links")) {
					if (links_flag) Warning ("Links Block was Not Terminated");
					links_flag = true;
				} else if (pair_itr->first.Equals ("</links")) {
					if (!links_flag) Warning ("Links Block was Not Initialized");
					links_flag = false;
				} else if (pair_itr->first.Equals ("<nodes")) {
					if (nodes_flag) Warning ("Nodes Block was Not Terminated");
					nodes_flag = true;
				} else if (pair_itr->first.Equals ("</nodes")) {
					if (!nodes_flag) Warning ("Nodes Block was Not Initialized");
					nodes_flag = false;
				} else if (pair_itr->first.Equals ("<desSpeedDistributions")) {
					if (speeds_flag) Warning ("Speed Distributions Block was Not Terminated");
					speeds_flag = true;
				} else if (pair_itr->first.Equals ("</desSpeedDistributions")) {
					if (!speeds_flag) Warning ("Speed Distributions Block was Not Initialized");
					speeds_flag = false;
				} else if (pair_itr->first.Equals ("<desSpeedDecisions")) {
					if (link_spds_flag) Warning ("Speed Decisions Block was Not Terminated");
					link_spds_flag = true;
				} else if (pair_itr->first.Equals ("</desSpeedDecisions")) {
					if (!link_spds_flag) Warning ("Speed Decisions Block was Not Initialized");
					link_spds_flag = false;
				} else if (pair_itr->first.Equals ("<linkBehaviorTypes")) {
					if (types_flag) Warning ("Link Behaviors Block was Not Terminated");
					types_flag = true;
				} else if (pair_itr->first.Equals ("</linkBehaviorTypes")) {
					if (!types_flag) Warning ("Link Behaviors Block was Not Initialized");
					types_flag = false;
				} else if (pair_itr->first.Equals ("<vehicleTypes")) {
					if (veh_types_flag) Warning ("Vehicle Types Block was Not Terminated");
					veh_types_flag = true;
				} else if (pair_itr->first.Equals ("</vehicleTypes")) {
					if (!veh_types_flag) Warning ("Vehicle Types Block was Not Initialized");
					veh_types_flag = false;
				} else if (pair_itr->first.Equals ("<stopSigns")) {
					if (signs_flag) Warning ("Stop Signs Block was Not Terminated");
					signs_flag = true;
				} else if (pair_itr->first.Equals ("</stopSigns")) {
					if (!signs_flag) Warning ("Stop Signs Block was Not Initialized");
					signs_flag = false;
				} else if (pair_itr->first.Equals ("<parkingLots")) {
					if (lots_flag) Warning ("Parking Lots Block was Not Terminated");
					lots_flag = true;
				} else if (pair_itr->first.Equals ("</parkingLots")) {
					if (!lots_flag) Warning ("Parking Lots Block was Not Initialized");
					lots_flag = false;
				} else if (pair_itr->first.Equals ("<detectors")) {
					if (detectors_flag) Warning ("Detectors Block was Not Terminated");
					detectors_flag = true;
				} else if (pair_itr->first.Equals ("</detectors")) {
					if (!detectors_flag) Warning ("Detectors Block was Not Initialized");
					detectors_flag = false;
				}

				//---- link processing ----

				if (links_flag) {
					if (Link_Fields ()) break;
				}

				//---- node processing ----

				if (nodes_flag) {
					if (Node_Fields ()) break;
				}

				//---- speed processing ----

				if (speeds_flag) {
					if (Speed_Fields ()) break;
				}

				//---- link speed processing ----

				if (link_spds_flag) {
					if (Link_Speed_Fields ()) break;
				}

				//---- link behavior type processing ----

				if (types_flag) {
					if (Link_Behavior ()) break;
				}

				//---- vehicle type processing ----

				if (veh_types_flag) {
					if (Veh_Type_Fields ()) break;
				}

				//---- stop sign processing ----

				if (signs_flag) {
					if (Sign_Fields ()) break;
				}

				//---- parking lot processing ----

				if (lots_flag) {
					if (Parking_Fields ()) break;
				}

				//---- detector processing ----

				if (detectors_flag) {
					if (Detector_Fields ()) break;
				}

				network_flag = end_flag;
			}
		}
	}
	End_Progress ();

	input_file.Close ();

	//---- process link connections ----

	Connections ();

	//---- process link data ----

	Process_Links ();

	//---- write files ----

	if (arc_link_flag) {
		arc_link_file.Close ();
	}
	Write_Nodes ();
	Write_Links ();
	if (System_File_Flag (NEW_SHAPE)) {
		Write_Shapes ();
	}
	if (System_File_Flag (NEW_ZONE)) {
		Write_Zones ();
	}
	if (System_File_Flag (NEW_CONNECTION)) {
		Write_Connections ();
	}
	if (System_File_Flag (NEW_PARKING)) {
		Write_Parking_Lots ();
	}
	if (System_File_Flag (NEW_LOCATION)) {
		Write_Locations ();
	}
	if (System_File_Flag (NEW_SIGN)) {
		Write_Signs ();
	}
	if (System_File_Flag (NEW_DETECTOR)) {
		Write_Detectors ();
	}
} 
