# EIP712-Playground
Hi! This is my personal playground for researching and playing with the EIP712 signature verification standard. If you want to learn more about EIP712, you can check their github repo [here](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-712.md). Please do read along to my hands-on examples and detailed explanation of the usage and implementation of the standard.

Before we get into the details of signature verification, you might want to understand how private key and public key works in Ethereum. If so, please [click here](./introduction/README.md) to our dedicated introduction.


# EIP-712

 EIP-712 is a standard for signing structured data in a way that is:

- Human-readable
- Deterministic
- Secure against replay attacks

## ❌ The Problem 

In Ethereum, signing typically looks like this:

`keccak256(message)` → sign → verify

This approach has several issues:

1. **No structure** — everything becomes a blob of bytes
2. **Ambiguity** — different inputs can hash to the same meaning
3. **Poor UX** — users cannot clearly see what they are signing
4. **Replay risks** — signatures can be reused across domains

## ✅ Solution

EIP-712 introduces structured signing by enforcing:

- Typed data (like structs)
- Domain separation (contract + chain-specific)
- Deterministic encoding rules

Instead of signing raw bytes, we sign:

```solidity
keccak256(
    "\x19\x01",
    domainSeparator,
    hashStruct(message)
)
```
## Full flow of EIP 712
```
User Input (Struct)
        ↓
encodeType
        ↓
encodeData
        ↓
hashStruct
        ↓
Domain Separator
        ↓
Final Digest
        ↓
ECDSA Sign
```

So let's go through each of the important stages one by one. 

Let's say we have the current struct
```solidity
struct Mail {
    address from;
    address to;
    string contents;
}
```
Suppose Alice wants to send to Bob:
```
From: alice's address
To: bob's address
Message: "Hello Bob"
```
Our goal is to transform this structured data into a deterministic hash that can be signed and later verified.

### 1. Encode Type
The first step is to define the type signature of the struct.
In our case, for our `Mail Struct`, we have:
```solidity
Mail(address from,address to,string contents)
```
Then we hash it into TYPE_HASH:
```solidity
bytes32 TYPE_HASH = keccak256(
    "Mail(address from,address to,string contents)"
);
```
This ensures that the structure itself is part of the signature.
### 2. Encode Data
Next, we encode the actual data according to strict rules.
```solidity
abi.encode(
    TYPE_HASH, //our encode type
    from, 
    to,
    keccak256(bytes(contents))
)
```
⚠️ Important Notes
- string and bytes are not encoded directly
- They are first hashed using keccak256
So in our case: 
`keccak256(bytes("Hello Bob"));`
### 3. Hash Struct
```solidity
bytes32 structHash = keccak256(
    abi.encode(
        TYPE_HASH,
        from,
        to,
        keccak256(bytes(contents))
    )
);
```
At this stage, we have a deterministic hash representing our struct.
### 4. Domain Separator
In order to prevent replay attacks, EIP712 introduced domain separators
```solidity
bytes32 DOMAIN_SEPARATOR = keccak256(
    abi.encode(
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        ),
        keccak256(bytes("MyApp")),
        keccak256(bytes("1")),
        block.chainid,
        address(this)
    )
);
```
- name, version, verifyingContract allows the signature to be tied to a specific contract to prevent cross contract replay attacks
- chainId allows the signature to be tied to a specific chain to prevent cross-chain attacks

### 5. Final Digest
Now we combine everything together
```solidity
bytes32 digest = keccak256(
    abi.encodePacked(
        "\x19\x01",
        DOMAIN_SEPARATOR,
        structHash
    )
);
```

### 6. Signing
Signing comes from off chain (e.g ethers.js):
```javascript
const signature = await signer.signTypedData(domain, types, message);
```
But for testing purposes, you can use foundry's `vm.sign`
```solidity
 (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, digest);
```
### 7. Verification
On-chain verification uses the `ecrecover` function
```solidity
address signer = ecrecover(digest, v, r, s);
``` 

## Example 

To solidify the concepts above, this repository includes a **minimal on-chain mail system**:

- `MailSystem.sol` → contract implementation  
- `MailSystem.t.sol` → Foundry test demonstrating signing + verification  

### MailSystem

This example implements a **signature-based messaging system**:

1. A sender (Alice) signs a structured `Mail` message **off-chain**  
2. Anyone (relayer) can submit the signed message **on-chain**  
3. The contract verifies the signature using EIP-712  
4. The message is stored in the recipient’s inbox (Bob)  
5. Only the recipient can read their own messages  

This mirrors real-world patterns such as:
- meta-transactions  
- permit-style approvals  
- off-chain authorization + on-chain execution  

**Contract Implementation**
- `MAIL_TYPEHASH` → defines struct format  
- `DOMAIN_SEPARATOR` → binds signatures to this contract + chain  
- `getDigest()` → builds the final signed message  

This directly implements the flow:
struct → hashStruct → domain → digest → verify
- Uses OpenZeppelin’s `ECDSA`
- Avoids manual handling of `(v, r, s)`

### MailSystemTest

In `test_deliverAndReadMail` we try to replicate a real-world scenario of off chain creating digest and signing the digest. 

- we built the digest by 
    1. Get `DOMAIN_SEPARATOR` from target contract
    2. Get `MAIL_TYPEHASH` from target contract
    3. Hash the data with the type hash together to get the mailHash
    3. Hash everything together to form the digest
    Note: Contracts that implement EIP712 usually has the `DOMAIN_SEPARATOR` and `TYPEHASH` as public for users to read directly, but in case they didn't, all you need to do is follow the hashing method provided above
- Mimic the signature signing off-chain with `vm.sign` foundry function
- Mimic a relayer (any third-party address) to deliver the message on behalf of Alice with her signature

# Real-world Usage
You might already have a brief understanding of the importance of EIP712. Now it is time for us to take a look at how we can utilize this standard to improve the Ethereum ecosystem. 

EIP-712 is widely adopted across DeFi and Web3:

- **ERC20 Permit (EIP-2612)** → gasless token approvals  
- **NFT marketplaces** → off-chain order signing  
- **DAO voting systems** → signed votes  
- **Authentication systems** → "Sign-in with Ethereum"  
- **Bridges & cross-chain protocols** → verified off-chain intents  
