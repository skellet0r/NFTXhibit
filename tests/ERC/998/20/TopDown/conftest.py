import pytest


@pytest.fixture(scope="module")
def token(alice, ERC20):
    return alice.deploy(ERC20, "Test Token", "TST", 18)


@pytest.fixture(scope="module")
def token_223(alice, ERC223):
    return alice.deploy(ERC223, "Test Token 223", "TST223", 18)


@pytest.fixture(scope="module", autouse=True)
def setup(alice, token, token_223, xhibit):
    token._mint_for_testing(alice, 100 * 10 ** 18, {"from": alice})
    token_223._mint_for_testing(alice, 100 * 10 ** 18, {"from": alice})
    xhibit.mint(alice, {"from": alice})
