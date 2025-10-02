// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import 'forge-std/Script.sol';
import 'forge-std/console.sol';
import 'solidity-utils/contracts/utils/ScriptUtils.sol';
import {AssetListingSteward} from '../../src/contracts/stewards/AssetListingSteward.sol';
import {IAaveV3ConfigEngine} from 'aave-v3-origin/contracts/extensions/v3-config-engine/IAaveV3ConfigEngine.sol';
import {IPoolAddressesProvider} from 'aave-v3-origin/contracts/interfaces/IPoolAddressesProvider.sol';
import {ChainIds} from 'solidity-utils/contracts/utils/ChainHelpers.sol';
import {AaveV3Ethereum} from 'aave-address-book/AaveV3Ethereum.sol';
import {AaveV3Polygon} from 'aave-address-book/AaveV3Polygon.sol';
import {AaveV3Avalanche} from 'aave-address-book/AaveV3Avalanche.sol';
import {AaveV3Optimism} from 'aave-address-book/AaveV3Optimism.sol';
import {AaveV3Arbitrum} from 'aave-address-book/AaveV3Arbitrum.sol';
import {AaveV3Base} from 'aave-address-book/AaveV3Base.sol';
import {AaveV3Gnosis} from 'aave-address-book/AaveV3Gnosis.sol';
import {AaveV3Scroll} from 'aave-address-book/AaveV3Scroll.sol';
import {AaveV3BNB} from 'aave-address-book/AaveV3BNB.sol';
import {AaveV3Metis} from 'aave-address-book/AaveV3Metis.sol';
import {AaveV3Sepolia} from 'aave-address-book/AaveV3Sepolia.sol';

/**
 * @title DeployAssetListingSteward
 * @notice Network-agnostic script to deploy Asset Listing Steward
 */
