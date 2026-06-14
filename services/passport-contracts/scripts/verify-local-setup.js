#!/usr/bin/env node
/**
 * verify-local-setup.js
 * 
 * Comprehensive verification script for local development setup.
 * Run this after starting Hardhat and deploying contracts to ensure everything is ready.
 * 
 * Usage:
 *   node scripts/verify-local-setup.js
 * 
 * Last updated: January 31, 2026
 */

const { ethers } = require('ethers');
const fs = require('fs');
const path = require('path');

// Configuration
const RPC_URL = 'http://127.0.0.1:8545';
const EXPECTED_CHAIN_ID = 31337;
const MOCK_EVIDENCE_REGISTRY_ADDR = '0x781268D46a654D020922f115D75dd3D56D287812';
const EXPECTED_ICAO_ROOT = '0x490355b1c9cca56d89c180780c5ea66c1766d57cf22670c7a9a07dc18b835a4f';

// Color helpers
const colors = {
  green: (s) => `\x1b[32m${s}\x1b[0m`,
  red: (s) => `\x1b[31m${s}\x1b[0m`,
  yellow: (s) => `\x1b[33m${s}\x1b[0m`,
  cyan: (s) => `\x1b[36m${s}\x1b[0m`,
  bold: (s) => `\x1b[1m${s}\x1b[0m`,
};

const CHECK = colors.green('✅');
const CROSS = colors.red('❌');
const WARN = colors.yellow('⚠️');

