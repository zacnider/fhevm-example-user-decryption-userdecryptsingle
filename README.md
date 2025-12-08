# EntropyUserDecryption

User decrypt single value using EntropyOracle and FHE.allow

## 🚀 Standard workflow
- Install (first run): `npm install --legacy-peer-deps`
- Compile: `npx hardhat compile`
- Test (local FHE + local oracle/chaos engine auto-deployed): `npx hardhat test`
- Deploy (frontend Deploy button): constructor arg is fixed to EntropyOracle `0x75b923d7940E1BD6689EbFdbBDCD74C1f6695361`
- Verify: `npx hardhat verify --network sepolia <contractAddress> 0x75b923d7940E1BD6689EbFdbBDCD74C1f6695361`

## 📋 Overview

This example demonstrates **user-decryption** concepts in FHEVM with **EntropyOracle integration**:
- Integrating with EntropyOracle
- Using entropy to enhance user-specific decryption patterns
- Combining entropy with user-specific access control
- Entropy-based decryption key generation

## 🎯 What This Example Teaches

This tutorial will teach you:

1. **How to use `FHE.allow()`** for user-specific decryption
2. **How to grant decryption permissions** to specific users
3. **How to enhance user decryption** with entropy from EntropyOracle
4. **The difference between `FHE.allow()` and `FHE.allowThis()`**
5. **User-specific access control patterns** in FHEVM
6. **How users decrypt values off-chain** using FHEVM SDK

## 💡 Why This Matters

Selective decryption maintains privacy while enabling authorized access. With EntropyOracle, you can:
- **Control who can decrypt** encrypted values
- **Add randomness** to decryption patterns
- **Implement fine-grained access control** with FHE permissions
- **Learn the foundation** for more complex access control patterns

## 🔍 How It Works

### Contract Structure

The contract has three main components:

1. **Store and Allow**: Store encrypted value and grant user permission
2. **Entropy Request**: Request randomness from EntropyOracle
3. **Store with Entropy and Allow**: Combine value with entropy, then grant permission

### Step-by-Step Code Explanation

#### 1. Constructor

```solidity
constructor(address _entropyOracle) {
    require(_entropyOracle != address(0), "Invalid oracle address");
    entropyOracle = IEntropyOracle(_entropyOracle);
}
```

**What it does:**
- Takes EntropyOracle address as parameter
- Validates the address is not zero
- Stores the oracle interface

**Why it matters:**
- Must use the correct oracle address: `0x75b923d7940E1BD6689EbFdbBDCD74C1f6695361`

#### 2. Store and Allow

```solidity
function storeAndAllow(
    externalEuint64 encryptedInput,
    bytes calldata inputProof,
    address user
) external {
    require(!initialized, "Already initialized");
    require(user != address(0), "Invalid user address");
    
    euint64 internalValue = FHE.fromExternal(encryptedInput, inputProof);
    FHE.allowThis(internalValue);  // Contract can use
    FHE.allow(internalValue, user); // User can decrypt
    
    encryptedValue = internalValue;
    allowedUser = user;
    initialized = true;
}
```

**What it does:**
- Accepts encrypted value from external source
- Validates encrypted value using input proof
- Converts external to internal format
- **Grants contract permission** to use value (`FHE.allowThis()`)
- **Grants user permission** to decrypt value (`FHE.allow()`)
- Stores value and allowed user address

**Key concepts:**
- **`FHE.allowThis()`**: Grants contract permission to use encrypted value
- **`FHE.allow(value, user)`**: Grants specific user permission to decrypt
- **User-specific access**: Only the allowed user can decrypt off-chain

**Why both permissions:**
- `FHE.allowThis()`: Contract needs to use value in operations
- `FHE.allow()`: User needs to decrypt value off-chain

**Common mistake:**
- Forgetting `FHE.allow()` means user cannot decrypt off-chain

#### 3. Request Entropy

```solidity
function requestEntropy(bytes32 tag) external payable returns (uint256 requestId) {
    require(msg.value >= entropyOracle.getFee(), "Insufficient fee");
    
    requestId = entropyOracle.requestEntropy{value: msg.value}(tag);
    entropyRequests[requestId] = true;
    
    return requestId;
}
```

**What it does:**
- Validates fee payment
- Requests entropy from EntropyOracle
- Stores request ID
- Returns request ID

#### 4. Store with Entropy and Allow

