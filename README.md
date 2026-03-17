# EIP712-Playground
Hi! This is my personal playground for researching and playing with the EIP712 signature verification standard. If you want to learn more about EIP712, you can check their github repo [here](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-712.md). Please do read along to my hands-on examples and detailed explanation of the usage and implementation of the standard.

## 1. Introduction
Before we get into the details of signature verification, we first have to understand how private key and public key works in Ethereum. 
>This section contains a lot of math concepts, you may feel free to skip if you are only concerned with the usage and implementation of EIP712 in smart contracts. [click here](#3-eip712)

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
```math
y^2 = x^3 + 7
```
but over a finite field.

### Private Key
A private key is simply just: 
```math
k \in [1,n-1]\text{, } \\
\text{where } n = \text{order of the curve} \sim 2^{256}
``` 
Therefore, you can understand private key as a random 256-bit integer

### Public Key
As we mentioned above, the public key is derived from the private key, but how? 
There is a fixed point on the curve $G = (x , y)$
We basically derive the public key by the following formula:
```math
\text{Public Key} = k\cdot G
```
By the above formula, it is easy to compute $k\cdot G$ but practically impossible to recover $k$ from $k \cdot G$
This is based on the [Elliptic Curve Discrete Logarithm Problem (ECDLP)](https://www.cyfrin.io/blog/zk-math-101-the-elliptic-curve-discrete-logarithm-problem)

### Ethereum Address
Ethereum doesn't use the entire public key as address, but instead it hashes the public key with the Keccak-256 hash algorithm and take the last 20 bytes
```solidity
address = keccak256(publicKey)[12:]
```
Results:
Private Key -> Public Key -> Address

## 2. Signature
Now we get into our main part. "Signing a message" means you are proving ownership of a private key over a specific 32-byte value. You can basically sign anything on chain, from arbitrary data, to permissions for third party to execute transactions on your behalf. 

### ECDSA Signature
In Ethereum, they use the Elliptic Curve Digital Signature Algorithm (ECDSA) for signing hash messages. When you sign a message in Ethereum, you produce:
```
(r,s,v) // This is the cryptographic proof
```
A signature is built from 3 components:
1. Your private key ($d$)
2. The message hash ($z$)
3. A random ephemeral key ($k$) 

The following is the steps of creating a signature:
1. **Generate a random point ($r$)**
```math
\begin{aligned}
R = k \cdot G\\
    = (x , y)\\
r = R \cdot x \\
\text{r is derived from the randomness of k}
\end{aligned}
```
2. **Combine everything together ($s$)**
s is the glue that binds the message($z$), the private key($d$) and randomness ($k$) together.
```math
s = ((z +r \times d)/ k) mod(n)
``` 
3. **Add recovery info($v$)**
from $r$ we only know $r = R \cdot x$, but on an elliptic curve, each $x$ corresponds to 2 possible value of $y$. so therefore $v$ tells us which of the two possible curve points is the correct $R$
```math
R = (x , y) \text{ or } (x , -y)
```
### ecrecover
Give we have $(r,s,v,z)$
1. we can reconstruct $R$ using $(r,v)$
2. use the equation in the above (2. combine everything together) to solve backwards and recover the public key

## 3. EIP712
After all the complex mathematics, and understanding how cryptography proofs work in Ethereum to power signing and verifying signature, we can finally move on to understand what the EIP-712 standard is about. 

