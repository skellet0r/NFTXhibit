import brownie
import pytest


@pytest.fixture(scope="module", autouse=True)
def local_setup(alice, composable_bottom_down, xhibit):
    composable_bottom_down.safeTransferFrom(alice, xhibit, 0, 0, {"from": alice})


def test_emits_TransferChild_event(alice, composable_bottom_down, nft, xhibit):
    tx = xhibit.transferChildToParent(
        0, nft, 0, composable_bottom_down, 0, b"", {"from": alice}
    )

    assert "TransferChild" in tx.events
    assert tx.events["TransferChild"]["_fromTokenId"] == 0
    assert tx.events["TransferChild"]["_to"] == nft
    assert tx.events["TransferChild"]["_childContract"] == composable_bottom_down
    assert tx.events["TransferChild"]["_childTokenId"] == 0


def test_subcalls_child_contract(alice, composable_bottom_down, nft, xhibit):
    tx = xhibit.transferChildToParent(
        0, nft, 0, composable_bottom_down, 0, b"", {"from": alice}
    )
    expected_inputs = dict(
        _from=xhibit, _toContract=nft, _toTokenId=0, _tokenId=0, _data="0x"
    )

    assert tx.subcalls[0]["to"] == composable_bottom_down
    assert (
        tx.subcalls[0]["function"]
        == "transferToParent(address,address,uint256,uint256,bytes)"
    )
    assert tx.subcalls[0]["inputs"] == expected_inputs


def test_reverts_if_sender_is_not_root_owner_operator_or_approved(
    bob, composable_bottom_down, nft, xhibit
):
    with brownie.reverts("dev: Caller is neither owner nor operator nor approved"):
        xhibit.transferChildToParent(
            0, nft, 0, composable_bottom_down, 0, b"", {"from": bob}
        )


def test_reverts_if_to_is_zero_address(
    alice, composable_bottom_down, xhibit, zero_address
):
    with brownie.reverts("dev: Transfers to ZERO_ADDRESS not permitted"):
        xhibit.transferChildToParent(
            0, zero_address, 0, composable_bottom_down, 0, b"", {"from": alice}
        )


def test_reverts_if_parent_token_id_is_incorrect(
    alice, composable_bottom_down, nft, xhibit
):
    with brownie.reverts("dev: Incorrect parent token ID"):
        xhibit.transferChildToParent(
            1, nft, 0, composable_bottom_down, 0, b"", {"from": alice}
        )


def test_removes_approval_if_caller_is_approved(
    alice, bob, composable_bottom_down, nft, xhibit, zero_address
):
    xhibit.approve(bob, 0, {"from": alice})
    xhibit.transferChildToParent(
        0, nft, 0, composable_bottom_down, 0, b"", {"from": bob}
    )

    assert xhibit.getApproved(0) == zero_address
