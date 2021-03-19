import brownie
from brownie.test import given, strategy


@given(
    approved=strategy("address"), owner=strategy("address"),
)
def test_approve_emits_approval_event(alice, approved, owner, xhibit):
    xhibit.mint(owner, {"from": alice})
    tx = xhibit.approve(approved, 0, {"from": owner})

    assert "Approval" in tx.events
    assert tx.events["Approval"]["_owner"] == owner
    assert tx.events["Approval"]["_approved"] == approved
    assert tx.events["Approval"]["_tokenId"] == 0


@given(
    approved=strategy("address"),
    operator=strategy("address"),
    owner=strategy("address"),
)
def test_approve_can_be_called_by_account_operator(
    alice, approved, operator, owner, xhibit
):
    xhibit.mint(owner, {"from": alice})
    xhibit.setApprovalForAll(operator, True, {"from": owner})
    tx = xhibit.approve(approved, 0, {"from": operator})

    assert "Approval" in tx.events
    assert tx.events["Approval"]["_owner"] == owner
    assert tx.events["Approval"]["_approved"] == approved
    assert tx.events["Approval"]["_tokenId"] == 0


@given(
    approved=strategy("address"), owner=strategy("address"),
)
def test_remove_approval_by_setting_approved_to_zero_address(
    alice, approved, owner, xhibit, zero_address
):
    xhibit.mint(owner, {"from": alice})
    xhibit.approve(approved, 0, {"from": owner})
    tx = xhibit.approve(zero_address, 0, {"from": owner})

    assert "Approval" in tx.events
    assert tx.events["Approval"]["_owner"] == owner
    assert tx.events["Approval"]["_approved"] == zero_address
    assert tx.events["Approval"]["_tokenId"] == 0


@given(
    approved=strategy("address"),
    caller=strategy("address"),
    token_id=strategy("uint256"),
)
def test_approve_reverts_if_caller_isnt_token_owner(approved, caller, token_id, xhibit):
    with brownie.reverts("dev: Caller is neither owner nor operator"):
        xhibit.approve(approved, token_id, {"from": caller})


@given(
    approved=strategy("address"),
    owner=strategy("address"),
    value=strategy("uint256", max_value=100 * 10 ** 18),
)
def test_approve_is_payable(alice, approved, owner, value, xhibit):
    xhibit.mint(owner, {"from": alice})
    xhibit.approve(approved, 0, {"from": owner, "value": value})

    assert xhibit.balance() == value
