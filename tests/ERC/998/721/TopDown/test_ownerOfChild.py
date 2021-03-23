import brownie

ERC998_MAGIC_VALUE = (
    "0xcd740db500000000000000000000000000000000000000000000000000000000"
)


def test_ownerOfChild_returns_correct_values(alice, nft, xhibit):
    nft.safeTransferFrom(alice, xhibit, 0, 0, {"from": alice})

    ownerOfChild = xhibit.ownerOfChild(nft, 0)

    assert ownerOfChild[0] == ERC998_MAGIC_VALUE[:-40] + alice.address[2:]
    assert ownerOfChild[1] == 0


def test_ownerOfChild_reverts_if_token_isnt_held(alice, nft, xhibit):
    with brownie.reverts("dev: Token is not held by self"):
        xhibit.ownerOfChild(nft, 0)
