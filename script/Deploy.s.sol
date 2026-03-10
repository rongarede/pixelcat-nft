// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/SimpleNFT.sol";

/**
 * @title DeployScript
 * @dev 部署脚本：支持多环境部署和配置
 */
contract DeployScript is Script {
    // 部署配置
    struct DeployConfig {
        string name;
        string symbol;
        uint256 maxSupply;
        uint256 mintPrice;
        uint256 maxMintPerAddress;
        string baseURI;
        address owner;
    }

    // 网络配置映射
    mapping(string => DeployConfig) public configs;

    // 部署的合约地址
    SimpleNFT public deployedNFT;

    function setUp() public {
        // 本地开发环境配置
        configs["local"] = DeployConfig({
            name: "Local SimpleNFT",
            symbol: "LSNFT",
            maxSupply: 1000,
            mintPrice: 0.01 ether,
            maxMintPerAddress: 10,
            baseURI: "https://localhost:3000/api/metadata/",
            owner: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 // Default Anvil address
        });

        // Sepolia测试网配置
        configs["sepolia"] = DeployConfig({
            name: "SimpleNFT Testnet",
            symbol: "SNFT-T",
            maxSupply: 10000,
            mintPrice: 0.001 ether,
            maxMintPerAddress: 5,
            baseURI: "https://api-sepolia.example.com/metadata/",
            owner: vm.envAddress("DEPLOYER_ADDRESS")
        });

        // 主网配置
        configs["mainnet"] = DeployConfig({
            name: "SimpleNFT",
            symbol: "SNFT",
            maxSupply: 10000,
            mintPrice: 0.1 ether,
            maxMintPerAddress: 3,
            baseURI: "https://api.example.com/metadata/",
            owner: vm.envAddress("DEPLOYER_ADDRESS")
        });

        // Polygon配置
        configs["polygon"] = DeployConfig({
            name: "SimpleNFT Polygon",
            symbol: "SNFT-P",
            maxSupply: 50000,
            mintPrice: 50 ether, // 50 MATIC
            maxMintPerAddress: 20,
            baseURI: "https://api-polygon.example.com/metadata/",
            owner: vm.envAddress("DEPLOYER_ADDRESS")
        });
    }

    /**
     * @dev 主要的部署函数
     */
    function run() public {
        string memory network = vm.envOr("NETWORK", string("local"));
        DeployConfig memory config = configs[network];

        require(bytes(config.name).length > 0, "Invalid network configuration");

        console.log("Deploying to network:", network);
        console.log("Contract name:", config.name);
        console.log("Symbol:", config.symbol);
        console.log("Max supply:", config.maxSupply);
        console.log("Mint price:", config.mintPrice);
        console.log("Owner:", config.owner);

        // 开始部署
        vm.startBroadcast();

        deployedNFT = new SimpleNFT(
            config.name,
            config.symbol,
            config.maxSupply,
            config.mintPrice,
            config.maxMintPerAddress,
            config.baseURI
        );

        // 如果指定了owner且不是部署者，则转移所有权
        if (config.owner != msg.sender && config.owner != address(0)) {
            deployedNFT.transferOwnership(config.owner);
            console.log("Ownership transferred to:", config.owner);
        }

        vm.stopBroadcast();

        // 记录部署信息
        console.log("SimpleNFT deployed at:", address(deployedNFT));

        // 保存部署信息到文件
        _saveDeploymentInfo(network, address(deployedNFT), config);

        // 验证部署
        _verifyDeployment(config);
    }

    /**
     * @dev 仅部署合约，不进行额外配置
     */
    function runSimpleDeploy() public {
        string memory network = vm.envOr("NETWORK", string("local"));
        DeployConfig memory config = configs[network];

        vm.startBroadcast();

        deployedNFT = new SimpleNFT(
            config.name,
            config.symbol,
            config.maxSupply,
            config.mintPrice,
            config.maxMintPerAddress,
            config.baseURI
        );

        vm.stopBroadcast();

        console.log("SimpleNFT deployed at:", address(deployedNFT));
    }

    /**
     * @dev 部署并进行初始配置
     */
    function runWithInitialSetup() public {
        run();

        // 初始配置
        address[] memory initialWhitelist = _getInitialWhitelist();

        if (initialWhitelist.length > 0) {
            vm.startBroadcast();
            deployedNFT.addMultipleToWhitelist(initialWhitelist);
            vm.stopBroadcast();

            console.log("Added", initialWhitelist.length, "addresses to whitelist");
        }

        // 预mint一些NFT给团队（如果需要）
        _preMintForTeam();
    }

    /**
     * @dev 验证部署是否成功
     */
    function _verifyDeployment(DeployConfig memory config) internal view {
        require(address(deployedNFT) != address(0), "Deployment failed");
        require(keccak256(bytes(deployedNFT.name())) == keccak256(bytes(config.name)), "Name mismatch");
        require(keccak256(bytes(deployedNFT.symbol())) == keccak256(bytes(config.symbol)), "Symbol mismatch");
        require(deployedNFT.maxSupply() == config.maxSupply, "Max supply mismatch");
        require(deployedNFT.mintPrice() == config.mintPrice, "Mint price mismatch");
        require(deployedNFT.maxMintPerAddress() == config.maxMintPerAddress, "Max mint per address mismatch");

        console.log("Deployment verification passed");
    }

    /**
     * @dev 保存部署信息到JSON文件
     */
    function _saveDeploymentInfo(string memory network, address contractAddress, DeployConfig memory config) internal {
        string memory json = "deploymentInfo";

        vm.serializeString(json, "network", network);
        vm.serializeAddress(json, "contractAddress", contractAddress);
        vm.serializeString(json, "name", config.name);
        vm.serializeString(json, "symbol", config.symbol);
        vm.serializeUint(json, "maxSupply", config.maxSupply);
        vm.serializeUint(json, "mintPrice", config.mintPrice);
        vm.serializeUint(json, "maxMintPerAddress", config.maxMintPerAddress);
        vm.serializeString(json, "baseURI", config.baseURI);
        vm.serializeAddress(json, "owner", config.owner);
        vm.serializeUint(json, "deployedAt", block.timestamp);

        string memory finalJson = vm.serializeUint(json, "blockNumber", block.number);

        string memory fileName = string(abi.encodePacked("deployments/", network, "-deployment.json"));
        vm.writeJson(finalJson, fileName);

        console.log("Deployment info saved to:", fileName);
    }

    /**
     * @dev 获取初始白名单地址
     */
    function _getInitialWhitelist() internal returns (address[] memory) {
        string memory network = vm.envOr("NETWORK", string("local"));

        if (keccak256(bytes(network)) == keccak256(bytes("local"))) {
            // 本地测试白名单
            address[] memory whitelist = new address[](3);
            whitelist[0] = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;
            whitelist[1] = 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC;
            whitelist[2] = 0x90F79bf6EB2c4f870365E785982E1f101E93b906;
            return whitelist;
        } else {
            // 从环境变量或文件读取白名单
            try vm.envAddress("WHITELIST_ADDRESS_1") returns (address addr1) {
                address[] memory whitelist = new address[](1);
                whitelist[0] = addr1;
                return whitelist;
            } catch {
                // 返回空数组
                return new address[](0);
            }
        }
    }

    /**
     * @dev 为团队预mint NFT
     */
    function _preMintForTeam() internal {
        string memory network = vm.envOr("NETWORK", string("local"));

        // 只在主网和测试网进行预mint
        if (keccak256(bytes(network)) != keccak256(bytes("local"))) {
            try vm.envAddress("TEAM_ADDRESS") returns (address teamAddr) {
                vm.startBroadcast();

                // 为团队mint 10个NFT
                for (uint256 i = 0; i < 10; i++) {
                    string memory uri = string(abi.encodePacked("team-nft-", vm.toString(i)));
                    deployedNFT.ownerMint(teamAddr, uri);
                }

                vm.stopBroadcast();

                console.log("Pre-minted 10 NFTs for team address:", teamAddr);
            } catch {
                console.log("No team address specified, skipping pre-mint");
            }
        }
    }

    /**
     * @dev 获取特定网络的gas价格建议
     */
    function getGasPrice(string memory network) public pure returns (uint256) {
        if (keccak256(bytes(network)) == keccak256(bytes("mainnet"))) {
            return 30 gwei;
        } else if (keccak256(bytes(network)) == keccak256(bytes("polygon"))) {
            return 100 gwei;
        } else if (keccak256(bytes(network)) == keccak256(bytes("sepolia"))) {
            return 10 gwei;
        } else {
            return 1 gwei; // local
        }
    }

    /**
     * @dev 估算部署成本
     */
    function estimateDeploymentCost(string memory network) public view returns (uint256) {
        uint256 gasPrice = getGasPrice(network);
        uint256 estimatedGas = 3000000; // 预估gas用量
        return gasPrice * estimatedGas;
    }
}