/*
 *  This file is part of Trans AI
 *
 *  Copyright 2009-2018 fanio zilla <fanio.zilla@gmail.com>
 *
 *  @see license.txt
 */

/**
 * XStation class
 * an AIStation eXtension
 */
class XStation
{
	Managers = {};
	/**
	 * Get the Manager for a station. If there is no manager yet, create one.
	 * @param station_id The StationID to get the Station Manager for.
	 * @return The Station Manager for the station.
	 */
	function GetManager(station_id, s_type) {
		assert(AIStation.IsValidStation(station_id));
		foreach(st, cls in XStation.Managers) {
			if (cls.GetID() == station_id && cls.GetSType() == s_type) {
				cls.Refresh();
				return cls;
			}
		}
		local cls = StationManager(station_id, s_type);
		cls.Refresh();
		XStation.Managers[cls.GetLocation()] <- cls;
		return cls;
	}

	function GetVehicleListType(st_id, s_type) {
		local clist = CLList(AIVehicleList_Station(st_id));
		clist.Valuate(AIVehicle.GetVehicleType);
		switch (s_type) {
			case AIStation.STATION_BUS_STOP:
			case AIStation.STATION_TRUCK_STOP:
				clist.KeepValue(AIVehicle.VT_ROAD);
				break;
			case AIStation.STATION_TRAIN:
				clist.KeepValue(AIVehicle.VT_RAIL);
				break;
			case AIStation.STATION_DOCK:
				clist.KeepValue(AIVehicle.VT_WATER);
				break;
			case AIStation.STATION_AIRPORT:
				clist.KeepValue(AIVehicle.VT_AIR);
				break;
			default:
				break;
		}
		return clist;
	}

	/** @param range to ignore */
	function FindIDNear(tile, range) {
		if (range > 0 && Setting.Get(SetString.distant_join_stations)) {
			//local range = Setting.Get (SetString.station_spread) ^ 2;
			local l = CLList(AIStationList(AIStation.STATION_ANY));
			l.Valuate(AIStation.GetDistanceManhattanToTile, tile);
			l.RemoveAboveValue(range);
			l.SortValueAscending();
			foreach(id, dist in l) {
				Info("found ID:", id , "distance:" , dist , " name:" , AIStation.GetName(id));
				return id;
			}
		}
		return AIStation.STATION_JOIN_ADJACENT;
	}

	function IsInUse(id) {
		return !AIVehicleList_Station(id).IsEmpty();
	}

	function RemovePart(st_id, s_type) {
		if (XStation.GetVehicleListType(st_id, s_type).Count()) return;
		foreach(tile, v in AITileList_StationType(st_id, s_type)) {
			if (!AITile.IsStationTile(tile)) continue;
			switch (s_type) {
				case AIStation.STATION_BUS_STOP:
				case AIStation.STATION_TRUCK_STOP:
					AIRoad.RemoveRoadStation(tile);
					continue;
				case AIStation.STATION_TRAIN:
					AIRail.RemoveRailStationTileRectangle(tile, tile, false);
					continue;
				case AIStation.STATION_DOCK:
					AIMarine.RemoveDock(tile);
					continue;
				case AIStation.STATION_AIRPORT:
					AIAirport.RemoveAirport(tile);
					continue;
				default:
					AITile.DemolishTile(tile);
					break;
			}
		}
	}

	function GetTipe(vhctipe, cargo) {
		local ret = "ANY";
		switch (vhctipe) {
			case AIVehicle.VT_ROAD:
				ret = AICargo.HasCargoClass(cargo, AICargo.CC_PASSENGERS) ? "STATION_BUS_STOP" : "STATION_TRUCK_STOP";
				break;
			case AIVehicle.VT_RAIL:
				ret = "STATION_TRAIN";
				break;
			case AIVehicle.VT_AIR:
				ret = "STATION_AIRPORT"
					  break;
			case AIVehicle.VT_WATER:
				ret = "STATION_DOCK";
				break;
		}
		return AIStation[ret];
	}

	function IsAccepting(st_id, cargo) {
		local cargoList = AICargoList_StationAccepting(st_id);
		return cargoList.HasItem(cargo);
	}

	function GetFirstLocation(id, s_type) {
		if (!AIStation.HasStationType(id, s_type)) return -1;
		return AITileList_StationType(id, s_type).Begin();
	}

	function GetVTipe(s_type) {
		switch (s_type) {
			case AIStation.STATION_BUS_STOP:
			case AIStation.STATION_TRUCK_STOP:
				return AIVehicle.VT_ROAD;
			case AIStation.STATION_TRAIN:
				return AIVehicle.VT_RAIL;
			case AIStation.STATION_AIRPORT:
				return AIVehicle.VT_AIR;
			case AIStation.STATION_DOCK:
				return AIVehicle.VT_WATER;
		}
		return AIVehicle.VT_INVALID;
	}

	function GetDivisorNum(s_type) {
		switch (s_type) {
			case AIStation.STATION_BUS_STOP:
			case AIStation.STATION_TRUCK_STOP:
				return 1;
			case AIStation.STATION_DOCK:
				return 2;
			case AIStation.STATION_TRAIN:
				return 3;
		}
		throw "don't request here. Use XAirport instead"
	}
}
