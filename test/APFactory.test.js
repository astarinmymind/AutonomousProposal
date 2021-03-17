// SPDX-License-Identifier: MIT
const chai = require("chai");
const { ethers } = require("hardhat");
const { solidity } = require("ethereum-waffle");

chai.use(solidity);

const DELEGATOR = "0x26a78D5b6d7a7acEEDD1e6eE3229b372A624d8b7";
const AAVE_SHORT_EXECUTOR = "0xee56e2b3d491590b5b31738cc34d5232f378a8d5";
const AAVE_GOVERNANCE_ADDRESS = "0xEC568fffba86c094cf06b22134B23074DFE2252c";
const AAVE_ECOSYSTEM_CONTROLLER = "0x1E506cbb6721B83B1549fa1558332381Ffa61A93";
const AAVE_TOKEN_ADDRESS = "0x7fc66500c84a76ad7e9c93437bfc5ac33e2ddae9";

/**
 * @notice The following test checks: 
 *         (1) given the same arguments, the predicted and deployed AP address is the same
 *         (2) given enough proposition power, the AP deploys and is created successfully
 */

describe("APTest", function() {

    it("Should deploy an AP once delegated enough proposition power", async function() {

        /**
         * @notice Get bytecode of the AP.
         */
        const getProposal = await ethers.getContractFactory("AP");
        const bytecode = getProposal.bytecode;

        /**
         * @notice Deploy the AP factory.
         */
        const getFactory = await ethers.getContractFactory("APFactory");
        const proposalFactory = await getFactory.deploy(bytecode);
        await proposalFactory.deployed();

        /**
         * @notice Get arguments to create proposal. 
         * In this test proposal, the AAVE Ecosystem Reserve approves the creator of the
         * AP to receive AAVE.
         */
        const creator = (await ethers.getSigners())[0].address;
        const governance = AAVE_GOVERNANCE_ADDRESS;
        const executor = AAVE_SHORT_EXECUTOR;
        const targets = [AAVE_ECOSYSTEM_CONTROLLER];
        const values = [0];
        const signatures = ["approve(address,address,uint256)"];
        const calldatas = [
            ethers.utils.defaultAbiCoder.encode(
                ["address", "address", "uint256"], [AAVE_TOKEN_ADDRESS, creator, ethers.utils.parseEther("100")]
            )
        ];
        const withDelegatecalls = [false];
        const ipfsHash = "0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470";

        /**
         * @notice Impersonate a delegator with a lot of AAVE tokens.
         */
        await hre.network.provider.request({
            method: "hardhat_impersonateAccount",
            params: [DELEGATOR]
        });
        const delegator = ethers.provider.getSigner(DELEGATOR);

        /**
         * @notice Calculate the address of the AP.
         */
        const proposalAddress = await proposalFactory.calculateAddress(
            creator, governance, executor, targets, values, signatures, calldatas, withDelegatecalls, ipfsHash
        );

        /**
         * @notice Delegate proposition power to the address of the AP.
         */
        const aaveABI = [
            "function delegateByType(address delegatee, uint8 delegationType)",
            "function getPowerCurrent(address user, DelegationType delegationType)"
        ];
        const delegateAAVEContract = new ethers.Contract(AAVE_TOKEN_ADDRESS, aaveABI, delegator);
        const delegateAAVE = await delegateAAVEContract.deployed();
        await delegateAAVE.delegateByType(proposalAddress, 1);

        /**
         * @notice Deployed AP should have same address as predicted. 
         */
        await chai.expect(proposalFactory.deployAP(creator, governance, executor, targets, values, signatures, calldatas, withDelegatecalls, ipfsHash))
            .to.emit(proposalFactory, 'APdeployed')
            .withArgs(proposalAddress, creator);
    });
});