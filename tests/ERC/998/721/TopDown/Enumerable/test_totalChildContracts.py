import pytest


@pytest.fixture(scope="module", autouse=True)
def local_setup(alice, nft, xhibit):
    nft.safeTransferFrom(alice, xhibit, 0, 0, {"from": alice})


def test_length_is_correct(xhibit):
    assert xhibit.totalChildContracts(0) == 1
