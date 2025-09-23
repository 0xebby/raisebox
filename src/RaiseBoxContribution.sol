// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
// import {RaiseBox} from "../src/RaiseBox.sol";

import {IRaiseBoxProjectCreation} from "../src/interfaces/IRaiseBoxProjectCreation.sol";
import {IRaiseBoxContribution} from "../src/interfaces/IRaiseBoxContribution.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {RaiseBoxStorage} from "../src/RaiseBoxStorage.sol";
import {ICore} from "../src/interfaces/ICore.sol";

contract RaiseBoxContribution is ReentrancyGuard, RaiseBoxStorage {
    address raiseBoxCoreaddress = 0x5FbDB2315678afecb367f032d93F642f64180aa3;
    IRaiseBoxProjectCreation public immutable i_raiseBoxCore;

    ICore public raiseBoxCore;

    using Strings for uint256;
    using Address for address;

    // contributions/users related state variables:
    mapping(address => uint256) public contributorsToAmountContributed; // not project dependent

    mapping(address contributor => mapping(bytes32 projectId => uint256 amtContributed))
        public amountContributedToProject;

    mapping(bytes32 => address[]) private contributors;

    // amount per contribution
    mapping(address => mapping(bytes32 => uint256))
        public amountPerContribution;

    uint256 public constant MAX_CONTRIBUTION_PERCENTAGE = 20; // 2% OF AMOUNT TO RAISE

    // tracks total amounts contributed to project

    uint256 public totalContributionsToProject;

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

    error RaiseBoxContribution_contribute_ContributionAboveMax(uint256);

    // contribution related events:
    event Contributed(
        address indexed user,
        uint256 indexed amount,
        bytes32 indexed projectId,
        uint256 amountRaised
    );

    // constructor(address raiseBoxCoreaddress_) {
    //     raiseBoxCoreaddress = raiseBoxCoreaddress_;
    //     i_raiseBoxCore = IRaiseBoxCore(raiseBoxCoreaddress_);
    // }

    constructor(address raiseBoxCoreAddress) RaiseBoxStorage() {
        raiseBoxCore = ICore(raiseBoxCoreAddress);
    }

    function contribute(
        uint256 amount,
        bytes32 projectId
    ) external payable nonReentrant {
        // projectId should be filled automatically via UI for project clicked by user

        // Checks

        if (projectId == 0) {
            revert RaiseBoxContribution_InvalidProject();
        }

        address projectOwner = raiseBoxCore.getProject(projectId).projectOwner;
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

        address payable raiseBoxProtocol = raiseBoxCore.getProtocol();
        if (raiseBoxProtocol == address(0)) {
            revert RaiseBoxContribution_RaiseBoxProtocolUnset();
        }

        uint256 amtToRaise = raiseBoxCore.getAmountToRaise(projectId);
        // uint256 amountRaisedByProject = raiseBoxCore.getAmountRaisedByProject(
        //     projectId
        // );

        uint256 maxContribution = calMaxContribution(projectId, amtToRaise);

        if (
            amountContributedToProject[msg.sender][projectId] + amount >
            maxContribution
        ) {
            revert RaiseBoxContribution_contribute_ContributionAboveMax(
                amtToRaise
            );
        }

        if (totalContributionsToProject == amtToRaise) {
            revert RaiseBox_RaiseEnded(projectId);
        }

        uint256 amountToTarget = (amtToRaise - totalContributionsToProject);
        uint256 totalToRaise = (amount + totalContributionsToProject);

        require(
            (totalToRaise <= amtToRaise),
            string(
                abi.encodePacked(
                    "Cannot over contribute: you can contribute only:",
                    amountToTarget.toString(),
                    " ether more"
                )
            )
        );

        // Effects
        amountContributedToProject[msg.sender][projectId] += amount;

        amountPerContribution[msg.sender][projectId] = amount;

        totalContributionsToProject += amount;

        // raiseBoxCore.updateAmountRaisedByProject(projectId, amount);

        if (totalContributionsToProject == amtToRaise) {
            raiseBoxCore.updateStorage(
                projectId,
                "name",
                msg.sender,
                "cook",
                100 ether,
                3 days,
                true,
                block.timestamp,
                totalContributionsToProject,
                0,
                0
            );
        }

        emit Contributed(
            msg.sender,
            amount,
            projectId,
            raiseBoxCore.getAmountRaisedByProject(projectId)
        );

        // Interactions
        (bool successfullyContributed, ) = raiseBoxProtocol.call{value: amount}(
            ""
        ); // funds sent to protocol for safekeeping pending release to project
        if (!successfullyContributed) {
            revert RaiseBoxContribution_ContributionFailed();
        }

        if (totalContributionsToProject == amtToRaise) {
            emit RaiseBox_RaisePassed(amtToRaise);
        }
    }

    receive() external payable {}

    // function getContributions(
    //     address contributor,
    //     bytes32 projectId
    // ) external view returns (uint256) {
    //     return amountContributedToProject[contributor][projectId];
    // }

    // function getContributors(
    //     bytes32 projectId
    // ) external view returns (address[] memory) {
    //     return contributors[projectId];
    // }

    // function getTotalAmountContributedByContributor(
    //     address _contributor,
    //     bytes32 _projectId
    // ) public view returns (uint256) {
    //     return amountContributedToProject[_contributor][_projectId];
    // }

    // function getRemainingContributionInEth(
    //     bytes32 projectId
    // ) external returns (uint256 remainingWei) {
    //     uint256 targetWei = i_raiseBoxCore.getAmountToRaise(projectId);
    //     uint256 raisedWei = i_raiseBoxCore.getAmountRaisedByProject(projectId);

    //     remainingWei = raisedWei >= targetWei ? 0 : targetWei - raisedWei;
    // }

    function calMaxContribution(
        bytes32 projectId,
        uint256 amountToRaise
    ) internal returns (uint256) {
        return ((MAX_CONTRIBUTION_PERCENTAGE * amountToRaise) / 100);
    }

    // function getMaxContribution(
    //     bytes32 projectId,
    //     uint256 amtToRaise
    // ) external returns (uint256) {
    //     return calMaxContribution(projectId, amtToRaise);
    // }
}
