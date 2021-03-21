# @version 0.2.11
"""
@title An collection of NFT Exhibits
@license GPL-3.0
@author Edward Amor
@notice You can use this contract to manage owned NFT exhibits
"""
from vyper.interfaces import ERC721


TOKEN_RECEIVED: constant(Bytes[4]) = 0x150b7a02
ERC998_MAGIC_VALUE: constant(
    bytes32
) = 0xcd740db500000000000000000000000000000000000000000000000000000000


interface ERC721TokenReceiver:
    def onERC721Received(
        _operator: address, _from: address, _tokenId: uint256, _data: Bytes[1024]
    ) -> Bytes[4]: nonpayable


struct ChildTokenData:
    parent_token_address: address
    parent_token_id: uint256
    is_held: bool


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

event ReceivedChild:
    _from: indexed(address)
    _toTokenId: indexed(uint256)
    _childContract: indexed(address)
    _childTokenId: uint256

event Transfer:
    _from: indexed(address)
    _to: indexed(address)
    _tokenId: indexed(uint256)

event TransferChild:
    _fromTokenId: indexed(uint256)
    _to: indexed(address)
    _childContract: indexed(address)
    _childTokenId: uint256


token_id_tracker: uint256

owner: public(address)

balanceOf: public(HashMap[address, uint256])
ownerOf: public(HashMap[uint256, address])
isApprovedForAll: public(HashMap[address, HashMap[address, bool]])
getApproved: public(HashMap[uint256, address])

# child token contract => child token id => child token data
child_token_data: HashMap[address, HashMap[uint256, ChildTokenData]]


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


@internal
def _transferFrom(_from: address, _to: address, _tokenId: uint256):
    """
    @dev Internal function for transferring tokens between accounts.
    @param _from Token owner address
    @param _to Token recipient address
    @param _tokenId Token to transfer
    """
    assert _to != ZERO_ADDRESS  # dev: Transfers to ZERO_ADDRESS not permitted

    self.getApproved[_tokenId] = ZERO_ADDRESS
    self.balanceOf[_from] -= 1
    self.balanceOf[_to] += 1
    self.ownerOf[_tokenId] = _to

    log Transfer(_from, _to, _tokenId)


<<<<<<< HEAD
=======
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
        0x0000000000000000000000000000000000000000000000000000000001ffc9a7,  # ERC-165
        0x000000000000000000000000000000000000000000000000000000007f5828d0,  # ERC-173
        0x0000000000000000000000000000000000000000000000000000000080ac58cd,  # ERC-721
    ]


>>>>>>> 36a3fe5 (fix: interfaceID capitalization)
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


@payable
@external
def transferFrom(_from: address, _to: address, _tokenId: uint256):
    """
    @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
        TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
        THEY MAY BE PERMANENTLY LOST
    @dev Throws unless `msg.sender` is the current owner, an authorized
        operator, or the approved address for this NFT. Throws if `_from` is
        not the current owner. Throws if `_to` is the zero address. Throws if
        `_tokenId` is not a valid NFT.
    @param _from The current owner of the NFT
    @param _to The new owner
    @param _tokenId The NFT to transfer
    """
    token_owner: address = self.ownerOf[_tokenId]
    assert (
        msg.sender == token_owner
        or self.isApprovedForAll[token_owner][msg.sender]
        or self.getApproved[_tokenId] == msg.sender
    )  # dev: Caller is neither owner nor operator nor approved

    self._transferFrom(_from, _to, _tokenId)


@payable
@external
def safeTransferFrom(
    _from: address, _to: address, _tokenId: uint256, _data: Bytes[1024] = b""
):
    """
    @notice Transfers the ownership of an NFT from one address to another address
    @dev Throws unless `msg.sender` is the current owner, an authorized
        operator, or the approved address for this NFT. Throws if `_from` is
        not the current owner. Throws if `_to` is the zero address. Throws if
        `_tokenId` is not a valid NFT. When transfer is complete, this function
        checks if `_to` is a smart contract (code size > 0). If so, it calls
        `onERC721Received` on `_to` and throws if the return value is not
        `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
    @param _from The current owner of the NFT
    @param _to The new owner
    @param _tokenId The NFT to transfer
    @param _data Additional data with no specified format, sent in call to `_to`
    """
    token_owner: address = self.ownerOf[_tokenId]
    assert (
        msg.sender == token_owner
        or self.isApprovedForAll[token_owner][msg.sender]
        or self.getApproved[_tokenId] == msg.sender
    )  # dev: Caller is neither owner nor operator nor approved

    self._transferFrom(_from, _to, _tokenId)

    if _to.is_contract:
        return_value: Bytes[8] = ERC721TokenReceiver(_to).onERC721Received(
            msg.sender, _from, _tokenId, _data
        )  # dev: bad response
        assert (
            return_value == TOKEN_RECEIVED
        )  # dev: Invalid ERC721TokenReceiver response


