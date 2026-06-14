const { ethers } = require('ethers');
const fs = require('fs');
const path = require('path');

async function deploy() {
  const p = new ethers.JsonRpcProvider('http://127.0.0.1:8545');
  const signer = new ethers.Wallet('0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80', p);
  console.log('Deployer:', signer.address);
  
  // Compile the MockEvidenceRegistry first
  console.log('\nCompiling contracts...');
  const { execSync } = require('child_process');
  execSync('npx hardhat compile', { cwd: __dirname + '/..', stdio: 'inherit' });
  
  // Get the compiled artifact
  const artifactPath = path.join(__dirname, '../artifacts/contracts/mock/MockEvidenceRegistry.sol/MockEvidenceRegistry.json');
  const artifact = JSON.parse(fs.readFileSync(artifactPath, 'utf8'));
  
  console.log('\nDeploying MockEvidenceRegistry...');
  const factory = new ethers.ContractFactory(artifact.abi, artifact.bytecode, signer);
  const mockEvReg = await factory.deploy();
  await mockEvReg.waitForDeployment();
  const mockAddr = await mockEvReg.getAddress();
  console.log('MockEvidenceRegistry deployed at:', mockAddr);
  
  // Now we need to update the SMTs to use the new evidence registry
  // But they're proxies and the evidenceRegistry is immutable in init...
  // We need to check if there's a way to update it
  
  // Actually, looking at the init function, evidenceRegistry is just a storage variable
  // We might need to redeploy the proxies or find another way
  
  // For now, let's just deploy a mock at the expected address using Hardhat's setCode
  const expectedAddr = '0x781268D46a654D020922f115D75dd3D56D287812';
  console.log('\nSetting code at expected address:', expectedAddr);
  
  // Get the deployed bytecode
  const deployedBytecode = await p.getCode(mockAddr);
  
  // Use hardhat_setCode to put the contract at the expected address
  await p.send('hardhat_setCode', [expectedAddr, deployedBytecode]);
  
  // Verify
  const codeAtExpected = await p.getCode(expectedAddr);
  console.log('Code at expected address:', codeAtExpected.length, 'chars');
  
  console.log('\n✅ MockEvidenceRegistry deployed at expected address');
  console.log('Now retry the registerCertificate call');
}

deploy().catch(console.error);
