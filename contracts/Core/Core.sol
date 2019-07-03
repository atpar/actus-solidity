pragma solidity ^0.5.2;
pragma experimental ABIEncoderV2;

import "../external/BokkyPooBah/BokkyPooBahsDateTimeLibrary.sol";

import "./Definitions.sol";
import "./DayCountConventions.sol";
import "./EndOfMonthConventions.sol";


contract Core is Definitions, DayCountConventions, EndOfMonthConventions {

	function performanceIndicator(ContractStatus contractStatus)
		internal
		pure
		returns (int8)
	{
		if (contractStatus == ContractStatus.DF) { return 0; }
		return 1;
	}

	function roleSign(ContractRole contractRole)
		internal
		pure
		returns (int8)
	{
		if (contractRole == ContractRole.RPA) { return 1; }
		if (contractRole == ContractRole.RPL) { return -1; }
		revert("Core.roleSign: ATTRIBUTE_NOT_FOUND");
	}

	function signum(int value) internal pure returns (int256) {
		if (value > 0) {
			return 1;
		} else if (value < 0) {
			return -1;
		} else {
			return INT256_MIN;
		}
	}

	function yearFraction(uint256 startTimestamp, uint256 endTimestamp, DayCountConvention ipdc)
		internal
		pure
		returns (int256)
	{
		require(endTimestamp >= startTimestamp, "Core.yearFraction: UNMET_CONDITION");
		if (ipdc == DayCountConvention.A_360) {
			return int256(actualThreeSixty(startTimestamp, endTimestamp));
		} else if (ipdc == DayCountConvention.A_365) {
			return int256(actualThreeSixtyFive(startTimestamp, endTimestamp));
		} else if (ipdc == DayCountConvention._30E_360) {
			return int256(thirtyEThreeSixty(startTimestamp, endTimestamp));
		} else {
			return 1;
		}
	}

	function getEpochOffset(EventType eventType)
		internal
		pure
		returns (uint256)
	{
		if (eventType == EventType.IED) { return 20; }
		if (eventType == EventType.PR) { return 25; }
		if (eventType == EventType.IP) { return 30; }
		if (eventType == EventType.IPCI) { return 40; }
		if (eventType == EventType.FP) { return 50; }
		if (eventType == EventType.DV) { return 60; }
		//if (eventType == EventType.PR) { return 70; }
		if (eventType == EventType.MR) { return 80; }
		if (eventType == EventType.RRY) { return 90; }
		if (eventType == EventType.RR) { return 100; }
		if (eventType == EventType.SC) { return 110; }
		if (eventType == EventType.IPCB) { return 120; }
		if (eventType == EventType.PRD) { return 130; }
		if (eventType == EventType.TD) { return 140; }
		if (eventType == EventType.STD) { return 150; }
		if (eventType == EventType.MD) { return 160; }
		if (eventType == EventType.SD) { return 900; }
		if (eventType == EventType.AD) { return 950; }
		if (eventType == EventType.Child) { return 10; }
		return 0;
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
		uint pivot = protoEventSchedule[left + (right - left) / 2].scheduledTimeWithEpochOffset;

		// do until pivot event is reached
		while (i <= j) {
			// search for event that is scheduled later than the pivot event
			while (protoEventSchedule[i].scheduledTimeWithEpochOffset < pivot) i++;
			// search for event that is scheduled earlier than the pivot event
			while (pivot < protoEventSchedule[j].scheduledTimeWithEpochOffset) j--;
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

		if (left < j)
			quickSortProtoEventSchedule(protoEventSchedule, left, j);
		if (i < right)
			quickSortProtoEventSchedule(protoEventSchedule, i, right);
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
		if (startTimestamp < timestamp && endTimestamp >= timestamp) {
			return true;
		}
		return false;
	}

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

	function getNextCycleDate(IPS memory cycle, uint256 cycleStart, uint256 cycleIndex)
		internal
		pure
		returns (uint256)
	{
		uint256 newTimestamp;

		if (cycle.p == P.D) {
			newTimestamp = BokkyPooBahsDateTimeLibrary.addDays(cycleStart, cycle.i * cycleIndex);
		} else if (cycle.p == P.W) {
			newTimestamp = BokkyPooBahsDateTimeLibrary.addDays(cycleStart, cycle.i * 7 * cycleIndex);
		} else if (cycle.p == P.M) {
			newTimestamp = BokkyPooBahsDateTimeLibrary.addMonths(cycleStart, cycle.i * cycleIndex);
		} else if (cycle.p == P.Q) {
			newTimestamp = BokkyPooBahsDateTimeLibrary.addMonths(cycleStart, cycle.i * 3 * cycleIndex);
		} else if (cycle.p == P.H) {
			newTimestamp = BokkyPooBahsDateTimeLibrary.addMonths(cycleStart, cycle.i * 6 * cycleIndex);
		} else if (cycle.p == P.Y) {
			newTimestamp = BokkyPooBahsDateTimeLibrary.addYears(cycleStart, cycle.i * cycleIndex);
		} else {
			revert("Core.getNextCycleDate: ATTRIBUTE_NOT_FOUND");
		}

		return newTimestamp;
	}

	function computeDatesFromCycleSegment(
		uint256 cycleStart,
		uint256 cycleEnd,
		IPS memory cycle,
		EndOfMonthConvention eomc,
		bool addEndTime,
		uint256 segmentStart,
		uint256 segmentEnd
	)
		internal
		pure
		returns (uint256[MAX_CYCLE_SIZE] memory)
	{
		uint256[MAX_CYCLE_SIZE] memory dates;
		uint256 index = 0;

		if (cycle.isSet == false) {
			if (isInPeriod(cycleStart, segmentStart, segmentEnd)) {
				dates[index] = cycleStart;
				index++;
			}
			if (isInPeriod(cycleEnd, segmentStart, segmentEnd)) {
				if (addEndTime == true) { dates[index] = cycleEnd; }
			}
			return dates;
		}

		// simplified

		EndOfMonthConvention actualEOMC = getEndOfMonthConvention(eomc, cycleStart, cycle);
		uint256 date = cycleStart;
		uint256 cycleIndex = 0;

		while (date < cycleEnd) {
			if (isInPeriod(date, segmentStart, segmentEnd)) {
				require(index < (MAX_CYCLE_SIZE - 2), "Core.computeDatesFromCycle: MAX_CYCLE_SIZE");
				dates[index] = date;
				index++;
			}

			cycleIndex++;

			if (actualEOMC == EndOfMonthConvention.EOM) {
				date = shiftEndOfMonth(getNextCycleDate(cycle, cycleStart, cycleIndex));
			} else {
				date = shiftSameDay(getNextCycleDate(cycle, cycleStart, cycleIndex));
			}
		}

		if (addEndTime == true) {
			if (isInPeriod(cycleEnd, segmentStart, segmentEnd)) {
				dates[index] = cycleEnd;
			}
		}

		if (index > 0 && isInPeriod(dates[index - 1], segmentStart, segmentEnd)) {
			if (cycle.s == S.LONG && index > 1 && cycleEnd != date) {
				dates[index - 1] = dates[index];
				delete dates[index];
			}
		}

		return dates;
	}
}
