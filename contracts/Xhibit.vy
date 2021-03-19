# @version 0.2.11
"""
@title An collection of NFT Exhibits
@license GPL-3.0
@author Edward Amor
@notice You can use this contract to manage owned NFT exhibits
"""


event Approval:
    _owner: indexed(address)
    _approved: indexed(address)
    _tokenId: indexed(uint256)

event ApprovalForAll:
    _owner: indexed(address)
    _operator: indexed(address)
    _approved: bool

event OwnershipTransferred:
    previousOwner: indexed(address)
    newOwner: indexed(address)

event Transfer:
    _from: indexed(address)
    _to: indexed(address)
    _tokenId: indexed(uint256)


token_id_tracker: uint256

owner: public(address)

balanceOf: public(HashMap[address, uint256])
ownerOf: public(HashMap[uint256, address])
isApprovedForAll: public(HashMap[address, HashMap[address, bool]])
getApproved: public(HashMap[uint256, address])


@external
def __init__():
    self.owner = msg.sender


@internal
def _mint(_to: address):
    """
    @dev Internal function for minting new tokens, reverts if
        `_to` is the zero address.
    @param _to Address which will receive the new token
    """
    assert _to != ZERO_ADDRESS  # dev: Minting to zero address disallowed

    token_id: uint256 = self.token_id_tracker
    self.balanceOf[_to] += 1
    self.ownerOf[token_id] = _to
    self.token_id_tracker += 1

    log Transfer(ZERO_ADDRESS, _to, token_id)


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
def mint(_to: address):
    """
    @notice External utility function for minting a new token
    @dev Reverts if caller is not the contract owner, or `_to` is
        zero address
    @param _to Address which receives the new token
    """
    assert msg.sender == self.owner  # dev: Caller is not owner

    self._mint(_to)


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


@payable
@external
def approve(_approved: address, _tokenId: uint256):
    """
    @notice Change or reaffirm the approved address for an NFT
    @dev The zero address indicates there is no approved address.
        Throws unless `msg.sender` is the current NFT owner, or an authorized
        operator of the current owner.
    @param _approved The new approved NFT controller
    @param _tokenId The NFT to approve
    """
    token_owner: address = self.ownerOf[_tokenId]
    assert (
        msg.sender == token_owner or self.isApprovedForAll[token_owner][msg.sender]
    )  # dev: Caller is neither owner nor operator

    self.getApproved[_tokenId] = _approved

    log Approval(token_owner, _approved, _tokenId)
