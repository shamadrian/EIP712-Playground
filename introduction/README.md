# Introduction
> **Note:** This section covers cryptographic math concepts. Feel free to [skip to implementation](../README.md) if you're only interested in EIP712 usage in smart contracts.

## 1. Ethereum Identity Fundamentals

The core idea of Ethereum Identity relies on three concepts:
- **Private Key**: A secret known only to the owner
- **Public Key**: A publicly derived number from the secret
- **Signature**: Cryptographic proof of secret knowledge without revealing it

These concepts are built on Elliptic Curve Cryptography.

### Ethereum's Curve: secp256k1

Ethereum uses the secp256k1 elliptic curve (*Standards for Efficient Cryptography prime field, 256-bit length, Koblitz curve, version 1*).

Key properties:
- Uses a 256-bit prime field: $(2^{256}-2^{32}-2^9-2^8-2^7-2^6-2^4-1)$
- Koblitz curve optimized for faster signature verification

The curve equation:
```math
y^2 = x^3 + 7
```
(over a finite field)

### Private Key

A private key is a random 256-bit integer:
```math
k \in [1,n-1] \text{ where } n \approx 2^{256}
```

### Public Key

The public key is derived using a fixed generator point $G = (x, y)$:
```math
\text{Public Key} = k \cdot G
```

Computing $k \cdot G$ is easy, but recovering $k$ from $k \cdot G$ is practically impossible—the [Elliptic Curve Discrete Logarithm Problem (ECDLP)](https://www.cyfrin.io/blog/zk-math-101-the-elliptic-curve-discrete-logarithm-problem).

### Ethereum Address

Ethereum derives the address by hashing the public key with Keccak-256 and taking the last 20 bytes:
```solidity
address = keccak256(publicKey)[12:]
```

**Flow:** Private Key → Public Key → Address

## 2. Digital Signatures (ECDSA)

Signing proves ownership of a private key for a specific 32-byte message.

### ECDSA Components

A signature produces three values: $(r, s, v)$, derived from:
1. Private key ($d$)
2. Message hash ($z$)
3. Random ephemeral key ($k$)

**Steps:**

1. **Generate random point** ($r$):
```math
R = k \cdot G = (x, y) \\
r = R_x
```

2. **Combine components** ($s$):
```math
s = \frac{z + r \cdot d}{k} \bmod n
```

3. **Add recovery info** ($v$):
Since each $x$ corresponds to two possible $y$ values, $v$ identifies which point is correct:
```math
R = (x, y) \text{ or } (x, -y)
```

### Recovery (ecrecover)

Given $(r, s, v, z)$:
1. Reconstruct $R$ using $(r, v)$
2. Solve backwards to recover the public key