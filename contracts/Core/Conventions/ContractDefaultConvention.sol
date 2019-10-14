pragma solidity ^0.5.2;

import "../Definitions.sol";


contract ContractDefaultConvention is Definitions {

  function performanceIndicator(ContractPerformance contractPerformance)
		internal
		pure
		returns (int8)
	{
		if (contractPerformance == ContractPerformance.DF) return 0;
		return 1;
	}
}