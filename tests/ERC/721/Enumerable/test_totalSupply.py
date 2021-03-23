from brownie.test import given, strategy


@given(to=strategy("address"), total=strategy("uint256", max_value=25))
def test_total_supply_is_correct(alice, total, to, xhibit):
    for _ in range(total):
        xhibit.mint(to, {"from": alice})

    assert xhibit.totalSupply() == total
