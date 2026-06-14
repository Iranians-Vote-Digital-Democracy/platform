/**
 * Create Test Proposals for Local Development
 * 
 * This script creates sample proposals for testing the voting flow locally.
 * 
 * Usage:
 *   cd platform/services/passport-voting-contracts
 *   npx hardhat run scripts/create-test-proposals.js --network localhost
 */

const { ethers } = require("hardhat");

// Local deployment addresses from current migration output.
// These are deterministic for the current local workflow, but still verify code at runtime below.
const PROPOSALS_STATE_ADDRESS = "0x021DBfF4A864Aa25c51F0ad2Cd73266Fde66199d";
const BIO_PASSPORT_VOTING_ADDRESS = "0x6DcBc91229d812910b54dF91b5c2b592572CD6B0";
// IDCardVoting (deployed via scripts/deploy-idcard-voting.js). Empty string
// disables INID proposal creation.
const ID_CARD_VOTING_ADDRESS = "0x46d4674578a2daBbD0CEAB0500c6c7867999db34";

// Citizenship codes - use the appropriate length for the document type!
// TD3 passports use 3-letter ISO codes (e.g., "IRN", "DEU")
// INID cards use 2-letter ISO codes (e.g., "IR", "DE")
function encodeCountry(code) {
  // Convert country code to uint256 (ASCII bytes)
  const bytes = Buffer.from(code, 'utf8');
  return BigInt('0x' + bytes.toString('hex'));
}

// 3-letter codes for TD3 passports (BioPassportVoting)
const IRAN_TD3 = encodeCountry('IRN');     // 0x49524e = 4805198
const GERMANY_TD3 = encodeCountry('DEU');
const USA_TD3 = encodeCountry('USA');

// 2-letter codes for INID cards (NoirIDVoting)
const IRAN_INID = encodeCountry('IR');     // 0x4952 = 18770
const GERMANY_INID = encodeCountry('DE');

const ALL_COUNTRIES = 0n; // Empty whitelist = all countries allowed

// Backwards compatibility aliases
const IRAN = IRAN_TD3;
const GERMANY = GERMANY_TD3;
const USA = USA_TD3;

/**
 * IMPORTANT: Per Rarimo circuit documentation, date bounds that are NOT used
 * MUST be set to 0x303030303030 (UTF-8 encoding of "000000"), NOT numeric 0.
 * Using numeric 0 will cause circuit constraint violations.
 * See: https://github.com/rarimo/passport-zk-circuits#query-circuit-inputs
 */
const ZERO_DATE = BigInt('0x303030303030'); // = 52983525027888 in decimal = "000000" in UTF-8

/**
 * QUERY SELECTOR BITS (from Noir circuit documentation)
 * 
 * The selector is a bitmask where bit N controls whether field N is revealed in the proof output.
 * If bit is 1, the field will be revealed; otherwise it will be zero.
 * 
 * Bit positions (from query_identity_td1 circuit):
 *   0 - nullifier
 *   1 - birth date
 *   2 - expiration date
 *   3 - name
 *   4 - nationality
 *   5 - citizenship      <- REQUIRED for citizenship whitelist check!
 *   6 - sex
 *   7 - document number hash
 *   8 - timestamp lowerbound
 *   9 - timestamp upperbound
 *   10 - identity counter lowerbound
 *   11 - identity counter upperbound
 *   12 - passport expiration lowerbound
 *   13 - passport expiration upperbound
 *   14 - birth date lowerbound
 *   15 - birth date upperbound
 *   16 - personal number hash
 *   17 - doc type
 * 
 * Common selector values:
 *   0 = no fields revealed (citizenship will be 0 in proof output!)
 *   32 = 2^5 = citizenship revealed (bit 5 set) - REQUIRED for citizenship checks!
 * 
 * See: https://github.com/rarimo/passport-zk-circuits-noir/blob/main/query_identity_td1/Readme.md
 */
const SELECTOR_CITIZENSHIP_WHITELIST = 32n; // 2^5 = bit 5 = reveal citizenship (passport)
// INID circuit (queryIdentity_inid_ca) requires bit 16 (pers_number + citizenship_check)
// in addition to bit 5. Without bit 16 the wallet passes citizenship_mask=0 while
// IDCardVoting._buildPublicSignalsTD1 always derives the mask from the whitelist,
// causing a public-signals mismatch and tx revert (estimateGas fail).
// 65569 = 0x10021 = bit 0 (nullifier) + bit 5 (citizenship) + bit 16 (pers_number + citizenship_check)
const SELECTOR_INID = 65569n;

