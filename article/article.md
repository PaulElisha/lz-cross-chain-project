# Layer Zero

## Introduction:

Interoperability has been an issue within the blockchain space considering that blockchains exist in silos. This means that there is an isolated environment every blockchain platform lives in and every user interested in the solution of a particular blockchain platform would be required to interact with it privately. However, there needs to be a possibility where a user on one blockchain platform would want to communicate with another user on another blockchain platform. This is the problem blockchain interoperability aims to solve.

Speaking of communication across platforms, let’s establish the low-level workings of communication and the types of communication that happens within a blockchain platform.

- Asset Transfer: This is a form of communication where value is transferred from a user to another on the same blockchain platform.

Example: 
Alice wants to send 5 KAIA to Bob. This happens when Bob shares his wallet address on that blockchain network with Alice. This form of communication can be called a wallet to wallet communication.

Basically, what happens is a state change. Updating a mapping that stores user’s balances.

```solidity
    function transfer(
        address _to,
        uint256 _value
    ) public returns (bool success) {
        balances[msg.sender] -= _value;
        balances[_to] += _value;
    }
```

- Message Transfer: This is a form of communication where a message is sent to another user, this could happen via an application (DApp) the user interacts with. 
- Data Transfer: This happens when Alice sends calldata to Bob to execute in a smart contract.

All of the above are some of the communication that can happen between a sender and a receiver on the same blockchain platform.

Interoperability is when two distinct blockchain platforms are operable within themselves, that is, you can interact or communicate with one from another. It is also called cross-chain communication.

In simpler terms, “Cross-chain technology can be understood as a chain-to-chain communication ”, according to IEEE Xplore.

## Why is cross-chain so important?

According to the Electric capital 2023 report, “34% of all open-source crypto developers worked on more than one chain in 2023.” 
- Trade-offs are constantly being made by the developers of a platform and users likewise, in terms of speed, cost, and security based on their use case.

- It facilitates the creation of a global ledger. That is, a smart contract can be deployed on multiple distinct chains and one is able to tailor those differences based on the strengths and trade-offs of that chain.

- Easy way of communicating with the community on those chains. 

Cross-chain Interoperability protocols are designed to connect blockchain networks that were originally isolated and independent, fostering interaction, permitting the movement of liquidity and updating of state between blockchain platforms..

They allow for diverse actions across chains such as cross-chain smart contract execution, data exchange, value transfer or movement of liquidity etc.

They can be seen as bridges, however, bridges are primarily specialized for asset transfer.

In this article, our focus is on the Layer Zero protocol.

First, what are bridges?

Bridges connect isolated groups of people. There are segmented groups that have information on each side but no way of communicating across what it is and so by unlocking with a bridge that flow of information we are able to coordinate the transfer of goods and services. In blockchain technology, the coordination of financial services.

Layer Zero acts as a universal message passing layer, facilitating communication and interaction across platforms. This interoperability is crucial for creating a cohesive ecosystem where assets can move freely without losing their integrity.

It facilitates the creation of tokens across multiple chains while maintaining a unified total supply. This is what primarily interoperability does and Layer Zero is at the vantage of it. This is achieved through the omnichain fungible token (OFT) standard which allows tokens to be transferred seamlessly between blockchains without the need for wrapping or creating synthetic assets.

## Understanding Unified Liquidity Supply.

Unified Liquidity supply refers to maintaining consistent liquidity across different chains without increasing the overall asset supply. 

`An ideal scenario:`

When transferring tokens between chains, if 1 million units of a token is debited from Ethereum and credited to the base chain, it should reflect as a direct transfer without altering the total supply. 

For true unified liquidity, you would need a mechanism that ensures that when tokens are moved from one chain to another, they are not simply minted anew but rather moved in such a way that they maintain their original total supply.

```solidity
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
```
With the `onlyOwner` modifier, unlike in a regular erc20 token, it's the mechanism that ensures no one can mint a token a new on the other blockchain. It restricts access to the owner of the oft-based token contract that was created.

## The Workings of Layer Zero

Unified Supply Mechanism.

The OFT standard operates by burning tokens on the source chain where a transfer is initiated. This action reduces the total supply on that chain.
Simultaneously, corresponding units of tokens are minted on the destination chain effectively maintaining the same total supply across both chains.
This process ensures that the overall supply of the token remains consistent, preventing inflation or deflation due to cross-chain transactions.


Communication Mechanism.

All forms of communication mentioned above are applicable to cross-chain communication. Let's examine the distinct mechanism of cross-chain asset transfer and how it differs from the one mentioned above. 

