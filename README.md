# EIP712-Playground
Hi! This is my personal playground for researching and playing with the EIP712 signature verification standard. If you want to learn more about EIP712, you can check their github repo [here](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-712.md). Please do read along to my hands-on examples and detailed explanation of the usage and implementation of the standard.

## 1. Introduction
Before we get into the details of signature verification, you might want to understand how private key and public key works in Ethereum. If so, please [click here](./introduction/README.md) to our dedicated introduction.


# 2. EIP-712

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