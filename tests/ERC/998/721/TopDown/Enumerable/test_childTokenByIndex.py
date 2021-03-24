import brownie
import pytest


@pytest.fixture(scope="module", autouse=True)
def local_setup(alice, nft, xhibit):
    nft.safeTransferFrom(alice, xhibit, 0, 0, {"from": alice})


def test_correct_token_is_returned(nft, xhibit):
    assert xhibit.childTokenByIndex(0, nft, 0) == 0


def test_reverts_if_length_greater_than_size(nft, xhibit):
    with brownie.reverts("dev: Invalid index"):
        xhibit.childTokenByIndex(0, nft, 1)
