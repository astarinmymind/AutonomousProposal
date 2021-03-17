//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

contract APFactory {

    bytes public bytecode;

    mapping (address => uint256) proposalCounts;

    event APdeployed(address indexed proposalAddress, address indexed creator);

    constructor(bytes memory _bytecode) {
        bytecode = _bytecode;
    }

    function deployAP(
        address creator,
        address governance,
        address executor,
        address[] memory targets,
        uint256[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas,
        bool[] memory withDelegatecalls,
        bytes32 ipfsHash
    ) external returns (address proposalAddress) {

        bytes memory initCodeWithArgs;
        {
            bytes memory initCode = bytecode;
            bytes memory args = abi.encode(
                creator,
                governance,
                executor,
                targets,
                values,
                signatures,
                calldatas,
                withDelegatecalls,
                ipfsHash
            );
            initCodeWithArgs = abi.encodePacked(initCode, args);
        }
        bytes32 initCodeHash = keccak256(initCodeWithArgs);

        uint256 proposalCount = proposalCounts[msg.sender];
        bytes32 salt = _calculateSalt(msg.sender, proposalCount);

        address expectedProposalAddress = _calculateAddress(
            msg.sender, proposalCount, initCodeHash    
        );
        assembly {
            proposalAddress := create2(
                0, add(32, initCodeWithArgs), mload(initCodeWithArgs), salt
            )
        }
        require(proposalAddress == expectedProposalAddress, "create2 failed");
        proposalCounts[msg.sender]++;

        emit APdeployed(proposalAddress, creator);
    }

    function calculateAddress(
        address creator,
        address governance,
        address executor,
        address[] memory targets,
        uint256[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas,
        bool[] memory withDelegatecalls,
        bytes32 ipfsHash
    ) public view returns (address predictedAddress) {
        bytes memory initCodeWithArgs;
        {
            bytes memory initCode = bytecode;
            bytes memory args = abi.encode(
                creator,
                governance,
                executor,
                targets,
                values,
                signatures,
                calldatas,
                withDelegatecalls,
                ipfsHash
            );
            initCodeWithArgs = abi.encodePacked(initCode, args);
        }
        bytes32 initCodeHash = keccak256(initCodeWithArgs);
        uint256 proposalCount = proposalCounts[creator];
        predictedAddress = _calculateAddress(creator, proposalCount, initCodeHash);
    }

    function _calculateAddress(
        address creator, uint256 proposalCount, bytes32 initCodeHash
    ) internal view returns (address addressPrediction) {
        bytes32 salt = _calculateSalt(creator, proposalCount);
        addressPrediction = address(uint160(uint256(keccak256(abi.encodePacked(
            bytes1(0xff), address(this), salt, initCodeHash
        )))));
    }

    function calculateSalt(address creator, uint256 proposalCount) public pure returns (bytes32 salt) {
        salt = _calculateSalt(creator, proposalCount);
    }

    function _calculateSalt(address creator, uint256 proposalCount) internal pure returns (bytes32 salt) {
        salt = keccak256(abi.encodePacked(creator, proposalCount));
    }

}