```solidity
function storeAndAllowWithEntropy(
    externalEuint64 encryptedInput,
    bytes calldata inputProof,
    address user,
    uint256 requestId
) external {
    require(entropyOracle.isRequestFulfilled(requestId), "Entropy not ready");
    
    euint64 internalValue = FHE.fromExternal(encryptedInput, inputProof);
    FHE.allowThis(internalValue);
    
    euint64 entropy = entropyOracle.getEncryptedEntropy(requestId);
    FHE.allowThis(entropy);  // CRITICAL!
    
    euint64 enhancedValue = FHE.xor(internalValue, entropy);
    FHE.allowThis(enhancedValue);
    FHE.allow(enhancedValue, user); // User can decrypt enhanced value
    
    encryptedValue = enhancedValue;
    allowedUser = user;
}
```

**What it does:**
- Validates request ID and fulfillment status
- Converts external encrypted input to internal
- Gets encrypted entropy from oracle
- **Grants permission** to use entropy (CRITICAL!)
- Combines value with entropy using XOR
- **Grants user permission** to decrypt enhanced value
- Stores entropy-enhanced value

**Key concepts:**
- **XOR mixing**: Combines user value with entropy
- **Enhanced decryption**: User decrypts entropy-enhanced value
- **Multiple permissions**: `FHE.allowThis()` for contract, `FHE.allow()` for user

**Why XOR then allow:**
- XOR adds randomness to value
- User decrypts the enhanced value (original value XOR entropy)
- Result: Entropy-enhanced user-specific decryption

## 🧪 Step-by-Step Testing

### Prerequisites

1. **Install dependencies:**
   ```bash
   npm install --legacy-peer-deps
   ```

2. **Compile contracts:**
   ```bash
   npx hardhat compile
   ```

### Running Tests

```bash
npx hardhat test
```

### What Happens in Tests

1. **Fixture Setup** (`deployContractFixture`):
   - Deploys FHEChaosEngine, EntropyOracle, and EntropyUserDecryption
   - Returns all contract instances

2. **Test: Store and Allow**
   ```typescript
   it("Should store and allow user to decrypt", async function () {
     const input = hre.fhevm.createEncryptedInput(contractAddress, owner.address);
     input.add64(42);
     const encryptedInput = await input.encrypt();
     
     await contract.storeAndAllow(
       encryptedInput.handles[0],
       encryptedInput.inputProof,
       user1.address
     );
     
     expect(await contract.isInitialized()).to.be.true;
     expect(await contract.getAllowedUser()).to.equal(user1.address);
   });
   ```
   - Creates encrypted input (value: 42)
   - Encrypts using FHEVM SDK
   - Calls `storeAndAllow()` with handle, proof, and user address
   - Verifies user is allowed to decrypt

3. **Test: Entropy Request**
   ```typescript
   it("Should request entropy", async function () {
     const tag = hre.ethers.id("test-user-decrypt");
     const fee = await oracle.getFee();
     await expect(
       contract.requestEntropy(tag, { value: fee })
     ).to.emit(contract, "EntropyRequested");
   });
   ```
   - Requests entropy with unique tag
   - Pays required fee
   - Verifies request event is emitted

### Expected Test Output

```
  EntropyUserDecryption
    Deployment
      ✓ Should deploy successfully
      ✓ Should have EntropyOracle address set
    Basic Storage and Allow
      ✓ Should store and allow user to decrypt
    Entropy-Enhanced Storage
      ✓ Should request entropy
      ✓ Should store with entropy and allow user

  5 passing
```

**Note:** Encrypted values appear as handles in test output. Allowed user can decrypt off-chain using FHEVM SDK.

## 🚀 Step-by-Step Deployment

### Option 1: Frontend (Recommended)

