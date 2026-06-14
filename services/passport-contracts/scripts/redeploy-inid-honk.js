// Redeploy passport + INID Honk verifiers from current artifacts and rewire
// Registration2.passportVerifiers. Use when on-chain verifier bytecode no
// longer matches the fresh artifact (Solidity setting drift) and registration
// reverts with SumcheckFailed().
const hre = require("hardhat");

const REGISTRATION2 = "0x959922bE3CAee4b8Cd9a407cc3ac1C251C2007B1";

const Z_NAMES = [
  ["Z_NOIR_PASSPORT_9_160_3_3_336_216_1_1080_3_256",
   "contracts/passport/verifiers2/noir-honk/NoirRegisterIdentity_9_160_3_3_336_216_1_1080_3_256_Honk.sol:NoirRegisterIdentity_9_160_3_3_336_216_1_1080_3_256_Honk"],
  ["Z_NOIR_PASSPORT_ID_CARD_I",
   "contracts/passport/verifiers2/noir-honk/NoirRegisterIdentity_ID_Card_I_Honk.sol:NoirRegisterIdentity_ID_Card_I_Honk"],
];

async function main() {
  const reg = await hre.ethers.getContractAt("Registration2", REGISTRATION2);
  const coder = hre.ethers.AbiCoder.defaultAbiCoder();

  for (const [name, fqcn] of Z_NAMES) {
    const z = hre.ethers.solidityPackedKeccak256(["string"], [name]);
    const current = await reg.passportVerifiers(z);
    const onCode = await hre.ethers.provider.getCode(current);
    const art = await hre.artifacts.readArtifact(fqcn);
    const onHash = hre.ethers.keccak256(onCode);
    const localHash = hre.ethers.keccak256(art.deployedBytecode);
    console.log(`\n[${name}]`);
    console.log("  current verifier:", current);
    console.log("  on-chain hash:   ", onHash);
    console.log("  artifact hash:   ", localHash);
    if (onHash === localHash) {
      console.log("  -> match, skipping");
      continue;
    }
    console.log("  -> mismatch, redeploying");
    const F = await hre.ethers.getContractFactoryFromArtifact(art);
    const v = await F.deploy();
    await v.waitForDeployment();
    const addr = await v.getAddress();
    console.log("  new verifier:    ", addr);
    // methodId 6 = RemovePassportVerifier
    await (await reg.updateDependency(6, coder.encode(["bytes32"], [z]))).wait();
    // methodId 5 = AddPassportVerifier
    await (await reg.updateDependency(5, coder.encode(["bytes32", "address"], [z, addr]))).wait();
    const after = await reg.passportVerifiers(z);
    console.log("  rewired to:      ", after);
  }
}

main().catch(e => { console.error(e); process.exit(1); });
