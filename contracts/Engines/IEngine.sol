pragma solidity ^0.5.2;
pragma experimental ABIEncoderV2;

import "../Core/Definitions.sol";


/**
 * @title the stateless component for a PAM contract
 * implements the STF and POF of the Actus standard for a PAM contract
 * @dev all numbers except unix timestamp are represented as multiple of 10 ** 18
 * inputs have to be multiplied by 10 ** 18, outputs have to divided by 10 ** 18
 */
contract IEngine is Definitions {

	/**
	 * get the initial contract state
	 * @param contractTerms terms of the contract
	 * @return initial contract state
	 */
	function computeInitialState(ContractTerms memory contractTerms)
		public
		pure
		returns (ContractState memory);

	/**
	 * compute next state for a given ProtoEvent
	 * @param contractTerms terms of the contract
	 * @param contractState current state of the contract
	 * @param protoEvent ProtoEvent to apply to the current state of the contract
	 * @param currentTimestamp current timestamp
	 * @return next state of the contract
	 */
	function computeStateForProtoEvent(
		ContractTerms memory contractTerms,
		ContractState memory contractState,
		bytes32 protoEvent,
		uint256 currentTimestamp
	)
		public
		pure
		returns (ContractState memory);

	/**
	 * compute the payoff for a given ProtoEvent
	 * @param contractTerms terms of the contract
	 * @param contractState current state of the contract
	 * @param protoEvent ProtoEvent to compute the payoff for
	 * @param currentTimestamp current timestamp
	 * @return payoff of the given ProtoEvent
	 */
	function computePayoffForProtoEvent(
		ContractTerms memory contractTerms,
		ContractState memory contractState,
		bytes32 protoEvent,
		uint256 currentTimestamp
	)
		public
		pure
		returns (int256);

	/**
	 * computes a schedule segment of non-cyclic contract events based on the contract terms and the specified period
	 * @param contractTerms terms of the contract
	 * @param segmentStart start timestamp of the segment
	 * @param segmentEnd end timestamp of the segement
	 * @return event schedule segment
	 */
	function computeNonCyclicProtoEventScheduleSegment(
		ContractTerms memory contractTerms,
		uint256 segmentStart,
		uint256 segmentEnd
	)
		public
		pure
		returns (bytes32[MAX_EVENT_SCHEDULE_SIZE] memory);

	/**
	 * computes a schedule segment of cyclic contract events based on the contract terms and the specified period
	 * @param contractTerms terms of the contract
	 * @param segmentStart start timestamp of the segment
	 * @param segmentEnd end timestamp of the segement
	 * @param eventType eventType of the cyclic schedule
	 * @return event schedule segment
	 */
	function computeCyclicProtoEventScheduleSegment(
		ContractTerms memory contractTerms,
		uint256 segmentStart,
		uint256 segmentEnd,
		EventType eventType
	)
		public
		pure
		returns (bytes32[MAX_EVENT_SCHEDULE_SIZE] memory);

	// /**
	//  * verifies that a given ProtoEvent is (still) scheduled under the current state of the contract
	//  * @param protoEvent ProtoEvent to verify
	//  * @param contractTerms terms of the contract
	//  * @param contractState current state of the contract
	//  * @return boolean if the the ProtoEvent is still scheduled
	//  */
	// function isProtoEventScheduled(
	// 	ProtoEvent memory protoEvent,
	// 	ContractTerms memory contractTerms,
	// 	ContractState memory contractState
	// )
	// 	public
	// 	pure
	// 	returns (bool);
}
