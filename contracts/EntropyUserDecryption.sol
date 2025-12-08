// SPDX-License-Identifier: BSD-3-Clause-Clear
pragma solidity ^0.8.27;

import {FHE, euint64, externalEuint64} from "@fhevm/solidity/lib/FHE.sol";
import {ZamaEthereumConfig} from "@fhevm/solidity/config/ZamaConfig.sol";
import "./IEntropyOracle.sol";

/**
 * @title EntropyUserDecryption
 * @notice User decrypt single value using EntropyOracle and FHE.allow
 * @dev Example demonstrating EntropyOracle integration: using entropy for user-specific decryption
 * 
 * This example shows:
 * - How to integrate with EntropyOracle
 * - Using entropy to enhance user decryption patterns
 * - Combining entropy with user-specific access control
 * - Entropy-based decryption key generation
 */
contract EntropyUserDecryption is ZamaEthereumConfig {
    // Entropy Oracle interface
    IEntropyOracle public entropyOracle;
    
    // Encrypted value
    euint64 private encryptedValue;
    
    // User who can decrypt
    address private allowedUser;
    
    bool private initialized;
    
    // Track entropy requests
    mapping(uint256 => bool) public entropyRequests;
    
    event ValueStored(address indexed user);
    event UserAllowed(address indexed user);
    event EntropyRequested(uint256 indexed requestId, address indexed caller);
    event ValueStoredWithEntropy(uint256 indexed requestId, address indexed user);
    
    /**
     * @notice Constructor - sets EntropyOracle address
     * @param _entropyOracle Address of EntropyOracle contract
     */
    constructor(address _entropyOracle) {
        require(_entropyOracle != address(0), "Invalid oracle address");
        entropyOracle = IEntropyOracle(_entropyOracle);
    }
    
    /**
     * @notice Store encrypted value and allow specific user to decrypt
     * @param encryptedInput Encrypted value from user
     * @param inputProof Input proof for encrypted value
     * @param user Address of user who can decrypt
     */
    function storeAndAllow(
        externalEuint64 encryptedInput,
        bytes calldata inputProof,
        address user
    ) external {
        require(!initialized, "Already initialized");
        require(user != address(0), "Invalid user address");
        
        // Convert external to internal
        euint64 internalValue = FHE.fromExternal(encryptedInput, inputProof);
        
        // Allow contract to use
        FHE.allowThis(internalValue);
        
        // Allow specific user to decrypt
        FHE.allow(internalValue, user);
        
        encryptedValue = internalValue;
        allowedUser = user;
        initialized = true;
        
        emit ValueStored(msg.sender);
        emit UserAllowed(user);
    }
    
    /**
     * @notice Request entropy for enhanced decryption
     * @param tag Unique tag for this request
     * @return requestId Request ID from EntropyOracle
     * @dev Requires 0.00001 ETH fee
     */
    function requestEntropy(bytes32 tag) external payable returns (uint256 requestId) {
        require(msg.value >= entropyOracle.getFee(), "Insufficient fee");
        
        requestId = entropyOracle.requestEntropy{value: msg.value}(tag);
        entropyRequests[requestId] = true;
        
        emit EntropyRequested(requestId, msg.sender);
        return requestId;
    }
    
    /**
     * @notice Store value with entropy enhancement and allow user to decrypt
     * @param encryptedInput Encrypted value from user
     * @param inputProof Input proof for encrypted value
     * @param user Address of user who can decrypt
     * @param requestId Request ID from requestEntropy()
     */
    function storeAndAllowWithEntropy(
        externalEuint64 encryptedInput,
        bytes calldata inputProof,
        address user,
        uint256 requestId
    ) external {
        require(!initialized, "Already initialized");
        require(user != address(0), "Invalid user address");
        require(entropyRequests[requestId], "Invalid request ID");
        require(entropyOracle.isRequestFulfilled(requestId), "Entropy not ready");
        
        // Convert external to internal
        euint64 internalValue = FHE.fromExternal(encryptedInput, inputProof);
        FHE.allowThis(internalValue);
        
        // Get entropy
        euint64 entropy = entropyOracle.getEncryptedEntropy(requestId);
        FHE.allowThis(entropy);
        
        // Combine value with entropy
        euint64 enhancedValue = FHE.xor(internalValue, entropy);
        FHE.allowThis(enhancedValue);
        
        // Allow user to decrypt enhanced value
        FHE.allow(enhancedValue, user);
        
        encryptedValue = enhancedValue;
        allowedUser = user;
        initialized = true;
        
        entropyRequests[requestId] = false;
        emit ValueStoredWithEntropy(requestId, msg.sender);
        emit UserAllowed(user);
    }
    
    /**
     * @notice Get encrypted value (only allowed user can decrypt off-chain)
     * @return Encrypted value (euint64)
     * @dev User must use FHEVM SDK to decrypt this value
     */
    function getEncryptedValue() external view returns (euint64) {
        require(initialized, "Not initialized");
        return encryptedValue;
    }
    
    /**
     * @notice Get allowed user address
     * @return Address of user who can decrypt
     */
    function getAllowedUser() external view returns (address) {
        return allowedUser;
    }
    
    /**
     * @notice Check if initialized
     */
    function isInitialized() external view returns (bool) {
        return initialized;
    }
    
    /**
     * @notice Get EntropyOracle address
     */
    function getEntropyOracle() external view returns (address) {
        return address(entropyOracle);
    }
}
