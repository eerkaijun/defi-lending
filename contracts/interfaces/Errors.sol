// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Lending protocol
error NotAdmin(address sender, address admin);
error WithdrawalClosed();
error NotCapitalPool();
error LockupPeriodNotOver(uint256 lockupPeriod);
error QuorumPeriodOver(uint256 quorumPeriod);
error QuorumPeriodNotOver(uint256 quorumPeriod);
error QuorumAchieved(uint256 raisedCapital, uint256 quorum); 
error QuorumNotAchieved(uint256 raisedCapital, uint256 quorum);
error InvalidReserveFactor();
error ReservePoolInsolvent(uint256 balance);

// Trust graph
error AlreadyJoinedGraph(address user);
error NotInGraph(address user);
error InvalidReferrer();