// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IReservePool {

    /**
     * @param capitalPoolAddress address to be added as valid capital pool
     */
    function addCapitalPool(address capitalPoolAddress) external;

    /**
     * @param capitalPoolAddress address to be removed as valid capital pool
     */
    function removeCapitalPool(address capitalPoolAddress) external;

    /**
     * @notice can only be called by a capital pool
     * @param creditLineID ID of the credit line in the insurance pool
     * @param borrower address of the defaulted borrower
     * @param amount the amount in USDC to be sent to the capital pool
     */
    function coverBadDebt(uint256 creditLineID, address borrower, uint256 amount) external;

}