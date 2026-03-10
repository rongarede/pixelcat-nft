// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "forge-std/console.sol";

/**
 * @title TestUtils
 * @dev NFT测试常用工具函数库
 */
library TestUtils {
    // 常用测试地址
    address constant ALICE = address(0x1);
    address constant BOB = address(0x2);
    address constant CHARLIE = address(0x3);
    address constant DEPLOYER = address(0x4);
    address constant TREASURY = address(0x5);

    // 常用测试值
    uint256 constant DEFAULT_MINT_PRICE = 0.1 ether;
    uint256 constant DEFAULT_MAX_SUPPLY = 10000;
    uint256 constant DEFAULT_MAX_PER_WALLET = 5;

    /**
     * @dev 生成随机地址
     */
    function randomAddress(uint256 seed) internal pure returns (address) {
        return address(uint160(uint256(keccak256(abi.encodePacked(seed)))));
    }

    /**
     * @dev 生成随机地址数组
     */
    function randomAddresses(uint256 count, uint256 startSeed) internal pure returns (address[] memory) {
        address[] memory addresses = new address[](count);
        for (uint256 i = 0; i < count; i++) {
            addresses[i] = randomAddress(startSeed + i);
        }
        return addresses;
    }

    /**
     * @dev 生成随机字符串
     */
    function randomString(uint256 seed, uint256 length) internal pure returns (string memory) {
        bytes memory result = new bytes(length);
        for (uint256 i = 0; i < length; i++) {
            result[i] = bytes1(uint8(65 + (uint256(keccak256(abi.encodePacked(seed, i))) % 26)));
        }
        return string(result);
    }

    /**
     * @dev 生成token URI数组
     */
    function generateTokenURIs(uint256 count, string memory prefix) internal pure returns (string[] memory) {
        string[] memory uris = new string[](count);
        for (uint256 i = 0; i < count; i++) {
            uris[i] = string(abi.encodePacked(prefix, Strings.toString(i)));
        }
        return uris;
    }

    /**
     * @dev 计算mint总费用
     */
    function calculateMintCost(uint256 quantity, uint256 pricePerToken) internal pure returns (uint256) {
        return quantity * pricePerToken;
    }

    /**
     * @dev 创建用于测试的ETH转账
     */
    function fundAccount(Vm vm, address account, uint256 amount) internal {
        vm.deal(account, amount);
    }

    /**
     * @dev 批量为账户提供ETH
     */
    function fundAccounts(Vm vm, address[] memory accounts, uint256 amount) internal {
        for (uint256 i = 0; i < accounts.length; i++) {
            vm.deal(accounts[i], amount);
        }
    }

    /**
     * @dev 模拟时间流逝
     */
    function skipTime(Vm vm, uint256 seconds_) internal {
        vm.warp(block.timestamp + seconds_);
    }

    /**
     * @dev 模拟区块增长
     */
    function skipBlocks(Vm vm, uint256 blocks) internal {
        vm.roll(block.number + blocks);
    }

    /**
     * @dev 验证ERC721基础功能
     */
    function assertERC721Basic(
        IERC721 token,
        address owner,
        uint256 tokenId,
        string memory expectedURI
    ) internal {
        assertEq(token.ownerOf(tokenId), owner, "Owner mismatch");
        assertEq(token.balanceOf(owner), 1, "Balance mismatch");
        assertEq(token.tokenURI(tokenId), expectedURI, "URI mismatch");
        assertTrue(token.supportsInterface(0x80ac58cd), "ERC721 interface not supported");
    }

    /**
     * @dev 验证代币转移
     */
    function assertTransfer(
        IERC721 token,
        address from,
        address to,
        uint256 tokenId
    ) internal {
        assertEq(token.ownerOf(tokenId), to, "Transfer failed: wrong owner");

        if (from != address(0)) {
            // 检查from地址余额减少（假设只转移一个token）
            // 注意：这里需要在转移前记录余额进行比较
        }
    }

    /**
     * @dev 断言合约状态
     */
    function assertContractState(
        address contractAddr,
        uint256 expectedBalance,
        bool expectedPaused
    ) internal {
        assertEq(contractAddr.balance, expectedBalance, "Contract balance mismatch");
        // 这里需要根据具体合约接口来检查paused状态
    }

    /**
     * @dev 生成Merkle树叶子节点
     */
    function generateMerkleLeaf(address account, uint256 amount) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(account, amount));
    }

    /**
     * @dev 预期事件断言辅助函数
     */
    function expectEmitMint(Vm vm, address to, uint256 tokenId, string memory uri) internal {
        vm.expectEmit(true, true, false, true);
        // 这里需要emit具体的事件
        // emit TokenMinted(to, tokenId, uri);
    }

    /**
     * @dev 预期转移事件
     */
    function expectEmitTransfer(Vm vm, address from, address to, uint256 tokenId) internal {
        vm.expectEmit(true, true, true, false);
        // emit Transfer(from, to, tokenId);
    }
}

