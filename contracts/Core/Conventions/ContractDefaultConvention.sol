pragma solidity ^0.5.2;

import "../Definitions.sol";


contract ContractDefaultConvention is Definitions {

  function performanceIndicator(ContractStatus contractStatus)
		internal
		pure
		returns (int8)
	{
		if (contractStatus == ContractStatus.DF) return 0;
		return 1;
	}
}