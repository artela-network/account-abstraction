// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

/* solhint-disable avoid-low-level-calls */
/* solhint-disable no-empty-blocks */

import "./BaseAccount.sol";
import "../interfaces/IAspectEnabledAccount.sol";

/**
 * Basic account implementation.
 * this contract provides the basic logic for implementing the IAccount interface  - validateUserOp
 * specific account implementation should inherit it and provide the account-specific logic
 */
abstract contract BaseAspectEnabledAccount is BaseAccount, IAspectEnabledAccount {
    // return value in case of aspect failure, with no time-range.
    // equivalent to _packValidationData(true,0,0);
    uint256 constant internal ASPECT_VALIDATION_FAILED = 2;

    /**
     * Validate aspect id and user's nonce.
     * subclass doesn't need to override this method. Instead, it should override the specific internal validation methods.
     */
    function validateAspectUserOp(UserOperation calldata userOp, address aspectId, uint256 missingAccountFunds)
    external override virtual returns (uint256 validationData) {
        _requireFromEntryPoint();
        validationData = _validateAspectId(userOp, aspectId);
        _validateNonce(userOp.nonce);
        _payPrefund(missingAccountFunds);
    }

    /**
     * validate the signature is valid for this message.
     * @param userOp validate the userOp.signature field
     * @param aspectId convenient field: the id of the aspect, to check the aspect id is allowed
     * @return validationData signature and time-range of this operation
     *      <20-byte> sigAuthorizer - 0 for valid signature, 1 to mark signature failure,
     *         otherwise, an address of an "authorizer" contract.
     *      <6-byte> validUntil - last timestamp this operation is valid. 0 for "indefinite"
     *      <6-byte> validAfter - first timestamp this operation is valid
     *      If the account doesn't use time-range, it is enough to return SIG_VALIDATION_FAILED value (1) for signature failure.
     *      Note that the validation code cannot use block.timestamp (or block.number) directly.
     */
    function _validateAspectId(UserOperation calldata userOp, address aspectId)
    internal virtual returns (uint256 validationData);
}
