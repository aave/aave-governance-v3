// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {console2 as console} from 'forge-std/console2.sol';
import {Test} from 'forge-std/Test.sol';

import {IPayloadsControllerCore} from '../../src/contracts/payloads/interfaces/IPayloadsControllerCore.sol';
import {IPermissionedPayloadsController, PermissionedPayloadsController} from '../../src/contracts/payloads/PermissionedPayloadsController.sol';
import {PayloadsControllerUtils} from '../../src/contracts/payloads/PayloadsControllerUtils.sol';
import {TransparentProxyFactory} from 'solidity-utils/contracts/transparent-proxy/TransparentProxyFactory.sol';
import {Errors} from '../../src/contracts/libraries/Errors.sol';
import {Executor, IExecutor, Ownable} from '../../src/contracts/payloads/Executor.sol';

import {HorizonAssetListing} from '../../scripts/Payloads/Horizon/HorizonAssetListing.sol';
import {Deploy_HorizonPermissionedPayloadsController} from '../../scripts/Deploy_HorizonPermissionedPayloadsController.s.sol';
import {HorizonAddresses} from '../../scripts/Payloads/Horizon/HorizonAddresses.sol';

import {IWithGuardian} from 'adi-deploy/lib/aave-delivery-infrastructure/src/contracts/old-oz/interfaces/IWithGuardian.sol';
import {IPoolAddressesProvider} from 'aave-v3-horizon/contracts/interfaces/IPoolAddressesProvider.sol';
import {IACLManager} from 'aave-v3-horizon/contracts/interfaces/IACLManager.sol';
import {IPool} from 'aave-v3-horizon/contracts/interfaces/IPool.sol';
import {IDefaultInterestRateStrategyV2} from 'aave-v3-horizon/contracts/interfaces/IDefaultInterestRateStrategyV2.sol';
import {IAaveOracle} from 'aave-v3-horizon/contracts/interfaces/IAaveOracle.sol';

import {DataTypes} from 'aave-v3-horizon/contracts/protocol/libraries/types/DataTypes.sol';
import {ReserveConfiguration} from 'aave-v3-horizon/contracts/protocol/libraries/configuration/ReserveConfiguration.sol';
import {MarketReport, ContractsReport, MarketConfig} from 'aave-v3-horizon/deployments/interfaces/IMarketReportTypes.sol';
import {MarketReportUtils} from 'aave-v3-horizon/deployments/contracts/utilities/MarketReportUtils.sol';
import {IMetadataReporter, MetadataReporter} from 'aave-v3-horizon/deployments/contracts/utilities/MetadataReporter.sol';
import {DeployUtils} from 'aave-v3-horizon/deployments/contracts/utilities/DeployUtils.sol';
import {AggregatorInterface} from 'aave-v3-horizon/contracts/dependencies/chainlink/AggregatorInterface.sol';

contract Deploy_HorizonPermissionedPayloadsControllerTest is
  Deploy_HorizonPermissionedPayloadsController
{
  function execute(address proxyFactory) public returns (address) {
    return _execute(proxyFactory);
  }

  function getUpdateExecutorInput()
    public
    returns (IPayloadsControllerCore.UpdateExecutorInput memory)
  {
    return _getUpdateExecutorInput();
  }
}

