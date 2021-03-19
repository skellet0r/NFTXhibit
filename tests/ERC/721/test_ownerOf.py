from brownie.test import given, strategy


@given(token_id=strategy("uint256"))
def test_ownerOf_queries_token_owner(token_id, xhibit, zero_address):
    assert xhibit.ownerOf(token_id) == zero_address
