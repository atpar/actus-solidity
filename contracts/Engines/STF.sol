pragma solidity ^0.5.2;
pragma experimental ABIEncoderV2;

import "../Core/Core.sol";


contract STF is Core {

  function STF_PAM_AD (
    ProtoEvent memory protoEvent,
    ContractTerms memory contractTerms,
    ContractState memory contractState,
    uint256 currentTimestamp
  )
    internal
    pure
    returns (ContractState memory)
  {
    int256 timeFromLastEvent = yearFraction(
      shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
      shiftCalcTime(protoEvent.scheduleTime, contractTerms.businessDayConvention, contractTerms.calendar),
      contractTerms.dayCountConvention,
      contractTerms.maturityDate
    );
    contractState.accruedInterest = contractState.accruedInterest
    .add(
      contractState.nominalInterestRate
      .floatMult(contractState.notionalPrincipal)
      .floatMult(timeFromLastEvent)
    );
    contractState.feeAccrued = contractState.feeAccrued
    .add(
      contractTerms.feeRate
      .floatMult(contractState.notionalPrincipal)
      .floatMult(timeFromLastEvent)
    );
    contractState.lastEventTime = protoEvent.scheduleTime;

    return contractState;
  }

  function STF_PAM_CD (
    ProtoEvent memory protoEvent,
    ContractTerms memory contractTerms,
    ContractState memory contractState,
    uint256 currentTimestamp
  )
    internal
    pure
    returns (ContractState memory)
  {
    int256 timeFromLastEvent = yearFraction(
      shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
      shiftCalcTime(protoEvent.scheduleTime, contractTerms.businessDayConvention, contractTerms.calendar),
      contractTerms.dayCountConvention,
      contractTerms.maturityDate
    );
    contractState.accruedInterest = contractState.accruedInterest
    .add(
      contractState.nominalInterestRate
      .floatMult(contractState.notionalPrincipal)
      .floatMult(timeFromLastEvent)
    );
    contractState.feeAccrued = contractState.feeAccrued
    .add(
      contractTerms.feeRate
      .floatMult(contractState.notionalPrincipal)
      .floatMult(timeFromLastEvent)
    );
    contractState.contractPerformance = ContractPerformance.DF;
    contractState.lastEventTime = protoEvent.scheduleTime;

    return contractState;
  }

  function STF_PAM_FP (
    ProtoEvent memory protoEvent,
    ContractTerms memory contractTerms,
    ContractState memory contractState,
    uint256 currentTimestamp
  )
    internal
    pure
    returns (ContractState memory)
  {
    int256 timeFromLastEvent = yearFraction(
      shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
      shiftCalcTime(protoEvent.scheduleTime, contractTerms.businessDayConvention, contractTerms.calendar),
      contractTerms.dayCountConvention,
      contractTerms.maturityDate
    );
    contractState.accruedInterest = contractState.accruedInterest
    .add(
      contractState.nominalInterestRate
      .floatMult(contractState.notionalPrincipal)
      .floatMult(timeFromLastEvent)
    );
    contractState.feeAccrued = 0;
    contractState.lastEventTime = protoEvent.scheduleTime;

    return contractState;
  }

  function STF_PAM_IED (
    ProtoEvent memory protoEvent,
    ContractTerms memory contractTerms,
    ContractState memory contractState,
    uint256 currentTimestamp
  )
    internal
    pure
    returns (ContractState memory)
  {
    int256 timeFromLastEvent = yearFraction(
      shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
      shiftCalcTime(protoEvent.scheduleTime, contractTerms.businessDayConvention, contractTerms.calendar),
      contractTerms.dayCountConvention,
      contractTerms.maturityDate
    );
    contractState.notionalPrincipal = roleSign(contractTerms.contractRole) * contractTerms.notionalPrincipal;
    contractState.nominalInterestRate = contractTerms.nominalInterestRate;
    contractState.lastEventTime = protoEvent.scheduleTime;

    if (contractTerms.cycleAnchorDateOfInterestPayment != 0 &&
      contractTerms.cycleAnchorDateOfInterestPayment < contractTerms.initialExchangeDate
    ) {
      contractState.accruedInterest = contractState.nominalInterestRate
      .floatMult(contractState.notionalPrincipal)
      .floatMult(
        yearFraction(
          contractTerms.cycleAnchorDateOfInterestPayment,
          protoEvent.scheduleTime,
          contractTerms.dayCountConvention,
          contractTerms.maturityDate
        )
      );
    }

    return contractState;
  }

  function STF_PAM_IPCI (
    ProtoEvent memory protoEvent,
    ContractTerms memory contractTerms,
    ContractState memory contractState,
    uint256 currentTimestamp
  )
    internal
    pure
    returns (ContractState memory)
  {
    int256 timeFromLastEvent = yearFraction(
      shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
      shiftCalcTime(protoEvent.scheduleTime, contractTerms.businessDayConvention, contractTerms.calendar),
      contractTerms.dayCountConvention,
      contractTerms.maturityDate
    );
    contractState.notionalPrincipal = contractState.notionalPrincipal
    .add(
      contractState.accruedInterest
      .add(
        contractState.nominalInterestRate
        .floatMult(contractState.notionalPrincipal)
        .floatMult(timeFromLastEvent)
      )
    );
    contractState.accruedInterest = 0;
    contractState.feeAccrued = contractState.feeAccrued
    .add(
      contractTerms.feeRate
      .floatMult(contractState.notionalPrincipal)
      .floatMult(timeFromLastEvent)
    );
    contractState.lastEventTime = protoEvent.scheduleTime;

    return contractState;
  }

  function STF_PAM_IP (
    ProtoEvent memory protoEvent,
    ContractTerms memory contractTerms,
    ContractState memory contractState,
    uint256 currentTimestamp
  )
    internal
    pure
    returns (ContractState memory)
  {
    int256 timeFromLastEvent = yearFraction(
      shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
      shiftCalcTime(protoEvent.scheduleTime, contractTerms.businessDayConvention, contractTerms.calendar),
      contractTerms.dayCountConvention,
      contractTerms.maturityDate
    );
    contractState.accruedInterest = 0;
    contractState.feeAccrued = contractState.feeAccrued
    .add(
      contractTerms.feeRate
      .floatMult(contractState.notionalPrincipal)
      .floatMult(timeFromLastEvent)
    );
    contractState.lastEventTime = protoEvent.scheduleTime;
    
    return contractState;
  }

  function STF_PAM_PP (
    ProtoEvent memory protoEvent,
    ContractTerms memory contractTerms,
    ContractState memory contractState,
    uint256 currentTimestamp
  )
    internal
    pure
    returns (ContractState memory)
  {
    int256 timeFromLastEvent = yearFraction(
      shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
      shiftCalcTime(protoEvent.scheduleTime, contractTerms.businessDayConvention, contractTerms.calendar),
      contractTerms.dayCountConvention,
      contractTerms.maturityDate
    );
    contractState.accruedInterest = contractState.accruedInterest
    .add(
      contractState.nominalInterestRate
      .floatMult(contractState.notionalPrincipal)
      .floatMult(timeFromLastEvent)
    );
    contractState.feeAccrued = contractState.feeAccrued
    .add(
      contractTerms.feeRate
      .floatMult(contractState.notionalPrincipal)
      .floatMult(timeFromLastEvent)
    );
    contractState.notionalPrincipal -= 0; // riskFactor(contractTerms.objectCodeOfPrepaymentModel, protoEvent.scheduleTime, contractState, contractTerms) * contractState.notionalPrincipal;
    contractState.lastEventTime = protoEvent.scheduleTime;

    return contractState;
  }

  function STF_PAM_PRD (
    ProtoEvent memory protoEvent,
    ContractTerms memory contractTerms,
    ContractState memory contractState,
    uint256 currentTimestamp
  )
    internal
    pure
    returns (ContractState memory)
  {
    int256 timeFromLastEvent = yearFraction(
      shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
      shiftCalcTime(protoEvent.scheduleTime, contractTerms.businessDayConvention, contractTerms.calendar),
      contractTerms.dayCountConvention,
      contractTerms.maturityDate
    );
    contractState.accruedInterest = contractState.accruedInterest
    .add(
      contractState.nominalInterestRate
      .floatMult(contractState.notionalPrincipal)
      .floatMult(timeFromLastEvent)
    );
    contractState.feeAccrued = contractState.feeAccrued
    .add(
      contractTerms.feeRate
      .floatMult(contractState.notionalPrincipal)
      .floatMult(timeFromLastEvent)
    );
    contractState.lastEventTime = protoEvent.scheduleTime;

    return contractState;
  }

  function STF_PAM_PR (
    ProtoEvent memory protoEvent,
    ContractTerms memory contractTerms,
    ContractState memory contractState,
    uint256 currentTimestamp
  )
    internal
    pure
    returns (ContractState memory)
  {
    int256 timeFromLastEvent = yearFraction(
      shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
      shiftCalcTime(protoEvent.scheduleTime, contractTerms.businessDayConvention, contractTerms.calendar),
      contractTerms.dayCountConvention,
      contractTerms.maturityDate
    );
    contractState.accruedInterest = contractState.accruedInterest
    .add(
      contractState.nominalInterestRate
      .floatMult(contractState.notionalPrincipal)
      .floatMult(timeFromLastEvent)
    );
    contractState.feeAccrued = contractState.feeAccrued
    .add(
      contractTerms.feeRate
      .floatMult(contractState.notionalPrincipal)
      .floatMult(timeFromLastEvent)
    );
    contractState.notionalPrincipal = 0;
    contractState.lastEventTime = protoEvent.scheduleTime;

    return contractState;
  }

  function STF_PAM_PY (
    ProtoEvent memory protoEvent,
    ContractTerms memory contractTerms,
    ContractState memory contractState,
    uint256 currentTimestamp
  )
    internal
    pure
    returns (ContractState memory)
  {
    int256 timeFromLastEvent = yearFraction(
      shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
      shiftCalcTime(protoEvent.scheduleTime, contractTerms.businessDayConvention, contractTerms.calendar),
      contractTerms.dayCountConvention,
      contractTerms.maturityDate
    );
    contractState.accruedInterest = contractState.accruedInterest
    .add(
      contractState.nominalInterestRate
      .floatMult(contractState.notionalPrincipal)
      .floatMult(timeFromLastEvent)
    );
    contractState.feeAccrued = contractState.feeAccrued
    .add(
      contractTerms.feeRate
      .floatMult(contractState.notionalPrincipal)
      .floatMult(timeFromLastEvent)
    );
    contractState.lastEventTime = protoEvent.scheduleTime;

    return contractState;
  }

  function STF_PAM_RRF (
    ProtoEvent memory protoEvent,
    ContractTerms memory contractTerms,
    ContractState memory contractState,
    uint256 currentTimestamp
  )
    internal
    pure
    returns (ContractState memory)
  {
    int256 timeFromLastEvent = yearFraction(
      shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
      shiftCalcTime(protoEvent.scheduleTime, contractTerms.businessDayConvention, contractTerms.calendar),
      contractTerms.dayCountConvention,
      contractTerms.maturityDate
    );
    contractState.accruedInterest = contractState.accruedInterest
    .add(
      contractState.nominalInterestRate
      .floatMult(contractState.notionalPrincipal)
      .floatMult(timeFromLastEvent)
    );
    contractState.feeAccrued = contractState.feeAccrued
    .add(
      contractTerms.feeRate
      .floatMult(contractState.notionalPrincipal)
      .floatMult(timeFromLastEvent)
    );
    contractState.nominalInterestRate = contractTerms.nextResetRate;
    contractState.lastEventTime = protoEvent.scheduleTime;

    return contractState;
  }

  function STF_PAM_RR (
    ProtoEvent memory protoEvent,
    ContractTerms memory contractTerms,
    ContractState memory contractState,
    uint256 currentTimestamp
  )
    internal
    pure
    returns (ContractState memory)
  {
    // int256 rate = //riskFactor(contractTerms.marketObjectCodeOfRateReset, protoEvent.scheduleTime, contractState, contractTerms)
    // 	* contractTerms.rateMultiplier + contractTerms.rateSpread;
    int256 rate = contractTerms.rateSpread;
    int256 deltaRate = rate.sub(contractState.nominalInterestRate);

      // apply period cap/floor
    if ((contractTerms.lifeCap < deltaRate) && (contractTerms.lifeCap < ((-1) * contractTerms.periodFloor))) {
      deltaRate = contractTerms.lifeCap;
    } else if (deltaRate < ((-1) * contractTerms.periodFloor)) {
      deltaRate = ((-1) * contractTerms.periodFloor);
    }
    rate = contractState.nominalInterestRate.add(deltaRate);

    // apply life cap/floor
    if (contractTerms.lifeCap < rate && contractTerms.lifeCap < contractTerms.lifeFloor) {
      rate = contractTerms.lifeCap;
    } else if (rate < contractTerms.lifeFloor) {
      rate = contractTerms.lifeFloor;
    }

    int256 timeFromLastEvent = yearFraction(
      shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
      shiftCalcTime(protoEvent.scheduleTime, contractTerms.businessDayConvention, contractTerms.calendar),
      contractTerms.dayCountConvention,
      contractTerms.maturityDate
    );
    contractState.accruedInterest = contractState.accruedInterest
    .add(
      contractState.nominalInterestRate
      .floatMult(contractState.notionalPrincipal)
      .floatMult(timeFromLastEvent)
    );
    contractState.nominalInterestRate = rate;
    contractState.lastEventTime = protoEvent.scheduleTime;

    return contractState;
  }

  function STF_PAM_SC (
    ProtoEvent memory protoEvent,
    ContractTerms memory contractTerms,
    ContractState memory contractState,
    uint256 currentTimestamp
  )
    internal
    pure
    returns (ContractState memory)
  {
    int256 timeFromLastEvent = yearFraction(
      shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
      shiftCalcTime(protoEvent.scheduleTime, contractTerms.businessDayConvention, contractTerms.calendar),
      contractTerms.dayCountConvention,
      contractTerms.maturityDate
    );
    contractState.accruedInterest = contractState.accruedInterest
    .add(
      contractState.nominalInterestRate
      .floatMult(contractState.notionalPrincipal)
      .floatMult(timeFromLastEvent)
    );
    contractState.feeAccrued = contractState.feeAccrued
    .add(
      contractTerms.feeRate
      .floatMult(contractState.notionalPrincipal)
      .floatMult(timeFromLastEvent)
    );

    if ((contractTerms.scalingEffect == ScalingEffect.I00)
      || (contractTerms.scalingEffect == ScalingEffect.IN0)
      || (contractTerms.scalingEffect == ScalingEffect.I0M)
      || (contractTerms.scalingEffect == ScalingEffect.INM)
    ) {
      contractState.interestScalingMultiplier = 0; // riskFactor(contractTerms.marketObjectCodeOfScalingIndex, protoEvent.scheduleTime, contractState, contractTerms)
    }
    if ((contractTerms.scalingEffect == ScalingEffect._0N0)
      || (contractTerms.scalingEffect == ScalingEffect._0NM)
      || (contractTerms.scalingEffect == ScalingEffect.IN0)
      || (contractTerms.scalingEffect == ScalingEffect.INM)
    ) {
      contractState.notionalScalingMultiplier = 0; // riskFactor(contractTerms.marketObjectCodeOfScalingIndex, protoEvent.scheduleTime, contractState, contractTerms)
    }

    contractState.lastEventTime = protoEvent.scheduleTime;

    return contractState;
  }

  function STF_PAM_TD (
    ProtoEvent memory protoEvent,
    ContractTerms memory contractTerms,
    ContractState memory contractState,
    uint256 currentTimestamp
  )
    internal
    pure
    returns (ContractState memory)
  {
    int256 timeFromLastEvent = yearFraction(
      shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
      shiftCalcTime(protoEvent.scheduleTime, contractTerms.businessDayConvention, contractTerms.calendar),
      contractTerms.dayCountConvention,
      contractTerms.maturityDate
    );
    contractState.notionalPrincipal = 0;
    contractState.accruedInterest = 0;
    contractState.feeAccrued = 0;
    contractState.lastEventTime = protoEvent.scheduleTime;

    return contractState;
  }

  function STF_PAM_DEL (
    ProtoEvent memory protoEvent,
    ContractTerms memory contractTerms,
    ContractState memory contractState,
    uint256 currentTimestamp
  )
    internal
    pure
    returns(ContractState memory)
  {
    uint256 nonPerformingDate = (contractState.nonPerformingDate == 0)
      ? protoEvent.eventTime
      : contractState.nonPerformingDate;

    uint256 graceDate = getTimestampPlusPeriod(contractTerms.gracePeriod, nonPerformingDate);
    uint256 delinquencyDate = getTimestampPlusPeriod(contractTerms.delinquencyPeriod, nonPerformingDate);

    if (protoEvent.scheduleTime <= graceDate) {
      contractState.contractPerformance = ContractPerformance.DL;
    } else if (protoEvent.scheduleTime <= delinquencyDate) {
      contractState.contractPerformance = ContractPerformance.DQ;
    } else {
      contractState.contractPerformance = ContractPerformance.DF;
    }

    if (contractState.nonPerformingDate == 0) {
      contractState.nonPerformingDate = protoEvent.eventTime;
    }

    return contractState;
  }

  // function STF_ANN_AD (
  //   ProtoEvent memory protoEvent,
  //   ContractTerms memory contractTerms,
  //   ContractState memory contractState
  // )
  //   internal
  //   pure
  //   returns (ContractState memory)
  // {
  //   int256 timeFromLastEvent = yearFraction(
  //     shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
  //     shiftCalcTime(protoEvent.scheduleTime, contractTerms.businessDayConvention, contractTerms.calendar),
  //     contractTerms.dayCountConvention,
  //     contractTerms.maturityDate
  //   );
  //   contractState.nominalAccrued = contractState.nominalAccrued
  //   .add(
  //     contractState.nominalInterestRate
  //     .floatMult(contractState.notionalPrincipal)
  //     .floatMult(timeFromLastEvent)
  //   );
  //   contractState.feeAccrued = contractState.feeAccrued
  //   .add(
  //     contractTerms.feeRate
  //     .floatMult(contractState.notionalPrincipal)
  //     .floatMult(timeFromLastEvent)
  //   );
  //   contractState.lastEventTime = protoEvent.scheduleTime;

  //   return contractState;
  // }

  // function STF_ANN_CD (
  //   ProtoEvent memory protoEvent,
  //   ContractTerms memory contractTerms,
  //   ContractState memory contractState
  // )
  //   internal
  //   pure
  //   returns (ContractState memory)
  // {
  //   int256 timeFromLastEvent = yearFraction(
  //     shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
  //     shiftCalcTime(protoEvent.scheduleTime, contractTerms.businessDayConvention, contractTerms.calendar),
  //     contractTerms.dayCountConvention,
  //     contractTerms.maturityDate
  //   );
  //   contractState.nominalAccrued = contractState.nominalAccrued
  //   .add(
  //     contractState.nominalInterestRate
  //     .floatMult(contractState.notionalPrincipal)
  //     .floatMult(timeFromLastEvent)
  //   );
  //   contractState.feeAccrued = contractState.feeAccrued
  //   .add(
  //     contractTerms.feeRate
  //     .floatMult(contractState.notionalPrincipal)
  //     .floatMult(timeFromLastEvent)
  //   );
  //   contractState.ContractPerformance = ContractPerformance.DF;
  //   contractState.lastEventTime = protoEvent.scheduleTime;

  //   return contractState;
  // }

  // function STF_ANN_FP (
  //   ProtoEvent memory protoEvent,
  //   ContractTerms memory contractTerms,
  //   ContractState memory contractState
  // )
  //   internal
  //   pure
  //   returns (ContractState memory)
  // {
  //   int256 timeFromLastEvent = yearFraction(
  //     shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
  //     shiftCalcTime(protoEvent.scheduleTime, contractTerms.businessDayConvention, contractTerms.calendar),
  //     contractTerms.dayCountConvention,
  //     contractTerms.maturityDate
  //   );
  //   contractState.nominalAccrued = contractState.nominalAccrued
  //   .add(
  //     contractState.nominalInterestRate
  //     .floatMult(contractState.notionalPrincipal)
  //     .floatMult(timeFromLastEvent)
  //   );
  //   contractState.feeAccrued = 0;
  //   contractState.lastEventTime = protoEvent.scheduleTime;

  //   return contractState;
  // }

  function STF_ANN_IED (
    ProtoEvent memory protoEvent,
    ContractTerms memory contractTerms,
    ContractState memory contractState,
    uint256 currentTimestamp
  )
    internal
    pure
    returns (ContractState memory)
  {
    int256 timeFromLastEvent = yearFraction(
      shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
      shiftCalcTime(protoEvent.scheduleTime, contractTerms.businessDayConvention, contractTerms.calendar),
      contractTerms.dayCountConvention,
      contractTerms.maturityDate
    );
    contractState.notionalPrincipal = roleSign(contractTerms.contractRole) * contractTerms.notionalPrincipal;
    contractState.nominalInterestRate = contractTerms.nominalInterestRate;
    contractState.lastEventTime = protoEvent.scheduleTime;

    if (contractTerms.cycleAnchorDateOfInterestPayment != 0 &&
      contractTerms.cycleAnchorDateOfInterestPayment < contractTerms.initialExchangeDate
    ) {
      contractState.accruedInterest = contractState.nominalInterestRate
      .floatMult(contractState.notionalPrincipal)
      .floatMult(
        yearFraction(
          shiftCalcTime(contractTerms.cycleAnchorDateOfInterestPayment, contractTerms.businessDayConvention, contractTerms.calendar),
          shiftCalcTime(protoEvent.scheduleTime, contractTerms.businessDayConvention, contractTerms.calendar),
          contractTerms.dayCountConvention,
          contractTerms.maturityDate
        )
      );
    }

    return contractState;
  }

  function STF_ANN_IPCI (
    ProtoEvent memory protoEvent,
    ContractTerms memory contractTerms,
    ContractState memory contractState,
    uint256 currentTimestamp
  )
    internal
    pure
    returns (ContractState memory)
  {
    int256 timeFromLastEvent = yearFraction(
      shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
      shiftCalcTime(protoEvent.scheduleTime, contractTerms.businessDayConvention, contractTerms.calendar),
      contractTerms.dayCountConvention,
      contractTerms.maturityDate
    );
    contractState.accruedInterest = contractState.accruedInterest
    .add(
      contractState.accruedInterest
      .add(
        contractState.nominalInterestRate
        .floatMult(contractState.notionalPrincipal)
        .floatMult(timeFromLastEvent)
      )
    );
    contractState.accruedInterest = 0;
    contractState.feeAccrued = contractState.feeAccrued
    .add(
      contractTerms.feeRate
      .floatMult(contractState.notionalPrincipal)
      .floatMult(timeFromLastEvent)
    );
    contractState.lastEventTime = protoEvent.scheduleTime;

    return contractState;
  }

  function STF_ANN_IP (
    ProtoEvent memory protoEvent,
    ContractTerms memory contractTerms,
    ContractState memory contractState,
    uint256 currentTimestamp
  )
    internal
    pure
    returns (ContractState memory)
  {
    int256 timeFromLastEvent = yearFraction(
      shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
      shiftCalcTime(protoEvent.scheduleTime, contractTerms.businessDayConvention, contractTerms.calendar),
      contractTerms.dayCountConvention,
      contractTerms.maturityDate
    );
    contractState.accruedInterest = 0;
    contractState.feeAccrued = contractState.feeAccrued
    .add(
      contractTerms.feeRate
      .floatMult(contractState.notionalPrincipal)
      .floatMult(timeFromLastEvent)
    );
    contractState.lastEventTime = protoEvent.scheduleTime;

    return contractState;
  }

  // function STF_ANN_PP (
  //   ProtoEvent memory protoEvent,
  //   ContractTerms memory contractTerms,
  //   ContractState memory contractState
  // )
  //   internal
  //   pure
  //   returns (ContractState memory)
  // {
  //   int256 timeFromLastEvent = yearFraction(
  //     shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
  //     shiftCalcTime(protoEvent.scheduleTime, contractTerms.businessDayConvention, contractTerms.calendar),
  //     contractTerms.dayCountConvention,
  //     contractTerms.maturityDate
  //   );
  //   contractState.nominalAccrued = contractState.nominalAccrued
  //   .add(
  //     contractState.nominalInterestRate
  //     .floatMult(contractState.notionalPrincipal)
  //     .floatMult(timeFromLastEvent)
  //   );
  //   contractState.feeAccrued = contractState.feeAccrued
  //   .add(
  //     contractTerms.feeRate
  //     .floatMult(contractState.notionalPrincipal)
  //     .floatMult(timeFromLastEvent)
  //   );
  //   contractState.notionalPrincipal -= 0; // riskFactor(contractTerms.objectCodeOfPrepaymentModel, protoEvent.scheduleTime, contractState, contractTerms) * contractState.notionalPrincipal;
  //   contractState.lastEventTime = protoEvent.scheduleTime;

  //   return contractState;
  // }

  // STF_PAM_PRD
  // function STF_ANN_PRD (
  //   ProtoEvent memory protoEvent,
  //   ContractTerms memory contractTerms,
  //   ContractState memory contractState
  // )
  //   internal
  //   pure
  //   returns (ContractState memory)
  // {
  //   int256 timeFromLastEvent = yearFraction(
  //     shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
  //     shiftCalcTime(protoEvent.scheduleTime, contractTerms.businessDayConvention, contractTerms.calendar),
  //     contractTerms.dayCountConvention,
  //     contractTerms.maturityDate
  //   );
  //   contractState.nominalAccrued = contractState.nominalAccrued
  //   .add(
  //     contractState.nominalInterestRate
  //     .floatMult(contractState.notionalPrincipal)
  //     .floatMult(timeFromLastEvent)
  //   );
  //   contractState.feeAccrued = contractState.feeAccrued
  //   .add(
  //     contractTerms.feeRate
  //     .floatMult(contractState.notionalPrincipal)
  //     .floatMult(timeFromLastEvent)
  //   );
  //   contractState.lastEventTime = protoEvent.scheduleTime;

  //   return contractState;
  // }

  function STF_ANN_PR (
    ProtoEvent memory protoEvent,
    ContractTerms memory contractTerms,
    ContractState memory contractState,
    uint256 currentTimestamp
  )
    internal
    pure
    returns (ContractState memory)
  {
    int256 timeFromLastEvent = yearFraction(
      shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
      shiftCalcTime(protoEvent.scheduleTime, contractTerms.businessDayConvention, contractTerms.calendar),
      contractTerms.dayCountConvention,
      contractTerms.maturityDate
    );
    contractState.accruedInterest = contractState.accruedInterest
    .add(
      contractState.nominalInterestRate
      .floatMult(contractState.notionalPrincipal)
      .floatMult(timeFromLastEvent)
    );
    contractState.feeAccrued = contractState.feeAccrued
    .add(
      contractTerms.feeRate
      .floatMult(contractState.notionalPrincipal)
      .floatMult(timeFromLastEvent)
    );
    contractState.notionalPrincipal = contractState.notionalPrincipal
    .sub(
      roleSign(contractTerms.contractRole)
      * (
        roleSign(contractTerms.contractRole)
        * contractState.notionalPrincipal
      )
      .min(
        roleSign(contractTerms.contractRole)
        * (
          contractState.nextPrincipalRedemptionPayment
          .sub(contractState.accruedInterest)
        )
      )
    );

    contractState.lastEventTime = protoEvent.scheduleTime;

    return contractState;
  }

  function STF_ANN_MD (
    ProtoEvent memory protoEvent,
    ContractTerms memory contractTerms,
    ContractState memory contractState,
    uint256 currentTimestamp
  )
    internal
    pure
    returns (ContractState memory)
  {
    int256 timeFromLastEvent = yearFraction(
      shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
      shiftCalcTime(protoEvent.scheduleTime, contractTerms.businessDayConvention, contractTerms.calendar),
      contractTerms.dayCountConvention,
      contractTerms.maturityDate
    );
    contractState.accruedInterest = contractState.accruedInterest
    .add(
      contractState.nominalInterestRate
      .floatMult(contractState.notionalPrincipal)
      .floatMult(timeFromLastEvent)
    );
    contractState.feeAccrued = contractState.feeAccrued
    .add(
      contractTerms.feeRate
      .floatMult(contractState.notionalPrincipal)
      .floatMult(timeFromLastEvent)
    );
    contractState.notionalPrincipal = 0.0;
    contractState.lastEventTime = protoEvent.scheduleTime;

    return contractState;
  }

  // STF_PAM_PY
  // function STF_ANN_PY (
  //   ProtoEvent memory protoEvent,
  //   ContractTerms memory contractTerms,
  //   ContractState memory contractState
  // )
  //   internal
  //   pure
  //   returns (ContractState memory)
  // {
  //   int256 timeFromLastEvent = yearFraction(
  //     shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
  //     shiftCalcTime(protoEvent.scheduleTime, contractTerms.businessDayConvention, contractTerms.calendar),
  //     contractTerms.dayCountConvention,
  //     contractTerms.maturityDate
  //   );
  //   contractState.nominalAccrued = contractState.nominalAccrued
  //   .add(
  //     contractState.nominalInterestRate
  //     .floatMult(contractState.notionalPrincipal)
  //     .floatMult(timeFromLastEvent)
  //   );
  //   contractState.feeAccrued = contractState.feeAccrued
  //   .add(
  //     contractTerms.feeRate
  //     .floatMult(contractState.notionalPrincipal)
  //     .floatMult(timeFromLastEvent)
  //   );
  //   contractState.lastEventTime = protoEvent.scheduleTime;

  //   return contractState;
  // }

  // function STF_ANN_RRF (
  //   ProtoEvent memory protoEvent,
  //   ContractTerms memory contractTerms,
  //   ContractState memory contractState
  // )
  //   internal
  //   pure
  //   returns (ContractState memory)
  // {
  //   int256 timeFromLastEvent = yearFraction(
  //     shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
  //     shiftCalcTime(protoEvent.scheduleTime, contractTerms.businessDayConvention, contractTerms.calendar),
  //     contractTerms.dayCountConvention,
  //     contractTerms.maturityDate
  //   );
  //   contractState.nominalAccrued = contractState.nominalAccrued
  //   .add(
  //     contractState.nominalInterestRate
  //     .floatMult(contractState.notionalPrincipal)
  //     .floatMult(timeFromLastEvent)
  //   );
  //   contractState.feeAccrued = contractState.feeAccrued
  //   .add(
  //     contractTerms.feeRate
  //     .floatMult(contractState.notionalPrincipal)
  //     .floatMult(timeFromLastEvent)
  //   );
  //   contractState.nominalInterestRate = contractTerms.nextResetRate;
  //   contractState.lastEventTime = protoEvent.scheduleTime;

  //   return contractState;
  // }

  function STF_ANN_RR (
    ProtoEvent memory protoEvent,
    ContractTerms memory contractTerms,
    ContractState memory contractState,
    uint256 currentTimestamp
  )
    internal
    pure
    returns (ContractState memory)
  {
    // int256 rate = //riskFactor(contractTerms.marketObjectCodeOfRateReset, protoEvent.scheduleTime, contractState, contractTerms)
    // 	* contractTerms.rateMultiplier + contractTerms.rateSpread;
    int256 rate = contractTerms.rateSpread;
    int256 deltaRate = rate.sub(contractState.nominalInterestRate);

      // apply period cap/floor
    if ((contractTerms.lifeCap < deltaRate) && (contractTerms.lifeCap < ((-1) * contractTerms.periodFloor))) {
      deltaRate = contractTerms.lifeCap;
    } else if (deltaRate < ((-1) * contractTerms.periodFloor)) {
      deltaRate = ((-1) * contractTerms.periodFloor);
    }
    rate = contractState.nominalInterestRate.add(deltaRate);

    // apply life cap/floor
    if (contractTerms.lifeCap < rate && contractTerms.lifeCap < contractTerms.lifeFloor) {
      rate = contractTerms.lifeCap;
    } else if (rate < contractTerms.lifeFloor) {
      rate = contractTerms.lifeFloor;
    }

    int256 timeFromLastEvent = yearFraction(
      shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
      shiftCalcTime(protoEvent.scheduleTime, contractTerms.businessDayConvention, contractTerms.calendar),
      contractTerms.dayCountConvention,
      contractTerms.maturityDate
    );
    contractState.accruedInterest = contractState.accruedInterest
    .add(
      contractState.nominalInterestRate
      .floatMult(contractState.notionalPrincipal)
      .floatMult(timeFromLastEvent)
    );
    contractState.nominalInterestRate = rate;
    contractState.nextPrincipalRedemptionPayment = 0; // TODO: implement annuity calculator
    contractState.lastEventTime = protoEvent.scheduleTime;

    return contractState;
  }

  function STF_ANN_SC (
    ProtoEvent memory protoEvent,
    ContractTerms memory contractTerms,
    ContractState memory contractState,
    uint256 currentTimestamp
  )
    internal
    pure
    returns (ContractState memory)
  {
    int256 timeFromLastEvent = yearFraction(
      shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
      shiftCalcTime(protoEvent.scheduleTime, contractTerms.businessDayConvention, contractTerms.calendar),
      contractTerms.dayCountConvention,
      contractTerms.maturityDate
    );
    contractState.accruedInterest = contractState.accruedInterest
    .add(
      contractState.nominalInterestRate
      .floatMult(contractState.notionalPrincipal)
      .floatMult(timeFromLastEvent)
    );
    contractState.feeAccrued = contractState.feeAccrued
    .add(
      contractTerms.feeRate
      .floatMult(contractState.notionalPrincipal)
      .floatMult(timeFromLastEvent)
    );

    if ((contractTerms.scalingEffect == ScalingEffect.I00)
      || (contractTerms.scalingEffect == ScalingEffect.IN0)
      || (contractTerms.scalingEffect == ScalingEffect.I0M)
      || (contractTerms.scalingEffect == ScalingEffect.INM)
    ) {
      contractState.interestScalingMultiplier = 0; // riskFactor(contractTerms.marketObjectCodeOfScalingIndex, protoEvent.scheduleTime, contractState, contractTerms)
    }
    if ((contractTerms.scalingEffect == ScalingEffect._0N0)
      || (contractTerms.scalingEffect == ScalingEffect._0NM)
      || (contractTerms.scalingEffect == ScalingEffect.IN0)
      || (contractTerms.scalingEffect == ScalingEffect.INM)
    ) {
      contractState.notionalScalingMultiplier = 0; // riskFactor(contractTerms.marketObjectCodeOfScalingIndex, protoEvent.scheduleTime, contractState, contractTerms)
    }

    contractState.lastEventTime = protoEvent.scheduleTime;
    return contractState;
  }

  // function STF_ANN_TD (
  //   ProtoEvent memory protoEvent,
  //   ContractTerms memory contractTerms,
  //   ContractState memory contractState
  // )
  //   internal
  //   pure
  //   returns (ContractState memory)
  // {
  //   int256 timeFromLastEvent = yearFraction(
  //     shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
  //     shiftCalcTime(protoEvent.scheduleTime, contractTerms.businessDayConvention, contractTerms.calendar),
  //     contractTerms.dayCountConvention,
  //     contractTerms.maturityDate
  //   );
  //   contractState.notionalPrincipal = 0;
  //   contractState.nominalAccrued = 0;
  //   contractState.feeAccrued = 0;
  //   contractState.lastEventTime = protoEvent.scheduleTime;

  //   return contractState;
  // }

  function STF_CEG_MD (
    ProtoEvent memory protoEvent,
    ContractTerms memory contractTerms,
    ContractState memory contractState,
    uint256 currentTimestamp
  )
    internal
    pure
    returns (ContractState memory)
  {
    contractState.notionalPrincipal = 0;
    contractState.lastEventTime = protoEvent.scheduleTime;

    return contractState;
  }

  function STF_CEG_XD (
    ProtoEvent memory protoEvent,
    ContractTerms memory contractTerms,
    ContractState memory contractState,
    uint256 currentTimestamp
  )
    internal
    pure
    returns (ContractState memory)
  {
    contractState.notionalPrincipal = 0;
    contractState.lastEventTime = protoEvent.scheduleTime;

    return contractState;
  }

  function STF_CEG_PRD (
    ProtoEvent memory protoEvent,
    ContractTerms memory contractTerms,
    ContractState memory contractState,
    uint256 currentTimestamp
  )
    internal
    pure
    returns (ContractState memory)
  {
    contractState.notionalPrincipal = roleSign(contractTerms.contractRole) * contractTerms.notionalPrincipal;
    contractState.nominalInterestRate = contractTerms.feeRate;
    contractState.lastEventTime = protoEvent.scheduleTime;

    return contractState;
  }

  function STF_CEG_FP (
    ProtoEvent memory protoEvent,
    ContractTerms memory contractTerms,
    ContractState memory contractState,
    uint256 currentTimestamp
  )
    internal
    pure
    returns (ContractState memory)
  {
    // uint256 timeFromLastEvent = yearFraction(
    //   shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
    //   shiftCalcTime(protoEvent.scheduleTime, contractTerms.businessDayConvention, contractTerms.calendar),
    //   contractTerms.dayCountConvention,
    //   contractTerms.maturityDate
    // );
    contractState.feeAccrued = 0;
    contractState.lastEventTime = protoEvent.scheduleTime;

    return contractState;
  }

    function STF_CEG_TD (
    ProtoEvent memory protoEvent,
    ContractTerms memory contractTerms,
    ContractState memory contractState,
    uint256 currentTimestamp
  )
    internal
    pure
    returns (ContractState memory)
  {
    // uint256 timeFromLastEvent = yearFraction(
    //   shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
    //   shiftCalcTime(protoEvent.scheduleTime, contractTerms.businessDayConvention, contractTerms.calendar),
    //   contractTerms.dayCountConvention,
    //   contractTerms.maturityDate
    // );
    contractState.notionalPrincipal = 0;
    contractState.accruedInterest = 0;
    contractState.feeAccrued = 0;
    contractState.lastEventTime = protoEvent.scheduleTime;

    return contractState;
  }
}