contract HorizonPermissionedPayloadsControllerBaseTest is DeployUtils, Test {
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;

  struct TokenListingParams {
    bool isGho;
    bool isRwa;
    bool hasPriceAdapter;
    address underlyingPiceFeed; // not the scaled adapter (if any)
    string aTokenName;
    string aTokenSymbol;
    string variableDebtTokenName;
    string variableDebtTokenSymbol;
    uint256 supplyCap;
    uint256 borrowCap;
    uint256 reserveFactor;
    bool enabledToBorrow;
    bool borrowableInIsolation;
    bool withSiloedBorrowing;
    bool flashloanable;
    uint256 ltv;
    uint256 liquidationThreshold;
    uint256 liquidationBonus;
    uint256 debtCeiling;
    uint256 liqProtocolFee;
    IDefaultInterestRateStrategyV2.InterestRateDataRay interestRateData;
  }

  MarketReport internal marketReport;
  ContractsReport internal contracts;
  IPool internal pool;

  address public constant CONFIG_ENGINE =
    0xbbE84e8966005471b0BDC179Add6bd6CE85a60F2;
  address public constant ACL_MANAGER =
    0x9Cfbd85499cb3c8d58AA2B186A3865071A1fa963;
  address public constant POOL_ADDRESSES_PROVIDER =
    0x6ED317B268c72ccb8B9AAFE0Cd8b6e53e44EDaf2;
  address public constant PROXY_FACTORY =
    0xdB6E849Fda6BAE72d1Ac7988a6d00169d355266d;

  address internal configEngine;
  address internal aclManager;
  address internal poolAddressesProvider;
  address internal proxyFactory;
  HorizonAssetListing internal horizonAssetListingPayload;

  TokenListingParams internal ASSET_LISTING_PARAMS;

  function setUp() public virtual {
    vm.createSelectFork(vm.rpcUrl('ethereum-testnet'));

    string memory reportFilePath = './reports/Horizon-market-deployment.json';

    IMetadataReporter metadataReporter = new MetadataReporter();
    marketReport = metadataReporter.parseMarketReport(reportFilePath);
    contracts = MarketReportUtils.toContractsReport(marketReport);

    pool = IPool(marketReport.poolProxy);
    horizonAssetListingPayload = new HorizonAssetListing(
      marketReport.configEngine
    );
    ASSET_LISTING_PARAMS = TokenListingParams({
      aTokenName: string.concat(
        'Aave Horizon RWA ',
        horizonAssetListingPayload.ASSET_SYMBOL()
      ),
      aTokenSymbol: string.concat(
        'aHRwa',
        horizonAssetListingPayload.ASSET_SYMBOL()
      ),
      variableDebtTokenName: string.concat(
        'Aave Horizon RWA Variable Debt',
        horizonAssetListingPayload.ASSET_SYMBOL()
      ),
      variableDebtTokenSymbol: string.concat(
        'variableDebtHRwa',
        horizonAssetListingPayload.ASSET_SYMBOL()
      ),
      isGho: false,
      isRwa: true,
      hasPriceAdapter: false,
      underlyingPiceFeed: horizonAssetListingPayload.ASSET_PRICE_FEED(),
      supplyCap: 5_000_000,
      borrowCap: 0,
      reserveFactor: 15_00,
      enabledToBorrow: false,
      borrowableInIsolation: false,
      withSiloedBorrowing: false,
      flashloanable: false,
      ltv: 75_00,
      liquidationThreshold: 80_00,
      liquidationBonus: 112_00,
      debtCeiling: 0,
      liqProtocolFee: 0,
      interestRateData: IDefaultInterestRateStrategyV2.InterestRateDataRay({
        optimalUsageRatio: 0.9250e27,
        baseVariableBorrowRate: 0,
        variableRateSlope1: 0.055e27,
        variableRateSlope2: 0.35e27
      })
    });
  }

  function test_listing(
    address token,
    TokenListingParams memory params
  ) internal {
    test_getConfiguration(token, params);
    // test_interestRateStrategy(token, params);
    // test_aToken(token, params);
    // test_variableDebtToken(token, params);
    // test_priceFeed(token, params);
  }

  function test_getConfiguration(
    address token,
    TokenListingParams memory params
  ) internal {
    DataTypes.ReserveConfigurationMap memory config = pool.getConfiguration(
      token
    );
    assertEq(config.getSupplyCap(), params.supplyCap, 'supplyCap');
    assertEq(config.getBorrowCap(), params.borrowCap, 'borrowCap');
    assertEq(
      config.getIsVirtualAccActive(),
      !params.isGho,
      'isVirtualAccActive'
    );
    assertEq(
      config.getBorrowingEnabled(),
      params.enabledToBorrow,
      'borrowingEnabled'
    );
    assertEq(
      config.getBorrowableInIsolation(),
      params.borrowableInIsolation,
      'borrowableInIsolation'
    );
    assertEq(
      config.getSiloedBorrowing(),
      params.withSiloedBorrowing,
      'siloedBorrowing'
    );
    assertEq(
      config.getFlashLoanEnabled(),
      params.flashloanable,
      'flashloanable'
    );
    assertEq(config.getReserveFactor(), params.reserveFactor, 'reserveFactor');
    assertEq(config.getLtv(), params.ltv, 'ltv');
    assertEq(
      config.getLiquidationThreshold(),
      params.liquidationThreshold,
      'liquidationThreshold'
    );
    assertEq(
      config.getLiquidationBonus(),
      params.liquidationBonus,
      'liquidationBonus'
    );
    assertEq(config.getDebtCeiling(), params.debtCeiling, 'debtCeiling');
    assertEq(
      config.getLiquidationProtocolFee(),
      params.liqProtocolFee,
      'liqProtocolFee'
    );
    assertEq(config.getPaused(), false, 'paused');
  }

  // function test_interestRateStrategy(
  //   address token,
  //   TokenListingParams memory params
  // ) private {
  //   assertEq(
  //     pool.getReserveData(token).interestRateStrategyAddress,
  //     address(marketReport.defaultInterestRateStrategy),
  //     'interestRateStrategyAddress'
  //   );
  //   assertEq(
  //     marketReport.defaultInterestRateStrategy.getInterestRateData(token),
  //     params.interestRateData
  //   );
  // }

  // function test_aToken(
  //   address token,
  //   TokenListingParams memory params
  // ) private {
  //   address aToken = pool.getReserveAToken(token);
  //   assertEq(IERC20Detailed(aToken).name(), params.aTokenName, 'aTokenName');
  //   assertEq(
  //     IERC20Detailed(aToken).symbol(),
  //     params.aTokenSymbol,
  //     'aTokenSymbol'
  //   );
  //   assertEq(
  //     IAToken(aToken).RESERVE_TREASURY_ADDRESS(),
  //     address(revenueSplitter),
  //     'reserveTreasuryAddress'
  //   );

  //   address currentATokenImpl = ProxyHelpers
  //     .getInitializableAdminUpgradeabilityProxyImplementation(vm, aToken);
  //   if (params.isRwa) {
  //     assertEq(currentATokenImpl, rwaATokenImpl, 'rwaATokenImpl');
  //     vm.expectRevert(bytes(Errors.OPERATION_NOT_SUPPORTED));
  //     IAToken(aToken).approve(address(0), 0);
  //   } else {
  //     assertEq(currentATokenImpl, aTokenImpl, 'aTokenImpl');
  //     IAToken(aToken).approve(makeAddr('randomAddress'), 1);
  //   }
  // }

  // function test_variableDebtToken(
  //   address token,
  //   TokenListingParams memory params
  // ) private {
  //   address variableDebtToken = pool.getReserveVariableDebtToken(token);
  //   assertEq(
  //     IERC20Detailed(variableDebtToken).name(),
  //     params.variableDebtTokenName,
  //     'variableDebtTokenName'
  //   );
  //   assertEq(
  //     IERC20Detailed(variableDebtToken).symbol(),
  //     params.variableDebtTokenSymbol,
  //     'variableDebtTokenSymbol'
  //   );
  //   assertEq(
  //     ProxyHelpers.getInitializableAdminUpgradeabilityProxyImplementation(
  //       vm,
  //       variableDebtToken
  //     ),
  //     horizonAssetListingPayload.VARIABLE_DEBT_TOKEN_IMPLEMENTATION(),
  //     'variableDebtTokenImpl'
  //   );
  // }

  // function test_priceFeed(
  //   address token,
  //   TokenListingParams memory params
  // ) private {
  //   IAaveOracle oracle = IAaveOracle(
  //     pool.ADDRESSES_PROVIDER().getPriceOracle()
  //   );

  //   AggregatorInterface oracleSource = AggregatorInterface(
  //     oracle.getSourceOfAsset(token)
  //   );
  //   assertEq(oracleSource.decimals(), 8, 'oracleSource.decimals');

  //   AggregatorInterface priceFeed = oracleSource;
  //   if (params.hasPriceAdapter) {
  //     priceFeed = AggregatorInterface(
  //       IScaledPriceAdapter(address(oracleSource)).source()
  //     );
  //     assertEq(
  //       priceFeed.latestAnswer() * int256(10 ** (8 - priceFeed.decimals())),
  //       oracleSource.latestAnswer(),
  //       'priceFeed.latestAnswer'
  //     );
  //   }

  //   assertEq(address(priceFeed), params.underlyingPiceFeed, 'priceFeed');
  // }
}

