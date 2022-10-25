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
    address public underlierAddress;

    mapping(uint256 => CreditLine) public creditLines;
    mapping(address => uint256) depositedAmount; // deposited amount by lenders in native token

    struct CreditLine {
        address borrower;
        uint256 quorum; // quorum for native tokens in order for deal to go through
        uint256 quorumPeriod; // unix timestamp of when quorum has to be achieved
        uint256 lockupPeriod; // unix timestamp of when loan period ends
        uint256 repayAmount; // amount to be repaid by borrower to capital pool (inclusive of interest)
        uint256 raisedCapital; // amount of native tokens raised
        uint256 borrowedAmount; // borrowed amount in USDC
        uint256 repaidAmountToAave; // repaid amount to Aave
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
        uint256 quorum, 
        uint256 quorumPeriod, 
        uint256 lockupPeriod,
        uint256 repayAmount
    ) external {
        creditLines[currentCreditLineID] = CreditLine(msg.sender, quorum, quorumPeriod, lockupPeriod, repayAmount, 0, 0, 0);
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
        // TODO: use of ERC 4626 to represent vault
        CreditLine memory pool = creditLines[creditLineID]; 

        // calculate profit
        uint256 profit = 0;
        if (pool.repayAmount > pool.repaidAmountToAave) {
            profit = pool.repayAmount = pool.repaidAmountToAave;
        }
        
        // profit sharing among lender
        uint256 userProfit = depositedAmount[msg.sender] * profit / pool.raisedCapital;

        // transfer native tokens + interest accrued back to user
        IERC20Metadata(underlierAddress).transfer(msg.sender, depositedAmount[msg.sender]);
        IERC20Metadata(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48).transfer(msg.sender, userProfit);
    }

    function triggerLoan(uint256 creditLineID, uint256 borrowAmount) external aboveQuorum(creditLineID) {
        CreditLine storage pool = creditLines[creditLineID]; 

        // get lending pool address (Ethereum mainnet)
        address lendingPoolAddress = LendingPoolAddressesProvider(0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5).getLendingPool();

        // approve the lending pool to transfer the underlying asset
        IERC20Metadata(underlierAddress).approve(lendingPoolAddress, pool.raisedCapital);
        
        // capital pool will receive the associated aToken
        ILendingPool(lendingPoolAddress).deposit(underlierAddress, pool.raisedCapital, address(this), 0);

        // borrow USDC from lending pool - use stable interest rate
        pool.borrowedAmount += borrowAmount;
        ILendingPool(lendingPoolAddress).borrow(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48, borrowAmount, 1, 0, address(this));

        // send the borrowed USDC to the borrower
        IERC20Metadata(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48).transfer(pool.borrower, borrowAmount);
    }

    /// @dev borrower first have to approve capital pool on their USDC
    function repayLoan(uint256 creditLineID, address borrower, uint256 amount) external {
        CreditLine storage pool = creditLines[creditLineID]; 

        // get lending pool address (Ethereum mainnet)
        address lendingPoolAddress = LendingPoolAddressesProvider(0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5).getLendingPool();

        // reduce borrowed amount
        IERC20Metadata(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48).transferFrom(borrower, address(this), amount);
        pool.repaidAmountToAave += amount;
        // allow lending pool to burn USDC debt token
        // TODO: can we just transfer directly from borrower
        IERC20Metadata(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48).approve(lendingPoolAddress, amount);
        // TODO: if borrow amount has been repaid, the USDC will just lie in the capital pool
        ILendingPool(lendingPoolAddress).repay(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48, amount, 1, address(this));
    } 
}