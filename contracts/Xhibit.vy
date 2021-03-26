# @version 0.2.11
"""
@title A collection of NFT Exhibits
@license GPL-3.0
@author Edward Amor
@notice You can use this contract to manage owned NFT exhibits
@dev A staticcall proxy contract has to be deployed prior to this contract's
    deployment
"""
from vyper.interfaces import ERC20
from vyper.interfaces import ERC721


# Constants


TOKEN_RECEIVED: constant(Bytes[4]) = 0x150b7a02
ERC998_MAGIC_VALUE: constant(Bytes[4]) = 0xcd740db5


# Interfaces


interface CallProxy:
    def tryStaticCall(_target: address, _calldata: Bytes[96]) -> Bytes[32]: view

interface ERC721TokenReceiver:
    def onERC721Received(
        _operator: address, _from: address, _tokenId: uint256, _data: Bytes[1024]
    ) -> Bytes[4]: nonpayable

interface ERC998ERC721BottomUp:
    def transferToParent(
        _from: address,
        _toContract: address,
        _toTokenId: uint256,
        _tokenId: uint256,
        _data: Bytes[1024],
    ): nonpayable


# Structs


struct TokenData:
    child_contracts: address[MAX_UINT256]
    child_contracts_size: uint256

struct ChildContractData:
    child_tokens: uint256[MAX_UINT256]
    child_tokens_size: uint256
    position: uint256
    is_held: bool

struct ChildTokenData:
    parent_token_id: uint256
    is_held: bool
    position: uint256


# Events


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

event ReceivedERC20:
    _from: indexed(address)
    _toTokenId: indexed(uint256)
    _erc20Contract: indexed(address)
    _value: uint256

event Transfer:
    _from: indexed(address)
    _to: indexed(address)
    _tokenId: indexed(uint256)

event TransferChild:
    _fromTokenId: indexed(uint256)
    _to: indexed(address)
    _childContract: indexed(address)
    _childTokenId: uint256

event TransferERC20:
    _fromTokenId: indexed(uint256)
    _to: indexed(address)
    _erc20Contract: indexed(address)
    _value: uint256


# State Variables


# ERC-721 Enumerable Extension
totalSupply: public(uint256)
owner_to_tokens: HashMap[address, uint256[MAX_UINT256]]
owner_to_token_to_index: HashMap[address, HashMap[uint256, uint256]]

owner: public(address)  # ERC-173

# ERC-721
balanceOf: public(HashMap[address, uint256])
ownerOf: public(HashMap[uint256, address])
isApprovedForAll: public(HashMap[address, HashMap[address, bool]])
getApproved: public(HashMap[uint256, address])

call_proxy: address

# ERC-998 ERC-721 Top Down Composable Enumerable Extension
tokens: HashMap[uint256, TokenData]
# token id => child contract => child data
child_contracts: HashMap[uint256, HashMap[address, ChildContractData]]
# child token contract => child token id => child token data
child_token_data: HashMap[address, HashMap[uint256, ChildTokenData]]

# tracks globally this contract's token balance
# used when asserting a token was received
global_balances: HashMap[address, uint256]
token_balances: HashMap[uint256, HashMap[address, uint256]]


@external
def __init__(_call_proxy: address):
    self.call_proxy = _call_proxy
    self.owner = msg.sender


# Internal Helper Functions


@internal
def _mint(_to: address):
    """
    @dev Internal function for minting new tokens, reverts if
        `_to` is the zero address.
    @param _to Address which will receive the new token
    """
    assert _to != ZERO_ADDRESS  # dev: Minting to zero address disallowed

    token_id: uint256 = self.totalSupply
    index: uint256 = self.balanceOf[_to]

    self.owner_to_tokens[_to][index] = token_id
    self.owner_to_token_to_index[_to][token_id] = index

    self.balanceOf[_to] += 1
    self.ownerOf[token_id] = _to
    self.totalSupply += 1

    log Transfer(ZERO_ADDRESS, _to, token_id)


