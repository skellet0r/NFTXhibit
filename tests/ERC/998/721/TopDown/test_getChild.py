import brownie


def test_getChild_success(alice, nft, xhibit):
    nft.approve(xhibit, 0, {"from": alice})
    tx = xhibit.getChild(alice, 0, nft, 0, {"from": alice})

    assert "ReceivedChild" in tx.events
    assert tx.events["ReceivedChild"]["_from"] == alice
    assert tx.events["ReceivedChild"]["_toTokenId"] == 0
    assert tx.events["ReceivedChild"]["_childContract"] == nft
    assert tx.events["ReceivedChild"]["_childTokenId"] == 0


def test_getChild_unsuccessful_not_approved(alice, nft, xhibit):
    with brownie.reverts("dev: Not approved to get token"):
        xhibit.getChild(alice, 0, nft, 0, {"from": alice})


def test_getChild_unsuccessful_invalid_caller(alice, bob, nft, xhibit):
    nft.approve(xhibit, 0, {"from": alice})

    with brownie.reverts("dev: Caller is neither _childTokenId owner nor operator"):
        xhibit.getChild(alice, 0, nft, 0, {"from": bob})


def test_unsuccessful_transfer_parent_token_non_existent(alice, nft, xhibit):
    nft.approve(xhibit, 0, {"from": alice})

    with brownie.reverts("dev: Recipient token non-existent"):
        xhibit.getChild(alice, 1, nft, 0, {"from": alice})


def test_unsuccessful_transfer_receiving_token_already_possessed(
    alice, nft_no_auth, xhibit
):
    nft_no_auth.approve(xhibit, 0, {"from": alice})
    xhibit.getChild(alice, 0, nft_no_auth, 0, {"from": alice})

    nft_no_auth.transferFrom(xhibit, alice, 0, {"from": alice})
    nft_no_auth.approve(xhibit, 0, {"from": alice})

    with brownie.reverts("dev: Child token already possessed"):
        xhibit.getChild(alice, 0, nft_no_auth, 0, {"from": alice})
