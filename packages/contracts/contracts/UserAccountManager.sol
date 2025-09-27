// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./UserAccount.sol";

/**
 * UserAccountManager: Manages creation and lookup of UserAccount contracts for owner wallets.
 */
contract UserAccountManager {
    // Mapping from owner address to UserAccount contract address
    mapping(address => address) public userAccounts;
    // List of all UserAccount contracts
    address[] public allAccounts;

    IEntryPoint private immutable entryPoint;

    event UserAccountCreated(address indexed owner, address account);

    constructor(address anEntryPoint) {
        entryPoint = IEntryPoint(anEntryPoint);
    }

    /**
     * Create a new UserAccount for the given owner wallet.
     * @param owner The owner wallet address
     * @return account The address of the created UserAccount
     */
    function createAccount(address owner) external returns (address account) {
        require(
            userAccounts[owner] == address(0),
            "UserAccountManager: account already exists for owner"
        );
        address[] memory owners = new address[](1);
        owners[0] = owner;
        UserAccount newAccount = new UserAccount(IEntryPoint(entryPoint));
        newAccount.initialize(owners);
        account = address(newAccount);
        userAccounts[owner] = account;
        allAccounts.push(account);
        emit UserAccountCreated(owner, account);
    }

    /**
     * Get the UserAccount contract address for a given owner wallet.
     * @param owner The owner wallet address
     * @return account The UserAccount contract address
     */
    function getAccount(address owner) external view returns (address account) {
        account = userAccounts[owner];
    }

    /**
     * Get all UserAccount contract addresses managed by this contract.
     */
    function getAllAccounts() external view returns (address[] memory) {
        return allAccounts;
    }
}
