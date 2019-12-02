pragma solidity ^0.5.2;
pragma experimental ABIEncoderV2;

import "../Core/Core.sol";

/**
 * @title Contract containing all pay-off functions (POF)
 * @dev ..
 */
contract POF is Core {

  /**
	 * initialize contract state space based on the contract terms
	 * @dev see initStateSpace()
	 * @param terms Lifecycle Terms
   * @param state State
   * @param scheduleTime time
   * @param externalData data
	 * @return initial contract state
	 */
  function POF_PAM_FP (
    LifecycleTerms memory terms,
    State memory state,
    uint256 scheduleTime,
    bytes32 externalData
  )
    internal
    pure
    returns(int256)
  {
    if (terms.feeBasis == FeeBasis.A) {
      return (
        performanceIndicator(state.contractPerformance)
        * roleSign(terms.contractRole)
        * terms.feeRate
      );
    }

    return (
      performanceIndicator(state.contractPerformance)
      * state.feeAccrued
        .add(
          yearFraction(
            shiftCalcTime(state.statusDate, terms.businessDayConvention, terms.calendar),
            shiftCalcTime(scheduleTime, terms.businessDayConvention, terms.calendar),
            terms.dayCountConvention,
            terms.maturityDate
          )
          .floatMult(terms.feeRate)
          .floatMult(state.notionalPrincipal)
        )
    );
  }

  function POF_PAM_IED (
    LifecycleTerms memory terms,
    State memory state,
    uint256 scheduleTime,
    bytes32 externalData
  )
    internal
    pure
    returns(int256)
  {
    return (
      performanceIndicator(state.contractPerformance)
      * roleSign(terms.contractRole)
      * (-1)
      * terms.notionalPrincipal
        .add(terms.premiumDiscountAtIED)
    );
  }

  function POF_PAM_IP (
    LifecycleTerms memory terms,
    State memory state,
    uint256 scheduleTime,
    bytes32 externalData
  )
    internal
    pure
    returns(int256)
  {
    return (
      performanceIndicator(state.contractPerformance)
      * state.interestScalingMultiplier
        .floatMult(
          state.accruedInterest
          .add(
            yearFraction(
              shiftCalcTime(state.statusDate, terms.businessDayConvention, terms.calendar),
              shiftCalcTime(scheduleTime, terms.businessDayConvention, terms.calendar),
              terms.dayCountConvention,
              terms.maturityDate
            )
            .floatMult(state.nominalInterestRate)
            .floatMult(state.notionalPrincipal)
          )
        )
    );
  }

  function POF_PAM_PP (
    LifecycleTerms memory terms,
    State memory state,
    uint256 scheduleTime,
    bytes32 externalData
  )
    internal
    pure
    returns(int256)
  {
    return (
      performanceIndicator(state.contractPerformance)
      * roleSign(terms.contractRole)
      * 0 // riskFactor(scheduleTime, state, terms, terms.objectCodeOfPrepaymentModel)
      * state.notionalPrincipal
    );
  }

  function POF_PAM_PRD (
    LifecycleTerms memory terms,
    State memory state,
    uint256 scheduleTime,
    bytes32 externalData
  )
    internal
    pure
    returns(int256)
  {
    return (
      performanceIndicator(state.contractPerformance)
      * roleSign(terms.contractRole)
      * (-1)
      * terms.priceAtPurchaseDate
        .add(state.accruedInterest)
        .add(
          yearFraction(
            shiftCalcTime(state.statusDate, terms.businessDayConvention, terms.calendar),
            shiftCalcTime(scheduleTime, terms.businessDayConvention, terms.calendar),
            terms.dayCountConvention,
            terms.maturityDate
          )
          .floatMult(state.nominalInterestRate)
          .floatMult(state.notionalPrincipal)
        )
    );
  }

  function POF_PAM_PR (
    LifecycleTerms memory terms,
    State memory state,
    uint256 scheduleTime,
    bytes32 externalData
  )
    internal
    pure
    returns(int256)
  {
    return (
      performanceIndicator(state.contractPerformance)
      * state.notionalScalingMultiplier
        .floatMult(state.notionalPrincipal)
    );
  }

  function POF_PAM_PY (
    LifecycleTerms memory terms,
    State memory state,
    uint256 scheduleTime,
    bytes32 externalData
  )
    internal
    pure
    returns(int256)
  {
    if (terms.penaltyType == PenaltyType.A) {
      return (
        performanceIndicator(state.contractPerformance)
        * roleSign(terms.contractRole)
        * terms.penaltyRate
      );
    } else if (terms.penaltyType == PenaltyType.N) {
      return (
        performanceIndicator(state.contractPerformance)
        * roleSign(terms.contractRole)
        * yearFraction(
            shiftCalcTime(state.statusDate, terms.businessDayConvention, terms.calendar),
            shiftCalcTime(scheduleTime, terms.businessDayConvention, terms.calendar),
            terms.dayCountConvention,
            terms.maturityDate
          )
          .floatMult(terms.penaltyRate)
          .floatMult(state.notionalPrincipal)
      );
    } else {
      // riskFactor(scheduleTime, state, terms, terms.marketObjectCodeOfRateReset);
      int256 risk = 0;
      int256 param = 0;
      if (state.nominalInterestRate - risk > 0) param = state.nominalInterestRate - risk;
      return (
        performanceIndicator(state.contractPerformance)
        * roleSign(terms.contractRole)
        * yearFraction(
            shiftCalcTime(state.statusDate, terms.businessDayConvention, terms.calendar),
            shiftCalcTime(scheduleTime, terms.businessDayConvention, terms.calendar),
            terms.dayCountConvention,
            terms.maturityDate
          )
          .floatMult(state.notionalPrincipal)
          .floatMult(param)
      );
    }
  }

  function POF_PAM_TD (
    LifecycleTerms memory terms,
    State memory state,
    uint256 scheduleTime,
    bytes32 externalData
  )
    internal
    pure
    returns(int256)
  {
    return (
      performanceIndicator(state.contractPerformance)
      * roleSign(terms.contractRole)
      * terms.priceAtPurchaseDate
        .add(state.accruedInterest)
        .add(
          yearFraction(
            shiftCalcTime(state.statusDate, terms.businessDayConvention, terms.calendar),
            shiftCalcTime(scheduleTime, terms.businessDayConvention, terms.calendar),
            terms.dayCountConvention,
            terms.maturityDate
          )
          .floatMult(state.nominalInterestRate)
          .floatMult(state.notionalPrincipal)
        )
    );
  }

  function POF_ANN_FP (
    LifecycleTerms memory terms,
    State memory state,
    uint256 scheduleTime,
    bytes32 externalData
  )
    internal
    pure
    returns(int256)
  {
    if (terms.feeBasis == FeeBasis.A) {
      return (
        performanceIndicator(state.contractPerformance)
        * roleSign(terms.contractRole)
        * terms.feeRate
      );
    } else {
      return (
        performanceIndicator(state.contractPerformance)
        * state.feeAccrued
          .add(
            yearFraction(
              shiftCalcTime(state.statusDate, terms.businessDayConvention, terms.calendar),
              shiftCalcTime(scheduleTime, terms.businessDayConvention, terms.calendar),
              terms.dayCountConvention,
              terms.maturityDate
            )
            .floatMult(terms.feeRate)
            .floatMult(state.notionalPrincipal)
          )
      );
    }
  }

  function POF_ANN_PR (
    LifecycleTerms memory terms,
    State memory state,
    uint256 scheduleTime,
    bytes32 externalData
  )
    internal
    pure
    returns(int256)
  {
    return (
      performanceIndicator(state.contractPerformance)
      * (state.notionalScalingMultiplier * roleSign(terms.contractRole))
        .floatMult(
          (roleSign(terms.contractRole) * state.notionalPrincipal)
          .min(
              roleSign(terms.contractRole)
              * (
                state.nextPrincipalRedemptionPayment
                - state.accruedInterest
                - yearFraction(
                  shiftCalcTime(state.statusDate, terms.businessDayConvention, terms.calendar),
                  shiftCalcTime(scheduleTime, terms.businessDayConvention, terms.calendar),
                  terms.dayCountConvention,
                  terms.maturityDate
                )
                .floatMult(state.nominalInterestRate)
                .floatMult(state.notionalPrincipal)
              )
            )
        )
    );
  }

  function POF_ANN_MD (
    LifecycleTerms memory terms,
    State memory state,
    uint256 scheduleTime,
    bytes32 externalData
  )
    internal
    pure
    returns(int256)
  {
    return (
      performanceIndicator(state.contractPerformance)
      * state.notionalScalingMultiplier
        .floatMult(state.notionalPrincipal)
    );
  }

  function POF_CEG_MD (
    LifecycleTerms memory terms,
    State memory state,
    uint256 scheduleTime,
    bytes32 externalData
  )
    internal
    pure
    returns(int256)
  {
    return 0;
  }

  function POF_CEG_XD (
    LifecycleTerms memory terms,
    State memory state,
    uint256 scheduleTime,
    bytes32 externalData
  )
    internal
    pure
    returns(int256)
  {
    return 0;
  }

  function POF_CEG_STD (
    LifecycleTerms memory terms,
    State memory state,
    uint256 scheduleTime,
    bytes32 externalData
  )
    internal
    pure
    returns(int256)
  {
    return state.executionAmount + state.feeAccrued;
  }

  function POF_CEG_PRD (
    LifecycleTerms memory terms,
    State memory state,
    uint256 scheduleTime,
    bytes32 externalData
  )
    internal
    pure
    returns(int256)
  {
    return (
      performanceIndicator(state.contractPerformance)
      * roleSign(terms.contractRole)
      * (-1)
      * terms.priceAtPurchaseDate
    );
  }

  function POF_CEG_FP (
    LifecycleTerms memory terms,
    State memory state,
    uint256 scheduleTime,
    bytes32 externalData
  )
    internal
    pure
    returns(int256)
  {
    if (terms.feeBasis == FeeBasis.A) {
      return (
        performanceIndicator(state.contractPerformance)
        * roleSign(terms.contractRole)
        * terms.feeRate
      );
    }

    return (
      performanceIndicator(state.contractPerformance)
      * state.feeAccrued
        .add(
          yearFraction(
            shiftCalcTime(state.statusDate, terms.businessDayConvention, terms.calendar),
            shiftCalcTime(scheduleTime, terms.businessDayConvention, terms.calendar),
            terms.dayCountConvention,
            terms.maturityDate
          )
          .floatMult(terms.feeRate)
          .floatMult(state.notionalPrincipal)
        )
    );
  }
}