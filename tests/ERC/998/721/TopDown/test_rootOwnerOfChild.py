ERC998_MAGIC_VALUE = (
    "0xcd740db500000000000000000000000000000000000000000000000000000000"
)
ETH_ADDR = "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE"


def test_return_value_for_eoa_owner(alice, xhibit, nft):
    nft.safeTransferFrom(alice, xhibit, 0, 0, {"from": alice})

    expected_root_owner = ERC998_MAGIC_VALUE[:-40] + alice.address[2:]
    root_owner = xhibit.rootOwnerOfChild(nft, 0)

    assert root_owner == expected_root_owner
