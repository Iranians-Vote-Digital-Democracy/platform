/**
 * Diff helper: compares the public signals the BioPassportVoting contract
 * computes (via getPublicSignals) against the public signals embedded in the
 * Noir proof itself.
 *
 * Usage:
 *   1. Reproduce the failing vote in the wallet. The submitVote logger will
 *      print:  [BioPassportSubmitVote] executeNoir args: {...}
 *   2. Save that JSON to platform/services/passport-voting-contracts/scripts/last-vote.json
 *   3. npx hardhat run scripts/diff-public-signals.ts --network localhost
 */

import { ethers } from "hardhat";
import * as fs from "fs";
import * as path from "path";

const VOTING_ADDRESS = "0x6DcBc91229d812910b54dF91b5c2b592572CD6B0";

const SIGNAL_NAMES = [
  "0  nullifier",
  "1  birthDate",
  "2  expirationDate",
  "3  name",
  "4  nameResidual",
  "5  nationality",
  "6  citizenship",
  "7  sex",
  "8  documentNumber",
  "9  eventId",
  "10 eventData",
  "11 idStateRoot",
  "12 selector",
  "13 currentDate",
  "14 timestampLowerbound",
  "15 timestampUpperbound",
  "16 identityCounterLowerbound",
  "17 identityCounterUpperbound",
  "18 birthDateLowerbound",
  "19 birthDateUpperbound",
  "20 expirationDateLowerbound",
  "21 expirationDateUpperbound",
  "22 (reserved)",
];

async function main() {
  const dumpPath = path.join(__dirname, "last-vote.json");
  if (!fs.existsSync(dumpPath)) {
    throw new Error(
      `Missing ${dumpPath}. Capture the wallet's [BioPassportSubmitVote] log and write it there.`,
    );
  }

  const dump = JSON.parse(fs.readFileSync(dumpPath, "utf8")) as {
    registrationRoot: string;
    currentDate: string;
    userPayload: string;
    proof: string;
    pub_signals: string[];
  };

  const abi = [
    "function getPublicSignals(bytes32,uint256,bytes) view returns (bytes32[])",
  ];
  const voting = new ethers.Contract(VOTING_ADDRESS, abi, ethers.provider);

  let expected: string[];
  try {
    expected = await voting.getPublicSignals(
      dump.registrationRoot,
      dump.currentDate,
      dump.userPayload,
    );
  } catch (e: any) {
    console.error("getPublicSignals reverted:", e.shortMessage ?? e.message);
    console.error(
      "(InvalidRegistrationRoot or InvalidDate from PublicSignalsBuilder is the most likely cause.)",
    );
    process.exit(1);
  }

  const actual = dump.pub_signals.map(s =>
    "0x" + BigInt("0x" + s).toString(16).padStart(64, "0"),
  );

  const norm = (s: string) =>
    "0x" + BigInt(s).toString(16).padStart(64, "0").toLowerCase();

  console.log("=== Public signal diff ===");
  console.log(`contract = ${VOTING_ADDRESS}`);
  console.log(`signals: ${expected.length} (expected) vs ${actual.length} (proof)`);
  console.log("");

  const len = Math.max(expected.length, actual.length);
  let mismatches = 0;
  for (let i = 0; i < len; i++) {
    const e = expected[i] ? norm(expected[i]) : "<missing>";
    const a = actual[i] ? norm(actual[i]) : "<missing>";
    const tag = e === a ? "    " : "DIFF";
    if (e !== a) mismatches++;
    const label = SIGNAL_NAMES[i] ?? `${i}`;
    console.log(`[${tag}] ${label.padEnd(28)} expected=${e}`);
    console.log(`         ${" ".repeat(28)} actual  =${a}`);
  }
  console.log("");
  console.log(`mismatches: ${mismatches}`);
  if (mismatches === 0) {
    console.log("Signals match — the revert is NOT a public-signal mismatch.");
    console.log("Investigate: verifier vk version, proof byte format, or registrationRoot validity.");
  }
}

main().catch(e => {
  console.error(e);
  process.exit(1);
});
