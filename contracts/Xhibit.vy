# @version 0.2.11
"""
@title An collection of NFT Exhibits
@license GPL-3.0
@author Edward Amor
@notice You can use this contract to manage owned NFT exhibits
"""


@view
@external
def supportsInterface(interfaceID: bytes32) -> bool:
    """
    @notice Query if an interface is implemented
    @param interfaceID The interface identifier, as specified in ERC-165
    @return `True` if the contract implements `interfaceID` and
        `interfaceID` is not 0xffffffff, `False` otherwise
    """
    return interfaceID in [
        0x0000000000000000000000000000000000000000000000000000000001FFC9A7,  # ERC-165
    ]
