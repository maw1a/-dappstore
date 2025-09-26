import { network } from "hardhat";
import { OwnerAccountPaymaster } from "./constants.js";

const { ethers } = await network.connect({
  network: "dev",
});

// TODO: CHANGE ADDRESS
const address = OwnerAccountPaymaster;

if (!ethers.isAddress(address)) {
  console.error("Invalid Ethereum address");
  process.exit(1);
}

try {
  const balance = await ethers.provider.getBalance(address);
  console.log(`Balance of ${address}:`);
  console.log(`${ethers.formatEther(balance)} ETH`);
  console.log(`${balance.toString()} Wei`);
} catch (error) {
  console.error("Error fetching balance:", error);
  process.exit(1);
}
