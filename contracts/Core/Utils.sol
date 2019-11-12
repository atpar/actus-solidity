pragma solidity ^0.5.2;

import "../external/BokkyPooBah/BokkyPooBahsDateTimeLibrary.sol";

import "./Definitions.sol";


contract Utils is Definitions {

	function encodeProtoEvent(EventType eventType, uint256 scheduleTime)
		public
		pure
		returns (bytes32)
	{
		return (
			bytes32(uint256(uint8(eventType))) << 248 |
			bytes32(scheduleTime)
		);
	}

	function decodeProtoEvent(bytes32 protoEvent)
		public
		pure
		returns (EventType, uint256)
	{
		EventType eventType = EventType(uint8(uint256(protoEvent >> 248)));
		uint256 scheduleTime = uint256(uint64(uint256(protoEvent)));

		return (eventType, scheduleTime);
	}

	function getTimestampPlusPeriod(IP memory period, uint256 timestamp)
		internal
		pure
		returns (uint256)
	{
		uint256 newTimestamp;

		if (period.p == P.D) {
			newTimestamp = BokkyPooBahsDateTimeLibrary.addDays(timestamp, period.i);
		} else if (period.p == P.W) {
			newTimestamp = BokkyPooBahsDateTimeLibrary.addDays(timestamp, period.i * 7);
		} else if (period.p == P.M) {
			newTimestamp = BokkyPooBahsDateTimeLibrary.addMonths(timestamp, period.i);
		} else if (period.p == P.Q) {
			newTimestamp = BokkyPooBahsDateTimeLibrary.addMonths(timestamp, period.i * 3);
		} else if (period.p == P.H) {
			newTimestamp = BokkyPooBahsDateTimeLibrary.addMonths(timestamp, period.i * 6);
		} else if (period.p == P.Y) {
			newTimestamp = BokkyPooBahsDateTimeLibrary.addYears(timestamp, period.i);
		} else {
			revert("Core.getTimestampPlusPeriod: ATTRIBUTE_NOT_FOUND");
		}

		return newTimestamp;
	}

  // function sortProtoEventSchedule(
	// 	ProtoEvent[MAX_EVENT_SCHEDULE_SIZE] memory protoEventSchedule,
	// 	uint256 numberOfProtoEvents
	// )
	// 	internal
	// 	pure
	// {
	// 	quickSortProtoEventSchedule(protoEventSchedule, uint(0), uint(protoEventSchedule.length - 1));

	// 	for (uint256 i = 0; i < numberOfProtoEvents; i++) {
	// 		protoEventSchedule[i] = protoEventSchedule[protoEventSchedule.length - numberOfProtoEvents + i];
	// 		delete protoEventSchedule[protoEventSchedule.length - numberOfProtoEvents + i];
	// 	}
	// }

	// function quickSortProtoEventSchedule(
	// 	ProtoEvent[MAX_EVENT_SCHEDULE_SIZE] memory protoEventSchedule,
	// 	uint left,
	// 	uint right
	// )
	// 	internal
	// 	pure
	// {
	// 	uint i = left;
	// 	uint j = right;

	// 	if (i == j) return;

	// 	// pick event in the middle of the schedule
	// 	uint pivot = protoEventSchedule[left + (right - left) / 2].eventTimeWithEpochOffset;

	// 	// do until pivot event is reached
	// 	while (i <= j) {
	// 		// search for event that is scheduled later than the pivot event
	// 		while (protoEventSchedule[i].eventTimeWithEpochOffset < pivot) i++;
	// 		// search for event that is scheduled earlier than the pivot event
	// 		while (pivot < protoEventSchedule[j].eventTimeWithEpochOffset) j--;
	// 		// if the event that is scheduled later comes before the event that is scheduled earlier, swap events
	// 		if (i <= j) {
	// 			(
	// 				protoEventSchedule[i], protoEventSchedule[j]
	// 			) = (
	// 				protoEventSchedule[j],
	// 				protoEventSchedule[i]
	// 			);
	// 			i++;
	// 			j--;
	// 		}
	// 	}

	// 	if (left < j) quickSortProtoEventSchedule(protoEventSchedule, left, j);
	// 	if (i < right) quickSortProtoEventSchedule(protoEventSchedule, i, right);
	// }

	/**
	 * checks if a timestamp is in a given period
	 * @dev returns true of timestamp is in period
	 * @param timestamp timestamp to check
	 * @param startTimestamp start timestamp of the period
	 * @param endTimestamp end timestamp of the period
	 * @return boolean
	 */
	function isInPeriod(
		uint256 timestamp,
		uint256 startTimestamp,
		uint256 endTimestamp
	)
		internal
		pure
		returns (bool)
	{
		if (startTimestamp < timestamp && endTimestamp >= timestamp) return true;
		return false;
	}
}