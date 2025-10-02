// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.8;

import {Address} from 'openzeppelin-contracts/contracts/utils/Address.sol';
import {IAaveV3ConfigEngine as IEngine} from 'aave-v3-origin/contracts/extensions/v3-config-engine/IAaveV3ConfigEngine.sol';
import {EngineFlags} from 'aave-v3-origin/contracts/extensions/v3-config-engine/EngineFlags.sol';
import {IPoolAddressesProvider} from 'aave-v3-origin/contracts/interfaces/IPoolAddressesProvider.sol';
import {Errors} from '../../src/contracts/libraries/Errors.sol';
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
import '../GovBaseScript.sol';

/**
 * @title AssetListingPayload
 * @author BGD Labs
 * @notice Payload contract for listing new assets on Aave V3 pools
 * @dev This contract follows the Aave V3 payload pattern and includes proper security measures
 * @dev IMPORTANT: This payload inheriting AssetListingPayload MUST BE STATELESS always
 */
abstract contract AssetListingPayload {
  using Address for address;

  event AssetListed(
    address indexed asset,
    address indexed aToken,
    address indexed variableDebtToken,
    address stableDebtToken,
    address interestRateStrategy,
    uint16 referralCode
  );

  event AssetListingFailed(
    address indexed asset,
    string reason
  );

  /// @notice The Aave V3 Config Engine contract
  IEngine public immutable CONFIG_ENGINE;
  
  /// @notice The Pool Addresses Provider
  IPoolAddressesProvider public immutable ADDRESSES_PROVIDER;

  constructor(IEngine configEngine, IPoolAddressesProvider addressesProvider) {
    require(address(configEngine) != address(0), Errors.INVALID_EXECUTION_TARGET);
    require(address(addressesProvider) != address(0), Errors.INVALID_EXECUTION_TARGET);
    
    CONFIG_ENGINE = configEngine;
    ADDRESSES_PROVIDER = addressesProvider;
  }

  /// @dev to be overridden on the child if any extra logic is needed pre-listing
  function _preExecute() internal virtual {}

  /// @dev to be overridden on the child if any extra logic is needed post-listing
  function _postExecute() internal virtual {}

  /// @dev to be overridden on the child if any extra validation is needed
  function _validateAsset(address asset) internal virtual {
    require(asset != address(0), Errors.INVALID_EXECUTION_TARGET);
    // TODO: Add contract validation once import issue is resolved
    // require(asset.isContract(), "Asset must be a contract");
  }

  function execute() external {
    _preExecute();

    IEngine.Listing[] memory listings = newListings();
    
    if (listings.length == 0) {
      revert(Errors.NO_ASSETS_TO_LIST);
    }

    // Validate all assets before execution
    for (uint256 i = 0; i < listings.length; i++) {
      _validateAsset(listings[i].asset);
    }

    try CONFIG_ENGINE.listAssets(getPoolContext(), listings) {
      // Emit success events for each listed asset
      for (uint256 i = 0; i < listings.length; i++) {
        emit AssetListed(
          listings[i].asset,
          address(0), // aToken address will be determined by the engine
          address(0), // variableDebtToken address will be determined by the engine
          address(0), // stableDebtToken address will be determined by the engine
          address(0), // interestRateStrategy address will be determined by the engine
          0 // referralCode
        );
      }
    } catch Error(string memory reason) {
      // Emit failure events for each asset
      for (uint256 i = 0; i < listings.length; i++) {
        emit AssetListingFailed(listings[i].asset, reason);
      }
      revert(reason);
    } catch {
      // Emit failure events for each asset with generic reason
      for (uint256 i = 0; i < listings.length; i++) {
        emit AssetListingFailed(listings[i].asset, Errors.ASSET_LISTING_FAILED);
      }
      revert(Errors.ASSET_LISTING_FAILED);
    }

    _postExecute();
  }

  /// @dev to be defined in the child with a list of new assets to list
  function newListings() public view virtual returns (IEngine.Listing[] memory);

  /// @dev to be defined in the child with the pool context
  function getPoolContext() public view virtual returns (IEngine.PoolContext memory);

  /// @dev Helper function to get the pool from addresses provider
  function _getPool() internal view returns (address) {
    return ADDRESSES_PROVIDER.getPool();
  }

  /// @dev Helper function to get the pool configurator from addresses provider
  function _getPoolConfigurator() internal view returns (address) {
    return ADDRESSES_PROVIDER.getPoolConfigurator();
  }

  /// @dev Helper function to get the ACL manager from addresses provider
  function _getACLManager() internal view returns (address) {
    return ADDRESSES_PROVIDER.getACLManager();
  }
}

