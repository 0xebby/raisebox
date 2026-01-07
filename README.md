RaiseBox
Milestone-based decentralized crowdfunding with enforceable, on-chain accountability.
RaiseBox is a permissionless crowdfunding protocol that replaces trust with verifiable rules.
Funds are not released because a project owner claims progress, but because contributors collectively approve milestones on-chain.
RaiseBox enables creators to raise capital transparently while giving contributors real control over how and when funds are released.
Table of Contents
Overview
Problem Statement
What Makes RaiseBox Different
Core Principles
Protocol Flow
Raise Lifecycle
Milestone-Based Fund Release
Voting System
Contributor Eligibility
Raise Failure Conditions
High-Level Architecture
Smart Contract Design Philosophy
Security Considerations
Tech Stack
Development Workflow
Deployment
Usage
Future Roadmap
License
Overview
RaiseBox is a milestone-driven decentralized crowdfunding protocol built in Solidity and designed to be future-proofed with zero-knowledge proofs.
Anyone can create a raise, contribute funds, and participate in governance. Funds are escrowed by the protocol and released incrementally only when contributors approve completed milestones through on-chain voting.
There are no admins, no discretionary withdrawals, and no off-chain enforcement.
Problem Statement
Traditional crowdfunding relies heavily on trust and centralized enforcement:
Funds are often released upfront
Contributors lose control after contributing
Accountability is weak or entirely off-chain
Dispute resolution is opaque and centralized
RaiseBox fixes this by making funding conditional, governance binding, and progress verification decentralized.
What Makes RaiseBox Different
Milestone-based funding instead of lump-sum payouts
Contributor-driven, on-chain governance
One wallet, one vote (not capital-weighted)
Permissionless raise creation
Escrowed funds with conditional release
Explicit refund and failure paths
No centralized authority or admin override
Core Principles
Permissionless Participation
Anyone with a wallet can create a raise, contribute, and vote.
Contributor Sovereignty
Contributors collectively control when funds are released.
Explicit State Machines
All raises and proposals follow deterministic state transitions.
No Trust Assumptions
Critical rules are enforced entirely at the contract level.
Modular & Auditable Design
Contracts are minimal, composable, and security-first.
Protocol Flow
Copy code

Host Raise
   ↓
Contribute to Raise
   ↓
Raise Becomes Active
   ↓
Host Proposal (Milestone)
   ↓
Contributors Vote
   ↓
If Passed → Drip Funds
If Failed → Track Failure
   ↓
Repeat Until Completion or Failure
Raise Lifecycle
Each raise progresses through strictly defined states.
Example States
CREATED
ACTIVE
MILESTONE_VOTING
MILESTONE_PASSED
MILESTONE_FAILED
REFUNDING
CLOSED
Invalid transitions revert automatically.
There are no implicit or automatic state changes.
Milestone-Based Fund Release
Raises are executed as a sequence of proposals (milestones).
Each proposal specifies:
Work completed
Percentage of total funds requested
Voting duration
How It Works
Funds remain escrowed in the protocol
The raise owner submits a milestone proposal
Contributors vote during a fixed window
If approved, the specified percentage is released
If rejected, failure counters are updated
This ensures continuous accountability throughout the raise lifecycle.
Voting System
RaiseBox uses a one wallet, one vote governance model.
Key Properties
Each eligible wallet votes once per proposal
Voting power is not weighted by contribution size
Votes are on-chain, verifiable, and binding
Voting windows are time-boxed
No delegation or off-chain signaling
Voting directly determines whether funds are released.
Contributor Eligibility
To vote on a proposal, a wallet must:
Have contributed at least the minimum contribution
Be registered as a contributor for that raise
Vote within the active voting window
This prevents spam while maintaining fairness and accessibility.
Raise Failure Conditions
A raise enters failure or refund states when any of the following occur:
Failed proposals exceed the maximum allowed
Total proposals reach the maximum limit
block.timestamp exceeds the project duration (e.g. 60 weeks)
Failure logic is deterministic and enforced on-chain.
High-Level Architecture
RaiseBox is composed of modular contracts with strict boundaries.
Each contract:
Owns its own storage
Exposes minimal interfaces
Interacts only through explicit calls
Core Contracts
RaiseBoxCore – Central state registry and coordination layer
RaiseBox – Raise creation and metadata
RaiseBoxContribution – Contribution handling and contributor records
RaiseBoxProposal – Milestone proposal logic
RaiseBoxVoting – Voting and outcome resolution
Smart Contract Design Philosophy
Contracts only mutate their own storage
Explicit interfaces for all cross-contract interactions
Getters for state inspection
Precondition checks on all state transitions
Centralized custom errors for gas efficiency
Deterministic, auditable behavior
RaiseBox behaves as a verifiable state machine, not a black box.
Security Considerations
RaiseBox is designed under adversarial assumptions.
Threats Considered
Malicious project owners
Coordinated voting abuse
Unauthorized contract calls
Reentrancy attacks
Invalid state transitions
Mitigations
Strict caller validation
Checks-effects-interactions pattern
Time-bounded voting
Revert-on-failure logic
No admin keys or overrides
Security is a first-class constraint, not an afterthought.
Tech Stack
Solidity
Foundry (Forge, Cast, Fuzzing)
EVM-compatible chains (e.g. Sepolia)
Modular interfaces for frontend integrations
Development Workflow
Copy code
Bash
forge install
forge build
forge test
forge test --fuzz
Deployment
Prerequisites
Foundry installed
EVM-compatible RPC (e.g. Sepolia)
ETH for deployment
Deploy Script
File: script/DeployRaiseBoxCore.s.sol
Copy code
Bash
forge script script/DeployRaiseBox.s.sol \
  --rpc-url <RPC_URL> \
  --broadcast \
  --verify
Usage
Contribute
Call contribute(uint256 amount) and send matching msg.value.
Voting
Eligible contributors vote during the active proposal window.
Fund Release
Funds are released automatically upon successful proposal passage.
Future Roadmap
ZK-based private voting
Cross-chain raises
DAO-controlled protocol parameters
Frontend SDKs
Advanced analytics and dashboards
License
MIT