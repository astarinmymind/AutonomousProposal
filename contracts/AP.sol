//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

interface IAaveGovernanceV2 {

    function create(
        address executor,
        address[] memory targets,
        uint256[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas,
        bool[] memory withDelegatecalls,
        bytes32 ipfsHash
    ) external returns (uint256);

}

/**
 * @title Autonomous Proposal
 * @dev This contract emits the proposal id and creator of the AP, which is 
 *      returned by calling the create function of Aave Governance V2. 
 *      It is called by the Factory contract when the AP attains enough
*       delegated proposition power.
 * @author Angela Lu
 **/
contract AP {

    event APcreated(uint256 indexed proposalId, address indexed creator);

    constructor(
        address creator,
        address _governance,
        address _executor,
        address[] memory _targets,
        uint256[] memory _values,
        string[] memory _signatures,
        bytes[] memory _calldatas,
        bool[] memory _withDelegatecalls,
        bytes32 _ipfsHash
    ) {
        uint256 proposalId = IAaveGovernanceV2(_governance).create(
            _executor,
            _targets,
            _values,
            _signatures,
            _calldatas,
            _withDelegatecalls,
            _ipfsHash
        );
        emit APcreated(proposalId, creator);
    }
}