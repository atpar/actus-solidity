pragma solidity ^0.5.2;
pragma experimental ABIEncoderV2;

import "../Engines/POF.sol";

/**
* These helper contracts expose internal functions for unit testing.
*/
contract TestPOF is POF {
    function _POF_PAM_FP (
        LifecycleTerms memory terms,
        State memory state,
        uint256 scheduleTime,
        bytes32 externalData
    )
    public
    pure
    returns(int256) {
        return POF_PAM_FP(
            terms,
            state,
            scheduleTime,
            externalData
        );
    }

    function _POF_PAM_IED (
        LifecycleTerms memory terms,
        State memory state,
        uint256 scheduleTime,
        bytes32 externalData
    )
    public
    pure
    returns(int256)
    {
        return POF_PAM_IED(
            terms,
            state,
            scheduleTime,
            externalData
        );
    }

    function _POF_PAM_IP (
        LifecycleTerms memory terms,
        State memory state,
        uint256 scheduleTime,
        bytes32 externalData
    )
    public
    pure
    returns(int256)
    {
        return POF_PAM_IP(
            terms,
            state,
            scheduleTime,
            externalData
        );
    }

    function _POF_PAM_PP (
        LifecycleTerms memory terms,
        State memory state,
        uint256 scheduleTime,
        bytes32 externalData
    )
    public
    pure
    returns(int256)
    {
        return POF_PAM_PP(
            terms,
            state,
            scheduleTime,
            externalData
        );
    }

    function _POF_PAM_PRD (
        LifecycleTerms memory terms,
        State memory state,
        uint256 scheduleTime,
        bytes32 externalData
    )
    public
    pure
    returns(int256)
    {
        return POF_PAM_PRD(
            terms,
            state,
            scheduleTime,
            externalData
        );
    }

    function _POF_PAM_PR (
        LifecycleTerms memory terms,
        State memory state,
        uint256 scheduleTime,
        bytes32 externalData
    )
    public
    pure
    returns(int256)
    {
        return POF_PAM_PR(
            terms,
            state,
            scheduleTime,
            externalData
        );
    }
}