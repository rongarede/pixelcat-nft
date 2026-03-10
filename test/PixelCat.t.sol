// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/PixelCat.sol";

contract PixelCatTest is Test {
    PixelCat public pixelCat;
    address public owner;
    address public user1;
    address public user2;

    uint256 constant BREEDING_FEE = 0.001 ether;

    // 允许合约接收ETH
    receive() external payable {}

    event NewCatBorn(
        uint256 indexed tokenId,
        uint256 indexed parent1,
        uint256 indexed parent2,
        uint256 gene,
        address owner
    );

    event CatMinted(uint256 indexed tokenId, uint256 gene, address indexed to);

    function setUp() public {
        owner = address(this);
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");

        pixelCat = new PixelCat();

        // 为用户提供一些ETH
        vm.deal(user1, 10 ether);
        vm.deal(user2, 10 ether);
    }

    function test_InitialState() public {
        // 检查初始状态
        assertEq(pixelCat.totalSupply(), 2, "Initial supply should be 2");
        assertEq(pixelCat.ownerOf(0), owner, "Owner should own token 0");
        assertEq(pixelCat.ownerOf(1), owner, "Owner should own token 1");
        assertEq(pixelCat.breedingFee(), BREEDING_FEE, "Breeding fee should be correct");

        // 检查基因不为0
        assertTrue(pixelCat.getGene(0) != 0, "Gene 0 should not be zero");
        assertTrue(pixelCat.getGene(1) != 0, "Gene 1 should not be zero");

        // 检查调色板
        string[16] memory palette = pixelCat.getPalette();
        assertEq(palette[0], "#000000", "First color should be black");
        assertEq(palette[1], "#FFFFFF", "Second color should be white");
    }

    function test_OwnerMint() public {
        uint256 initialSupply = pixelCat.totalSupply();

        vm.expectEmit(true, true, true, false);
        emit CatMinted(initialSupply, 0, user1); // gene值会随机生成，所以用0占位

        pixelCat.ownerMint(user1);

        assertEq(pixelCat.totalSupply(), initialSupply + 1, "Supply should increase");
        assertEq(pixelCat.ownerOf(initialSupply), user1, "User1 should own new token");
        assertTrue(pixelCat.getGene(initialSupply) != 0, "New gene should not be zero");
    }

    function test_OwnerMintOnlyOwner() public {
        vm.prank(user1);
        vm.expectRevert("Ownable: caller is not the owner");
        pixelCat.ownerMint(user2);
    }

    function test_BreedSuccess() public {
        // Owner铸造两只猫给user1
        pixelCat.ownerMint(user1);
        pixelCat.ownerMint(user1);

        uint256 parent1 = 2; // 第三只猫
        uint256 parent2 = 3; // 第四只猫
        uint256 expectedOffspring = pixelCat.totalSupply();

        vm.startPrank(user1);

        vm.expectEmit(true, true, true, false);
        emit NewCatBorn(expectedOffspring, parent1, parent2, 0, user1);

        pixelCat.breed{value: BREEDING_FEE}(parent1, parent2);

        vm.stopPrank();

        // 验证结果
        assertEq(pixelCat.totalSupply(), expectedOffspring + 1, "Supply should increase");
        assertEq(pixelCat.ownerOf(expectedOffspring), user1, "User1 should own offspring");
        assertTrue(pixelCat.getGene(expectedOffspring) != 0, "Offspring gene should not be zero");
    }

    function test_BreedWithOneParent() public {
        // user1拥有一只猫，owner拥有另一只
        pixelCat.ownerMint(user1);

        vm.startPrank(user1);

        // user1可以用自己的猫(2)和owner的猫(0)繁殖
        pixelCat.breed{value: BREEDING_FEE}(2, 0);

        vm.stopPrank();

        assertEq(pixelCat.totalSupply(), 4, "Supply should be 4");
        assertEq(pixelCat.ownerOf(3), user1, "User1 should own offspring");
    }

    function test_BreedFailInsufficientFee() public {
        pixelCat.ownerMint(user1);
        pixelCat.ownerMint(user1);

        vm.startPrank(user1);

        vm.expectRevert("Insufficient breeding fee");
        pixelCat.breed{value: BREEDING_FEE - 1}(2, 3);

        vm.stopPrank();
    }

    function test_BreedFailSameCat() public {
        pixelCat.ownerMint(user1);

        vm.startPrank(user1);

        vm.expectRevert("Cannot breed with itself");
        pixelCat.breed{value: BREEDING_FEE}(2, 2);

        vm.stopPrank();
    }

    function test_BreedFailNotOwner() public {
        pixelCat.ownerMint(user2);
        pixelCat.ownerMint(user2);

        vm.startPrank(user1);

        vm.expectRevert("Must own at least one parent cat");
        pixelCat.breed{value: BREEDING_FEE}(2, 3);

        vm.stopPrank();
    }

    function test_BreedFailNonexistentCat() public {
        vm.startPrank(user1);

        vm.expectRevert("Parent cats do not exist");
        pixelCat.breed{value: BREEDING_FEE}(999, 1000);

        vm.stopPrank();
    }

    function test_GetGeneFailNonexistent() public {
        vm.expectRevert("Cat does not exist");
        pixelCat.getGene(999);
    }

    function test_SetBreedingFee() public {
        uint256 newFee = 0.002 ether;

        pixelCat.setBreedingFee(newFee);

        assertEq(pixelCat.breedingFee(), newFee, "Breeding fee should be updated");
    }

    function test_SetBreedingFeeOnlyOwner() public {
        vm.prank(user1);
        vm.expectRevert("Ownable: caller is not the owner");
        pixelCat.setBreedingFee(0.002 ether);
    }

    function test_Withdraw() public {
        // 先进行一些繁殖来积累资金
        pixelCat.ownerMint(user1);
        pixelCat.ownerMint(user1);

        vm.prank(user1);
        pixelCat.breed{value: BREEDING_FEE}(2, 3);

        uint256 contractBalance = address(pixelCat).balance;
        uint256 ownerInitialBalance = owner.balance;

        pixelCat.withdraw();

        assertEq(address(pixelCat).balance, 0, "Contract balance should be zero");
        assertEq(owner.balance, ownerInitialBalance + contractBalance, "Owner should receive funds");
    }

    function test_WithdrawOnlyOwner() public {
        vm.prank(user1);
        vm.expectRevert("Ownable: caller is not the owner");
        pixelCat.withdraw();
    }

    function test_WithdrawNoFunds() public {
        vm.expectRevert("No funds to withdraw");
        pixelCat.withdraw();
    }

    function test_UtilityFunctions() public {
        assertTrue(pixelCat.exists(0), "Token 0 should exist");
        assertTrue(pixelCat.exists(1), "Token 1 should exist");
        assertFalse(pixelCat.exists(999), "Token 999 should not exist");
    }

    function test_GeneGeneration() public {
        // 测试基因生成的随机性
        uint256[] memory genes = new uint256[](10);

        for (uint256 i = 0; i < 10; i++) {
            pixelCat.ownerMint(user1);
            genes[i] = pixelCat.getGene(pixelCat.totalSupply() - 1);
        }

        // 检查基因不全相同（虽然理论上可能相同，但概率极低）
        bool allSame = true;
        for (uint256 i = 1; i < 10; i++) {
            if (genes[i] != genes[0]) {
                allSame = false;
                break;
            }
        }
        assertFalse(allSame, "Not all genes should be the same");
    }

    function test_BreedingGeneInheritance() public {
        // 获取父母基因
        uint256 gene1 = pixelCat.getGene(0);
        uint256 gene2 = pixelCat.getGene(1);

        pixelCat.ownerMint(user1);
        pixelCat.ownerMint(user1);

        vm.prank(user1);
        pixelCat.breed{value: BREEDING_FEE}(2, 3);

        uint256 offspringGene = pixelCat.getGene(4);

        // 子代基因应该不同于父母基因（除非极端巧合）
        assertTrue(offspringGene != gene1 || offspringGene != gene2, "Offspring should have different gene");

        console.log("Parent 1 gene:", gene1);
        console.log("Parent 2 gene:", gene2);
        console.log("Offspring gene:", offspringGene);
    }

    function test_MultipleBreeding() public {
        // 测试多次繁殖
        pixelCat.ownerMint(user1);
        pixelCat.ownerMint(user1);

        vm.startPrank(user1);

        // 第一次繁殖
        pixelCat.breed{value: BREEDING_FEE}(2, 3);
        uint256 offspring1 = pixelCat.totalSupply() - 1;

        // 第二次繁殖（使用新生的猫）
        pixelCat.breed{value: BREEDING_FEE}(2, offspring1);
        uint256 offspring2 = pixelCat.totalSupply() - 1;

        vm.stopPrank();

        assertEq(pixelCat.totalSupply(), 6, "Should have 6 cats total");
        assertEq(pixelCat.ownerOf(offspring1), user1, "User1 should own first offspring");
        assertEq(pixelCat.ownerOf(offspring2), user1, "User1 should own second offspring");
    }

    // 模糊测试：随机繁殖
    function testFuzz_BreedingSuccess(uint256 fee) public {
        vm.assume(fee >= BREEDING_FEE && fee <= 1 ether);

        pixelCat.ownerMint(user1);
        pixelCat.ownerMint(user1);

        vm.deal(user1, fee);

        vm.prank(user1);
        pixelCat.breed{value: fee}(2, 3);

        assertEq(pixelCat.totalSupply(), 5, "Supply should be 5");
        assertTrue(pixelCat.exists(4), "New cat should exist");
    }
}