contract HorizonPermissionedPayloadsControllerForkTest is
  HorizonPermissionedPayloadsControllerBaseTest
{
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;

  IPermissionedPayloadsController permissionedPayloadsController;
  Deploy_HorizonPermissionedPayloadsControllerTest
    internal deploy_HorizonPermissionedPayloadsControllerTest;

  address internal permissionedExecutor;
  uint256 internal delay;
  address internal guardian;
  address internal payloadsManager;

  function setUp() public override {
    super.setUp();
    address aclAdmin = IPoolAddressesProvider(
      marketReport.poolAddressesProvider
    ).getACLAdmin();

    deploy_HorizonPermissionedPayloadsControllerTest = new Deploy_HorizonPermissionedPayloadsControllerTest();
    permissionedPayloadsController = IPermissionedPayloadsController(
      deploy_HorizonPermissionedPayloadsControllerTest.execute(
        marketReport.transparentProxyFactory
      )
    );

    permissionedExecutor = deploy_HorizonPermissionedPayloadsControllerTest
      .PERMISSIONED_EXECUTOR();
    delay = deploy_HorizonPermissionedPayloadsControllerTest.DELAY();
    payloadsManager = deploy_HorizonPermissionedPayloadsControllerTest
      .PAYLOADS_MANAGER();
    guardian = deploy_HorizonPermissionedPayloadsControllerTest.GUARDIAN();

    // grant necessary roles to executor
    // vm.startPrank(aclAdmin);
    // IACLManager(ACL_MANAGER).addAssetListingAdmin(permissionedExecutor);
    // IACLManager(ACL_MANAGER).addRiskAdmin(permissionedExecutor);
    // vm.stopPrank();

    // PPC must own the permissioned executor to execute payloads
    vm.prank(HorizonAddresses.HORIZON_ADVANCED_MULTISIG);
    Ownable(permissionedExecutor).transferOwnership(
      address(permissionedPayloadsController)
    );
  }

  function testGetPayloadsManager() external {
    assertEq(
      permissionedPayloadsController.payloadsManager(),
      payloadsManager,
      'payloads manager'
    );
  }

  function testPayloadsCreationWithInvalidCaller() external {
    address user = makeAddr('user');
    vm.expectRevert(bytes(Errors.ONLY_BY_PAYLOADS_MANAGER));
    _createPayload(user);
  }

  function testPayloadsCreation() external {
    uint40 payloadId = _createPayload(payloadsManager);
    assertEq(
      permissionedPayloadsController.getPayloadsCount(),
      1,
      'payload count'
    );
    assertTrue(
      permissionedPayloadsController.getPayloadState(payloadId) ==
        IPayloadsControllerCore.PayloadState.Queued,
      'state=Queued'
    );
    IPayloadsControllerCore.Payload
      memory payload = permissionedPayloadsController.getPayloadById(payloadId);
  }

  function testGuardian() external {
    assertEq(
      IWithGuardian(address(permissionedPayloadsController)).guardian(),
      deploy_HorizonPermissionedPayloadsControllerTest.GUARDIAN(),
      'guardian'
    );
  }

  function testExecutorOwner() external {
    assertEq(
      Ownable(permissionedExecutor).owner(),
      address(permissionedPayloadsController),
      'executor owner'
    );
  }

  // function testPayloadTimeLockNotExceeded(uint256 warpTime) external {
  //   address origin = makeAddr('origin');
  //   uint40 payloadId = _createPayload(payloadsManager);

  //   uint256 invalidWarpTime = warpTime % delay;
  //   vm.warp(invalidWarpTime);

  //   vm.expectRevert(bytes(Errors.TIMELOCK_NOT_FINISHED));
  //   vm.prank(origin);
  //   permissionedPayloadsController.executePayload(payloadId);
  // }

  function _executePayload(address origin) internal {
    uint40 payloadId = _createPayload(payloadsManager);
    vm.warp(vm.getBlockTimestamp() + delay + 1);

    vm.prank(origin);
    permissionedPayloadsController.executePayload(payloadId);
  }

  function testPayloadExecution() external {
    address origin = makeAddr('origin');
    // create and queue payload
    _executePayload(origin);

    test_getConfiguration(
      horizonAssetListingPayload.ASSET_ADDRESS(),
      ASSET_LISTING_PARAMS
    );
  }

  function testAdminRoles() external {
    address origin = makeAddr('origin');
    // create and queue payload
    _executePayload(origin);

    assertFalse(
      IACLManager(ACL_MANAGER).isAssetListingAdmin(permissionedExecutor),
      'executor has asset listing admin'
    );
    assertFalse(
      IACLManager(ACL_MANAGER).isRiskAdmin(permissionedExecutor),
      'executor has risk admin'
    );
  }

  // function testSetExecutionDelayWithGuardian() external {
  //   uint40 newDelay = 500;

  //   vm.prank(deploy_HorizonPermissionedPayloadsControllerTest.GUARDIAN());
  //   permissionedPayloadsController.setExecutionDelay(newDelay);

  //   IPayloadsControllerCore.ExecutorConfig
  //     memory executorConfig = permissionedPayloadsController
  //       .getExecutorSettingsByAccessControl(
  //         PayloadsControllerUtils.AccessControl.Level_1
  //       );

  //   assertEq(
  //     executorConfig.delay,
  //     newDelay,
  //     'Execution delay was not set correctly'
  //   );
  //   assertNotEq(
  //     abi.encode(
  //       deploy_HorizonPermissionedPayloadsControllerTest
  //         .getUpdateExecutorInput()
  //         .executorConfig
  //     ),
  //     abi.encode(executorConfig)
  //   );
  // }

  function _createPayload(address caller) internal returns (uint40) {
    return _createPayload(caller, address(horizonAssetListingPayload));
  }

  function _createPayload(
    address caller,
    address target
  ) internal returns (uint40) {
    IPayloadsControllerCore.ExecutionAction[]
      memory actions = new IPayloadsControllerCore.ExecutionAction[](1);
    actions[0].target = target;
    actions[0].value = 0;
    actions[0].signature = 'execute()';
    actions[0].callData = bytes('');
    actions[0].withDelegateCall = true;
    actions[0].accessLevel = PayloadsControllerUtils.AccessControl.Level_1;

    vm.startPrank(caller);
    uint40 payloadId = permissionedPayloadsController.createPayload(actions);
    vm.stopPrank();
    return payloadId;
  }
}
