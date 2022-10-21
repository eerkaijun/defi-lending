// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import { ICapitalPool } from "./interfaces/ICapitalPool.sol";
import { LockupPeriodNotOver } from "./interfaces/Errors.sol";

contract CapitalPool is ICapitalPool {

    uint256 currentCreditLineID = 1;

    mapping(uint256 => CreditLine) creditLines;

    struct CreditLine {
        address borrower;
        uint256 quorum;
        uint256 quorumPeriod;
        uint256 lockupPeriod;
    }

    modifier afterLockup(uint256 creditLineID) {
        if (block.timestamp < creditLines[creditLineID].lockupPeriod) {
            // lockup period not over yet
            revert LockupPeriodNotOver(creditLines[creditLineID].lockupPeriod);
        }
        _;
    }

    function openCreditLine(
        address borrower, 
        uint256 quorum, 
        uint256 quorumPeriod, 
        uint256 lockupPeriod
    ) external {
        creditLines[currentCreditLineID] = CreditLine(borrower, quorum, quorumPeriod, lockupPeriod);
        currentCreditLineID ++;
    }

    function lendCapital(uint256 creditLineID, uint256 amount) external {

    }

    function withdrawCapital(uint256 creditLineID) external afterLockup(creditLineID) {

    }

}