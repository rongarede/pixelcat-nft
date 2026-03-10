# PixelCat NFT繁殖游戏 MVP

基于以太坊区块链的像素猫繁殖游戏最小可行版本，用户可以拥有、查看和繁殖独特的8x8像素艺术猫咪。

## 🎮 游戏特性

- **独特基因系统**: 每只猫的基因用uint256编码，代表64个4-bit像素值
- **繁殖机制**: 选择两只猫繁殖，生成具有混合基因的后代
- **突变机制**: 约6.25%概率发生基因突变，创造稀有特征
- **可视化渲染**: Canvas绘制8x8像素网格，16色调色板
- **MetaMask集成**: 无缝Web3钱包连接体验

## 🛠 技术栈

### 智能合约
- **Solidity ^0.8.19**: 智能合约开发语言
- **Foundry**: 开发、测试和部署工具链
- **OpenZeppelin**: ERC-721标准实现

### 前端
- **Next.js 15**: React框架
- **TypeScript**: 类型安全
- **Tailwind CSS**: 样式框架
- **ethers.js v6**: Web3库

## 📁 项目结构

```
nft-project/
├── src/                    # 智能合约源码
│   ├── PixelCat.sol       # 主要NFT合约
│   └── SimpleNFT.sol      # 参考合约
├── script/                 # 部署和交互脚本
│   ├── DeployPixelCat.s.sol
│   ├── Deploy.s.sol
│   └── Interact.s.sol
├── test/                   # 合约测试
├── frontend/               # Next.js前端应用
│   ├── src/
│   │   ├── app/           # Next.js 13+ App Router
│   │   ├── components/    # React组件
│   │   ├── hooks/         # 自定义Hooks
│   │   ├── types/         # TypeScript类型定义
│   │   └── utils/         # 工具函数
│   ├── package.json
│   └── tailwind.config.js
├── foundry.toml           # Foundry配置
└── README.md
```

## 🚀 快速开始

### 1. 环境准备

```bash
# 安装Foundry
curl -L https://foundry.paradigm.xyz | bash
foundryup

# 安装Node.js依赖
cd frontend
npm install
```

### 2. 本地开发

```bash
# 启动本地区块链
anvil

# 部署合约
forge script script/DeployPixelCat.s.sol --broadcast --rpc-url http://127.0.0.1:8545

# 启动前端
cd frontend
npm run dev
```

### 3. 配置前端

复制环境配置文件：
```bash
cp frontend/.env.local.example frontend/.env.local
```

更新合约地址：
```env
NEXT_PUBLIC_PIXEL_CAT_CONTRACT=0x合约地址
```

## 🎯 核心组件

### 智能合约 (`src/PixelCat.sol`)

```solidity
// 主要功能
function breed(uint256 parent1, uint256 parent2) external payable
function getGene(uint256 tokenId) external view returns (uint256)
function ownerMint(address to) external onlyOwner
```

**关键特性:**
- ERC-721标准NFT
- 基因编码/解码系统
- 繁殖算法（继承+突变）
- 事件日志记录

### 前端组件

1. **PixelCatRenderer**: Canvas像素渲染
2. **CatCard**: 猫咪展示卡片
3. **WalletConnector**: MetaMask连接
4. **BreedingInterface**: 繁殖操作界面

### 自定义Hooks

1. **useWallet**: 钱包状态管理
2. **usePixelCat**: 合约交互逻辑

## 🧬 基因系统

每只像素猫的基因由uint256表示：

```
基因值: 0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef
      │  └─┘│  └─┘│  └─┘│  └─┘│  └─┘│  └─┘│  └─┘│  └─┘
      │   像素0  像素1  像素2  像素3  像素4  像素5  像素6  像素7
      └── 64个像素，每个4-bit（0-15），对应16色调色板
```

### 16色调色板
```javascript
['#000000', '#FFFFFF', '#FF0000', '#00FF00',
 '#0000FF', '#FFFF00', '#FF00FF', '#00FFFF',
 '#800000', '#008000', '#000080', '#808000',
 '#800080', '#008080', '#C0C0C0', '#808080']
```

## 🔬 繁殖算法

```solidity
// 逐像素处理
for (uint256 i = 0; i < 64; i++) {
    uint256 pixel1 = (gene1 >> (i * 4)) & 0xF;
    uint256 pixel2 = (gene2 >> (i * 4)) & 0xF;
    uint256 random = (randomSeed >> (i * 4)) & 0xF;

    // 6.25%概率突变
    if (random == 0) {
        newPixel = random & 0xF;
    }
    // 随机继承父母基因
    else if (random % 2 == 0) {
        newPixel = pixel1;
    } else {
        newPixel = pixel2;
    }
}
```

## 🧪 测试

```bash
# 运行合约测试
forge test

# 测试覆盖率
forge coverage

# Gas报告
forge test --gas-report
```

## 🌐 部署

### 本地测试网
```bash
forge script script/DeployPixelCat.s.sol --broadcast --rpc-url http://127.0.0.1:8545
```

### Sepolia测试网
```bash
forge script script/DeployPixelCat.s.sol --broadcast --rpc-url $SEPOLIA_RPC_URL --verify
```

## 📝 使用流程

1. **连接钱包**: 使用MetaMask连接到DApp
2. **获得初始猫**: 点击"免费获得猫咪"按钮
3. **查看收藏**: 在"我的猫咪"标签页查看拥有的NFT
4. **选择繁殖**: 在"繁殖中心"选择两只猫
5. **支付费用**: 确认交易并支付繁殖费用
6. **等待挖矿**: 交易确认后获得新生猫咪

## ⚠️ 重要说明

这是一个MVP版本，专注于核心功能演示：

- **仅支持基础繁殖功能**
- **使用简单的随机数生成**
- **没有高级游戏机制**
- **适合学习Web3开发**

## 🔮 未来扩展

- [ ] 稀有度系统
- [ ] 交易市场
- [ ] 多种动物类型
- [ ] 链上VRF随机数
- [ ] 社区功能
- [ ] 游戏化元素

## 📄 许可证

MIT License - 查看 [LICENSE](LICENSE) 文件了解详情

## 🤝 贡献

欢迎提交Issue和Pull Request！

---

**祝您玩得开心！** 🐱✨