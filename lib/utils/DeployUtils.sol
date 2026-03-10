// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "forge-std/console.sol";

/**
 * @title DeployUtils
 * @dev 部署工具库，包含常用的部署辅助函数
 */
library DeployUtils {
    // 网络ID映射
    uint256 constant MAINNET = 1;
    uint256 constant SEPOLIA = 11155111;
    uint256 constant POLYGON = 137;
    uint256 constant MUMBAI = 80001;
    uint256 constant ARBITRUM = 42161;
    uint256 constant OPTIMISM = 10;
    uint256 constant BASE = 8453;
    uint256 constant LOCAL = 31337;

    struct NetworkConfig {
        uint256 chainId;
        string name;
        string rpcUrl;
        uint256 gasPrice;
        uint256 gasLimit;
        address deployer;
    }

    /**
     * @dev 获取当前网络配置
     */
    function getCurrentNetworkConfig(Vm vm) internal returns (NetworkConfig memory) {
        uint256 chainId = block.chainid;

        if (chainId == MAINNET) {
            return NetworkConfig({
                chainId: MAINNET,
                name: "mainnet",
                rpcUrl: vm.envString("MAINNET_RPC_URL"),
                gasPrice: 30 gwei,
                gasLimit: 300000,
                deployer: vm.envAddress("DEPLOYER_PRIVATE_KEY")
            });
        } else if (chainId == SEPOLIA) {
            return NetworkConfig({
                chainId: SEPOLIA,
                name: "sepolia",
                rpcUrl: vm.envString("SEPOLIA_RPC_URL"),
                gasPrice: 10 gwei,
                gasLimit: 300000,
                deployer: vm.envAddress("DEPLOYER_PRIVATE_KEY")
            });
        } else if (chainId == POLYGON) {
            return NetworkConfig({
                chainId: POLYGON,
                name: "polygon",
                rpcUrl: vm.envString("POLYGON_RPC_URL"),
                gasPrice: 100 gwei,
                gasLimit: 300000,
                deployer: vm.envAddress("DEPLOYER_PRIVATE_KEY")
            });
        } else {
            // 默认为本地网络
            return NetworkConfig({
                chainId: LOCAL,
                name: "local",
                rpcUrl: "http://127.0.0.1:8545",
                gasPrice: 1 gwei,
                gasLimit: 300000,
                deployer: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
            });
        }
    }

    /**
     * @dev 验证部署前的条件
     */
    function validateDeployment(
        Vm vm,
        address deployer,
        uint256 requiredBalance
    ) internal view {
        require(deployer != address(0), "Invalid deployer address");
        require(deployer.balance >= requiredBalance, "Insufficient deployer balance");

        // 验证环境变量
        if (block.chainid != LOCAL) {
            require(bytes(vm.envString("ETHERSCAN_API_KEY")).length > 0, "Etherscan API key required");
        }
    }

    /**
     * @dev 计算部署成本
     */
    function calculateDeploymentCost(
        uint256 gasPrice,
        uint256 estimatedGas
    ) internal pure returns (uint256) {
        return gasPrice * estimatedGas;
    }

    /**
     * @dev 等待合约部署确认
     */
    function waitForConfirmations(
        Vm vm,
        address contractAddress,
        uint256 confirmations
    ) internal view {
        require(contractAddress != address(0), "Invalid contract address");
        require(contractAddress.code.length > 0, "Contract not deployed");

        // 在实际网络上等待确认
        if (block.chainid != LOCAL) {
            console.log("Waiting for", confirmations, "confirmations...");
            // 这里可以添加实际的等待逻辑
        }
    }

    /**
     * @dev 验证合约部署
     */
    function verifyContractDeployment(address contractAddress) internal view {
        require(contractAddress != address(0), "Contract address is zero");
        require(contractAddress.code.length > 0, "No contract code at address");
    }

    /**
     * @dev 生成部署报告
     */
    function generateDeploymentReport(
        string memory contractName,
        address contractAddress,
        uint256 gasUsed,
        uint256 deploymentCost
    ) internal view {
        console.log("=== Deployment Report ===");
        console.log("Contract:", contractName);
        console.log("Address:", contractAddress);
        console.log("Gas Used:", gasUsed);
        console.log("Deployment Cost:", deploymentCost);
        console.log("Chain ID:", block.chainid);
        console.log("Block Number:", block.number);
        console.log("========================");
    }

    /**
     * @dev 保存部署地址到文件
     */
    function saveDeploymentAddress(
        Vm vm,
        string memory network,
        string memory contractName,
        address contractAddress
    ) internal {
        string memory json = "deployment";
        vm.serializeAddress(json, contractName, contractAddress);
        string memory finalJson = vm.serializeUint(json, "timestamp", block.timestamp);

        string memory fileName = string(abi.encodePacked(network, "-addresses.json"));
        vm.writeJson(finalJson, fileName);

        console.log("Deployment address saved to:", fileName);
    }

    /**
     * @dev 读取已部署的合约地址
     */
    function loadDeploymentAddress(
        Vm vm,
        string memory network,
        string memory contractName
    ) internal returns (address) {
        string memory fileName = string(abi.encodePacked(network, "-addresses.json"));

        try vm.readFile(fileName) returns (string memory json) {
            return vm.parseJsonAddress(json, string(abi.encodePacked(".", contractName)));
        } catch {
            return address(0);
        }
    }
}

