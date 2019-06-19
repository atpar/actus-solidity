pragma solidity ^0.5.2;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/drafts/SignedSafeMath.sol";
import "../../external/BokkyPooBah/BokkyPooBahsDateTimeLibrary.sol";

import "../Definitions.sol";
import "../FloatMath.sol";


contract DayCountConvention is Definitions {

	using SafeMath for uint;
	using SignedSafeMath for int;
	using FloatMath for int;

	function yearFraction(uint256 startTimestamp, uint256 endTimestamp, DayCountConvention ipdc)
		internal
		pure
		returns (int256)
	{
		require(endTimestamp >= startTimestamp, "Core.yearFraction: UNMET_CONDITION");
		if (ipdc == DayCountConvention.A_AISDA) {
			return actualActualISDA(startTimestamp, endTimestamp);
		} else if (ipdc == DayCountConvention.A_360) {
			return actualThreeSixty(startTimestamp, endTimestamp);
		} else if (ipdc == DayCountConvention.A_365) {
			return actualThreeSixtyFive(startTimestamp, endTimestamp);
		} else if (ipdc == DayCountConvention._30E_360) {
			return thirtyEThreeSixty(startTimestamp, endTimestamp);
		} else {
			return 1000000000000000000;
		}
	}

	function actualActualISDA(uint256 startTime, uint256 endTime)
		internal
		pure
		returns (int256)
	{
		uint256 d1Year = BokkyPooBahsDateTimeLibrary.getYear(startTime);
		uint256 d2Year = BokkyPooBahsDateTimeLibrary.getYear(endTime);

		int256 firstBasis = (BokkyPooBahsDateTimeLibrary.isLeapYear(startTime)) ? 366 : 365;

		if (d1Year == d2Year) {
			return int256(BokkyPooBahsDateTimeLibrary.diffDays(startTime, endTime)).floatDiv(firstBasis);
		}

		int256 secondBasis = (BokkyPooBahsDateTimeLibrary.isLeapYear(endTime)) ? 366 : 365;

		int256 firstFraction = int256(BokkyPooBahsDateTimeLibrary.diffDays(
			startTime,
			BokkyPooBahsDateTimeLibrary.timestampFromDate(d1Year.add(1), 1, 1)
		)).floatDiv(firstBasis);
		int256 secondFraction = int256(BokkyPooBahsDateTimeLibrary.diffDays(
			BokkyPooBahsDateTimeLibrary.timestampFromDate(d2Year, 1, 1),
			endTime
		)).floatDiv(secondBasis);

		return firstFraction.add(secondFraction).add(int256(d2Year.sub(d1Year).sub(1)));
	}

	function actualThreeSixty(uint256 startTime, uint256 endTime)
		internal
		pure
		returns (int256)
	{
		return (int256((endTime.sub(startTime)).div(86400)).floatDiv(360));
	}

	function actualThreeSixtyFive(uint256 startTime, uint256 endTime)
		internal
		pure
		returns (int256)
	{
		return (int256((endTime.sub(startTime)).div(86400)).floatDiv(365));
	}

	function thirtyEThreeSixty(uint256 startTime, uint256 endTime)
		internal
		pure
		returns (int256)
	{
		uint256 d1Day;
		uint256 d1Month;
		uint256 d1Year;

		uint256 d2Day;
		uint256 d2Month;
		uint256 d2Year;

		(d1Year, d1Month, d1Day) = BokkyPooBahsDateTimeLibrary.timestampToDate(startTime);
		(d2Year, d2Month, d2Day) = BokkyPooBahsDateTimeLibrary.timestampToDate(endTime);

		if (d1Day == 31) {
			d1Day = 30;
		}

		if (d2Day == 31) {
			d2Day = 30;
		}

		int256 delD = int256(d2Day).sub(int256(d1Day));
		int256 delM = int256(d2Month).sub(int256(d1Month));
		int256 delY = int256(d2Year).sub(int256(d1Year));

		return ((delY.mul(360).add(delM.mul(30)).add(delD)).floatDiv(360));
	}
}