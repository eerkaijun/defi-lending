const { ethers } = require("hardhat");
const { expect } = require("chai");

describe("Escrow", () => {

    it("Should be able to deposit", async () => {
        let user;
        [user] = await ethers.getSigners();
        const Escrow = await ethers.getContractFactory("Escrow");
        const escrow = await Escrow.deploy();

        const depositAmount = ethers.utils.parseEther("0.5");
        escrow.connect(user).stake({value: depositAmount});

        expect(await escrow.deposits(user.address)).equal(depositAmount);
    });
});