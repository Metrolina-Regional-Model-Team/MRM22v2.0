//*********************************************************
//	VissimNet.cpp - VISSIM network conversion
//*********************************************************

#include "VissimNet.hpp"

//---------------------------------------------------------
//	VissimNet constructor
//---------------------------------------------------------

VissimNet::VissimNet (void) : Data_Service ()
{
	Program ("VissimNet");
	Version (7);
	Title ("VISSIM Network Conversion");
	
	System_File_Type optional_files [] = {
		NODE, LINK, SHAPE, POCKET, LANE_USE, CONNECTION, LOCATION, PARKING, ACCESS_LINK, TRANSIT_STOP, 
		SIGN, SIGNAL, TIMING_PLAN, PHASING_PLAN, DETECTOR, ZONE, 
		PERFORMANCE, TURN_DELAY, 
		NEW_NODE, NEW_LINK,NEW_SHAPE, NEW_POCKET, NEW_LANE_USE, NEW_CONNECTION, NEW_LOCATION, NEW_PARKING, 
		NEW_ACCESS_LINK, NEW_TRANSIT_STOP, 
		NEW_SIGN, NEW_SIGNAL, NEW_TIMING_PLAN, NEW_PHASING_PLAN, NEW_DETECTOR, NEW_ZONE,
		NEW_PERFORMANCE, NEW_TURN_DELAY, END_FILE
	};
	int file_service_keys [] = {
		NOTES_AND_NAME_FIELDS, 0
	};
	Control_Key keys [] = { //--- code, key, level, status, type, default, range, help ----
		{ VISSIM_XML_FILE, "VISSIM_XML_FILE", LEVEL0, OPT_KEY, IN_KEY, "", FILE_RANGE, NO_HELP },
		{ KEEP_CONNECTOR_LIST, "KEEP_CONNECTOR_LIST", LEVEL0, OPT_KEY, TEXT_KEY, "", "e.g., 100, 200, 300", NO_HELP },
		{ NEW_VISSIM_XML_FILE, "NEW_VISSIM_XML_FILE", LEVEL0, OPT_KEY, OUT_KEY, "", FILE_RANGE, NO_HELP },
		{ NEW_ARC_LINK_FILE, "NEW_ARC_LINK_FILE", LEVEL0, OPT_KEY, OUT_KEY, "", FILE_RANGE, NO_HELP },
		END_CONTROL
	};
	const char *reports [] = {
		""
	};
	Optional_System_Files (optional_files);
	File_Service_Keys (file_service_keys);

	Key_List (keys);
	Report_List (reports);

	input_flag = arc_link_flag = false;
	nodes_flag = node_flag = links_flag = link_flag = lanes_flag = lane_flag = speeds_flag = speed_flag = speed_pts_flag = speed_pt_flag = false;
	geo_flag = points_flag = point_flag = linkseg_flag = linksegs_flag = types_flag = type_flag = veh_types_flag = veh_type_flag = false;
	signs_flag = sign_flag = link_spds_flag = link_spd_flag = veh_spds_flag = veh_spd_flag = lots_flag = lot_flag = false;
	detectors_flag = detector_flag = veh_class_flag = false;

	org_field = des_field = -1;
	code = link = type= zone = node = parking = 0;
	fx = fy = value = 0.0;
}

//---------------------------------------------------------
//	NetMerge destructor
//---------------------------------------------------------

VissimNet::~VissimNet (void)
{
}
#ifdef _CONSOLE
//---------------------------------------------------------
//	main program
//---------------------------------------------------------

int main (int commands, char *control [])
{
	int stat = 0;
	VissimNet *program = 0;
	try {
		program = new VissimNet ();
		stat = program->Start_Execution (commands, control);
	}
	catch (exit_exception &e) {
		stat = e.Exit_Code ();
	}
	if (program != 0) delete program;
	return (stat);
}
#endif
