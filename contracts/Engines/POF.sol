pragma solidity ^0.5.2;
pragma experimental ABIEncoderV2;

import "../Core/Core.sol";


/**
 * @title Contract containing all pay-off functions (POF)
 */
contract POF is Core {

    function applyFXRate(int256 payoff, int256 fxRate, LifecycleTerms memory terms)
        internal
        pure
        returns (int256)
    {
        return payoff.floatMult((terms.currency != terms.settlementCurrency) ? fxRate : ONE_POINT_ZERO);
    }

    /**
     * Calculate the pay-off for PAM Fees. The method how to calculate the fee
     * heavily depends on the selected Fee Basis.
     * @return the fee amount for PAM contracts
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
            return applyFXRate(
                (
                    roleSign(terms.contractRole)
                    * terms.feeRate
                ), int256(externalData), terms
            );
        }

        return applyFXRate(
            (state.feeAccrued
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
            ), int256(externalData), terms
        );
    }

    /**
     * Calculate the payoff for the initial exchange
     * @return the payoff at iniitial exchange for PAM contracts
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
        return applyFXRate(
            (
                roleSign(terms.contractRole)
                * (-1)
                * terms.notionalPrincipal
                    .add(terms.premiumDiscountAtIED)
            ), int256(externalData), terms
        );
    }

    function POF_PAM_IP_EVAL_YEAR_FRACTION (
        LifecycleTerms memory terms,
        State memory state,
        uint256 scheduleTime
    )
        internal
        pure
        returns(int256)
    {
        return yearFraction(
            shiftCalcTime(state.statusDate, terms.businessDayConvention, terms.calendar),
            shiftCalcTime(scheduleTime, terms.businessDayConvention, terms.calendar),
            terms.dayCountConvention,
            terms.maturityDate
        );
    }

    /**
     * Calculate the interest payment payoff
     * @return the interest amount to pay for PAM contracts
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
        return applyFXRate(
            (
                state.interestScalingMultiplier
                    .floatMult(
                        state.accruedInterest
                        .add(
                            POF_PAM_IP_EVAL_YEAR_FRACTION(terms, state, scheduleTime)
                            .floatMult(state.nominalInterestRate)
                            .floatMult(state.notionalPrincipal)
                        )
                    )
            ), int256(externalData), terms
        );
    }

    /**
     * Calculate the principal prepayment payoff
     * @return the principal prepayment amount for PAM contracts
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
        return applyFXRate(
            (
                roleSign(terms.contractRole)
                * state.notionalPrincipal
            ), int256(externalData), terms
        );
    }

    /**
     * Calculate the payoff in case of maturity
     * @return the maturity payoff for PAM contracts
     */
    function POF_PAM_MD (
        LifecycleTerms memory terms,
        State memory state,
        uint256 scheduleTime,
        bytes32 externalData
    )
        internal
        pure
        returns(int256)
    {
        return applyFXRate(
            (
                state.notionalScalingMultiplier
                    .floatMult(state.notionalPrincipal)
            ), int256(externalData), terms
        );
    }

    /**
     * Calculate the payoff in case of a penalty event
     * @return the penalty amount for PAM contracts
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
            return applyFXRate(
                (
                    roleSign(terms.contractRole)
                    * terms.penaltyRate
                ), int256(externalData), terms
            );
        } else if (terms.penaltyType == PenaltyType.N) {
            return applyFXRate(
                (
                    roleSign(terms.contractRole)
                    * yearFraction(
                        shiftCalcTime(state.statusDate, terms.businessDayConvention, terms.calendar),
                        shiftCalcTime(scheduleTime, terms.businessDayConvention, terms.calendar),
                        terms.dayCountConvention,
                        terms.maturityDate
                    )
                    .floatMult(terms.penaltyRate)
                    .floatMult(state.notionalPrincipal)
                ), int256(externalData), terms
            );
        } else {
            return applyFXRate(
                (
                    roleSign(terms.contractRole)
                    * yearFraction(
                        shiftCalcTime(state.statusDate, terms.businessDayConvention, terms.calendar),
                        shiftCalcTime(scheduleTime, terms.businessDayConvention, terms.calendar),
                        terms.dayCountConvention,
                        terms.maturityDate
                    )
                    .floatMult(state.notionalPrincipal)
                ), int256(externalData), terms
            );
        }
    }

    /**
     * Calculate the payoff in case of termination of a contract
     * @return the termination payoff amount for PAM contracts
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
        return applyFXRate(
            (
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
            ), int256(externalData), terms
        );
    }

    function POF_ANN_PR_YEAR_FRACTION(
        LifecycleTerms memory terms,
        State memory state,
        uint256 scheduleTime
    )
        internal
        pure
        returns(int256)
    {
        return yearFraction(
            shiftCalcTime(state.statusDate, terms.businessDayConvention, terms.calendar),
            shiftCalcTime(scheduleTime, terms.businessDayConvention, terms.calendar),
            terms.dayCountConvention,
            terms.maturityDate
        );
    }

    /**
     * Calculate the payoff for principal redemption
     * @dev This is a replacement of the POF_PR_NAM which we have not implemented, yet
     * @return the principal redemption amount for ANN contracts
     */
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
        return applyFXRate(
            (
                (state.notionalScalingMultiplier * roleSign(terms.contractRole))
                .floatMult(
                    (roleSign(terms.contractRole) * state.notionalPrincipal)
                    .min(
                            roleSign(terms.contractRole)
                            * (
                                state.nextPrincipalRedemptionPayment
                                - state.accruedInterest
                                - POF_ANN_PR_YEAR_FRACTION(terms, state, scheduleTime)
                                .floatMult(state.nominalInterestRate)
                                .floatMult(state.notionalPrincipal)
                            )
                        )
                )
            ), int256(externalData), terms
        );
    }

    /**
     * Calculate the payoff in case of settlement
     * @return the settlement payoff amount for CEG contracts
     */
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
        return applyFXRate(
            (state.executionAmount + state.feeAccrued),
            int256(externalData),
            terms
        );
    }

    /**
     * Calculate the pay-off for CEG Fees.
     * @return the fee amount for CEG contracts
     */
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
            return applyFXRate(
                (
                    roleSign(terms.contractRole)
                    * terms.feeRate
                ), int256(externalData), terms
            );
        }

        return applyFXRate(
            (
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
            ), int256(externalData), terms
        );
    }
}