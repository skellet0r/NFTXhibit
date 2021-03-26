import brownie


def test_successful_transfer_to_parent_token_emits_event(alice, token, xhibit):
    token.approve(xhibit, 10 ** 18, {"from": alice})
    tx = xhibit.getERC20(alice, 0, token, 10 ** 18, {"from": alice})

    assert "ReceivedERC20" in tx.events
    assert tx.events["ReceivedERC20"]["_from"] == alice
    assert tx.events["ReceivedERC20"]["_toTokenId"] == 0
    assert tx.events["ReceivedERC20"]["_erc20Contract"] == token
    assert tx.events["ReceivedERC20"]["_value"] == 10 ** 18


def test_successful_transfer_to_parent_token_calls_erc20_transferFrom(
    alice, token, xhibit
):
    token.approve(xhibit, 10 ** 18, {"from": alice})
    tx = xhibit.getERC20(alice, 0, token, 10 ** 18, {"from": alice})

    assert tx.subcalls[0]["to"] == token
    assert tx.subcalls[0]["function"] == "allowance(address,address)"
    assert tx.subcalls[1]["to"] == token
    assert tx.subcalls[1]["function"] == "transferFrom(address,address,uint256)"


def test_unsuccessful_transfer_caller_is_not_account_owner(alice, bob, token, xhibit):
    token.approve(xhibit, 10 ** 18, {"from": alice})
    with brownie.reverts("dev: Caller is not account owner"):
        xhibit.getERC20(alice, 0, token, 10 ** 18, {"from": bob})


def test_unsuccessful_transfer_contract_allowance_not_enough(alice, token, xhibit):
    with brownie.reverts("dev: Contract was not given enough approval"):
        xhibit.getERC20(alice, 0, token, 10 ** 18, {"from": alice})


def test_unsuccessful_transfer_parent_token_non_existent(alice, token, xhibit):
    token.approve(xhibit, 10 ** 18, {"from": alice})
    with brownie.reverts("dev: Recipient token non-existent"):
        xhibit.getERC20(alice, 1, token, 10 ** 18, {"from": alice})