/**
 * @title BaseDeployScript
 * @dev 基础部署脚本，其他部署脚本可以继承
 */
abstract contract BaseDeployScript is Script {
    using DeployUtils for *;

    DeployUtils.NetworkConfig public networkConfig;

    modifier onlyValidNetwork() {
        networkConfig = DeployUtils.getCurrentNetworkConfig(vm);
        require(networkConfig.chainId != 0, "Unsupported network");
        _;
    }

    modifier validateDeployer() {
        require(msg.sender != address(0), "Invalid deployer");
        _;
    }

    function setUp() public virtual {
        networkConfig = DeployUtils.getCurrentNetworkConfig(vm);
    }

    /**
     * @dev 部署前的通用检查
     */
    function preDeploymentChecks() internal view {
        console.log("Deploying to network:", networkConfig.name);
        console.log("Chain ID:", networkConfig.chainId);
        console.log("Deployer:", networkConfig.deployer);
        console.log("Deployer balance:", networkConfig.deployer.balance);

        DeployUtils.validateDeployment(vm, networkConfig.deployer, 0.1 ether);
    }

    /**
     * @dev 部署后的通用操作
     */
    function postDeploymentActions(
        string memory contractName,
        address contractAddress,
        uint256 gasUsed
    ) internal {
        DeployUtils.verifyContractDeployment(contractAddress);

        uint256 deploymentCost = DeployUtils.calculateDeploymentCost(
            networkConfig.gasPrice,
            gasUsed
        );

        DeployUtils.generateDeploymentReport(
            contractName,
            contractAddress,
            gasUsed,
            deploymentCost
        );

        DeployUtils.saveDeploymentAddress(
            vm,
            networkConfig.name,
            contractName,
            contractAddress
        );

        // 在测试网和主网上验证合约
        if (networkConfig.chainId != DeployUtils.LOCAL) {
            verifyContract(contractAddress);
        }
    }

    /**
     * @dev 验证合约（子类需要实现）
     */
    function verifyContract(address contractAddress) internal virtual {
        console.log("Contract verification not implemented for:", contractAddress);
    }

    /**
     * @dev 获取或创建Create2地址
     */
    function getCreate2Address(
        bytes memory bytecode,
        bytes32 salt,
        address deployer
    ) internal pure returns (address) {
        return address(uint160(uint256(keccak256(abi.encodePacked(
            bytes1(0xff),
            deployer,
            salt,
            keccak256(bytecode)
        )))));
    }

    /**
     * @dev 使用Create2部署合约
     */
    function deployWithCreate2(
        bytes memory bytecode,
        bytes32 salt
    ) internal returns (address) {
        address computed = getCreate2Address(bytecode, salt, address(this));

        assembly {
            let addr := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }

        return computed;
    }
}