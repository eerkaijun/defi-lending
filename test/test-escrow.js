const { ethers } = require("hardhat");
const { expect } = require("chai");
const { EDIT_DISTANCE_THRESHOLD } = require("hardhat/internal/constants");

describe("Escrow", () => {

    let user;
    let escrow; // escrow smart contract
    let depositAmount, withdrawAmount;

    before(async() => {
        [user] = await ethers.getSigners();
        const Escrow = await ethers.getContractFactory("Escrow");
        escrow = await Escrow.deploy();
    })

    it("Should be able to stake", async () => {
        depositAmount = ethers.utils.parseEther("0.5");
        escrow.connect(user).stake({value: depositAmount});

        expect(await escrow.deposits(user.address)).equal(depositAmount);
    });

    it("Should be able to unstake", async () => {
        await escrow.allowWithdraw();
        withdrawAmount = ethers.utils.parseEther("0.2");
        await escrow.connect(user).withdraw();

        expect(await escrow.deposits(user.address)).equal(0);
    });
});