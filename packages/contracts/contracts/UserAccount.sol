// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "@account-abstraction/contracts/core/BaseAccount.sol";
import "@account-abstraction/contracts/core/Helpers.sol";
import "@account-abstraction/contracts/accounts/callback/TokenCallbackHandler.sol";

/**
 * UserAccount: Account Abstraction contract with multiple owners and Paymaster support
 */
contract UserAccount is BaseAccount, TokenCallbackHandler, UUPSUpgradeable, Initializable {
	// Mapping for owner addresses
	mapping(address => bool) public isOwner;
	address[] public owners;

	IEntryPoint private immutable _entryPoint;

	event UserAccountInitialized(IEntryPoint indexed entryPoint, address[] owners);
	event OwnerAdded(address indexed newOwner);
	event OwnerRemoved(address indexed removedOwner);

	modifier onlyOwner() {
		require(isOwner[msg.sender] || msg.sender == address(this), "UserAccount: not owner");
		_;
	}

	/// @inheritdoc BaseAccount
	function entryPoint() public view override returns (IEntryPoint) {
		return _entryPoint;
	}

	// solhint-disable-next-line no-empty-blocks
	receive() external payable {}

	constructor(IEntryPoint anEntryPoint) {
		_entryPoint = anEntryPoint;
		_disableInitializers();
	}

	function initialize(address[] memory initialOwners) public initializer {
		require(initialOwners.length > 0, "UserAccount: at least one owner required");
		for (uint256 i = 0; i < initialOwners.length; i++) {
			address owner = initialOwners[i];
			require(owner != address(0), "UserAccount: zero address");
			require(!isOwner[owner], "UserAccount: duplicate owner");
			isOwner[owner] = true;
			owners.push(owner);
		}
		emit UserAccountInitialized(_entryPoint, owners);
	}

	// Owner management
	function addOwner(address newOwner) external onlyOwner {
		require(newOwner != address(0), "UserAccount: zero address");
		require(!isOwner[newOwner], "UserAccount: already owner");
		isOwner[newOwner] = true;
		owners.push(newOwner);
		emit OwnerAdded(newOwner);
	}

	function removeOwner(address ownerToRemove) external onlyOwner {
		require(isOwner[ownerToRemove], "UserAccount: not an owner");
		require(owners.length > 1, "UserAccount: cannot remove last owner");
		isOwner[ownerToRemove] = false;
		// Remove from owners array
		for (uint256 i = 0; i < owners.length; i++) {
			if (owners[i] == ownerToRemove) {
				owners[i] = owners[owners.length - 1];
				owners.pop();
				break;
			}
		}
		emit OwnerRemoved(ownerToRemove);
	}

	function getOwners() external view returns (address[] memory) {
		return owners;
	}

	// Require the function call went through EntryPoint or owner
	function _requireForExecute() internal view override {
		require(
			msg.sender == address(entryPoint()) || isOwner[msg.sender],
			"UserAccount: not Owner or EntryPoint"
		);
	}

	/// implement template method of BaseAccount
	function _validateSignature(PackedUserOperation calldata userOp, bytes32 userOpHash)
		internal view override returns (uint256 validationData)
	{
		// Accept if any owner signed
		for (uint256 i = 0; i < owners.length; i++) {
			if (owners[i] == ECDSA.recover(userOpHash, userOp.signature)) {
				return SIG_VALIDATION_SUCCESS;
			}
		}
		return SIG_VALIDATION_FAILED;
	}

	// Paymaster support: deposit, withdraw, etc. (same as SimpleAccount)
	function getDeposit() public view returns (uint256) {
		return entryPoint().balanceOf(address(this));
	}

	function addDeposit() public payable {
		entryPoint().depositTo{value: msg.value}(address(this));
	}

	function withdrawDepositTo(address payable withdrawAddress, uint256 amount) public onlyOwner {
		entryPoint().withdrawTo(withdrawAddress, amount);
	}

	function _authorizeUpgrade(address newImplementation) internal view override {
		require(isOwner[msg.sender], "UserAccount: not owner");
	}
}