async function main() {
  console.log("Creating test proposals for local development...\n");

  const [deployer] = await ethers.getSigners();
  console.log("Deployer address:", deployer.address);
  console.log("Deployer balance:", ethers.formatEther(await ethers.provider.getBalance(deployer.address)), "ETH\n");

  // Sanity-check that expected contracts are actually deployed at these addresses.
  const checks = [
    ["ProposalsState", PROPOSALS_STATE_ADDRESS],
    ["BioPassportVoting", BIO_PASSPORT_VOTING_ADDRESS],
  ];
  if (ID_CARD_VOTING_ADDRESS) checks.push(["IDCardVoting", ID_CARD_VOTING_ADDRESS]);
  for (const [name, addr] of checks) {
    const code = await ethers.provider.getCode(addr);
    if (code === "0x") {
      throw new Error(`${name} has no code at ${addr}. Re-run voting migrations.`);
    }
  }

  // Get contract instances
  const proposalsState = await ethers.getContractAt("ProposalsState", PROPOSALS_STATE_ADDRESS);
  
  // Check minimum funding amount
  const minFunding = await proposalsState.minFundingAmount();
  console.log("Minimum funding amount:", ethers.formatEther(minFunding), "ETH");
  
  // If minFunding is too high, set it to 0 for testing
  if (minFunding > ethers.parseEther("0.01")) {
    console.log("Setting minimum funding to 0 for testing...");
    await proposalsState.setMinFundingAmount(0);
  }

  const block = await ethers.provider.getBlock("latest");
  const now = Number(block.timestamp);
  const oneDay = 86400;
  const oneWeek = oneDay * 7;

  // ProposalConfig struct:
  // {
  //   startTimestamp: uint64,
  //   duration: uint64,
  //   multichoice: uint256,
  //   acceptedOptions: uint256[],
  //   description: string,
  //   votingWhitelist: address[],
  //   votingWhitelistData: bytes[]
  // }

  // ProposalRules struct (encoded in votingWhitelistData):
  // {
  //   selector: uint256,
  //   citizenshipWhitelist: uint256[],
  //   identityCreationTimestampUpperBound: uint256,
  //   identityCounterUpperBound: uint256,
  //   sex: uint256,
  //   birthDateLowerbound: uint256,
  //   birthDateUpperbound: uint256,
  //   expirationDateLowerBound: uint256
  // }

  // Create ProposalRules. Pass selector explicitly: 32 for passport, 65569 for INID.
  const createProposalRules = (citizenshipWhitelist, selector = SELECTOR_CITIZENSHIP_WHITELIST) => {
    return ethers.AbiCoder.defaultAbiCoder().encode(
      ["tuple(uint256,uint256[],uint256,uint256,uint256,uint256,uint256,uint256)"],
      [[
        selector, // 32 = passport, 65569 = INID
        citizenshipWhitelist, // citizenshipWhitelist
        now + oneWeek, // identityCreationTimestampUpperBound
        100, // identityCounterUpperBound
        0, // sex (0 = any)
        ZERO_DATE, // birthDateLowerbound - MUST use "000000" format, not numeric 0
        ZERO_DATE, // birthDateUpperbound - MUST use "000000" format, not numeric 0
        ZERO_DATE, // expirationDateLowerBound - MUST use "000000" format, not numeric 0
      ]]
    );
  };

  // =====================================
  // Proposal 1: Iranian Referendum (Iran only)
  // =====================================
  console.log("\n📋 Creating Proposal 1: Iranian Referendum...");
  
  const proposal1Config = {
    startTimestamp: now - 60, // Started 1 minute ago
    duration: oneWeek,
    multichoice: 0, // Single choice only
    acceptedOptions: [3], // 0b11 = 2 choices (Yes/No)
    description: "ipfs://QmProposal1IranianReferendum", // Would be actual IPFS hash
    votingWhitelist: [BIO_PASSPORT_VOTING_ADDRESS],
    votingWhitelistData: [createProposalRules([IRAN])],
  };

  try {
    const tx1 = await proposalsState.createProposal(proposal1Config, { value: minFunding });
    await tx1.wait();
    const proposalId1 = await proposalsState.lastProposalId();
    console.log("✅ Proposal 1 created! ID:", proposalId1.toString());
  } catch (e) {
    console.log("❌ Error creating Proposal 1:", e.message);
  }

  // =====================================
  // Proposal 2: Global Climate Survey (All countries)
  // =====================================
  console.log("\n📋 Creating Proposal 2: Global Climate Survey...");
  
  const proposal2Config = {
    startTimestamp: now - 60,
    duration: oneDay * 30, // 30 days
    multichoice: 0,
    acceptedOptions: [7], // 0b111 = 3 choices (Yes/No/Abstain)
    description: "ipfs://QmProposal2GlobalClimateSurvey",
    votingWhitelist: [BIO_PASSPORT_VOTING_ADDRESS],
    votingWhitelistData: [createProposalRules([])], // Empty = all countries
  };

  try {
    const tx2 = await proposalsState.createProposal(proposal2Config, { value: minFunding });
    await tx2.wait();
    const proposalId2 = await proposalsState.lastProposalId();
    console.log("✅ Proposal 2 created! ID:", proposalId2.toString());
  } catch (e) {
    console.log("❌ Error creating Proposal 2:", e.message);
  }

  // =====================================
  // Proposal 3: Iran + Germany (Multi-country)
  // =====================================
  console.log("\n📋 Creating Proposal 3: Iran & Germany Joint Survey...");
  
  const proposal3Config = {
    startTimestamp: now - 60,
    duration: oneWeek * 2, // 2 weeks
    multichoice: 1, // Multi-choice allowed for option 0
    acceptedOptions: [15, 3], // Option 0: 4 choices (multichoice), Option 1: 2 choices
    description: "ipfs://QmProposal3IranGermanyJoint",
    votingWhitelist: [BIO_PASSPORT_VOTING_ADDRESS],
    votingWhitelistData: [createProposalRules([IRAN, GERMANY])],
  };

  try {
    const tx3 = await proposalsState.createProposal(proposal3Config, { value: minFunding });
    await tx3.wait();
    const proposalId3 = await proposalsState.lastProposalId();
    console.log("✅ Proposal 3 created! ID:", proposalId3.toString());
  } catch (e) {
    console.log("❌ Error creating Proposal 3:", e.message);
  }

  // =====================================
  // Proposal 4: Future Proposal (not started yet)
  // =====================================
  console.log("\n📋 Creating Proposal 4: Future Referendum (starts tomorrow)...");
  
  const proposal4Config = {
    startTimestamp: now + oneDay, // Starts tomorrow
    duration: oneWeek,
    multichoice: 0,
    acceptedOptions: [3],
    description: "ipfs://QmProposal4FutureReferendum",
    votingWhitelist: [BIO_PASSPORT_VOTING_ADDRESS],
    votingWhitelistData: [createProposalRules([IRAN])],
  };

  try {
    const tx4 = await proposalsState.createProposal(proposal4Config, { value: minFunding });
    await tx4.wait();
    const proposalId4 = await proposalsState.lastProposalId();
    console.log("✅ Proposal 4 created! ID:", proposalId4.toString());
  } catch (e) {
    console.log("❌ Error creating Proposal 4:", e.message);
  }

  // =====================================
  // NOIR ID VOTING PROPOSALS (for INID cards)
  // IMPORTANT: INID cards use 2-letter country codes, not 3-letter!
  // =====================================
  if (ID_CARD_VOTING_ADDRESS) {
  console.log("\n\n🎯 Creating NoirIDVoting Proposals (for INID cards)...\n");
  console.log("📝 Note: INID uses 2-letter codes ('IR' = " + IRAN_INID.toString() + "), not 3-letter ('IRN' = " + IRAN_TD3.toString() + ")\n");

  // =====================================
  // NoirID Proposal 1: Iran Freedom Vote (INID holders only)
  // =====================================
  console.log("📋 Creating NoirID Proposal 1: Iran Freedom Vote...");
  
  const noirProposal1Config = {
    startTimestamp: now - 60, // Started 1 minute ago
    duration: oneWeek,
    multichoice: 0,
    acceptedOptions: [3], // Yes/No
    description: "ipfs://QmNoirProposal1_IranFreedomVote_Test",
    votingWhitelist: [ID_CARD_VOTING_ADDRESS],
    votingWhitelistData: [createProposalRules([IRAN_INID], SELECTOR_INID)], // Use 2-letter code!
  };

  try {
    const tx5 = await proposalsState.createProposal(noirProposal1Config, { value: minFunding });
    await tx5.wait();
    const proposalId5 = await proposalsState.lastProposalId();
    console.log("✅ NoirID Proposal 1 created! ID:", proposalId5.toString());
  } catch (e) {
    console.log("❌ Error creating NoirID Proposal 1:", e.message);
  }

  // =====================================
  // NoirID Proposal 2: Feature Priority Poll
  // =====================================
  console.log("\n📋 Creating NoirID Proposal 2: Feature Priority Poll...");
  
  const noirProposal2Config = {
    startTimestamp: now - 60,
    duration: oneDay * 14, // 14 days
    multichoice: 0,
    acceptedOptions: [15], // 4 choices (0b1111)
    description: "ipfs://QmNoirProposal2_FeaturePriority_Test",
    votingWhitelist: [ID_CARD_VOTING_ADDRESS],
    votingWhitelistData: [createProposalRules([IRAN_INID], SELECTOR_INID)], // Use 2-letter code!
  };

  try {
    const tx6 = await proposalsState.createProposal(noirProposal2Config, { value: minFunding });
    await tx6.wait();
    const proposalId6 = await proposalsState.lastProposalId();
    console.log("✅ NoirID Proposal 2 created! ID:", proposalId6.toString());
  } catch (e) {
    console.log("❌ Error creating NoirID Proposal 2:", e.message);
  }

  // =====================================
  // NoirID Proposal 3: Global Demo (all countries)
  // =====================================
  console.log("\n📋 Creating NoirID Proposal 3: Global Democracy Demo...");
  
  const noirProposal3Config = {
    startTimestamp: now - 60,
    duration: oneDay * 3, // 3 days
    multichoice: 0,
    acceptedOptions: [7], // 3 choices
    description: "ipfs://QmNoirProposal3_GlobalDemoTest",
    votingWhitelist: [ID_CARD_VOTING_ADDRESS],
    votingWhitelistData: [createProposalRules([], SELECTOR_INID)], // All countries
  };

  try {
    const tx7 = await proposalsState.createProposal(noirProposal3Config, { value: minFunding });
    await tx7.wait();
    const proposalId7 = await proposalsState.lastProposalId();
    console.log("✅ NoirID Proposal 3 created! ID:", proposalId7.toString());
  } catch (e) {
    console.log("❌ Error creating NoirID Proposal 3:", e.message);
  }
  } // end if (ID_CARD_VOTING_ADDRESS)

  // =====================================
  // Summary
  // =====================================
  console.log("\n========================================");
  console.log("📊 Summary of Created Proposals:");
  console.log("========================================");
  
  const totalProposals = await proposalsState.lastProposalId();
  console.log("Total proposals:", totalProposals.toString());
  
  for (let i = 1n; i <= totalProposals; i++) {
    try {
      const info = await proposalsState.getProposalInfo(i);
      const status = ["None", "Waiting", "Started", "Ended", "DoNotShow"][Number(info.status)];
      console.log(`\nProposal ${i}:`);
      console.log(`  Status: ${status}`);
      console.log(`  SMT: ${info.proposalSMT}`);
      console.log(`  Description: ${info.config.description}`);
      console.log(`  Options: ${info.config.acceptedOptions.length}`);
      console.log(`  Start: ${new Date(Number(info.config.startTimestamp) * 1000).toISOString()}`);
      console.log(`  Duration: ${Number(info.config.duration) / 86400} days`);
    } catch (e) {
      console.log(`Proposal ${i}: Error fetching info - ${e.message}`);
    }
  }

  console.log("\n✅ Done! Test proposals created successfully.");
  console.log("\nNow rebuild the app to see the proposals:");
  console.log("  cd iranians.vote && APP_ENV=local npx expo run:ios --device");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
