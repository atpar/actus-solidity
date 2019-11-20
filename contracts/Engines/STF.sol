pragma solidity ^0.5.2;
pragma experimental ABIEncoderV2;

import "../Core/Core.sol";


contract STF is Core {

  function STF_PAM_AD (
    uint256 scheduleTime,
    LifecycleTerms memory terms,
    State memory state,
    uint256 currentTimestamp
  )
    internal
    pure
    returns (State memory)
  {
    int256 timeFromLastEvent = yearFraction(
      shiftCalcTime(state.lastEventTime, terms.businessDayConvention, terms.calendar),
      shiftCalcTime(scheduleTime, terms.businessDayConvention, terms.calendar),
      terms.dayCountConvention,
      terms.maturityDate
    );
    state.accruedInterest = state.accruedInterest
    .add(
      state.nominalInterestRate
      .floatMult(state.notionalPrincipal)
      .floatMult(timeFromLastEvent)
    );
    state.feeAccrued = state.feeAccrued
    .add(
      terms.feeRate
      .floatMult(state.notionalPrincipal)
      .floatMult(timeFromLastEvent)
    );
    state.lastEventTime = scheduleTime;

    return state;
  }

  function STF_PAM_CD (
    uint256 scheduleTime,
    LifecycleTerms memory terms,
    State memory state,
    uint256 currentTimestamp
  )
    internal
    pure
    returns (State memory)
  {
    int256 timeFromLastEvent = yearFraction(
      shiftCalcTime(state.lastEventTime, terms.businessDayConvention, terms.calendar),
      shiftCalcTime(scheduleTime, terms.businessDayConvention, terms.calendar),
      terms.dayCountConvention,
      terms.maturityDate
    );
    state.accruedInterest = state.accruedInterest
    .add(
      state.nominalInterestRate
      .floatMult(state.notionalPrincipal)
      .floatMult(timeFromLastEvent)
    );
    state.feeAccrued = state.feeAccrued
    .add(
      terms.feeRate
      .floatMult(state.notionalPrincipal)
      .floatMult(timeFromLastEvent)
    );
    state.contractPerformance = ContractPerformance.DF;
    state.lastEventTime = scheduleTime;

    return state;
  }

  function STF_PAM_FP (
    uint256 scheduleTime,
    LifecycleTerms memory terms,
    State memory state,
    uint256 currentTimestamp
  )
    internal
    pure
    returns (State memory)
  {
    int256 timeFromLastEvent = yearFraction(
      shiftCalcTime(state.lastEventTime, terms.businessDayConvention, terms.calendar),
      shiftCalcTime(scheduleTime, terms.businessDayConvention, terms.calendar),
      terms.dayCountConvention,
      terms.maturityDate
    );
    state.accruedInterest = state.accruedInterest
    .add(
      state.nominalInterestRate
      .floatMult(state.notionalPrincipal)
      .floatMult(timeFromLastEvent)
    );
    state.feeAccrued = 0;
    state.lastEventTime = scheduleTime;

    return state;
  }

  function STF_PAM_IED (
    uint256 scheduleTime,
    LifecycleTerms memory terms,
    State memory state,
    uint256 currentTimestamp
  )
    internal
    pure
    returns (State memory)
  {
    int256 timeFromLastEvent = yearFraction(
      shiftCalcTime(state.lastEventTime, terms.businessDayConvention, terms.calendar),
      shiftCalcTime(scheduleTime, terms.businessDayConvention, terms.calendar),
      terms.dayCountConvention,
      terms.maturityDate
    );
    state.notionalPrincipal = roleSign(terms.contractRole) * terms.notionalPrincipal;
    state.nominalInterestRate = terms.nominalInterestRate;
    state.lastEventTime = scheduleTime;

    state.accruedInterest = terms.accruedInterest;

    // if (terms.cycleAnchorDateOfInterestPayment != 0 &&
    //   terms.cycleAnchorDateOfInterestPayment < terms.initialExchangeDate
    // ) {
    //   state.accruedInterest = state.nominalInterestRate
    //   .floatMult(state.notionalPrincipal)
    //   .floatMult(
    //     yearFraction(
    //       terms.cycleAnchorDateOfInterestPayment,
    //       scheduleTime,
    //       terms.dayCountConvention,
    //       terms.maturityDate
    //     )
    //   );
    // }

    return state;
  }

  function STF_PAM_IPCI (
    uint256 scheduleTime,
    LifecycleTerms memory terms,
    State memory state,
    uint256 currentTimestamp
  )
    internal
    pure
    returns (State memory)
  {
    int256 timeFromLastEvent = yearFraction(
      shiftCalcTime(state.lastEventTime, terms.businessDayConvention, terms.calendar),
      shiftCalcTime(scheduleTime, terms.businessDayConvention, terms.calendar),
      terms.dayCountConvention,
      terms.maturityDate
    );
    state.notionalPrincipal = state.notionalPrincipal
    .add(
      state.accruedInterest
      .add(
        state.nominalInterestRate
        .floatMult(state.notionalPrincipal)
        .floatMult(timeFromLastEvent)
      )
    );
    state.accruedInterest = 0;
    state.feeAccrued = state.feeAccrued
    .add(
      terms.feeRate
      .floatMult(state.notionalPrincipal)
      .floatMult(timeFromLastEvent)
    );
    state.lastEventTime = scheduleTime;

    return state;
  }

  function STF_PAM_IP (
    uint256 scheduleTime,
    LifecycleTerms memory terms,
    State memory state,
    uint256 currentTimestamp
  )
    internal
    pure
    returns (State memory)
  {
    int256 timeFromLastEvent = yearFraction(
      shiftCalcTime(state.lastEventTime, terms.businessDayConvention, terms.calendar),
      shiftCalcTime(scheduleTime, terms.businessDayConvention, terms.calendar),
      terms.dayCountConvention,
      terms.maturityDate
    );
    state.accruedInterest = 0;
    state.feeAccrued = state.feeAccrued
    .add(
      terms.feeRate
      .floatMult(state.notionalPrincipal)
      .floatMult(timeFromLastEvent)
    );
    state.lastEventTime = scheduleTime;
    
    return state;
  }

  function STF_PAM_PP (
    uint256 scheduleTime,
    LifecycleTerms memory terms,
    State memory state,
    uint256 currentTimestamp
  )
    internal
    pure
    returns (State memory)
  {
    int256 timeFromLastEvent = yearFraction(
      shiftCalcTime(state.lastEventTime, terms.businessDayConvention, terms.calendar),
      shiftCalcTime(scheduleTime, terms.businessDayConvention, terms.calendar),
      terms.dayCountConvention,
      terms.maturityDate
    );
    state.accruedInterest = state.accruedInterest
    .add(
      state.nominalInterestRate
      .floatMult(state.notionalPrincipal)
      .floatMult(timeFromLastEvent)
    );
    state.feeAccrued = state.feeAccrued
    .add(
      terms.feeRate
      .floatMult(state.notionalPrincipal)
      .floatMult(timeFromLastEvent)
    );
    state.notionalPrincipal -= 0; // riskFactor(terms.objectCodeOfPrepaymentModel, scheduleTime, state, terms) * state.notionalPrincipal;
    state.lastEventTime = scheduleTime;

    return state;
  }

  function STF_PAM_PRD (
    uint256 scheduleTime,
    LifecycleTerms memory terms,
    State memory state,
    uint256 currentTimestamp
  )
    internal
    pure
    returns (State memory)
  {
    int256 timeFromLastEvent = yearFraction(
      shiftCalcTime(state.lastEventTime, terms.businessDayConvention, terms.calendar),
      shiftCalcTime(scheduleTime, terms.businessDayConvention, terms.calendar),
      terms.dayCountConvention,
      terms.maturityDate
    );
    state.accruedInterest = state.accruedInterest
    .add(
      state.nominalInterestRate
      .floatMult(state.notionalPrincipal)
      .floatMult(timeFromLastEvent)
    );
    state.feeAccrued = state.feeAccrued
    .add(
      terms.feeRate
      .floatMult(state.notionalPrincipal)
      .floatMult(timeFromLastEvent)
    );
    state.lastEventTime = scheduleTime;

    return state;
  }

  function STF_PAM_PR (
    uint256 scheduleTime,
    LifecycleTerms memory terms,
    State memory state,
    uint256 currentTimestamp
  )
    internal
    pure
    returns (State memory)
  {
    int256 timeFromLastEvent = yearFraction(
      shiftCalcTime(state.lastEventTime, terms.businessDayConvention, terms.calendar),
      shiftCalcTime(scheduleTime, terms.businessDayConvention, terms.calendar),
      terms.dayCountConvention,
      terms.maturityDate
    );
    state.accruedInterest = state.accruedInterest
    .add(
      state.nominalInterestRate
      .floatMult(state.notionalPrincipal)
      .floatMult(timeFromLastEvent)
    );
    state.feeAccrued = state.feeAccrued
    .add(
      terms.feeRate
      .floatMult(state.notionalPrincipal)
      .floatMult(timeFromLastEvent)
    );
    state.notionalPrincipal = 0;
    state.lastEventTime = scheduleTime;

    return state;
  }

  function STF_PAM_PY (
    uint256 scheduleTime,
    LifecycleTerms memory terms,
    State memory state,
    uint256 currentTimestamp
  )
    internal
    pure
    returns (State memory)
  {
    int256 timeFromLastEvent = yearFraction(
      shiftCalcTime(state.lastEventTime, terms.businessDayConvention, terms.calendar),
      shiftCalcTime(scheduleTime, terms.businessDayConvention, terms.calendar),
      terms.dayCountConvention,
      terms.maturityDate
    );
    state.accruedInterest = state.accruedInterest
    .add(
      state.nominalInterestRate
      .floatMult(state.notionalPrincipal)
      .floatMult(timeFromLastEvent)
    );
    state.feeAccrued = state.feeAccrued
    .add(
      terms.feeRate
      .floatMult(state.notionalPrincipal)
      .floatMult(timeFromLastEvent)
    );
    state.lastEventTime = scheduleTime;

    return state;
  }

  function STF_PAM_RRF (
    uint256 scheduleTime,
    LifecycleTerms memory terms,
    State memory state,
    uint256 currentTimestamp
  )
    internal
    pure
    returns (State memory)
  {
    int256 timeFromLastEvent = yearFraction(
      shiftCalcTime(state.lastEventTime, terms.businessDayConvention, terms.calendar),
      shiftCalcTime(scheduleTime, terms.businessDayConvention, terms.calendar),
      terms.dayCountConvention,
      terms.maturityDate
    );
    state.accruedInterest = state.accruedInterest
    .add(
      state.nominalInterestRate
      .floatMult(state.notionalPrincipal)
      .floatMult(timeFromLastEvent)
    );
    state.feeAccrued = state.feeAccrued
    .add(
      terms.feeRate
      .floatMult(state.notionalPrincipal)
      .floatMult(timeFromLastEvent)
    );
    state.nominalInterestRate = terms.nextResetRate;
    state.lastEventTime = scheduleTime;

    return state;
  }

  function STF_PAM_RR (
    uint256 scheduleTime,
    LifecycleTerms memory terms,
    State memory state,
    uint256 currentTimestamp
  )
    internal
    pure
    returns (State memory)
  {
    // int256 rate = //riskFactor(terms.marketObjectCodeOfRateReset, scheduleTime, state, terms)
    // 	* terms.rateMultiplier + terms.rateSpread;
    int256 rate = terms.rateSpread;
    int256 deltaRate = rate.sub(state.nominalInterestRate);

      // apply period cap/floor
    if ((terms.lifeCap < deltaRate) && (terms.lifeCap < ((-1) * terms.periodFloor))) {
      deltaRate = terms.lifeCap;
    } else if (deltaRate < ((-1) * terms.periodFloor)) {
      deltaRate = ((-1) * terms.periodFloor);
    }
    rate = state.nominalInterestRate.add(deltaRate);

    // apply life cap/floor
    if (terms.lifeCap < rate && terms.lifeCap < terms.lifeFloor) {
      rate = terms.lifeCap;
    } else if (rate < terms.lifeFloor) {
      rate = terms.lifeFloor;
    }

    int256 timeFromLastEvent = yearFraction(
      shiftCalcTime(state.lastEventTime, terms.businessDayConvention, terms.calendar),
      shiftCalcTime(scheduleTime, terms.businessDayConvention, terms.calendar),
      terms.dayCountConvention,
      terms.maturityDate
    );
    state.accruedInterest = state.accruedInterest
    .add(
      state.nominalInterestRate
      .floatMult(state.notionalPrincipal)
      .floatMult(timeFromLastEvent)
    );
    state.nominalInterestRate = rate;
    state.lastEventTime = scheduleTime;

    return state;
  }

  function STF_PAM_SC (
    uint256 scheduleTime,
    LifecycleTerms memory terms,
    State memory state,
    uint256 currentTimestamp
  )
    internal
    pure
    returns (State memory)
  {
    int256 timeFromLastEvent = yearFraction(
      shiftCalcTime(state.lastEventTime, terms.businessDayConvention, terms.calendar),
      shiftCalcTime(scheduleTime, terms.businessDayConvention, terms.calendar),
      terms.dayCountConvention,
      terms.maturityDate
    );
    state.accruedInterest = state.accruedInterest
    .add(
      state.nominalInterestRate
      .floatMult(state.notionalPrincipal)
      .floatMult(timeFromLastEvent)
    );
    state.feeAccrued = state.feeAccrued
    .add(
      terms.feeRate
      .floatMult(state.notionalPrincipal)
      .floatMult(timeFromLastEvent)
    );

    if ((terms.scalingEffect == ScalingEffect.I00)
      || (terms.scalingEffect == ScalingEffect.IN0)
      || (terms.scalingEffect == ScalingEffect.I0M)
      || (terms.scalingEffect == ScalingEffect.INM)
    ) {
      state.interestScalingMultiplier = 0; // riskFactor(terms.marketObjectCodeOfScalingIndex, scheduleTime, state, terms)
    }
    if ((terms.scalingEffect == ScalingEffect._0N0)
      || (terms.scalingEffect == ScalingEffect._0NM)
      || (terms.scalingEffect == ScalingEffect.IN0)
      || (terms.scalingEffect == ScalingEffect.INM)
    ) {
      state.notionalScalingMultiplier = 0; // riskFactor(terms.marketObjectCodeOfScalingIndex, scheduleTime, state, terms)
    }

    state.lastEventTime = scheduleTime;

    return state;
  }

  function STF_PAM_TD (
    uint256 scheduleTime,
    LifecycleTerms memory terms,
    State memory state,
    uint256 currentTimestamp
  )
    internal
    pure
    returns (State memory)
  {
    int256 timeFromLastEvent = yearFraction(
      shiftCalcTime(state.lastEventTime, terms.businessDayConvention, terms.calendar),
      shiftCalcTime(scheduleTime, terms.businessDayConvention, terms.calendar),
      terms.dayCountConvention,
      terms.maturityDate
    );
    state.notionalPrincipal = 0;
    state.accruedInterest = 0;
    state.feeAccrued = 0;
    state.lastEventTime = scheduleTime;

    return state;
  }

  function STF_PAM_DEL (
    uint256 scheduleTime,
    LifecycleTerms memory terms,
    State memory state,
    uint256 currentTimestamp
  )
    internal
    pure
    returns(State memory)
  {
    uint256 nonPerformingDate = (state.nonPerformingDate == 0)
      ? shiftEventTime(scheduleTime, terms.businessDayConvention, terms.calendar)
      : state.nonPerformingDate;

    bool isInGracePeriod = false;
    if (terms.gracePeriod.isSet) {
      uint256 graceDate = getTimestampPlusPeriod(terms.gracePeriod, nonPerformingDate);
      if (currentTimestamp <= graceDate) {
        state.contractPerformance = ContractPerformance.DL;
        isInGracePeriod = true;
      }
    }

    if (terms.delinquencyPeriod.isSet && !isInGracePeriod) {
      uint256 delinquencyDate = getTimestampPlusPeriod(terms.delinquencyPeriod, nonPerformingDate);
      if (currentTimestamp <= delinquencyDate) {
        state.contractPerformance = ContractPerformance.DQ;
      } else {
        state.contractPerformance = ContractPerformance.DF;
      }
    }

    if (state.nonPerformingDate == 0) {
      state.nonPerformingDate = shiftEventTime(
        scheduleTime,
        terms.businessDayConvention,
        terms.calendar
      );
    }

    return state;
  }

  // function STF_ANN_AD (
  //   uint256 scheduleTime,
  //   LifecycleTerms memory terms,
  //   State memory state
  // )
  //   internal
  //   pure
  //   returns (State memory)
  // {
  //   int256 timeFromLastEvent = yearFraction(
  //     shiftCalcTime(state.lastEventTime, terms.businessDayConvention, terms.calendar),
  //     shiftCalcTime(scheduleTime, terms.businessDayConvention, terms.calendar),
  //     terms.dayCountConvention,
  //     terms.maturityDate
  //   );
  //   state.nominalAccrued = state.nominalAccrued
  //   .add(
  //     state.nominalInterestRate
  //     .floatMult(state.notionalPrincipal)
  //     .floatMult(timeFromLastEvent)
  //   );
  //   state.feeAccrued = state.feeAccrued
  //   .add(
  //     terms.feeRate
  //     .floatMult(state.notionalPrincipal)
  //     .floatMult(timeFromLastEvent)
  //   );
  //   state.lastEventTime = scheduleTime;

  //   return state;
  // }

  // function STF_ANN_CD (
  //   uint256 scheduleTime,
  //   LifecycleTerms memory terms,
  //   State memory state
  // )
  //   internal
  //   pure
  //   returns (State memory)
  // {
  //   int256 timeFromLastEvent = yearFraction(
  //     shiftCalcTime(state.lastEventTime, terms.businessDayConvention, terms.calendar),
  //     shiftCalcTime(scheduleTime, terms.businessDayConvention, terms.calendar),
  //     terms.dayCountConvention,
  //     terms.maturityDate
  //   );
  //   state.nominalAccrued = state.nominalAccrued
  //   .add(
  //     state.nominalInterestRate
  //     .floatMult(state.notionalPrincipal)
  //     .floatMult(timeFromLastEvent)
  //   );
  //   state.feeAccrued = state.feeAccrued
  //   .add(
  //     terms.feeRate
  //     .floatMult(state.notionalPrincipal)
  //     .floatMult(timeFromLastEvent)
  //   );
  //   state.ContractPerformance = ContractPerformance.DF;
  //   state.lastEventTime = scheduleTime;

  //   return state;
  // }

  // function STF_ANN_FP (
  //   uint256 scheduleTime,
  //   LifecycleTerms memory terms,
  //   State memory state
  // )
  //   internal
  //   pure
  //   returns (State memory)
  // {
  //   int256 timeFromLastEvent = yearFraction(
  //     shiftCalcTime(state.lastEventTime, terms.businessDayConvention, terms.calendar),
  //     shiftCalcTime(scheduleTime, terms.businessDayConvention, terms.calendar),
  //     terms.dayCountConvention,
  //     terms.maturityDate
  //   );
  //   state.nominalAccrued = state.nominalAccrued
  //   .add(
  //     state.nominalInterestRate
  //     .floatMult(state.notionalPrincipal)
  //     .floatMult(timeFromLastEvent)
  //   );
  //   state.feeAccrued = 0;
  //   state.lastEventTime = scheduleTime;

  //   return state;
  // }

  function STF_ANN_IED (
    uint256 scheduleTime,
    LifecycleTerms memory terms,
    State memory state,
    uint256 currentTimestamp
  )
    internal
    pure
    returns (State memory)
  {
    int256 timeFromLastEvent = yearFraction(
      shiftCalcTime(state.lastEventTime, terms.businessDayConvention, terms.calendar),
      shiftCalcTime(scheduleTime, terms.businessDayConvention, terms.calendar),
      terms.dayCountConvention,
      terms.maturityDate
    );
    state.notionalPrincipal = roleSign(terms.contractRole) * terms.notionalPrincipal;
    state.nominalInterestRate = terms.nominalInterestRate;
    state.lastEventTime = scheduleTime;

    state.accruedInterest = terms.accruedInterest;

    // if (terms.cycleAnchorDateOfInterestPayment != 0 &&
    //   terms.cycleAnchorDateOfInterestPayment < terms.initialExchangeDate
    // ) {
    //   state.accruedInterest = state.nominalInterestRate
    //   .floatMult(state.notionalPrincipal)
    //   .floatMult(
    //     yearFraction(
    //       shiftCalcTime(terms.cycleAnchorDateOfInterestPayment, terms.businessDayConvention, terms.calendar),
    //       shiftCalcTime(scheduleTime, terms.businessDayConvention, terms.calendar),
    //       terms.dayCountConvention,
    //       terms.maturityDate
    //     )
    //   );
    // }

    return state;
  }

  function STF_ANN_IPCI (
    uint256 scheduleTime,
    LifecycleTerms memory terms,
    State memory state,
    uint256 currentTimestamp
  )
    internal
    pure
    returns (State memory)
  {
    int256 timeFromLastEvent = yearFraction(
      shiftCalcTime(state.lastEventTime, terms.businessDayConvention, terms.calendar),
      shiftCalcTime(scheduleTime, terms.businessDayConvention, terms.calendar),
      terms.dayCountConvention,
      terms.maturityDate
    );
    state.accruedInterest = state.accruedInterest
    .add(
      state.accruedInterest
      .add(
        state.nominalInterestRate
        .floatMult(state.notionalPrincipal)
        .floatMult(timeFromLastEvent)
      )
    );
    state.accruedInterest = 0;
    state.feeAccrued = state.feeAccrued
    .add(
      terms.feeRate
      .floatMult(state.notionalPrincipal)
      .floatMult(timeFromLastEvent)
    );
    state.lastEventTime = scheduleTime;

    return state;
  }

  function STF_ANN_IP (
    uint256 scheduleTime,
    LifecycleTerms memory terms,
    State memory state,
    uint256 currentTimestamp
  )
    internal
    pure
    returns (State memory)
  {
    int256 timeFromLastEvent = yearFraction(
      shiftCalcTime(state.lastEventTime, terms.businessDayConvention, terms.calendar),
      shiftCalcTime(scheduleTime, terms.businessDayConvention, terms.calendar),
      terms.dayCountConvention,
      terms.maturityDate
    );
    state.accruedInterest = 0;
    state.feeAccrued = state.feeAccrued
    .add(
      terms.feeRate
      .floatMult(state.notionalPrincipal)
      .floatMult(timeFromLastEvent)
    );
    state.lastEventTime = scheduleTime;

    return state;
  }

  // function STF_ANN_PP (
  //   uint256 scheduleTime,
  //   LifecycleTerms memory terms,
  //   State memory state
  // )
  //   internal
  //   pure
  //   returns (State memory)
  // {
  //   int256 timeFromLastEvent = yearFraction(
  //     shiftCalcTime(state.lastEventTime, terms.businessDayConvention, terms.calendar),
  //     shiftCalcTime(scheduleTime, terms.businessDayConvention, terms.calendar),
  //     terms.dayCountConvention,
  //     terms.maturityDate
  //   );
  //   state.nominalAccrued = state.nominalAccrued
  //   .add(
  //     state.nominalInterestRate
  //     .floatMult(state.notionalPrincipal)
  //     .floatMult(timeFromLastEvent)
  //   );
  //   state.feeAccrued = state.feeAccrued
  //   .add(
  //     terms.feeRate
  //     .floatMult(state.notionalPrincipal)
  //     .floatMult(timeFromLastEvent)
  //   );
  //   state.notionalPrincipal -= 0; // riskFactor(terms.objectCodeOfPrepaymentModel, scheduleTime, state, terms) * state.notionalPrincipal;
  //   state.lastEventTime = scheduleTime;

  //   return state;
  // }

  // STF_PAM_PRD
  // function STF_ANN_PRD (
  //   uint256 scheduleTime,
  //   LifecycleTerms memory terms,
  //   State memory state
  // )
  //   internal
  //   pure
  //   returns (State memory)
  // {
  //   int256 timeFromLastEvent = yearFraction(
  //     shiftCalcTime(state.lastEventTime, terms.businessDayConvention, terms.calendar),
  //     shiftCalcTime(scheduleTime, terms.businessDayConvention, terms.calendar),
  //     terms.dayCountConvention,
  //     terms.maturityDate
  //   );
  //   state.nominalAccrued = state.nominalAccrued
  //   .add(
  //     state.nominalInterestRate
  //     .floatMult(state.notionalPrincipal)
  //     .floatMult(timeFromLastEvent)
  //   );
  //   state.feeAccrued = state.feeAccrued
  //   .add(
  //     terms.feeRate
  //     .floatMult(state.notionalPrincipal)
  //     .floatMult(timeFromLastEvent)
  //   );
  //   state.lastEventTime = scheduleTime;

  //   return state;
  // }

  function STF_ANN_PR (
    uint256 scheduleTime,
    LifecycleTerms memory terms,
    State memory state,
    uint256 currentTimestamp
  )
    internal
    pure
    returns (State memory)
  {
    int256 timeFromLastEvent = yearFraction(
      shiftCalcTime(state.lastEventTime, terms.businessDayConvention, terms.calendar),
      shiftCalcTime(scheduleTime, terms.businessDayConvention, terms.calendar),
      terms.dayCountConvention,
      terms.maturityDate
    );
    state.accruedInterest = state.accruedInterest
    .add(
      state.nominalInterestRate
      .floatMult(state.notionalPrincipal)
      .floatMult(timeFromLastEvent)
    );
    state.feeAccrued = state.feeAccrued
    .add(
      terms.feeRate
      .floatMult(state.notionalPrincipal)
      .floatMult(timeFromLastEvent)
    );
    state.notionalPrincipal = state.notionalPrincipal
    .sub(
      roleSign(terms.contractRole)
      * (
        roleSign(terms.contractRole)
        * state.notionalPrincipal
      )
      .min(
        roleSign(terms.contractRole)
        * (
          state.nextPrincipalRedemptionPayment
          .sub(state.accruedInterest)
        )
      )
    );

    state.lastEventTime = scheduleTime;

    return state;
  }

  function STF_ANN_MD (
    uint256 scheduleTime,
    LifecycleTerms memory terms,
    State memory state,
    uint256 currentTimestamp
  )
    internal
    pure
    returns (State memory)
  {
    int256 timeFromLastEvent = yearFraction(
      shiftCalcTime(state.lastEventTime, terms.businessDayConvention, terms.calendar),
      shiftCalcTime(scheduleTime, terms.businessDayConvention, terms.calendar),
      terms.dayCountConvention,
      terms.maturityDate
    );
    state.accruedInterest = state.accruedInterest
    .add(
      state.nominalInterestRate
      .floatMult(state.notionalPrincipal)
      .floatMult(timeFromLastEvent)
    );
    state.feeAccrued = state.feeAccrued
    .add(
      terms.feeRate
      .floatMult(state.notionalPrincipal)
      .floatMult(timeFromLastEvent)
    );
    state.notionalPrincipal = 0.0;
    state.lastEventTime = scheduleTime;

    return state;
  }

  // STF_PAM_PY
  // function STF_ANN_PY (
  //   uint256 scheduleTime,
  //   LifecycleTerms memory terms,
  //   State memory state
  // )
  //   internal
  //   pure
  //   returns (State memory)
  // {
  //   int256 timeFromLastEvent = yearFraction(
  //     shiftCalcTime(state.lastEventTime, terms.businessDayConvention, terms.calendar),
  //     shiftCalcTime(scheduleTime, terms.businessDayConvention, terms.calendar),
  //     terms.dayCountConvention,
  //     terms.maturityDate
  //   );
  //   state.nominalAccrued = state.nominalAccrued
  //   .add(
  //     state.nominalInterestRate
  //     .floatMult(state.notionalPrincipal)
  //     .floatMult(timeFromLastEvent)
  //   );
  //   state.feeAccrued = state.feeAccrued
  //   .add(
  //     terms.feeRate
  //     .floatMult(state.notionalPrincipal)
  //     .floatMult(timeFromLastEvent)
  //   );
  //   state.lastEventTime = scheduleTime;

  //   return state;
  // }

  // function STF_ANN_RRF (
  //   uint256 scheduleTime,
  //   LifecycleTerms memory terms,
  //   State memory state
  // )
  //   internal
  //   pure
  //   returns (State memory)
  // {
  //   int256 timeFromLastEvent = yearFraction(
  //     shiftCalcTime(state.lastEventTime, terms.businessDayConvention, terms.calendar),
  //     shiftCalcTime(scheduleTime, terms.businessDayConvention, terms.calendar),
  //     terms.dayCountConvention,
  //     terms.maturityDate
  //   );
  //   state.nominalAccrued = state.nominalAccrued
  //   .add(
  //     state.nominalInterestRate
  //     .floatMult(state.notionalPrincipal)
  //     .floatMult(timeFromLastEvent)
  //   );
  //   state.feeAccrued = state.feeAccrued
  //   .add(
  //     terms.feeRate
  //     .floatMult(state.notionalPrincipal)
  //     .floatMult(timeFromLastEvent)
  //   );
  //   state.nominalInterestRate = terms.nextResetRate;
  //   state.lastEventTime = scheduleTime;

  //   return state;
  // }

  function STF_ANN_RR (
    uint256 scheduleTime,
    LifecycleTerms memory terms,
    State memory state,
    uint256 currentTimestamp
  )
    internal
    pure
    returns (State memory)
  {
    // int256 rate = //riskFactor(terms.marketObjectCodeOfRateReset, scheduleTime, state, terms)
    // 	* terms.rateMultiplier + terms.rateSpread;
    int256 rate = terms.rateSpread;
    int256 deltaRate = rate.sub(state.nominalInterestRate);

      // apply period cap/floor
    if ((terms.lifeCap < deltaRate) && (terms.lifeCap < ((-1) * terms.periodFloor))) {
      deltaRate = terms.lifeCap;
    } else if (deltaRate < ((-1) * terms.periodFloor)) {
      deltaRate = ((-1) * terms.periodFloor);
    }
    rate = state.nominalInterestRate.add(deltaRate);

    // apply life cap/floor
    if (terms.lifeCap < rate && terms.lifeCap < terms.lifeFloor) {
      rate = terms.lifeCap;
    } else if (rate < terms.lifeFloor) {
      rate = terms.lifeFloor;
    }

    int256 timeFromLastEvent = yearFraction(
      shiftCalcTime(state.lastEventTime, terms.businessDayConvention, terms.calendar),
      shiftCalcTime(scheduleTime, terms.businessDayConvention, terms.calendar),
      terms.dayCountConvention,
      terms.maturityDate
    );
    state.accruedInterest = state.accruedInterest
    .add(
      state.nominalInterestRate
      .floatMult(state.notionalPrincipal)
      .floatMult(timeFromLastEvent)
    );
    state.nominalInterestRate = rate;
    state.nextPrincipalRedemptionPayment = 0; // TODO: implement annuity calculator
    state.lastEventTime = scheduleTime;

    return state;
  }

  function STF_ANN_SC (
    uint256 scheduleTime,
    LifecycleTerms memory terms,
    State memory state,
    uint256 currentTimestamp
  )
    internal
    pure
    returns (State memory)
  {
    int256 timeFromLastEvent = yearFraction(
      shiftCalcTime(state.lastEventTime, terms.businessDayConvention, terms.calendar),
      shiftCalcTime(scheduleTime, terms.businessDayConvention, terms.calendar),
      terms.dayCountConvention,
      terms.maturityDate
    );
    state.accruedInterest = state.accruedInterest
    .add(
      state.nominalInterestRate
      .floatMult(state.notionalPrincipal)
      .floatMult(timeFromLastEvent)
    );
    state.feeAccrued = state.feeAccrued
    .add(
      terms.feeRate
      .floatMult(state.notionalPrincipal)
      .floatMult(timeFromLastEvent)
    );

    if ((terms.scalingEffect == ScalingEffect.I00)
      || (terms.scalingEffect == ScalingEffect.IN0)
      || (terms.scalingEffect == ScalingEffect.I0M)
      || (terms.scalingEffect == ScalingEffect.INM)
    ) {
      state.interestScalingMultiplier = 0; // riskFactor(terms.marketObjectCodeOfScalingIndex, scheduleTime, state, terms)
    }
    if ((terms.scalingEffect == ScalingEffect._0N0)
      || (terms.scalingEffect == ScalingEffect._0NM)
      || (terms.scalingEffect == ScalingEffect.IN0)
      || (terms.scalingEffect == ScalingEffect.INM)
    ) {
      state.notionalScalingMultiplier = 0; // riskFactor(terms.marketObjectCodeOfScalingIndex, scheduleTime, state, terms)
    }

    state.lastEventTime = scheduleTime;
    return state;
  }

  // function STF_ANN_TD (
  //   uint256 scheduleTime,
  //   LifecycleTerms memory terms,
  //   State memory state
  // )
  //   internal
  //   pure
  //   returns (State memory)
  // {
  //   int256 timeFromLastEvent = yearFraction(
  //     shiftCalcTime(state.lastEventTime, terms.businessDayConvention, terms.calendar),
  //     shiftCalcTime(scheduleTime, terms.businessDayConvention, terms.calendar),
  //     terms.dayCountConvention,
  //     terms.maturityDate
  //   );
  //   state.notionalPrincipal = 0;
  //   state.nominalAccrued = 0;
  //   state.feeAccrued = 0;
  //   state.lastEventTime = scheduleTime;

  //   return state;
  // }

  function STF_CEG_MD (
    uint256 scheduleTime,
    LifecycleTerms memory terms,
    State memory state,
    uint256 currentTimestamp
  )
    internal
    pure
    returns (State memory)
  {
    state.notionalPrincipal = 0;
    state.lastEventTime = scheduleTime;

    return state;
  }

  function STF_CEG_XD (
    uint256 scheduleTime,
    LifecycleTerms memory terms,
    State memory state,
    uint256 currentTimestamp
  )
    internal
    pure
    returns (State memory)
  {
    state.notionalPrincipal = 0;
    state.lastEventTime = scheduleTime;

    return state;
  }

  function STF_CEG_PRD (
    uint256 scheduleTime,
    LifecycleTerms memory terms,
    State memory state,
    uint256 currentTimestamp
  )
    internal
    pure
    returns (State memory)
  {
    state.notionalPrincipal = roleSign(terms.contractRole) * terms.notionalPrincipal;
    state.nominalInterestRate = terms.feeRate;
    state.lastEventTime = scheduleTime;

    return state;
  }

  function STF_CEG_FP (
    uint256 scheduleTime,
    LifecycleTerms memory terms,
    State memory state,
    uint256 currentTimestamp
  )
    internal
    pure
    returns (State memory)
  {
    // uint256 timeFromLastEvent = yearFraction(
    //   shiftCalcTime(state.lastEventTime, terms.businessDayConvention, terms.calendar),
    //   shiftCalcTime(scheduleTime, terms.businessDayConvention, terms.calendar),
    //   terms.dayCountConvention,
    //   terms.maturityDate
    // );
    state.feeAccrued = 0;
    state.lastEventTime = scheduleTime;

    return state;
  }

    function STF_CEG_TD (
    uint256 scheduleTime,
    LifecycleTerms memory terms,
    State memory state,
    uint256 currentTimestamp
  )
    internal
    pure
    returns (State memory)
  {
    // uint256 timeFromLastEvent = yearFraction(
    //   shiftCalcTime(state.lastEventTime, terms.businessDayConvention, terms.calendar),
    //   shiftCalcTime(scheduleTime, terms.businessDayConvention, terms.calendar),
    //   terms.dayCountConvention,
    //   terms.maturityDate
    // );
    state.notionalPrincipal = 0;
    state.accruedInterest = 0;
    state.feeAccrued = 0;
    state.lastEventTime = scheduleTime;

    return state;
  }
}