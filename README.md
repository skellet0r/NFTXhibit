# NFT Xhibit

A virtual space for exploring NFT collections.

## Description

This project implements a thin wrapper around existing protocols using ERC-998, allowing for essentially an NFT crypto-collectibles wallet.
This project was intended to give users of various NFT platforms/marketplaces a virtual world to store and view their collectibles in an
interesting virtual world.

This project uses the Vyper smart contract language to provide a thin wrapper around existing contracts and manage NFTs on-chain.
The UI utilizes the A-Frame 3D library for creating virtual experiences using standard HTML/JS.
Development required a heavy dosage of eth-brownie.

## Smart Contract Development Quickstart

```bash
$ git clone https://github.com/skellet0r/NFTXhibit.git
$ cd NFTXhibit
$ python -m venv venv
$ source ./venv/bin/activate
$ pip install -r requirements.txt
$ pre-commit install && pre-commit install --hook-type commit-msg
```

### Running the Test Suite

To run the suite of unit tests, along with outputting coverage and gas estimates run the following command.

```bash
$ brownie test -CG
```

### Contracts Overview

The primary contract is `contracts/Xhibit.vy`, written in vyper and following the ERC-721 and ERC-998 standards along with the associated enumeration extensions respectively.
This contract is supplemented with `contracts/CallProxy.sol`, written in solidity, which provides a simple wrapper function `tryStaticCall`. This wrapper function
is required because vyper does not yet have error catching functionality (think of `try ... except ...` syntax in python), which is required for the `rootOwnerOf` function to work
according to the ERC-998 standard.
