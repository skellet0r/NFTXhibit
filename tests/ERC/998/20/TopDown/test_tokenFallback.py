import brownie


def test_successful_transfer_to_parent_token_emits_event(alice, token_223, xhibit):
    tx = token_223.transfer(xhibit, 10 ** 18, 0, {"from": alice})

    assert "ReceivedERC20" in tx.events
    assert tx.events["ReceivedERC20"]["_from"] == alice
    assert tx.events["ReceivedERC20"]["_toTokenId"] == 0
    assert tx.events["ReceivedERC20"]["_erc20Contract"] == token_223
    assert tx.events["ReceivedERC20"]["_value"] == 10 ** 18


def test_successful_transfer_to_parent_token_calls_tokenFallback(
    alice, token_223, xhibit
):
    tx = token_223.transfer(xhibit, 10 ** 18, 0, {"from": alice})

    assert tx.subcalls[0]["function"] == "tokenFallback(address,uint256,bytes)"


def test_unsuccessful_transfer_parent_token_not_given(alice, token_223, xhibit):

    with brownie.reverts("dev: bad response"):
        tx = token_223.transfer(xhibit, 10 ** 18, b"", {"from": alice})

        assert (
            tx.subcalls[0]["revert_msg"]
            == "dev: _data must contain the receiving tokenId"
        )


def test_unsuccessful_transfer_tokens_not_transferred(
    alice, token_223_transfer_last, xhibit
):

    with brownie.reverts("dev: bad response"):
        tx = token_223_transfer_last.transfer(xhibit, 10 ** 18, 0, {"from": alice})

        assert (
            tx.subcalls[0]["revert_msg"]
            == "dev: Tokens were not transferred to contract"
        )


def test_unsuccessful_transfer_parent_token_non_existent(alice, token_223, xhibit):

    with brownie.reverts("dev: bad response"):
        tx = token_223.transfer(xhibit, 10 ** 18, 1, {"from": alice})

        assert tx.subcalls[0]["revert_msg"] == "dev: Recipient token non-existent"
