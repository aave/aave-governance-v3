# Horizon Asset Listing Steward

A comprehensive governance system for managing Aave V3 asset listings with enhanced security and controlled permissions.

## Overview

The Horizon Asset Listing Steward provides a structured approach to asset listing management that combines:
- **Permissioned Proposals**: Anyone can propose, but only authorized parties can execute
- **Time Delays**: Built-in security delays for proposal execution
- **Risk Management**: Controlled parameter updates and emergency controls
- **Multi-Network Support**: Works across all Aave V3 networks

## Architecture

### Core Components

1. **AssetListingSteward**: Main steward contract managing proposals and executions
2. **AssetListingPayload**: Traditional payload contracts for governance integration
3. **Deployment Scripts**: Network-agnostic deployment infrastructure
4. **Fork Tests**: Comprehensive testing against real Aave protocols

### Smart Contracts

```
src/contracts/
├── stewards/
│   └── AssetListingSteward.sol       # Main steward implementation
├── interfaces/
│   └── IAssetListingSteward.sol      # Steward interface
└── libraries/
    └── Errors.sol                    # Error definitions (updated)
```

### Scripts & Testing

```
scripts/
├── stewards/
│   └── DeployAssetListingSteward.s.sol    # Multi-network deployment
├── E2E_StewardAssetListingTest.s.sol      # Steward E2E testing
├── E2E_AssetListingTest.s.sol             # Traditional payload E2E
└── SimpleVerifyAssetListing.s.sol         # Asset verification

tests/
├── stewards/
│   └── AssetListingSteward.t.sol          # Comprehensive steward tests
├── payloads/
│   ├── AssetListingPayload.t.sol          # Payload unit tests
│   └── AssetListingPayloadFork.t.sol      # Fork tests against mainnet
```

## Workflow

### 1. Asset Listing Proposal

Anyone can propose a new asset listing:

```solidity
uint256 proposalId = steward.proposeAssetListing(listing, poolContext);
```

The proposal includes:
- Asset address and configuration
- Risk parameters (LTV, liquidation threshold, etc.)
- Interest rate strategy parameters
- Supply/borrow caps

### 2. Proposal Review Period

- **24-hour delay** before execution is allowed
- Proposals can be cancelled by:
  - Original proposer
  - Risk Council
  - Guardian

### 3. Approval & Execution

Risk Council can approve and execute proposals:

```solidity
steward.approveAssetListing(proposalId);
```

This automatically:
- Lists the asset in Aave V3
- Creates aToken, debt tokens
- Applies specified risk parameters

### 4. Ongoing Management

Risk Council can update parameters:

```solidity
steward.updateRiskParameters(updates);
```

Guardian can emergency freeze assets:

```solidity
steward.emergencyFreezeAsset(asset);
```

## Security Features

### Access Control

- **Risk Council**: Can approve listings, update parameters, freeze/unfreeze assets
- **Guardian**: Can cancel proposals, emergency freeze assets  
- **Public**: Can propose asset listings

### Safety Mechanisms

- **Parameter Validation**: 
  - Max LTV: 75%
  - Max Liquidation Threshold: 85%
  - LTV ≤ Liquidation Threshold
- **Time Delays**: 24-hour minimum before execution
- **Asset Validation**: Contract existence and not already listed
- **Emergency Controls**: Immediate asset freezing capability

### Error Handling

Comprehensive error handling with descriptive messages:
- `INVALID_CALLER`
- `PROPOSAL_DELAY_NOT_MET`
- `ASSET_ALREADY_LISTED`
- `INVALID_RISK_PARAMETERS`

## Network Support

Supported Aave V3 networks:
- Ethereum Mainnet
- Polygon
- Avalanche
- Optimism
- Arbitrum
- Base
- Gnosis
- Scroll
- BNB Chain
- Metis
- Ethereum Sepolia (testnet)

## Usage Examples

### Deploy Steward

```bash
# Deploy on Sepolia
forge script scripts/stewards/DeployAssetListingSteward.s.sol --rpc-url $RPC_SEPOLIA --broadcast

# Deploy on Mainnet
forge script scripts/stewards/DeployAssetListingSteward.s.sol --rpc-url $RPC_MAINNET --broadcast
```

