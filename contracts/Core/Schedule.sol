pragma solidity ^0.5.2;
pragma experimental ABIEncoderV2;

import "../external/BokkyPooBah/BokkyPooBahsDateTimeLibrary.sol";

import "./Definitions.sol";
import "./Utils.sol";

import "./Conventions/EndOfMonthConvention.sol";


contract Schedule is Definitions, Utils, EndOfMonthConvention {

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
			revert("Schedule.getNextCycleDate: ATTRIBUTE_NOT_FOUND");
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
				if (addEndTime == true) dates[index] = cycleEnd;
			}
			return dates;
		}

		// simplified

		EndOfMonthConvention actualEOMC = getEndOfMonthConvention(eomc, cycleStart, cycle);
		uint256 date = cycleStart;
		uint256 cycleIndex = 0;

		while (date < cycleEnd) {
			if (isInPeriod(date, segmentStart, segmentEnd)) {
				require(index < (MAX_CYCLE_SIZE - 2), "Schedule.computeDatesFromCycle: MAX_CYCLE_SIZE");
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
