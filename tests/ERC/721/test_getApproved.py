from brownie.test import given, strategy


@given(token_id=strategy("uint256"))
def test_getApproved_queries_a_tokens_approved_address(token_id, xhibit, zero_address):
    assert xhibit.getApproved(token_id) == zero_address
