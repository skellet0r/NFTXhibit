import brownie
from brownie.test import given, strategy


@given(to=strategy("address"))
def test_mint_increases_the_balance_of_to(alice, to, xhibit):
    xhibit.mint(to, {"from": alice})

    assert xhibit.balanceOf(to) == 1


@given(to=strategy("address"))
def test_mint_emits_transfer_event(alice, to, xhibit, zero_address):
    tx = xhibit.mint(to, {"from": alice})

    assert "Transfer" in tx.events
    assert tx.events["Transfer"]["_from"] == zero_address
    assert tx.events["Transfer"]["_to"] == to


@given(caller=strategy("address"), to=strategy("address"))
def test_mint_reverts_when_caller_is_not_owner(alice, caller, to, xhibit):
    if caller != alice:
        with brownie.reverts("dev: Caller is not owner"):
            xhibit.mint(to, {"from": caller})


def test_mint_reverts_when_to_is_zero_address(alice, xhibit, zero_address):
    with brownie.reverts("dev: Minting to zero address disallowed"):
        xhibit.mint(zero_address, {"from": alice})
