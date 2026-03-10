// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * @title PixelCat NFT繁殖游戏合约
 * @dev 基于ERC-721的像素猫繁殖游戏MVP实现
 */
contract PixelCat is ERC721, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    // 基因映射: tokenId => 基因(uint256)
    mapping(uint256 => uint256) public genes;

    // 繁殖费用
    uint256 public breedingFee = 0.001 ether;

    // 16色调色板
    string[16] private palette = [
        "#000000", "#FFFFFF", "#FF0000", "#00FF00",
        "#0000FF", "#FFFF00", "#FF00FF", "#00FFFF",
        "#800000", "#008000", "#000080", "#808000",
        "#800080", "#008080", "#C0C0C0", "#808080"
    ];

    // 事件
    event NewCatBorn(
        uint256 indexed tokenId,
        uint256 indexed parent1,
        uint256 indexed parent2,
        uint256 gene,
        address owner
    );

    event CatMinted(uint256 indexed tokenId, uint256 gene, address indexed to);

    constructor() ERC721("PixelCat", "PCAT") {
        // 创建创世猫 - tokenId 0
        _mintCat(msg.sender, _generateRandomGene(0));
        // 创建创世猫 - tokenId 1
        _mintCat(msg.sender, _generateRandomGene(1));
    }

    /**
     * @dev 繁殖两只猫，生成新的后代
     * @param parent1 父亲tokenId
     * @param parent2 母亲tokenId
     */
    function breed(uint256 parent1, uint256 parent2) external payable {
        require(msg.value >= breedingFee, "Insufficient breeding fee");
        require(_exists(parent1) && _exists(parent2), "Parent cats do not exist");
        require(parent1 != parent2, "Cannot breed with itself");
        require(
            ownerOf(parent1) == msg.sender || ownerOf(parent2) == msg.sender,
            "Must own at least one parent cat"
        );

        uint256 newGene = _breedGenes(genes[parent1], genes[parent2], _tokenIdCounter.current());
        uint256 newTokenId = _mintCat(msg.sender, newGene);

        emit NewCatBorn(newTokenId, parent1, parent2, newGene, msg.sender);
    }

    /**
     * @dev 获取指定tokenId的基因
     */
    function getGene(uint256 tokenId) external view returns (uint256) {
        require(_exists(tokenId), "Cat does not exist");
        return genes[tokenId];
    }

    /**
     * @dev Owner铸造猫（用于测试和初始分发）
     */
    function ownerMint(address to) external onlyOwner {
        uint256 randomGene = _generateRandomGene(_tokenIdCounter.current());
        _mintCat(to, randomGene);
    }

    /**
     * @dev 设置繁殖费用
     */
    function setBreedingFee(uint256 newFee) external onlyOwner {
        breedingFee = newFee;
    }

    /**
     * @dev 提取合约余额
     */
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");

        (bool success, ) = payable(owner()).call{value: balance}("");
        require(success, "Withdrawal failed");
    }

    /**
     * @dev 获取总供应量
     */
    function totalSupply() external view returns (uint256) {
        return _tokenIdCounter.current();
    }

    /**
     * @dev 检查NFT是否存在
     */
    function exists(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }

    /**
     * @dev 内部函数：铸造新猫
     */
    function _mintCat(address to, uint256 gene) internal returns (uint256) {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        genes[tokenId] = gene;
        _mint(to, tokenId);

        emit CatMinted(tokenId, gene, to);
        return tokenId;
    }

    /**
     * @dev 内部函数：生成随机基因
     * @param nonce 随机数种子
     */
    function _generateRandomGene(uint256 nonce) internal view returns (uint256) {
        uint256 randomValue = uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.difficulty,
            msg.sender,
            nonce
        )));

        uint256 gene = 0;
        // 生成64个4-bit像素值
        for (uint256 i = 0; i < 64; i++) {
            uint256 pixelValue = (randomValue >> (i * 4)) & 0xF;
            gene |= (pixelValue << (i * 4));
        }

        return gene;
    }

    /**
     * @dev 内部函数：繁殖基因算法
     * @param gene1 父亲基因
     * @param gene2 母亲基因
     * @param nonce 随机种子
     */
    function _breedGenes(uint256 gene1, uint256 gene2, uint256 nonce) internal view returns (uint256) {
        uint256 randomSeed = uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.difficulty,
            gene1,
            gene2,
            nonce
        )));

        uint256 newGene = 0;

        // 逐像素处理64个像素
        for (uint256 i = 0; i < 64; i++) {
            uint256 pixel1 = (gene1 >> (i * 4)) & 0xF;
            uint256 pixel2 = (gene2 >> (i * 4)) & 0xF;
            uint256 random = (randomSeed >> (i * 4)) & 0xF;

            uint256 newPixel;

            // 1-5%概率突变
            if (random == 0) { // ~6.25%概率突变
                newPixel = random & 0xF;
            }
            // 随机选择父母基因
            else if (random % 2 == 0) {
                newPixel = pixel1;
            } else {
                newPixel = pixel2;
            }

            newGene |= (newPixel << (i * 4));
        }

        return newGene;
    }

    /**
     * @dev 获取调色板
     */
    function getPalette() external view returns (string[16] memory) {
        return palette;
    }
}