/**
 * @title NetworkAgnosticAssetListingPayload  
 * @notice Network-agnostic deployment script using Aave Address Book
 * @dev Automatically resolves addresses based on TRANSACTION_NETWORK() using established patterns
 */
abstract contract NetworkAgnosticAssetListingPayload is GovBaseScript {
  
  /// @notice Get the Aave V3 Config Engine for the current network
  function getConfigEngine() public view returns (address) {
    uint256 chainId = TRANSACTION_NETWORK();
    
    if (chainId == ChainIds.ETHEREUM) {
      return AaveV3Ethereum.CONFIG_ENGINE;
    } else if (chainId == ChainIds.POLYGON) {
      return AaveV3Polygon.CONFIG_ENGINE;
    } else if (chainId == ChainIds.AVALANCHE) {
      return AaveV3Avalanche.CONFIG_ENGINE;
    } else if (chainId == ChainIds.OPTIMISM) {
      return AaveV3Optimism.CONFIG_ENGINE;
    } else if (chainId == ChainIds.ARBITRUM) {
      return AaveV3Arbitrum.CONFIG_ENGINE;
    } else if (chainId == ChainIds.BASE) {
      return AaveV3Base.CONFIG_ENGINE;
    } else if (chainId == ChainIds.GNOSIS) {
      return AaveV3Gnosis.CONFIG_ENGINE;
    } else if (chainId == ChainIds.SCROLL) {
      return AaveV3Scroll.CONFIG_ENGINE;
    } else if (chainId == ChainIds.BNB) {
      return AaveV3BNB.CONFIG_ENGINE;
    } else if (chainId == ChainIds.METIS) {
      return AaveV3Metis.CONFIG_ENGINE;
    } else {
      revert(Errors.UNSUPPORTED_NETWORK_FOR_AAVE_V3);
    }
  }
  
  /// @notice Get the Pool Addresses Provider for the current network
  function getAddressesProvider() public view returns (address) {
    uint256 chainId = TRANSACTION_NETWORK();
    
    if (chainId == ChainIds.ETHEREUM) {
      return address(AaveV3Ethereum.POOL_ADDRESSES_PROVIDER);
    } else if (chainId == ChainIds.POLYGON) {
      return address(AaveV3Polygon.POOL_ADDRESSES_PROVIDER);
    } else if (chainId == ChainIds.AVALANCHE) {
      return address(AaveV3Avalanche.POOL_ADDRESSES_PROVIDER);
    } else if (chainId == ChainIds.OPTIMISM) {
      return address(AaveV3Optimism.POOL_ADDRESSES_PROVIDER);
    } else if (chainId == ChainIds.ARBITRUM) {
      return address(AaveV3Arbitrum.POOL_ADDRESSES_PROVIDER);
    } else if (chainId == ChainIds.BASE) {
      return address(AaveV3Base.POOL_ADDRESSES_PROVIDER);
    } else if (chainId == ChainIds.GNOSIS) {
      return address(AaveV3Gnosis.POOL_ADDRESSES_PROVIDER);
    } else if (chainId == ChainIds.SCROLL) {
      return address(AaveV3Scroll.POOL_ADDRESSES_PROVIDER);
    } else if (chainId == ChainIds.BNB) {
      return address(AaveV3BNB.POOL_ADDRESSES_PROVIDER);
    } else if (chainId == ChainIds.METIS) {
      return address(AaveV3Metis.POOL_ADDRESSES_PROVIDER);
    } else {
      revert(Errors.UNSUPPORTED_NETWORK_FOR_AAVE_V3);
    }
  }
  
  function _execute(
    GovDeployerHelpers.Addresses memory addresses
  ) internal override {
    address configEngine = getConfigEngine();
    address addressesProvider = getAddressesProvider();
    
    require(configEngine != address(0), "Config engine address must be set");
    require(addressesProvider != address(0), "Addresses provider must be set");
    
    // Deploy the concrete payload implementation
    new AssetListingPayloadImpl(
      IEngine(configEngine),
      IPoolAddressesProvider(addressesProvider)
    );
  }
}

