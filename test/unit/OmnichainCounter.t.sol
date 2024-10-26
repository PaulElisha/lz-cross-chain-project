// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../mocks/LZEndpointMock.sol";
import "../../src/OmnichainApps/OmnichainCounterA.sol";
import "../../src/OmnichainApps/OmnichainCounterB.sol";

contract OmnichainCounterTest is Test {
    LZEndpointMock lzEndpointMock;
    OmnichainCounterA omnichainCounterA;
    OmnichainCounterB omnichainCounterB;
    uint16 private constant chainid = 31337;

    function setUp() public {
        // `vm.deal()` and `vm.prank()` - `hoax()`
        // deploy our contracts and the lzEndpoint

        hoax(address(0x1), 100 ether);

        lzEndpointMock = new LZEndpointMock(chainid);

        hoax(address(0x2), 100 ether);

        omnichainCounterA = new OmnichainCounterA(
            address(lzEndpointMock),
            address(0x2)
        );

        hoax(address(0x3), 100 ether);

        omnichainCounterB = new OmnichainCounterB(
            address(lzEndpointMock),
            address(0x3)
        );

        // Send ether to the deployed contracts and the endpoint
        vm.deal(address(lzEndpointMock), 100 ether);
        vm.deal(address(omnichainCounterA), 100 ether);
        vm.deal(address(omnichainCounterB), 100 ether);

        // get the contract addresses
        bytes memory omnichainCounterB_Address = abi.encodePacked(
            uint160(address(omnichainCounterB))
        );

        bytes memory omnichainCounterA_Address = abi.encodePacked(
            uint160(address(omnichainCounterA))
        );

        // prank lzEndpoint deployer to set Destination lzEndpoint for contract A and B
        vm.startPrank(address(0x1));
        lzEndpointMock.setDestLzEndpoint(
            address(omnichainCounterA),
            address(lzEndpointMock)
        );

        lzEndpointMock.setDestLzEndpoint(
            address(omnichainCounterB),
            address(lzEndpointMock)
        );

        vm.stopPrank();

        vm.prank(address(0x2));
        omnichainCounterA.setTrustedRemoteAddress(
            chainid,
            omnichainCounterB_Address
        );

        vm.prank(address(0x3));
        omnichainCounterB.setTrustedRemoteAddress(
            chainid,
            omnichainCounterA_Address
        );
    }

    function testSepoliaToKaia() public {
        uint256 count = omnichainCounterA.counter();

        console.log(count);

        hoax(address(0x10), 100 ether);
        omnichainCounterA.increment{value: 1 ether}(chainid);

        console.log(omnichainCounterB.counter());

        assertEq(omnichainCounterB.counter(), count + 1);
    }
}
