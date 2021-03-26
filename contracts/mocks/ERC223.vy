# @version 0.2.11
"""
@notice Mock ERC223 for testing
@dev ERC223 has basically been superseded by ERC777 and or ERC1363
"""


interface ERC223Receiver:
    def tokenFallback(_from: address, _value: uint256, _data: Bytes[32]): nonpayable


event Transfer:
    _from: indexed(address)
    _to: indexed(address)
    _value: uint256

event Approval:
    _owner: indexed(address)
    _spender: indexed(address)
    _value: uint256


name: public(String[64])
symbol: public(String[32])
decimals: public(uint256)

balanceOf: public(HashMap[address, uint256])
allowance: public(HashMap[address, HashMap[address, uint256]])
totalSupply: public(uint256)


@external
def __init__(_name: String[64], _symbol: String[32], _decimals: uint256):
    self.name = _name
    self.symbol = _symbol
    self.decimals = _decimals


@external
def transfer(_to : address, _value : uint256, _data: Bytes[32] = b"") -> bool:
    self.balanceOf[msg.sender] -= _value
    self.balanceOf[_to] += _value
    if _to.is_contract:
        ERC223Receiver(_to).tokenFallback(msg.sender, _value, _data)
    log Transfer(msg.sender, _to, _value)
    return True


@external
def transferFrom(_from : address, _to : address, _value : uint256) -> bool:
    self.balanceOf[_from] -= _value
    self.balanceOf[_to] += _value
    self.allowance[_from][msg.sender] -= _value
    log Transfer(_from, _to, _value)
    return True


@external
def approve(_spender : address, _value : uint256) -> bool:
    self.allowance[msg.sender][_spender] = _value
    log Approval(msg.sender, _spender, _value)
    return True


@external
def _mint_for_testing(_target: address, _value: uint256) -> bool:
    self.totalSupply += _value
    self.balanceOf[_target] += _value
    log Transfer(ZERO_ADDRESS, _target, _value)

    return True
