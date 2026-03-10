// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/PixelCat.sol";

contract SimpleDeployPixelCat is Script {
    function run() external {
        vm.startBroadcast();

        // 部署PixelCat合约
        PixelCat pixelCat = new PixelCat();

        vm.stopBroadcast();

        console.log("PixelCat deployed at:", address(pixelCat));
        console.log("Total supply:", pixelCat.totalSupply());
        console.log("Breeding fee:", pixelCat.breedingFee());
    }
}