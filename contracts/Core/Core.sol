pragma solidity ^0.5.2;
pragma experimental ABIEncoderV2;

import "./ACTUSTypes.sol";
import "./Utils.sol";
import "./Schedule.sol";

import "./Conventions/BusinessDayConvention.sol";
import "./Conventions/ContractDefaultConvention.sol";
import "./Conventions/ContractRoleConvention.sol";
import "./Conventions/DayCountConvention.sol";
import "./Conventions/EndOfMonthConvention.sol";


contract Core is
	ACTUSTypes,
	BusinessDayConvention,
	ContractDefaultConvention,
	ContractRoleConvention,
	DayCountConvention,
	EndOfMonthConvention,
	Utils,
	Schedule
{}
