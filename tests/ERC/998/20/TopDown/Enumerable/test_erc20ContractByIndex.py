def test_correct_contract_is_returned(alice, token, xhibit):
    token.approve(xhibit, 10 * 10 ** 18, {"from": alice})
    xhibit.getERC20(alice, 0, token, 10 ** 18, {"from": alice})

    assert xhibit.erc20ContractByIndex(0, 0) == token
