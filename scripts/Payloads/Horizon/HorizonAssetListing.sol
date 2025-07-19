// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {console2 as console} from 'forge-std/console2.sol';

import {ACLManager} from 'lib/adi-deploy/lib/aave-helpers/lib/aave-address-book/lib/aave-v3-origin/src/contracts/protocol/configuration/ACLManager.sol';
import {IPoolConfigurator} from 'lib/adi-deploy/lib/aave-helpers/lib/aave-address-book/lib/aave-v3-origin/src/contracts/interfaces/IPoolConfigurator.sol';
import {IAaveV3ConfigEngine as IEngine} from 'lib/adi-deploy/lib/aave-helpers/lib/aave-address-book/lib/aave-v3-origin/src/contracts/extensions/v3-config-engine/IAaveV3ConfigEngine.sol';
import {EngineFlags} from 'lib/adi-deploy/lib/aave-helpers/lib/aave-address-book/lib/aave-v3-origin/src/contracts/extensions/v3-config-engine/EngineFlags.sol';
import {AaveV3Payload} from 'lib/adi-deploy/lib/aave-helpers/lib/aave-address-book/lib/aave-v3-origin/src/contracts/extensions/v3-config-engine/AaveV3Payload.sol';

contract HorizonAssetListing is AaveV3Payload {
  bytes32 public constant RISK_ADMIN_ROLE = keccak256('RISK_ADMIN');
  bytes32 public constant ASSET_LISTING_ADMIN_ROLE =
    keccak256('ASSET_LISTING_ADMIN');

  address public constant ATOKEN_IMPLEMENTATION =
    0xa592C7900fDD6fb4019a93E50DF3fE664b569151; // Horizon PROD vtestnet
  address public constant RWA_ATOKEN_IMPLEMENTATION =
    0x8941D6c373ff55a5a5615920CEF589FA4c200277; // Horizon PROD vtestnet
  address public constant VARIABLE_DEBT_TOKEN_IMPLEMENTATION =
    0x2096537dbFF6E0950d68c41927091e303ecC1579; // Horizon PROD vtestnet
  address public constant ACL_MANAGER =
    0x9Cfbd85499cb3c8d58AA2B186A3865071A1fa963; // Horizon PROD vtestnet

  address public constant ASSET_ADDRESS =
    0x7712c34205737192402172409a8F7ccef8aA2AEc; // BUIDL
  address public constant ASSET_PRICE_FEED =
    0xb9BD795BB71012c0F3cd1D9c9A4c686F2d3524A4; // BUIDL
  string public constant ASSET_SYMBOL = 'BUIDL';

  constructor(address configEngine) AaveV3Payload(IEngine(configEngine)) {}

  // new custom asset listing
  function newListingsCustom()
    public
    view
    override
    returns (IEngine.ListingWithCustomImpl[] memory)
  {
    IEngine.ListingWithCustomImpl[]
      memory listingsCustom = new IEngine.ListingWithCustomImpl[](1);

    listingsCustom[0] = IEngine.ListingWithCustomImpl(
      IEngine.Listing({
        asset: ASSET_ADDRESS,
        assetSymbol: ASSET_SYMBOL,
        priceFeed: ASSET_PRICE_FEED,
        rateStrategyParams: IEngine.InterestRateInputData({
          optimalUsageRatio: 92_50,
          baseVariableBorrowRate: 0,
          variableRateSlope1: 5_50,
          variableRateSlope2: 35_00
        }),
        enabledToBorrow: EngineFlags.DISABLED,
        borrowableInIsolation: EngineFlags.DISABLED,
        withSiloedBorrowing: EngineFlags.DISABLED,
        flashloanable: EngineFlags.DISABLED,
        ltv: 75_00,
        liqThreshold: 80_00,
        liqBonus: 12_00,
        reserveFactor: 15_00,
        supplyCap: 5_000_000,
        borrowCap: 0,
        debtCeiling: 0,
        liqProtocolFee: 0
      }),
      IEngine.TokenImplementations({
        aToken: ATOKEN_IMPLEMENTATION,
        vToken: VARIABLE_DEBT_TOKEN_IMPLEMENTATION
      })
    );

    return listingsCustom;
  }

  function getPoolContext()
    public
    pure
    override
    returns (IEngine.PoolContext memory)
  {
    return
      IEngine.PoolContext({
        networkName: 'Horizon RWA',
        networkAbbreviation: 'HorRwa'
      });
  }

  // optional
  function _postExecute() internal override {
    ACLManager(ACL_MANAGER).renounceRole(RISK_ADMIN_ROLE, address(this));
    ACLManager(ACL_MANAGER).renounceRole(
      ASSET_LISTING_ADMIN_ROLE,
      address(this)
    );
  }
}
