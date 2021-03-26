import brownie
import pytest


@pytest.fixture(autouse=True)
def local_setup(alice, token_223, token_no_return, xhibit):
    token_223.transfer(xhibit, 10 * 10 ** 18, 0, {"from": alice})

    token_no_return.transfer(xhibit, 10 * 10 ** 18, 0, {"from": alice})


def test_successful_transfer_reduces_balance_of_token(alice, token_223, xhibit):
    balance_prev = xhibit.balanceOfERC20(0, token_223)

    xhibit.transferERC223(0, alice, token_223, 10 ** 18, b"", {"from": alice})

    assert xhibit.balanceOfERC20(0, token_223) == balance_prev - 10 ** 18


def test_successful_transfer_calls_contract(alice, token_223, xhibit):
    tx = xhibit.transferERC223(0, alice, token_223, 10 ** 18, b"", {"from": alice})

    assert tx.subcalls[0]["to"] == token_223
    assert tx.subcalls[0]["function"] == "transfer(address,uint256,bytes)"


def test_successful_transfer_emits_transfer_event(alice, token_223, xhibit):
    tx = xhibit.transferERC223(0, alice, token_223, 10 ** 18, b"", {"from": alice})

    assert "TransferERC20" in tx.events
    assert tx.events["TransferERC20"]["_fromTokenId"] == 0
    assert tx.events["TransferERC20"]["_to"] == alice
    assert tx.events["TransferERC20"]["_erc20Contract"] == token_223
    assert tx.events["TransferERC20"]["_value"] == 10 ** 18


def test_unsuccessful_transfer_to_is_zero_address(
    alice, token_223, xhibit, zero_address
):
    with brownie.reverts("dev: Transfers to ZERO_ADDRESS not permitted"):
        xhibit.transferERC223(
            0, zero_address, token_223, 10 ** 18, b"", {"from": alice}
        )


def test_unsuccessful_transfer_caller_not_owner(bob, token_223, xhibit):
    with brownie.reverts("dev: Caller is neither owner nor operator nor approved"):
        xhibit.transferERC223(0, bob, token_223, 10 ** 18, b"", {"from": bob})


def test_unsuccessful_transfer_no_return_value(alice, token_no_return, xhibit):
    with brownie.reverts("dev: bad response"):
        tx = xhibit.transferERC223(
            0, alice, token_no_return, 10 ** 18, b"", {"from": alice}
        )

        assert tx.subcalls[0]["return_value"] is None


def test_unsuccessful_transfer_insufficient_balance(alice, token_no_return, xhibit):
    with brownie.reverts("dev: Token balance not sufficient for transfer"):
        xhibit.transferERC223(
            0, alice, token_no_return, 10000 * 10 ** 18, b"", {"from": alice}
        )