/**
 * @title NFTTestBase
 * @dev NFT测试的基础合约，包含常用的setup和辅助函数
 */
abstract contract NFTTestBase is Test {
    using TestUtils for *;

    // 常用测试账户
    address public deployer = TestUtils.DEPLOYER;
    address public alice = TestUtils.ALICE;
    address public bob = TestUtils.BOB;
    address public charlie = TestUtils.CHARLIE;
    address public treasury = TestUtils.TREASURY;

    // 常用测试值
    uint256 public constant MINT_PRICE = TestUtils.DEFAULT_MINT_PRICE;
    uint256 public constant MAX_SUPPLY = TestUtils.DEFAULT_MAX_SUPPLY;
    uint256 public constant MAX_PER_WALLET = TestUtils.DEFAULT_MAX_PER_WALLET;

    function setUpAccounts() public virtual {
        // 为测试账户分配ETH
        vm.deal(alice, 100 ether);
        vm.deal(bob, 100 ether);
        vm.deal(charlie, 100 ether);
        vm.deal(deployer, 100 ether);

        // 设置账户标签（便于调试）
        vm.label(alice, "Alice");
        vm.label(bob, "Bob");
        vm.label(charlie, "Charlie");
        vm.label(deployer, "Deployer");
        vm.label(treasury, "Treasury");
    }

    /**
     * @dev 生成测试用的地址数组
     */
    function generateTestAddresses(uint256 count) internal pure returns (address[] memory) {
        return TestUtils.randomAddresses(count, 100);
    }

    /**
     * @dev 生成测试用的URI数组
     */
    function generateTestURIs(uint256 count) internal pure returns (string[] memory) {
        return TestUtils.generateTokenURIs(count, "test-uri-");
    }

    /**
     * @dev 模拟用户mint操作
     */
    function simulateUserMint(
        address user,
        address nftContract,
        uint256 quantity,
        uint256 pricePerToken
    ) internal {
        uint256 totalCost = TestUtils.calculateMintCost(quantity, pricePerToken);

        vm.startPrank(user);
        // 这里需要根据具体的mint函数来调用
        // INFTContract(nftContract).mint{value: totalCost}(quantity);
        vm.stopPrank();
    }

    /**
     * @dev 断言mint成功
     */
    function assertMintSuccess(
        IERC721 token,
        address owner,
        uint256 expectedTokenId,
        uint256 expectedBalance
    ) internal {
        assertEq(token.ownerOf(expectedTokenId), owner, "Token owner mismatch");
        assertEq(token.balanceOf(owner), expectedBalance, "Balance mismatch");
    }

    /**
     * @dev 断言mint失败
     */
    function assertMintFailure(
        address user,
        address nftContract,
        bytes memory expectedError,
        uint256 value
    ) internal {
        vm.startPrank(user);
        vm.expectRevert(expectedError);
        // 这里需要根据具体的mint函数来调用
        // INFTContract(nftContract).mint{value: value}(1);
        vm.stopPrank();
    }

    /**
     * @dev 测试合约暂停功能
     */
    function testPauseFunctionality(address contractAddr, address owner) internal {
        // 暂停合约
        vm.prank(owner);
        // IPausable(contractAddr).pause();

        // 验证暂停状态
        // assertTrue(IPausable(contractAddr).paused(), "Contract should be paused");

        // 恢复合约
        vm.prank(owner);
        // IPausable(contractAddr).unpause();

        // 验证恢复状态
        // assertFalse(IPausable(contractAddr).paused(), "Contract should be unpaused");
    }

    /**
     * @dev 测试访问控制
     */
    function testAccessControl(
        address contractAddr,
        address owner,
        address nonOwner,
        bytes4 selector
    ) internal {
        // 测试非owner调用应该失败
        vm.startPrank(nonOwner);
        vm.expectRevert("Ownable: caller is not the owner");
        // 这里需要根据具体函数来调用
        vm.stopPrank();

        // 测试owner调用应该成功
        vm.startPrank(owner);
        // 这里需要根据具体函数来调用
        vm.stopPrank();
    }

    /**
     * @dev 跳过到指定时间
     */
    function skipToTime(uint256 timestamp) internal {
        vm.warp(timestamp);
    }

    /**
     * @dev 跳过指定秒数
     */
    function skipSeconds(uint256 seconds_) internal {
        vm.warp(block.timestamp + seconds_);
    }

    /**
     * @dev 生成模拟签名（用于测试）
     */
    function generateMockSignature() internal pure returns (bytes memory) {
        return abi.encodePacked(
            bytes32(0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef),
            bytes32(0xfedcba0987654321fedcba0987654321fedcba0987654321fedcba0987654321),
            uint8(27)
        );
    }
}