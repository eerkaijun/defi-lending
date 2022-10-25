const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Capital Pool", () => {

    let capitalPool;

    beforeEach(async() => {
        const CapitalPool = await ethers.getContractFactory("CapitalPool");
        capitalPool = await CapitalPool.deploy("0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9");
    })

    it("Borrower should be able to open a credit line", async () => {
        
    });

    it("Investor should be able to lend capital", async() => {

    });

    it("Admin should be able to trigger and send capital to the borrower", async () => {

    });

    it("Borrower should be able to repay loan", async () => {

    });
});