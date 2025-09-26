import { network } from "hardhat";
import { Account0, OwnerAccountPaymaster } from "./constants.js";

const { ethers, provider } = await network.connect({
  network: "dev",
});

console.log("Sending transaction using the dev chain");

const sender = new ethers.Wallet(Account0.privateKey, new ethers.BrowserProvider(provider))

console.log(
  "Funding 50 eth from sender:",
  sender.address,
  "to OwnerAccountPaymaster:",
  OwnerAccountPaymaster
);

try {
	console.log("Sending transaction");
		const tx = await sender.sendTransaction({
	  to: OwnerAccountPaymaster,
	  value: ethers.parseEther("50"),
	});
	console.log("Transaction hash:", tx.hash, "Waiting for confirmation...");
	await tx.wait();
} catch (error) {
	console.error("Error funding OwnerAccountPaymaster:", error);
  process.exit(1);
}

console.log("Transaction sent successfully");
