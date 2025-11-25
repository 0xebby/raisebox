# raisebox

## Overview
raisebox is a decentralized crowdfunding protocol built with Solidity and going to be future-proofed with zk proofs. It allows contributors to fund project(s) they care about, this funds are dripped based on milestones reached by the project creator(s). 

## Features
- **Project Creation:** Anyone looking to raise funds for a project can create one with just a wallet address**
- **Contribution:** Anyone can contribute ETH to a project, subject to a minimum contribution of 0.01e
- **Host Proposals:** Proposals are milestones achieved since creating the project and requesting for raise, every proposal is voted on by contributors and if passes, % of funds are dripped and so on.
- **Voting** Contributors vote on the outcome of proposals to determine if drips are released or not

## Contract Details
- **Project Owner:** Receives contributed ETH on each milestone proposal passage.
- **Protocol:** Receives protocol fees and can withdraw them.
- **Minimum Contribution:** 0.01 ETH.

## Deployment

### Prerequisites
- [Foundry](https://book.getfoundry.sh/) installed
- Sepolia or other EVM-compatible network access
- Sufficient ETH for deployment and initial contributions

### Deployment Script
The contract can be deployed using the provided Foundry script:

**File:** `script/DePloyRaiseBoxCore.s.sol`

```solidity
contract DeployRaiseBoxCore is Script {
    function run() public {
        // main contract that holds general storage
        RaiseBoxCore raiseBoxCore;

        // project creation contract
        RaiseBox raiseBoxProjectCreationContract;

        // contribution contract
        RaiseBoxContribution raiseBoxContributionContract;

        // proposal contract
        RaiseBoxProposal raiseBoxProposalContract;
        vm.startBroadcast();

        raiseBoxCore = new RaiseBoxCore();

        raiseBoxProjectCreationContract = new RaiseBox(address(raiseBoxCore));

        raiseBoxCore.setProjectCreationContractAddress(address(raiseBoxProjectCreationContract));

        raiseBoxContributionContract = new RaiseBoxContribution(address(raiseBoxCore));

        raiseBoxCore.setContributionContractAddress(address(raiseBoxContributionContract));

        raiseBoxProposalContract = new RaiseBoxProposal(address(raiseBoxCore), address(0)); // set voting contract address later

        raiseBoxCore.setProposalContractAddress(address(raiseBoxProposalContract));

        RaiseBoxVoting raiseBoxVotingContract =
            new RaiseBoxVoting(address(raiseBoxCore), address(raiseBoxContributionContract));

        raiseBoxCore.setVotingContractAddress(address(raiseBoxVotingContract));

        // now set the voting contract address in proposal contract
        raiseBoxProposalContract = new RaiseBoxProposal(address(raiseBoxCore), address(raiseBoxVotingContract));
        vm.stopBroadcast();
    }
}
```
Replace `<PROJECT_OWNER_ADDRESS>` with the desired EOA address.

#### Deploy via Foundry
```bash
forge script script/DeployCrowdFund.s.sol --rpc-url <SEPOLIA_RPC_URL> --broadcast --verify
```

## Usage

### Contribute
Call the `contribute(uint256 amount)` function, sending ETH with the transaction. The `amount` parameter should match the ETH sent (`msg.value`).

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

