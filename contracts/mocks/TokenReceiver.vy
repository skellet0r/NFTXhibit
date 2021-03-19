# @version 0.2.11
"""
@title Mock ERC721 Receiver contract
"""


ON_ERC721_RECEIVED: constant(
    bytes32
) = 0x00000000000000000000000000000000000000000000000000000000150B7A02


is_receiver: bool


@external
def __init__(is_receiver: bool):
    self.is_receiver = is_receiver


@external
def onERC721Received(
    _operator: address, _from: address, _tokenId: uint256, _data: Bytes[1024]
) -> bytes32:
    if self.is_receiver:
        return ON_ERC721_RECEIVED
    else:
        return 0x0000000000000000000000000000000000000000000000000000000000000000