### Run E2E Tests

```bash
# Test steward workflow
forge script scripts/E2E_StewardAssetListingTest.s.sol --rpc-url $RPC_SEPOLIA --broadcast -vvv

# Test traditional payload
forge script scripts/E2E_AssetListingTest.s.sol --rpc-url $RPC_SEPOLIA --broadcast -vvv
```

### Run Fork Tests

```bash
# Test against real Aave mainnet
forge test --match-contract AssetListingPayloadForkTest --fork-url $MAINNET_RPC -vvv

# Test steward unit tests
forge test --match-contract AssetListingStewardTest -vvv
```

## Integration with Governance

### Traditional Governance Integration

The steward can be integrated with Aave's traditional governance system:

1. Create governance proposal that calls `steward.approveAssetListing()`
2. Community votes on proposal
3. If passed, proposal execution triggers steward approval
4. Asset is automatically listed

### Direct Steward Usage

For faster iteration with trusted risk council:

1. Anyone proposes asset listing
2. Risk council reviews and approves after delay
3. Asset is immediately listed
4. Community oversight through emergency controls

## Risk Management

### Parameter Constraints

The steward enforces conservative defaults:
- **Initial LTV**: 0% (can be increased later)
- **Liquidation Threshold**: 0% (can be increased later)
- **Borrowing**: Disabled initially
- **Supply Caps**: Conservative limits
- **Interest Rates**: Moderate slope parameters

### Emergency Procedures

1. **Asset Freezing**: Immediate freeze via `emergencyFreezeAsset()`
2. **Proposal Cancellation**: Cancel problematic proposals
3. **Parameter Updates**: Quick risk parameter adjustments
4. **Guardian Controls**: Multi-party emergency access

## Testing Strategy

### Unit Tests
- Complete coverage of steward functionality
- Mock contracts for isolated testing
- Edge case and error condition testing

### Fork Tests  
- Real protocol integration testing
- Mainnet state verification
- End-to-end workflow validation

### E2E Scripts
- Complete deployment and usage workflows
- Network-specific testing
- Documentation and verification

## Development Guidelines

### Adding New Networks

1. Update `getNetworkConfig()` in deployment scripts
2. Add network-specific council/guardian addresses
3. Test on network's testnet first
4. Update documentation

### Proposing Assets

When proposing assets, ensure:
- Asset contract is verified and audited
- Price feed is reliable (Chainlink recommended)
- Risk parameters are conservative initially
- Supply caps are reasonable for market size

### Risk Parameter Updates

Follow these principles:
- Gradual increases in LTV/liquidation thresholds
- Monitor utilization before increasing caps
- Consider market conditions and volatility
- Coordinate with risk council for major changes

## Deployment Information

### Contract Addresses

Update this section with deployed contract addresses:

```
Ethereum Mainnet:
- AssetListingSteward: [To be deployed]

Ethereum Sepolia:
- AssetListingSteward: [To be deployed]

Polygon:
- AssetListingSteward: [To be deployed]

[Other networks...]
```

### Verification

All contracts should be verified on respective block explorers with:
- Source code
- Constructor parameters
- Compiler version and settings

## Contributing

When contributing to the Horizon Asset Listing Steward:

1. **Test thoroughly**: Run both unit and fork tests
2. **Follow patterns**: Use existing Aave patterns and conventions
3. **Document changes**: Update relevant documentation
4. **Security first**: Prioritize safety over convenience
5. **Network compatibility**: Ensure changes work across all supported networks

## References

- [Aave V3 Documentation](https://docs.aave.com/developers/v/3.0/)
- [Aave Governance V3](https://github.com/bgd-labs/aave-governance-v3)
- [Aave Address Book](https://github.com/bgd-labs/aave-address-book)
- [Risk Steward Implementations](https://github.com/bgd-labs/aave-helpers/tree/main/src/riskstewards)

---

**Built for Aave's Horizon Asset Listing Initiative** 🚀