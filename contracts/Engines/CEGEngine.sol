pragma solidity ^0.5.2;
pragma experimental ABIEncoderV2;

import "../Core/Core.sol";
import "./BaseEngine.sol";
import "./IEngine.sol";
import "./STF.sol";
import "./POF.sol";


/**
 * @title the stateless component for a CEG contract
 * implements the STF and POF of the Actus standard for a CEG contract
 * @dev all numbers except unix timestamp are represented as multiple of 10 ** 18
 * inputs have to be multiplied by 10 ** 18, outputs have to divided by 10 ** 18
 */
contract CEGEngine is BaseEngine, STF, POF {

    /**
     * initialize contract state space based on the contract terms
     * TODO:
     * - implement annuity calculator
     * @dev see initStateSpace()
     * @param terms terms of the contract
     * @return initial contract state
     */
    function computeInitialState(LifecycleTerms memory terms)
        public
        pure
        returns (State memory)
    {
        State memory state;

        state.contractPerformance = ContractPerformance.PF;
        state.statusDate = terms.statusDate;
        state.maturityDate = terms.maturityDate;
        state.notionalPrincipal = roleSign(terms.contractRole) * terms.notionalPrincipal;
        state.feeAccrued = terms.feeAccrued;

        return state;
    }

    /**
     * computes a schedule segment of non-cyclic contract events based on the contract terms and the specified period
     * @param terms terms of the contract
     * @param segmentStart start timestamp of the segment
     * @param segmentEnd end timestamp of the segement
     * @return event schedule segment
     */
    function computeNonCyclicScheduleSegment(
        GeneratingTerms memory terms,
        uint256 segmentStart,
        uint256 segmentEnd
    )
        public
        pure
        returns (bytes32[MAX_EVENT_SCHEDULE_SIZE] memory)
    {
        bytes32[MAX_EVENT_SCHEDULE_SIZE] memory _eventSchedule;
        uint16 index = 0;

        // purchase
        if (terms.purchaseDate != 0) {
            if (isInPeriod(terms.purchaseDate, segmentStart, segmentEnd)) {
                _eventSchedule[index] = encodeEvent(EventType.PRD, terms.purchaseDate);
                index++;
            }
        }

        // maturity event
        if (isInPeriod(terms.maturityDate, segmentStart, segmentEnd) == true) {
            _eventSchedule[index] = encodeEvent(EventType.MD, terms.maturityDate);
            index++;
        }

        return _eventSchedule;
    }

    /**
     * computes a schedule segment of cyclic contract events based on the contract terms and the specified period
     * @param terms terms of the contract
     * @param segmentStart start timestamp of the segment
     * @param segmentEnd end timestamp of the segement
     * @param eventType eventType of the cyclic schedule
     * @return event schedule segment
     */
    function computeCyclicScheduleSegment(
        GeneratingTerms memory terms,
        uint256 segmentStart,
        uint256 segmentEnd,
        EventType eventType
    )
        public
        pure
        returns (bytes32[MAX_EVENT_SCHEDULE_SIZE] memory)
    {
        bytes32[MAX_EVENT_SCHEDULE_SIZE] memory _eventSchedule;

        if (eventType == EventType.FP) {
            uint256 index = 0;

            // fees
            if (terms.cycleOfFee.isSet == true && terms.cycleAnchorDateOfFee != 0) {
                uint256[MAX_CYCLE_SIZE] memory feeSchedule = computeDatesFromCycleSegment(
                    terms.cycleAnchorDateOfFee,
                    terms.maturityDate,
                    terms.cycleOfFee,
                    true,
                    segmentStart,
                    segmentEnd
                );
                for (uint8 i = 0; i < MAX_CYCLE_SIZE; i++) {
                    if (feeSchedule[i] == 0) break;
                    if (isInPeriod(feeSchedule[i], segmentStart, segmentEnd) == false) continue;
                    _eventSchedule[index] = encodeEvent(EventType.FP, feeSchedule[i]);
                    index++;
                }
            }
        }

        return _eventSchedule;
    }

    function isEventScheduled(
        bytes32 _event,
        LifecycleTerms memory terms,
        State memory state,
        bool hasUnderlying,
        State memory underlyingState
    )
        public
        pure
        returns (bool)
    {
        (EventType eventType, uint256 scheduleTime) = decodeEvent(_event);

        if (hasUnderlying) {
            // FP, MD events only scheduled up to execution of the Guarantee
            if (
                (eventType == EventType.FP || eventType == EventType.MD)
                && underlyingState.executionAmount > int256(0)
            ) {
                return false;
            }
        }

        return true;
    }

    /**
     * computes the next contract state based on the contract terms, state and the event type
     * TODO:
     * - annuity calculator for RR/RRF events
     * - IPCB events and Icb state variable
     * - Icb state variable updates in Nac-updating events
     * @param terms terms of the contract
     * @param state current state of the contract
     * @param _event proto event for which to evaluate the next state for
     * @param externalData external data needed for POF evaluation
     * @return next contract state
     */
    function stateTransitionFunction(
        LifecycleTerms memory terms,
        State memory state,
        bytes32 _event,
        bytes32 externalData
    )
        private
        pure
        returns (State memory)
    {
        (EventType eventType, uint256 scheduleTime) = decodeEvent(_event);

        if (eventType == EventType.PRD) return STF_CEG_PRD(terms, state, scheduleTime, externalData);
        if (eventType == EventType.FP) return STF_CEG_FP(terms, state, scheduleTime, externalData);
        if (eventType == EventType.XD) return STF_CEG_XD(terms, state, scheduleTime, externalData);
        if (eventType == EventType.STD) return STF_CEG_STD(terms, state, scheduleTime, externalData);
        if (eventType == EventType.MD) return STF_CEG_MD(terms, state, scheduleTime, externalData);
        if (eventType == EventType.CE) return STF_PAM_CE(terms, state, scheduleTime, externalData);

        revert("CEGEngine.stateTransitionFunction: ATTRIBUTE_NOT_FOUND");
    }

    /**
     * calculates the payoff for the current time based on the contract terms,
     * state and the event type
     * - IPCB events and Icb state variable
     * - Icb state variable updates in IP-paying events
     * @param terms terms of the contract
     * @param state current state of the contract
     * @param _event proto event for which to evaluate the payoff for
     * @param externalData external data needed for POF evaluation
     * @return payoff
     */
    function payoffFunction(
        LifecycleTerms memory terms,
        State memory state,
        bytes32 _event,
        bytes32 externalData
    )
        private
        pure
        returns (int256)
    {
        (EventType eventType, uint256 scheduleTime) = decodeEvent(_event);

        if (eventType == EventType.CE) return 0;
        if (eventType == EventType.PRD) return POF_CEG_PRD(terms, state, scheduleTime, externalData);
        if (eventType == EventType.FP) return POF_CEG_FP(terms, state, scheduleTime, externalData);
        if (eventType == EventType.XD) return 0;
        if (eventType == EventType.STD) return POF_CEG_STD(terms, state, scheduleTime, externalData);
        if (eventType == EventType.MD) return 0;
        
        revert("CEGEngine.payoffFunction: ATTRIBUTE_NOT_FOUND");
    }
}