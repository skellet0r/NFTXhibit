from brownie.test import given, strategy


@given(account=strategy("address"))
def test_balanceOf_queries_account_balances(account, xhibit):
    assert xhibit.balanceOf(account) == 0
