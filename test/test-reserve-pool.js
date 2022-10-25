const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Reserve Pool", () => {

    let capitalPool, reservePool;
    let stablecoin;
    let underlier;

    let borrower, investor;

    before(async() => {
        [borrower, investor] = await ethers.getSigners();

        const CapitalPool = await ethers.getContractFactory("CapitalPool");
        capitalPool = await CapitalPool.deploy("0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9");
        const ReservePool = await ethers.getContractFactory("ReservePool");
        reservePool = await ReservePool.deploy();
        stablecoin = await ethers.getContractAt("IERC20Metadata", "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48");
        underlier = await ethers.getContractAt("IERC20Metadata", "0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9");
    })

    it("reserve pool should be able to cover a bad debt in the capital pool", async () => {

    })
});