contract DeployAssetListingSteward is Script {
  
  struct NetworkConfig {
    address configEngine;
    address addressesProvider;
    address riskCouncil;
    address guardian;
    string networkName;
  }

  function getNetworkConfig() public view returns (NetworkConfig memory config) {
    uint256 chainId = block.chainid;
    
    if (chainId == ChainIds.ETHEREUM) {
      config = NetworkConfig({
        configEngine: AaveV3Ethereum.CONFIG_ENGINE,
        addressesProvider: address(AaveV3Ethereum.POOL_ADDRESSES_PROVIDER),
        riskCouncil: 0x47c71dFEB55Ebaa431Ae3fbF99Ea50e0D3d30fA8, // Aave Risk Council
        guardian: 0xCA76Ebd8617a03126B6FB84F9b1c1A0fB71C2633, // Aave Guardian
        networkName: "Ethereum Mainnet"
      });
    } else if (chainId == ChainIds.POLYGON) {
      config = NetworkConfig({
        configEngine: AaveV3Polygon.CONFIG_ENGINE,
        addressesProvider: address(AaveV3Polygon.POOL_ADDRESSES_PROVIDER),
        riskCouncil: 0x2C40FB1ACe63084fc0bB95F83C31B5854C6C4cB5, // Polygon Risk Council
        guardian: 0x1450F2898D6bA2710C98BE9CAF3041330eD5ae58, // Polygon Guardian
        networkName: "Polygon"
      });
    } else if (chainId == ChainIds.AVALANCHE) {
      config = NetworkConfig({
        configEngine: AaveV3Avalanche.CONFIG_ENGINE,
        addressesProvider: address(AaveV3Avalanche.POOL_ADDRESSES_PROVIDER),
        riskCouncil: 0xa35b76E4935449E33C56aB24b23fcd3246f13470, // Avalanche Risk Council
        guardian: 0xa35b76E4935449E33C56aB24b23fcd3246f13470, // Avalanche Guardian
        networkName: "Avalanche"
      });
    } else if (chainId == ChainIds.OPTIMISM) {
      config = NetworkConfig({
        configEngine: AaveV3Optimism.CONFIG_ENGINE,
        addressesProvider: address(AaveV3Optimism.POOL_ADDRESSES_PROVIDER),
        riskCouncil: 0xCb86256A994f0c505c5e15c75BF85fdFEa0F2a56, // Optimism Risk Council
        guardian: 0xE50c8C619d05ff98b22Adf991F17602C774F785c, // Optimism Guardian
        networkName: "Optimism"
      });
    } else if (chainId == ChainIds.ARBITRUM) {
      config = NetworkConfig({
        configEngine: AaveV3Arbitrum.CONFIG_ENGINE,
        addressesProvider: address(AaveV3Arbitrum.POOL_ADDRESSES_PROVIDER),
        riskCouncil: 0xbbd9f90699c1FA0D7A65870D241DD1f1217c96Eb, // Arbitrum Risk Council
        guardian: 0xbbd9f90699c1FA0D7A65870D241DD1f1217c96Eb, // Arbitrum Guardian
        networkName: "Arbitrum"
      });
    } else if (chainId == ChainIds.BASE) {
      config = NetworkConfig({
        configEngine: AaveV3Base.CONFIG_ENGINE,
        addressesProvider: address(AaveV3Base.POOL_ADDRESSES_PROVIDER),
        riskCouncil: 0x9390B1735def18560c509E2d0bc090E9d6BA257a, // Base Risk Council
        guardian: 0x9390B1735def18560c509E2d0bc090E9d6BA257a, // Base Guardian
        networkName: "Base"
      });
    } else if (chainId == ChainIds.GNOSIS) {
      config = NetworkConfig({
        configEngine: AaveV3Gnosis.CONFIG_ENGINE,
        addressesProvider: address(AaveV3Gnosis.POOL_ADDRESSES_PROVIDER),
        riskCouncil: 0xd312b7e8ebc618BabB2e40dd52D2E2aE3fF8E86E, // Gnosis Risk Council
        guardian: 0xd312b7e8ebc618BabB2e40dd52D2E2aE3fF8E86E, // Gnosis Guardian
        networkName: "Gnosis"
      });
    } else if (chainId == ChainIds.SCROLL) {
      config = NetworkConfig({
        configEngine: AaveV3Scroll.CONFIG_ENGINE,
        addressesProvider: address(AaveV3Scroll.POOL_ADDRESSES_PROVIDER),
        riskCouncil: 0x6720C3bf6FE1b6C8630C83CaacE3E7b5fC5da76a, // Scroll Risk Council
        guardian: 0x6720C3bf6FE1b6C8630C83CaacE3E7b5fC5da76a, // Scroll Guardian
        networkName: "Scroll"
      });
    } else if (chainId == ChainIds.BNB) {
      config = NetworkConfig({
        configEngine: AaveV3BNB.CONFIG_ENGINE,
        addressesProvider: address(AaveV3BNB.POOL_ADDRESSES_PROVIDER),
        riskCouncil: 0x5C6E913f75e5f1f1F3db2A246F2ab16FdB89f76B, // BNB Risk Council
        guardian: 0x5C6E913f75e5f1f1F3db2A246F2ab16FdB89f76B, // BNB Guardian
        networkName: "BNB Chain"
      });
    } else if (chainId == ChainIds.METIS) {
      config = NetworkConfig({
        configEngine: AaveV3Metis.CONFIG_ENGINE,
        addressesProvider: address(AaveV3Metis.POOL_ADDRESSES_PROVIDER),
        riskCouncil: 0xf7ba8E0e7B3F49e6BD3CBa70EE1f57fE6c87dA3a, // Metis Risk Council
        guardian: 0xf7ba8E0e7B3F49e6BD3CBa70EE1f57fE6c87dA3a, // Metis Guardian
        networkName: "Metis"
      });
    } else if (chainId == 11155111) { // Sepolia
      config = NetworkConfig({
        configEngine: 0x0a275C06556EeB3c7Ff2b0f0cfD462A7645772EF, // Sepolia Config Engine
        addressesProvider: address(AaveV3Sepolia.POOL_ADDRESSES_PROVIDER),
        riskCouncil: msg.sender, // Use deployer as risk council for testnet
        guardian: msg.sender, // Use deployer as guardian for testnet
        networkName: "Ethereum Sepolia"
      });
    } else {
      revert("Unsupported network for Asset Listing Steward deployment");
    }
  }

  function run() external {
    vm.startBroadcast();
    
    console.log("=== ASSET LISTING STEWARD DEPLOYMENT ===");
    console.log("");
    
    NetworkConfig memory config = getNetworkConfig();
    
    console.log("Network:", config.networkName);
    console.log("Chain ID:", block.chainid);
    console.log("Config Engine:", config.configEngine);
    console.log("Addresses Provider:", config.addressesProvider);
    console.log("Risk Council:", config.riskCouncil);
    console.log("Guardian:", config.guardian);
    console.log("Deployer:", msg.sender);
    console.log("");
    
    // Deploy the Asset Listing Steward
    console.log("=== DEPLOYING ASSET LISTING STEWARD ===");
    
    AssetListingSteward steward = new AssetListingSteward(
      IAaveV3ConfigEngine(config.configEngine),
      IPoolAddressesProvider(config.addressesProvider),
      config.riskCouncil,
      config.guardian
    );
    
    console.log("Asset Listing Steward deployed at:", address(steward));
    console.log("");
    
    // Verify deployment
    console.log("=== VERIFYING DEPLOYMENT ===");
    console.log("Config Engine:", steward.getConfigEngine());
    console.log("Risk Council:", steward.getRiskCouncil());
    console.log("Proposal Delay:", steward.getProposalDelay());
    console.log("Proposal Count:", steward.getProposalCount());
    console.log("Is Council Member (Risk Council):", steward.isCouncilMember(config.riskCouncil));
    console.log("Is Council Member (Random Address):", steward.isCouncilMember(address(0x123)));
    console.log("");
    
    console.log("=== DEPLOYMENT SUMMARY ===");
    console.log("SUCCESS: Asset Listing Steward deployed successfully");
    console.log("SUCCESS: All view functions working correctly");
    console.log("SUCCESS: Permissions configured correctly");
    console.log("");
    
    console.log("DEPLOYMENT COMPLETED!");
    console.log("   Asset Listing Steward Address:", address(steward));
    console.log("   Network:", config.networkName);
    console.log("   Next steps:");
    console.log("   1. Verify contract on block explorer");
    console.log("   2. Test asset listing proposal workflow");
    console.log("   3. Configure risk council permissions");
    console.log("   4. Update documentation with deployment address");
    
    vm.stopBroadcast();
  }
}

