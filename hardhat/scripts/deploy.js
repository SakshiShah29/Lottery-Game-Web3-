const {ethers}=require("hardhat");
require("dotenv").config({path:".env"});
const {FEE,VRF_COORDINATOR,LINK_TOKEN,KEY_HASH}=require("../constants");

async function main(){
  const randonWinnerGame=await ethers.getContractFactory("RandomWinnerGame");
  //deploy the contract
  const deployedRandomWinnerGameContract=await randonWinnerGame.deploy(VRF_COORDINATOR,LINK_TOKEN,KEY_HASH,FEE);
  await deployedRandomWinnerGameContract.deployed();

  //printing the address of the deployed contract
  console.log(
    "Verify Contract Address:",deployedRandomWinnerGameContract.address
  );

  console.log("Sleeping..");
  //Wait foe etherscan to noticethat the contract is deployed
  await sleep(30000);

  // Verify the contract after deploying
  await hre.run("verify:verify", {
    address: deployedRandomWinnerGameContract.address,
    constructorArguments: [VRF_COORDINATOR, LINK_TOKEN, KEY_HASH, FEE],
  });
}

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

main()
  .then(()=>process.exit(0))
  .catch((error)=>{
    console.log(error);
    process.exit(1);
  });
