// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IRaiseBoxCore {
    struct ProjectInfo {
        string projectName;
        address projectOwner;
        string valueProposition;
        uint256 amountToRaise;
        uint256 duration;
        bytes32 raiseId;
        bool projectExists;
        uint256 timeCreated;
        uint256 amountRaisedByProject;
        uint256 proposalsHosted;
        uint256 numberOfProjectsCreatedByProjectOwner;
    }

    // errors:

    // getter errors:
    error RaiseBoxCore_getProject_InvalidProjectId();
    error RaiseBoxCore_getAmountToRaise_InvalidProjectId();
    error RaiseBoxCore_getAmtRaisedByProject_InvalidProjectId();

    error RaiseBox_RaiseEnded(bytes32);
    error RaiseBoxCore_updateStorage_wrongCaller();
    error RaiseBoxCore_getRaiseBoxProjectCount_CallNotFromProjectCreation();
    error RaiseBoxCore_NotAuthorized();
    error RaiseBoxCore_UnAuthorizedCaller();
    error InvalidContract();
    error RaiseBox_updateStorage_NotAValidProjectID();
    error RaiseBoxCore_getProtocol_RaiseBoxProtocolUnset();
    error RaiseBoxCore_setRaiseCreation_InvalidCA();
    error RaiseBoxCore_setRaiseCreation_ContractAlreadySet();
    error RaiseBoxCore_setRaiseContribution_ContractAlreadySet();
    error RaiseBoxCore_setRaiseContribution_InvalidContract();
    error NotProposalContract();
    error RaiseBoxCore_NotSupportedToken();
    error RaiseBoxCore_setDripHandler_InvalidContract();

    // events:

    event RaiseBox_RaisePassed(uint256 amountToRaise, uint256 amountRaised);
    event RaiseCreationDetailsUpdated(bytes32);
    event RaiseBoxCore_RaiseCreationContractSet(address contractAddress);
    event RoleGranted(bytes32 indexed role, address indexed account);
    event RoleRevoked(bytes32 indexed role, address indexed account);
    event ContributionContractSet(address indexed contractAddress);
    event ProposalContractSet(address indexed contractAddress);
    event VotingContractSet(address indexed contractAddress);
    event RaiseHostedProposalsUpdated();
    event AmountRaisedUpdateSuccessful();
    event RaiseBoxCore_AcceptedTokenSet(address indexed acceptedToken);
    event DripperContractSet(address contractAddress);

    // raiseBoxCore methods:

    function getRaiseCount() external returns (uint256);

    function getProtocol() external returns (address payable);

    function getMinimumContribution() external view returns (uint256);

    function getAmtRaisedByProject(bytes32 projectId_) external returns (uint256);

    function getProtocolFeeAddress() external view returns (address);

    function getProject(bytes32 id) external returns (ProjectInfo memory projectInfo);

    function getRaiseCreator(bytes32 raiseId) external view returns (address);

    function getRaiseInfo(bytes32 raiseId)
        external
        returns (
            string memory,
            address,
            string memory,
            uint256,
            uint256,
            bytes32,
            bool,
            uint256,
            uint256,
            uint256,
            uint256
        );

    function getAmountToRaise(bytes32 raiseId) external returns (uint256);

    function updateStorage(
        bytes32 raiseId,
        string memory _projectName,
        address _projectOwner,
        string memory _valueProposition,
        uint256 _amountToRaise,
        uint256 _duration,
        bool _exist,
        uint256 _wenProjectCreated,
        uint256 _amountRaisedByProject,
        uint256 _noOfProposalsHosted,
        uint256 _numberOfProjectsCreatedByProjectOwner
    ) external;

    function incrementRaiseCount() external;

    function doesRaiseExist(bytes32 raiseId) external view returns (bool);

    function updateNumOfProposals(bytes32 raiseId) external;

    function getRaiseBoxOwner() external view returns (address);

    function getAcceptedToken() external view returns (address);

    // contribution methods:

    function updateAmountRaisedInStorage(bytes32 raiseId, uint256 amountRaised) external;

    // proposal methods;

    // voting methods:

    // expose all the contract addresses using the getters;
}
