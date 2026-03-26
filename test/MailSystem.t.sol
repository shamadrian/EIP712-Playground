// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test , console2} from "forge-std/Test.sol";
import {MailSystem} from "../src/MailSystem.sol";

contract MailSystemTest is Test {
    MailSystem public mailContract;
    address public alice;
    uint256 public aliceKey;
    address public bob;
    uint256 public bobKey;

    function setUp() public {
        mailContract = new MailSystem();
        (alice, aliceKey) = makeAddrAndKey("alice");
        (bob, bobKey) = makeAddrAndKey("bob");
    }

    function test_deliverAndReadMail() public {
        // Create Mail struct in memory
        // The message Alice wants to send to Bob
        MailSystem.Mail memory m = MailSystem.Mail({
            from: alice,
            to: bob,
            contents: "Hello Bob"
        });

        // Create digest 
        // We try to create the digest from a client-side perspective, to simulate the off-chain signing process
        bytes32 DOMAIN_SEPARATOR = mailContract.DOMAIN_SEPARATOR();
        bytes32 MAIL_TYPEHASH = mailContract.MAIL_TYPEHASH();
        
        bytes32 mailHash = keccak256(
            abi.encode(
                MAIL_TYPEHASH,
                m.from,
                m.to,
                keccak256(bytes(m.contents))
            )
        );

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                mailHash
            )
        );
        
        //Alice signs the digest off-chain
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(aliceKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        // Relayer send the mail on-chain, with Alice's signature
        // Anyone can submit the mail (gasless UX)
        address relayer = address(0x999);
        vm.prank(relayer);
        mailContract.deliverMail(m, signature);

        // Bob reads his inbox
        vm.prank(bob);
        MailSystem.Mail memory received = mailContract.readMail(0);

        assertEq(received.from, alice);
        assertEq(received.to, bob);
        assertEq(received.contents, "Hello Bob");
        console2.log("Mail contents:", received.contents);
    }

}
