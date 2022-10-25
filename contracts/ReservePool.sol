// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { IReservePool } from "./interfaces/IReservePool.sol";
import { NotCapitalPool } from "./interfaces/Errors.sol";

contract ReservePool is IReservePool {

    mapping(address => bool) validCapitalPool;

    modifier onlyCapitalPool() {
        if (!validCapitalPool[msg.sender]) {
            revert NotCapitalPool();
        }
        _;
    }

    function coverBadDebt(uint256 amount) external onlyCapitalPool {
        // send USDC to capital pool
        IERC20Metadata(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48).transfer(msg.sender, amount);
    }

    

}