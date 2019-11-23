pragma solidity ^0.5.2;
pragma experimental ABIEncoderV2;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/drafts/SignedSafeMath.sol";

import "../Core/Core.sol";
import "../Core/SignedMath.sol";
import "./IEngine.sol";
import "./STF.sol";
import "./POF.sol";


/**
 * @title the stateless component for a CEC contract
 * implements the STF and POF of the Actus standard for a CEC contract
 * @dev all numbers except unix timestamp are represented as multiple of 10 ** 18
 * inputs have to be multiplied by 10 ** 18, outputs have to divided by 10 ** 18
 */
contract CECEngine is Core, IEngine, STF, POF {

	using SafeMath for uint;
	using SignedSafeMath for int;
	using SignedMath for int;


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
	 * applys a prototype event to the current state of a contract and
	 * returns the contrat event and the new contract state
	 * @param terms terms of the contract
	 * @param state current state of the contract
	 * @param _event prototype event to be evaluated and applied to the contract state
	 * @param currentTimestamp current timestamp
	 * @return the new contract state and the evaluated event
	 */
	function computeStateForEvent(
		LifecycleTerms memory terms,
		State memory state,
		bytes32 _event,
		uint256 currentTimestamp
	)
		public
		pure
		returns (State memory)
	{
		return stateTransitionFunction(
			_event,
			state,
			terms,
			currentTimestamp
		);
	}

	/**
	 * applys a prototype event to the current state of a contract and
	 * returns the contrat event and the new contract state
	 * @param terms terms of the contract
	 * @param state current state of the contract
	 * @param _event prototype event to be evaluated and applied to the contract state
	 * @param currentTimestamp current timestamp
	 * @return the new contract state and the evaluated event
	 */
	function computePayoffForEvent(
		LifecycleTerms memory terms,
		State memory state,
		bytes32 _event,
		uint256 currentTimestamp
	)
		public
		pure
		returns (int256)
	{
		return payoffFunction(
			_event,
			state,
			terms,
			currentTimestamp
		);
	}

	/**
	 * computes a schedule segment of non-cyclic contract events based on the contract terms and the specified period
	 * @param terms terms of the contract
	 * @param segmentStart start timestamp of the segment
	 * @param segmentEnd end timestamp of the segement
	 * @return event schedule segment
	 */
	function computeNonCylicEventScheduleSegment(
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
		return true;
	}

	/**
	 * computes the next contract state based on the contract terms, state and the event type
	 * TODO:
	 * - annuity calculator for RR/RRF events
	 * - IPCB events and Icb state variable
	 * - Icb state variable updates in Nac-updating events
	 * @param _event proto event for which to evaluate the next state for
	 * @param state current state of the contract
	 * @param terms terms of the contract
	 * @param currentTimestamp current timestamp
	 * @return next contract state
	 */
	function stateTransitionFunction(
		bytes32 _event,
		State memory state,
		LifecycleTerms memory terms,
		uint256 currentTimestamp
	)
		private
		pure
		returns (State memory)
	{
		(EventType eventType, uint256 scheduleTime) = decodeEvent(_event);

		if (eventType == EventType.PRD) return STF_CEG_PRD(scheduleTime, terms, state, currentTimestamp);
		if (eventType == EventType.FP) return STF_CEG_FP(scheduleTime, terms, state, currentTimestamp);
		if (eventType == EventType.XD) return STF_CEG_XD(scheduleTime, terms, state, currentTimestamp);
		if (eventType == EventType.MD) return STF_CEG_MD(scheduleTime, terms, state, currentTimestamp);
		if (eventType == EventType.CE) return STF_PAM_DEL(scheduleTime, terms, state, currentTimestamp);

		revert("CEGEngine.stateTransitionFunction: ATTRIBUTE_NOT_FOUND");
	}

	/**
	 * calculates the payoff for the current time based on the contract terms,
	 * state and the event type
	 * - IPCB events and Icb state variable
	 * - Icb state variable updates in IP-paying events
	 * @param _event proto event for which to evaluate the payoff for
	 * @param state current state of the contract
	 * @param terms terms of the contract
	 * @param currentTimestamp current timestamp
	 * @return payoff
	 */
	function payoffFunction(
		bytes32 _event,
		State memory state,
		LifecycleTerms memory terms,
		uint256 currentTimestamp
	)
		private
		pure
		returns (int256)
	{
		(EventType eventType, uint256 scheduleTime) = decodeEvent(_event);

		if (eventType == EventType.CE) return 0;
		if (eventType == EventType.PRD) return POF_CEG_PRD(scheduleTime, terms, state, currentTimestamp);
		if (eventType == EventType.FP) return POF_CEG_FP(scheduleTime, terms, state, currentTimestamp);
		if (eventType == EventType.XD) return POF_CEG_XD(scheduleTime, terms, state, currentTimestamp);
		if (eventType == EventType.MD) return POF_CEG_MD(scheduleTime, terms, state, currentTimestamp);

		revert("CEGEngine.payoffFunction: ATTRIBUTE_NOT_FOUND");
	}
}