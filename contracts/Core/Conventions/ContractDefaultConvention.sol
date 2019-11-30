pragma solidity ^0.5.2;

import "../ACTUSTypes.sol";


contract ContractDefaultConvention is ACTUSTypes {

  function performanceIndicator(ContractPerformance contractPerformance)
		internal
		pure
		returns (int8)
	{
		if (contractPerformance == ContractPerformance.DF) return 0;
		return 1;
	}
}