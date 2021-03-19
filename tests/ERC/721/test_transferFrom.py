import brownie


def test_transferFrom_transfers_ownership_of_a_token(alice, bob, xhibit):
    xhibit.mint(alice, {"from": alice})
    xhibit.transferFrom(alice, bob, 0, {"from": alice})

    assert xhibit.ownerOf(0) == bob


def test_transferFrom_adjusts_balances_of_sender_and_recipient(alice, bob, xhibit):
    xhibit.mint(alice, {"from": alice})
    xhibit.transferFrom(alice, bob, 0, {"from": alice})

    assert xhibit.balanceOf(alice) == 0
    assert xhibit.balanceOf(bob) == 1


def test_transferFrom_emits_Transfer_event(alice, bob, xhibit):
    xhibit.mint(alice, {"from": alice})
    tx = xhibit.transferFrom(alice, bob, 0, {"from": alice})

    assert "Transfer" in tx.events
    assert tx.events["Transfer"]["_from"] == alice
    assert tx.events["Transfer"]["_to"] == bob
    assert tx.events["Transfer"]["_tokenId"] == 0


def test_transferFrom_removes_token_approval(alice, bob, xhibit, zero_address):
    xhibit.mint(alice, {"from": alice})
    xhibit.approve(bob, 0, {"from": alice})
    xhibit.transferFrom(alice, bob, 0, {"from": alice})

    assert xhibit.getApproved(0) == zero_address


def test_transferFrom_reverts_if_sender_is_not_owner_operator_or_approved(
    alice, bob, xhibit
):
    with brownie.reverts("dev: Caller is neither owner nor operator nor approved"):
        xhibit.transferFrom(alice, bob, 0, {"from": alice})


def test_transferFrom_reverts_if_to_is_zero_address(alice, xhibit, zero_address):
    xhibit.mint(alice, {"from": alice})

    with brownie.reverts("dev: Transfers to ZERO_ADDRESS not permitted"):
        xhibit.transferFrom(alice, zero_address, 0, {"from": alice})


def test_transferfrom_is_payable(alice, bob, xhibit):
    xhibit.mint(alice, {"from": alice})
    xhibit.transferFrom(alice, bob, 0, {"from": alice, "value": 10 ** 18})

    assert xhibit.balance() == 10 ** 18