/**
 * @title DeployEthereumAssetListingPayload
 * @notice Ethereum mainnet asset listing payload deployment
 */
contract DeployEthereumAssetListingPayload is NetworkAgnosticAssetListingPayload {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.ETHEREUM;
  }
}

/**
 * @title DeployPolygonAssetListingPayload
 * @notice Polygon asset listing payload deployment
 */
contract DeployPolygonAssetListingPayload is NetworkAgnosticAssetListingPayload {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.POLYGON;
  }
}

/**
 * @title DeployArbitrumAssetListingPayload
 * @notice Arbitrum asset listing payload deployment
 */
contract DeployArbitrumAssetListingPayload is NetworkAgnosticAssetListingPayload {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.ARBITRUM;
  }
}

/**
 * @title DeployOptimismAssetListingPayload
 * @notice Optimism asset listing payload deployment
 */
contract DeployOptimismAssetListingPayload is NetworkAgnosticAssetListingPayload {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.OPTIMISM;
  }
}

/**
 * @title DeployAvalancheAssetListingPayload
 * @notice Avalanche asset listing payload deployment
 */
contract DeployAvalancheAssetListingPayload is NetworkAgnosticAssetListingPayload {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.AVALANCHE;
  }
}

/**
 * @title DeployBaseAssetListingPayload
 * @notice Base asset listing payload deployment
 */
contract DeployBaseAssetListingPayload is NetworkAgnosticAssetListingPayload {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.BASE;
  }
}

/**
 * @title AssetListingPayloadImpl
 * @notice Concrete implementation of AssetListingPayload for deployment
 * @dev This is a template implementation - in practice, you would create specific implementations
 *      for each asset listing with the actual asset addresses and configurations
 */
contract AssetListingPayloadImpl is AssetListingPayload {
  // Example implementation - in practice, these would be set in the constructor
  // or through a more sophisticated configuration system
  
  constructor(
    IEngine configEngine,
    IPoolAddressesProvider addressesProvider
  ) AssetListingPayload(configEngine, addressesProvider) {}

  function newListings() public view override returns (IEngine.Listing[] memory) {
    // This should be overridden in actual implementations
    // Example structure:
    /*
    IEngine.Listing[] memory listings = new IEngine.Listing[](1);
    listings[0] = IEngine.Listing({
      asset: address(0x...), // The asset to list
      aTokenImpl: address(0x...), // aToken implementation
      stableDebtTokenImpl: address(0x...), // Stable debt token implementation
      variableDebtTokenImpl: address(0x...), // Variable debt token implementation
      interestRateStrategy: address(0x...), // Interest rate strategy
      treasury: address(0x...), // Treasury address
      referralCode: 0, // Referral code
      enabledToBorrow: EngineFlags.ENABLED, // Borrow enabled
      stableRateModeEnabled: EngineFlags.DISABLED, // Stable rate disabled
      borrowableInIsolation: EngineFlags.DISABLED, // Not borrowable in isolation
      withSiloedBorrowing: EngineFlags.DISABLED, // No siloed borrowing
      flashloanable: EngineFlags.ENABLED, // Flashloan enabled
      ltv: 7500, // 75% LTV
      liqThreshold: 8000, // 80% liquidation threshold
      liqBonus: 500, // 5% liquidation bonus
      reserveFactor: 1000, // 10% reserve factor
      supplyCap: 1000000 * 1e18, // Supply cap
      borrowCap: 800000 * 1e18, // Borrow cap
      debtCeiling: 0, // No debt ceiling
      liqProtocolFee: 1000, // 10% protocol fee
      eModeCategory: 0 // No eMode category
    });
    return listings;
    */
    revert("newListings must be implemented in child contract");
  }

  function getPoolContext() public view override returns (IEngine.PoolContext memory) {
    // This should be overridden in actual implementations
    // Example structure:
    /*
    return IEngine.PoolContext({
      networkBaseTokenPriceInUsd: 2000 * 1e8, // $2000 for ETH
      networkBaseTokenPriceDecimals: 8,
      marketReferenceCurrencyUnit: 1e8,
      marketReferenceCurrencyPriceInUsd: 1 * 1e8 // $1 for USDC
    });
    */
    revert("getPoolContext must be implemented in child contract");
  }
}