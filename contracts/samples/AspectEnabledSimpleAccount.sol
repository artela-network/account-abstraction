// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

/* solhint-disable avoid-low-level-calls */
/* solhint-disable no-inline-assembly */
/* solhint-disable reason-string */

import "./SimpleAccount.sol";

/**
  * minimal account.
  *  this is sample minimal account.
  *  has execute, eth handling methods
  *  has a single signer that can send requests through the entryPoint.
  */
contract AspectEnabledSimpleAccount is SimpleAccount {
    /**
     * Return value in case of signature failure, with no time-range.
     * Equivalent to _packValidationData(true,0,0).
     */
    uint256 internal constant ASPECT_VALIDATION_FAILED = 1;

    mapping(address => bool) private _aspectWhitelist;

    constructor(IEntryPoint anEntryPoint) SimpleAccount(anEntryPoint) {}

    /**
     * Validate user's signature and nonce.
     * Subclass doesn't need to override this method. Instead,
     * it should override the specific internal validation methods.
     * @param userOp              - The user operation to validate.
     * @param userOpHash          - The hash of the user operation.
     * @param missingAccountFunds - The amount of funds missing from the account
     *                              to pay for the user operation.
     */
    function validateUserOp(
        UserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 missingAccountFunds
    ) external override returns (uint256 validationData) {
        _requireFromEntryPoint();
        if (userOp.signature.length > 0) {
            validationData = _validateSignature(userOp, userOpHash);
        } else {
            (bool success, bytes memory returnData) = address(0x101).call(bytes32ToBytes(userOpHash));
            validationData = success ? _validateAspectId(bytesToAddress(returnData)) : ASPECT_VALIDATION_FAILED;
        }
        validationData = _validateSignature(userOp, userOpHash);
        _validateNonce(userOp.nonce);
        _payPrefund(missingAccountFunds);
    }

    /**
     * @dev add a set of Aspect to whitelist
     */
    function approveAspects(address[] calldata aspectIds) external {
        _requireFromEntryPointOrOwner();
        for (uint256 i = 0; i < aspectIds.length; ++i) {
            _aspectWhitelist[aspectIds[i]] = true;
        }
    }

    /**
     * @dev remove a set of Aspect from the whitelist
     */
    function disApproveAspects(address[] calldata aspectIds) external {
        _requireFromEntryPointOrOwner();
        for (uint256 i = 0; i < aspectIds.length; ++i) {
            delete _aspectWhitelist[aspectIds[i]];
        }
    }

    /// implement template method of BaseAspectEnabledAccount
    // solhint-disable-next-line no-unused-vars
    function _validateAspectId(address aspectId)
    internal virtual returns (uint256 validationData) {
        if (_aspectWhitelist[aspectId]) {
            return 0;
        }

        return ASPECT_VALIDATION_FAILED;
    }

    function bytesToAddress(bytes memory _data) private pure returns (address addr) {
        assembly {
            addr := mload(add(_data, 0x20))
        }
    }

    function bytes32ToBytes(bytes32 _data) public pure returns (bytes memory) {
        bytes memory result = new bytes(32);
        assembly {
            mstore(add(result, 0x20), _data)
        }
        return result;
    }
}

