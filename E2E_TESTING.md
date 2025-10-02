# End-to-End Asset Listing Testing Guide

This guide explains how to run comprehensive end-to-end tests for the Aave V3 Asset Listing Payload system.

## Overview

The E2E testing suite includes:
- **E2E_AssetListingTest.s.sol**: Full end-to-end deployment and testing
- **VerifyAssetListing.s.sol**: Asset verification and status checking

## Prerequisites

1. **Environment Setup**:
   ```bash
   # Set up environment variables (create .env file)
   PRIVATE_KEY=your_private_key_here
   RPC_SEPOLIA=https://eth-sepolia.g.alchemy.com/v2/your_api_key
   RPC_MAINNET=https://eth-mainnet.g.alchemy.com/v2/your_api_key
   ```

2. **Network Support**:
   - Ethereum Mainnet (Chain ID: 1)
   - Ethereum Sepolia (Chain ID: 11155111)
   - Can be extended to other Aave V3 networks

3. **Funding**:
   - Ensure your test account has enough ETH for gas fees
   - For Sepolia: Get testnet ETH from faucets

## Running E2E Tests

### 1. Traditional Asset Listing Payload Test

This test deploys a new ERC20 token and creates a traditional asset listing payload:

```bash
# Run on Sepolia testnet
forge script scripts/E2E_AssetListingTest.s.sol --rpc-url $RPC_SEPOLIA --broadcast -vvv

# Run on Ethereum mainnet (view only - no actual listing without governance)
forge script scripts/E2E_AssetListingTest.s.sol --rpc-url $RPC_MAINNET --broadcast -vvv

# Dry run (no broadcast)
forge script scripts/E2E_AssetListingTest.s.sol --rpc-url $RPC_SEPOLIA -vvv
```

### 2. Horizon Asset Listing Steward E2E Test

This test deploys the full steward system and demonstrates the governance workflow:

```bash
# Run steward E2E test on Sepolia testnet
forge script scripts/E2E_StewardAssetListingTest.s.sol --rpc-url $RPC_SEPOLIA --broadcast -vvv

# Run on Ethereum mainnet (view only)
forge script scripts/E2E_StewardAssetListingTest.s.sol --rpc-url $RPC_MAINNET --broadcast -vvv

# Dry run (no broadcast)
forge script scripts/E2E_StewardAssetListingTest.s.sol --rpc-url $RPC_SEPOLIA -vvv
```

### 3. Deploy Asset Listing Steward Only

Deploy just the steward contract without the full E2E workflow:

```bash
# Deploy steward on Sepolia
forge script scripts/stewards/DeployAssetListingSteward.s.sol --rpc-url $RPC_SEPOLIA --broadcast -vvv

# Deploy steward on Ethereum mainnet
forge script scripts/stewards/DeployAssetListingSteward.s.sol --rpc-url $RPC_MAINNET --broadcast -vvv
```

**What the traditional payload test does:**
1. Detects network and loads correct Aave V3 addresses
2. Deploys a test ERC20 token with configurable properties
3. Creates and deploys an AssetListingPayload contract
4. Verifies all contract integrations and configurations
5. Tests ERC20 functionality (transfer, approve)
6. Validates payload view functions
7. Outputs comprehensive deployment information

**What the steward E2E test does:**
1. Detects network and loads correct Aave V3 addresses
2. Deploys a test ERC20 token
3. Deploys the Asset Listing Steward contract
4. Creates an asset listing proposal through the steward
5. Verifies steward permissions and governance controls
6. Tests risk parameter validation
7. Demonstrates the complete steward workflow
8. Shows how to approve proposals (requires risk council)

### 2. Asset Verification

Verify if an asset is already listed in Aave and check its configuration:

```bash
# Verify specific asset on Sepolia
forge script scripts/VerifyAssetListing.s.sol:VerifyAssetListing --sig "runWithAsset(address)" 0xYourAssetAddress --rpc-url $RPC_SEPOLIA -vvv

# Verify default assets
forge script scripts/VerifyAssetListing.s.sol --rpc-url $RPC_SEPOLIA -vvv

# Check mainnet asset
forge script scripts/VerifyAssetListing.s.sol:VerifyAssetListing --sig "runWithAsset(address)" 0xA0b86a33E6F8e34c0E8a3fC5dC8aF3D5a8b8c3e2 --rpc-url $RPC_MAINNET -vvv
```

**What this outputs:**
- 📊 Complete asset information (name, symbol, decimals, price)
- 🏦 Aave integration status (aToken, debt tokens, etc.)
- ⚙️ Risk parameters (LTV, liquidation threshold, etc.)
- 📈 Supply and borrow caps
- 🚦 Asset flags (active, frozen, paused, etc.)

