# @version 0.2.11
"""
@title An collection of NFT Exhibits
@license GPL-3.0
@author Edward Amor
@notice You can use this contract to manage owned NFT exhibits
"""


event ApprovalForAll:
    _owner: indexed(address)
    _operator: indexed(address)
    _approved: bool


balanceOf: public(HashMap[address, uint256])
ownerOf: public(HashMap[uint256, address])
isApprovedForAll: public(HashMap[address, HashMap[address, bool]])


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


@external
def setApprovalForAll(_operator: address, _approved: bool):
    """
    @notice Enable or disable approval for a third party ("operator") to manage
        all of `msg.sender`'s assets
    @dev Emits the ApprovalForAll event. The contract MUST allow
        multiple operators per owner.
    @param _operator Address to add to the set of authorized operators
    @param _approved True if the operator is approved, False to revoke approval
    """
    self.isApprovedForAll[msg.sender][_operator] = _approved

    log ApprovalForAll(msg.sender, _operator, _approved)
