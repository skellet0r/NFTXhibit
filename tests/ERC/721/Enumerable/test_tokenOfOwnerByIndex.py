import brownie


def test_correct_indices_after_mint(alice, xhibit):
    xhibit.mint(alice, {"from": alice})

    assert xhibit.tokenOfOwnerByIndex(alice, 0) == 0


def test_transferring_modifies_indexes(alice, bob, xhibit):
    xhibit.mint(alice, {"from": alice})
    xhibit.safeTransferFrom(alice, bob, 0, {"from": alice})

    assert xhibit.tokenOfOwnerByIndex(bob, 0) == 0
    with brownie.reverts("dev: Invalid index"):
        xhibit.tokenOfOwnerByIndex(alice, 0)


def test_reverts_when_index_greater_than_balance(alice, xhibit):
    with brownie.reverts("dev: Invalid index"):
        xhibit.tokenOfOwnerByIndex(alice, 0)