## Expected Outputs

### Successful E2E Test Output:

```
=== AAVE V3 ASSET LISTING E2E TEST ===

Network: Sepolia
Chain ID: 11155111
Config Engine: 0x0a275C06556EeB3c7Ff2b0f0cfD462A7645772EF
Pool Addresses Provider: 0x012bAC54348C0E635dCAc9D5FB99f06F24136C9A

=== STEP 1: DEPLOYING TEST TOKEN ===
Test Token Address: 0x...
Test Token Name: Test Asset Token
Test Token Symbol: TEST
Test Token Decimals: 18
Test Token Total Supply: 1000000000000000000000000
Deployer Balance: 1000000000000000000000000

=== STEP 2: DEPLOYING ASSET LISTING PAYLOAD ===
Payload Address: 0x...
Payload Asset: 0x...
Payload Config Engine: 0x0a275C06556EeB3c7Ff2b0f0cfD462A7645772EF
Payload Addresses Provider: 0x012bAC54348C0E635dCAc9D5FB99f06F24136C9A

=== STEP 3: AAVE POOL INFORMATION ===
Pool Address: 0x6Ae43d3271ff6888e7Fc43Fd7321a503ff738951
Pool Configurator: 0x7Ee60D184C24Ef7AfC1Ec7Be59A0f448A0abd138
ACL Manager: 0x7F2bE3b178deeFF716CD6Ff03Ef79A1dFf360ddD
Price Oracle: 0x2da88497588bf89281816106C7259e31AF45a663

=== STEP 4: PRE-LISTING ASSET STATUS ===
✅ Asset is not yet listed in Aave (expected)

=== STEP 5: EXECUTING ASSET LISTING ===
Number of assets to list: 1
Asset to list: 0x...
Asset symbol: TEST
Price feed: 0x0000000000000000000000000000000000000001
Optimal usage ratio: 8000
Base variable borrow rate: 0
Variable rate slope 1: 400
Variable rate slope 2: 6000
Supply cap: 1000000
Borrow cap: 0
LTV: 0
Liquidation threshold: 0
Liquidation bonus: 1000
Reserve factor: 1000
Enabled to borrow: 0
Flashloanable: 1

✅ Payload configured successfully!
⚠️  Note: Actual execution requires governance permissions

=== STEP 6: INTEGRATION VERIFICATION ===
Testing ERC20 functionality:
- Transfer test...
  ✅ Transfer successful
- Approve test...
  ✅ Approval successful
  Approved amount: 1000000000000000000000

Testing payload view functions:
- Network name: Test
- Network abbreviation: Test
  ✅ Pool context retrieved

=== FINAL SUMMARY ===
✅ Test token deployed successfully
✅ Asset listing payload deployed successfully  
✅ Aave pool integration verified
✅ All view functions working correctly
✅ ERC20 token functions working correctly

📋 DEPLOYMENT ADDRESSES:
Test Token: 0x...
Asset Listing Payload: 0x...
Config Engine: 0x0a275C06556EeB3c7Ff2b0f0cfD462A7645772EF
Pool Addresses Provider: 0x012bAC54348C0E635dCAc9D5FB99f06F24136C9A
Pool: 0x6Ae43d3271ff6888e7Fc43Fd7321a503ff738951

🚀 E2E TEST COMPLETED SUCCESSFULLY!
```

### Steward E2E Test Output:

```
=== ASSET LISTING STEWARD E2E TEST ===

Network: Ethereum Sepolia
Chain ID: 11155111
Config Engine: 0x0a275C06556EeB3c7Ff2b0f0cfD462A7645772EF
Pool Addresses Provider: 0x012bAC54348C0E635dCAc9D5FB99f06F24136C9A
Risk Council: 0x...
Guardian: 0x...

=== STEP 1: DEPLOYING TEST TOKEN ===
Test Token Address: 0x...
Test Token Name: Steward Test Token
Test Token Symbol: STEST

=== STEP 2: DEPLOYING ASSET LISTING STEWARD ===
Steward Address: 0x...
Steward Config Engine: 0x0a275C06556EeB3c7Ff2b0f0cfD462A7645772EF
Steward Risk Council: 0x...
Steward Proposal Delay: 86400

=== STEP 4: CREATING ASSET LISTING PROPOSAL ===
Proposal ID: 1
Proposal Count: 1

=== STEP 5: VERIFYING PROPOSAL DETAILS ===
Proposal Asset: 0x...
Proposal Proposer: 0x...
Asset Symbol: STEST
Supply Cap: 1000000
LTV: 0
Liquidation Threshold: 0

STEWARD E2E TEST COMPLETED SUCCESSFULLY!
   Next steps for production use:
   1. Wait for proposal delay (24 hours)
   2. Risk council approves proposal via approveAssetListing()
   3. Asset gets listed in Aave pool automatically
```

