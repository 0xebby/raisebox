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
        // contracts:
        RaiseBoxCore raiseBoxCore;
        RaiseBox raiseBoxProjectCreationContract;
        RaiseBoxContribution raiseBoxContributionContract;
        RaiseBoxProposal raiseBoxProposalContract;


        vm.startBroadcast();

        raiseBoxCore = new RaiseBoxCore();

        raiseBoxProjectCreationContract = new RaiseBox(address(raiseBoxCore));

        raiseBoxCore.setProjectCreationContractAddress(address(raiseBoxProjectCreationContract));

        raiseBoxContributionContract = new RaiseBoxContribution(address(raiseBoxCore));

        raiseBoxCore.setContributionContractAddress(address(raiseBoxContributionContract));

        // set voting contract address later - circular dependency
        raiseBoxProposalContract = new RaiseBoxProposal(address(raiseBoxCore), address(0)); 

        raiseBoxCore.setProposalContractAddress(address(raiseBoxProposalContract));

        RaiseBoxVoting raiseBoxVotingContract =
            new RaiseBoxVoting(address(raiseBoxCore), address(raiseBoxContributionContract));

        raiseBoxCore.setVotingContractAddress(address(raiseBoxVotingContract));

        raiseBoxProposalContract = new RaiseBoxProposal(address(raiseBoxCore), address(raiseBoxVotingContract));


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
 -->


# RaiseBox

**RaiseBox** is a milestone-based decentralized crowdfunding protocol that enables permissionless fundraising, contributor-driven governance, and conditional fund release through on-chain voting.

Anyone with a wallet can be whitelisted, create a raise for a project or idea, receive contributions, and unlock funds incrementally as milestones are completed and approved by contributors.

RaiseBox replaces trust with enforceable rules. Funds are not released because a project owner says work is done, but because contributors collectively verify and approve progress on-chain.

---

## Table of Contents

- [Problem Statement](#problem-statement)
- [What Makes RaiseBox Different](#what-makes-raisebox-different)
- [Core Principles](#core-principles)
- [High-Level Architecture](#high-level-architecture)
- [Raise Lifecycle](#raise-lifecycle)
- [Milestone-Based Fund Release](#milestone-based-fund-release)
- [Voting System](#voting-system)
- [Contributor Eligibility](#contributor-eligibility)
- [Contributor Protection Model](#contributor-protection-model)
- [Smart Contract Design Philosophy](#smart-contract-design-philosophy)
- [State Management](#state-management)
- [Security Considerations](#security-considerations)
- [Tech Stack](#tech-stack)
- [Development Workflow](#development-workflow)
- [Testing Strategy](#testing-strategy)
- [Future Features](#future-features)
- [Roadmap](#roadmap)
- [License](#license)

---

## Problem Statement

Crowdfunding today relies heavily on trust and centralized enforcement.

Contributors have little to no control after funds are sent. Project owners often receive capital upfront with weak accountability. Voting systems, when present, are usually off-chain or non-binding.

RaiseBox solves this by making funding conditional, governance enforceable, and progress approval decentralized.

---

## What Makes RaiseBox Different

- Milestone-based funding instead of lump-sum raises
- One wallet, one vote governance
- Minimum contribution gated voting
- Permissionless raise creation
- Incremental fund drips tied to verified progress
- No centralized authority controlling funds

---

## Core Principles

- **Permissionless participation**  
  Anyone with a wallet can participate in the system.

- **Contributor sovereignty**  
  Contributors collectively decide when funds are released.

- **Explicit state machines**  
  Every raise and milestone follows deterministic state transitions.

- **No trust assumptions**  
  All critical rules are enforced at the contract level.

- **Composable and auditable design**  
  Contracts are modular, minimal, and security-first.

---

## High-Level Architecture

RaiseBox is composed of modular contracts with strict boundaries.





Each contract owns its storage and exposes minimal interfaces for interaction.

---

## Raise Lifecycle

Each raise progresses through well-defined states.

### Example Raise States

- `CREATED`
- `ACTIVE`
- `MILESTONE_VOTING`
- `MILESTONE_PASSED`
- `MILESTONE_FAILED`
- `REFUNDING`
- `CLOSED`

Invalid transitions revert. No implicit state changes exist.

---

## Milestone-Based Fund Release

Raises are defined as a sequence of milestones.

Each milestone specifies:
- A description of work to be completed
- A portion of the total raise amount
- A voting window

Funds are not released upfront. When a milestone is submitted:

1. Contributors vote on whether the milestone has been successfully completed
2. If the vote passes, the allocated portion of funds is released to the project owner
3. If the vote fails, the system can either retry, pause, or move to refunds depending on configuration

This ensures continuous accountability throughout the lifecycle of the project.

---

## Voting System

RaiseBox uses a **one wallet, one vote** governance model.

### Key Properties

- Each eligible wallet can vote once per milestone
- Voting power is not weighted by contribution size
- Voting is strictly tied to milestone approval
- Votes are on-chain, verifiable, and binding
- Voting windows are time-boxed

There is no delegation or off-chain signaling.

---

## Contributor Eligibility

To participate in voting, a wallet must:

- Have contributed at least the minimum contribution amount for the raise
- Hold a valid contributor record for that raise
- Vote within the active voting window

This prevents spam voting while maintaining fairness and accessibility.

---

## Contributor Protection Model

RaiseBox is designed to protect contributors by default.

### Built-in Safeguards

- Funds are held in escrow until milestones are approved
- Project owners cannot withdraw funds arbitrarily
- Voting outcomes directly control fund release
- Refund paths are explicitly encoded
- Unauthorized access attempts revert at the contract level

There are no admin overrides.

---

## Smart Contract Design Philosophy

RaiseBox contracts follow strict architectural rules:

- Contracts only mutate their own storage
- External contracts interact through explicit interfaces
- Getters are used for state inspection
- State changes are guarded by precondition checks
- Custom errors are centralized for clarity and gas efficiency

This approach improves auditability and long-term maintainability.

---

## State Management

- Enums model raise and milestone states
- Structs act as storage containers, not logic abstractions
- Nested mappings track contributor and milestone data
- All state transitions are explicit and validated

The system behaves as a deterministic state machine.

---

## Security Considerations

RaiseBox assumes adversarial conditions.

### Threats Considered

- Malicious project owners
- Coordinated voting abuse
- Unauthorized contract calls
- Reentrancy and external call risks
- Invalid state transitions

### Mitigations

- Strict caller validation
- Checks-effects-interactions pattern
- Time-bounded voting
- Revert-on-failure logic
- Minimal trusted surface area

Security is a first-class design constraint.

---

## Tech Stack

- Solidity for smart contracts
- Foundry for development, testing, and fuzzing
- EVM-compatible blockchains
- Modular interfaces for frontend and protocol integrations

---

## Development Workflow

```bash
forge install
forge build
forge test
forge test --fuzz
