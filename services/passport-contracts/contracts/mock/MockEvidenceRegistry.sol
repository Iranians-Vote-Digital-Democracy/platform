// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {IEvidenceRegistry} from "@rarimo/evidence-registry/interfaces/IEvidenceRegistry.sol";

/**
 * @notice Mock Evidence Registry for local testing
 */
contract MockEvidenceRegistry is IEvidenceRegistry {
    mapping(bytes32 => bytes32) public statements;
    mapping(bytes32 => uint256) public rootTimestamps;
    bytes32 public currentRoot;

    function addStatement(bytes32 key, bytes32 value) external override {
        statements[key] = value;
        currentRoot = key; // Just use the key as root for simplicity
        rootTimestamps[key] = block.timestamp;
        emit RootUpdated(bytes32(0), key);
    }

    function removeStatement(bytes32 key) external override {
        delete statements[key];
    }

    function updateStatement(bytes32 key, bytes32 newValue) external override {
        statements[key] = newValue;
    }

    function getRootTimestamp(bytes32 root) external view override returns (uint256) {
        if (root == currentRoot) {
            return block.timestamp;
        }
        return rootTimestamps[root];
    }
}
