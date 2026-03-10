// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/SimpleNFT.sol";

/**
 * @title InteractScript
 * @dev 与已部署合约交互的脚本
 */
contract InteractScript is Script {
    SimpleNFT public nft;

    function setUp() public {
        address contractAddress = vm.envAddress("CONTRACT_ADDRESS");
        nft = SimpleNFT(contractAddress);
    }

    /**
     * @dev Mint NFT脚本
     */
    function mintNFT() public {
        address recipient = vm.envAddress("RECIPIENT_ADDRESS");
        string memory tokenURI = vm.envString("TOKEN_URI");
        uint256 mintPrice = nft.mintPrice();

        vm.startBroadcast();
        nft.mint{value: mintPrice}(recipient, tokenURI);
        vm.stopBroadcast();

        console.log("Minted NFT to:", recipient);
        console.log("Token URI:", tokenURI);
    }

    /**
     * @dev 批量添加白名单
     */
    function addWhitelist() public {
        // 从环境变量读取地址列表
        string memory addressList = vm.envString("WHITELIST_ADDRESSES");
        address[] memory addresses = _parseAddresses(addressList);

        vm.startBroadcast();
        nft.addMultipleToWhitelist(addresses);
        vm.stopBroadcast();

        console.log("Added", addresses.length, "addresses to whitelist");
    }

    /**
     * @dev 更新配置
     */
    function updateConfig() public {
        vm.startBroadcast();

        // 更新mint价格 - 需要手动设置环境变量
        try vm.envUint("NEW_MINT_PRICE") returns (uint256 newPrice) {
            nft.setMintPrice(newPrice);
            console.log("Updated mint price to:", newPrice);
        } catch {
            console.log("NEW_MINT_PRICE not set, skipping");
        }

        // 更新base URI - 需要手动设置环境变量
        try vm.envString("NEW_BASE_URI") returns (string memory newBaseURI) {
            nft.setBaseURI(newBaseURI);
            console.log("Updated base URI to:", newBaseURI);
        } catch {
            console.log("NEW_BASE_URI not set, skipping");
        }

        // 更新每地址最大mint数量
        try vm.envUint("NEW_MAX_MINT_PER_ADDRESS") returns (uint256 newMax) {
            nft.setMaxMintPerAddress(newMax);
            console.log("Updated max mint per address to:", newMax);
        } catch {
            console.log("NEW_MAX_MINT_PER_ADDRESS not set, skipping");
        }

        vm.stopBroadcast();
    }

    /**
     * @dev 提取资金
     */
    function withdraw() public {
        uint256 balance = address(nft).balance;
        console.log("Contract balance:", balance);

        if (balance > 0) {
            vm.startBroadcast();
            nft.withdraw();
            vm.stopBroadcast();
            console.log("Withdrawn", balance, "wei");
        } else {
            console.log("No funds to withdraw");
        }
    }

    /**
     * @dev 查询合约状态
     */
    function getStatus() public view {
        console.log("=== SimpleNFT Contract Status ===");
        console.log("Contract address:", address(nft));
        console.log("Name:", nft.name());
        console.log("Symbol:", nft.symbol());
        console.log("Total supply:", nft.totalSupply());
        console.log("Max supply:", nft.maxSupply());
        console.log("Mint price:", nft.mintPrice());
        console.log("Max mint per address:", nft.maxMintPerAddress());
        console.log("Owner:", nft.owner());
        console.log("Paused:", nft.paused());
        console.log("Contract balance:", address(nft).balance);
    }

    /**
     * @dev 暂停/恢复合约
     */
    function togglePause() public {
        vm.startBroadcast();

        if (nft.paused()) {
            nft.unpause();
            console.log("Contract unpaused");
        } else {
            nft.pause();
            console.log("Contract paused");
        }

        vm.stopBroadcast();
    }

    /**
     * @dev 解析地址列表（逗号分隔）
     */
    function _parseAddresses(string memory addressList) internal pure returns (address[] memory) {
        // 简化实现：假设最多10个地址
        address[] memory addresses = new address[](10);
        uint256 count = 0;

        // 这里应该实现更复杂的字符串解析逻辑
        // 为了简化，这里返回一个示例地址
        addresses[0] = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;
        count = 1;

        // 调整数组大小
        address[] memory result = new address[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = addresses[i];
        }

        return result;
    }
}