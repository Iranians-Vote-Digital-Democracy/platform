const { ethers } = require('ethers');
const provider = new ethers.JsonRpcProvider('http://127.0.0.1:8545');

async function advanceTime() {
  // Get current block timestamp
  const block = await provider.getBlock('latest');
  console.log('Current block timestamp:', block.timestamp);
  console.log('Current block time:', new Date(Number(block.timestamp) * 1000).toISOString());
  
  // Target: current real time
  const targetTimestamp = Math.floor(Date.now() / 1000);
  console.log('Target timestamp:', targetTimestamp);
  console.log('Target time:', new Date(targetTimestamp * 1000).toISOString());
  
  // Time to advance
  const timeToAdvance = targetTimestamp - Number(block.timestamp);
  console.log('Time to advance (seconds):', timeToAdvance);
  console.log('Time to advance (years):', (timeToAdvance / (365 * 24 * 3600)).toFixed(2));
  
  if (timeToAdvance <= 0) {
    console.log('Block time is already at or ahead of current time. Nothing to do.');
    return;
  }
  
  // Use evm_increaseTime to advance time
  await provider.send('evm_increaseTime', [timeToAdvance]);
  
  // Mine a new block to apply the time change
  await provider.send('evm_mine', []);
  
  // Verify
  const newBlock = await provider.getBlock('latest');
  console.log('\n✅ Time advanced!');
  console.log('New block timestamp:', newBlock.timestamp);
  console.log('New block time:', new Date(Number(newBlock.timestamp) * 1000).toISOString());
}

advanceTime().catch(console.error);
