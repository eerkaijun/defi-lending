// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface ICapitalPool {

    /**
     * @param borrower address of the borrower 
     * @param quorum minimum amount of funds for credit line to go forward
     * @param quorumPeriod unix timestamp to reach the required quorum
     * @param lockupPeriod if quorum passes, unix timestamp for which the funds are locked until
     * @param repayAmount amount to be repaid by borrower to capital pool (inclusive of interest)
     */
    function openCreditLine(address borrower, uint256 quorum, uint256 quorumPeriod, uint256 lockupPeriod, uint256 repayAmount) external;

    /**
     * @param creditLineID id of the opened credit line
     * @param amount amount of capital to lend to
     */
    function lendCapital(uint256 creditLineID, uint256 amount) external;

    /**
     * @notice if quorum is not achieved, lender is free to remove its capital
     * @param creditLineID id of the opened credit line
     */
    function removeCapital(uint256 creditLineID) external;

    /**
     * @notice during withdraw, lender withdraws its initial capital plus accrued interest rates
     * @param creditLineID id of the opened credit line
     */
    function withdrawCapital(uint256 creditLineID) external;

    /**
     * @notice when quorum reached, admin can trigger loans to borrower
     * @param creditLineID id of the opened credit line
     * @param amount amount to be borrowed in Aave (in USDC)
     */
    function triggerLoan(uint256 creditLineID, uint256 amount) external;

    /**
     * @notice function called by the borrower to repay its loan
     * @param creditLineID id of the opened credit line
     * @param borrower the address of the borrower
     * @param amount amount to be repaid (in USDC)
     */
    function repayLoan(uint256 creditLineID, address borrower, uint256 amount) external;
}