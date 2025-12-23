# smartCrowdFunder

## Overview
smartCrowdFunder is a decentralized crowdfunding smart contract built in Solidity. It allows contributors to fund a project, collects protocol fees, and enables the project owner and protocol to withdraw funds securely. The contract is designed for deployment on EVM-compatible blockchains (e.g., Sepolia, Ethereum mainnet, etc.).

## Features
- **Contribution:** Anyone can contribute ETH to a project, subject to a minimum contribution of 0.00001 ether == 1e15.
- **Protocol Fee:** A fixed percentage (5%) of each contribution is collected as a protocol fee.
- **Withdrawal:** Project owner receives contributed funds (minus protocol fee). Only Protocol can withdraw accumulated fees.
- **Contributor Tracking:** Tracks contributors and their contributed amounts.
- **Custom Errors:** Uses custom errors for efficient gas usage and clear revert reasons.

## Contract Details
- **Project Owner:** Receives contributed ETH.
- **Protocol:** Receives protocol fees and can withdraw them.
- **Minimum Contribution:** 0.00001 ETH.
- **Protocol Fee:** 5% of each contribution.

## Deployment

### Prerequisites
- [Foundry](https://book.getfoundry.sh/) installed
- Sepolia or other EVM-compatible network access
- Sufficient ETH for deployment and initial contributions

### Deployment Script
The contract can be deployed using the provided Foundry script:

**File:** `script/DeployCrowdFund.s.sol`

```solidity
contract DeployCrowdFund is Script {
    function run() public {
        vm.startBroadcast();
        crowdFund = new CrowdFund(<PROJECT_OWNER_ADDRESS>);
        vm.stopBroadcast();
    }
}
```
Replace `<PROJECT_OWNER_ADDRESS>` with the desired EOA address.

#### Deploy via Foundry
```bash
forge script script/DeployRaiseBox.s.sol --rpc-url <SEPOLIA_RPC_URL> --broadcast --verify
```

## Usage

### Contribute
Call the `contribute(uint256 amount)` function, sending ETH with the transaction. The `amount` parameter should match the ETH sent (`msg.value`).

### Withdraw Protocol Fees
Protocol can call `withdrawProtocolFees()` to withdraw accumulated fees.

## Natspec Documentation
All public/external functions and contract-level details are documented with NatSpec comments for clarity and best practices.

## Security Considerations
- Reentrancy protection: State changes before external calls.
- Custom errors for efficient gas usage.
- Only protocol can withdraw protocol fees.

## License
MIT

## Contact
For questions or support, open an issue or contact the repository maintainer.

## raisebox protocol flow:
user hosts a raise on raisebox protocol
contributors contribute to the raise
raise passes
raise owner host proposals as milestones are reached requesting a percentage of raised amount
contributors vote on proposal to determine if drip will be approved or rejected
drip is released on successful proposal/milestone
same flow untill entire raise is released to raise host and what they are building is achieved

host raise -> contribute to raise -> host proposal -> vote on proposal -> drip raise percentage --

raise failure instances:
failed proposals exxceed max failed proposals allowed
total proposals >= max proposals
block.timestamp > projectDuration(60 weeks)

