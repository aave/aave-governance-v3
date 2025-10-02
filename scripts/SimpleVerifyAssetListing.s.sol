// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.8;

import 'forge-std/Script.sol';
import 'forge-std/console.sol';
import {IPoolAddressesProvider} from 'aave-v3-origin/contracts/interfaces/IPoolAddressesProvider.sol';
import {IPool} from 'aave-v3-origin/contracts/interfaces/IPool.sol';
import {IERC20Detailed} from 'aave-v3-origin/contracts/dependencies/openzeppelin/contracts/IERC20Detailed.sol';
import {AaveV3Ethereum} from 'aave-address-book/AaveV3Ethereum.sol';
import {AaveV3Sepolia} from 'aave-address-book/AaveV3Sepolia.sol';
import {ChainIds} from 'solidity-utils/contracts/utils/ChainHelpers.sol';

/**
 * @title SimpleVerifyAssetListing
 * @notice Simplified script to verify an asset listing in Aave V3
 */
contract SimpleVerifyAssetListing is Script {
  
  function getNetworkAddresses() public view returns (address pool, string memory networkName) {
    uint256 chainId = block.chainid;
    
    if (chainId == ChainIds.ETHEREUM) {
      return (address(AaveV3Ethereum.POOL), "Ethereum Mainnet");
    } else if (chainId == 11155111) { // Sepolia
      return (address(AaveV3Sepolia.POOL), "Ethereum Sepolia");
    } else {
      revert("Unsupported network");
    }
  }
  
  function verifyAsset(address asset) external view {
    (address poolAddress, string memory networkName) = getNetworkAddresses();
    
    console.log("=== AAVE V3 ASSET VERIFICATION ===");
    console.log("Network:", networkName);
    console.log("Asset Address:", asset);
    console.log("Pool Address:", poolAddress);
    console.log("");
    
    IPool pool = IPool(poolAddress);
    
    // Get token details
    IERC20Detailed token = IERC20Detailed(asset);
    string memory name = "";
    string memory symbol = "";
    uint8 tokenDecimals = 0;
    
    try token.name() returns (string memory tokenName) {
      name = tokenName;
    } catch {}
    
    try token.symbol() returns (string memory tokenSymbol) {
      symbol = tokenSymbol;
    } catch {}
    
    try token.decimals() returns (uint8 tokenDecimalsValue) {
      tokenDecimals = tokenDecimalsValue;
    } catch {}
    
    console.log("=== TOKEN INFORMATION ===");
    console.log("Name:", name);
    console.log("Symbol:", symbol);
    console.log("Decimals:", tokenDecimals);
    console.log("");
    
    // Check if asset is listed (simple check)
    console.log("=== AAVE INTEGRATION STATUS ===");
    try pool.getReserveData(asset) {
      console.log("Status: LISTED in Aave");
      console.log("Note: Asset found in Aave pool");
    } catch {
      console.log("Status: NOT LISTED in Aave");
      console.log("Note: Asset not found or error reading data");
    }
    
    console.log("");
    console.log("=== VERIFICATION COMPLETE ===");
  }
  
  function run() external view {
    // Example verification - replace with actual asset address
    address asset;
    uint256 chainId = block.chainid;
    
    if (chainId == ChainIds.ETHEREUM) {
      asset = 0xa0b86a33e6f8e34c0e8a3fc5dC8af3D5A8b8C3E2; // Example address
      console.log("Verifying example asset on Ethereum Mainnet");
    } else if (chainId == 11155111) { // Sepolia
      asset = 0x1234567890123456789012345678901234567890; // Example address
      console.log("Verifying example asset on Sepolia");
    } else {
      revert("Please specify an asset address for this network");
    }
    
    this.verifyAsset(asset);
  }
  
  // Helper function to verify a specific asset address
  function runWithAsset(address asset) external view {
    this.verifyAsset(asset);
  }
}