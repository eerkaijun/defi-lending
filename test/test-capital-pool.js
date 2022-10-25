const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Capital Pool", () => {

    let capitalPool;
    let stablecoin;
    let underlier;

    let borrower, investor;

    before(async() => {
        [borrower, investor] = await ethers.getSigners();

        const CapitalPool = await ethers.getContractFactory("CapitalPool");
        capitalPool = await CapitalPool.deploy("0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9");
        stablecoin = await ethers.getContractAt("IERC20Metadata", "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48");
        underlier = await ethers.getContractAt("IERC20Metadata", "0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9");
    })

    it("Borrower should be able to open a credit line", async () => {
        const underlierDecimals = await underlier.decimals();
        const stablecoinDecimals = await stablecoin.decimals();
        const quorum = ethers.utils.parseUnits("100", underlierDecimals);
        const quorumPeriod = await getFutureTimestamp(5); // 5 days later
        const lockupPeriod = await getFutureTimestamp(10); // 10 days later
        const repayAmount = ethers.utils.parseUnits("100", stablecoinDecimals);
        await capitalPool.openCreditLine(quorum, quorumPeriod, lockupPeriod, repayAmount);

        const creditLine = await capitalPool.creditLines(1);
        expect(creditLine.borrower).equal(borrower.address);
    });

    it("Investor should be able to lend capital", async() => {
        const underlierDecimals = await underlier.decimals();
        const lendAmount = ethers.utils.parseUnits("100", underlierDecimals);

        // mint tokens to investor
        await ethers.provider.send('hardhat_impersonateAccount', ['0x3744da57184575064838bbc87a0fc791f5e39ea2']);
        const aaveWhale = await ethers.provider.getSigner('0x3744da57184575064838bbc87a0fc791f5e39ea2');
        await underlier.connect(aaveWhale).transfer(
            investor.address,
            lendAmount
        );
        await underlier.connect(investor).approve(capitalPool.address, lendAmount);
        await capitalPool.connect(investor).lendCapital(1, lendAmount);

        const creditLine = await capitalPool.creditLines(1);
        expect(creditLine.raisedCapital).equal(lendAmount);
    });

    it("Admin should be able to trigger and send capital to the borrower", async () => {
        const stablecoinDecimals = await stablecoin.decimals();
        const borrowAmount = ethers.utils.parseUnits("50", stablecoinDecimals);
        await capitalPool.triggerLoan(1, borrowAmount);

        // debt token of USDC
        const usdcDebtToken = await ethers.getContractAt("IERC20Metadata", "0xE4922afAB0BbaDd8ab2a88E0C79d884Ad337fcA6");
        expect(await stablecoin.balanceOf(borrower.address)).equal(borrowAmount);
        // capital pool should accumulate debt token of USDC the same amount as borrow amount
        expect(await usdcDebtToken.balanceOf(capitalPool.address)).equal(borrowAmount);
    });

    it("Borrower should be able to repay loan", async () => {
        const stablecoinDecimals = await stablecoin.decimals();
        const borrowAmount = ethers.utils.parseUnits("50", stablecoinDecimals);
        await stablecoin.connect(borrower).approve(capitalPool.address, borrowAmount);

        const usdcDebtToken = await ethers.getContractAt("IERC20Metadata", "0xE4922afAB0BbaDd8ab2a88E0C79d884Ad337fcA6");
        expect(await stablecoin.balanceOf(borrower.address)).equal(borrowAmount);
        expect(await usdcDebtToken.balanceOf(capitalPool.address)).equal(borrowAmount);
        
        await capitalPool.repayLoan(1, borrower.address, borrowAmount);
        expect(await stablecoin.balanceOf(borrower.address)).equal(0);
        expect(await usdcDebtToken.balanceOf(capitalPool.address)).equal(0);
    });
});

async function getFutureTimestamp(days) {
    const blockNumber = await ethers.provider.getBlockNumber();
    const block = await ethers.provider.getBlock(blockNumber);
    return block.timestamp + 3600 * 24 * days;
}