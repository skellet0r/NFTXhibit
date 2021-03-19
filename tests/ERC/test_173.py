import brownie
from brownie.test import given, strategy


def test_owner_is_deployer(alice, xhibit):
    assert xhibit.owner() == alice


@given(new_owner=strategy("address"))
def test_transferOwnership_changes_contract_owner(alice, new_owner, xhibit):
    xhibit.transferOwnership(new_owner, {"from": alice})

    assert xhibit.owner() == new_owner


@given(new_owner=strategy("address"))
def test_transferOwnership_emits_event(alice, new_owner, xhibit):
    tx = xhibit.transferOwnership(new_owner, {"from": alice})

    assert "OwnershipTransferred" in tx.events
    assert tx.events["OwnershipTransferred"]["previousOwner"] == alice
    assert tx.events["OwnershipTransferred"]["newOwner"] == new_owner


@given(caller=strategy("address"), new_owner=strategy("address"))
def test_transferOwnership_can_only_be_called_by_owner(
    alice, caller, new_owner, xhibit
):
    if caller != alice:
        with brownie.reverts("dev: Caller is not owner"):
            xhibit.transferOwnership(new_owner, {"from": caller})
