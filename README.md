# PixelCat NFT

An on-chain NFT breeding game built on EVM with genetic encoding and mutation mechanics.

## Overview

PixelCat is an ERC-721 NFT project where each cat's appearance is determined by on-chain gene data. Cats can breed to produce offspring with inherited and mutated genes.

- **64-pixel canvas** with 4-bit gene encoding (16-color palette)
- **6.25% mutation rate** per pixel during breeding
- **On-chain gene storage** as `uint256`
- **Full-stack DApp** with Next.js frontend and Canvas rendering

## Tech Stack

- **Smart Contract**: Solidity 0.8+ / OpenZeppelin (ERC721, Ownable)
- **Testing**: Foundry (forge test) — 14 unit tests + 1 fuzz test
- **Frontend**: Next.js + ethers.js v6 + HTML Canvas
- **Tooling**: Foundry (forge/cast/anvil), Hardhat (alternative)

## Project Structure

```
src/PixelCat.sol          # Core ERC-721 contract with breeding logic
test/PixelCat.t.sol       # Comprehensive Foundry test suite
script/DeployPixelCat.s.sol  # Deployment script
pixelcat-dapp/            # Next.js frontend DApp
  packages/nextjs/        # React components (BreedingPanel, CatDisplay, GeneRenderer)
```

## Core Mechanics

### Gene Encoding
Each cat stores a `uint256` gene representing 64 pixels x 4 bits. During breeding, each pixel is randomly inherited from one parent, with a 6.25% chance of mutation.

### Breeding
```solidity
function breed(uint256 parent1, uint256 parent2) external payable returns (uint256)
```
- Both parents must be owned by the caller
- Breeding fee: 0.001 ETH (configurable by owner)
- Offspring gene is deterministically derived from parent genes + block data

## Quick Start

```bash
# Build & test
forge build
forge test -vvv

# Deploy locally
anvil &
forge script script/DeployPixelCat.s.sol --rpc-url http://localhost:8545 --broadcast

# Frontend
cd pixelcat-dapp
yarn install
yarn start
```

## License

MIT
