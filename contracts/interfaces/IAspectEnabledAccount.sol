// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import "./UserOperation.sol";

interface IAspectEnabledAccount {
    /**
     * Validate whether the aspect id is allowed in this wallet and nonce
     * the entryPoint will make the call to the recipient only if this validation call returns successfully.
     * aspect id verification failure should be reported by returning ASPECT_NOT_ALLOWED (9).
     * This allows making a "simulation call" without a valid aspect id
     * Other failures (e.g. nonce mismatch) should still revert to signal failure.
     *
     * @dev Must validate caller is the entryPoint.
     *      Must validate the aspect id and nonce
     * @param userOp the operation that is about to be executed.
     * @param aspectId id of the requested aspect id.
     * @param missingAccountFunds missing funds on the account's deposit in the entrypoint.
     *      This is the minimum amount to transfer to the sender(entryPoint) to be able to make the call.
     *      The excess is left as a deposit in the entrypoint, for future calls.
     *      can be withdrawn anytime using "entryPoint.withdrawTo()"
     *      In case there is a paymaster in the request (or the current deposit is high enough), this value will be zero.
     * @return validationData packaged ValidationData structure. use `_packValidationData` and `_unpackValidationData` to encode and decode
     *      <20-byte> sigAuthorizer - 0 for valid signature, 1 to mark signature failure,
     *         otherwise, an address of an "authorizer" contract.
     *      <6-byte> validUntil - last timestamp this operation is valid. 0 for "indefinite"
     *      <6-byte> validAfter - first timestamp this operation is valid
     *      If an account doesn't use time-range, it is enough to return ASPECT_NOT_ALLOWED value (9) for aspect failure.
     *      Note that the validation code cannot use block.timestamp (or block.number) directly.
     */
    function validateAspectUserOp(UserOperation calldata userOp, address aspectId, uint256 missingAccountFunds)
    external returns (uint256 validationData);
}