@view
@internal
def _owner_of_child(
    _childContract: address, _childTokenId: uint256
) -> (address, uint256):
    """
    @dev Internal function for retrieving the parent token of a
        child token. This will revert if the token is not possessed
        by this contract.
    @param _childContract The contract address of the child token
    @param _childTokenId The child token ID
    @return The parent address of the child token
    @return The parent token ID of the child token
    """
    assert self.child_token_data[_childContract][
        _childTokenId
    ].is_held  # dev: Token is not held by self

    parent_token_id: uint256 = self.child_token_data[_childContract][
        _childTokenId
    ].parent_token_id
    return (self.ownerOf[parent_token_id], parent_token_id)


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

    # if the child contract isn't registered, register it in _token_id
    if not self.child_contracts[_token_id][_child_contract].is_held:
        # add child contract to _token_id child contracts array
        length: uint256 = self.tokens[_token_id].child_contracts_size
        self.tokens[_token_id].child_contracts[length] = _child_contract
        self.tokens[_token_id].child_contracts_size += 1

        self.child_contracts[_token_id][_child_contract].position = length
        self.child_contracts[_token_id][_child_contract].is_held = True

    # register the token in the _token_id._child_contract data
    # add child token to _token_id._child_contract child tokens array
    length: uint256 = self.child_contracts[_token_id][_child_contract].child_tokens_size
    self.child_contracts[_token_id][_child_contract].child_tokens[
        length
    ] = _child_token_id
    self.child_contracts[_token_id][_child_contract].child_tokens_size += 1

    self.child_token_data[_child_contract][_child_token_id].position = length

    # register the child token data
    self.child_token_data[_child_contract][_child_token_id].is_held = True
    self.child_token_data[_child_contract][_child_token_id].parent_token_id = _token_id

    log ReceivedChild(_from, _token_id, _child_contract, _child_token_id)


@internal
def _receive_token(_from: address, _token_id: uint256, _contract: address, _value: uint256):
    """
    @dev Internal function for receiving ERC20 tokens
    """
    assert self.ownerOf[_token_id] != ZERO_ADDRESS  # dev: Recipient token non-existent

    if _value == 0:
        return

    self.global_balances[_contract] += _value
    self.token_balances[_token_id][_contract] += _value

    log ReceivedERC20(_from, _token_id, _contract, _value)


@internal
def _remove_child(
    _from_token_id: uint256, _childContract: address, _childTokenId: uint256,
):
    """
    @dev Internal function for emptying child token data
    """
    # position in the child contract array of tokens
    child_token_index: uint256 = self.child_token_data[_childContract][
        _childTokenId
    ].position

    # empty child token data
    self.child_token_data[_childContract][_childTokenId].parent_token_id = empty(
        uint256
    )
    self.child_token_data[_childContract][_childTokenId].is_held = False
    self.child_token_data[_childContract][_childTokenId].position = 0

    # reduce the size of the child contract array of tokens
    self.child_contracts[_from_token_id][_childContract].child_tokens_size -= 1

    # index of the last child token in the array which we will zero out
    last_child_token_index: uint256 = self.child_contracts[_from_token_id][
        _childContract
    ].child_tokens_size
    # if the pos of the token we are removing isn't last
    if child_token_index < last_child_token_index:
        # overwrite the position
        # this is the last token
        last_child_token: uint256 = self.child_contracts[_from_token_id][
            _childContract
        ].child_tokens[last_child_token_index]
        # we overwrite the child_token_index with the last token
        self.child_contracts[_from_token_id][_childContract].child_tokens[
            child_token_index
        ] = last_child_token
        # we set the last token's index in it's data struct
        self.child_token_data[_childContract][
            last_child_token
        ].position = child_token_index
    # lastly we zero out the last token position in the token array
    self.child_contracts[_from_token_id][_childContract].child_tokens[
        last_child_token_index
    ] = 0

    # handle removing a contract if all the tokens are gone
    if self.child_contracts[_from_token_id][_childContract].child_tokens_size == 0:
        # position of the contract in the array of contracts
        contract_index: uint256 = self.child_contracts[_from_token_id][
            _childContract
        ].position
        # empty the data
        self.child_contracts[_from_token_id][_childContract].is_held = False
        self.child_contracts[_from_token_id][_childContract].position = 0

        self.tokens[_from_token_id].child_contracts_size -= 1
        last_contract_index: uint256 = self.tokens[_from_token_id].child_contracts_size
        if contract_index < last_contract_index:
            last_contract: address = self.tokens[_from_token_id].child_contracts[
                last_contract_index
            ]
            self.tokens[_from_token_id].child_contracts[contract_index] = last_contract
            self.child_contracts[_from_token_id][
                last_contract
            ].position = contract_index
        self.tokens[_from_token_id].child_contracts[last_contract_index] = ZERO_ADDRESS


