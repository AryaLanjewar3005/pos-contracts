pragma solidity ^0.5.2;

interface ValidatorSet {
	/// Get initial validator set
	function getInitialValidators()
		external
		view
		returns (address[] memory, uint256[] memory);

	/// Get current validator set (last enacted or initial if no changes ever made) with current stake.
	function getValidators()
		external
		view
		returns (address[] memory, uint256[] memory);

	// validate validator set
  function validateValidatorSet(
    bytes calldata vote,
    bytes calldata sigs,
    bytes calldata txBytes,
    bytes calldata proof
  ) external;

	// Commit span
	function commitSpan(
		bytes calldata vote,
		bytes calldata sigs,
		bytes calldata txBytes,
		bytes calldata proof
	) external;
}
