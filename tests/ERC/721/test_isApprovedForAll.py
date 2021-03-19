from brownie.test import given, strategy


@given(owner=strategy("address"), operator=strategy("address"))
def test_isApprovedForAll_returns_false_for_non_account_operator(
    owner, operator, xhibit
):
    assert xhibit.isApprovedForAll(owner, operator) is False
