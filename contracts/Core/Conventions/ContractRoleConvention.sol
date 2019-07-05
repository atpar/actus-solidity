pragma solidity ^0.5.2;

import "../Definitions.sol";


contract ContractRoleConvention is Definitions {

  function roleSign(ContractRole contractRole)
		internal
		pure
		returns (int8)
	{
		if (contractRole == ContractRole.RPA) return 1;
		if (contractRole == ContractRole.RPL) return -1;
		revert("ContractRoleConvention.roleSign: ATTRIBUTE_NOT_FOUND");
	}
}