@view
@internal
def _root_owner_of_child(_childContract: address, _childTokenId: uint256) -> address:
    """
    @dev Internal function for retrieving the root owner of a child token. This is
        the account at the top of the tree of composables. There are a couple of cases
        a child token can be owned by (1) a parent token in this contract (and that
        parent token can also be owned by a parent token in this contract), (2) an
        external Top Down composables contract, (3) a contract which doesn't adhere
        to the Top Down composables interface, (4) an EOA.
        Passing ZERO_ADDRESS for `_childContract` will search for the root owner of
        a parent token in this contract.
    @param _childContract The contract address of the child token
    @param The child token ID
    @return The root owner address
    """
    root_owner_address: address = ZERO_ADDRESS
    parent_token_id: uint256 = 0

    if _childContract == ZERO_ADDRESS:
        root_owner_address = self.ownerOf[_childTokenId]
    else:
        root_owner_address, parent_token_id = self._owner_of_child(
            _childContract, _childTokenId
        )

    for i in range(MAX_UINT256):
        if root_owner_address != self:
            break
        root_owner_address, parent_token_id = self._owner_of_child(
            root_owner_address, parent_token_id
        )

    if root_owner_address.is_contract:
        fn_sig: Bytes[4] = method_id("rootOwnerOfChild(address,uint256)")
        fn_data: Bytes[64] = concat(
            convert(self, bytes32), convert(parent_token_id, bytes32)
        )
        result: Bytes[32] = CallProxy(self.call_proxy).tryStaticCall(
            root_owner_address, concat(fn_sig, fn_data)
        )

        if len(result) == 32:
            # TODO: Figure out why the following do not work
            # slice(result, 0, 4) == ERC998_MAGIC_VALUE
            # extract32(result, 12, output_type=address)
            magic_val: uint256 = convert(slice(result, 0, 4), uint256)
            addr_val: uint256 = convert(slice(result, 12, 20), uint256)

            if magic_val == convert(ERC998_MAGIC_VALUE, uint256):
                root_owner_address = convert(addr_val, address)

    return root_owner_address


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

    # next available index in _to tokens array
    last_index_to: uint256 = self.balanceOf[_to] - 1

    # local variables to decrease gas costs of accessing storage
    index: uint256 = self.owner_to_token_to_index[_from][_tokenId]
    last_index: uint256 = self.balanceOf[_from]

    # if the position of _tokenId in _from's token array is not
    # the last token, overwrite the position with the last token
    # in the array an change the last_token's position tracker
    if index < last_index:
        last_token: uint256 = self.owner_to_tokens[_from][last_index]
        self.owner_to_tokens[_from][index] = last_token
        self.owner_to_token_to_index[_from][last_token] = index

    # set the _tokenId data to 0 in _from
    self.owner_to_token_to_index[_from][_tokenId] = 0
    self.owner_to_tokens[_from][last_index] = 0

    # set the _tokenId data to appropriate values in _to
    self.owner_to_token_to_index[_to][_tokenId] = last_index_to
    self.owner_to_tokens[_to][last_index_to] = _tokenId

    log Transfer(_from, _to, _tokenId)


# ERC-173


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


# Utility


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


