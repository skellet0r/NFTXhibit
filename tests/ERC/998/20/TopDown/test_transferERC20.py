import brownie
import pytest


@pytest.fixture(autouse=True)
def local_setup(alice, token, token_no_return, xhibit):
    token.approve(xhibit, 10 * 10 ** 18, {"from": alice})
    xhibit.getERC20(alice, 0, token, 10 ** 18, {"from": alice})

    token_no_return.transfer(xhibit, 10 * 10 ** 18, 0, {"from": alice})


def test_successful_transfer_reduces_balance_of_token(alice, token, xhibit):
    balance_prev = xhibit.balanceOfERC20(0, token)

    xhibit.transferERC20(0, alice, token, 10 ** 18, {"from": alice})

    assert xhibit.balanceOfERC20(0, token) == balance_prev - 10 ** 18


def test_successful_transfer_calls_contract(alice, token, xhibit):
    tx = xhibit.transferERC20(0, alice, token, 10 ** 18, {"from": alice})

    assert tx.subcalls[0]["to"] == token
    assert tx.subcalls[0]["function"] == "transfer(address,uint256)"


def test_successful_transfer_emits_transfer_event(alice, token, xhibit):
    tx = xhibit.transferERC20(0, alice, token, 10 ** 18, {"from": alice})

    assert "TransferERC20" in tx.events
    assert tx.events["TransferERC20"]["_fromTokenId"] == 0
    assert tx.events["TransferERC20"]["_to"] == alice
    assert tx.events["TransferERC20"]["_erc20Contract"] == token
    assert tx.events["TransferERC20"]["_value"] == 10 ** 18


def test_unsuccessful_transfer_to_is_zero_address(alice, token, xhibit, zero_address):
    with brownie.reverts("dev: Transfers to ZERO_ADDRESS not permitted"):
        xhibit.transferERC20(0, zero_address, token, 10 ** 18, {"from": alice})


def test_unsuccessful_transfer_caller_not_owner(bob, token, xhibit):
    with brownie.reverts("dev: Caller is neither owner nor operator nor approved"):
        xhibit.transferERC20(0, bob, token, 10 ** 18, {"from": bob})


def test_unsuccessful_transfer_no_return_value(alice, token_no_return, xhibit):
    with brownie.reverts("dev: bad response"):
        tx = xhibit.transferERC20(0, alice, token_no_return, 10 ** 18, {"from": alice})

        assert tx.subcalls[0]["return_value"] is None


def test_unsuccessful_transfer_insufficient_balance(alice, token_no_return, xhibit):
    with brownie.reverts("dev: Token balance not sufficient for transfer"):
        xhibit.transferERC20(
            0, alice, token_no_return, 10000 * 10 ** 18, {"from": alice}
        )
