pragma solidity ^0.5.2;
pragma experimental ABIEncoderV2;

import "../Core/Core.sol";


contract STF is Core {

  function STF_PAM_AD (
    uint256 scheduleTime,
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
      shiftCalcTime(scheduleTime, contractTerms.businessDayConvention, contractTerms.calendar),
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
    contractState.lastEventTime = scheduleTime;

    return contractState;
  }

  function STF_PAM_CD (
    uint256 scheduleTime,
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
      shiftCalcTime(scheduleTime, contractTerms.businessDayConvention, contractTerms.calendar),
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
    contractState.lastEventTime = scheduleTime;

    return contractState;
  }

  function STF_PAM_FP (
    uint256 scheduleTime,
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
      shiftCalcTime(scheduleTime, contractTerms.businessDayConvention, contractTerms.calendar),
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
    contractState.lastEventTime = scheduleTime;

    return contractState;
  }

  function STF_PAM_IED (
    uint256 scheduleTime,
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
      shiftCalcTime(scheduleTime, contractTerms.businessDayConvention, contractTerms.calendar),
      contractTerms.dayCountConvention,
      contractTerms.maturityDate
    );
    contractState.notionalPrincipal = roleSign(contractTerms.contractRole) * contractTerms.notionalPrincipal;
    contractState.nominalInterestRate = contractTerms.nominalInterestRate;
    contractState.lastEventTime = scheduleTime;

    if (contractTerms.cycleAnchorDateOfInterestPayment != 0 &&
      contractTerms.cycleAnchorDateOfInterestPayment < contractTerms.initialExchangeDate
    ) {
      contractState.accruedInterest = contractState.nominalInterestRate
      .floatMult(contractState.notionalPrincipal)
      .floatMult(
        yearFraction(
          contractTerms.cycleAnchorDateOfInterestPayment,
          scheduleTime,
          contractTerms.dayCountConvention,
          contractTerms.maturityDate
        )
      );
    }

    return contractState;
  }

  function STF_PAM_IPCI (
    uint256 scheduleTime,
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
      shiftCalcTime(scheduleTime, contractTerms.businessDayConvention, contractTerms.calendar),
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
    contractState.lastEventTime = scheduleTime;

    return contractState;
  }

  function STF_PAM_IP (
    uint256 scheduleTime,
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
      shiftCalcTime(scheduleTime, contractTerms.businessDayConvention, contractTerms.calendar),
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
    contractState.lastEventTime = scheduleTime;
    
    return contractState;
  }

  function STF_PAM_PP (
    uint256 scheduleTime,
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
      shiftCalcTime(scheduleTime, contractTerms.businessDayConvention, contractTerms.calendar),
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
    contractState.notionalPrincipal -= 0; // riskFactor(contractTerms.objectCodeOfPrepaymentModel, scheduleTime, contractState, contractTerms) * contractState.notionalPrincipal;
    contractState.lastEventTime = scheduleTime;

    return contractState;
  }

  function STF_PAM_PRD (
    uint256 scheduleTime,
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
      shiftCalcTime(scheduleTime, contractTerms.businessDayConvention, contractTerms.calendar),
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
    contractState.lastEventTime = scheduleTime;

    return contractState;
  }

  function STF_PAM_PR (
    uint256 scheduleTime,
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
      shiftCalcTime(scheduleTime, contractTerms.businessDayConvention, contractTerms.calendar),
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
    contractState.lastEventTime = scheduleTime;

    return contractState;
  }

  function STF_PAM_PY (
    uint256 scheduleTime,
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
      shiftCalcTime(scheduleTime, contractTerms.businessDayConvention, contractTerms.calendar),
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
    contractState.lastEventTime = scheduleTime;

    return contractState;
  }

  function STF_PAM_RRF (
    uint256 scheduleTime,
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
      shiftCalcTime(scheduleTime, contractTerms.businessDayConvention, contractTerms.calendar),
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
    contractState.lastEventTime = scheduleTime;

    return contractState;
  }

  function STF_PAM_RR (
    uint256 scheduleTime,
    ContractTerms memory contractTerms,
    ContractState memory contractState,
    uint256 currentTimestamp
  )
    internal
    pure
    returns (ContractState memory)
  {
    // int256 rate = //riskFactor(contractTerms.marketObjectCodeOfRateReset, scheduleTime, contractState, contractTerms)
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
      shiftCalcTime(scheduleTime, contractTerms.businessDayConvention, contractTerms.calendar),
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
    contractState.lastEventTime = scheduleTime;

    return contractState;
  }

  function STF_PAM_SC (
    uint256 scheduleTime,
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
      shiftCalcTime(scheduleTime, contractTerms.businessDayConvention, contractTerms.calendar),
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
      contractState.interestScalingMultiplier = 0; // riskFactor(contractTerms.marketObjectCodeOfScalingIndex, scheduleTime, contractState, contractTerms)
    }
    if ((contractTerms.scalingEffect == ScalingEffect._0N0)
      || (contractTerms.scalingEffect == ScalingEffect._0NM)
      || (contractTerms.scalingEffect == ScalingEffect.IN0)
      || (contractTerms.scalingEffect == ScalingEffect.INM)
    ) {
      contractState.notionalScalingMultiplier = 0; // riskFactor(contractTerms.marketObjectCodeOfScalingIndex, scheduleTime, contractState, contractTerms)
    }

    contractState.lastEventTime = scheduleTime;

    return contractState;
  }

  function STF_PAM_TD (
    uint256 scheduleTime,
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
      shiftCalcTime(scheduleTime, contractTerms.businessDayConvention, contractTerms.calendar),
      contractTerms.dayCountConvention,
      contractTerms.maturityDate
    );
    contractState.notionalPrincipal = 0;
    contractState.accruedInterest = 0;
    contractState.feeAccrued = 0;
    contractState.lastEventTime = scheduleTime;

    return contractState;
  }

  function STF_PAM_DEL (
    uint256 scheduleTime,
    ContractTerms memory contractTerms,
    ContractState memory contractState,
    uint256 currentTimestamp
  )
    internal
    pure
    returns(ContractState memory)
  {
    uint256 nonPerformingDate = (contractState.nonPerformingDate == 0)
      ? shiftEventTime(scheduleTime, contractTerms.businessDayConvention, contractTerms.calendar)
      : contractState.nonPerformingDate;

    bool isInGracePeriod = false;
    if (contractTerms.gracePeriod.isSet) {
      uint256 graceDate = getTimestampPlusPeriod(contractTerms.gracePeriod, nonPerformingDate);
      if (currentTimestamp <= graceDate) {
        contractState.contractPerformance = ContractPerformance.DL;
        isInGracePeriod = true;
      }
    }

    if (contractTerms.delinquencyPeriod.isSet && !isInGracePeriod) {
      uint256 delinquencyDate = getTimestampPlusPeriod(contractTerms.delinquencyPeriod, nonPerformingDate);
      if (currentTimestamp <= delinquencyDate) {
        contractState.contractPerformance = ContractPerformance.DQ;
      } else {
        contractState.contractPerformance = ContractPerformance.DF;
      }
    }

    if (contractState.nonPerformingDate == 0) {
      contractState.nonPerformingDate = shiftEventTime(
        scheduleTime,
        contractTerms.businessDayConvention,
        contractTerms.calendar
      );
    }

    return contractState;
  }

  // function STF_ANN_AD (
  //   uint256 scheduleTime,
  //   ContractTerms memory contractTerms,
  //   ContractState memory contractState
  // )
  //   internal
  //   pure
  //   returns (ContractState memory)
  // {
  //   int256 timeFromLastEvent = yearFraction(
  //     shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
  //     shiftCalcTime(scheduleTime, contractTerms.businessDayConvention, contractTerms.calendar),
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
  //   contractState.lastEventTime = scheduleTime;

  //   return contractState;
  // }

  // function STF_ANN_CD (
  //   uint256 scheduleTime,
  //   ContractTerms memory contractTerms,
  //   ContractState memory contractState
  // )
  //   internal
  //   pure
  //   returns (ContractState memory)
  // {
  //   int256 timeFromLastEvent = yearFraction(
  //     shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
  //     shiftCalcTime(scheduleTime, contractTerms.businessDayConvention, contractTerms.calendar),
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
  //   contractState.lastEventTime = scheduleTime;

  //   return contractState;
  // }

  // function STF_ANN_FP (
  //   uint256 scheduleTime,
  //   ContractTerms memory contractTerms,
  //   ContractState memory contractState
  // )
  //   internal
  //   pure
  //   returns (ContractState memory)
  // {
  //   int256 timeFromLastEvent = yearFraction(
  //     shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
  //     shiftCalcTime(scheduleTime, contractTerms.businessDayConvention, contractTerms.calendar),
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
  //   contractState.lastEventTime = scheduleTime;

  //   return contractState;
  // }

  function STF_ANN_IED (
    uint256 scheduleTime,
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
      shiftCalcTime(scheduleTime, contractTerms.businessDayConvention, contractTerms.calendar),
      contractTerms.dayCountConvention,
      contractTerms.maturityDate
    );
    contractState.notionalPrincipal = roleSign(contractTerms.contractRole) * contractTerms.notionalPrincipal;
    contractState.nominalInterestRate = contractTerms.nominalInterestRate;
    contractState.lastEventTime = scheduleTime;

    if (contractTerms.cycleAnchorDateOfInterestPayment != 0 &&
      contractTerms.cycleAnchorDateOfInterestPayment < contractTerms.initialExchangeDate
    ) {
      contractState.accruedInterest = contractState.nominalInterestRate
      .floatMult(contractState.notionalPrincipal)
      .floatMult(
        yearFraction(
          shiftCalcTime(contractTerms.cycleAnchorDateOfInterestPayment, contractTerms.businessDayConvention, contractTerms.calendar),
          shiftCalcTime(scheduleTime, contractTerms.businessDayConvention, contractTerms.calendar),
          contractTerms.dayCountConvention,
          contractTerms.maturityDate
        )
      );
    }

    return contractState;
  }

  function STF_ANN_IPCI (
    uint256 scheduleTime,
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
      shiftCalcTime(scheduleTime, contractTerms.businessDayConvention, contractTerms.calendar),
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
    contractState.lastEventTime = scheduleTime;

    return contractState;
  }

  function STF_ANN_IP (
    uint256 scheduleTime,
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
      shiftCalcTime(scheduleTime, contractTerms.businessDayConvention, contractTerms.calendar),
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
    contractState.lastEventTime = scheduleTime;

    return contractState;
  }

  // function STF_ANN_PP (
  //   uint256 scheduleTime,
  //   ContractTerms memory contractTerms,
  //   ContractState memory contractState
  // )
  //   internal
  //   pure
  //   returns (ContractState memory)
  // {
  //   int256 timeFromLastEvent = yearFraction(
  //     shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
  //     shiftCalcTime(scheduleTime, contractTerms.businessDayConvention, contractTerms.calendar),
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
  //   contractState.notionalPrincipal -= 0; // riskFactor(contractTerms.objectCodeOfPrepaymentModel, scheduleTime, contractState, contractTerms) * contractState.notionalPrincipal;
  //   contractState.lastEventTime = scheduleTime;

  //   return contractState;
  // }

  // STF_PAM_PRD
  // function STF_ANN_PRD (
  //   uint256 scheduleTime,
  //   ContractTerms memory contractTerms,
  //   ContractState memory contractState
  // )
  //   internal
  //   pure
  //   returns (ContractState memory)
  // {
  //   int256 timeFromLastEvent = yearFraction(
  //     shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
  //     shiftCalcTime(scheduleTime, contractTerms.businessDayConvention, contractTerms.calendar),
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
  //   contractState.lastEventTime = scheduleTime;

  //   return contractState;
  // }

  function STF_ANN_PR (
    uint256 scheduleTime,
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
      shiftCalcTime(scheduleTime, contractTerms.businessDayConvention, contractTerms.calendar),
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

    contractState.lastEventTime = scheduleTime;

    return contractState;
  }

  function STF_ANN_MD (
    uint256 scheduleTime,
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
      shiftCalcTime(scheduleTime, contractTerms.businessDayConvention, contractTerms.calendar),
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
    contractState.lastEventTime = scheduleTime;

    return contractState;
  }

  // STF_PAM_PY
  // function STF_ANN_PY (
  //   uint256 scheduleTime,
  //   ContractTerms memory contractTerms,
  //   ContractState memory contractState
  // )
  //   internal
  //   pure
  //   returns (ContractState memory)
  // {
  //   int256 timeFromLastEvent = yearFraction(
  //     shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
  //     shiftCalcTime(scheduleTime, contractTerms.businessDayConvention, contractTerms.calendar),
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
  //   contractState.lastEventTime = scheduleTime;

  //   return contractState;
  // }

  // function STF_ANN_RRF (
  //   uint256 scheduleTime,
  //   ContractTerms memory contractTerms,
  //   ContractState memory contractState
  // )
  //   internal
  //   pure
  //   returns (ContractState memory)
  // {
  //   int256 timeFromLastEvent = yearFraction(
  //     shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
  //     shiftCalcTime(scheduleTime, contractTerms.businessDayConvention, contractTerms.calendar),
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
  //   contractState.lastEventTime = scheduleTime;

  //   return contractState;
  // }

  function STF_ANN_RR (
    uint256 scheduleTime,
    ContractTerms memory contractTerms,
    ContractState memory contractState,
    uint256 currentTimestamp
  )
    internal
    pure
    returns (ContractState memory)
  {
    // int256 rate = //riskFactor(contractTerms.marketObjectCodeOfRateReset, scheduleTime, contractState, contractTerms)
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
      shiftCalcTime(scheduleTime, contractTerms.businessDayConvention, contractTerms.calendar),
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
    contractState.lastEventTime = scheduleTime;

    return contractState;
  }

  function STF_ANN_SC (
    uint256 scheduleTime,
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
      shiftCalcTime(scheduleTime, contractTerms.businessDayConvention, contractTerms.calendar),
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
      contractState.interestScalingMultiplier = 0; // riskFactor(contractTerms.marketObjectCodeOfScalingIndex, scheduleTime, contractState, contractTerms)
    }
    if ((contractTerms.scalingEffect == ScalingEffect._0N0)
      || (contractTerms.scalingEffect == ScalingEffect._0NM)
      || (contractTerms.scalingEffect == ScalingEffect.IN0)
      || (contractTerms.scalingEffect == ScalingEffect.INM)
    ) {
      contractState.notionalScalingMultiplier = 0; // riskFactor(contractTerms.marketObjectCodeOfScalingIndex, scheduleTime, contractState, contractTerms)
    }

    contractState.lastEventTime = scheduleTime;
    return contractState;
  }

  // function STF_ANN_TD (
  //   uint256 scheduleTime,
  //   ContractTerms memory contractTerms,
  //   ContractState memory contractState
  // )
  //   internal
  //   pure
  //   returns (ContractState memory)
  // {
  //   int256 timeFromLastEvent = yearFraction(
  //     shiftCalcTime(contractState.lastEventTime, contractTerms.businessDayConvention, contractTerms.calendar),
  //     shiftCalcTime(scheduleTime, contractTerms.businessDayConvention, contractTerms.calendar),
  //     contractTerms.dayCountConvention,
  //     contractTerms.maturityDate
  //   );
  //   contractState.notionalPrincipal = 0;
  //   contractState.nominalAccrued = 0;
  //   contractState.feeAccrued = 0;
  //   contractState.lastEventTime = scheduleTime;

  //   return contractState;
  // }

  function STF_CEG_MD (
    uint256 scheduleTime,
    ContractTerms memory contractTerms,
    ContractState memory contractState,
    uint256 currentTimestamp
  )
    internal
    pure
    returns (ContractState memory)
  {
    contractState.notionalPrincipal = 0;
    contractState.lastEventTime = scheduleTime;

    return contractState;
  }

  function STF_CEG_XD (
    uint256 scheduleTime,
    ContractTerms memory contractTerms,
    ContractState memory contractState,
    uint256 currentTimestamp
  )
    internal
    pure
    returns (ContractState memory)
  {
    contractState.notionalPrincipal = 0;
    contractState.lastEventTime = scheduleTime;

    return contractState;
  }

  function STF_CEG_PRD (
    uint256 scheduleTime,
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
    contractState.lastEventTime = scheduleTime;

    return contractState;
  }

  function STF_CEG_FP (
    uint256 scheduleTime,
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
    //   shiftCalcTime(scheduleTime, contractTerms.businessDayConvention, contractTerms.calendar),
    //   contractTerms.dayCountConvention,
    //   contractTerms.maturityDate
    // );
    contractState.feeAccrued = 0;
    contractState.lastEventTime = scheduleTime;

    return contractState;
  }

    function STF_CEG_TD (
    uint256 scheduleTime,
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
    //   shiftCalcTime(scheduleTime, contractTerms.businessDayConvention, contractTerms.calendar),
    //   contractTerms.dayCountConvention,
    //   contractTerms.maturityDate
    // );
    contractState.notionalPrincipal = 0;
    contractState.accruedInterest = 0;
    contractState.feeAccrued = 0;
    contractState.lastEventTime = scheduleTime;

    return contractState;
  }
}