Under the hood, there is a debit function in the layer zero that does debit the sender transferring the tokens. Similar to the erc20 token mechanism, however, instead of updating balances, it burns tokens from the sender account and mints the burned token on the destination chain to the receiver account.

On Ethereum
```solidity
    function _debit(
        address _from,
        uint256 _amountLD,
        uint256 _minAmountLD,
        uint32 _dstEid
    ) internal virtual override returns (uint256 amountSentLD, uint256 amountReceivedLD) {
        (amountSentLD, amountReceivedLD) = _debitView(_amountLD, _minAmountLD, _dstEid);

        // @dev In NON-default OFT, amountSentLD could be 100, with a 10% fee, the amountReceivedLD amount is 90,
        // therefore amountSentLD CAN differ from amountReceivedLD.

        // @dev Default OFT burns on src.
        _burn(_from, amountSentLD);
    }
```

This debit function is not called by the user but there is a send function called by the user that does call the internal function `debit` to remove tokens from the sender. 

```solidity

    // The `send()` external function calling the `_send()` internal function.
    function send(
        SendParam calldata _sendParam,
        MessagingFee calldata _fee,
        address _refundAddress
    ) external payable virtual returns (MessagingReceipt memory msgReceipt, OFTReceipt memory oftReceipt) {
        return _send(_sendParam, _fee, _refundAddress);
    }

    // The `_send()` internal function calling the debit function.
    function _send(
        SendParam calldata _sendParam,
        MessagingFee calldata _fee,
        address _refundAddress
    ) internal virtual returns (MessagingReceipt memory msgReceipt, OFTReceipt memory oftReceipt) {
        // @dev Applies the token transfers regarding this send() operation.
        // - amountSentLD is the amount in local decimals that was ACTUALLY sent/debited from the sender.
        // - amountReceivedLD is the amount in local decimals that will be received/credited to the recipient on the remote OFT instance.
        (uint256 amountSentLD, uint256 amountReceivedLD) = _debit(
            msg.sender,
            _sendParam.amountLD,
            _sendParam.minAmountLD,
            _sendParam.dstEid
        );

        // @dev Builds the options and OFT message to quote in the endpoint.
        (bytes memory message, bytes memory options) = _buildMsgAndOptions(_sendParam, amountReceivedLD);

        // @dev Sends the message to the LayerZero endpoint and returns the LayerZero msg receipt.
        msgReceipt = _lzSend(_sendParam.dstEid, message, options, _fee, _refundAddress);
        // @dev Formulate the OFT receipt.
        oftReceipt = OFTReceipt(amountSentLD, amountReceivedLD);

        emit OFTSent(msgReceipt.guid, _sendParam.dstEid, msg.sender, amountSentLD, amountReceivedLD);
    }
```

On Kaia
```solidity

    // This is a receive function on the destination chain that receives the token and updates the receiver balance on the destination chain.

    function _lzReceive(
        Origin calldata _origin,
        bytes32 _guid,
        bytes calldata _message,
        address /*_executor*/, // @dev unused in the default implementation.
        bytes calldata /*_extraData*/ // @dev unused in the default implementation.
    ) internal virtual override {
        // @dev The src sending chain doesnt know the address length on this chain (potentially non-evm)
        // Thus everything is bytes32() encoded in flight.
        address toAddress = _message.sendTo().bytes32ToAddress();
        // @dev Credit the amountLD to the recipient and return the ACTUAL amount the recipient received in local decimals
        uint256 amountReceivedLD = _credit(toAddress, _toLD(_message.amountSD()), _origin.srcEid);

        if (_message.isComposed()) {
            // @dev Proprietary composeMsg format for the OFT.
            bytes memory composeMsg = OFTComposeMsgCodec.encode(
                _origin.nonce,
                _origin.srcEid,
                amountReceivedLD,
                _message.composeMsg()
            );

            // @dev Stores the lzCompose payload that will be executed in a separate tx.
            // Standardizes functionality for executing arbitrary contract invocation on some non-evm chains.
            // @dev The off-chain executor will listen and process the msg based on the src-chain-callers compose options passed.
            // @dev The index is used when a OApp needs to compose multiple msgs on lzReceive.
            // For default OFT implementation there is only 1 compose msg per lzReceive, thus its always 0.
            endpoint.sendCompose(toAddress, _guid, 0 /* the index of the composed message*/, composeMsg);
        }

        emit OFTReceived(_guid, _origin.srcEid, toAddress, amountReceivedLD);
    }
```


