pragma solidity ^0.5.2;
pragma experimental ABIEncoderV2;

import "truffle/Assert.sol";

import "../../contracts/Core/Core.sol";


contract TestCore is Core {

  function testPerformanceIndicator() public {
    Assert.equal(performanceIndicator(ContractStatus.PF), 1, "Performance should be 1");
    Assert.equal(performanceIndicator(ContractStatus.DL), 1, "Performance should be 1");
    Assert.equal(performanceIndicator(ContractStatus.DQ), 1, "Performance should be 1");
    Assert.equal(performanceIndicator(ContractStatus.DF), 0, "Performance should be 0");
  }

  function testRoleSign() public {
    Assert.equal(roleSign(ContractRole.RPA), 1, "Sign should be 1");
    Assert.equal(roleSign(ContractRole.RPL), -1, "Sign should be -1");
  }

  function testSignum() public {
    Assert.equal(signum(1), 1, "Sign should be 1");
    Assert.equal(signum(-2), -1, "Sign should be -1");
  }

  function testYearFraction() public {
    Assert.equal(yearFraction(1506816000, 1538352000, DayCountConvention.A_360), 1013888888888888888, "YearFraction should be 1.013888888888888888");
    Assert.equal(yearFraction(1506816000, 1538352000, DayCountConvention.A_365), 1000000000000000000, "YearFraction should be 1.0");
    Assert.equal(yearFraction(1506816000, 1538352000, DayCountConvention._30E_360), 1000000000000000000, "YearFraction should be 1.0");
  }

  function testSortProtoEventSchedule() public {
    ProtoEvent[MAX_EVENT_SCHEDULE_SIZE] memory protoEventSchedule;
    uint16 index = 0;

    protoEventSchedule[index] = ProtoEvent(
      uint256(4),
      uint256(4).add(getEpochOffset(EventType.TD)),
      uint256(4),
      EventType.TD,
      address(0),
      EventType.TD,
      EventType.TD
    );
    index++;

    protoEventSchedule[index] = ProtoEvent(
      uint256(4),
      uint256(4).add(getEpochOffset(EventType.MD)),
      uint256(4),
      EventType.MD,
      address(0),
      EventType.MD,
      EventType.MD
    );
    index++;

    protoEventSchedule[index] = ProtoEvent(
      uint256(1),
      uint256(1).add(getEpochOffset(EventType.IED)),
      uint256(1),
      EventType.IED,
      address(0),
      EventType.IED,
      EventType.IED
    );
    index++;

    sortProtoEventSchedule(protoEventSchedule, index);

    Assert.equal(uint256(protoEventSchedule[0].eventType), uint256(EventType.IED), "First ProtoEvent in schedule should be IED");
    Assert.equal(uint256(protoEventSchedule[1].eventType), uint256(EventType.TD), "Second ProtoEvent in schedule should be TD");
    Assert.equal(uint256(protoEventSchedule[2].eventType), uint256(EventType.MD), "Second ProtoEvent in schedule should be MD");
    Assert.equal(uint256(protoEventSchedule[3].eventTime), uint256(0), "Following ProtoEvents should be 0");
    Assert.equal(uint256(protoEventSchedule[4].eventTime), uint256(0), "Following ProtoEvents should be 0");
  }

  function testIsInPeriod() public {
    Assert.equal(isInPeriod(uint256(100), uint256(99), uint256(101)), true, "Timestamp should be contained in the period");
    Assert.equal(isInPeriod(uint256(100), uint256(99), uint256(100)), true, "Timestamp should be contained in the period");
    Assert.equal(isInPeriod(uint256(100), uint256(100), uint256(100)), false, "Timestamp should not be contained in the period");
    Assert.equal(isInPeriod(uint256(100), uint256(100), uint256(99)), false, "Timestamp should not be contained in the period");
  }

  function testGetTimestampPlusPeriod() public {
    Assert.equal(getTimestampPlusPeriod(IPS(1, P.D, S.LONG, true), 1514764800), 1514851200, "Timestamp + 1D+ should be 1514851200");
    Assert.equal(getTimestampPlusPeriod(IPS(5, P.D, S.LONG, true), 1514764800), 1515196800, "Timestamp + 5D+ should be 1515196800");
    Assert.equal(getTimestampPlusPeriod(IPS(1, P.W, S.LONG, true), 1514764800), 1515369600, "Timestamp + 1W+ should be 1515369600");
    Assert.equal(getTimestampPlusPeriod(IPS(5, P.W, S.LONG, true), 1514764800), 1517788800, "Timestamp + 5W+ should be 1517788800");
    Assert.equal(getTimestampPlusPeriod(IPS(1, P.Q, S.LONG, true), 1514764800), 1522540800, "Timestamp + 1Q+ should be 1522540800");
    Assert.equal(getTimestampPlusPeriod(IPS(3, P.Q, S.LONG, true), 1514764800), 1538352000, "Timestamp + 3Q+ should be 1538352000");
    Assert.equal(getTimestampPlusPeriod(IPS(1, P.H, S.LONG, true), 1514764800), 1530403200, "Timestamp + 1H+ should be 1530403200");
    Assert.equal(getTimestampPlusPeriod(IPS(5, P.H, S.LONG, true), 1514764800), 1593561600, "Timestamp + 5H+ should be 1593561600");
    Assert.equal(getTimestampPlusPeriod(IPS(1, P.Y, S.LONG, true), 1514764800), 1546300800, "Timestamp + 1Y+ should be 1546300800");
    Assert.equal(getTimestampPlusPeriod(IPS(5, P.Y, S.LONG, true), 1514764800), 1672531200, "Timestamp + 5Y+ should be 1672531200");
  }

  function testGetNextCycleDate() public {
    Assert.equal(getNextCycleDate(IPS(1, P.D, S.LONG, true), 1514764800, 0), 1514764800, "Timestamp + 1D+ with CycleIndex 0 should be 1514764800");
    Assert.equal(getNextCycleDate(IPS(1, P.W, S.LONG, true), 1514764800, 0), 1514764800, "Timestamp + 1W+ with CycleIndex 0 should be 1514764800");
    Assert.equal(getNextCycleDate(IPS(1, P.Q, S.LONG, true), 1514764800, 0), 1514764800, "Timestamp + 1Q+ with CycleIndex 0 should be 1514764800");
    Assert.equal(getNextCycleDate(IPS(1, P.H, S.LONG, true), 1514764800, 0), 1514764800, "Timestamp + 1H+ with CycleIndex 0 should be 1514764800");
    Assert.equal(getNextCycleDate(IPS(1, P.Y, S.LONG, true), 1514764800, 0), 1514764800, "Timestamp + 1Y+ with CycleIndex 0 should be 1514764800");

    Assert.equal(getNextCycleDate(IPS(1, P.D, S.LONG, true), 1514764800, 1), 1514851200, "Timestamp + 1D+ with CycleIndex 1 should be 1514851200");
    Assert.equal(getNextCycleDate(IPS(5, P.D, S.LONG, true), 1514764800, 1), 1515196800, "Timestamp + 5D+ with CycleIndex 1 should be 1515196800");
    Assert.equal(getNextCycleDate(IPS(1, P.W, S.LONG, true), 1514764800, 1), 1515369600, "Timestamp + 1W+ with CycleIndex 1 should be 1515369600");
    Assert.equal(getNextCycleDate(IPS(5, P.W, S.LONG, true), 1514764800, 1), 1517788800, "Timestamp + 5W+ with CycleIndex 1 should be 1517788800");
    Assert.equal(getNextCycleDate(IPS(1, P.Q, S.LONG, true), 1514764800, 1), 1522540800, "Timestamp + 1Q+ with CycleIndex 1 should be 1522540800");
    Assert.equal(getNextCycleDate(IPS(3, P.Q, S.LONG, true), 1514764800, 1), 1538352000, "Timestamp + 3Q+ with CycleIndex 1 should be 1538352000");
    Assert.equal(getNextCycleDate(IPS(1, P.H, S.LONG, true), 1514764800, 1), 1530403200, "Timestamp + 1H+ with CycleIndex 1 should be 1530403200");
    Assert.equal(getNextCycleDate(IPS(5, P.H, S.LONG, true), 1514764800, 1), 1593561600, "Timestamp + 5H+ with CycleIndex 1 should be 1593561600");
    Assert.equal(getNextCycleDate(IPS(1, P.Y, S.LONG, true), 1514764800, 1), 1546300800, "Timestamp + 1Y+ with CycleIndex 1 should be 1546300800");
    Assert.equal(getNextCycleDate(IPS(5, P.Y, S.LONG, true), 1514764800, 1), 1672531200, "Timestamp + 5Y+ with CycleIndex 1 should be 1672531200");

    Assert.equal(getNextCycleDate(IPS(1, P.D, S.LONG, true), 1514764800, 3), 1515024000, "Timestamp + 1D+ with CycleIndex 3 should be 1515024000");
    Assert.equal(getNextCycleDate(IPS(5, P.D, S.LONG, true), 1514764800, 3), 1516060800, "Timestamp + 5D+ with CycleIndex 3 should be 1516060800");
    Assert.equal(getNextCycleDate(IPS(1, P.W, S.LONG, true), 1514764800, 3), 1516579200, "Timestamp + 1W+ with CycleIndex 3 should be 1516579200");
    Assert.equal(getNextCycleDate(IPS(5, P.W, S.LONG, true), 1514764800, 3), 1523836800, "Timestamp + 5W+ with CycleIndex 3 should be 1523836800");
    Assert.equal(getNextCycleDate(IPS(1, P.Q, S.LONG, true), 1514764800, 3), 1538352000, "Timestamp + 1Q+ with CycleIndex 3 should be 1538352000");
    Assert.equal(getNextCycleDate(IPS(3, P.Q, S.LONG, true), 1514764800, 3), 1585699200, "Timestamp + 3Q+ with CycleIndex 3 should be 1585699200");
    Assert.equal(getNextCycleDate(IPS(1, P.H, S.LONG, true), 1514764800, 3), 1561939200, "Timestamp + 1H+ with CycleIndex 3 should be 1561939200");
    Assert.equal(getNextCycleDate(IPS(5, P.H, S.LONG, true), 1514764800, 3), 1751328000, "Timestamp + 5H+ with CycleIndex 3 should be 1751328000");
    Assert.equal(getNextCycleDate(IPS(1, P.Y, S.LONG, true), 1514764800, 3), 1609459200, "Timestamp + 1Y+ with CycleIndex 3 should be 1609459200");
    Assert.equal(getNextCycleDate(IPS(5, P.Y, S.LONG, true), 1514764800, 3), 1988150400, "Timestamp + 5Y+ with CycleIndex 3 should be 1988150400");
  }

  // function computeDatesFromCycleSegment() public {

  // }
}
