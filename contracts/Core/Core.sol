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
	// function createProtoEvent(
	// 	EventType eventType,
	// 	uint256 scheduleTime,
	// 	LifecycleTerms memory terms
	// )
	// 	public
	// 	pure
	// 	returns (ProtoEvent memory)
	// {
	// 	uint256 eventTime = shiftEventTime(
	// 		scheduleTime,
	// 		terms.businessDayConvention,
	// 		terms.calendar
	// 	);

	// 	return ProtoEvent(
	// 		eventTime,
	// 		eventTime.add(getEpochOffset(eventType)),
	// 		scheduleTime,
	// 		eventType,
	// 		terms.currency
	// 	);
	// }

	function signum(int value) internal pure returns (int256) {
		if (value > 0) {
			return 1;
		} else if (value < 0) {
			return -1;
		} else {
			return INT256_MIN;
		}
	}
}
