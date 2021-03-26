def test_balance_is_correct(alice, token_223, xhibit):
    token_223.transfer(xhibit, 10 ** 18, 0, {"from": alice})

    assert xhibit.balanceOfERC20(0, token_223) == 10 ** 18
