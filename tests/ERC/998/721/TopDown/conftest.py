import pytest


@pytest.fixture(scope="module")
def composable_top_down(alice, ComposableTopDown):
    return alice.deploy(ComposableTopDown)


@pytest.fixture(scope="module")
def nft_transfer_last(alice, ERC721TransferLast):
    return alice.deploy(ERC721TransferLast)


@pytest.fixture(scope="module")
def nft_no_auth(alice, ERC721NoAuth):
    return alice.deploy(ERC721NoAuth)


@pytest.fixture(scope="module", autouse=True)
def setup(alice, nft, nft_no_auth, nft_transfer_last, xhibit):
    nft_no_auth._mint_for_testing(alice, {"from": alice})
    nft_transfer_last._mint_for_testing(alice, {"from": alice})
    nft._mint_for_testing(alice, {"from": alice})
    xhibit.mint(alice, {"from": alice})
