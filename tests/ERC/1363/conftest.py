import pytest


@pytest.fixture(scope="module")
def token_1363(alice, ERC1363):
    return alice.deploy(ERC1363, "Test Token", "TST", 18)


@pytest.fixture(scope="module")
def token_1363_transfer_last(alice, ERC1363TransferLast):
    return alice.deploy(ERC1363TransferLast, "Test Token", "TST", 18)


@pytest.fixture(scope="module", autouse=True)
def setup(alice, token_1363, token_1363_transfer_last, xhibit):
    token_1363._mint_for_testing(alice, 100 * 10 ** 18, {"from": alice})
    token_1363_transfer_last._mint_for_testing(alice, 100 * 10 ** 18, {"from": alice})
    xhibit.mint(alice, {"from": alice})
