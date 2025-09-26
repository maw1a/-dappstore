import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const entryPointAddress = "0x2aC9FFE590d7030417b3eaf3Cd0573B2d77A3cad";

export default buildModule("UserAccountModule", (m) => {
  const userAccountManager = m.contract("UserAccountManager", [
    entryPointAddress,
  ]);

  /* const ownerAccountPaymaster = m.contract("OwnerAccountPaymaster", [
    entryPointAddress,
    userAccountManager,
  ]);  */

  return { userAccountManager };
});
