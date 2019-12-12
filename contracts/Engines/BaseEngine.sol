pragma solidity ^0.5.2;
pragma experimental ABIEncoderV2;

import "../Core/Core.sol";
import "./IEngine.sol";


/**
 * @title
 * @dev
 */
contract BaseEngine is Core, IEngine {

    /**
     * applys a prototype event to the current state of a contract and
     * returns the contrat event and the new contract state
     * @param terms terms of the contract
     * @param state current state of the contract
     * @param _event prototype event to be evaluated and applied to the contract state
     * @param externalData external data needed for POF evaluation
     * @return the new contract state and the evaluated event
     */
    function computeStateForEvent(
        LifecycleTerms memory terms,
        State memory state,
        bytes32 _event,
        bytes32 externalData
    )
        public
        pure
        returns (State memory)
    {
        return stateTransitionFunction(
            terms,
            state,
            _event,
            externalData
        );
    }

    /**
     * applys a prototype event to the current state of a contract and
     * returns the contrat event and the new contract state
     * @param terms terms of the contract
     * @param state current state of the contract
     * @param _event prototype event to be evaluated and applied to the contract state
     * @param externalData external data needed for POF evaluation
     * @return the new contract state and the evaluated event
     */
    function computePayoffForEvent(
        LifecycleTerms memory terms,
        State memory state,
        bytes32 _event,
        bytes32 externalData
    )
        public
        pure
        returns (int256)
    {
        // if alternative settlementCurrency is set then apply fxRate to payoff
        if (terms.settlementCurrency != address(0) && terms.currency != terms.settlementCurrency) {
            return payoffFunction(
                terms,
                state,
                _event,
                externalData
            ).floatMult(int256(externalData));
        }

        return payoffFunction(
            terms,
            state,
            _event,
            externalData
        );
    }

    /**
     * computes the next contract state based on the contract terms, state and the event type
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
        returns (State memory);

    /**
     * calculates the payoff for the current time based on the contract terms,
     * state and the event type
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
        returns (int256);
}