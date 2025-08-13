// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @title CrowdFund - Decentralized crowdfunding contract
/// @author devhat
/// @notice This contract allows users to contribute ETH to a project, collects protocol fees, and enables withdrawals for project owner and protocol.
/// @dev Designed for EVM-compatible blockchains. Uses custom errors for gas efficiency.
contract CrowdFund {
    // State variables
    address public projectOwner;
    address public protocol;
    mapping(address => uint256) public contributorsToAmountContributed;
    mapping(address => bool) public hasContributed;
    address[] public contributors;
    uint256 public totalAmountContributed;
    uint256 public totalProtocolFees;
    uint256 private constant PROTOCOL_FEE = 5; // 5%
    uint256 public constant MINIMUM_CONTRIBUTION = 0.00001 ether; // 1e13
    uint256 public constant MAX_PERCENTAGE = 100;

    // Errors
    error ContributeMoreEth();
    error NoContributionMade();
    error ContributionFailed();
    error NoFeesToWithdraw();
    error FeesWithdrawalFailed();
    error OnlyProtocolCanWithdrawFees();
    error InvalidContributionAmount();

    // Constructor
    /// @notice Initializes the contract with the project owner and protocol address
    /// @param _projectOwner The address of the project owner who will receive contributions
    constructor(address _projectOwner) {
        require(
            _projectOwner != address(0),
            "Zero address cannot be projectOwner"
        );
        projectOwner = _projectOwner;
        protocol = msg.sender;
    }

    // Calculate protocol fee (5% of contribution)
    /// @notice Calculates the protocol fee for a given contribution
    /// @param _contribution The amount contributed
    /// @return The protocol fee amount
    function calculateProtocolFees(
        uint256 _contribution
    ) public pure returns (uint256) {
        if (_contribution == 0) {
            revert NoContributionMade();
        }
        return (PROTOCOL_FEE * _contribution) / MAX_PERCENTAGE;
    }

    // Contribute ETH to the project
    /// @notice Contribute ETH to the project
    /// @dev Send ETH with this function. Protocol fee is deducted and sent to protocol address.
    /// @param amount The amount of ETH to contribute (should match msg.value)
    function contribute(uint256 amount) public payable {
        // Checks
        if (amount < MINIMUM_CONTRIBUTION) {
            revert ContributeMoreEth();
        }
        // if (amount != msg.value) {
        //     revert InvalidContributionAmount();
        // }

        uint256 protocolFee = calculateProtocolFees(amount);
        uint256 actualAmountContributed = amount - protocolFee;

        // Effects
        totalAmountContributed += actualAmountContributed;
        totalProtocolFees += protocolFee;
        if (!hasContributed[msg.sender]) {
            contributors.push(msg.sender);
            hasContributed[msg.sender] = true;
        }
        contributorsToAmountContributed[msg.sender] += amount;

        // Interactions
        (bool success, ) = projectOwner.call{value: actualAmountContributed}(
            ""
        );
        if (!success) {
            revert ContributionFailed();
        }
    }

    // Withdraw accumulated protocol fees
    /// @notice Withdraw accumulated protocol fees to the protocol address
    /// @dev Only callable by protocol address
    function withdrawProtocolFees() external {
        if (msg.sender != protocol) {
            revert OnlyProtocolCanWithdrawFees();
        }
        if (totalProtocolFees == 0) {
            revert NoFeesToWithdraw();
        }

        uint256 feesToWithdraw = totalProtocolFees;
        totalProtocolFees = 0; // Reset before transfer to prevent reentrancy

        // Interactions
        (bool success, ) = protocol.call{value: feesToWithdraw}("");
        if (!success) {
            revert FeesWithdrawalFailed();
        }
    }

    // Allow contract to receive ETH
    /// @notice Allow contract to receive ETH directly
    receive() external payable {}
}
