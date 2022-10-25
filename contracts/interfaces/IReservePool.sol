// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IReservePool {

    /**
     * @param amount the amount in USDC to be sent to the capital pool
     */
    function coverBadDebt(uint256 amount) external;

}