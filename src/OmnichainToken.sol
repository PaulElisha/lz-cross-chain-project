// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/access/Ownable.sol";
import "@layerzerolabs/oft-evm/contracts/OFT.sol";

/// @notice OFT is an ERC-20 token that extends the OFTCore contract.
contract OmnichainToken is OFT {
    constructor(
        string memory _name,
        string memory _symbol,
        address _lzEndpoint,
        address _delegate
    ) OFT(_name, _symbol, _lzEndpoint, _delegate) Ownable(_delegate) {}

    // only owner can mint to prevent creating a new token leading disrupting unifying liquidity
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}
