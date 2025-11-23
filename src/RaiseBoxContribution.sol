// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
// import {RaiseBox} from "../src/RaiseBox.sol";

// import {IRaiseBoxProjectCreation} from "../src/interfaces/IRaiseBoxProjectCreation.sol";
import {IRaiseBoxContribution} from "../src/interfaces/IRaiseBoxContribution.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {RaiseBoxCore} from "../src/RaiseBoxCore.sol";
import {IRaiseBoxCore} from "../src/interfaces/IRaiseBoxCore.sol";

contract RaiseBoxContribution is ReentrancyGuard, RaiseBoxCore, IRaiseBoxContribution {
    // address raiseBoxCoreaddress = 0x5FbDB2315678afecb367f032d93F642f64180aa3;

    IRaiseBoxCore public raiseBoxCore; // the central contract that holds main storage of raisebox

    using Strings for uint256;
    using Address for address;

    // contributions/users related state variables:
    mapping(address => uint256) public contributorsToAmountContributed; // not project dependent

    mapping(address contributor => mapping(bytes32 projectId => uint256 amtContributed)) public
        amountContributedToProject;

    mapping(bytes32 => address[]) private contributors;

    mapping(bytes32 => mapping(address => bool)) private hasContributed;

    mapping(address => mapping(bytes32 => uint256[])) public contributionsToProjectArray; // array of contributions per user per project

    uint256 public constant MAX_CONTRIBUTION_PERCENTAGE = 20; // 2% OF AMOUNT TO RAISE

    // tracks total amount contributed to project

    mapping(bytes32 => uint256) public totalContributionsToProject;

    // contribution state enum
    enum ContributionState {
        CONTRIBUTION_LIVE,
        CONTRIBUTION_ENDED,
        WITHDRAWING_PROTOCOL_FEES
    }

    // contribution related errors:
    error RaiseBoxContribution_ValueSentMismatch();
    error RaiseBoxContribution_ContributeMoreEth(uint256);
    error RaiseBoxContribution_ZeroAmount();
    error RaiseBoxContribution_ContributionFailed();
    error RaiseBoxContribution_InvalidProject();
    error RaiseBoxContribution_RaiseBoxProtocolUnset();
    error RaiseBoxContribution_ContributeAmountRemaining(uint256);
    error RaiseContribution_ContributionEnded(uint256);
    error RaiseBoxContribution_contribute_ContributionAboveMax(uint256, string);
    error RaiseBoxContribution_getMaxContributionAllowedForProject_CannotBeZero();

    // contribution related events:
    event Contributed(address indexed user, uint256 indexed amount, bytes32 indexed projectId, uint256 amountRaised);

    constructor(address raiseBoxCoreAddress) RaiseBoxCore() {
        raiseBoxCore = IRaiseBoxCore(raiseBoxCoreAddress);
    }

    function contribute(uint256 amount, bytes32 projectId) external payable nonReentrant {
        // projectId should be filled automatically via UI for project clicked by user

        // Checks

        if (projectId == 0) {
            revert RaiseBoxContribution_InvalidProject();
        }

        // get valid project from storage
        ProjectInfo memory project = raiseBoxCore.getProject(projectId);

        address projectOwner = project.projectOwner;
        if (projectOwner == address(0)) {
            revert RaiseBoxContribution_InvalidProject();
        }

        if (amount == 0) {
            revert RaiseBoxContribution_ZeroAmount();
        }

        uint256 minContribution = raiseBoxCore.getMinimumContribution();
        if (amount < minContribution) {
            revert RaiseBoxContribution_ContributeMoreEth(minContribution);
        }

        if (msg.value != amount) {
            revert RaiseBoxContribution_ValueSentMismatch();
        }

        // if (raiseBoxProtocol == address(0)) {
        //     revert RaiseBoxContribution_RaiseBoxProtocolUnset();
        // }

        uint256 amtToRaise = project.amountToRaise;

        uint256 maxContribution = calMaxContribution(projectId, amtToRaise);
        uint256 amountToTarget = (amtToRaise - totalContributionsToProject[projectId]);

        if (amountContributedToProject[msg.sender][projectId] + amount > maxContribution) {
            revert RaiseBoxContribution_contribute_ContributionAboveMax(
                amtToRaise,
                string(
                    abi.encodePacked(
                        "Cannot over contribute: you can contribute only:",
                        (amountToTarget / 1e18).toString(),
                        " ether more to this project"
                    )
                )
            );
        }

        if (totalContributionsToProject[projectId] == amtToRaise) {
            revert RaiseBox_RaiseEnded(projectId);
        }

        uint256 totalToRaise = (amount + totalContributionsToProject[projectId]);

        require(
            (totalToRaise <= amtToRaise),
            string(
                abi.encodePacked(
                    "Cannot over contribute: you can contribute only:", amountToTarget.toString(), " ether more"
                )
            )
        );

        // Effects
        amountContributedToProject[msg.sender][projectId] += amount;

        contributionsToProjectArray[msg.sender][projectId].push(amount);

        totalContributionsToProject[projectId] += amount;

        if (!hasContributed[projectId][msg.sender]) {
            contributors[projectId].push(msg.sender);
            hasContributed[projectId][msg.sender] = true;
        }

        // only update storage when raise has passed,
        // i.e. the amount to raise by project has been raised successfully
        // instead of updating storage everytime a contribution is made, wasteful
        if (totalContributionsToProject[projectId] == amtToRaise) {
            raiseBoxCore.updateStorage(
                projectId,
                "name",
                msg.sender,
                "cook",
                100 ether,
                3 days,
                true,
                block.timestamp,
                totalContributionsToProject[projectId], // only field updated
                0,
                0
            );
        }

        emit Contributed(
            msg.sender,
            amount,
            projectId,
            raiseBoxCore.getAmountRaisedByProject(projectId) // this should show that the main storage has been updated with totalContributionsToProject[projectid]
        );

        // Interactions
        // get protocol address so funds can be sent there:
        address payable raiseBoxProtocol = raiseBoxCore.getProtocol();
        (bool successfullyContributed,) = raiseBoxProtocol.call{value: amount}(""); // funds sent to protocol for safekeeping pending release to project
        if (!successfullyContributed) {
            revert RaiseBoxContribution_ContributionFailed();
        }

        if (totalContributionsToProject[projectId] == amtToRaise) {
            emit RaiseBox_RaisePassed(amtToRaise);
        }
    }

    receive() external payable {}

    // INTERNAL FUNCTIONS

    function calMaxContribution(bytes32 projectId, uint256 amountToRaise) internal returns (uint256) {
        return ((MAX_CONTRIBUTION_PERCENTAGE * amountToRaise) / 100);
    }

    // EXTERNAL/GETTER FUNCTIONS

    function getMaxContributionAllowedForProject(bytes32 projectId) external returns (uint256) {
        uint256 amountToRaise = raiseBoxCore.getAmountToRaise(projectId);
        if (amountToRaise == 0) {
            revert RaiseBoxContribution_getMaxContributionAllowedForProject_CannotBeZero();
        }
        return calMaxContribution(projectId, amountToRaise);
    }

    function getContributors(bytes32 projectId) external view returns (address[] memory) {
        return contributors[projectId];
    }

    function getContributionsToProject(address user, bytes32 projectId) external view returns (uint256[] memory) {
        return contributionsToProjectArray[user][projectId];
    }

    function getTotalContributionsToProject(bytes32 projectId) external returns (uint256 contributionsReceived) {
        if (!raiseBoxCore.doesProjectExist(projectId)) {
            revert RaiseBox_getProject_InvalidProjectId();
        }
        return totalContributionsToProject[projectId];
    }
    // testing
}
