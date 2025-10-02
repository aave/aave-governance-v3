// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IAaveV3ConfigEngine} from 'aave-v3-origin/contracts/extensions/v3-config-engine/IAaveV3ConfigEngine.sol';

/**
 * @title IAssetListingSteward
 * @author BGD Labs
 * @notice Interface for the Asset Listing Steward contract
 * @dev This steward manages asset listing operations with controlled permissions and risk parameters
 */
interface IAssetListingSteward {
  /**
   * @notice Emitted when an asset listing is approved and executed
   * @param asset The asset that was listed
   * @param aToken The aToken address created for the asset
   * @param variableDebtToken The variable debt token address
   * @param stableDebtToken The stable debt token address
   * @param council The council member who approved the listing
   */
  event AssetListingApproved(
    address indexed asset,
    address indexed aToken,
    address indexed variableDebtToken,
    address stableDebtToken,
    address council
  );

  /**
   * @notice Emitted when an asset listing is proposed
   * @param asset The asset proposed for listing
   * @param proposer The address that proposed the listing
   * @param proposalId The unique identifier for the proposal
   */
  event AssetListingProposed(
    address indexed asset,
    address indexed proposer,
    uint256 indexed proposalId
  );

  /**
   * @notice Emitted when an asset listing proposal is cancelled
   * @param asset The asset whose listing was cancelled
   * @param proposalId The proposal identifier
   * @param canceller The address that cancelled the proposal
   */
  event AssetListingCancelled(
    address indexed asset,
    uint256 indexed proposalId,
    address indexed canceller
  );

  /**
   * @notice Emitted when risk parameters are updated for an asset
   * @param asset The asset whose parameters were updated
   * @param council The council member who updated the parameters
   */
  event AssetRiskParametersUpdated(
    address indexed asset,
    address indexed council
  );

  /**
   * @notice Emitted when an asset is emergency frozen
   * @param asset The asset that was frozen
   * @param council The council member who froze the asset
   */
  event AssetEmergencyFrozen(
    address indexed asset,
    address indexed council
  );

  /**
   * @notice Struct representing an asset listing proposal
   * @param asset The asset to be listed
   * @param proposer The address that proposed the listing
   * @param listing The detailed listing configuration
   * @param poolContext The pool context for the listing
   * @param proposedAt The timestamp when the proposal was created
   * @param executed Whether the proposal has been executed
   * @param cancelled Whether the proposal has been cancelled
   */
  struct AssetListingProposal {
    address asset;
    address proposer;
    IAaveV3ConfigEngine.Listing listing;
    IAaveV3ConfigEngine.PoolContext poolContext;
    uint256 proposedAt;
    bool executed;
    bool cancelled;
  }

  /**
   * @notice Struct for asset risk parameter updates
   * @param asset The asset to update
   * @param ltv The new loan-to-value ratio
   * @param liqThreshold The new liquidation threshold
   * @param liqBonus The new liquidation bonus
   * @param supplyCap The new supply cap
   * @param borrowCap The new borrow cap
   */
  struct RiskParameterUpdate {
    address asset;
    uint256 ltv;
    uint256 liqThreshold;
    uint256 liqBonus;
    uint256 supplyCap;
    uint256 borrowCap;
  }

  /**
   * @notice Proposes a new asset for listing
   * @param listing The asset listing configuration
   * @param poolContext The pool context
   * @return proposalId The unique identifier for the proposal
   */
  function proposeAssetListing(
    IAaveV3ConfigEngine.Listing calldata listing,
    IAaveV3ConfigEngine.PoolContext calldata poolContext
  ) external returns (uint256 proposalId);

  /**
   * @notice Approves and executes an asset listing proposal (council only)
   * @param proposalId The proposal to approve and execute
   */
  function approveAssetListing(uint256 proposalId) external;

  /**
   * @notice Cancels an asset listing proposal
   * @param proposalId The proposal to cancel
   */
  function cancelAssetListing(uint256 proposalId) external;

  /**
   * @notice Updates risk parameters for an already listed asset (council only)
   * @param updates Array of risk parameter updates to apply
   */
  function updateRiskParameters(RiskParameterUpdate[] calldata updates) external;

  /**
   * @notice Emergency freezes an asset (council only)
   * @param asset The asset to freeze
   */
  function emergencyFreezeAsset(address asset) external;

  /**
   * @notice Emergency unfreezes an asset (council only)
   * @param asset The asset to unfreeze
   */
  function emergencyUnfreezeAsset(address asset) external;

  /**
   * @notice Gets an asset listing proposal by ID
   * @param proposalId The proposal identifier
   * @return proposal The proposal details
   */
  function getProposal(uint256 proposalId) external view returns (AssetListingProposal memory proposal);

  /**
   * @notice Gets the total number of proposals
   * @return count The total proposal count
   */
  function getProposalCount() external view returns (uint256 count);

  /**
   * @notice Checks if an address is a council member
   * @param account The address to check
   * @return isCouncil True if the address is a council member
   */
  function isCouncilMember(address account) external view returns (bool isCouncil);

  /**
   * @notice Gets the risk council address
   * @return council The risk council contract address
   */
  function getRiskCouncil() external view returns (address council);

  /**
   * @notice Gets the config engine address
   * @return configEngine The Aave V3 config engine address
   */
  function getConfigEngine() external view returns (address configEngine);

  /**
   * @notice Gets the minimum time delay for proposals
   * @return delay The delay in seconds
   */
  function getProposalDelay() external view returns (uint256 delay);
}