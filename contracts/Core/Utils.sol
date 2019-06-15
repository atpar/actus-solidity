pragma solidity ^0.5.2;

import "../external/BokkyPooBah/BokkyPooBahsDateTimeLibrary.sol";

import "./Definitions.sol";


contract Utils is Definitions {

  function getTimestampPlusPeriod(IPS memory cycle, uint256 timestamp)
		internal
		pure
		returns (uint256)
	{
		uint256 newTimestamp;

		if (cycle.p == P.D) {
			newTimestamp = BokkyPooBahsDateTimeLibrary.addDays(timestamp, cycle.i);
		} else if (cycle.p == P.W) {
			newTimestamp = BokkyPooBahsDateTimeLibrary.addDays(timestamp, cycle.i * 7);
		} else if (cycle.p == P.M) {
			newTimestamp = BokkyPooBahsDateTimeLibrary.addMonths(timestamp, cycle.i);
		} else if (cycle.p == P.Q) {
			newTimestamp = BokkyPooBahsDateTimeLibrary.addMonths(timestamp, cycle.i * 3);
		} else if (cycle.p == P.H) {
			newTimestamp = BokkyPooBahsDateTimeLibrary.addMonths(timestamp, cycle.i * 6);
		} else if (cycle.p == P.Y) {
			newTimestamp = BokkyPooBahsDateTimeLibrary.addYears(timestamp, cycle.i);
		} else {
			revert("Core.getTimestampPlusPeriod: ATTRIBUTE_NOT_FOUND");
		}

		return newTimestamp;
	}

  function sortProtoEventSchedule(
		ProtoEvent[MAX_EVENT_SCHEDULE_SIZE] memory protoEventSchedule,
		uint256 numberOfProtoEvents
	)
		internal
		pure
	{
		quickSortProtoEventSchedule(protoEventSchedule, uint(0), uint(protoEventSchedule.length - 1));

		for (uint256 i = 0; i < numberOfProtoEvents; i++) {
			protoEventSchedule[i] = protoEventSchedule[protoEventSchedule.length - numberOfProtoEvents + i];
			delete protoEventSchedule[protoEventSchedule.length - numberOfProtoEvents + i];
		}
	}

	function quickSortProtoEventSchedule(
		ProtoEvent[MAX_EVENT_SCHEDULE_SIZE] memory protoEventSchedule,
		uint left,
		uint right
	)
		internal
		pure
	{
		uint i = left;
		uint j = right;

		if (i == j) return;

		// pick event in the middle of the schedule
		uint pivot = protoEventSchedule[left + (right - left) / 2].eventTimeWithEpochOffset;

		// do until pivot event is reached
		while (i <= j) {
			// search for event that is scheduled later than the pivot event
			while (protoEventSchedule[i].eventTimeWithEpochOffset < pivot) i++;
			// search for event that is scheduled earlier than the pivot event
			while (pivot < protoEventSchedule[j].eventTimeWithEpochOffset) j--;
			// if the event that is scheduled later comes before the event that is scheduled earlier, swap events
			if (i <= j) {
				(
					protoEventSchedule[i], protoEventSchedule[j]
				) = (
					protoEventSchedule[j],
					protoEventSchedule[i]
				);
				i++;
				j--;
			}
		}

		if (left < j) quickSortProtoEventSchedule(protoEventSchedule, left, j);
		if (i < right) quickSortProtoEventSchedule(protoEventSchedule, i, right);
	}

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