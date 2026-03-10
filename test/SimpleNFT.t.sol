// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/SimpleNFT.sol";

/**
 * @title SimpleNFTTest
 * @dev ERC-721合约的完整测试套件
 */
contract SimpleNFTTest is Test {
    SimpleNFT public nft;

    // 测试地址
    address public owner = address(0x1);
    address public user1 = address(0x2);
    address public user2 = address(0x3);
    address public user3 = address(0x4);

    // 测试常量
    string constant NAME = "SimpleNFT";
    string constant SYMBOL = "SNFT";
    uint256 constant MAX_SUPPLY = 1000;
    uint256 constant MINT_PRICE = 0.1 ether;
    uint256 constant MAX_MINT_PER_ADDRESS = 5;
    string constant BASE_URI = "https://api.example.com/metadata/";
    string constant TOKEN_URI = "test-uri";

    // 自定义错误
    error InsufficientBalance();
    error TransferFailed();

    // 事件声明（用于测试）
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event TokenMinted(address indexed to, uint256 indexed tokenId, string tokenURI);
    event WhitelistAdded(address indexed account);
    event WhitelistRemoved(address indexed account);

    function setUp() public {
        // 设置测试环境
        vm.startPrank(owner);
        nft = new SimpleNFT(
            NAME,
            SYMBOL,
            MAX_SUPPLY,
            MINT_PRICE,
            MAX_MINT_PER_ADDRESS,
            BASE_URI
        );
        vm.stopPrank();

        // 给用户分配ETH
        vm.deal(user1, 10 ether);
        vm.deal(user2, 10 ether);
        vm.deal(user3, 10 ether);
    }

    // ============ 基础功能测试 ============

    function testInitialState() public {
        assertEq(nft.name(), NAME);
        assertEq(nft.symbol(), SYMBOL);
        assertEq(nft.maxSupply(), MAX_SUPPLY);
        assertEq(nft.mintPrice(), MINT_PRICE);
        assertEq(nft.maxMintPerAddress(), MAX_MINT_PER_ADDRESS);
        assertEq(nft.owner(), owner);
        assertEq(nft.totalSupply(), 0);
        assertFalse(nft.paused());
    }

    function testSupportsInterface() public {
        // ERC721
        assertTrue(nft.supportsInterface(0x80ac58cd));
        // ERC721Metadata
        assertTrue(nft.supportsInterface(0x5b5e139f));
        // ERC721Enumerable
        assertTrue(nft.supportsInterface(0x780e9d63));
        // ERC165
        assertTrue(nft.supportsInterface(0x01ffc9a7));
    }

    // ============ Mint功能测试 ============

    function testMintSuccess() public {
        vm.startPrank(user1);

        // 验证事件发出
        vm.expectEmit(true, true, false, true);
        emit TokenMinted(user1, 0, TOKEN_URI);

        nft.mint{value: MINT_PRICE}(user1, TOKEN_URI);

        assertEq(nft.balanceOf(user1), 1);
        assertEq(nft.ownerOf(0), user1);
        assertEq(nft.tokenURI(0), string(abi.encodePacked(BASE_URI, TOKEN_URI)));
        assertEq(nft.totalSupply(), 1);
        assertEq(nft.mintedCount(user1), 1);

        vm.stopPrank();
    }

    function testMintInsufficientPayment() public {
        vm.startPrank(user1);

        vm.expectRevert("Insufficient payment");
        nft.mint{value: MINT_PRICE - 1}(user1, TOKEN_URI);

        vm.stopPrank();
    }

    function testMintExceedsMaxSupply() public {
        // 设置最大供应量为1
        vm.startPrank(owner);
        SimpleNFT smallNft = new SimpleNFT(NAME, SYMBOL, 1, MINT_PRICE, MAX_MINT_PER_ADDRESS, BASE_URI);
        vm.stopPrank();

        vm.startPrank(user1);

        // 第一次mint成功
        smallNft.mint{value: MINT_PRICE}(user1, TOKEN_URI);

        // 第二次mint失败
        vm.expectRevert("Max supply reached");
        smallNft.mint{value: MINT_PRICE}(user1, TOKEN_URI);

        vm.stopPrank();
    }

    function testMintExceedsMaxPerAddress() public {
        vm.startPrank(user1);

        // Mint到限制数量
        for (uint256 i = 0; i < MAX_MINT_PER_ADDRESS; i++) {
            nft.mint{value: MINT_PRICE}(user1, TOKEN_URI);
        }

        // 超出限制应该失败
        vm.expectRevert("Max mint per address exceeded");
        nft.mint{value: MINT_PRICE}(user1, TOKEN_URI);

        vm.stopPrank();
    }

    function testMintWhenPaused() public {
        vm.prank(owner);
        nft.pause();

        vm.startPrank(user1);
        vm.expectRevert("Pausable: paused");
        nft.mint{value: MINT_PRICE}(user1, TOKEN_URI);
        vm.stopPrank();
    }

    // ============ 白名单功能测试 ============

    function testWhitelistMint() public {
        // 添加用户到白名单
        vm.prank(owner);
        nft.addToWhitelist(user1);

        assertTrue(nft.whitelist(user1));

        vm.startPrank(user1);

        // 白名单用户可以半价mint
        vm.expectEmit(true, true, false, true);
        emit TokenMinted(user1, 0, TOKEN_URI);

        nft.whitelistMint{value: MINT_PRICE / 2}(user1, TOKEN_URI);

        assertEq(nft.balanceOf(user1), 1);
        assertEq(nft.ownerOf(0), user1);

        vm.stopPrank();
    }

    function testWhitelistMintNotWhitelisted() public {
        vm.startPrank(user1);

        vm.expectRevert("Not whitelisted");
        nft.whitelistMint{value: MINT_PRICE / 2}(user1, TOKEN_URI);

        vm.stopPrank();
    }

    function testWhitelistMintInsufficientPayment() public {
        vm.prank(owner);
        nft.addToWhitelist(user1);

        vm.startPrank(user1);

        vm.expectRevert("Insufficient payment");
        nft.whitelistMint{value: MINT_PRICE / 2 - 1}(user1, TOKEN_URI);

        vm.stopPrank();
    }

    function testAddRemoveWhitelist() public {
        vm.startPrank(owner);

        // 添加到白名单
        vm.expectEmit(true, false, false, false);
        emit WhitelistAdded(user1);
        nft.addToWhitelist(user1);
        assertTrue(nft.whitelist(user1));

        // 从白名单移除
        vm.expectEmit(true, false, false, false);
        emit WhitelistRemoved(user1);
        nft.removeFromWhitelist(user1);
        assertFalse(nft.whitelist(user1));

        vm.stopPrank();
    }

    function testAddMultipleToWhitelist() public {
        address[] memory accounts = new address[](3);
        accounts[0] = user1;
        accounts[1] = user2;
        accounts[2] = user3;

        vm.prank(owner);
        nft.addMultipleToWhitelist(accounts);

        assertTrue(nft.whitelist(user1));
        assertTrue(nft.whitelist(user2));
        assertTrue(nft.whitelist(user3));
    }

    // ============ Owner功能测试 ============

    function testOwnerMint() public {
        vm.startPrank(owner);

        vm.expectEmit(true, true, false, true);
        emit TokenMinted(user1, 0, TOKEN_URI);

        nft.ownerMint(user1, TOKEN_URI);

        assertEq(nft.balanceOf(user1), 1);
        assertEq(nft.ownerOf(0), user1);

        vm.stopPrank();
    }

    function testOwnerMintNonOwner() public {
        vm.startPrank(user1);

        vm.expectRevert("Ownable: caller is not the owner");
        nft.ownerMint(user1, TOKEN_URI);

        vm.stopPrank();
    }

    function testBatchMint() public {
        address[] memory recipients = new address[](3);
        recipients[0] = user1;
        recipients[1] = user2;
        recipients[2] = user3;

        string[] memory uris = new string[](3);
        uris[0] = "uri1";
        uris[1] = "uri2";
        uris[2] = "uri3";

        vm.prank(owner);
        nft.batchMint(recipients, uris);

        assertEq(nft.totalSupply(), 3);
        assertEq(nft.balanceOf(user1), 1);
        assertEq(nft.balanceOf(user2), 1);
        assertEq(nft.balanceOf(user3), 1);

        assertEq(nft.ownerOf(0), user1);
        assertEq(nft.ownerOf(1), user2);
        assertEq(nft.ownerOf(2), user3);
    }

    function testBatchMintArrayLengthMismatch() public {
        address[] memory recipients = new address[](2);
        recipients[0] = user1;
        recipients[1] = user2;

        string[] memory uris = new string[](3);
        uris[0] = "uri1";
        uris[1] = "uri2";
        uris[2] = "uri3";

        vm.prank(owner);
        vm.expectRevert("Arrays length mismatch");
        nft.batchMint(recipients, uris);
    }

    // ============ 配置管理测试 ============

    function testSetBaseURI() public {
        string memory newBaseURI = "https://newapi.example.com/";

        vm.prank(owner);
        nft.setBaseURI(newBaseURI);

        // Mint一个token来验证URI
        vm.prank(owner);
        nft.ownerMint(user1, TOKEN_URI);

        assertEq(nft.tokenURI(0), string(abi.encodePacked(newBaseURI, TOKEN_URI)));
    }

    function testSetMintPrice() public {
        uint256 newPrice = 0.2 ether;

        vm.prank(owner);
        nft.setMintPrice(newPrice);

        assertEq(nft.mintPrice(), newPrice);

        // 验证新价格生效
        vm.startPrank(user1);
        nft.mint{value: newPrice}(user1, TOKEN_URI);
        vm.stopPrank();

        assertEq(nft.balanceOf(user1), 1);
    }

    function testSetMaxMintPerAddress() public {
        uint256 newMax = 10;

        vm.prank(owner);
        nft.setMaxMintPerAddress(newMax);

        assertEq(nft.maxMintPerAddress(), newMax);
    }

    // ============ 暂停功能测试 ============

    function testPauseUnpause() public {
        vm.startPrank(owner);

        // 暂停
        nft.pause();
        assertTrue(nft.paused());

        // 恢复
        nft.unpause();
        assertFalse(nft.paused());

        vm.stopPrank();
    }

    function testPauseNonOwner() public {
        vm.startPrank(user1);

        vm.expectRevert("Ownable: caller is not the owner");
        nft.pause();

        vm.stopPrank();
    }

    function testTransferWhenPaused() public {
        // 先mint一个token
        vm.prank(owner);
        nft.ownerMint(user1, TOKEN_URI);

        // 暂停合约
        vm.prank(owner);
        nft.pause();

        // 尝试转移token应该失败
        vm.startPrank(user1);
        vm.expectRevert("Pausable: paused");
        nft.transferFrom(user1, user2, 0);
        vm.stopPrank();
    }

    // ============ 资金提取测试 ============

    function testWithdraw() public {
        // 用户mint一些NFT，向合约发送ETH
        vm.startPrank(user1);
        nft.mint{value: MINT_PRICE}(user1, TOKEN_URI);
        vm.stopPrank();

        vm.startPrank(user2);
        nft.mint{value: MINT_PRICE}(user2, TOKEN_URI);
        vm.stopPrank();

        uint256 contractBalance = address(nft).balance;
        uint256 ownerBalanceBefore = owner.balance;

        assertEq(contractBalance, MINT_PRICE * 2);

        vm.prank(owner);
        nft.withdraw();

        assertEq(address(nft).balance, 0);
        assertEq(owner.balance, ownerBalanceBefore + contractBalance);
    }

    function testWithdrawNoFunds() public {
        vm.prank(owner);
        vm.expectRevert("No funds to withdraw");
        nft.withdraw();
    }

    function testWithdrawNonOwner() public {
        vm.startPrank(user1);
        vm.expectRevert("Ownable: caller is not the owner");
        nft.withdraw();
        vm.stopPrank();
    }

    // ============ 查询功能测试 ============

    function testTokensOfOwner() public {
        vm.startPrank(owner);

        // Mint多个token给user1
        nft.ownerMint(user1, "uri1");
        nft.ownerMint(user2, "uri2");
        nft.ownerMint(user1, "uri3");
        nft.ownerMint(user1, "uri4");

        vm.stopPrank();

        uint256[] memory user1Tokens = nft.tokensOfOwner(user1);
        uint256[] memory user2Tokens = nft.tokensOfOwner(user2);

        assertEq(user1Tokens.length, 3);
        assertEq(user2Tokens.length, 1);

        assertEq(user1Tokens[0], 0);
        assertEq(user1Tokens[1], 2);
        assertEq(user1Tokens[2], 3);

        assertEq(user2Tokens[0], 1);
    }

    function testExists() public {
        assertFalse(nft.exists(0));

        vm.prank(owner);
        nft.ownerMint(user1, TOKEN_URI);

        assertTrue(nft.exists(0));
        assertFalse(nft.exists(1));
    }

    // ============ 边界条件和模糊测试 ============

    function testFuzzMint(uint96 price) public {
        vm.assume(price >= MINT_PRICE);
        vm.assume(price <= 100 ether); // 设置合理上限

        vm.deal(user1, price);

        vm.startPrank(user1);
        nft.mint{value: price}(user1, TOKEN_URI);
        vm.stopPrank();

        assertEq(nft.balanceOf(user1), 1);
        assertEq(nft.ownerOf(0), user1);
    }

    function testFuzzBatchMint(uint8 count) public {
        vm.assume(count > 0 && count <= 50); // 限制合理范围

        address[] memory recipients = new address[](count);
        string[] memory uris = new string[](count);

        for (uint256 i = 0; i < count; i++) {
            recipients[i] = address(uint160(0x1000 + i));
            uris[i] = string(abi.encodePacked("uri", vm.toString(i)));
        }

        vm.prank(owner);
        nft.batchMint(recipients, uris);

        assertEq(nft.totalSupply(), count);

        for (uint256 i = 0; i < count; i++) {
            assertEq(nft.ownerOf(i), recipients[i]);
        }
    }

    // ============ Gas优化测试 ============

    function testGasOptimizedMint() public {
        vm.startPrank(user1);

        uint256 gasBefore = gasleft();
        nft.mint{value: MINT_PRICE}(user1, TOKEN_URI);
        uint256 gasUsed = gasBefore - gasleft();

        console.log("Gas used for mint:", gasUsed);
        assertLt(gasUsed, 200000); // 确保gas使用在合理范围内

        vm.stopPrank();
    }

    // ============ 辅助函数 ============

    function _mintTokens(address to, uint256 count) internal {
        vm.startPrank(owner);
        for (uint256 i = 0; i < count; i++) {
            nft.ownerMint(to, string(abi.encodePacked("uri", vm.toString(i))));
        }
        vm.stopPrank();
    }

    function _addToWhitelist(address account) internal {
        vm.prank(owner);
        nft.addToWhitelist(account);
    }

    // ============ 集成测试 ============

    function testCompleteWorkflow() public {
        // 1. 添加用户到白名单
        _addToWhitelist(user1);

        // 2. 白名单用户mint
        vm.startPrank(user1);
        nft.whitelistMint{value: MINT_PRICE / 2}(user1, "whitelist-uri");
        vm.stopPrank();

        // 3. 普通用户mint
        vm.startPrank(user2);
        nft.mint{value: MINT_PRICE}(user2, "normal-uri");
        vm.stopPrank();

        // 4. Owner批量mint
        address[] memory recipients = new address[](2);
        recipients[0] = user2;
        recipients[1] = user3;

        string[] memory uris = new string[](2);
        uris[0] = "batch-uri-1";
        uris[1] = "batch-uri-2";

        vm.prank(owner);
        nft.batchMint(recipients, uris);

        // 5. 验证最终状态
        assertEq(nft.totalSupply(), 4);
        assertEq(nft.balanceOf(user1), 1);
        assertEq(nft.balanceOf(user2), 2);
        assertEq(nft.balanceOf(user3), 1);

        // 6. 提取资金
        uint256 expectedBalance = MINT_PRICE / 2 + MINT_PRICE;
        assertEq(address(nft).balance, expectedBalance);

        vm.prank(owner);
        nft.withdraw();

        assertEq(address(nft).balance, 0);
    }
}