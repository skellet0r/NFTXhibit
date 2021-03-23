ERC998_MAGIC_VALUE = (
    "0xcd740db500000000000000000000000000000000000000000000000000000000"
)
ETH_ADDR = "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE"


def test_root_owner_is_eoa(alice, xhibit, nft):
    nft.safeTransferFrom(alice, xhibit, 0, 0, {"from": alice})

    expected_root_owner = ERC998_MAGIC_VALUE[:-40] + alice.address[2:]
    root_owner = xhibit.rootOwnerOfChild(nft, 0)

    assert root_owner == expected_root_owner


def test_root_owner_is_contract(alice, nft_no_auth, xhibit):
    # mint an xhibit for nft_no_auth
    xhibit.mint(nft_no_auth, {"from": alice})
    # alice sends her token to nft_no_auth's xhibit token
    nft_no_auth.safeTransferFrom(alice, xhibit, 0, 1, {"from": alice})

    expected_root_owner = ERC998_MAGIC_VALUE[:-40] + nft_no_auth.address[2:]
    root_owner = xhibit.rootOwnerOfChild(nft_no_auth, 0)

    assert root_owner == expected_root_owner


def test_root_owner_is_top_down_composable(
    alice, composable_top_down, nft_no_auth, xhibit
):
    # mint an xhibit for the mock Top Down contract
    xhibit.mint(composable_top_down, {"from": alice})
    # alice sends her token to the composables's xhibit token
    nft_no_auth.safeTransferFrom(alice, xhibit, 0, 1, {"from": alice})

    # when we call rootOwnerOfChild looking for who owns the child token
    # (nft_no_auth, 0) it should see that the parent token is owned by a
    # contract, and then call that contract's rootOwnerOfChild fn
    # with (xhibit, parent_token_id)
    # the result is the parent given by the composables rootOwnerOfChild fn
    expected_root_owner = ERC998_MAGIC_VALUE[:-40] + ETH_ADDR[2:]
    root_owner = xhibit.rootOwnerOfChild(nft_no_auth, 0)

    assert root_owner == expected_root_owner