@internal
def _receive_child(
    _from: address,
    _token_id: uint256,
    _child_contract: address,
    _child_token_id: uint256,
):
    """
    @dev Internal functionality for receiving a token
    @param _from The address which previously owned the token
    @param _token_id The receiving token identifier
    @param _child_contract The contract address of the child token being received
    @param _child_token_id The token identifier of the token being received
    """
    assert self.ownerOf[_token_id] != ZERO_ADDRESS  # dev: Recipient token non-existent
    assert not self.child_token_data[_child_contract][
        _child_token_id
    ].is_held  # dev: Child token already possessed

    self.child_token_data[_child_contract][_child_token_id].is_held = True
    self.child_token_data[_child_contract][_child_token_id].parent_token_address = self
    self.child_token_data[_child_contract][_child_token_id].parent_token_id = _token_id

    log ReceivedChild(_from, _token_id, _child_contract, _child_token_id)


@external
def onERC721Received(
    _operator: address, _from: address, _childTokenId: uint256, _data: Bytes[32]
) -> Bytes[4]:
    """
    @notice Handle the receipt of an NFT
    @dev The ERC721 smart contract calls this function after a `transfer`.
        This function MAY throw to revert and reject the transfer. Return
        of other than the magic value MUST result in the transaction being
        reverted. Note: the contract address is always the message sender.
    @param _operator The address which called the `safeTransferFrom` function
        of the calling contract.
    @param _from The address which previously owned the token
    @param _childTokenId The NFT identifier which is being transferred
    @param _data Up to the first 32 bytes contains an integer which is the receiving
        parent tokenId.
    @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
        unless throwing
    """
    assert len(_data) > 0  # dev: _data must contain the receiving tokenId
    assert (
        ERC721(msg.sender).ownerOf(_childTokenId) == self
    )  # dev: Token was not transferred to contract

    token_id: uint256 = convert(_data, uint256)
    self._receive_child(_from, token_id, msg.sender, _childTokenId)
    return TOKEN_RECEIVED


@external
def getChild(
    _from: address, _tokenId: uint256, _childContract: address, _childTokenId: uint256
):
    """
    @notice Get a child token from an ERC721 contract.
    @param _from The address that owns the child token.
    @param _tokenId The token that becomes the parent owner
    @param _childContract The ERC721 contract of the child token
    @param _childTokenId The tokenId of the child token
    """
    assert (
        ERC721(_childContract).getApproved(_childTokenId) == self
    )  # dev: Not approved to get token
    assert _from == msg.sender or ERC721(_childContract).isApprovedForAll(
        _from, msg.sender
    )  # dev: Caller is neither _childTokenId owner nor operator

    ERC721(_childContract).transferFrom(_from, self, _childTokenId)
    self._receive_child(_from, _tokenId, _childContract, _childTokenId)


@view
@internal
def _ownerOfChild(
    _childContract: address, _childTokenId: uint256
) -> (address, uint256):
    assert self.child_token_data[_childContract][
        _childTokenId
    ].is_held  # dev: Token is not held by self

    parent_token_address: address = self.child_token_data[_childContract][
        _childTokenId
    ].parent_token_address
    parent_token_id: uint256 = self.child_token_data[_childContract][
        _childTokenId
    ].parent_token_id
    return (parent_token_address, parent_token_id)


@view
@external
def ownerOfChild(_childContract: address, _childTokenId: uint256) -> (bytes32, uint256):
    """
    @notice Get the parent tokenId of a child token.
    @param _childContract The contract address of the child token.
    @param _childTokenId The tokenId of the child.
    @return The parent address of the parent token and ERC998 magic value
    @return The parent tokenId of _tokenId
    """
    parent_token_address: address = empty(address)
    parent_token_id: uint256 = empty(uint256)

    parent_token_address, parent_token_id = self._ownerOfChild(
        _childContract, _childTokenId
    )
    parent_token_address_num: uint256 = convert(parent_token_address, uint256)
    magic_value_num: uint256 = convert(ERC998_MAGIC_VALUE, uint256)
    parent_addr_and_magic_val: uint256 = bitwise_or(
        magic_value_num, parent_token_address_num
    )

    return (convert(parent_addr_and_magic_val, bytes32), parent_token_id)
