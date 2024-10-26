// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/OmnichainToken.sol";
import "./NetworkConfig.s.sol";

contract DeployOmnichainToken is Script, CodeConstants {
    OmnichainToken public omnichainToken;
    NetworkConfig public networkConfig;

    function run() public returns (OmnichainToken) {
        return _deployOmnichainToken();
    }

    function _deployOmnichainToken() public returns (OmnichainToken) {
        networkConfig = new NetworkConfig();

        // networkConfig.Config memory config = networkConfig.getConfig();
        // address lzendpoint = config.lzendpoint;

        address lzendpoint = networkConfig.getConfig().lzendpoint;

        vm.startBroadcast();

        omnichainToken = new OmnichainToken(
            "OmnichainToken",
            "Oct",
            lzendpoint,
            msg.sender
        );

        vm.stopBroadcast();

        return omnichainToken;
    }
}
