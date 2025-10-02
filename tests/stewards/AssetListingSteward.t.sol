// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.8;

import 'forge-std/Test.sol';
import {AssetListingSteward} from '../../src/contracts/stewards/AssetListingSteward.sol';
import {IAssetListingSteward} from '../../src/contracts/interfaces/IAssetListingSteward.sol';
import {IAaveV3ConfigEngine as IEngine} from 'aave-v3-origin/contracts/extensions/v3-config-engine/IAaveV3ConfigEngine.sol';
import {EngineFlags} from 'aave-v3-origin/contracts/extensions/v3-config-engine/EngineFlags.sol';
import {IPoolAddressesProvider} from 'aave-v3-origin/contracts/interfaces/IPoolAddressesProvider.sol';
import {IPool} from 'aave-v3-origin/contracts/interfaces/IPool.sol';
import {IPoolConfigurator} from 'aave-v3-origin/contracts/interfaces/IPoolConfigurator.sol';
import {IERC20} from 'openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';
import {ERC20} from 'openzeppelin-contracts/contracts/token/ERC20/ERC20.sol';
import {DataTypes} from 'aave-v3-origin/contracts/protocol/libraries/types/DataTypes.sol';
import {Errors} from '../../src/contracts/libraries/Errors.sol';

contract MockERC20 is ERC20 {
  uint8 private _decimals;
  
  constructor(string memory name, string memory symbol, uint8 decimals_) ERC20(name, symbol) {
    _decimals = decimals_;
    _mint(msg.sender, 1000000 * 10**decimals_);
  }
  
  function decimals() public view override returns (uint8) {
    return _decimals;
  }
}

contract MockConfigEngine {
  bool public shouldRevert;
  
  function setShouldRevert(bool _shouldRevert) external {
    shouldRevert = _shouldRevert;
  }
  
  function listAssets(
    IEngine.PoolContext memory,
    IEngine.Listing[] memory
  ) external view {
    if (shouldRevert) {
      revert("Mock config engine error");
    }
  }
  
  function updateCollateralSide(IEngine.CollateralUpdate[] memory) external view {
    if (shouldRevert) {
      revert("Mock config engine error");
    }
  }
  
  function updateCaps(IEngine.CapsUpdate[] memory) external view {
    if (shouldRevert) {
      revert("Mock config engine error");
    }
  }
}

contract MockPool {
  mapping(address => bool) public isListed;
  mapping(address => address) public aTokens;
  
  function setAssetListed(address asset, bool listed, address aToken) external {
    isListed[asset] = listed;
    aTokens[asset] = aToken;
  }
  
  function getReserveData(address asset) external view returns (DataTypes.ReserveDataLegacy memory reserveData) {
    if (!isListed[asset]) {
      revert("Asset not listed");
    }
    reserveData.aTokenAddress = aTokens[asset];
    reserveData.stableDebtTokenAddress = address(0x2);
    reserveData.variableDebtTokenAddress = address(0x3);
    reserveData.currentLiquidityRate = 0;
    reserveData.currentVariableBorrowRate = 0;
    reserveData.currentStableBorrowRate = 0;
    reserveData.lastUpdateTimestamp = uint40(block.timestamp);
    reserveData.liquidityIndex = 1e27;
    reserveData.variableBorrowIndex = 1e27;
  }
}

contract MockPoolConfigurator {
  mapping(address => bool) public frozenAssets;
  
  function setReserveFreeze(address asset, bool freeze) external {
    frozenAssets[asset] = freeze;
  }
  
  function isReserveFrozen(address asset) external view returns (bool) {
    return frozenAssets[asset];
  }
}

contract MockAddressesProvider {
  address public pool;
  address public poolConfigurator;
  
  constructor(address _pool, address _poolConfigurator) {
    pool = _pool;
    poolConfigurator = _poolConfigurator;
  }
  
  function getPool() external view returns (address) {
    return pool;
  }
  
  function getPoolConfigurator() external view returns (address) {
    return poolConfigurator;
  }
}

