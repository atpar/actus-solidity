pragma solidity ^0.5.2;
pragma experimental ABIEncoderV2;

import "../Core/Core.sol";


/**
 * @title Contract containing all pay-off functions (POF)
 */
contract POF is Core {

  /**
	 * Calculate the pay-off for PAM Fees. The method how to calculate the fee
   * heavily depends on the selected Fee Basis.
	 * @return the fee amount
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
        roleSign(terms.contractRole)
        * terms.feeRate
      );
    }

    return (
      state.feeAccrued
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

  /**
	 * Calculate the payoff for the initial exchange
	 * @return the payoff at iniitial exchange
	 */
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
      roleSign(terms.contractRole)
      * (-1)
      * terms.notionalPrincipal
        .add(terms.premiumDiscountAtIED)
    );
  }

  /**
	 * Calculate the interest payment payoff
	 * @return the interest amount to pay
	 */
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
      state.interestScalingMultiplier
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

  /**
	 * Calculate the principal prepayment payoff
	 * @return the principal prepayment amount
	 */
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
      roleSign(terms.contractRole)
      * state.notionalPrincipal
    );
  }

  /**
   * Calculate the payoff in case of a purchase of the contract
   * @return the purchase amount
   */
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
      (
        roleSign(terms.contractRole)
        * terms.priceAtPurchaseDate
        * -1
      )
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

  /**
   * Calculate the payoff in case of a scheduled principal redemption payment
   * @return the principal redemption amount
   */
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
      state.notionalScalingMultiplier
        .floatMult(state.notionalPrincipal)
    );
  }

  /**
   * Calculate the payoff in case of a penalty event
   * @return the penalty amount
   */
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
        roleSign(terms.contractRole)
        * terms.penaltyRate
      );
    } else if (terms.penaltyType == PenaltyType.N) {
      return (
        roleSign(terms.contractRole)
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
      return (
        roleSign(terms.contractRole)
        * yearFraction(
            shiftCalcTime(state.statusDate, terms.businessDayConvention, terms.calendar),
            shiftCalcTime(scheduleTime, terms.businessDayConvention, terms.calendar),
            terms.dayCountConvention,
            terms.maturityDate
          )
          .floatMult(state.notionalPrincipal)
      );
    }
  }

  /**
   * Calculate the payoff in case of termination of a contract
   * @return the termination payoff amount
   */
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
      roleSign(terms.contractRole)
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
        roleSign(terms.contractRole)
        * terms.feeRate
      );
    } else {
      return (
        state.feeAccrued
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
      (state.notionalScalingMultiplier * roleSign(terms.contractRole))
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
      state.notionalScalingMultiplier
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
      roleSign(terms.contractRole)
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
        roleSign(terms.contractRole)
        * terms.feeRate
      );
    }

    return (
      state.feeAccrued
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