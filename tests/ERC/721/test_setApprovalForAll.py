from brownie.test import given, strategy


@given(owner=strategy("address"), operator=strategy("address"))
def test_setApprovalForAll_emits_ApprovalForAll_event(owner, operator, xhibit):
    tx = xhibit.setApprovalForAll(operator, True, {"from": owner})

    assert "ApprovalForAll" in tx.events
    assert tx.events["ApprovalForAll"]["_owner"] == owner
    assert tx.events["ApprovalForAll"]["_operator"] == operator
    assert tx.events["ApprovalForAll"]["_approved"] is True


@given(owner=strategy("address"))
def test_setApprovalForAll_can_be_set_multiple_times(owner, accounts, xhibit):
    for operator in accounts:
        xhibit.setApprovalForAll(operator, True, {"from": owner})

    for operator in accounts:
        assert xhibit.isApprovedForAll(owner, operator) is True


@given(owner=strategy("address"), operator=strategy("address"))
def test_revoke_approval_for_all(owner, operator, xhibit):
    xhibit.setApprovalForAll(operator, True, {"from": owner})
    xhibit.setApprovalForAll(operator, False, {"from": owner})

    assert xhibit.isApprovedForAll(owner, operator) is False
