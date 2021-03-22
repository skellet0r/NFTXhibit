import pytest


@pytest.fixture(scope="module", autouse=True)
def setup(alice, nft, xhibit):
    nft._mint_for_testing(alice, {"from": alice})
    xhibit.mint(alice, {"from": alice})


@pytest.fixture(scope="module")
def composable_top_down(alice, ComposableTopDown):
    return alice.deploy(ComposableTopDown)
