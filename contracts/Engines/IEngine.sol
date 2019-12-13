pragma solidity ^0.5.2;
pragma experimental ABIEncoderV2;

import "../Core/ACTUSTypes.sol";


/**
 * @title IEngine
 * @notice Interface which all Engines have to implement
 */
contract IEngine is ACTUSTypes {

    /**
     * get the initial contract state
     * @param terms terms of the contract
     * @return initial contract state
     */
    function computeInitialState(LifecycleTerms memory terms)
        public
        pure
        returns (State memory);

    /**
     * compute next state for a given event
     * @param terms terms of the contract
     * @param state current state of the contract
     * @param _event event to apply to the current state of the contract
     * @param externalData external data needed for STF evaluation
     * @return next state of the contract
     */
    function computeStateForEvent(
        LifecycleTerms memory terms,
        State memory state,
        bytes32 _event,
        bytes32 externalData
    )
        public
        pure
        returns (State memory);

    /**
     * compute the payoff for a given event
     * @param terms terms of the contract
     * @param state current state of the contract
     * @param _event event to compute the payoff for
     * @param externalData external data needed for POF evaluation
     * @return payoff of the given event
     */
    function computePayoffForEvent(
        LifecycleTerms memory terms,
        State memory state,
        bytes32 _event,
        bytes32 externalData
    )
        public
        pure
        returns (int256);

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
        returns (bytes32[MAX_EVENT_SCHEDULE_SIZE] memory);

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
        returns (bytes32[MAX_EVENT_SCHEDULE_SIZE] memory);

    /**
     * verifies that a given event is (still) scheduled under the current state of the contract
     * @param _event event to verify
     * @param terms terms of the contract
     * @param state current state of the contract
     * @return boolean if the the event is still scheduled
     */
    function isEventScheduled(
        bytes32 _event,
        LifecycleTerms memory terms,
        State memory state,
        bool hasUnderlying,
        State memory underlyingState
    )
        public
        pure
        returns (bool);
}