contract AssetListingStewardTest is Test {
  AssetListingSteward public steward;
  MockConfigEngine public configEngine;
  MockAddressesProvider public addressesProvider;
  MockPool public pool;
  MockPoolConfigurator public poolConfigurator;
  MockERC20 public testAsset;
  
  address public constant RISK_COUNCIL = address(0x123);
  address public constant GUARDIAN = address(0x456);
  address public constant USER = address(0x789);
  
  event AssetListingProposed(
    address indexed asset,
    address indexed proposer,
    uint256 indexed proposalId
  );
  
  event AssetListingApproved(
    address indexed asset,
    address indexed aToken,
    address indexed variableDebtToken,
    address stableDebtToken,
    address council
  );
  
  event AssetListingCancelled(
    address indexed asset,
    uint256 indexed proposalId,
    address indexed canceller
  );
  
  event AssetRiskParametersUpdated(
    address indexed asset,
    address indexed council
  );
  
  event AssetEmergencyFrozen(
    address indexed asset,
    address indexed council
  );

  function setUp() public {
    // Deploy mocks
    configEngine = new MockConfigEngine();
    pool = new MockPool();
    poolConfigurator = new MockPoolConfigurator();
    addressesProvider = new MockAddressesProvider(address(pool), address(poolConfigurator));
    
    // Deploy test asset
    testAsset = new MockERC20("Test Token", "TEST", 18);
    
    // Deploy steward
    steward = new AssetListingSteward(
      IEngine(address(configEngine)),
      IPoolAddressesProvider(address(addressesProvider)),
      RISK_COUNCIL,
      GUARDIAN
    );
  }

  function testDeployment() public view {
    assertEq(address(steward.CONFIG_ENGINE()), address(configEngine));
    assertEq(steward.getRiskCouncil(), RISK_COUNCIL);
    assertEq(steward.getConfigEngine(), address(configEngine));
    assertEq(steward.getProposalDelay(), 24 hours);
    assertEq(steward.getProposalCount(), 0);
    assertTrue(steward.isCouncilMember(RISK_COUNCIL));
    assertFalse(steward.isCouncilMember(USER));
  }

  function testProposeAssetListing() public {
    IEngine.Listing memory listing = _createTestListing();
    IEngine.PoolContext memory poolContext = _createTestPoolContext();
    
    vm.expectEmit(true, true, true, true);
    emit AssetListingProposed(address(testAsset), USER, 1);
    
    vm.prank(USER);
    uint256 proposalId = steward.proposeAssetListing(listing, poolContext);
    
    assertEq(proposalId, 1);
    assertEq(steward.getProposalCount(), 1);
    
    IAssetListingSteward.AssetListingProposal memory proposal = steward.getProposal(proposalId);
    assertEq(proposal.asset, address(testAsset));
    assertEq(proposal.proposer, USER);
    assertEq(proposal.proposedAt, block.timestamp);
    assertFalse(proposal.executed);
    assertFalse(proposal.cancelled);
  }

  function testProposeAssetListingInvalidAsset() public {
    IEngine.Listing memory listing = _createTestListing();
    listing.asset = address(0);
    IEngine.PoolContext memory poolContext = _createTestPoolContext();
    
    vm.prank(USER);
    vm.expectRevert("ZERO_ADDRESS");
    steward.proposeAssetListing(listing, poolContext);
  }

  function testProposeAssetListingAlreadyListed() public {
    // Mark asset as already listed
    pool.setAssetListed(address(testAsset), true, address(0x1));
    
    IEngine.Listing memory listing = _createTestListing();
    IEngine.PoolContext memory poolContext = _createTestPoolContext();
    
    // The steward allows proposals for already listed assets 
    // (config engine will handle duplicate detection)
    vm.prank(USER);
    uint256 proposalId = steward.proposeAssetListing(listing, poolContext);
    
    assertEq(proposalId, 1);
    assertEq(steward.getProposalCount(), 1);
  }

  function testApproveAssetListing() public {
    // Create proposal
    IEngine.Listing memory listing = _createTestListing();
    IEngine.PoolContext memory poolContext = _createTestPoolContext();
    
    vm.prank(USER);
    uint256 proposalId = steward.proposeAssetListing(listing, poolContext);
    
    // Fast forward past delay
    vm.warp(block.timestamp + 24 hours + 1);
    
    // Mock the asset listing result
    pool.setAssetListed(address(testAsset), true, address(0x1));
    
    vm.expectEmit(true, true, true, true);
    emit AssetListingApproved(address(testAsset), address(0x1), address(0x3), address(0x2), RISK_COUNCIL);
    
    vm.prank(RISK_COUNCIL);
    steward.approveAssetListing(proposalId);
    
    IAssetListingSteward.AssetListingProposal memory proposal = steward.getProposal(proposalId);
    assertTrue(proposal.executed);
  }

  function testApproveAssetListingUnauthorized() public {
    // Create proposal
    IEngine.Listing memory listing = _createTestListing();
    IEngine.PoolContext memory poolContext = _createTestPoolContext();
    
    vm.prank(USER);
    uint256 proposalId = steward.proposeAssetListing(listing, poolContext);
    
    vm.warp(block.timestamp + 24 hours + 1);
    
    vm.prank(USER);
    vm.expectRevert("INVALID_CALLER");
    steward.approveAssetListing(proposalId);
  }

  function testApproveAssetListingDelayNotMet() public {
    // Create proposal
    IEngine.Listing memory listing = _createTestListing();
    IEngine.PoolContext memory poolContext = _createTestPoolContext();
    
    vm.prank(USER);
    uint256 proposalId = steward.proposeAssetListing(listing, poolContext);
    
    // Don't wait for delay
    vm.prank(RISK_COUNCIL);
    vm.expectRevert("PROPOSAL_DELAY_NOT_MET");
    steward.approveAssetListing(proposalId);
  }

  function testCancelAssetListing() public {
    // Create proposal
    IEngine.Listing memory listing = _createTestListing();
    IEngine.PoolContext memory poolContext = _createTestPoolContext();
    
    vm.prank(USER);
    uint256 proposalId = steward.proposeAssetListing(listing, poolContext);
    
    vm.expectEmit(true, true, true, true);
    emit AssetListingCancelled(address(testAsset), proposalId, USER);
    
    // Proposer can cancel
    vm.prank(USER);
    steward.cancelAssetListing(proposalId);
    
    IAssetListingSteward.AssetListingProposal memory proposal = steward.getProposal(proposalId);
    assertTrue(proposal.cancelled);
  }

  function testCancelAssetListingByRiskCouncil() public {
    // Create proposal
    IEngine.Listing memory listing = _createTestListing();
    IEngine.PoolContext memory poolContext = _createTestPoolContext();
    
    vm.prank(USER);
    uint256 proposalId = steward.proposeAssetListing(listing, poolContext);
    
    // Risk council can cancel
    vm.prank(RISK_COUNCIL);
    steward.cancelAssetListing(proposalId);
    
    IAssetListingSteward.AssetListingProposal memory proposal = steward.getProposal(proposalId);
    assertTrue(proposal.cancelled);
  }

  function testCancelAssetListingByGuardian() public {
    // Create proposal
    IEngine.Listing memory listing = _createTestListing();
    IEngine.PoolContext memory poolContext = _createTestPoolContext();
    
    vm.prank(USER);
    uint256 proposalId = steward.proposeAssetListing(listing, poolContext);
    
    // Guardian can cancel
    vm.prank(GUARDIAN);
    steward.cancelAssetListing(proposalId);
    
    IAssetListingSteward.AssetListingProposal memory proposal = steward.getProposal(proposalId);
    assertTrue(proposal.cancelled);
  }

  function testUpdateRiskParameters() public {
    // Mark asset as listed
    pool.setAssetListed(address(testAsset), true, address(0x1));
    
    IAssetListingSteward.RiskParameterUpdate[] memory updates = new IAssetListingSteward.RiskParameterUpdate[](1);
    updates[0] = IAssetListingSteward.RiskParameterUpdate({
      asset: address(testAsset),
      ltv: 70_00,
      liqThreshold: 75_00,
      liqBonus: 5_00,
      supplyCap: 1000000,
      borrowCap: 800000
    });
    
    vm.expectEmit(true, true, false, false);
    emit AssetRiskParametersUpdated(address(testAsset), RISK_COUNCIL);
    
    vm.prank(RISK_COUNCIL);
    steward.updateRiskParameters(updates);
  }

  function testUpdateRiskParametersUnauthorized() public {
    pool.setAssetListed(address(testAsset), true, address(0x1));
    
    IAssetListingSteward.RiskParameterUpdate[] memory updates = new IAssetListingSteward.RiskParameterUpdate[](1);
    updates[0] = IAssetListingSteward.RiskParameterUpdate({
      asset: address(testAsset),
      ltv: 70_00,
      liqThreshold: 75_00,
      liqBonus: 5_00,
      supplyCap: 1000000,
      borrowCap: 800000
    });
    
    vm.prank(USER);
    vm.expectRevert("INVALID_CALLER");
    steward.updateRiskParameters(updates);
  }

  function testUpdateRiskParametersAssetNotListed() public {
    IAssetListingSteward.RiskParameterUpdate[] memory updates = new IAssetListingSteward.RiskParameterUpdate[](1);
    updates[0] = IAssetListingSteward.RiskParameterUpdate({
      asset: address(testAsset),
      ltv: 70_00,
      liqThreshold: 75_00,
      liqBonus: 5_00,
      supplyCap: 1000000,
      borrowCap: 800000
    });
    
    vm.prank(RISK_COUNCIL);
    vm.expectRevert("Asset not listed");
    steward.updateRiskParameters(updates);
  }

  function testEmergencyFreezeAsset() public {
    // Mark asset as listed
    pool.setAssetListed(address(testAsset), true, address(0x1));
    
    vm.prank(RISK_COUNCIL);
    steward.emergencyFreezeAsset(address(testAsset));
    
    assertTrue(poolConfigurator.frozenAssets(address(testAsset)));
  }

  function testEmergencyFreezeAssetByGuardian() public {
    // Mark asset as listed
    pool.setAssetListed(address(testAsset), true, address(0x1));
    
    vm.prank(GUARDIAN);
    steward.emergencyFreezeAsset(address(testAsset));
    
    assertTrue(poolConfigurator.frozenAssets(address(testAsset)));
  }

  function testEmergencyFreezeAssetUnauthorized() public {
    pool.setAssetListed(address(testAsset), true, address(0x1));
    
    vm.prank(USER);
    vm.expectRevert("INVALID_CALLER");
    steward.emergencyFreezeAsset(address(testAsset));
  }

  function testEmergencyUnfreezeAsset() public {
    // Mark asset as listed and frozen
    pool.setAssetListed(address(testAsset), true, address(0x1));
    poolConfigurator.setReserveFreeze(address(testAsset), true);
    
    vm.prank(RISK_COUNCIL);
    steward.emergencyUnfreezeAsset(address(testAsset));
    
    assertFalse(poolConfigurator.frozenAssets(address(testAsset)));
  }

  function testEmergencyUnfreezeAssetUnauthorized() public {
    pool.setAssetListed(address(testAsset), true, address(0x1));
    
    vm.prank(GUARDIAN);
    vm.expectRevert("INVALID_CALLER");
    steward.emergencyUnfreezeAsset(address(testAsset));
  }

  function testRiskParameterValidation() public {
    IEngine.Listing memory listing = _createTestListing();
    listing.ltv = 80_00; // Higher than max (75%)
    IEngine.PoolContext memory poolContext = _createTestPoolContext();
    
    vm.prank(USER);
    vm.expectRevert("INVALID_LTV");
    steward.proposeAssetListing(listing, poolContext);
  }

  function testLtvHigherThanThreshold() public {
    IEngine.Listing memory listing = _createTestListing();
    listing.ltv = 75_00;
    listing.liqThreshold = 70_00; // Lower than LTV
    IEngine.PoolContext memory poolContext = _createTestPoolContext();
    
    vm.prank(USER);
    vm.expectRevert("LTV_HIGHER_THAN_THRESHOLD");
    steward.proposeAssetListing(listing, poolContext);
  }

  function _createTestListing() internal view returns (IEngine.Listing memory) {
    return IEngine.Listing({
      asset: address(testAsset),
      assetSymbol: 'TEST',
      priceFeed: address(0x1),
      rateStrategyParams: IEngine.InterestRateInputData({
        optimalUsageRatio: 80_00,
        baseVariableBorrowRate: 0,
        variableRateSlope1: 4_00,
        variableRateSlope2: 60_00
      }),
      enabledToBorrow: EngineFlags.DISABLED,
      borrowableInIsolation: EngineFlags.DISABLED,
      withSiloedBorrowing: EngineFlags.DISABLED,
      flashloanable: EngineFlags.ENABLED,
      ltv: 70_00,
      liqThreshold: 75_00,
      liqBonus: 5_00,
      reserveFactor: 10_00,
      supplyCap: 1000000,
      borrowCap: 0,
      debtCeiling: 0,
      liqProtocolFee: 10_00
    });
  }

  function _createTestPoolContext() internal pure returns (IEngine.PoolContext memory) {
    return IEngine.PoolContext({
      networkName: 'Test',
      networkAbbreviation: 'Test'
    });
  }
}