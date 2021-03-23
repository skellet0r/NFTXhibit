import brownie
import pytest


@pytest.fixture(scope="module", autouse=True)
def local_setup(alice, nft, xhibit):
    nft.safeTransferFrom(alice, xhibit, 0, 0, {"from": alice})


def test_transfers_ownership_of_a_token(alice, bob, nft, xhibit):
    previous_owner = nft.ownerOf(0)
    xhibit.safeTransferChild(0, bob, nft, 0, {"from": alice})

    assert previous_owner == xhibit
    assert nft.ownerOf(0) == bob


def test_emits_TransferChild_event(alice, bob, nft, xhibit):
    tx = xhibit.safeTransferChild(0, bob, nft, 0, {"from": alice})

    assert "TransferChild" in tx.events
    assert tx.events["TransferChild"]["_fromTokenId"] == 0
    assert tx.events["TransferChild"]["_to"] == bob
    assert tx.events["TransferChild"]["_childContract"] == nft
    assert tx.events["TransferChild"]["_childTokenId"] == 0


def test_subcalls_child_contract(alice, bob, nft, xhibit):
    tx = xhibit.safeTransferChild(0, bob, nft, 0, {"from": alice})

    assert tx.subcalls[0]["to"] == nft
    assert (
        tx.subcalls[0]["function"] == "safeTransferFrom(address,address,uint256,bytes)"
    )
    assert tx.subcalls[0]["inputs"] == dict(
        _from=xhibit, _to=bob, _tokenId=0, _data="0x"
    )


def test_subcalls_child_contract_with_bytes(alice, bob, nft, xhibit):
    tx = xhibit.safeTransferChild(0, bob, nft, 0, b"", {"from": alice})

    assert tx.subcalls[0]["to"] == nft
    assert (
        tx.subcalls[0]["function"] == "safeTransferFrom(address,address,uint256,bytes)"
    )
    assert tx.subcalls[0]["inputs"] == dict(
        _from=xhibit, _to=bob, _tokenId=0, _data="0x"
    )


def test_reverts_if_sender_is_not_root_owner_operator_or_approved(bob, nft, xhibit):
    with brownie.reverts("dev: Caller is neither owner nor operator nor approved"):
        xhibit.safeTransferChild(0, bob, nft, 0, {"from": bob})


def test_reverts_if_to_is_zero_address(alice, nft, xhibit, zero_address):
    with brownie.reverts("dev: Transfers to ZERO_ADDRESS not permitted"):
        xhibit.safeTransferChild(0, zero_address, nft, 0, {"from": alice})


def test_reverts_if_parent_token_id_is_incorrect(alice, bob, nft, xhibit):
    with brownie.reverts("dev: Incorrect parent token ID"):
        xhibit.safeTransferChild(1, bob, nft, 0, {"from": alice})


def test_removes_approval_if_caller_is_approved(alice, bob, nft, xhibit, zero_address):
    xhibit.approve(bob, 0, {"from": alice})
    xhibit.safeTransferChild(0, bob, nft, 0, {"from": bob})

    assert xhibit.getApproved(0) == zero_address
