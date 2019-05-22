pragma solidity ^0.5.2;


library FloatMath {

	int256 constant private INT256_MIN = -2 ** 255;

	uint256 constant public PRECISION = 18;
	uint256 constant public MULTIPLICATOR = 10 ** PRECISION;

	/**
	 * @dev The product of self and b has to be less than INT256_MAX (~10 ** 76),
	 * as devision (normalization) is performed after multiplication
	 * Upper boundary would be (10 ** 58) * (MULTIPLICATOR) == ~10 ** 76
	 */
	function floatMult(int256 self, int256 b)
		public
		pure
		returns (int256)
	{
		if (self == 0 || b == 0) { return 0; }

		require(!(self == -1 && b == INT256_MIN), "FloatMath.floatMult: OVERFLOW_DETECTED");
		int256 c = self * b;
		require(c / self == b, "FloatMath.floatMult: OVERFLOW_DETECTED");

		// normalize (divide by MULTIPLICATOR)
		int256 d = c / int256(MULTIPLICATOR);
		require(d != 0, "FloatMath.floatMult: CANNOT_REPRESENT_GRANULARITY");

		return d;
	}

	function floatDiv(int256 self, int256 b)
		public
		pure
		returns (int256)
	{
		require(b != 0, "FloatMath.floatDiv: DIVIDEDBY_ZERO");

		// normalize (multiply by MULTIPLICATOR)
		if (self == 0) { return 0; }
		int256 c = self * int256(MULTIPLICATOR);
		require(c / self == int256(MULTIPLICATOR), "FloatMath.floatDiv: OVERFLOW_DETECTED");

		require(!(b == -1 && self == INT256_MIN), "FloatMATH.floatDiv: OVERFLOW_DETECTED");
		int256 d = c / b;
		require(d != 0, "FloatMath.floatDiv: CANNOT_REPRESENT_GRANULARITY");

		return d;
	}
}