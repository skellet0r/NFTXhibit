def test_correct_contracts_amount_is_returned(alice, token, xhibit):
    token.approve(xhibit, 10 * 10 ** 18, {"from": alice})
    xhibit.getERC20(alice, 0, token, 10 ** 18, {"from": alice})

    assert xhibit.totalERC20Contracts(0) == 1
