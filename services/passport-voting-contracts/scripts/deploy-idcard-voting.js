const { ethers } = require("hardhat");

// 238 two-letter country codes as uint256 values, in exact order matching the INID circuit
// Each value = char1*256 + char2 (e.g., "IR" = 73*256 + 82 = 18770)
// Source: iranians.vote/src/utils/citizenship-mask.ts INID_COUNTRY_CODES
const INID_COUNTRY_CODES = [
  16727, 16710, 16719, 16713, 16716, 16708, 16718, 16709, 16722, 16717, 16723, 16721, 16711, 16725,
  16724, 16730, 16969, 16965, 16970, 16966, 16964, 16967, 16968, 16979, 16961, 16972, 16985, 16986,
  16973, 16975, 16978, 16962, 16974, 16980, 16983, 17222, 17217, 17219, 17224, 17228, 17230, 17225,
  17229, 17220, 17223, 17227, 17231, 19277, 17238, 17234, 17237, 17239, 17240, 19289, 17241, 17242,
  17477, 17482, 17485, 17483, 17487, 17498, 17731, 17735, 17746, 17736, 17747, 17733, 17748, 17993,
  17994, 17995, 18002, 17999, 17997, 18241, 18242, 18245, 18247, 18248, 18249, 18254, 18253, 18263,
  18257, 18258, 18244, 18252, 18260, 18261, 18265, 18507, 18510, 18514, 18516, 18517, 18756, 18765,
  18766, 18767, 18757, 18770, 18769, 18771, 18764, 18772, 19021, 19013, 19023, 19024, 19290, 19269,
  19271, 19272, 19273, 19278, 19282, 19287, 19521, 19522, 19538, 19545, 19523, 19529, 19531, 19539,
  19540, 19541, 19791, 19782, 19777, 19779, 19780, 19783, 19798, 19800, 19784, 19787, 19788, 19796,
  19789, 19781, 19790, 19792, 19802, 19794, 19795, 19797, 19799, 19801, 22868, 20033, 20035, 20037,
  20039, 20041, 20053, 20044, 20047, 20048, 20050, 20058, 20301, 20555, 20545, 20558, 20549, 20552,
  20567, 20551, 20556, 20562, 19280, 20564, 20569, 20563, 20801, 21061, 21071, 21077, 21079, 21313,
  21316, 21326, 21319, 21320, 21322, 21314, 21324, 21334, 21325, 21327, 20557, 21075, 21331, 21332,
  21330, 21323, 21321, 21317, 21338, 21336, 21315, 21337, 21571, 21572, 21575, 21576, 21578, 21579,
  21581, 21580, 21583, 21588, 21582, 21586, 21590, 21591, 21594, 21831, 21825, 21849, 21843, 21850,
  22081, 22083, 22085, 22087, 22089, 22094, 22101, 22342, 22355, 22603, 22853, 23105, 23117, 23127,
];

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying with:", deployer.address);

  // *** CURRENT DEPLOYMENT ADDRESSES (Jun 2026 deploy) ***
  const registrationSMT = process.env.REGISTRATION_SMT || "0x5FC8d32690cc91D4c39d9d3abcBD16989F875707";
  const PROPOSALS_STATE = process.env.PROPOSALS_STATE || "0x021DBfF4A864Aa25c51F0ad2Cd73266Fde66199d";

  // Verify ProposalsState has code
  const psCode = await ethers.provider.getCode(PROPOSALS_STATE);
  if (psCode === "0x") throw new Error("ProposalsState has no code!");
  console.log("✅ ProposalsState exists at", PROPOSALS_STATE);

  // 1. Deploy the Honk verifier for the INID query circuit. Must be the Honk
  // variant (NoirINIDQueryHonkVerifier) — the older UltraPlonk verifier
  // (NoirTD1Verifier_ID_Card_I) has the wrong interface for AQueryProofExecutor.
  console.log("\n1. Deploying NoirINIDQueryHonkVerifier...");
  const VerifierFactory = await ethers.getContractFactory("NoirINIDQueryHonkVerifier");
  const verifier = await VerifierFactory.deploy();
  await verifier.waitForDeployment();
  const verifierAddr = await verifier.getAddress();
  console.log("   NoirINIDQueryHonkVerifier:", verifierAddr);

  // 2. Deploy IDCardVoting implementation
  console.log("\n2. Deploying IDCardVoting implementation...");
  const IDCardVotingFactory = await ethers.getContractFactory("IDCardVoting");
  const impl = await IDCardVotingFactory.deploy();
  await impl.waitForDeployment();
  const implAddr = await impl.getAddress();
  console.log("   IDCardVoting impl:", implAddr);

  // 3. Deploy ERC1967 Proxy
  console.log("\n3. Deploying ERC1967Proxy for IDCardVoting...");
  const initData = IDCardVotingFactory.interface.encodeFunctionData(
    "__IDCardVoting_init",
    [registrationSMT, PROPOSALS_STATE, verifierAddr]
  );
  const ProxyFactory = await ethers.getContractFactory("ERC1967Proxy");
  const proxy = await ProxyFactory.deploy(implAddr, initData);
  await proxy.waitForDeployment();
  const proxyAddr = await proxy.getAddress();
  console.log("   IDCardVoting Proxy:", proxyAddr);

  // 4. Initialize the lookup table
  console.log("\n4. Initializing lookup table with 238 country codes...");
  const idCardVoting = IDCardVotingFactory.attach(proxyAddr);
  const countryCodes = INID_COUNTRY_CODES.map(code => BigInt(code));
  const tx = await idCardVoting.initializeLookupTable(countryCodes);
  await tx.wait();
  console.log("   Lookup table initialized!");
  
  // Verify IR (18770) is at expected index 101
  const irIndex = await idCardVoting.countryCodeToBitIndex(18770n);
  console.log(`   IR (18770) -> bit index: ${irIndex} (expected: 101) ${irIndex.toString() === "101" ? "✅" : "❌"}`);

  // 5. Register IDCardVoting in ProposalsState
  console.log("\n5. Registering IDCardVoting in ProposalsState...");
  const ps = await ethers.getContractAt(
    ["function addVoting(string,address) external", "function proposalCount() view returns (uint256)"],
    PROPOSALS_STATE
  );
  const addTx = await ps.addVoting("IDCardVoting", proxyAddr);
  await addTx.wait();
  console.log("   Registered as 'IDCardVoting' ✅");

  console.log("\n========== DEPLOYMENT SUMMARY ==========");
  console.log("NoirINIDQueryHonkVerifier:", verifierAddr);
  console.log("IDCardVoting (impl):      ", implAddr);
  console.log("IDCardVoting (proxy):     ", proxyAddr);
  console.log("ProposalsState:           ", PROPOSALS_STATE);
  console.log("RegistrationSMT:          ", registrationSMT);
  console.log("Lookup table:              ✅ (238 codes, IR@101)");
  console.log("=========================================");
  console.log("\nNext steps to make this address usable for INID voting:");
  console.log(`  1. In Jomhoor-wallet/.env.local set:`);
  console.log(`       EXPO_PUBLIC_NOIR_ID_VOTING_CONTRACT=${proxyAddr}`);
  console.log(`  2. In scripts/create-test-proposals.js set:`);
  console.log(`       const ID_CARD_VOTING_ADDRESS = "${proxyAddr}";`);
  console.log(`  3. Re-run create-test-proposals.js — it creates INID proposals`);
  console.log(`     with the correct ZERO_DATE encoding the INID circuit expects.`);
  console.log(`  4. Fund the new INID proposal IDs in voting_contract_accounts.`);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
