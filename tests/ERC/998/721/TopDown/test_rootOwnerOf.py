ERC998_MAGIC_VALUE = (
    "0xcd740db500000000000000000000000000000000000000000000000000000000"
)
ETH_ADDR = "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE"


def test_root_owner_is_eoa(alice, xhibit, nft):
    expected_root_owner = ERC998_MAGIC_VALUE[:-40] + alice.address[2:]
    root_owner = xhibit.rootOwnerOf(0)

    assert root_owner == expected_root_owner


def test_root_owner_is_contract(alice, nft_no_auth, xhibit):
    # mint an xhibit for nft_no_auth
    xhibit.mint(nft_no_auth, {"from": alice})

    expected_root_owner = ERC998_MAGIC_VALUE[:-40] + nft_no_auth.address[2:]
    root_owner = xhibit.rootOwnerOf(1)

    assert root_owner == expected_root_owner


def test_root_owner_is_top_down_composable(
    alice, composable_top_down, nft_no_auth, xhibit
):
    # mint an xhibit for the mock Top Down contract
    xhibit.mint(composable_top_down, {"from": alice})

    expected_root_owner = ERC998_MAGIC_VALUE[:-40] + ETH_ADDR[2:]
    root_owner = xhibit.rootOwnerOf(1)

    assert root_owner == expected_root_owner
