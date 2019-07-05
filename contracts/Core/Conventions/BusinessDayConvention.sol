pragma solidity ^0.5.2;

import "../../external/BokkyPooBah/BokkyPooBahsDateTimeLibrary.sol";

import "../Definitions.sol";


contract BusinessDayConvention is Definitions {

	// used in POFs and STFs for DCFs
	function shiftCalcTime(
		uint256 timestamp,
		BusinessDayConvention convention,
		Calendar calendar
	)
		internal
		pure
		returns (uint256)
	{
		if (
			convention == BusinessDayConvention.CSF ||
			convention == BusinessDayConvention.CSMF ||
			convention == BusinessDayConvention.CSP ||
			convention == BusinessDayConvention.CSMP
		) {
			return timestamp;
		}

		return shiftEventTime(timestamp, convention, calendar);
	}

	// used in ProtoEvent schedule generation (for single events and event cycles schedules)
	// before event offset is applied
	function shiftEventTime(
		uint256 timestamp,
		BusinessDayConvention convention,
		Calendar calendar
	)
		internal
		pure
		returns (uint256)
	{
		if (convention == BusinessDayConvention.SCF || convention == BusinessDayConvention.CSF) {
			return getClosestBusinessDaySameDayOrFollowing(timestamp, calendar);
		} else if (convention == BusinessDayConvention.SCMF || convention == BusinessDayConvention.CSMF) {
			uint256 followingOrSameBusinessDay = getClosestBusinessDaySameDayOrFollowing(timestamp, calendar);
			if (BokkyPooBahsDateTimeLibrary.getMonth(followingOrSameBusinessDay) == BokkyPooBahsDateTimeLibrary.getMonth(timestamp)) {
				return followingOrSameBusinessDay;
			}
			return getClosestBusinessDaySameDayOrPreceeding(timestamp, calendar);
		} else if (convention == BusinessDayConvention.SCP || convention == BusinessDayConvention.CSP) {
			return getClosestBusinessDaySameDayOrPreceeding(timestamp, calendar);
		} else if (convention == BusinessDayConvention.SCMP || convention == BusinessDayConvention.CSMP) {
			uint256 preceedingOrSameBusinessDay = getClosestBusinessDaySameDayOrPreceeding(timestamp, calendar);
			if (BokkyPooBahsDateTimeLibrary.getMonth(preceedingOrSameBusinessDay) == BokkyPooBahsDateTimeLibrary.getMonth(timestamp)) {
				return preceedingOrSameBusinessDay;
			}
			return getClosestBusinessDaySameDayOrFollowing(timestamp, calendar);
		}

		return timestamp;
	}

	function getClosestBusinessDaySameDayOrFollowing(uint256 timestamp, Calendar calendar)
		internal
		pure
		returns (uint256)
	{
		if (calendar == Calendar.MondayToFriday) {
			if (BokkyPooBahsDateTimeLibrary.getDayOfWeek(timestamp) == 6) {
				return BokkyPooBahsDateTimeLibrary.addDays(timestamp, 2);
			} else if (BokkyPooBahsDateTimeLibrary.getDayOfWeek(timestamp) == 7) {
				return BokkyPooBahsDateTimeLibrary.addDays(timestamp, 1);
			}
		}
		return timestamp;
	}

	function getClosestBusinessDaySameDayOrPreceeding(uint256 timestamp, Calendar calendar)
		internal
		pure
		returns (uint256)
	{
		if (calendar == Calendar.MondayToFriday) {
			if (BokkyPooBahsDateTimeLibrary.getDayOfWeek(timestamp) == 6) {
				return BokkyPooBahsDateTimeLibrary.subDays(timestamp, 1);
			} else if (BokkyPooBahsDateTimeLibrary.getDayOfWeek(timestamp) == 7) {
				return BokkyPooBahsDateTimeLibrary.subDays(timestamp, 2);
			}
		}
		return timestamp;
	}
}
