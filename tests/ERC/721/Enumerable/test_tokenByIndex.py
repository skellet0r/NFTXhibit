import brownie


def test_returns_token_at_index(alice, xhibit):
    xhibit.mint(alice, {"from": alice})

    assert xhibit.tokenByIndex(0) == 0


def test_reverts_if_arg_is_greater_or_equal_to_total_supply(alice, xhibit):
    with brownie.reverts("dev: Invalid index"):
        xhibit.tokenByIndex(0)
