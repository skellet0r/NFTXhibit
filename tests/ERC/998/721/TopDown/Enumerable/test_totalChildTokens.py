import pytest


@pytest.fixture(scope="module", autouse=True)
def local_setup(alice, nft, xhibit):
    nft.safeTransferFrom(alice, xhibit, 0, 0, {"from": alice})


def test_length_is_correct(nft, xhibit):
    assert xhibit.totalChildTokens(0, nft) == 1
