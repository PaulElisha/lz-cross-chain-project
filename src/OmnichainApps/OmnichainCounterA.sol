// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../NonblockingLzApp.sol";

contract OmnichainCounterA is NonblockingLzApp {
    uint256 public counter;
    bytes public constant PAYLOAD = "Sepolia_to_Kaia";

    event Incremented(uint256);

    constructor(
        address _lzEndpoint,
        address _initialOwner
    ) NonblockingLzApp(_lzEndpoint) Ownable(_initialOwner) {}

    function increment(uint16 _dstChainid) public payable {
        _lzSend(
            _dstChainid,
            PAYLOAD,
            payable(msg.sender),
            address(0),
            hex"",
            msg.value
        );
    }

    // The mock endpoint simply calls the `_nonblockingLzReceive` on smart contract number 2.
    // Sometimes it can include an additional logic you would want to execute when it's called
    // or emit an event.

    function _nonblockingLzReceive(
        uint16,
        bytes memory,
        uint64,
        bytes memory
    ) internal override {
        counter += 1;
        emit Incremented(counter);
    }

    /**
    Here is what the flow of a cross-chain message looks like: 
    
    Smart contract on Chain A -> LayerZero Endpoint on Chain A -> 
    Relayer + Oracle -> 
    LayerZero Endpoint on Chain B -> Smart contract on Chain B

    But since we can't really mock the behavior of the relayer and the oracle, 
    but how do we set up a mock endpoint, that can impersonate the cross-chain 
    behavior pattern of two endpoints on a single network? 

    How about this:

    Smart contract number 1 on local network calls send() function on mock endpoint.
    Mock endpoint does NOT check the message's validity in any way.
    The mock endpoint simply calls the _nonblockingLzReceive on smart contract number 2.
    
    Smart contract number 1 -> Mock Endpoint -> Smart contract number 2
    */

    /**

    The following functions are needed when the relayer and oracle are at work.

    estimateFee() - 

    setOracle() - 

    getOracle() - 

    */

    // function estimateFee(
    //     uint16 _dstChainId,
    //     bool _useZro,
    //     bytes calldata _adapterParams
    // ) public view returns (uint nativeFee, uint zroFee) {
    //     return
    //         lzEndpoint.estimateFees(
    //             _dstChainId,
    //             address(this),
    //             PAYLOAD,
    //             _useZro,
    //             _adapterParams
    //         );
    // }

    // function setOracle(uint16 dstChainId, address oracle) external onlyOwner {
    //     uint TYPE_ORACLE = 6;
    //     // set the Oracle
    //     lzEndpoint.setConfig(
    //         lzEndpoint.getSendVersion(address(this)),
    //         dstChainId,
    //         TYPE_ORACLE,
    //         abi.encode(oracle)
    //     );
    // }

    // function getOracle(
    //     uint16 remoteChainId
    // ) external view returns (address _oracle) {
    //     bytes memory bytesOracle = lzEndpoint.getConfig(
    //         lzEndpoint.getSendVersion(address(this)),
    //         remoteChainId,
    //         address(this),
    //         6
    //     );
    //     assembly {
    //         _oracle := mload(add(bytesOracle, 32))
    //     }
    // }
}
