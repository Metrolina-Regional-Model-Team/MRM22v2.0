//*********************************************************
//	Node_Fields.cpp - process node related fields
//*********************************************************

#include "VissimNet.hpp"

#include <math.h>

//---------------------------------------------------------
//	Node_Fields
//---------------------------------------------------------

bool VissimNet::Node_Fields (void)
{
	int i, link, index, index2, index3, index4, in_count, out_count;
	bool a_flag, b_flag;
	String data;

	Int_Map_Itr map_itr;
	Link_Data *link_ptr, *link2_ptr;
	Dir_Data *dir_ptr, *dir2_ptr;
	Connect_Data *connect_ptr, *connect2_ptr, *connect3_ptr, *connect4_ptr;
	Int_Key_Map link_count;
	Int_Key_Map_Stat count_stat;
	Int_Key_Map_Itr key_itr;
	Int_Set_Itr set_itr;
	Int_Itr int_itr;

	a_flag = b_flag = false;

	if (pair_itr->first.Equals ("<node")) {
		if (node_flag) Warning ("Node Block was Not Terminated");
		node_flag = !pair_itr->second.Equals ("/>");
		node_data.Clear ();
		node = (int) node_array.size ();

		connect_list.clear ();
		link_flags.clear ();

		for (++pair_itr; pair_itr != string_pairs.end (); pair_itr++) {
			if (pair_itr->first.Equals ("anmConnNodeNo")) {
				data = pair_itr->second;
				if (data.length () > 10) {
					data = data.substr (data.length () - 10);
				}
				if (data.length () == 10 && data [0] > '1') data [0] = '1';
				node_data.Node (data.Integer ());
			} else if (pair_itr->first.Equals ("no")) {
				data = pair_itr->second;
				if (data.length () > 10) {
					data = data.substr (data.length () - 10);
				}
				if (data.length () == 10 && data [0] > '1') data [0] = '1';
				node_data.Node (data.Integer ());
			}
		}
		if (!node_flag) {
			if (node_map.insert (Int_Map_Data (node_data.Node (), node)).second) {
				node_array.push_back (node_data);
				if ((int) node_array.size () != node + 1) {
					Warning ("Node Numbering Problem, Node=") << node_data.Node ();
				}
			}
		}
		return (true);
	} else if (pair_itr->first.Equals ("</node")) {
		if (!node_flag) Warning ("Node Block was Not Initialized");
		node_flag = false;
		if (node_map.insert (Int_Map_Data (node_data.Node (), node)).second) {
			node_array.push_back (node_data);

			if ((int) node_array.size () != node + 1) {
				Warning ("Node Numbering Problem, Node=") << node_data.Node ();
			} else {
				goto save_node;
			}
		}
	}
	if (node_flag) {
		if (pair_itr->first.Equals ("<linkSegs")) {
			if (linksegs_flag) Warning ("LinkSeg Block was Not Terminated");
			linksegs_flag = true;
		} else if (pair_itr->first.Equals ("</linkSegs")) {
			if (!linksegs_flag) Warning ("LinkSeg Block was Not Initialized");
			linksegs_flag = false;
		}
		if (linksegs_flag) {
			if (pair_itr->first.Equals ("<linkSegment")) {
				if (linkseg_flag) Warning ("LinkSegment Block was Not Terminated");
				linkseg_flag = !pair_itr->second.Equals ("/>");

				for (++pair_itr; pair_itr != string_pairs.end (); pair_itr++) {
					if (pair_itr->first.Equals ("link")) {
						data = pair_itr->second;
						if (data.length () > 10) {
							data = data.substr (data.length () - 10);
						}
						if (data.length () == 10 && data [0] > '1') data [0] = '1';
						link = data.Integer ();
					} else if (pair_itr->first.Equals ("fromPos")) {
						a_flag = (pair_itr->second.Double () == 0.0);
					} else if (pair_itr->first.Equals ("internalToPos")) {
						b_flag = (pair_itr->second.Double () == -1.0);
					}
				}
				if (!linkseg_flag) {
					goto save_data;
				}
			} else if (pair_itr->first.Equals ("</linkSegment")) {
				if (!linkseg_flag) Warning ("LinkSegment Block was Not Initialized");
				linkseg_flag = false;
				goto save_data;
			}
		}
	}
	return (false);

save_data:
	key_itr = keep_list.find (link);

	if (key_itr != keep_list.end ()) {
		connect_list.insert (key_itr->second.first);
		connect_list.insert (key_itr->second.second);

	} else {
		map_itr = link_map.find (link);

		if (map_itr == link_map.end ()) {
			map_itr = connect_link.find (link);

			if (map_itr != connect_link.end ()) {
				connect_list.insert (map_itr->second);
			}
		} else {
			link = map_itr->second * 10 + ((a_flag) ? 1 : 0) + ((b_flag) ? 2 : 0);
			link_flags.push_back (link);
		}
	}
	return (true);

save_node:

	//---- external nodes ----

	if (connect_list.size () == 0) {
		a_flag = b_flag = false;

		for (int_itr = link_flags.begin (); int_itr != link_flags.end (); int_itr++) {
			link = *int_itr / 10;
			link_ptr = &link_array [link];
			link = *int_itr % 10;

			if (link == 1) {
				link_ptr->Anode (node);
				a_flag = true;
			} else if (link == 2) {
				link_ptr->Bnode (node);
				b_flag = true;
			}
		}
		if (link_flags.size () == 2 && (!a_flag || !b_flag)) {
			for (int_itr = link_flags.begin (); int_itr != link_flags.end (); int_itr++) {
				link = *int_itr % 10;

				if (link == 0) {
					link = *int_itr / 10;
					link_ptr = &link_array [link];

					if (a_flag) {
						link_ptr->Bnode (node);
					} else {
						link_ptr->Anode (node);
					}
					break;
				}
			}
		} else if (link_flags.size () == 1 && !a_flag && !b_flag) {
			int_itr = link_flags.begin ();
			link = *int_itr / 10;

			link_ptr = &link_array [link];

			if (link_ptr->Bnode () == -1) {
				link_ptr->Bnode (node);
			} else if (link_ptr->Anode () == -1) {
				link_ptr->Anode (node);
			}
		}
		return (true);
	} else if (connect_list.size () == 1) {
		set_itr = connect_list.begin ();
		connect_ptr = &connect_array [*set_itr];

		dir_ptr = &dir_array [connect_ptr->Dir_Index ()];
		link_ptr = &link_array [dir_ptr->Link ()];
		link_ptr->Bnode (node);

		dir_ptr = &dir_array [connect_ptr->To_Index ()];
		link_ptr = &link_array [dir_ptr->Link ()];
		link_ptr->Anode (node);
		return (true);
	}

	//---- count the number of node connections for each link ----

	link_count.clear ();

	for (set_itr = connect_list.begin (); set_itr != connect_list.end (); set_itr++) {
		connect_ptr = &connect_array [*set_itr];

		count_stat = link_count.insert (Int_Key_Map_Data (connect_ptr->Dir_Index (), Int2_Key (1, 0)));

		if (!count_stat.second) {
			count_stat.first->second.first++;
		}
		count_stat = link_count.insert (Int_Key_Map_Data (connect_ptr->To_Index (), Int2_Key (0, 1)));

		if (!count_stat.second) {
			count_stat.first->second.second++;
		}
	}

	//---- initialize the link flags ----

	for (key_itr = link_count.begin (); key_itr != link_count.end (); key_itr++) {
		link = key_itr->first;
		dir_ptr = &dir_array [link];
		link_ptr = &link_array [dir_ptr->Link ()];

		if (link_ptr->Anode () == -1 && key_itr->second.second > 0) link_ptr->Anode (-2);
		if (link_ptr->Bnode () == -1 && key_itr->second.first > 0) link_ptr->Bnode (-2);
	}

	//---- search for the link with multiple connections ----

	for (i = 4; i >= 0; i--) {

		for (key_itr = link_count.begin (); key_itr != link_count.end (); key_itr++) {
			if (key_itr->second.first != i && key_itr->second.second != i) continue;
			if (i > 1) {
				if (key_itr->second.first > i || key_itr->second.second > i) continue;
			} else if (i == 1) {
				if (key_itr->second.first != 1 || key_itr->second.second != 1) continue;
			} else {
				if (key_itr->second.first > 0 && key_itr->second.second > 0) continue;
			}

			link = key_itr->first;
			out_count = key_itr->second.first;
			in_count = key_itr->second.second;

			//---- process the link ----

			a_flag = b_flag = false;
			dir_ptr = &dir_array [link];
			link_ptr = &link_array [dir_ptr->Link ()];

			//---- check the Bnode ----

			if ((out_count == i && i > 0) || (out_count == 1 && i == 0)) {

				if (link_ptr->Bnode () == node && link_ptr->Anode () != -3) {
					if (link_ptr->Anode () == -2) {
						a_flag = true;
					}
				} else if (link_ptr->Anode () == node || link_ptr->Anode () == -3 || link_ptr->Bnode () != -2) {
					b_flag = true;
				} else {

					//---- scan for conflicts ----

					for (index = dir_ptr->First_Connect_To (); index >= 0; index = connect_ptr->Next_To ()) {
						connect_ptr = &connect_array [index];

						dir2_ptr = &dir_array [connect_ptr->To_Index ()];
						link2_ptr = &link_array [dir2_ptr->Link ()];

						if (link2_ptr->Bnode () == node || link2_ptr->Bnode () == -3) {
							a_flag = b_flag = true;
							break;
						}

						for (index2 = dir2_ptr->First_Connect_From (); index2 >= 0; index2 = connect2_ptr->Next_From ()) {
							connect2_ptr = &connect_array [index2];

							if (index2 != index) {
								dir2_ptr = &dir_array [connect2_ptr->Dir_Index ()];
								link2_ptr = &link_array [dir2_ptr->Link ()];

								if (link2_ptr->Anode () == node || link2_ptr->Anode () == -3) {
									a_flag = b_flag = true;
									break;
								}
							}
						}
					}

					//---- set the node ----

					if (!b_flag) {
						link_ptr->Bnode (node);
						if (link_ptr->Anode () == -2) {
							a_flag = true;
						}
						for (index = dir_ptr->First_Connect_To (); index >= 0; index = connect_ptr->Next_To ()) {
							connect_ptr = &connect_array [index];
							connect_ptr->Node (node);

							dir2_ptr = &dir_array [connect_ptr->To_Index ()];
							link2_ptr = &link_array [dir2_ptr->Link ()];
							link2_ptr->Anode (node);
							if (link2_ptr->Bnode () == -2) link2_ptr->Bnode (-3);

							for (index2 = dir2_ptr->First_Connect_From (); index2 >= 0; index2 = connect2_ptr->Next_From ()) {
								connect2_ptr = &connect_array [index2];

								if (index2 != index) {
									connect2_ptr->Node (node);

									dir2_ptr = &dir_array [connect2_ptr->Dir_Index ()];
									link2_ptr = &link_array [dir2_ptr->Link ()];
									link2_ptr->Bnode (node);
									if (link2_ptr->Anode () == -2) link2_ptr->Anode (-3);

									for (index3 = dir2_ptr->First_Connect_To (); index3 >= 0; index3 = connect3_ptr->Next_To ()) {
										connect3_ptr = &connect_array [index3];

										if (index3 != index2 && index3 != index) {
											connect3_ptr->Node (node);

											dir2_ptr = &dir_array [connect3_ptr->To_Index ()];
											link2_ptr = &link_array [dir2_ptr->Link ()];
											link2_ptr->Anode (node);
											if (link2_ptr->Bnode () == -2) link2_ptr->Bnode (-3);

											for (index4 = dir2_ptr->First_Connect_From (); index4 >= 0; index4 = connect4_ptr->Next_From ()) {
												connect4_ptr = &connect_array [index4];

												if (index4 != index3 && index4 != index2 && index4 != index) {
													connect4_ptr->Node (node);

													dir2_ptr = &dir_array [connect4_ptr->Dir_Index ()];
													link2_ptr = &link_array [dir2_ptr->Link ()];
													link2_ptr->Bnode (node);
													if (link2_ptr->Anode () == -2) link2_ptr->Anode (-3);
												}
											}
										}
									}
								}
							}
						}
					}
				}
			}

			//---- check the A node ----

			if (!a_flag && ((in_count == i && i > 0) || (in_count == 1 && i == 0))) {

				if (link_ptr->Anode () == node && link_ptr->Bnode () != -3) {
					if (link_ptr->Bnode () == -2) {
						b_flag = true;
					}
				} else if (link_ptr->Bnode () == node || link_ptr->Bnode () == -3 || link_ptr->Anode () != -2) {
					a_flag = true;
				} else {

					//---- scan for conflicts ----

					for (index = dir_ptr->First_Connect_From (); index >= 0; index = connect_ptr->Next_From ()) {
						connect_ptr = &connect_array [index];

						dir2_ptr = &dir_array [connect_ptr->Dir_Index ()];
						link2_ptr = &link_array [dir2_ptr->Link ()];
						if (link2_ptr->Anode () == node || link2_ptr->Anode () == -3) {
							a_flag = b_flag = true;
							break;
						}

						for (index2 = dir2_ptr->First_Connect_To (); index2 >= 0; index2 = connect2_ptr->Next_To ()) {
							connect2_ptr = &connect_array [index2];

							if (index2 != index) {
								dir2_ptr = &dir_array [connect2_ptr->To_Index ()];
								link2_ptr = &link_array [dir2_ptr->Link ()];
								if (link2_ptr->Bnode () == node || link2_ptr->Bnode () == -3) {
									a_flag = b_flag = true;
									break;
								}
							}
						}
					}

					if (!a_flag) {

						//---- set the node ----

						link_ptr->Anode (node);
						if (link_ptr->Bnode () == -2) {
							b_flag = true;
						}

						for (index = dir_ptr->First_Connect_From (); index >= 0; index = connect_ptr->Next_From ()) {
							connect_ptr = &connect_array [index];
							connect_ptr->Node (node);

							dir2_ptr = &dir_array [connect_ptr->Dir_Index ()];
							link2_ptr = &link_array [dir2_ptr->Link ()];
							link2_ptr->Bnode (node);
							if (link2_ptr->Anode () == -2) link2_ptr->Anode (-3);

							for (index2 = dir2_ptr->First_Connect_To (); index2 >= 0; index2 = connect2_ptr->Next_To ()) {
								connect2_ptr = &connect_array [index2];

								if (index2 != index) {
									connect2_ptr->Node (node);

									dir2_ptr = &dir_array [connect2_ptr->To_Index ()];
									link2_ptr = &link_array [dir2_ptr->Link ()];
									link2_ptr->Anode (node);
									if (link2_ptr->Bnode () == -2) link2_ptr->Bnode (-3);

									for (index3 = dir2_ptr->First_Connect_From (); index3 >= 0; index3 = connect3_ptr->Next_From ()) {
										connect3_ptr = &connect_array [index3];

										if (index3 != index2 && index3 != index) {
											connect3_ptr->Node (node);

											dir2_ptr = &dir_array [connect3_ptr->Dir_Index ()];
											link2_ptr = &link_array [dir2_ptr->Link ()];
											link2_ptr->Bnode (node);
											if (link2_ptr->Anode () == -2) link2_ptr->Anode (-3);

											for (index4 = dir2_ptr->First_Connect_To (); index4 >= 0; index4 = connect4_ptr->Next_To ()) {
												connect4_ptr = &connect_array [index4];

												if (index4 != index3 && index4 != index2 && index4 != index) {
													connect4_ptr->Node (node);

													dir2_ptr = &dir_array [connect4_ptr->To_Index ()];
													link2_ptr = &link_array [dir2_ptr->Link ()];
													link2_ptr->Anode (node);
													if (link2_ptr->Bnode () == -2) link2_ptr->Bnode (-3);
												}
											}
										}
									}
								}
							}
						}
					}
				}
			}

			//---- flag the attached links ----

			if (a_flag && link_ptr->Anode () == -2) {
				link_ptr->Anode (-3);

				for (index = dir_ptr->First_Connect_From (); index >= 0; index = connect_ptr->Next_From ()) {
					connect_ptr = &connect_array [index];

					dir2_ptr = &dir_array [connect_ptr->Dir_Index ()];
					link2_ptr = &link_array [dir2_ptr->Link ()];
					link2_ptr->Bnode (-3);

					for (index2 = dir2_ptr->First_Connect_To (); index2 >= 0; index2 = connect2_ptr->Next_To ()) {
						connect2_ptr = &connect_array [index2];

						if (index2 != index) {
							dir2_ptr = &dir_array [connect2_ptr->To_Index ()];
							link2_ptr = &link_array [dir2_ptr->Link ()];
							link2_ptr->Anode (-3);
						}
					}
				}
			}

			if (b_flag && link_ptr->Bnode () == -2) {
				link_ptr->Bnode (-3);

				for (index = dir_ptr->First_Connect_To (); index >= 0; index = connect_ptr->Next_To ()) {
					connect_ptr = &connect_array [index];

					dir2_ptr = &dir_array [connect_ptr->To_Index ()];
					link2_ptr = &link_array [dir2_ptr->Link ()];
					link2_ptr->Anode (-3);

					for (index2 = dir2_ptr->First_Connect_From (); index2 >= 0; index2 = connect2_ptr->Next_From ()) {
						connect2_ptr = &connect_array [index2];

						if (index2 != index) {
							dir2_ptr = &dir_array [connect2_ptr->Dir_Index ()];
							link2_ptr = &link_array [dir2_ptr->Link ()];
							link2_ptr->Bnode (-3);
						}
					}
				}
			}
		}
	}

	//---- reset the link flags ----

	for (key_itr = link_count.begin (); key_itr != link_count.end (); key_itr++) {
		link = key_itr->first;
		dir_ptr = &dir_array [link];
		link_ptr = &link_array [dir_ptr->Link ()];

		if (link_ptr->Anode () <= -2) link_ptr->Anode (-1);
		if (link_ptr->Bnode () <= -2) link_ptr->Bnode (-1);
	}
	return (true);
} 
