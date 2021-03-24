import brownie
import pytest


@pytest.fixture(scope="module", autouse=True)
def local_setup(alice, nft, xhibit):
    nft.safeTransferFrom(alice, xhibit, 0, 0, {"from": alice})


def test_correct_contract_is_returned(nft, xhibit):
    assert xhibit.childContractByIndex(0, 0) == nft


def test_reverts_if_length_greater_than_size(xhibit):
    with brownie.reverts("dev: Invalid index"):
        xhibit.childContractByIndex(0, 1)
