# Local INID Voting Setup (IDCardVoting + Keccak UltraHonk)

One-shot guide to deploy IDCardVoting and create a votable INID proposal on local Hardhat.

## Prerequisites

- Hardhat node running: `npx hardhat node --hostname 0.0.0.0` (in `passport-contracts/`)
- `passport-contracts` already deployed: `npx hardhat migrate --network localhost`
- Docker services running: `docker-compose up -d postgres proof-verification-relayer nginx`

## Step 1: Deploy Voting Stack (fresh)

```bash
cd platform/services/passport-voting-contracts

# Clear old migration state and redeploy base voting stack
echo '{}' > cache/.migrate.storage.json
npx hardhat migrate --network localhost
```

This outputs new addresses for **ProposalsState** and **BioPassportVoting**.
Note the **ProposalsState** proxy address from the output table.

## Step 2: Update deploy script with fresh ProposalsState

Edit `scripts/deploy-idcard-voting-keccak-local.js`:

```js
const PROPOSALS_STATE_PROXY = "<NEW_PROPOSALS_STATE_ADDRESS>";
const REGISTRATION_SMT = "0x5FC8d32690cc91D4c39d9d3abcBD16989F875707"; // stable across passport-contracts deploys
```

## Step 3: Deploy IDCardVoting with Keccak Verifier

```bash
npx hardhat run scripts/deploy-idcard-voting-keccak-local.js --network localhost
```

Expected output:
```
✅ IDCardVoting registered in ProposalsState as 'IDCardVoting'
IDCardVoting Proxy: 0x...
```

Note the **IDCardVoting Proxy** address.

## Step 4: Create INID Proposal

Save as `/tmp/create-inid-proposal.js`:

```js
async function main() {
  const PS = "<PROPOSALS_STATE_ADDRESS>";
  const IDV = "<IDCARD_VOTING_PROXY_ADDRESS>";
  const ps = await ethers.getContractAt("ProposalsState", PS);

  const ZERO_DATE = BigInt("0x303030303030"); // 52983525027888
  const IR = BigInt(18770); // 0x4952
  const block = await ethers.provider.getBlock("latest");
  const now = BigInt(block.timestamp);

  const whitelist = ethers.AbiCoder.defaultAbiCoder().encode(
    ["tuple(uint256,uint256[],uint256,uint256,uint256,uint256,uint256,uint256)"],
    [[
      BigInt(65569),       // selector 0x10021 (bits 0,5,16)
      [IR],                // allowed citizenships
      now + BigInt(604800),// identityCreationTimestampUpperBound (1 week)
      BigInt(10),          // identityCounterUpperBound
      BigInt(0),           // sex (0 = any)
      ZERO_DATE,           // birthDateLowerbound
      ZERO_DATE,           // birthDateUpperbound
      ZERO_DATE,           // expirationDateLowerBound
    ]]
  );

  const tx = await ps.createProposal({
    startTimestamp: now - BigInt(60),  // already started
    duration: BigInt(604800),          // 1 week
    multichoice: BigInt(0),
    acceptedOptions: [BigInt(7)],      // 0b111 = 3 choices (Yes/No/Abstain)
    description: "ipfs://QmINIDLocalTest",
    votingWhitelist: [IDV],
    votingWhitelistData: [whitelist],
  }, { value: ethers.parseEther("0.1") });

  await tx.wait();
  const id = await ps.lastProposalId();
  console.log("✅ Proposal ID:", id.toString());
}
main();
```

Run:
```bash
npx hardhat run /tmp/create-inid-proposal.js --network localhost
```

## Step 5: Fund Proposal in Relayer DB

```bash
docker exec rarimo-postgres psql -U rarimo -d proof_verification -c "
INSERT INTO voting_contract_accounts
  (voting_id, residual_balance, gas_limit, creator_address,
   parsed_whitelist_data_with_metadata, total_balance,
   min_age, max_age, start_timestamp, end_timestamp, votes_count)
VALUES
  (<PROPOSAL_ID>, 10000000000000000000, 5000000,
   '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266',
   '{\"metadata\":{\"title\":\"INID Test\",\"imageCid\":\"\",\"description\":\"Local INID voting test\",\"acceptedOptions\":null},\"parsed_voting_whitelist_data\":null}',
   10000000000000000000, 0, 0, 0, 0, 0);"
```

## Step 6: Update Relayer Config

Edit `platform/configs/proof-verification-relayer.yaml`:
```yaml
voting_v2:
  proposal_state_address: "<NEW_PROPOSALS_STATE_ADDRESS>"
```

Restart:
```bash
docker restart proof-verification-relayer
```

## Step 7: Update Wallet

Edit `jomhoor-wallet/.env.local`:
```env
EXPO_PUBLIC_NOIR_ID_VOTING_CONTRACT=<IDCARD_VOTING_PROXY_ADDRESS>
EXPO_PUBLIC_PROPOSAL_STATE_CONTRACT_ADDRESS=<NEW_PROPOSALS_STATE_ADDRESS>
```

Rebuild:
```bash
cd jomhoor-wallet && APP_ENV=local npx expo run:ios --device
```

## Quick Reference: INID Proposal Parameters

| Parameter | Value | Notes |
|-----------|-------|-------|
| Selector | 65569 (0x10021) | Bits 0,5,16 |
| ZERO_DATE | 52983525027888 (0x303030303030) | All date bounds must be this |
| acceptedOptions | [7] | 0b111 = 3 options. Use [3] for 2 only |
| Citizenship | 18770 (0x4952 = "IR") | 2-letter ISO → uint16 |
| Entry point | `executeINID` | NOT `executeNoir` |
| Circuit | `queryIdentity_inid_ca` | 23 public signals |

## Troubleshooting

| Error | Fix |
|-------|-----|
| `duplicate voting` in step 3 | IDCardVoting name already taken from prev deploy. Either clear migration (step 1) or change the name in the script |
| `require(false)` on createProposal | Usually stale ProposalsState address. Verify the proxy has `proposalSMTImpl()` set |
| `Insufficient funds` from relayer | Step 5 not done, or wrong `voting_id` |
| Proposal not visible in app | Rebuild app (env vars are compile-time) |
| `PAIRING_FAILED` on vote | See `docs/INID_REGISTRATION_DEEP_DIVE.md` — check selector, ZERO_DATE bounds, 4-field INIDUserData |
| `InvalidDate` on vote | Run `node platform/services/passport-contracts/scripts/advance-time.js` |

## Contract Addresses (June 14, 2026 deploy)

| Contract | Address |
|----------|---------|
| ProposalsState | `0xb4e9A5BC64DC07f890367F72941403EEd7faDCbB` |
| IDCardVoting Proxy | `0x4653251486a57f90Ee89F9f34E098b9218659b83` |
| NoirINIDQueryHonkVerifier | `0x969E3128DB078b179E9F3b3679710d2443cCDB72` |
| INID Proposal ID | 3 |
