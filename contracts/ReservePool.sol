// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IReservePool } from "./interfaces/IReservePool.sol";
import { ICapitalPool } from "./interfaces/ICapitalPool.sol";
import { NotCapitalPool, InvalidReserveFactor, ReservePoolInsolvent } from "./interfaces/Errors.sol";

contract ReservePool is IReservePool, Ownable {

    uint256 public reserveFactor; // in basis points term, i.e reserve factor 1 is equal to 0.01%
    mapping(address => bool) validCapitalPool;

    modifier onlyCapitalPool() {
        if (!validCapitalPool[msg.sender]) {
            revert NotCapitalPool();
        }
        _;
    }

    function addCapitalPool(address capitalPoolAddress) external onlyOwner {
        validCapitalPool[capitalPoolAddress] = true;
    }

    function removeCapitalPool(address capitalPoolAddress) external onlyOwner {
        validCapitalPool[capitalPoolAddress] = false;
    }

    function setReserveFactor(uint256 newReserveFactor) external onlyOwner {
        if (newReserveFactor > 10000) {
            // reserve factor cannot be larger than 100%
            revert InvalidReserveFactor();
        }
        reserveFactor = newReserveFactor;
    }

    function coverBadDebt(uint256 creditLineID, address borrower, uint256 amount) external onlyCapitalPool {
        uint256 balance = IERC20Metadata(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48).balanceOf(address(this));
        if (balance < amount) {
            // not enough stablecoin in the reserve pool to cover capital pool bad debt
            revert ReservePoolInsolvent(balance);
        }
        // repay loan on behalf of the borrower
        IERC20Metadata(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48).approve(msg.sender, amount);
        ICapitalPool(msg.sender).repayLoan(creditLineID, borrower, amount);
    }
}