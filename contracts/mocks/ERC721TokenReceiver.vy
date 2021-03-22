# @version 0.2.11
"""
@title Mock ERC721 Token Receiver
@dev On deployment specify if `onERC721Received` returns a
    successful response
"""


is_receiver: bool


@external
def __init__(is_receiver: bool):
    self.is_receiver = is_receiver


@external
def onERC721Received(
    _operator: address, _from: address, _tokenId: uint256, _data: Bytes[1024]
) -> Bytes[4]:
    value: Bytes[4] = empty(Bytes[4])
    if self.is_receiver:
        value = method_id("onERC721Received(address,address,uint256,bytes)")
    return value
