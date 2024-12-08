const { ethers } = require("hardhat");

async function main() {
  const lendingPoolAddress = "0x7d2768de32b0b80b7a3454c06bdac94a69ddc7a9"; // Aave v2 mainnet
  const LiquidationArbitrage = await ethers.getContractFactory("LiquidationArbitrage");
  console.log("Deploying contract...");
  const contract = await LiquidationArbitrage.deploy(lendingPoolAddress);
  await contract.deployed();
  console.log("Deployed at:", contract.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
