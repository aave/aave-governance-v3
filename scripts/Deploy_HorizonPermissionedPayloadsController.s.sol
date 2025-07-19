// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {console2 as console} from 'forge-std/console2.sol';

import 'forge-std/Script.sol';
import {PermissionedPayloadsController, PayloadsControllerUtils, IPayloadsControllerCore} from '../src/contracts/payloads/PermissionedPayloadsController.sol';
import {Ownable} from 'openzeppelin-contracts/contracts/access/Ownable.sol';
import {Constants} from './GovBaseScript.sol';
import {TransparentProxyFactory} from 'solidity-utils/contracts/transparent-proxy/TransparentProxyFactory.sol';
import {HorizonAddresses} from './Payloads/Horizon/HorizonAddresses.sol';

contract Deploy_HorizonPermissionedPayloadsController is Script {
  uint40 public constant DELAY = 1 days; // MIN_DELAY

  function run(address proxyFactory) public {
    vm.startBroadcast();
    _execute(proxyFactory);
    vm.stopBroadcast();
  }

  function GUARDIAN() public virtual returns (address) {
    return HorizonAddresses.HORIZON_ADVANCED_MULTISIG;
  }
  function PAYLOADS_MANAGER() public virtual returns (address) {
    return HorizonAddresses.HORIZON_ADVANCED_MULTISIG;
  }
  function PERMISSIONED_EXECUTOR() public virtual returns (address) {
    return HorizonAddresses.EXECUTOR;
  }

  function _getUpdateExecutorInput()
    internal
    returns (IPayloadsControllerCore.UpdateExecutorInput memory)
  {
    IPayloadsControllerCore.UpdateExecutorInput
      memory updateExecutorInput = IPayloadsControllerCore.UpdateExecutorInput({
        accessLevel: PayloadsControllerUtils.AccessControl.Level_1,
        executorConfig: IPayloadsControllerCore.ExecutorConfig({
          executor: PERMISSIONED_EXECUTOR(),
          delay: DELAY
        })
      });
    return updateExecutorInput;
  }

  function _execute(address proxyFactory) internal returns (address) {
    address permissionedPayloadsControllerImpl = address(
      new PermissionedPayloadsController()
    );
    IPayloadsControllerCore.UpdateExecutorInput[]
      memory executors = new IPayloadsControllerCore.UpdateExecutorInput[](1);
    executors[0] = _getUpdateExecutorInput();

    address permissionedPayloadsController = TransparentProxyFactory(
      proxyFactory
    ).createDeterministic(
        permissionedPayloadsControllerImpl,
        PERMISSIONED_EXECUTOR(), // owner of proxy that will be deployed
        abi.encodeWithSelector(
          PermissionedPayloadsController.initialize.selector,
          GUARDIAN(),
          PAYLOADS_MANAGER(),
          executors
        ),
        Constants.PERMISSIONED_PAYLOADS_CONTROLLER_SALT
      );

    return permissionedPayloadsController;
  }
}
