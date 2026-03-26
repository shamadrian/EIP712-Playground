// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract MailSystem {
    using ECDSA for bytes32;
    // =========================
    //          STRUCT 
    // =========================

    struct Mail {
        address from;
        address to;
        string contents;
    }

    mapping(address => Mail[]) private inbox;
    // prevent replay (same signature reused)
    mapping(bytes32 => bool) public usedDigests;

    // =========================
    //        TYPE HASHES 
    // =========================

    bytes32 public constant MAIL_TYPEHASH =
        keccak256("Mail(address from,address to,string contents)");

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
                keccak256(bytes("MailDApp")),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );
    }

    // =========================
    //       HASHING LOGIC 
    // =========================

    function hashMail(Mail memory mail) public pure returns (bytes32) {
        return keccak256(
            abi.encode(
                MAIL_TYPEHASH,
                mail.from,
                mail.to,
                keccak256(bytes(mail.contents))
            )
        );
    }

    function getDigest(Mail memory mail) public view returns (bytes32) {
        bytes32 structHash = hashMail(mail);

        return keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                structHash
            )
        );
    }

    // =========================
    //        MAIN LOGIC
    // =========================
    function deliverMail(
        Mail memory mail,
        bytes memory signature
    ) external {
        bytes32 digest = getDigest(mail);

        require(!usedDigests[digest], "Already used");

        address signer = digest.recover(signature);
        require(signer == mail.from, "Invalid signature");

        usedDigests[digest] = true;

        inbox[mail.to].push(mail);
    }

    function readMail(uint256 index) external view returns (Mail memory) {
        require(index < inbox[msg.sender].length, "No mail at this index");
        return inbox[msg.sender][index];
    }
}