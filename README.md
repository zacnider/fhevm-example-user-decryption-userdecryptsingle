# EntropyUserDecryption

Learn how to user decrypt single value using encrypted randomness and fhe.allow

## 🎓 What You'll Learn

This example teaches you how to use FHEVM to build privacy-preserving smart contracts. You'll learn step-by-step how to implement encrypted operations, manage permissions, and work with encrypted data.

## 🚀 Quick Start

1. **Clone this repository:**
   ```bash
   git clone https://github.com/zacnider/fhevm-example-user-decryption-userdecryptsingle.git
   cd fhevm-example-user-decryption-userdecryptsingle
   ```

2. **Install dependencies:**
   ```bash
   npm install --legacy-peer-deps
   ```

3. **Setup environment:**
   ```bash
   npm run setup
   ```
   Then edit `.env` file with your credentials:
   - `SEPOLIA_RPC_URL` - Your Sepolia RPC endpoint
   - `PRIVATE_KEY` - Your wallet private key (for deployment)
   - `ETHERSCAN_API_KEY` - Your Etherscan API key (for verification)

4. **Compile contracts:**
   ```bash
   npm run compile
   ```

5. **Run tests:**
   ```bash
   npm test
   ```

6. **Deploy to Sepolia:**
   ```bash
   npm run deploy:sepolia
   ```

7. **Verify contract (after deployment):**
   ```bash
   npm run verify <CONTRACT_ADDRESS>
   ```

**Alternative:** Use the [Examples page](https://entrofhe.vercel.app/examples) for browser-based deployment and verification.

---

## 📚 Overview

@title EntropyUserDecryption
@notice User decrypt single value using encrypted randomness and FHE.allow
@dev This example teaches you how to integrate encrypted randomness into your FHEVM contracts: using entropy for user-specific decryption
In this example, you will learn:
- How to integrate encrypted randomness
- How to use encrypted randomness to enhance user decryption patterns
- Combining entropy with user-specific access control
- Entropy-based decryption key generation

@notice Constructor - sets encrypted randomness address
@param _encrypted randomness Address of encrypted randomness contract

@notice Store encrypted value and allow specific user to decrypt
@param encryptedInput Encrypted value from user
@param inputProof Input proof for encrypted value
@param user Address of user who can decrypt

@notice Request entropy for enhanced decryption
@param tag Unique tag for this request
@return requestId Request ID from encrypted randomness
@dev Requires 0.00001 ETH fee

@notice Store value with entropy enhancement and allow user to decrypt
@param encryptedInput Encrypted value from user
@param inputProof Input proof for encrypted value
@param user Address of user who can decrypt
@param requestId Request ID from requestEntropy()

@notice Get encrypted value (only allowed user can decrypt off-chain)
@return Encrypted value (euint64)
@dev User must use FHEVM SDK to decrypt this value

@notice Get allowed user address
@return Address of user who can decrypt

@notice Check if initialized

@notice Get encrypted randomness address



## 🔐 Learn Zama FHEVM Through This Example

This example teaches you how to use the following **Zama FHEVM** features:

### What You'll Learn About

- **ZamaEthereumConfig**: Inherits from Zama's network configuration
  ```solidity
  contract MyContract is ZamaEthereumConfig {
      // Inherits network-specific FHEVM configuration
  }
  ```

- **FHE Operations**: Uses Zama's FHE library for encrypted operations
  - `FHE.add()` - Zama FHEVM operation
  - `FHE.sub()` - Zama FHEVM operation
  - `FHE.mul()` - Zama FHEVM operation
  - `FHE.eq()` - Zama FHEVM operation
  - `FHE.xor()` - Zama FHEVM operation

- **Encrypted Types**: Uses Zama's encrypted integer types
  - `euint64` - 64-bit encrypted unsigned integer
  - `externalEuint64` - External encrypted value from user

- **Access Control**: Uses Zama's permission system
  - `FHE.allowThis()` - Allow contract to use encrypted values
  - `FHE.allow()` - Allow specific user to decrypt
  - `FHE.allowTransient()` - Temporary permission for single operation
  - `FHE.fromExternal()` - Convert external encrypted values to internal

### Zama FHEVM Imports

```solidity
// Zama FHEVM Core Library - FHE operations and encrypted types
import {FHE, euint64, externalEuint64} from "@fhevm/solidity/lib/FHE.sol";

// Zama Network Configuration - Provides network-specific settings
import {ZamaEthereumConfig} from "@fhevm/solidity/config/ZamaConfig.sol";
```

### Zama FHEVM Code Example

```solidity
// Using Zama FHEVM's encrypted integer type
euint64 private encryptedValue;

// Converting external encrypted value to internal (Zama FHEVM)
euint64 internalValue = FHE.fromExternal(encryptedValue, inputProof);
FHE.allowThis(internalValue); // Zama FHEVM permission system

// Performing encrypted operations using Zama FHEVM
euint64 result = FHE.add(encryptedValue, FHE.asEuint64(1));
FHE.allowThis(result);
```

### FHEVM Concepts You'll Learn

1. **Encrypted Arithmetic**: Learn how to use Zama FHEVM for encrypted arithmetic
2. **Encrypted Comparison**: Learn how to use Zama FHEVM for encrypted comparison
3. **External Encryption**: Learn how to use Zama FHEVM for external encryption
4. **Permission Management**: Learn how to use Zama FHEVM for permission management
5. **Entropy Integration**: Learn how to use Zama FHEVM for entropy integration

### Learn More About Zama FHEVM

- 📚 [Zama FHEVM Documentation](https://docs.zama.org/protocol)
- 🎓 [Zama Developer Hub](https://www.zama.org/developer-hub)
- 💻 [Zama FHEVM GitHub](https://github.com/zama-ai/fhevm)



## 🔍 Contract Code

```solidity
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

```

## 🧪 Tests

See [test file](./test/EntropyUserDecryption.test.ts) for comprehensive test coverage.

```bash
npm test
```


## 📚 Category

**user**



## 🔗 Related Examples

- [All user examples](https://github.com/zacnider/entrofhe/tree/main/examples)

## 📝 License

BSD-3-Clause-Clear
