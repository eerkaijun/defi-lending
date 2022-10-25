// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import { NotAdmin } from "./interfaces/Errors.sol";

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

    constructor() {
        admin = msg.sender;
    }

    function lend() external payable {
        deposits[msg.sender] += msg.value;
    }

    function withdraw() external {
        payable(msg.sender).transfer(deposits[msg.sender]);
    }

    function allowWithdraw() external onlyAdmin {
        allowWithdrawal = true;
    }

}
