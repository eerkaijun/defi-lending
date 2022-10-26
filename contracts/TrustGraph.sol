// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import { AlreadyJoinedGraph, NotInGraph, InvalidReferrer } from "./interfaces/Errors.sol";

contract TrustGraph is ERC721URIStorage {

    uint256 public currentTokenID = 1;
    mapping(address => bool) public graphNodes;

    constructor() ERC721("Trust Graph", "<->") {
        graphNodes[msg.sender] = true;
    } 

    function joinGraph(bytes memory signature) external {
        if (graphNodes[msg.sender]) {
            revert AlreadyJoinedGraph(msg.sender);
        }

        // user can only join through referral
        // referral link is in the form of signature
        bytes32 hashedMessage = keccak256(abi.encodePacked(
            "\x19Ethereum Signed Message:\n32",
            keccak256(abi.encodePacked(msg.sender))
        ));
        address referrer = getAddressFromSignature(hashedMessage, signature);
        if (!graphNodes[referrer]) {
            revert InvalidReferrer();
        }

        graphNodes[msg.sender] = true;
        _mint(msg.sender, currentTokenID);
        currentTokenID ++;

        emit newEdge(msg.sender, referrer);
    }

    function formEdge(address destination) external {
        if (!graphNodes[msg.sender]) {
            revert NotInGraph(msg.sender);
        }

        emit newEdge(msg.sender, destination);
    }

    function getAddressFromSignature(bytes32 hashedMessage, bytes memory signature) private pure returns(address) {
        bytes32 r;
        bytes32 s;
        uint8 v;

        // Check the signature length
        if (signature.length != 65) return address(0);

        // Divide the signature in r, s and v variables
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        // Appendix F in the Ethereum Yellow paper states that the valid range for s is 0 < s < secp256k1n ÷ 2 + 1
        // Check taken from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/cryptography/ECDSA.sol#L161
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return address(0);
        }

        // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
        if (v < 27) v += 27;

        // If the version is correct return the signer address
        if (v != 27 && v != 28) {
            return address(0);
        } else {
            return ecrecover(hashedMessage, v, r, s);
        }
    }

    event newEdge(address source, address destination);
}