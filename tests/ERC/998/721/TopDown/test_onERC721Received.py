import brownie
import pytest


@pytest.fixture(scope="module", autouse=True)
def setup(alice, nft, xhibit):
    nft._mint_for_testing(alice, {"from": alice})
    xhibit.mint(alice, {"from": alice})


def test_successful_transfer_to_parent_token(alice, nft, xhibit, web3):
    tx = nft.safeTransferFrom(alice, xhibit, 0, 0, {"from": alice})

    assert "ReceivedChild" in tx.events
    assert tx.events["ReceivedChild"]["_from"] == alice
    assert tx.events["ReceivedChild"]["_toTokenId"] == 0
    assert tx.events["ReceivedChild"]["_childContract"] == nft
    assert tx.events["ReceivedChild"]["_childTokenId"] == 0


def test_unsuccessful_transfer_parent_token_not_given(alice, nft, xhibit, web3):

    with brownie.reverts("dev: _data must contain the receiving tokenId"):
        nft.safeTransferFrom(alice, xhibit, 0, b"", {"from": alice})


def test_unsuccessful_transfer_parent_token_non_existent(alice, nft, xhibit, web3):

    with brownie.reverts("dev: Recipient token non-existent"):
        nft.safeTransferFrom(alice, xhibit, 0, 1, {"from": alice})