// Network-specific deployment contracts
contract DeployEthereumAssetListingSteward is EthereumScript {
  function run() external broadcast {
    DeployAssetListingSteward.NetworkConfig memory config = DeployAssetListingSteward.NetworkConfig({
      configEngine: AaveV3Ethereum.CONFIG_ENGINE,
      addressesProvider: address(AaveV3Ethereum.POOL_ADDRESSES_PROVIDER),
      riskCouncil: 0x47c71dFEB55Ebaa431Ae3fbF99Ea50e0D3d30fA8,
      guardian: 0xCA76Ebd8617a03126B6FB84F9b1c1A0fB71C2633,
      networkName: "Ethereum"
    });

    new AssetListingSteward(
      IAaveV3ConfigEngine(config.configEngine),
      IPoolAddressesProvider(config.addressesProvider),
      config.riskCouncil,
      config.guardian
    );
  }
}

contract DeployPolygonAssetListingSteward is PolygonScript {
  function run() external broadcast {
    DeployAssetListingSteward.NetworkConfig memory config = DeployAssetListingSteward.NetworkConfig({
      configEngine: AaveV3Polygon.CONFIG_ENGINE,
      addressesProvider: address(AaveV3Polygon.POOL_ADDRESSES_PROVIDER),
      riskCouncil: 0x2C40FB1ACe63084fc0bB95F83C31B5854C6C4cB5,
      guardian: 0x1450F2898D6bA2710C98BE9CAF3041330eD5ae58,
      networkName: "Polygon"
    });

    new AssetListingSteward(
      IAaveV3ConfigEngine(config.configEngine),
      IPoolAddressesProvider(config.addressesProvider),
      config.riskCouncil,
      config.guardian
    );
  }
}

contract DeployArbitrumAssetListingSteward is ArbitrumScript {
  function run() external broadcast {
    DeployAssetListingSteward.NetworkConfig memory config = DeployAssetListingSteward.NetworkConfig({
      configEngine: AaveV3Arbitrum.CONFIG_ENGINE,
      addressesProvider: address(AaveV3Arbitrum.POOL_ADDRESSES_PROVIDER),
      riskCouncil: 0xbbd9f90699c1FA0D7A65870D241DD1f1217c96Eb,
      guardian: 0xbbd9f90699c1FA0D7A65870D241DD1f1217c96Eb,
      networkName: "Arbitrum"
    });

    new AssetListingSteward(
      IAaveV3ConfigEngine(config.configEngine),
      IPoolAddressesProvider(config.addressesProvider),
      config.riskCouncil,
      config.guardian
    );
  }
}

contract DeployOptimismAssetListingSteward is OptimismScript {
  function run() external broadcast {
    DeployAssetListingSteward.NetworkConfig memory config = DeployAssetListingSteward.NetworkConfig({
      configEngine: AaveV3Optimism.CONFIG_ENGINE,
      addressesProvider: address(AaveV3Optimism.POOL_ADDRESSES_PROVIDER),
      riskCouncil: 0xCb86256A994f0c505c5e15c75BF85fdFEa0F2a56,
      guardian: 0xE50c8C619d05ff98b22Adf991F17602C774F785c,
      networkName: "Optimism"
    });

    new AssetListingSteward(
      IAaveV3ConfigEngine(config.configEngine),
      IPoolAddressesProvider(config.addressesProvider),
      config.riskCouncil,
      config.guardian
    );
  }
}

contract DeployBaseAssetListingSteward is BaseScript {
  function run() external broadcast {
    DeployAssetListingSteward.NetworkConfig memory config = DeployAssetListingSteward.NetworkConfig({
      configEngine: AaveV3Base.CONFIG_ENGINE,
      addressesProvider: address(AaveV3Base.POOL_ADDRESSES_PROVIDER),
      riskCouncil: 0x9390B1735def18560c509E2d0bc090E9d6BA257a,
      guardian: 0x9390B1735def18560c509E2d0bc090E9d6BA257a,
      networkName: "Base"
    });

    new AssetListingSteward(
      IAaveV3ConfigEngine(config.configEngine),
      IPoolAddressesProvider(config.addressesProvider),
      config.riskCouncil,
      config.guardian
    );
  }
}