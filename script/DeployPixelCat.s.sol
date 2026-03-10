// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/PixelCat.sol";

contract DeployPixelCat is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        // 部署PixelCat合约
        PixelCat pixelCat = new PixelCat();

        vm.stopBroadcast();

        console.log("PixelCat deployed at:", address(pixelCat));
        console.log("Deployer:", vm.addr(deployerPrivateKey));
        console.log("Initial supply:", pixelCat.totalSupply());
        console.log("Breeding fee:", pixelCat.breedingFee());

        // 验证部署
        require(pixelCat.totalSupply() == 2, "Initial supply should be 2");
        require(pixelCat.ownerOf(0) == vm.addr(deployerPrivateKey), "Owner should own token 0");
        require(pixelCat.ownerOf(1) == vm.addr(deployerPrivateKey), "Owner should own token 1");

        console.log("Deployment successful!");
    }
}