// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@account-abstraction/contracts/core/BasePaymaster.sol";
import "./UserAccountManager.sol";

/**
 * OwnerAccountPaymaster: Only approves if owner is calling createAccount and doesn't have a UserAccount.
 */
contract OwnerAccountPaymaster is BasePaymaster {
    UserAccountManager public accountManager;

    constructor(IEntryPoint _entryPoint, address _accountManager) BasePaymaster(_entryPoint) {
        accountManager = UserAccountManager(_accountManager);
    }

    /**
     * Validate a user operation for paymaster approval.
     * Only approve if owner is calling createAccount and doesn't have a UserAccount.
     */
    function _validatePaymasterUserOp(
        PackedUserOperation calldata userOp,
        bytes32 /* userOpHash */,
        uint256 /* maxCost */
    ) internal view override returns (bytes memory context, uint256 validationData) {
        // Only approve if owner is calling createAccount and doesn't have a UserAccount
        if (userOp.callData.length == 68) {
            // 4 bytes selector + 32 bytes entryPoint + 32 bytes owner
            bytes4 selector;
            address entryPointArg;
            address ownerArg;
            // Use abi.decode to extract selector and args
            bytes memory callData = userOp.callData;
            assembly {
                selector := mload(add(callData, 32))
            }
            if (selector == UserAccountManager.createAccount.selector) {
                // Copy callData[4:] into a new bytes array for abi.decode
                bytes memory args = new bytes(64);
                for (uint256 i = 0; i < 64; i++) {
                    args[i] = callData[i + 4];
                }
                (entryPointArg, ownerArg) = abi.decode(args, (address, address));
                if (accountManager.userAccounts(ownerArg) == address(0)) {
                    return ("", SIG_VALIDATION_SUCCESS);
                }
            }
        }
        return ("", SIG_VALIDATION_FAILED);
    }
}
