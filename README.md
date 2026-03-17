# EIP712-Playground
Hi! This is my personal playground for researching and playing with the EIP712 signature verification standard. If you want to learn more about EIP712, you can check their github repo [here](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-712.md). Please do read along to my hands-on examples and detailed explanation of the usage and implementation of the standard.

## Introduction
Before we get into the details of signature verification, we first have to understand how private key and public key works in Ethereum. 
>This section contains a lot of math concepts, you may feel free to skip if you are only concerned with the usage and implementation of EIP712 in smart contracts. 

The core Idea of Ethereum Identity is as follows:
- **Private Key**: A secret only owner knows
- **Public Key**: A publicly known number derived from the secret
- **Signature**: A proof you know the secret without revealing it

These are all built on Elliptic Curve Cryptography
### Ethereum's Specific Curve: secp256k1
Ethereum uses the specific elliptic curve secp256k1 which stands for *Standards for Efficient Cryptography (SEC) prime field, 256-bit lenght, koblitz curve, version 1.* From the name you can derive the following properties:
- The curve utilizes a 256-bit prime field $(2^{256}-2^{32}-2^9-2^8-2^7-2^6-2^4-1)$.
- It is a koblitz curve which is a special class of curves optimised for faster signature verification.

The curve is roughly defined as:
$$y^2 = x^3 + 7$$ but over a finite field.

### Private Key
A private key is simply just: 
$$
k \in [1,n-1]\\
\text{where } n = \text{order of the curve} \sim 2^{256}
$$Therefore, you can understand private key as a random 256-bit integer

### Public Key
As we mentioned above, the public key is derived from the private key, but how? 
There is a fixed point on the curve $G = (x , y)$
We basically derive the public key by the following formula:
$$
\text{Public Key} = k\cdot G
$$By the above formula, it is easy to compute $k\cdot G$ but practically impossible to recover $k$ from $k \cdot G$
This is based on the [Elliptic Curve Discrete Logarithm Problem (ECDLP)](https://www.cyfrin.io/blog/zk-math-101-the-elliptic-curve-discrete-logarithm-problem)

### Ethereum Address
Ethereum doesn't use the entire public key as address, but instead it hashes the public key with the Keccak-256 hash algorithm and take the last 20 bytes
```solidity
address = keccak256(publicKey)[12:]
```
Results:
Private Key -> Public Key -> Address