// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

error NotAdmin(address sender, address admin);
error LockupPeriodNotOver(uint256 lockupPeriod);
error QuorumPeriodOver(uint256 quorumPeriod);
error QuorumPeriodNotOver(uint256 quorumPeriod);
error QuorumAchieved(uint256 raisedCapital, uint256 quorum); 
error QuorumNotAchieved(uint256 raisedCapital, uint256 quorum);