# ERC-721


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
    root_owner: address = self._root_owner_of_child(ZERO_ADDRESS, _tokenId)
    assert (
        msg.sender == root_owner or self.isApprovedForAll[root_owner][msg.sender]
    )  # dev: Caller is neither owner nor operator

    self.getApproved[_tokenId] = _approved

    log Approval(root_owner, _approved, _tokenId)


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
    root_owner: address = self._root_owner_of_child(ZERO_ADDRESS, _tokenId)
    assert (
        msg.sender == root_owner
        or self.isApprovedForAll[root_owner][msg.sender]
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
    root_owner: address = self._root_owner_of_child(ZERO_ADDRESS, _tokenId)
    assert (
        msg.sender == root_owner
        or self.isApprovedForAll[root_owner][msg.sender]
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


# ERC-721 Enumerable Extension


@view
@external
def tokenByIndex(_index: uint256) -> uint256:
    """
    @notice Enumerate valid NFTs
    @dev Throws if `_index` >= `totalSupply()`. Since token identifiers
        are generated incrementally from 0, this just returns the arg
        given.
    @param _index A value less than `totalSupply()`
    @return The token identifier for the `_index`th NFT,
        (sort order not specified)
    """
    assert _index < self.totalSupply  # dev: Invalid index

    return _index


@view
@external
def tokenOfOwnerByIndex(_owner: address, _index: uint256) -> uint256:
    """
    @notice Enumerate NFTs assigned to an owner
    @dev Throws if `_index` >= `balanceOf(_owner)` or if
        `_owner` is the zero address, representing invalid NFTs.
    @param _owner An address where we are interested in NFTs owned by them
    @param _index A counter less than `balanceOf(_owner)`
    @return The token identifier for the `_index`th NFT assigned to `_owner`,
        (sort order not specified)
    """
    assert _index < self.balanceOf[_owner]  # dev: Invalid index

    return self.owner_to_tokens[_owner][_index]


# ERC-998 ERC-721 Top Down Composable


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
    @dev Caller must be the owner of the token being sent or
        an approved operator
    @param _from The address that owns the child token.
    @param _tokenId The token that becomes the parent owner
    @param _childContract The ERC721 contract of the child token
    @param _childTokenId The tokenId of the child token
    """
    assert ERC721(_childContract).getApproved(_childTokenId) == self or ERC721(
        _childContract
    ).isApprovedForAll(
        _from, self
    )  # dev: Not approved to get token
    assert _from == msg.sender or ERC721(_childContract).isApprovedForAll(
        _from, msg.sender
    )  # dev: Caller is neither _childTokenId owner nor operator

    ERC721(_childContract).transferFrom(_from, self, _childTokenId)
    self._receive_child(_from, _tokenId, _childContract, _childTokenId)


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
    parent_address: address = ZERO_ADDRESS
    parent_token_id: uint256 = 0

    magic_val: bytes32 = convert(ERC998_MAGIC_VALUE, bytes32)
    parent_address, parent_token_id = self._owner_of_child(
        _childContract, _childTokenId
    )
    parent_addr_and_magic_val: uint256 = bitwise_or(
        convert(magic_val, uint256), convert(parent_address, uint256)
    )

    return (convert(parent_addr_and_magic_val, bytes32), parent_token_id)


@view
@external
def rootOwnerOfChild(_childContract: address, _childTokenId: uint256) -> bytes32:
    """
    @notice Get the root owner of a child token.
    @param _childContract The contract address of the child token.
    @param _childTokenId The tokenId of the child.
    @return The root owner at the top of tree of tokens and ERC998 magic value.
    """
    magic_val: bytes32 = convert(ERC998_MAGIC_VALUE, bytes32)
    root_owner_address: address = self._root_owner_of_child(
        _childContract, _childTokenId
    )
    return_value: uint256 = bitwise_or(
        convert(magic_val, uint256), convert(root_owner_address, uint256)
    )

    return convert(return_value, bytes32)


@view
@external
def rootOwnerOf(_tokenId: uint256) -> bytes32:
    """
    @notice Get the root owner of tokenId.
    @param _tokenId The token to query for a root owner address
    @return The root owner at the top of tree of tokens and ERC998 magic value.
    """
    magic_val: bytes32 = convert(ERC998_MAGIC_VALUE, bytes32)
    root_owner_address: address = self._root_owner_of_child(ZERO_ADDRESS, _tokenId)
    return_value: uint256 = bitwise_or(
        convert(magic_val, uint256), convert(root_owner_address, uint256)
    )

    return convert(return_value, bytes32)


@external
def transferChild(
    _fromTokenId: uint256, _to: address, _childContract: address, _childTokenId: uint256
):
    """
    @notice Transfer child token from top-down composable to address.
    @dev Reverts if caller is not root owner, operator, or approved.
        Calls the child contract's `tranferFrom` function.
    @param _fromTokenId The owning token to transfer from.
    @param _to The address that receives the child token
    @param _childContract The ERC721 contract of the child token.
    @param _childTokenId The tokenId of the token that is being transferred.
    """
    parent_addr: address = ZERO_ADDRESS
    parent_token_id: uint256 = 0
    parent_addr, parent_token_id = self._owner_of_child(_childContract, _childTokenId)

    root_owner: address = self._root_owner_of_child(_childContract, _childTokenId)

    assert (
        msg.sender == root_owner
        or self.isApprovedForAll[root_owner][msg.sender]
        or self.getApproved[parent_token_id] == msg.sender
    )  # dev: Caller is neither owner nor operator nor approved
    assert _fromTokenId == parent_token_id  # dev: Incorrect parent token ID
    assert _to != ZERO_ADDRESS  # dev: Transfers to ZERO_ADDRESS not permitted

    if msg.sender == self.getApproved[parent_token_id]:
        self.getApproved[parent_token_id] = ZERO_ADDRESS

    self._remove_child(parent_token_id, _childContract, _childTokenId)
    ERC721(_childContract).transferFrom(self, _to, _childTokenId)  # dev: bad response

    log TransferChild(_fromTokenId, _to, _childContract, _childTokenId)


@external
def safeTransferChild(
    _fromTokenId: uint256,
    _to: address,
    _childContract: address,
    _childTokenId: uint256,
    _data: Bytes[1024] = b"",
):
    """
    @notice Transfer child token from top-down composable to address.
    @dev Reverts if caller is not root owner, operator, or approved.
        Calls the child contract's `safeTranferFrom` function.
    @param _fromTokenId The owning token to transfer from.
    @param _to The address that receives the child token
    @param _childContract The ERC721 contract of the child token.
    @param _childTokenId The tokenId of the token that is being transferred.
    @param _data Additional data with no specified format
    """
    parent_addr: address = ZERO_ADDRESS
    parent_token_id: uint256 = 0
    parent_addr, parent_token_id = self._owner_of_child(_childContract, _childTokenId)

    root_owner: address = self._root_owner_of_child(_childContract, _childTokenId)

    assert (
        msg.sender == root_owner
        or self.isApprovedForAll[root_owner][msg.sender]
        or self.getApproved[parent_token_id] == msg.sender
    )  # dev: Caller is neither owner nor operator nor approved
    assert _fromTokenId == parent_token_id  # dev: Incorrect parent token ID
    assert _to != ZERO_ADDRESS  # dev: Transfers to ZERO_ADDRESS not permitted

    if msg.sender == self.getApproved[parent_token_id]:
        self.getApproved[parent_token_id] = ZERO_ADDRESS

    self._remove_child(parent_token_id, _childContract, _childTokenId)
    ERC721(_childContract).safeTransferFrom(
        self, _to, _childTokenId, _data
    )  # dev: bad response

    log TransferChild(_fromTokenId, _to, _childContract, _childTokenId)


@external
def transferChildToParent(
    _fromTokenId: uint256,
    _toContract: address,
    _toTokenId: uint256,
    _childContract: address,
    _childTokenId: uint256,
    _data: Bytes[1024],
):
    """
    @notice Transfer bottom-up composable child token from top-down composable
        to other ERC721 token.
    @dev Reverts if caller is not root owner, operator, or approved.
        Calls the child contract's `safeTranferFrom` function.
    @param _fromTokenId The owning token to transfer from.
    @param _toContract The ERC721 contract of the receiving token
    @param _toTokenId The receiving token
    @param _childContract The bottom-up composable contract of the child token.
    @param _childTokenId The token that is being transferred.
    @param _data Additional data with no specified format
    """
    parent_addr: address = ZERO_ADDRESS
    parent_token_id: uint256 = 0
    parent_addr, parent_token_id = self._owner_of_child(_childContract, _childTokenId)

    root_owner: address = self._root_owner_of_child(_childContract, _childTokenId)

    assert (
        msg.sender == root_owner
        or self.isApprovedForAll[root_owner][msg.sender]
        or self.getApproved[parent_token_id] == msg.sender
    )  # dev: Caller is neither owner nor operator nor approved
    assert _fromTokenId == parent_token_id  # dev: Incorrect parent token ID
    assert _toContract != ZERO_ADDRESS  # dev: Transfers to ZERO_ADDRESS not permitted

    if msg.sender == self.getApproved[parent_token_id]:
        self.getApproved[parent_token_id] = ZERO_ADDRESS

    self._remove_child(parent_token_id, _childContract, _childTokenId)
    ERC998ERC721BottomUp(_childContract).transferToParent(
        self, _toContract, _toTokenId, _childTokenId, _data
    )  # dev: bad response

    log TransferChild(_fromTokenId, _toContract, _childContract, _childTokenId)


# ERC-998 ERC-721 Top Down Composable Enumerable Extension


@view
@external
def totalChildContracts(_tokenId: uint256) -> uint256:
    """
    @notice Get the total number of child contracts with tokens that
        are owned by tokenId.
    @param _tokenId The parent token of child tokens in child contracts
    @return The total number of child contracts with tokens owned by tokenId.
    """
    return self.tokens[_tokenId].child_contracts_size


@view
@external
def childContractByIndex(_tokenId: uint256, _index: uint256) -> address:
    """
    @notice Get child contract by tokenId and index
    @param _tokenId The parent token of child tokens in child contract
    @param _index The index position of the child contract
    @return The contract found at the tokenId and index.
    """
    assert _index < self.tokens[_tokenId].child_contracts_size  # dev: Invalid index

    return self.tokens[_tokenId].child_contracts[_index]


@view
@external
def totalChildTokens(_tokenId: uint256, _childContract: address) -> uint256:
    """
    @notice Get the total number of child tokens owned by tokenId that exist in a
        child contract.
    @param _tokenId The parent token of child tokens
    @param _childContract The child contract containing the child tokens
    @return The total number of child tokens found in child contract that are
        owned by tokenId.
    """
    return self.child_contracts[_tokenId][_childContract].child_tokens_size


@view
@external
def childTokenByIndex(
    _tokenId: uint256, _childContract: address, _index: uint256
) -> uint256:
    """
    @notice Get child token owned by tokenId, in child contract, at index position
    @param _tokenId The parent token of the child token
    @param _childContract The child contract of the child token
    @param _index The index position of the child token.
    @return The child tokenId for the parent token, child token and index
    """
    assert (
        _index < self.child_contracts[_tokenId][_childContract].child_tokens_size
    )  # dev: Invalid index

    return self.child_contracts[_tokenId][_childContract].child_tokens[_index]


# ERC-998 ERC-20 Top Down Composable


@external
def tokenFallback(_from: address, _value: uint256, _data: Bytes[32]):
    """
    @notice A token receives ERC20 tokens
    @dev This is called by a
    @param _from The prior owner of the ERC20 tokens
    @param _value The number of ERC20 tokens received
    @param _data Up to the first 32 bytes contains an integer which is the receiving tokenId
    """
    assert len(_data) > 0  # dev: _data must contain the receiving tokenId
    assert (
        ERC20(msg.sender).balanceOf(self) == self.global_balances[msg.sender] + _value
    )  # dev: Tokens were not transferred to contract

    token_id: uint256 = convert(_data, uint256)
    self._receive_token(_from, token_id, msg.sender, _value)


@external
def getERC20(
    _from: address, _tokenId: uint256, _erc20Contract: address, _value: uint256
):
    """
    @notice Get ERC20 tokens from ERC20 contract.
    @dev Contract must be approved prior to calling this function
    @param _from The current owner address of the ERC20 tokens that are being transferred.
    @param _tokenId The token to transfer the ERC20 tokens to.
    @param _erc20Contract The ERC20 token contract
    @param _value The number of ERC20 tokens to transfer
    """
    assert _from == msg.sender  # dev: Caller is not account owner
    assert (
        ERC20(_erc20Contract).allowance(_from, self) >= _value
    )  # dev: Contract was not given enough approval

    ERC20(_erc20Contract).transferFrom(_from, self, _value)  # dev: bad response

    self._receive_token(_from, _tokenId, _erc20Contract, _value)
