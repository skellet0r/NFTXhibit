# @version 0.2.11
"""
@title Mock ERC721 Receiver contract
"""


is_receiver: bool


@external
def __init__(is_receiver: bool):
    self.is_receiver = is_receiver


@external
def onERC721Received(
    _operator: address, _from: address, _tokenId: uint256, _data: Bytes[1024]
) -> bytes32:
    value: bytes32 = empty(bytes32)
    if self.is_receiver:
        value = method_id(
            "onERC721Received(address,address,uint256,bytes)", output_type=bytes32
        )
    return value
