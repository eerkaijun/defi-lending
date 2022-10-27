// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import { NotAdmin, WithdrawalClosed } from "./interfaces/Errors.sol";

contract Escrow {

    address admin;
    bool allowWithdrawal = false;
    mapping(address => uint256) public deposits;

    modifier onlyAdmin() {
        if (msg.sender != admin) {
            revert NotAdmin(msg.sender, admin);
        }
        _;
    }

    modifier withdrawalOpen() {
        if (!allowWithdrawal) {
            // need to wait for admin to open withdrawal period
            revert WithdrawalClosed();
        }
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    function stake() external payable {
        deposits[msg.sender] += msg.value;
    }

    function withdraw() external withdrawalOpen {
        uint256 withdrawAmount = deposits[msg.sender];
        deposits[msg.sender] = 0;
        payable(msg.sender).transfer(withdrawAmount);
    }

    function allowWithdraw() external onlyAdmin {
        allowWithdrawal = true;
    }

}
