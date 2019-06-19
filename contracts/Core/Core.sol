pragma solidity ^0.5.2;
pragma experimental ABIEncoderV2;

import "./Definitions.sol";
import "./Utils.sol";
import "./Schedule.sol";

import "./Conventions/BusinessDayConvention.sol";
import "./Conventions/ContractDefaultConvention.sol";
import "./Conventions/ContractRoleConvention.sol";
import "./Conventions/DayCountConvention.sol";
import "./Conventions/EndOfMonthConvention.sol";


contract Core is
	Definitions,
	Utils,
	BusinessDayConvention,
	ContractDefaultConvention,
	ContractRoleConvention,
	DayCountConvention,
	EndOfMonthConvention,
	Schedule
{

	function signum(int value) internal pure returns (int256) {
		if (value > 0) {
			return 1;
		} else if (value < 0) {
			return -1;
		} else {
			return INT256_MIN;
		}
	}

	function getEpochOffset(EventType eventType)
		internal
		pure
		returns (uint256)
	{
		if (eventType == EventType.IED) return 20;
		if (eventType == EventType.IP) return 30;
		if (eventType == EventType.IPCI) return 40;
		if (eventType == EventType.FP) return 50;
		if (eventType == EventType.DV) return 60;
		if (eventType == EventType.PR) return 70;
		if (eventType == EventType.MR) return 80;
		if (eventType == EventType.RRY) return 90;
		if (eventType == EventType.RR) return 100;
		if (eventType == EventType.SC) return 110;
		if (eventType == EventType.IPCB) return 120;
		if (eventType == EventType.PRD) return 130;
		if (eventType == EventType.TD) return 140;
		if (eventType == EventType.STD) return 150;
		if (eventType == EventType.MD) return 160;
		if (eventType == EventType.SD) return 900;
		if (eventType == EventType.AD) return 950;
		if (eventType == EventType.Child) return 10;
		return 0;
	}
}
