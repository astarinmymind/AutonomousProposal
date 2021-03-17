//SPDX-License-Identifier: Unlicense
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

contract AP {

    address public creator;

    event APcreated(uint256 indexed proposalId, address indexed creator);

    constructor(
        address _creator,
        address _governance,
        address _executor,
        address[] memory _targets,
        uint256[] memory _values,
        string[] memory _signatures,
        bytes[] memory _calldatas,
        bool[] memory _withDelegatecalls,
        bytes32 _ipfsHash
    ) {
        creator = _creator;
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