1. Navigate to [Examples page](https://entrofhe.vercel.app/examples)
2. Find "EntropyUserDecryption" in Tutorial Examples
3. Click **"Deploy"** button
4. Approve transaction in wallet
5. Wait for deployment confirmation
6. Copy deployed contract address

### Option 2: CLI

1. **Create deploy script** (`scripts/deploy.ts`):
   ```typescript
   import hre from "hardhat";

   async function main() {
     const ENTROPY_ORACLE_ADDRESS = "0x75b923d7940E1BD6689EbFdbBDCD74C1f6695361";
     
     const ContractFactory = await hre.ethers.getContractFactory("EntropyUserDecryption");
     const contract = await ContractFactory.deploy(ENTROPY_ORACLE_ADDRESS);
     await contract.waitForDeployment();
     
     const address = await contract.getAddress();
     console.log("EntropyUserDecryption deployed to:", address);
   }

   main().catch((error) => {
     console.error(error);
     process.exitCode = 1;
   });
   ```

2. **Deploy:**
   ```bash
   npx hardhat run scripts/deploy.ts --network sepolia
   ```

## ✅ Step-by-Step Verification

### Option 1: Frontend

1. After deployment, click **"Verify"** button on Examples page
2. Wait for verification confirmation
3. View verified contract on Etherscan

### Option 2: CLI

```bash
npx hardhat verify --network sepolia <CONTRACT_ADDRESS> 0x75b923d7940E1BD6689EbFdbBDCD74C1f6695361
```

**Important:** Constructor argument must be the EntropyOracle address: `0x75b923d7940E1BD6689EbFdbBDCD74C1f6695361`

## 📊 Expected Outputs

### After Store and Allow

- `isInitialized()` returns `true`
- `getAllowedUser()` returns user address
- `getEncryptedValue()` returns encrypted value (handle)
- User can decrypt value off-chain using FHEVM SDK
- `ValueStored` and `UserAllowed` events emitted

### After Store with Entropy and Allow

- `isInitialized()` returns `true`
- `getAllowedUser()` returns user address
- `getEncryptedValue()` returns entropy-enhanced encrypted value
- User can decrypt enhanced value off-chain
- Decrypted value is original value XOR entropy
- `ValueStoredWithEntropy` and `UserAllowed` events emitted

## ⚠️ Common Errors & Solutions

### Error: `SenderNotAllowed()`

**Cause:** Missing `FHE.allowThis()` or `FHE.allow()` call.

**Example:**
```solidity
euint64 value = FHE.fromExternal(encryptedInput, inputProof);
// Missing: FHE.allowThis(value);
// Missing: FHE.allow(value, user);
encryptedValue = value; // ❌ Error if used later!
```

**Solution:**
```solidity
euint64 value = FHE.fromExternal(encryptedInput, inputProof);
FHE.allowThis(value);  // ✅ Contract can use
FHE.allow(value, user); // ✅ User can decrypt
encryptedValue = value;
```

**Prevention:** Always call both `FHE.allowThis()` and `FHE.allow()` when needed.

---

### Error: `Invalid user address`

**Cause:** Zero address passed as user parameter.

**Example:**
```solidity
FHE.allow(value, address(0)); // ❌ Invalid!
```

**Solution:**
```solidity
require(user != address(0), "Invalid user address");
FHE.allow(value, user); // ✅ Valid address
```

**Prevention:** Always validate user address before calling `FHE.allow()`.

---

### Error: `Entropy not ready`

**Cause:** Calling `storeAndAllowWithEntropy()` before entropy is fulfilled.

**Solution:** Always check `isRequestFulfilled()` before using entropy.

---

### Error: `Already initialized`

**Cause:** Trying to store value twice.

**Solution:** This contract only allows one value. Deploy new contract for new value.

---

### Error: `Insufficient fee`

**Cause:** Not sending enough ETH when requesting entropy.

**Solution:** Always send exactly 0.00001 ETH:
```typescript
const fee = await contract.entropyOracle.getFee();
await contract.requestEntropy(tag, { value: fee });
```

---

### Error: Verification failed - Constructor arguments mismatch

**Cause:** Wrong constructor argument used during verification.

**Solution:** Always use the EntropyOracle address:
```bash
npx hardhat verify --network sepolia <CONTRACT_ADDRESS> 0x75b923d7940E1BD6689EbFdbBDCD74C1f6695361
```

## 🔗 Related Examples

- [EntropyPublicDecryption](../public-decryption-publicdecryptsingle/) - Entropy-based public decryption
- [EntropyAccessControl](../access-control-accesscontrol/) - Entropy-based access control
- [EntropyEncryption](../encryption-encryptsingle/) - Encrypting values with entropy
- [Category: user-decryption](../)

## 📚 Additional Resources

- [Full Tutorial Track Documentation](../../../frontend/src/pages/Docs.tsx) - Complete educational guide
- [Zama FHEVM Documentation](https://docs.zama.org/) - Official FHEVM docs
- [GitHub Repository](https://github.com/zacnider/fhevm-example-user-decryption-userdecryptsingle) - Source code

## 📝 License

BSD-3-Clause-Clear
