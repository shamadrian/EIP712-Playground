// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract AdvancedMailSystem {
    using ECDSA for bytes32;
    // =========================
    //          STRUCT 
    // =========================

    struct Product {
        uint256 id;
        uint256 price;
        string name;
    }


    struct AdvancedMail {
        address from;
        address to;
        Product product;
        string[] tags;
    }

    mapping(address => AdvancedMail[]) private inbox;
    // prevent replay (same signature reused)
    mapping(bytes32 => bool) public usedDigests;

    // =========================
    //        TYPE HASHES
    // =========================

    bytes32 public constant PRODUCT_TYPEHASH =
        keccak256(
            "Product(uint256 id,uint256 price,string name)"
        );

    bytes32 public constant ADVANCEDMAIL_TYPEHASH =
        keccak256(
            "AdvancedMail(address from,address to,Product product,string[] tags)"
            "Product(uint256 id,uint256 price,string name)"
        );

    bytes32 public constant DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
    
    // =========================
    //        DOMAIN DATA
    // =========================

    bytes32 public immutable DOMAIN_SEPARATOR;
    constructor() {
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes("AdvancedMailDApp")),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );
    }

    // =========================
    //       HASHING LOGIC 
    // =========================

    function hashProduct(Product memory p) public pure returns (bytes32) {
        return keccak256(
            abi.encode(
                PRODUCT_TYPEHASH,
                p.id,
                p.price,
                keccak256(bytes(p.name)) // string → hash
            )
        );
    }

    function hashStringArray(string[] memory arr) public pure returns (bytes32) {
        bytes32[] memory hashes = new bytes32[](arr.length);

        for (uint256 i = 0; i < arr.length; i++) {
            hashes[i] = keccak256(bytes(arr[i]));
        }

        return keccak256(abi.encodePacked(hashes));
    }

    function hashAdvancedMail(AdvancedMail memory mail) public pure returns (bytes32) {
        return keccak256(
            abi.encode(
                ADVANCEDMAIL_TYPEHASH,
                mail.from,
                mail.to,
                hashProduct(mail.product),
                hashStringArray(mail.tags)
            )
        );
    }

    function getDigest(AdvancedMail memory mail) public view returns (bytes32) {
        return keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                hashAdvancedMail(mail)
            )
        );
    }

    // =========================
    //        MAIN LOGIC
    // =========================

    function deliverMail(
        AdvancedMail memory mail,
        bytes memory signature
    ) external {
        // 1. Reconstruct digest
        bytes32 digest = getDigest(mail);

        require(!usedDigests[digest], "Already used");

        address signer = digest.recover(signature);
        require(signer == mail.from, "Invalid signature");

        usedDigests[digest] = true;

        inbox[mail.to].push(mail);
    }

    function readMail(uint256 index) external view returns (AdvancedMail memory) {
        require(index < inbox[msg.sender].length, "Invalid index");
        return inbox[msg.sender][index];
    }
}   