// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract MerkleProofDebug {
    using MerkleProof for bytes32[];

    function computeRoot(
        bytes calldata publicKey,
        bytes32[] calldata proof
    ) external pure returns (bytes32 leaf, bytes32 root) {
        leaf = keccak256(publicKey);
        root = proof.processProof(leaf);
    }
    
    function computeRootFromLeaf(
        bytes32 leaf,
        bytes32[] calldata proof
    ) external pure returns (bytes32 root) {
        root = proof.processProof(leaf);
    }
}