### Asset Verification Output:

```
=== AAVE V3 ASSET VERIFICATION ===
Network: Ethereum Sepolia
Asset Address: 0x...

=== TOKEN INFORMATION ===
Name: Test Asset Token
Symbol: TEST
Decimals: 18
Price (in wei): 1000000000000000000

=== AAVE INTEGRATION ===
✅ Asset is listed in Aave
Reserve ID: 12
aToken: 0x...
Variable Debt Token: 0x...
Stable Debt Token: 0x...
Interest Rate Strategy: 0x...

=== RISK PARAMETERS ===
LTV: 0 bps
Liquidation Threshold: 0 bps
Liquidation Bonus: 1000 bps
Reserve Factor: 1000 bps

=== CAPS ===
Supply Cap: 1000000
Borrow Cap: 0

=== FLAGS ===
Is Active: ✅
Is Frozen: ✅
Is Paused: ✅
Usage as Collateral Enabled: ❌
Borrowing Enabled: ❌
Stable Borrow Rate Enabled: ❌
```

## Customization

### Test Token Configuration

Edit these constants in `E2E_AssetListingTest.s.sol`:

```solidity
uint256 public constant INITIAL_SUPPLY = 1000000 * 1e18; // 1M tokens
string public constant ASSET_NAME = "Test Asset Token";
string public constant ASSET_SYMBOL = "TEST";
uint8 public constant ASSET_DECIMALS = 18;
```

### Asset Listing Parameters

Modify the `newListings()` function in `TestAssetListingPayload`:

```solidity
listings[0] = IEngine.Listing({
  asset: TEST_ASSET,
  assetSymbol: assetSymbol,
  priceFeed: priceFeed,
  rateStrategyParams: IEngine.InterestRateInputData({
    optimalUsageRatio: 80_00,     // 80%
    baseVariableBorrowRate: 0,    // 0% for safety
    variableRateSlope1: 4_00,     // 4%
    variableRateSlope2: 60_00     // 60%
  }),
  enabledToBorrow: EngineFlags.DISABLED, // Change to ENABLED if needed
  // ... other parameters
});
```

### Network Support

To add support for other networks, update `getNetworkInfo()`:

```solidity
function getNetworkInfo() public view returns (...) {
  uint256 chainId = block.chainid;
  
  if (chainId == ChainIds.POLYGON) {
    return (chainId, AaveV3Polygon.CONFIG_ENGINE, address(AaveV3Polygon.POOL_ADDRESSES_PROVIDER), "Polygon");
  }
  // Add other networks...
}
```

## Production Deployment

⚠️ **Important**: These scripts create test tokens and payloads for verification purposes. For production asset listing:

1. **Use Real Assets**: Replace test token with actual production token address
2. **Use Real Price Feeds**: Replace mock price feed with Chainlink price feed
3. **Configure Risk Parameters**: Set appropriate LTV, liquidation thresholds based on risk assessment
4. **Use Governance Process**: Submit payload through proper Aave governance channels
5. **Enable Borrowing Carefully**: Only enable borrowing after thorough testing and risk analysis

## Troubleshooting

### Common Issues:

1. **"Unsupported network"**: Add network support or use supported testnet
2. **"Insufficient funds"**: Get more testnet ETH from faucets
3. **"Asset already listed"**: Use verification script to check existing assets
4. **Rate limiting**: Use your own RPC endpoints instead of public ones

### Debug Mode:

Add `-vvvv` flag for maximum verbosity:
```bash
forge script scripts/E2E_AssetListingTest.s.sol --rpc-url $RPC_SEPOLIA --broadcast -vvvv
```

## Next Steps

After successful E2E testing:

1. 📝 **Document Results**: Save deployment addresses and transaction hashes
2. 🔍 **Verify Contracts**: Use block explorers to verify contract deployment
3. 🏛️ **Submit to Governance**: Create governance proposal for actual asset listing
4. 🗳️ **Community Voting**: Participate in governance voting process
5. ⚡ **Execute Payload**: After successful vote, execute through PayloadsController
6. 🧪 **Post-Listing Testing**: Verify supply/withdraw functionality works correctly

This comprehensive testing ensures your asset listing payload works correctly before going through the governance process!