## The Implications for Unified Liquidity Supply.
Increased capital efficiency: A unified liquidity model allows for better utilization of capital as liquidity providers can contribute to a single pool that serves multiple chains rather than managing pools on separate chains.
Enhanced Market Dynamics: With unified liquidity, market participants can access deeper pools of liquidity, leading to better pricing and reduced slippage when trading assets across different chains.
Greater adoption potential: The ease of transferring assets without losing value or encountering significant barriers can encourage more users to engage with DeFi applications across various blockchain ecosystems. 

## Building a cross-chain application

How do we build a cross-chain application? Let's do a walk through to understand how to build an application that sends a message cross-chain.

We will build a counter application where a user calls a function to increment a count on the source chain and it gets incremented on the destination chain.

Breakdown.

1. Components: The following components are useful when building a cross-chain application using layer zero.

- LzApp: It is the general layer zero implementation contract that contains all the logic needed by a user. It is useful for the configuration, sending and receiving of data cross-chain. 

At the constructor level, the LzApp sets the endpoint address to ensure that the endpoint contract knows which contract to interact with when sending and receiving cross-chain messages.

The configuration functions ensure that a user can set the version, chainID, configType etc. Also, it allows a user to set gaslimit for their cross-chain transaction, and a trusted remote address, which is the application address, ensuring a communication path is established, etc. The receive function is a callback function called by the layer zero endpoint, it ensures that a receiver application is able to receive the data sent cross-chain via a payload. Lastly, the send function facilitates the sending of cross-chain messages.

- NonblockingLzApp: this contract ensures that failed messages are nonblocking, that is, it does not block the message pathway even if the configuration is not properly set. With it's try-catch logic, it tries a message to ensure that they can't block the message pathway and catch them if they fail for future retry. The nonblockingLzApp inherits the LzApp making it easy to ensure that our application integrates the generic layer zero contract while ensuring our app remain nonblocking.

- Application

Before examining the code, let's reason the application flow from first principles.

A counter application is simply a counter application. It contains a counter for tracking the current count in our application but we need a function to increment the count by the user, this is where the `increment()` function comes in.

We need to have a way to ensure that when we increment our count, it sends that message across and we are able to receive it on the destination chain. This implies that, our application will have a sender and a receiver contract.

--Counter.sol

```solidity

// we need our contract to inherit the layer zero application through the nonblockingLzApp

// the contract for both sending and receiver logic will be created and deployed on different chains.

contract Counter is NonblockingLzApp {
    
    uint256 counter     // counter to track the number of count


    // the endpoint contract will send the message so we will set it at the constructor level

    constructor(address _endpoint) NonblockingLzApp(_endpoint) Ownable(_initiaOwner) {}

    function increment(uint16 destChainId) public payable {
        // this function could send the current state of count and effect the increment on the destination chain or it could increment the current state of count and send the message to the destination chain.

        // we want to send the current state of count cross-chain

        // we made it payable because we would need to send ether to cover for the gas fees

        // the message to send, a payload

        bytes public payload = abi.encode(counter);

        // then we call the layer zero send logic
        _lzSend(
            _dstChainid,
            payload,
            payable(msg.sender),
            address(0),
            hex"",
            msg.value
        );
    }

    // this function is necessary in both sender and receiver applications

    function _nonblockingLzReceive(
        uint16,
        bytes memory,
        uint64,
        bytes memory
    ) internal override {
        counter += 1;
        emit Incremented(counter);
    }

    // The following functions are needed when the relayer and oracle are at work. But this is a simple implementation

    estimateFee() - 

    setOracle() - 

    getOracle() - 
}


```

--Test.t.sol

```solidity
paulelisha@Macbook-M3-Pro omnichain-layerzero % forge t --mt testSepoliaToKaia
[⠊] Compiling...
[⠢] Compiling 5 files with Solc 0.8.28
[⠆] Solc 0.8.28 finished in 1.16s
Compiler run successful!

Ran 1 test for test/unit/OmnichainCounter.t.sol:OmnichainCounterTest
[PASS] testSepoliaToKaia() (gas: 173852)
Suite result: ok. 1 passed; 0 failed; 0 skipped; finished in 7.17ms (1.44ms CPU time)

Ran 1 test suite in 130.63ms (7.17ms CPU time): 1 tests passed, 0 failed, 0 skipped (1 total tests)
```

Conclusion: We have explained in detail how layer zero works and demonstrated how to build a cross-chain application. 

Congratulations to you for coming this far.