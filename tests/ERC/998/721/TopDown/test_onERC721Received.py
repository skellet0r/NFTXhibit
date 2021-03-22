import brownie


def test_successful_transfer_to_parent_token_emits_event(alice, nft, xhibit):
    tx = nft.safeTransferFrom(alice, xhibit, 0, 0, {"from": alice})

    assert "ReceivedChild" in tx.events
    assert tx.events["ReceivedChild"]["_from"] == alice
    assert tx.events["ReceivedChild"]["_toTokenId"] == 0
    assert tx.events["ReceivedChild"]["_childContract"] == nft
    assert tx.events["ReceivedChild"]["_childTokenId"] == 0


def test_unsuccessful_transfer_parent_token_not_given(alice, nft, xhibit):

    with brownie.reverts("dev: bad response"):
        tx = nft.safeTransferFrom(alice, xhibit, 0, b"", {"from": alice})

        assert (
            tx.subcalls[0]["revert_msg"]
            == "dev: _data must contain the receiving tokenId"
        )


def test_unsuccessful_transfer_parent_token_non_existent(alice, nft, xhibit):

    with brownie.reverts("dev: bad response"):
        tx = nft.safeTransferFrom(alice, xhibit, 0, 1, {"from": alice})

        assert tx.subcalls[0]["revert_msg"] == "dev: Recipient token non-existent"


def test_unsuccessful_transfer_receiving_token_not_transferred(
    alice, nft_transfer_last, xhibit
):

    with brownie.reverts("dev: bad response"):
        tx = nft_transfer_last.safeTransferFrom(alice, xhibit, 0, 0, {"from": alice})

        assert (
            tx.subcalls[0]["revert_msg"] == "dev: Token was not transferred to contract"
        )
