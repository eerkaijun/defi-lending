// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { ICapitalPool } from "./interfaces/ICapitalPool.sol";
import { 
    LockupPeriodNotOver,
    QuorumPeriodOver,
    QuorumPeriodNotOver,
    QuorumAchieved,
    QuorumNotAchieved
} from "./interfaces/Errors.sol";

// Aave integration import
import { ILendingPool } from "./aave/ILendingPool.sol";
import { LendingPoolAddressesProvider } from "./aave/LendingPoolAddressesProvider.sol";

contract CapitalPool is ICapitalPool {

    uint256 currentCreditLineID = 1;
    address underlierAddress;

    mapping(uint256 => CreditLine) creditLines;
    mapping(address => uint256) depositedAmount;

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

    constructor(address _underlierAddress) {
        underlierAddress = _underlierAddress;
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

    /// @dev user first have to approve the ERC20 token to be spent
    function lendCapital(uint256 creditLineID, uint256 amount) external beforeQuorumPeriod(creditLineID) {
        CreditLine storage pool = creditLines[creditLineID];
        pool.raisedCapital += amount;
        depositedAmount[msg.sender] += amount;
        IERC20Metadata(underlierAddress).transferFrom(msg.sender, address(this), amount);
    }

    function removeCapital(uint256 creditLineID) external afterQuorumPeriod(creditLineID) belowQuorum(creditLineID) {
        uint256 amount = depositedAmount[msg.sender];
        depositedAmount[msg.sender] = 0;
        IERC20Metadata(underlierAddress).transfer(msg.sender, amount);
    }

    function withdrawCapital(uint256 creditLineID) external afterLockupPeriod(creditLineID) {
        // TODO: Use of interest bearing token such as cToken to represents share
        // TODO: alternatively use of ERC 4626 to represent vault
    }

    function triggerLoan(uint256 creditLineID) external aboveQuorum(creditLineID) {
        // TODO: integration with lending protocol such as Aave and Compound
        CreditLine memory pool = creditLines[creditLineID]; 

        // get lending pool address (Ethereum mainnet)
        address lendingPoolAddress = LendingPoolAddressesProvider(0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5).getLendingPool();

        // approve the lending pool to transfer the underlying asset
        IERC20Metadata(underlierAddress).approve(lendingPoolAddress, pool.raisedCapital);
        
        // capital pool will receive the associated aToken
        ILendingPool(lendingPoolAddress).deposit(underlierAddress, pool.raisedCapital, address(this), 0);
    }
}