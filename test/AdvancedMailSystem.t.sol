// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test , console2} from "forge-std/Test.sol";
import {AdvancedMailSystem} from "../src/AdvancedMailSystem.sol";

contract AdvancedMailSystemTest is Test {
    AdvancedMailSystem public mailContract;
    address public alice;
    uint256 public aliceKey;
    address public bob;
    uint256 public bobKey;

    function setUp() public {
        mailContract = new AdvancedMailSystem();
        (alice, aliceKey) = makeAddrAndKey("alice");
        (bob, bobKey) = makeAddrAndKey("bob");
    }

    function test_deliverAndReadAdvancedMail() public {
        AdvancedMailSystem.Product memory product = AdvancedMailSystem.Product({
            id: 1,
            price: 100,
            name: "Glass Vase"
        });

        string[] memory tags = new string[](2);
        tags[0] = "fragile";
        tags[1] = "gift";

        AdvancedMailSystem.AdvancedMail memory m = AdvancedMailSystem.AdvancedMail({
            from: alice,
            to: bob,
            product: product,
            tags: tags
        });

        bytes32 DOMAIN_SEPARATOR = mailContract.DOMAIN_SEPARATOR();
        bytes32 PRODUCT_TYPEHASH = mailContract.PRODUCT_TYPEHASH();
        bytes32 ADVANCEDMAIL_TYPEHASH = mailContract.ADVANCEDMAIL_TYPEHASH();

        bytes32 productHash = keccak256(
            abi.encode(
                PRODUCT_TYPEHASH,
                product.id,
                product.price,
                keccak256(bytes(product.name))
            )
        );

        bytes32[] memory tagHashes = new bytes32[](tags.length);
        for (uint256 i = 0; i < tags.length; i++) {
            tagHashes[i] = keccak256(bytes(tags[i]));
        }

        bytes32 tagsHash = keccak256(abi.encodePacked(tagHashes));

        bytes32 mailHash = keccak256(
            abi.encode(
                ADVANCEDMAIL_TYPEHASH,
                alice,
                bob,
                productHash,
                tagsHash
            )
        );

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                mailHash
            )
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(aliceKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        address relayer = address(0x999);
        vm.prank(relayer);
        mailContract.deliverMail(m, signature);

        vm.prank(bob);
        AdvancedMailSystem.AdvancedMail memory received =
        mailContract.readMail(0);

        // =========================
        // ===== ASSERT ============
        // =========================

        assertEq(received.from, alice);
        assertEq(received.to, bob);
        assertEq(received.product.name, "Glass Vase");
        assertEq(received.tags[0], "fragile");
        assertEq(received.tags[1], "gift");
        console2.log("Product:", received.product.name);
        console2.log("Price:", received.product.price);
        console2.log("ID:", received.product.id);
        console2.log("Tags:", received.tags[0], ",", received.tags[1]);

    }

}