async function main() {
  console.log(colors.bold('\n========================================'));
  console.log(colors.bold('  LOCAL DEVELOPMENT SETUP VERIFICATION'));
  console.log(colors.bold('========================================\n'));

  const results = {
    passed: 0,
    failed: 0,
    warnings: 0,
    fixes: [],
  };

  let provider;

  // ============================================
  // Step 1: Check Hardhat Node
  // ============================================
  console.log(colors.cyan('1. Checking Hardhat Node...\n'));

  try {
    provider = new ethers.JsonRpcProvider(RPC_URL);
    const network = await provider.getNetwork();
    const chainId = Number(network.chainId);
    
    if (chainId === EXPECTED_CHAIN_ID) {
      console.log(`   ${CHECK} Hardhat node running at ${RPC_URL}`);
      console.log(`   ${CHECK} Chain ID: ${chainId}`);
      results.passed++;
    } else {
      console.log(`   ${CROSS} Wrong chain ID: expected ${EXPECTED_CHAIN_ID}, got ${chainId}`);
      results.failed++;
    }

    const blockNumber = await provider.getBlockNumber();
    console.log(`   ${CHECK} Current block: ${blockNumber}`);
    results.passed++;

    // Check block timestamp
    const block = await provider.getBlock('latest');
    const blockTime = new Date(Number(block.timestamp) * 1000);
    const now = new Date();
    const timeDiff = Math.abs(now.getTime() - blockTime.getTime()) / 1000 / 60 / 60 / 24; // days
    
    if (timeDiff > 30) {
      console.log(`   ${WARN} Block timestamp is ${Math.floor(timeDiff)} days off from current time`);
      console.log(`      Block time: ${blockTime.toISOString()}`);
      console.log(`      Current time: ${now.toISOString()}`);
      results.warnings++;
      results.fixes.push('node scripts/advance-time.js');
    } else {
      console.log(`   ${CHECK} Block timestamp: ${blockTime.toISOString()}`);
      results.passed++;
    }

  } catch (error) {
    console.log(`   ${CROSS} Cannot connect to Hardhat node at ${RPC_URL}`);
    console.log(`      Error: ${error.message}`);
    console.log(`\n   ${colors.yellow('FIX:')} Start Hardhat with:`);
    console.log(`      cd platform/services/passport-contracts`);
    console.log(`      npx hardhat node --hostname 0.0.0.0`);
    results.failed++;
    process.exit(1);
  }

  // ============================================
  // Step 2: Check Migration Storage
  // ============================================
  console.log(colors.cyan('\n2. Checking Contract Deployments...\n'));

  const migrateStoragePath = path.join(__dirname, '../cache/.migrate.storage.json');
  let migrateStorage;
  
  try {
    migrateStorage = JSON.parse(fs.readFileSync(migrateStoragePath, 'utf8'));
    console.log(`   ${CHECK} Migration storage found`);
    results.passed++;
  } catch (error) {
    console.log(`   ${CROSS} Migration storage not found at ${migrateStoragePath}`);
    console.log(`\n   ${colors.yellow('FIX:')} Deploy contracts with:`);
    console.log(`      npx hardhat migrate --network localhost`);
    results.failed++;
    results.fixes.push('npx hardhat migrate --network localhost');
  }

  // Extract key contract addresses from migration storage
  // Storage format: { storage: {}, transactions: {...}, artifacts: {...}, verification: {...} }
  // Transactions have: { contractKeyData: { name: "..." }, contractAddress: "0x...", metadata: {...} }
  const contracts = {};
  if (migrateStorage && migrateStorage.transactions) {
    // Find contracts by searching through transactions
    for (const [txHash, txData] of Object.entries(migrateStorage.transactions)) {
      const contractName = txData?.contractKeyData?.name || '';
      const contractAddress = txData?.contractAddress;
      
      if (!contractAddress) continue;
      
      // Registration2 (proxy is what we want, named "Registration2 Proxy")
      if (contractName === 'Registration2 Proxy') {
        contracts.Registration2 = contractAddress;
      }
      else if (contractName === 'Registration2') {
        contracts.Registration2Impl = contractAddress;
      }
      // StateKeeper
      else if (contractName === 'StateKeeper Proxy') {
        contracts.StateKeeper = contractAddress;
      }
      else if (contractName === 'StateKeeper') {
        contracts.StateKeeperImpl = contractAddress;
      }
      // RegistrationSMT
      else if (contractName === 'RegistrationSMT Proxy') {
        contracts.RegistrationSMT = contractAddress;
      }
      else if (contractName === 'RegistrationSMT') {
        contracts.RegistrationSMTImpl = contractAddress;
      }
      // CertificatesSMT
      else if (contractName === 'CertificatesSMT Proxy') {
        contracts.CertificatesSMT = contractAddress;
      }
      else if (contractName === 'CertificatesSMT') {
        contracts.CertificatesSMTImpl = contractAddress;
      }
    }
    
    // Fallback: use implementation addresses if proxies not found
    if (!contracts.Registration2 && contracts.Registration2Impl) {
      contracts.Registration2 = contracts.Registration2Impl;
      console.log(`   ${WARN} Using Registration2 implementation address (no proxy found)`);
      results.warnings++;
    }
    if (!contracts.StateKeeper && contracts.StateKeeperImpl) {
      contracts.StateKeeper = contracts.StateKeeperImpl;
      console.log(`   ${WARN} Using StateKeeper implementation address (no proxy found)`);
      results.warnings++;
    }
    if (!contracts.RegistrationSMT && contracts.RegistrationSMTImpl) {
      contracts.RegistrationSMT = contracts.RegistrationSMTImpl;
      console.log(`   ${WARN} Using RegistrationSMT implementation address (no proxy found)`);
      results.warnings++;
    }
    if (!contracts.CertificatesSMT && contracts.CertificatesSMTImpl) {
      contracts.CertificatesSMT = contracts.CertificatesSMTImpl;
      console.log(`   ${WARN} Using CertificatesSMT implementation address (no proxy found)`);
      results.warnings++;
    }
  }

  // Check each required contract
  const requiredContracts = ['Registration2', 'StateKeeper', 'RegistrationSMT', 'CertificatesSMT'];
  for (const name of requiredContracts) {
    if (contracts[name]) {
      const code = await provider.getCode(contracts[name]);
      if (code.length > 2) {
        console.log(`   ${CHECK} ${name}: ${contracts[name]}`);
        results.passed++;
      } else {
        console.log(`   ${CROSS} ${name}: ${contracts[name]} (NO CODE DEPLOYED)`);
        results.failed++;
      }
    } else {
      console.log(`   ${CROSS} ${name}: not found in migration storage`);
      results.failed++;
    }
  }

  // ============================================
  // Step 3: Check MockEvidenceRegistry
  // ============================================
  console.log(colors.cyan('\n3. Checking MockEvidenceRegistry...\n'));

  const evidenceCode = await provider.getCode(MOCK_EVIDENCE_REGISTRY_ADDR);
  if (evidenceCode.length > 2) {
    console.log(`   ${CHECK} MockEvidenceRegistry deployed at ${MOCK_EVIDENCE_REGISTRY_ADDR}`);
    console.log(`      Code size: ${evidenceCode.length} chars`);
    results.passed++;
  } else {
    console.log(`   ${CROSS} MockEvidenceRegistry NOT DEPLOYED at ${MOCK_EVIDENCE_REGISTRY_ADDR}`);
    console.log(`\n   ${colors.yellow('FIX:')} Deploy mock with:`);
    console.log(`      node scripts/deploy-mock-evidence-registry.js`);
    results.failed++;
    results.fixes.push('node scripts/deploy-mock-evidence-registry.js');
  }

  // ============================================
  // Step 4: Check ICAO Root
  // ============================================
  console.log(colors.cyan('\n4. Checking ICAO Root in StateKeeper...\n'));

  if (contracts.StateKeeper) {
    try {
      const stateKeeperAbi = ['function icaoMasterTreeMerkleRoot() view returns (bytes32)'];
      const stateKeeper = new ethers.Contract(contracts.StateKeeper, stateKeeperAbi, provider);
      const icaoRoot = await stateKeeper.icaoMasterTreeMerkleRoot();
      
      if (icaoRoot === EXPECTED_ICAO_ROOT) {
        console.log(`   ${CHECK} ICAO root matches expected value`);
        console.log(`      ${icaoRoot}`);
        results.passed++;
      } else if (icaoRoot === '0x0000000000000000000000000000000000000000000000000000000000000000') {
        console.log(`   ${CROSS} ICAO root is empty (0x00...)`);
        console.log(`      Expected: ${EXPECTED_ICAO_ROOT}`);
        console.log(`\n   ${colors.yellow('FIX:')} Update ICAO root in StateKeeper`);
        results.failed++;
      } else {
        console.log(`   ${WARN} ICAO root differs from expected`);
        console.log(`      Current:  ${icaoRoot}`);
        console.log(`      Expected: ${EXPECTED_ICAO_ROOT}`);
        results.warnings++;
      }
    } catch (error) {
      console.log(`   ${CROSS} Cannot read ICAO root: ${error.message}`);
      results.failed++;
    }
  } else {
    console.log(`   ${WARN} Skipping ICAO check - StateKeeper not found`);
    results.warnings++;
  }

  // ============================================
  // Step 5: Check Dispatchers
  // ============================================
  console.log(colors.cyan('\n5. Checking Certificate Dispatchers...\n'));

  if (contracts.Registration2) {
    try {
      const registrationAbi = ['function certificateDispatchers(bytes32) view returns (address)'];
      const registration = new ethers.Contract(contracts.Registration2, registrationAbi, provider);
      
      const dispatchers = [
        { name: 'C_RSA_2048', typeHash: ethers.keccak256(ethers.toUtf8Bytes('C_RSA_2048')) },
        { name: 'C_RSA_4096', typeHash: ethers.keccak256(ethers.toUtf8Bytes('C_RSA_4096')) },
        { name: 'C_RSA_SHA1_2688', typeHash: ethers.keccak256(ethers.toUtf8Bytes('C_RSA_SHA1_2688')) },
      ];

      for (const d of dispatchers) {
        const addr = await registration.certificateDispatchers(d.typeHash);
        if (addr !== ethers.ZeroAddress) {
          console.log(`   ${CHECK} ${d.name}: ${addr}`);
          results.passed++;
        } else {
          console.log(`   ${WARN} ${d.name}: not registered`);
          results.warnings++;
        }
      }
    } catch (error) {
      console.log(`   ${CROSS} Cannot check dispatchers: ${error.message}`);
      results.failed++;
    }
  } else {
    console.log(`   ${WARN} Skipping dispatcher check - Registration2 not found`);
    results.warnings++;
  }

  // ============================================
  // Step 6: Check Docker Services
  // ============================================
  console.log(colors.cyan('\n6. Checking Docker Services...\n'));

  const { execSync } = require('child_process');
  try {
    const dockerPs = execSync('docker ps --format "{{.Names}}"', { encoding: 'utf8' });
    const runningContainers = dockerPs.split('\n').filter(Boolean);
    
    const requiredServices = ['registration-relayer', 'postgres'];
    for (const service of requiredServices) {
      const found = runningContainers.some(c => c.includes(service));
      if (found) {
        console.log(`   ${CHECK} ${service} is running`);
        results.passed++;
      } else {
        console.log(`   ${WARN} ${service} is not running`);
        results.warnings++;
        results.fixes.push(`docker-compose up -d ${service}`);
      }
    }
  } catch (error) {
    console.log(`   ${WARN} Cannot check Docker: ${error.message}`);
    results.warnings++;
  }

  // ============================================
  // Summary
  // ============================================
  console.log(colors.bold('\n========================================'));
  console.log(colors.bold('  SUMMARY'));
  console.log(colors.bold('========================================\n'));

  console.log(`   ${CHECK} Passed:   ${results.passed}`);
  console.log(`   ${WARN} Warnings: ${results.warnings}`);
  console.log(`   ${CROSS} Failed:   ${results.failed}`);

  if (results.fixes.length > 0) {
    console.log(colors.yellow('\n   Suggested fixes:\n'));
    for (const fix of results.fixes) {
      console.log(`      ${fix}`);
    }
  }

  if (results.failed === 0 && results.warnings === 0) {
    console.log(colors.green('\n   🎉 All checks passed! Ready for testing.\n'));
    process.exit(0);
  } else if (results.failed === 0) {
    console.log(colors.yellow('\n   ⚠️  Setup complete with warnings. May work but check issues above.\n'));
  } else {
    console.log(colors.red('\n   ❌ Setup incomplete. Fix the issues above before testing.\n'));
    process.exit(1);
  }

  // ============================================
  // Print .env.local Template
  // ============================================
  if (contracts.Registration2 || contracts.StateKeeper) {
    console.log(colors.bold('\n========================================'));
    console.log(colors.bold('  .ENV.LOCAL TEMPLATE'));
    console.log(colors.bold('========================================'));
    console.log(colors.cyan('\nCopy these addresses to iranians.vote/.env.local:\n'));
    console.log(`# Identity Registration Contracts`);
    console.log(`EXPO_PUBLIC_REGISTRATION_CONTRACT_ADDRESS=${contracts.Registration2 || '0x_NOT_FOUND'}`);
    console.log(`EXPO_PUBLIC_STATE_KEEPER_CONTRACT_ADDRESS=${contracts.StateKeeper || '0x_NOT_FOUND'}`);
    console.log(`EXPO_PUBLIC_CERT_POSEIDON_SMT_CONTRACT_ADDRESS=${contracts.CertificatesSMT || '0x_NOT_FOUND'}`);
    console.log(`EXPO_PUBLIC_REGISTRATION_POSEIDON_SMT_CONTRACT_ADDRESS=${contracts.RegistrationSMT || '0x_NOT_FOUND'}`);
    console.log(`\n# Also add (from passport-voting-contracts deploy):`);
    console.log(`# EXPO_PUBLIC_NOIR_ID_VOTING_CONTRACT=0x...`);
    console.log(`# EXPO_PUBLIC_PROPOSAL_STATE_CONTRACT_ADDRESS=0x...`);
    console.log('');
  }
}

main().catch(console.error);
