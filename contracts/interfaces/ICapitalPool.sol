// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface ICapitalPool {

    /**
     * @param borrower address of the borrower 
     * @param quorum minimum amount of funds for credit line to go forward
     * @param quorumPeriod unix timestamp to reach the required quorum
     * @param lockupPeriod if quorum passes, unix timestamp for which the funds are locked until
     */
    function openCreditLine(address borrower, uint256 quorum, uint256 quorumPeriod, uint256 lockupPeriod) external;

    /**
     * @param creditLineID id of the opened credit line
     * @param amount amount of capital to lend to
     */
    function lendCapital(uint256 creditLineID, uint256 amount) external;

    /**
     * @notice during withdraw, lender withdraws its initial capital plus accrued interest rates
     * @param creditLineID id of the opened credit line
     */
    function withdrawCapital(uint256 creditLineID) external;
}