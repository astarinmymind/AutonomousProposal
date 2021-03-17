//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

/**
 * @title Autonomous Proposal Factory
 * @dev This contract allows anyone to create an autonomous proposal (AP). 
 *      It is able to predetermine the address for an AP that people may
 *      delegate their proposition power to before it is deployed.
 *      Therefore, the creator only calls the create function if he/she
 *      knows it has enough proposition power to succeed, saving gas.
 * @author Angela Lu
 **/
contract APFactory {

    bytes public bytecode;
    mapping (address => uint256) proposalCounts;

    event APdeployed(address indexed proposalAddress, address indexed creator);

    constructor(bytes memory _bytecode) {
        bytecode = _bytecode;
    }

   /**
    * @dev When a predetermined AP address has enough delegated proposition power,
    *      deploy the AP using CREATE2 (https://eips.ethereum.org/EIPS/eip-1014)
    *      If successful, increment proposal count of creator and emit event.
    *
    * @notice The salt is generated with msg.sender, therefore only the creator is
    *         allowed to deploy his/her AP.
    *         This function takes in the same parameters as the AP address predictor,
    *         so the creator must input the exact same arguments in order to deploy
    *         the AP address with the delegated proposition power. 
    *         This prevents the creator from ex post facto altering the arguments of the AP.
    *
    * @param creator address of the creator of AP
    * @param governance address of AaveGovernanceV2
    * @param executor address of ExecutorWithTimelock contract that will execute the proposal
    * @param targets list of contracts called by proposal's associated transactions
    * @param values list of values (in wei) for each propoposal's associated transactions
    * @param signatures list of function signatures
    * @param calldatas list of calldatas
    * @param withDelegatecalls list of if transaction delegatecalls the target
    * @param ipfsHash IPFS hash of the proposal
    *
    * @return proposalAddress address of the deployed AP
    **/
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

        // get AP abi
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

        // calculate salt
        bytes32 salt = _calculateSalt(msg.sender, proposalCounts[msg.sender]);

        // deploy AP contract using CREATE2
        assembly {
            proposalAddress := create2(
                0, add(32, initCodeWithArgs), mload(initCodeWithArgs), salt
            )
        }

        // increment deployed proposal count nonce of creator
        proposalCounts[msg.sender]++;

        emit APdeployed(proposalAddress, creator);
    }

   /**
    * @dev Calculate the address of the AP **before** it is deployed.
    *
    * @param creator address of the creator of AP
    * @param governance address of AaveGovernanceV2
    * @param executor address of ExecutorWithTimelock contract that will execute the proposal
    * @param targets list of contracts called by proposal's associated transactions
    * @param values list of values (in wei) for each propoposal's associated transactions
    * @param signatures list of function signatures
    * @param calldatas list of calldatas
    * @param withDelegatecalls list of if transaction delegatecalls the target
    * @param ipfsHash IPFS hash of the proposal
    *
    * @return predictedAddress predicted address of AP
    **/
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

        // get AP abi
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

        // calculate hash of AP bytecode
        bytes32 initCodeHash = keccak256(initCodeWithArgs);

        // get proposal count nonce of creator
        uint256 proposalCount = proposalCounts[creator];

        // calculate address
        predictedAddress = _calculateAddress(creator, proposalCount, initCodeHash);
    }

   /**
    * @dev Predicts the address of the AP using CREATE2. 
    *
    * @param creator address of creator of AP
    * @param proposalCount number of AP's the creator has successfully deployed
    * @param initCodeHash hash of AP bytecode
    *
    * @return addressPrediction predicted address of AP
    **/
    function _calculateAddress(
        address creator, uint256 proposalCount, bytes32 initCodeHash
    ) internal view returns (address addressPrediction) {

        // calculate salt
        bytes32 salt = _calculateSalt(creator, proposalCount);

        // calculates predetermined address: 
        // encodes arguments according to CREATE2 spec
        // the address is [12:32] of the resulting hash
        addressPrediction = address(uint160(uint256(keccak256(abi.encodePacked(
            bytes1(0xff), address(this), salt, initCodeHash
        )))));
    }

   /**
    * @dev Gets salt for CREATE2.
    *
    * @param creator address of creator of AP
    * @param proposalCount number of AP's the creator has successfully deployed
    *
    * @return salt salt
    **/
    function calculateSalt(address creator, uint256 proposalCount) public pure returns (bytes32 salt) {
        salt = _calculateSalt(creator, proposalCount);
    }

   /**
    * @dev Calculates salt by hashing together address of creator and his/her number of deployed proposals.
    *
    * @param creator address of creator of AP
    * @param proposalCount number of AP's the creator has successfully deployed
    *
    * @return salt salt
    **/
    function _calculateSalt(address creator, uint256 proposalCount) internal pure returns (bytes32 salt) {
        salt = keccak256(abi.encodePacked(creator, proposalCount));
    }

}
