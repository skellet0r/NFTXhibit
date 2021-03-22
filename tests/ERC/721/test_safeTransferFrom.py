import brownie


def test_safeTransferFrom_transfers_ownership_of_a_token(alice, bob, xhibit):
    xhibit.mint(alice, {"from": alice})
    xhibit.safeTransferFrom(alice, bob, 0, {"from": alice})

    assert xhibit.ownerOf(0) == bob


def test_safeTransferFrom_adjusts_balances_of_sender_and_recipient(alice, bob, xhibit):
    xhibit.mint(alice, {"from": alice})
    xhibit.safeTransferFrom(alice, bob, 0, {"from": alice})

    assert xhibit.balanceOf(alice) == 0
    assert xhibit.balanceOf(bob) == 1


def test_safeTransferFrom_emits_Transfer_event(alice, bob, xhibit):
    xhibit.mint(alice, {"from": alice})
    tx = xhibit.safeTransferFrom(alice, bob, 0, {"from": alice})

    assert "Transfer" in tx.events
    assert tx.events["Transfer"]["_from"] == alice
    assert tx.events["Transfer"]["_to"] == bob
    assert tx.events["Transfer"]["_tokenId"] == 0


def test_safeTransferFrom_removes_token_approval(alice, bob, xhibit, zero_address):
    xhibit.mint(alice, {"from": alice})
    xhibit.approve(bob, 0, {"from": alice})
    xhibit.safeTransferFrom(alice, bob, 0, {"from": alice})

    assert xhibit.getApproved(0) == zero_address


def test_safeTransferFrom_reverts_if_sender_is_not_owner_operator_or_approved(
    alice, bob, xhibit
):
    with brownie.reverts("dev: Caller is neither owner nor operator nor approved"):
        xhibit.safeTransferFrom(alice, bob, 0, {"from": alice})


def test_safeTransferFrom_reverts_if_to_is_zero_address(alice, xhibit, zero_address):
    xhibit.mint(alice, {"from": alice})

    with brownie.reverts("dev: Transfers to ZERO_ADDRESS not permitted"):
        xhibit.safeTransferFrom(alice, zero_address, 0, {"from": alice})


def test_safeTransferFrom_is_payable(alice, bob, xhibit):
    xhibit.mint(alice, {"from": alice})
    xhibit.safeTransferFrom(alice, bob, 0, {"from": alice, "value": 10 ** 18})

    assert xhibit.balance() == 10 ** 18


def test_safeTransferFrom_transfers_ownership_to_contract(
    alice, xhibit, ERC721TokenReceiver
):
    instance = alice.deploy(ERC721TokenReceiver, True)
    xhibit.mint(alice, {"from": alice})
    tx = xhibit.safeTransferFrom(alice, instance.address, 0, b"", {"from": alice})

    assert "Transfer" in tx.events


def test_safeTransferFrom_transfers_ownership_to_contract_no_data(
    alice, xhibit, ERC721TokenReceiver
):
    instance = alice.deploy(ERC721TokenReceiver, True)
    xhibit.mint(alice, {"from": alice})
    tx = xhibit.safeTransferFrom(alice, instance.address, 0, {"from": alice})

    assert "Transfer" in tx.events


def test_safeTransferFrom_reverts_when_transferring_to_non_receiver_contract(
    alice, xhibit, ERC721TokenReceiver
):
    instance = alice.deploy(ERC721TokenReceiver, False)
    xhibit.mint(alice, {"from": alice})

    with brownie.reverts("dev: Can not transfer to non-ERC721Receiver"):
        xhibit.safeTransferFrom(alice, instance.address, 0, b"", {"from": alice})
