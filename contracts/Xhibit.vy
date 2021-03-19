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

event OwnershipTransferred:
    previousOwner: indexed(address)
    newOwner: indexed(address)


owner: public(address)

balanceOf: public(HashMap[address, uint256])
ownerOf: public(HashMap[uint256, address])
isApprovedForAll: public(HashMap[address, HashMap[address, bool]])
getApproved: public(HashMap[uint256, address])


@external
def __init__():
    self.owner = msg.sender


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
        0x000000000000000000000000000000000000000000000000000000007F5828D0,  # ERC-173
    ]


@external
def transferOwnership(_newOwner: address):
    """
    @notice Set the address of the new owner of the contract
    @dev Set `_newOwner` to address(0) to renounce any ownership.
    @param _newOwner The address of the new owner of the contract
    """
    assert msg.sender == self.owner  # dev: Caller is not owner

    previous_owner: address = self.owner
    self.owner = _newOwner

    log OwnershipTransferred(previous_owner, _newOwner)


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
