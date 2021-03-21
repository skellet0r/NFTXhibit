# @version 0.2.11
"""
@title Mock ComposableTopDown ERC721 contract
"""


ERC998_MAGIC_VALUE: constant(
    bytes32
) = 0xCD740DB500000000000000000000000000000000000000000000000000000000
ETH_ADDR: constant(address) = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE


@view
@external
def rootOwnerOfChild(_childContract: address, _childTokenId: uint256) -> bytes32:
    return convert(
        bitwise_or(convert(ERC998_MAGIC_VALUE, uint256), convert(ETH_ADDR, uint256)),
        bytes32,
    )
