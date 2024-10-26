// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "./CodeConstants.s.sol";
import "../test/mocks/LZEndpointMock.sol";

contract NetworkConfig is Script, CodeConstants {
    struct Config {
        address lzendpoint;
    }

    Config public anvilConfig;
    mapping(uint256 => Config) private configs;

    function _getConfigByChainID(
        uint256 chainid
    ) public returns (Config memory) {
        if (chainid == mainnetID) {
            return getMainnetConfig();
        } else if (chainid == testnetID) {
            return getTestnetConfig();
        } else {
            return getAnvilConfig();
        }
    }

    function getConfig() public returns (Config memory) {
        return _getConfigByChainID(block.chainid);
    }

    function getMainnetConfig() public view returns (Config memory) {
        Config memory config = configs[mainnetID];
        config.lzendpoint = 0x1a44076050125825900e736c501f859c50fE728c;

        return config;
    }

    function getTestnetConfig() public view returns (Config memory) {
        Config memory config = configs[testnetID];
        config.lzendpoint = 0x6EDCE65403992e310A62460808c4b910D972f10f;

        return config;
    }

    function getAnvilConfig() public returns (Config memory) {
        // To get anvil config, we need to first deploy a mock endpoint on anvil

        if (configs[localnetwork].lzendpoint != address(0)) {
            return (anvilConfig);
        }

        vm.startBroadcast();
        LZEndpointMock lzendpointMock = new LZEndpointMock(localnetwork);
        vm.stopBroadcast();

        anvilConfig = configs[localnetwork];
        anvilConfig.lzendpoint = address(lzendpointMock);

        return (anvilConfig);
    }
}
