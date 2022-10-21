// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import { ICapitalPool } from "./interfaces/ICapitalPool.sol";
import { 
    LockupPeriodNotOver,
    QuorumPeriodOver,
    QuorumPeriodNotOver,
    QuorumAchieved,
    QuorumNotAchieved
} from "./interfaces/Errors.sol";

contract CapitalPool is ICapitalPool {

    uint256 currentCreditLineID = 1;

    mapping(uint256 => CreditLine) creditLines;

    struct CreditLine {
        address borrower;
        uint256 quorum;
        uint256 quorumPeriod;
        uint256 lockupPeriod;
        uint256 raisedCapital;
    }

    modifier afterLockupPeriod(uint256 creditLineID) {
        if (block.timestamp < creditLines[creditLineID].lockupPeriod) {
            // lockup period not over yet
            revert LockupPeriodNotOver(creditLines[creditLineID].lockupPeriod);
        }
        _;
    }

    modifier beforeQuorumPeriod(uint256 creditLineID) {
        if (block.timestamp > creditLines[creditLineID].quorumPeriod) {
            // quorum period has ended
            revert QuorumPeriodOver(creditLines[creditLineID].quorumPeriod);
        }
        _;
    }

    modifier afterQuorumPeriod(uint256 creditLineID) {
        if (block.timestamp < creditLines[creditLineID].quorumPeriod) {
            // quorum period has not ended
            revert QuorumPeriodNotOver(creditLines[creditLineID].quorumPeriod);
        }
        _;
    }

    modifier belowQuorum(uint256 creditLineID) {
        CreditLine memory pool = creditLines[creditLineID];
        if (pool.raisedCapital > pool.quorum) {
            // quorum achieved
            revert QuorumAchieved(pool.raisedCapital, pool.quorum);
        }
        _;
    }

    modifier aboveQuorum(uint256 creditLineID) {
        CreditLine memory pool = creditLines[creditLineID];
        if (pool.raisedCapital < pool.quorum) {
            // quorum not achieved
            revert QuorumNotAchieved(pool.raisedCapital, pool.quorum);
        }
        _;
    }

    function openCreditLine(
        address borrower, 
        uint256 quorum, 
        uint256 quorumPeriod, 
        uint256 lockupPeriod
    ) external {
        creditLines[currentCreditLineID] = CreditLine(borrower, quorum, quorumPeriod, lockupPeriod, 0);
        currentCreditLineID ++;
    }

    function lendCapital(uint256 creditLineID, uint256 amount) external beforeQuorumPeriod(creditLineID) {

    }

    function removeCapital(uint256 creditLineID) external afterQuorumPeriod(creditLineID) belowQuorum(creditLineID) {

    }

    function withdrawCapital(uint256 creditLineID) external afterLockupPeriod(creditLineID) {

    }

    function triggerLoan(uint256 creditLineID) external aboveQuorum(creditLineID) {

    }
}